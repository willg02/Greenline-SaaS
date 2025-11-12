<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container" v-if="quotesStore.loading && !quotesStore.currentQuote">
        <div class="card p-4">Loading quote...</div>
      </div>
      <div class="container" v-else-if="!quotesStore.currentQuote">
        <div class="card p-4">Quote not found. <router-link to="/quotes">Back to quotes</router-link></div>
      </div>
      <div class="container" v-else>
        <div class="page-header">
          <h1>Quote {{ quotesStore.currentQuote.quote_number }}</h1>
          <p class="subtitle">Client: {{ quotesStore.currentQuote.client_name }}</p>
        </div>

        <div class="card mb-3">
          <div class="overview-grid">
            <div>
              <label>Status</label><br />
              <span :class="['status-chip','status-' + quotesStore.currentQuote.status]">{{ quotesStore.currentQuote.status }}</span>
            </div>
            <div>
              <label>Subtotal</label><div>{{ money(quotesStore.currentQuote.subtotal) }}</div>
            </div>
            <div>
              <label>Tax ({{ quotesStore.currentQuote.tax_rate || 0 }}%)</label><div>{{ money(quotesStore.currentQuote.tax_amount) }}</div>
            </div>
            <div>
              <label>Total</label><div class="total">{{ money(quotesStore.currentQuote.total_amount) }}</div>
            </div>
          </div>
          <div class="status-actions">
            <button class="btn btn-sm" @click="setStatus('sent')" :disabled="quotesStore.currentQuote.status==='sent'">Mark Sent</button>
            <button class="btn btn-sm" @click="setStatus('accepted')" :disabled="quotesStore.currentQuote.status==='accepted'">Mark Accepted</button>
            <button class="btn btn-sm" @click="setStatus('rejected')" :disabled="quotesStore.currentQuote.status==='rejected'">Mark Rejected</button>
            <router-link to="/quotes" class="btn btn-sm btn-secondary">Back</router-link>
          </div>
        </div>

        <div class="card mb-3">
          <h3 class="section-title">Line Items</h3>
          <table class="items-table">
            <thead>
              <tr>
                <th style="width:110px">Type</th>
                <th>Name</th>
                <th style="width:80px">Qty</th>
                <th style="width:120px">Unit Price</th>
                <th style="width:120px">Total</th>
                <th style="width:60px"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in quotesStore.quoteItems" :key="item.id">
                <td><span class="item-type">{{ item.item_type }}</span></td>
                <td>{{ item.item_name }}</td>
                <td>
                  <input type="number" min="1" v-model.number="editable[item.id].quantity" @change="updateItem(item.id)" />
                </td>
                <td>
                  <input type="number" min="0" step="0.01" v-model.number="editable[item.id].unit_price" @change="updateItem(item.id)" />
                </td>
                <td>{{ money(item.total_price) }}</td>
                <td>
                  <button class="icon-btn" @click="removeItem(item.id)" title="Delete">✕</button>
                </td>
              </tr>
              <tr v-if="quotesStore.quoteItems.length === 0">
                <td colspan="6" class="empty">No items yet. Add your first line item below.</td>
              </tr>
            </tbody>
          </table>

          <form class="add-item-form" @submit.prevent="addItem">
            <select v-model="newItem.type" required>
              <option disabled value="">Type</option>
              <option value="plant">Plant</option>
              <option value="material">Material</option>
              <option value="labor">Labor</option>
              <option value="other">Other</option>
            </select>
            <input v-model="newItem.name" type="text" placeholder="Item name" required />
            <input v-model.number="newItem.quantity" type="number" min="1" placeholder="Qty" required />
            <input v-model.number="newItem.unit_price" type="number" step="0.01" min="0" placeholder="Unit Price" required />
            <button class="btn btn-primary" :disabled="addingItem">{{ addingItem ? 'Adding...' : 'Add Item' }}</button>
          </form>
          <p v-if="quotesStore.error" class="error mt-1">{{ quotesStore.error }}</p>
        </div>

        <div class="card">
          <h3 class="section-title">Export</h3>
          <p>PDF export & share links coming soon.</p>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import NavigationBar from '@/components/NavigationBar.vue'
import { useQuotesStore } from '@/stores/quotes'

const route = useRoute()
const quotesStore = useQuotesStore()
const addingItem = ref(false)
const editable = reactive({})
const newItem = reactive({ type: '', name: '', quantity: 1, unit_price: 0 })

function money(v) { return v == null ? '—' : '$' + Number(v).toFixed(2) }

async function init() {
  await quotesStore.loadQuoteById(route.params.id)
  for (const item of quotesStore.quoteItems) {
    editable[item.id] = { quantity: item.quantity, unit_price: item.unit_price }
  }
}

async function addItem() {
  if (!newItem.type || !newItem.name) return
  addingItem.value = true
  try {
    const item = await quotesStore.addQuoteItem({
      quote_id: quotesStore.currentQuote.id,
      item_type: newItem.type,
      item_name: newItem.name,
      quantity: newItem.quantity,
      unit_price: newItem.unit_price
    })
    editable[item.id] = { quantity: item.quantity, unit_price: item.unit_price }
    newItem.type = ''; newItem.name=''; newItem.quantity=1; newItem.unit_price=0
  } finally {
    addingItem.value = false
  }
}

async function updateItem(id) {
  const state = editable[id]
  if (!state) return
  await quotesStore.updateQuoteItem(id, { quantity: state.quantity, unit_price: state.unit_price })
}

async function removeItem(id) {
  await quotesStore.deleteQuoteItem(id)
  delete editable[id]
}

async function setStatus(status) {
  await quotesStore.updateQuoteStatus(quotesStore.currentQuote.id, status)
}

onMounted(init)
</script>

<style scoped>
.page-layout { min-height: 100vh; background: var(--bg-secondary); }
.page-main { padding: 2rem 0 4rem; }
.page-header { margin-bottom: 1.25rem; }
.subtitle { color: var(--text-secondary); margin: 0; }
.overview-grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(140px,1fr)); gap: 1rem; font-size: .8rem; }
.overview-grid label { font-weight: 600; font-size: .7rem; text-transform: uppercase; letter-spacing: .5px; color: var(--text-secondary); }
.total { font-weight: 600; font-size: 1.05rem; }
.status-actions { display: flex; flex-wrap: wrap; gap: .5rem; margin-top: 1rem; }
.status-chip { display:inline-block; padding:.25rem .6rem; border-radius:999px; font-size:.65rem; text-transform:uppercase; letter-spacing:.5px; }
.status-draft { background:#ddd; color:#333; }
.status-sent { background:#d0ebff; color:#095c91; }
.status-accepted { background:#d3f9d8; color:#2b7a0b; }
.status-rejected { background:#ffe3e3; color:#c92a2a; }
.items-table { width:100%; border-collapse: collapse; margin-bottom:.75rem; }
.items-table th, .items-table td { padding:.5rem .55rem; border-bottom:1px solid var(--border-color); font-size:.75rem; }
.items-table th { background: var(--bg-tertiary); text-transform:uppercase; font-weight:600; letter-spacing:.5px; font-size:.65rem; }
.items-table input { width:100%; padding:.35rem .4rem; border:1px solid var(--border-color); background: var(--bg-secondary); border-radius:4px; font-size:.7rem; }
.item-type { text-transform: capitalize; font-weight:600; font-size:.7rem; }
.empty { text-align:center; padding:1.5rem; color: var(--text-secondary); }
.add-item-form { display:flex; flex-wrap:wrap; gap:.5rem; }
.add-item-form input, .add-item-form select { flex:1 1 100px; min-width:90px; padding:.45rem .5rem; border:1px solid var(--border-color); background: var(--bg-secondary); border-radius:6px; font-size:.7rem; }
.add-item-form button { flex:0 0 auto; }
.icon-btn { background:transparent; border:none; cursor:pointer; font-size:.85rem; line-height:1; padding:.25rem .4rem; color:#c92a2a; }
.icon-btn:hover { background:#ffe3e3; border-radius:4px; }
.section-title { margin:0 0 .75rem; font-size: .9rem; }
.error { color:#c92a2a; font-size:.7rem; }
.btn-sm { font-size:.65rem; padding:.4rem .6rem; }
.btn-secondary { background: var(--bg-tertiary); }
</style>
