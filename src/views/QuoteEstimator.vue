<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>💰 Quotes</h1>
          <p class="subtitle">Create and manage landscaping quotes</p>
        </div>

        <div class="actions mb-3">
          <button class="btn btn-primary" @click="openNewQuoteModal">New Quote</button>
          <router-link to="/dashboard" class="btn btn-secondary">Dashboard</router-link>
        </div>

        <div v-if="quotesStore.loading" class="card p-4">Loading quotes...</div>
        <div v-else class="card quotes-card">
          <table class="quotes-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Client</th>
                <th>Status</th>
                <th>Total</th>
                <th>Date</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="quotesStore.quotes.length === 0">
                <td colspan="6" class="empty">No quotes yet. Create your first quote.</td>
              </tr>
              <tr v-for="q in quotesStore.quotes" :key="q.id">
                <td>{{ q.quote_number }}</td>
                <td>
                  <div class="client-name">{{ q.client_name }}</div>
                  <small v-if="q.project_name" class="text-secondary">{{ q.project_name }}</small>
                </td>
                <td>
                  <span :class="['status-chip', 'status-' + q.status]">{{ q.status }}</span>
                </td>
                <td>{{ formatMoney(q.total_amount) }}</td>
                <td>{{ formatDate(q.created_at) }}</td>
                <td>
                  <router-link :to="`/quotes/${q.id}`" class="btn btn-sm btn-outline">Open</router-link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- New Quote Modal -->
        <div v-if="showNewModal" class="modal-backdrop">
          <div class="modal-card">
            <h3>Create Quote</h3>
            <form @submit.prevent="createQuote">
              <label class="form-field">
                <span>Client</span>
                <select v-model="selectedClientId" required>
                  <option disabled value="">Select client...</option>
                  <option v-for="c in clients" :key="c.id" :value="c.id">{{ c.name }}</option>
                </select>
              </label>
              <label class="form-field">
                <span>Project Name (optional)</span>
                <input v-model="projectName" type="text" placeholder="Spring Clean Up" />
              </label>
              <label class="form-field">
                <span>Tax Rate (%)</span>
                <input v-model.number="taxRate" type="number" step="0.01" min="0" />
              </label>
              <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="closeNewQuoteModal">Cancel</button>
                <button type="submit" class="btn btn-primary" :disabled="quotesStore.creating">{{ quotesStore.creating ? 'Creating...' : 'Create' }}</button>
              </div>
              <p v-if="quotesStore.error" class="error mt-2">{{ quotesStore.error }}</p>
            </form>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import NavigationBar from '@/components/NavigationBar.vue'
import { useQuotesStore } from '@/stores/quotes'
import { supabase } from '@/lib/supabase'
import { useOrganizationStore } from '@/stores/organization'

const quotesStore = useQuotesStore()
const router = useRouter()
const organizationStore = useOrganizationStore()
const clients = ref([])
const showNewModal = ref(false)
const selectedClientId = ref('')
const projectName = ref('')
const taxRate = ref(0)

function formatMoney(val) {
  if (!val && val !== 0) return '—'
  return '$' + Number(val).toFixed(2)
}
function formatDate(d) { return new Date(d).toLocaleDateString() }

function openNewQuoteModal() { showNewModal.value = true }
function closeNewQuoteModal() { showNewModal.value = false }

async function loadClients() {
  if (!organizationStore.organizationId) return
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .eq('organization_id', organizationStore.organizationId)
    .order('name', { ascending: true })
  if (!error) clients.value = data
}

async function createQuote() {
  const client = clients.value.find(c => c.id === selectedClientId.value)
  if (!client) return
  const quote = await quotesStore.createQuote({ client, project_name: projectName.value, tax_rate: taxRate.value })
  closeNewQuoteModal()
  selectedClientId.value = ''
  projectName.value = ''
  taxRate.value = 0
  if (quote?.id) router.push({ name: 'QuoteDetail', params: { id: quote.id } })
}

onMounted(async () => {
  await quotesStore.loadQuotes()
  await loadClients()
})
</script>

<style scoped>
.page-layout { min-height: 100vh; background: var(--bg-secondary); }
.page-main { padding: 2rem 0 4rem; }
.page-header { margin-bottom: 1.5rem; }
.subtitle { color: var(--text-secondary); margin: 0; }
.actions { display: flex; gap: .75rem; }
.quotes-card { overflow-x: auto; }
.quotes-table { width: 100%; border-collapse: collapse; }
.quotes-table th, .quotes-table td { padding: .6rem .75rem; text-align: left; border-bottom: 1px solid var(--border-color); }
.quotes-table th { background: var(--bg-tertiary); font-weight: 600; font-size: .85rem; }
.empty { text-align: center; padding: 2rem; color: var(--text-secondary); }
.status-chip { display: inline-block; padding: .25rem .6rem; border-radius: 999px; font-size: .7rem; text-transform: uppercase; letter-spacing: .5px; }
.status-draft { background: #ddd; color: #333; }
.status-sent { background: #d0ebff; color: #095c91; }
.status-accepted { background: #d3f9d8; color: #2b7a0b; }
.status-rejected { background: #ffe3e3; color: #c92a2a; }
.client-name { font-weight: 600; }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.35); display: flex; align-items: flex-start; justify-content: center; padding-top: 6vh; z-index: 50; }
.modal-card { background: var(--bg-primary); width: 420px; max-width: 95vw; padding: 1.25rem 1.25rem 1rem; border-radius: 8px; box-shadow: 0 8px 32px rgba(0,0,0,.25); }
.modal-card h3 { margin: 0 0 1rem; }
.form-field { display: flex; flex-direction: column; gap: .35rem; margin-bottom: .9rem; font-size: .85rem; }
.form-field input, .form-field select { padding: .55rem .65rem; border: 1px solid var(--border-color); background: var(--bg-secondary); border-radius: 6px; font-size: .85rem; }
.modal-actions { display: flex; justify-content: flex-end; gap: .75rem; margin-top: .25rem; }
.error { color: #c92a2a; font-size: .75rem; }
.btn-sm { font-size: .7rem; padding: .35rem .55rem; }
.btn-outline { background: transparent; border: 1px solid var(--border-color); }
</style>
