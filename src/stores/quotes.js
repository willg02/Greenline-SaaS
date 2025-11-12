import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useOrganizationStore } from './organization'
import { useAuthStore } from './auth'

// Helper to safely number formatting
function formatCurrency(value) {
  if (value == null || isNaN(value)) return 0
  return Math.round(Number(value) * 100) / 100
}

export const useQuotesStore = defineStore('quotes', () => {
  const quotes = ref([])
  const currentQuote = ref(null)
  const quoteItems = ref([])
  const loading = ref(false)
  const creating = ref(false)
  const error = ref(null)

  async function loadQuotes() {
    const orgStore = useOrganizationStore()
    if (!orgStore.organizationId) return
    loading.value = true
    error.value = null
    try {
      const { data, error: fetchError } = await supabase
        .from('quotes')
        .select('*')
        .eq('organization_id', orgStore.organizationId)
        .order('created_at', { ascending: false })
      if (fetchError) throw fetchError
      quotes.value = data || []
    } catch (e) {
      console.error('Error loading quotes', e)
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function loadQuoteById(id) {
    if (!id) return
    loading.value = true
    error.value = null
    try {
      const { data: quote, error: quoteError } = await supabase
        .from('quotes')
        .select('*')
        .eq('id', id)
        .single()
      if (quoteError) throw quoteError
      currentQuote.value = quote

      const { data: items, error: itemsError } = await supabase
        .from('quote_items')
        .select('*')
        .eq('quote_id', id)
        .order('created_at', { ascending: true })
      if (itemsError) throw itemsError
      quoteItems.value = items || []
      return quote
    } catch (e) {
      console.error('Error loading quote', e)
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function createQuote({ client, project_name, tax_rate = 0 }) {
    const orgStore = useOrganizationStore()
    const authStore = useAuthStore()
    if (!orgStore.organizationId || !authStore.user) throw new Error('Missing org or user context')
    if (!client) throw new Error('Client is required')
    creating.value = true
    error.value = null
    try {
      // Generate quote number via RPC (server sequence). If fails, fallback.
      let quote_number = 'TMP-' + Date.now()
      const { data: numData, error: numError } = await supabase.rpc('generate_quote_number')
      if (!numError && numData) quote_number = numData

      const insertPayload = {
        organization_id: orgStore.organizationId,
        client_id: client.id,
        client_name: client.name,
        client_email: client.email,
        client_phone: client.phone,
        client_address: [client.address, client.city, client.state, client.zip_code].filter(Boolean).join(', '),
        quote_number,
        status: 'draft',
        project_name: project_name || null,
        tax_rate: tax_rate,
        created_by: authStore.user.id
      }

      const { data, error: insertError } = await supabase
        .from('quotes')
        .insert(insertPayload)
        .select()
        .single()
      if (insertError) throw insertError

      quotes.value = [data, ...quotes.value]
      return data
    } catch (e) {
      console.error('Error creating quote', e)
      error.value = e.message
      throw e
    } finally {
      creating.value = false
    }
  }

  async function addQuoteItem({ quote_id, item_type, item_name, description = '', quantity = 1, unit_price }) {
    if (!quote_id) throw new Error('quote_id required')
    const total_price = formatCurrency(quantity * unit_price)
    try {
      const { data, error: insertError } = await supabase
        .from('quote_items')
        .insert({ quote_id, item_type, item_name, description, quantity, unit_price, total_price })
        .select()
        .single()
      if (insertError) throw insertError
      quoteItems.value.push(data)
      await recomputeTotals()
      return data
    } catch (e) {
      console.error('Error adding item', e)
      error.value = e.message
      throw e
    }
  }

  async function updateQuoteItem(id, updates) {
    if (!id) throw new Error('Item id required')
    const next = { ...updates }
    if (next.quantity != null && next.unit_price != null) {
      next.total_price = formatCurrency(next.quantity * next.unit_price)
    }
    try {
      const { data, error: updateError } = await supabase
        .from('quote_items')
        .update(next)
        .eq('id', id)
        .select()
        .single()
      if (updateError) throw updateError
      const idx = quoteItems.value.findIndex(i => i.id === id)
      if (idx !== -1) quoteItems.value[idx] = data
      await recomputeTotals()
      return data
    } catch (e) {
      console.error('Error updating item', e)
      error.value = e.message
      throw e
    }
  }

  async function deleteQuoteItem(id) {
    if (!id) return
    try {
      const { error: delError } = await supabase
        .from('quote_items')
        .delete()
        .eq('id', id)
      if (delError) throw delError
      quoteItems.value = quoteItems.value.filter(i => i.id !== id)
      await recomputeTotals()
    } catch (e) {
      console.error('Error deleting item', e)
      error.value = e.message
      throw e
    }
  }

  async function recomputeTotals() {
    if (!currentQuote.value) return
    const byType = { plant: 0, material: 0, labor: 0, other: 0 }
    for (const item of quoteItems.value) {
      byType[item.item_type] = formatCurrency(byType[item.item_type] + Number(item.total_price || 0))
    }
    const subtotal = formatCurrency(byType.plant + byType.material + byType.labor + byType.other)
    const tax_rate = currentQuote.value.tax_rate || 0
    const tax_amount = formatCurrency(subtotal * (tax_rate / 100))
    const total_amount = formatCurrency(subtotal + tax_amount)
    const updatePayload = {
      plants_cost: byType.plant,
      materials_cost: byType.material,
      labor_cost: byType.labor,
      other_cost: byType.other,
      subtotal,
      tax_amount,
      total_amount
    }
    try {
      const { data, error: updateError } = await supabase
        .from('quotes')
        .update(updatePayload)
        .eq('id', currentQuote.value.id)
        .select()
        .single()
      if (updateError) throw updateError
      currentQuote.value = data
      // Also update list copy
      const idx = quotes.value.findIndex(q => q.id === data.id)
      if (idx !== -1) quotes.value[idx] = data
    } catch (e) {
      console.error('Error updating quote totals', e)
      error.value = e.message
    }
  }

  async function updateQuoteStatus(id, status) {
    try {
      const { data, error: statusError } = await supabase
        .from('quotes')
        .update({ status })
        .eq('id', id)
        .select()
        .single()
      if (statusError) throw statusError
      if (currentQuote.value?.id === id) currentQuote.value.status = data.status
      const idx = quotes.value.findIndex(q => q.id === id)
      if (idx !== -1) quotes.value[idx].status = data.status
      return data
    } catch (e) {
      console.error('Error updating quote status', e)
      error.value = e.message
      throw e
    }
  }

  function clearCurrentQuote() {
    currentQuote.value = null
    quoteItems.value = []
  }

  return {
    quotes,
    currentQuote,
    quoteItems,
    loading,
    creating,
    error,
    loadQuotes,
    loadQuoteById,
    createQuote,
    addQuoteItem,
    updateQuoteItem,
    deleteQuoteItem,
    recomputeTotals,
    updateQuoteStatus,
    clearCurrentQuote
  }
})
