<template>
  <div class="dashboard-layout">
    <NavigationBar />
    
    <main class="dashboard-main">
      <div class="container">
        <div class="dashboard-header">
          <div>
            <h1>Dashboard</h1>
            <p class="subtitle">Welcome back, {{ userName }}!</p>
          </div>
          <div class="org-info" v-if="organizationName">
            <span class="org-badge">{{ organizationName }}</span>
            <span class="plan-badge">{{ subscriptionTier }}</span>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-card card">
            <div class="stat-icon">💰</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalQuotes }}</div>
              <div class="stat-label">Total Quotes</div>
            </div>
          </div>

          <div class="stat-card card">
            <div class="stat-icon">👥</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalClients }}</div>
              <div class="stat-label">Clients</div>
            </div>
          </div>

          <div class="stat-card card">
            <div class="stat-icon">🌿</div>
            <div class="stat-content">
              <div class="stat-value">{{ totalPlants }}</div>
              <div class="stat-label">Plants in Database</div>
            </div>
          </div>

          <div class="stat-card card">
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
              <router-link to="/quotes" class="action-button btn btn-primary">
                <span>💰</span> Create New Quote
              </router-link>
              <router-link to="/clients" class="action-button btn btn-secondary">
                <span>👤</span> Add Client
              </router-link>
              <router-link to="/plants" class="action-button btn btn-secondary">
                <span>🌿</span> Browse Plants
              </router-link>
              <router-link to="/calculator" class="action-button btn btn-secondary">
                <span>📐</span> Material Calculator
              </router-link>
            </div>
          </div>

          <div class="recent-quotes card">
            <h2>Recent Quotes</h2>
            <div v-if="recentQuotes.length === 0" class="empty-state">
              <p>No quotes yet. Create your first quote to get started!</p>
              <router-link to="/quotes" class="btn btn-primary btn-sm">
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
import NavigationBar from '@/components/NavigationBar.vue'
import { supabase } from '@/lib/supabase'

const authStore = useAuthStore()
const orgStore = useOrganizationStore()

const totalQuotes = ref(0)
const totalClients = ref(0)
const totalPlants = ref(30) // Default from plant database
const totalRevenue = ref(0)
const recentQuotes = ref([])

const userName = computed(() => 
  authStore.user?.user_metadata?.full_name || 
  authStore.user?.email?.split('@')[0] || 
  'User'
)
const organizationName = computed(() => orgStore.organizationName)
const subscriptionTier = computed(() => 
  orgStore.currentOrganization?.subscription_tier?.toUpperCase() || 'FREE'
)

onMounted(async () => {
  await loadDashboardData()
})

async function loadDashboardData() {
  if (!orgStore.organizationId) return

  try {
    // Load quotes count and recent quotes
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

    // Load clients count
    const { count: clientsCount, error: clientsError } = await supabase
      .from('clients')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', orgStore.organizationId)

    if (!clientsError) {
      totalClients.value = clientsCount || 0
    }

    // Load custom plants count
    const { count: plantsCount, error: plantsError } = await supabase
      .from('plants')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', orgStore.organizationId)

    if (!plantsError) {
      totalPlants.value += (plantsCount || 0)
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
</style>
