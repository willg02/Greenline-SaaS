<template>
  <div class="dashboard-layout">
    <NavigationBar />
    
    <!-- Create Organization Modal -->
    <div v-if="showCreateOrgModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content" @click.stop>
        <button class="close-button" @click="closeModal" type="button">×</button>
        <div class="modal-icon">🏢</div>
        <h2>Create Your Organization</h2>
        <p class="modal-description">Get started by setting up your organization. You can always change this later.</p>
        <form @submit.prevent="handleCreateOrganization" class="modal-form">
          <div class="form-group">
            <label for="org-name">Organization Name</label>
            <input 
              id="org-name"
              v-model="newOrgName" 
              type="text" 
              required
              :disabled="loading"
              placeholder="e.g., GreenTouch Landscaping"
              class="form-input"
              autofocus
            >
          </div>
          <div class="button-group">
            <button type="button" @click="closeModal" class="btn-secondary" :disabled="loading">Cancel</button>
            <button type="submit" class="btn-primary" :disabled="loading || !newOrgName.trim()">
              <span v-if="loading">Creating...</span>
              <span v-else>Create Organization</span>
            </button>
          </div>
        </form>
        <p v-if="errorMessage" class="error-message">{{ errorMessage }}</p>
      </div>
    </div>

    <!-- No Organization State -->
    <div v-if="!orgStore.currentOrganization && !loading" class="no-org-state">
      <div class="welcome-card">
        <div class="welcome-icon">🌱</div>
        <h2>Welcome to Greenline!</h2>
        <p>Let's get started by creating your organization. This will be your workspace for managing quotes, clients, and projects.</p>
        <button @click="showCreateOrgModal = true" class="btn-create-org">
          <span class="btn-icon">🏢</span>
          Create Your Organization
        </button>
      </div>
    </div>
    
    <main v-else class="dashboard-main">
      <div class="container">
        <div class="dashboard-header">
          <div>
            <h1>Dashboard</h1>
            <p class="subtitle">Welcome back, {{ userName }}!</p>
          </div>
          <div class="org-info" v-if="organizationName">
            <span class="role-badge" :class="'role-' + currentRole.toLowerCase()">{{ currentRole }}</span>
            <span class="org-badge">{{ organizationName }}</span>
            <span class="plan-badge">{{ subscriptionTier }}</span>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-card card" v-if="canReadQuotes">
            <div class="stat-icon">💰</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalQuotes }}</div>
              <div class="stat-label">Total Quotes</div>
            </div>
          </div>

          <div class="stat-card card" v-if="canReadClients">
            <div class="stat-icon">👥</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalClients }}</div>
              <div class="stat-label">Clients</div>
            </div>
          </div>

          <div class="stat-card card" v-if="canReadPlants">
            <div class="stat-icon">🌿</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalPlants }}</div>
              <div class="stat-label">Plants in Database</div>
            </div>
          </div>

          <div class="stat-card card" v-if="canReadQuotes">
            <div class="stat-icon">📈</div>
            <div class="stat-content">
              <div class="stat-value">${{ totalRevenue }}</div>
              <div class="stat-label">Total Revenue</div>
            </div>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="quick-actions card">
            <h2>Quick Actions</h2>
            <div class="actions-list">
              <router-link to="/quotes" class="action-button btn btn-primary" v-if="canCreateQuotes">
                <span>💰</span> Create New Quote
              </router-link>
              <router-link to="/clients" class="action-button btn btn-secondary" v-if="canManageClients">
                <span>👤</span> Add Client
              </router-link>
              <router-link to="/plants" class="action-button btn btn-secondary" v-if="canReadPlants">
                <span>🌿</span> Browse Plants
              </router-link>
              <router-link to="/calculator" class="action-button btn btn-secondary" v-if="canUseMaterialCalculator">
                <span>📐</span> Material Calculator
              </router-link>
            </div>
          </div>

          <div class="recent-quotes card" v-if="canReadQuotes">
            <h2>Recent Quotes</h2>
            <div v-if="recentQuotes.length === 0" class="empty-state">
              <p>No quotes yet. Create your first quote to get started!</p>
              <router-link to="/quotes" class="btn btn-primary btn-sm" v-if="canCreateQuotes">
                Create Quote
              </router-link>
            </div>
            <div v-else class="quotes-list">
              <div 
                v-for="quote in recentQuotes" 
                :key="quote.id"
                class="quote-item"
              >
                <div class="quote-info">
                  <div class="quote-client">{{ quote.client_name }}</div>
                  <div class="quote-date">{{ formatDate(quote.created_at) }}</div>
                </div>
                <div class="quote-amount">${{ quote.total_amount }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useOrganizationStore } from '@/stores/organization'
import { usePermissionsStore } from '@/stores/permissions'
import NavigationBar from '@/components/NavigationBar.vue'
import { supabase } from '@/lib/supabase'

const authStore = useAuthStore()
const orgStore = useOrganizationStore()
const permissionsStore = usePermissionsStore()

const totalQuotes = ref(0)
const totalClients = ref(0)
const totalPlants = ref(30) // Default from plant database
const totalRevenue = ref(0)
const recentQuotes = ref([])
const showCreateOrgModal = ref(false)
const newOrgName = ref('')
const loading = ref(false)
const errorMessage = ref('')

const userName = computed(() => 
  authStore.user?.user_metadata?.full_name || 
  authStore.user?.email?.split('@')[0] || 
  'User'
)
const organizationName = computed(() => orgStore.organizationName)
const subscriptionTier = computed(() => 
  orgStore.currentOrganization?.subscription_tier?.toUpperCase() || 'FREE'
)

// Permission-based computed properties
const currentRole = computed(() => orgStore.currentOrganization?.role_display || 'Member')
const canCreateQuotes = computed(() => permissionsStore.can('quotes', 'create'))
const canReadQuotes = computed(() => permissionsStore.can('quotes', 'read'))
const canManageClients = computed(() => permissionsStore.can('clients', 'create'))
const canReadClients = computed(() => permissionsStore.can('clients', 'read'))
const canReadPlants = computed(() => permissionsStore.can('plants', 'read'))
const canUseMaterialCalculator = computed(() => permissionsStore.can('quotes', 'read')) // Basic access

onMounted(async () => {
  // Load organizations first
  await orgStore.loadUserOrganizations()
  
  // Check if user has organizations, if not show create modal
  if (orgStore.userOrganizations.length === 0 && !orgStore.currentOrganization) {
    showCreateOrgModal.value = true
  } else {
    await permissionsStore.load() // Load permissions after org is set
    await loadDashboardData()
  }
})

async function handleCreateOrganization() {
  if (!newOrgName.value.trim()) return
  
  loading.value = true
  errorMessage.value = ''
  
  try {
    const { data, error } = await orgStore.createOrganization({
      name: newOrgName.value.trim(),
      owner_id: authStore.user.id
    })
    
    if (error) {
      console.error('Organization creation error:', error)
      errorMessage.value = error.message || 'Failed to create organization. Please try again.'
      return
    }
    
    showCreateOrgModal.value = false
    newOrgName.value = ''
    await permissionsStore.load() // Load permissions for new org
    await loadDashboardData()
  } catch (error) {
    console.error('Error creating organization:', error)
    errorMessage.value = 'An unexpected error occurred. Please try again.'
  } finally {
    loading.value = false
  }
}

function closeModal() {
  if (!loading.value) {
    showCreateOrgModal.value = false
    errorMessage.value = ''
    newOrgName.value = ''
  }
}

async function loadDashboardData() {
  if (!orgStore.organizationId) return

  try {
    // Load quotes count and recent quotes (if user has permission)
    if (canReadQuotes.value) {
      const { data: quotes, error: quotesError } = await supabase
        .from('quotes')
        .select('*')
        .eq('organization_id', orgStore.organizationId)
        .order('created_at', { ascending: false })
        .limit(5)

      if (!quotesError && quotes) {
        totalQuotes.value = quotes.length
        recentQuotes.value = quotes
        totalRevenue.value = quotes.reduce((sum, q) => sum + (q.total_amount || 0), 0)
      }
    }

    // Load clients count (if user has permission)
    if (canReadClients.value) {
      const { count: clientsCount, error: clientsError } = await supabase
        .from('clients')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgStore.organizationId)

      if (!clientsError) {
        totalClients.value = clientsCount || 0
      }
    }

    // Load custom plants count (if user has permission)
    if (canReadPlants.value) {
      const { count: plantsCount, error: plantsError } = await supabase
        .from('plants')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgStore.organizationId)

      if (!plantsError) {
        totalPlants.value += (plantsCount || 0)
      }
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  }
}

function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>

<style scoped>
.dashboard-layout {
  min-height: 100vh;
  background-color: var(--bg-secondary);
}

.dashboard-main {
  padding: 2rem 0 4rem;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.dashboard-header h1 {
  margin-bottom: 0.25rem;
}

.subtitle {
  color: var(--text-secondary);
  margin: 0;
}

.org-info {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.role-badge {
  padding: 0.5rem 1rem;
  border-radius: var(--border-radius);
  font-weight: 600;
  font-size: 0.875rem;
  text-transform: capitalize;
  border: 2px solid;
}

.role-badge.role-owner {
  background-color: #fef3c7;
  color: #92400e;
  border-color: #fbbf24;
}

.role-badge.role-admin {
  background-color: #dbeafe;
  color: #1e3a8a;
  border-color: #3b82f6;
}

.role-badge.role-member {
  background-color: #d1fae5;
  color: #065f46;
  border-color: #10b981;
}

.role-badge.role-viewer {
  background-color: #f3f4f6;
  color: #374151;
  border-color: #9ca3af;
}

.org-badge {
  padding: 0.5rem 1rem;
  background-color: var(--color-white);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  font-weight: 500;
  color: var(--text-primary);
}

.plan-badge {
  padding: 0.5rem 1rem;
  background-color: var(--color-primary);
  color: var(--color-white);
  border-radius: var(--border-radius);
  font-weight: 600;
  font-size: 0.875rem;
  text-transform: uppercase;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
}

.stat-icon {
  font-size: 2.5rem;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
  margin-bottom: 0.25rem;
}

.stat-label {
  color: var(--text-secondary);
  font-size: 0.875rem;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}

.quick-actions h2,
.recent-quotes h2 {
  font-size: 1.25rem;
  margin-bottom: 1.5rem;
}

.actions-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.action-button {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  text-align: left;
  justify-content: flex-start;
}

.action-button span {
  font-size: 1.5rem;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: var(--text-secondary);
}

.empty-state p {
  margin-bottom: 1rem;
}

.quotes-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.quote-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background-color: var(--bg-secondary);
  border-radius: var(--border-radius);
  transition: background-color var(--transition-fast);
  cursor: pointer;
}

.quote-item:hover {
  background-color: var(--bg-tertiary);
}

.quote-client {
  font-weight: 500;
  color: var(--text-primary);
  margin-bottom: 0.25rem;
}

.quote-date {
  font-size: 0.875rem;
  color: var(--text-tertiary);
}

.quote-amount {
  font-weight: 700;
  font-size: 1.125rem;
  color: var(--color-primary);
}

@media (max-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .dashboard-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}

/* Organization Creation Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { 
    opacity: 0;
    transform: translateY(20px);
  }
  to { 
    opacity: 1;
    transform: translateY(0);
  }
}

.modal-content {
  background: white;
  padding: 40px;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 480px;
  width: 90%;
  position: relative;
  animation: slideUp 0.3s ease-out;
}

.close-button {
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  font-size: 32px;
  color: #999;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.2s;
}

.close-button:hover {
  color: #333;
}

.modal-icon {
  font-size: 48px;
  text-align: center;
  margin-bottom: 16px;
}

.modal-content h2 {
  margin: 0 0 12px 0;
  color: #1a1a1a;
  font-size: 28px;
  font-weight: 600;
  text-align: center;
}

.modal-description {
  color: #666;
  text-align: center;
  margin-bottom: 24px;
  line-height: 1.5;
  font-size: 14px;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  text-align: left;
}

.form-group label {
  font-weight: 500;
  color: #333;
  font-size: 14px;
}

.form-input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.2s;
  font-family: inherit;
}

.form-input:focus {
  outline: none;
  border-color: #0066cc;
}

.form-input:disabled {
  background: #f5f5f5;
  cursor: not-allowed;
}

.button-group {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.button-group button {
  flex: 1;
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  font-family: inherit;
}

.btn-primary {
  background: #0066cc;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #0052a3;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 102, 204, 0.3);
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: #f5f5f5;
  color: #666;
}

.btn-secondary:hover:not(:disabled) {
  background: #e0e0e0;
}

.error-message {
  color: #dc3545;
  font-size: 14px;
  text-align: center;
  margin-top: 12px;
  padding: 10px;
  background: #fff5f5;
  border-radius: 6px;
  border: 1px solid #ffebee;
}

/* No Organization State */
.no-org-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  padding: 60px 20px;
}

.welcome-card {
  background: white;
  padding: 48px;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  text-align: center;
  max-width: 560px;
  animation: slideUp 0.4s ease-out;
}

.welcome-icon {
  font-size: 64px;
  margin-bottom: 24px;
}

.welcome-card h2 {
  margin: 0 0 16px 0;
  color: #1a1a1a;
  font-size: 32px;
  font-weight: 600;
}

.welcome-card p {
  margin-bottom: 32px;
  color: #666;
  font-size: 16px;
  line-height: 1.6;
}

.btn-create-org {
  padding: 14px 32px;
  background: linear-gradient(135deg, #0066cc 0%, #0052a3 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 16px rgba(0, 102, 204, 0.3);
  font-family: inherit;
}

.btn-create-org:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(0, 102, 204, 0.4);
}

.btn-icon {
  font-size: 20px;
}
</style>
