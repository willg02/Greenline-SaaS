<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <div>
            <h1>👥 Client Management</h1>
            <p class="subtitle">Manage your client relationships</p>
          </div>
          <button class="btn btn-primary" @click="openAddClientModal">+ Add Client</button>
        </div>

        <!-- Search and Filter -->
        <div class="card" style="margin-bottom: 1.5rem;">
          <input
            v-model="searchQuery"
            type="text"
            class="input-field"
            placeholder="Search clients by name, email, or phone..."
            style="width: 100%;"
          />
        </div>

        <!-- Clients List -->
        <div v-if="loading" class="card">
          <p>Loading clients...</p>
        </div>

        <div v-else-if="filteredClients.length === 0" class="card">
          <p style="text-align: center; color: var(--text-secondary);">
            {{ searchQuery ? 'No clients found matching your search.' : 'No clients yet. Add your first client to get started!' }}
          </p>
        </div>

        <div v-else class="clients-grid">
          <div v-for="client in filteredClients" :key="client.id" class="client-card card">
            <div class="client-header">
              <h3>{{ client.name }}</h3>
              <div class="client-actions">
                <button class="btn-icon" @click="editClient(client)" title="Edit">✏️</button>
                <button class="btn-icon" @click="deleteClient(client)" title="Delete">🗑️</button>
              </div>
            </div>
            <div class="client-details">
              <div v-if="client.email" class="detail-row">
                <span class="detail-label">Email:</span>
                <a :href="`mailto:${client.email}`">{{ client.email }}</a>
              </div>
              <div v-if="client.phone" class="detail-row">
                <span class="detail-label">Phone:</span>
                <a :href="`tel:${client.phone}`">{{ client.phone }}</a>
              </div>
              <div v-if="client.address" class="detail-row">
                <span class="detail-label">Address:</span>
                <span>{{ formatAddress(client) }}</span>
              </div>
              <div v-if="client.notes" class="detail-row">
                <span class="detail-label">Notes:</span>
                <p class="notes">{{ client.notes }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Add/Edit Client Modal -->
    <div v-if="showClientModal" class="modal-overlay" @click="closeClientModal">
      <div class="modal-card" @click.stop>
        <h2>{{ editingClient ? 'Edit Client' : 'Add New Client' }}</h2>
        <form @submit.prevent="saveClient">
          <div class="input-group">
            <label for="clientName">Name *</label>
            <input
              id="clientName"
              v-model="clientForm.name"
              type="text"
              class="input-field"
              required
            />
          </div>
          <div class="input-group">
            <label for="clientEmail">Email</label>
            <input
              id="clientEmail"
              v-model="clientForm.email"
              type="email"
              class="input-field"
            />
          </div>
          <div class="input-group">
            <label for="clientPhone">Phone</label>
            <input
              id="clientPhone"
              v-model="clientForm.phone"
              type="tel"
              class="input-field"
            />
          </div>
          <div class="input-group">
            <label for="clientAddress">Address</label>
            <input
              id="clientAddress"
              v-model="clientForm.address"
              type="text"
              class="input-field"
            />
          </div>
          <div class="form-row">
            <div class="input-group">
              <label for="clientCity">City</label>
              <input
                id="clientCity"
                v-model="clientForm.city"
                type="text"
                class="input-field"
              />
            </div>
            <div class="input-group">
              <label for="clientState">State</label>
              <input
                id="clientState"
                v-model="clientForm.state"
                type="text"
                class="input-field"
                maxlength="2"
              />
            </div>
            <div class="input-group">
              <label for="clientZip">Zip</label>
              <input
                id="clientZip"
                v-model="clientForm.zip_code"
                type="text"
                class="input-field"
              />
            </div>
          </div>
          <div class="input-group">
            <label for="clientNotes">Notes</label>
            <textarea
              id="clientNotes"
              v-model="clientForm.notes"
              class="input-field"
              rows="4"
            ></textarea>
          </div>
          <div v-if="error" class="alert alert-error">{{ error }}</div>
          <div class="modal-actions">
            <button type="button" class="btn btn-secondary" @click="closeClientModal" :disabled="saving">Cancel</button>
            <button type="submit" class="btn btn-primary" :disabled="saving">
              {{ saving ? 'Saving...' : 'Save Client' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import NavigationBar from '@/components/NavigationBar.vue'
import { useOrganizationStore } from '@/stores/organization'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const orgStore = useOrganizationStore()
const authStore = useAuthStore()

const clients = ref([])
const loading = ref(false)
const searchQuery = ref('')
const showClientModal = ref(false)
const editingClient = ref(null)
const saving = ref(false)
const error = ref(null)

const clientForm = ref({
  name: '',
  email: '',
  phone: '',
  address: '',
  city: '',
  state: '',
  zip_code: '',
  notes: ''
})

const filteredClients = computed(() => {
  if (!searchQuery.value) return clients.value
  const query = searchQuery.value.toLowerCase()
  return clients.value.filter(client =>
    client.name.toLowerCase().includes(query) ||
    client.email?.toLowerCase().includes(query) ||
    client.phone?.toLowerCase().includes(query)
  )
})

onMounted(() => {
  loadClients()
})

async function loadClients() {
  loading.value = true
  try {
    const { data, error: fetchError } = await supabase
      .from('clients')
      .select('*')
      .eq('organization_id', orgStore.organizationId)
      .order('name')
    
    if (fetchError) throw fetchError
    clients.value = data || []
  } catch (err) {
    console.error('Error loading clients:', err)
  } finally {
    loading.value = false
  }
}

function openAddClientModal() {
  editingClient.value = null
  clientForm.value = {
    name: '',
    email: '',
    phone: '',
    address: '',
    city: '',
    state: '',
    zip_code: '',
    notes: ''
  }
  error.value = null
  showClientModal.value = true
}

function editClient(client) {
  editingClient.value = client
  clientForm.value = { ...client }
  error.value = null
  showClientModal.value = true
}

function closeClientModal() {
  showClientModal.value = false
  editingClient.value = null
  error.value = null
}

async function saveClient() {
  error.value = null
  saving.value = true

  try {
    const clientData = {
      ...clientForm.value,
      organization_id: orgStore.organizationId,
      created_by: authStore.user.id
    }

    if (editingClient.value) {
      // Update existing client
      const { error: updateError } = await supabase
        .from('clients')
        .update(clientData)
        .eq('id', editingClient.value.id)
      
      if (updateError) throw updateError
    } else {
      // Create new client
      const { error: insertError } = await supabase
        .from('clients')
        .insert([clientData])
      
      if (insertError) throw insertError
    }

    await loadClients()
    closeClientModal()
  } catch (err) {
    console.error('Error saving client:', err)
    error.value = err.message || 'Failed to save client'
  } finally {
    saving.value = false
  }
}

async function deleteClient(client) {
  if (!confirm(`Are you sure you want to delete ${client.name}? This cannot be undone.`)) {
    return
  }

  try {
    const { error: deleteError } = await supabase
      .from('clients')
      .delete()
      .eq('id', client.id)
    
    if (deleteError) throw deleteError
    await loadClients()
  } catch (err) {
    console.error('Error deleting client:', err)
    alert('Failed to delete client: ' + err.message)
  }
}

function formatAddress(client) {
  const parts = [client.address, client.city, client.state, client.zip_code].filter(Boolean)
  return parts.join(', ')
}
</script>

<style scoped>
.page-layout {
  min-height: 100vh;
  background-color: var(--bg-secondary);
}

.page-main {
  padding: 2rem 0 4rem;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  margin-bottom: 0.5rem;
}

.subtitle {
  color: var(--text-secondary);
  margin: 0;
}

.clients-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.client-card {
  padding: 1.5rem;
}

.client-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.client-header h3 {
  margin: 0;
  font-size: 1.25rem;
}

.client-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.25rem;
  padding: 0.25rem;
  opacity: 0.7;
  transition: opacity var(--transition-fast);
}

.btn-icon:hover {
  opacity: 1;
}

.client-details {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.detail-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--text-tertiary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.detail-row a {
  color: var(--color-primary);
  text-decoration: none;
}

.detail-row a:hover {
  text-decoration: underline;
}

.notes {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.9375rem;
  white-space: pre-wrap;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 1rem;
}

.modal-card {
  background: var(--color-white);
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-lg);
  padding: 2rem;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-card h2 {
  margin-bottom: 1.5rem;
}

.input-group {
  margin-bottom: 1rem;
}

.input-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: var(--text-primary);
}

.input-field {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  font-size: 1rem;
  font-family: inherit;
}

.input-field:focus {
  outline: none;
  border-color: var(--color-primary);
}

textarea.input-field {
  resize: vertical;
}

.form-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 1rem;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1.5rem;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .clients-grid {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
