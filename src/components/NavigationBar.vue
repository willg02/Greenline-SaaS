<template>
  <nav class="navbar">
    <div class="navbar-container">
      <div class="navbar-brand">
        <router-link to="/" class="brand-link">
          🌿 <span class="brand-text">Greenline</span>
        </router-link>
      </div>

      <div class="navbar-menu" :class="{ 'is-active': mobileMenuOpen }">
        <template v-if="!isAuthenticated">
          <router-link to="/login" class="nav-link">Login</router-link>
          <router-link to="/signup" class="btn btn-primary btn-sm">Get Started</router-link>
        </template>

        <template v-else>
          <router-link to="/dashboard" class="nav-link">Dashboard</router-link>
          <router-link to="/plants" class="nav-link">Plants</router-link>
          <router-link to="/quotes" class="nav-link">Quotes</router-link>
          <router-link to="/clients" class="nav-link">Clients</router-link>
          <router-link to="/calculator" class="nav-link">Calculator</router-link>
          <router-link to="/sop-library" class="nav-link">SOP Library</router-link>
          
          <div class="navbar-divider"></div>
          
          <div class="user-menu" @click="toggleUserMenu">
            <div class="user-avatar">
              {{ userInitials }}
            </div>
            <span class="user-name">{{ userName }}</span>
            
            <div v-if="userMenuOpen" class="user-dropdown">
              <div class="organization-switcher" v-if="organizations.length">
                <div class="dropdown-label">Switch Organization</div>
                <div 
                  v-for="org in organizations" 
                  :key="org.id"
                  @click.stop="switchOrganization(org.id)"
                  class="dropdown-item"
                  :class="{ active: org.id === currentOrgId }"
                >
                  <span class="org-name">{{ org.name }}</span>
                  <span class="org-badge">{{ org.role_display || org.role }}</span>
                </div>
                <div class="dropdown-divider"></div>
              </div>
              
              <router-link 
                to="/settings" 
                class="dropdown-item" 
                @click="closeUserMenu"
                v-if="permissionsStore.can('organization', 'manage_settings') || permissionsStore.can('organization', 'manage_members')"
              >
                Settings
              </router-link>
              <router-link 
                to="/settings/billing" 
                class="dropdown-item" 
                @click="closeUserMenu"
                v-if="permissionsStore.can('organization', 'configure_billing')"
              >
                Billing
              </router-link>
              <div class="dropdown-divider"></div>
              <button @click="handleSignOut" class="dropdown-item dropdown-item-danger">
                Sign Out
              </button>
            </div>
          </div>
        </template>
      </div>

      <button class="mobile-menu-toggle" @click="toggleMobileMenu">
        <span class="hamburger"></span>
      </button>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useOrganizationStore } from '@/stores/organization'
import { usePermissionsStore } from '@/stores/permissions'

const router = useRouter()
const authStore = useAuthStore()
const orgStore = useOrganizationStore()
const permissionsStore = usePermissionsStore()

const mobileMenuOpen = ref(false)
const userMenuOpen = ref(false)

const isAuthenticated = computed(() => authStore.isAuthenticated)
const userName = computed(() => authStore.user?.user_metadata?.full_name || authStore.user?.email?.split('@')[0] || 'User')
const userInitials = computed(() => {
  const name = userName.value
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
})
const organizations = computed(() => orgStore.userOrganizations)
const currentOrgId = computed(() => orgStore.organizationId)

// Initialize permissions when component mounts
onMounted(async () => {
  if (authStore.isAuthenticated && orgStore.currentOrganization) {
    await permissionsStore.load()
  }
})

function toggleMobileMenu() {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

function toggleUserMenu() {
  userMenuOpen.value = !userMenuOpen.value
}

function closeUserMenu() {
  userMenuOpen.value = false
}

async function switchOrganization(orgId) {
  await orgStore.setCurrentOrganization(orgId)
  await permissionsStore.load() // Reload permissions for new org
  closeUserMenu()
  router.push('/dashboard')
}

async function handleSignOut() {
  await authStore.signOut()
  router.push('/login')
}
</script>

<style scoped>
.navbar {
  background-color: var(--color-white);
  border-bottom: 1px solid var(--border-color);
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: var(--shadow-sm);
}

.navbar-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 var(--spacing-lg);
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
}

.navbar-brand {
  display: flex;
  align-items: center;
}

.brand-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-primary);
  text-decoration: none;
}

.brand-text {
  font-size: 1.25rem;
}

.navbar-menu {
  display: flex;
  align-items: center;
  gap: var(--spacing-lg);
}

.nav-link {
  color: var(--text-secondary);
  font-weight: 500;
  transition: color var(--transition-fast);
  text-decoration: none;
}

.nav-link:hover,
.nav-link.router-link-active {
  color: var(--color-primary);
}

.navbar-divider {
  width: 1px;
  height: 24px;
  background-color: var(--border-color);
}

.user-menu {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  border-radius: var(--border-radius);
  cursor: pointer;
  transition: background-color var(--transition-fast);
}

.user-menu:hover {
  background-color: var(--bg-secondary);
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-primary), var(--color-accent));
  color: var(--color-white);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 0.875rem;
}

.user-name {
  font-weight: 500;
  color: var(--text-primary);
}

.user-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 0.5rem;
  background-color: var(--color-white);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-lg);
  min-width: 240px;
  z-index: 1001;
}

.dropdown-label {
  padding: 0.75rem 1rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--text-tertiary);
  letter-spacing: 0.05em;
}

.dropdown-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  color: var(--text-primary);
  text-decoration: none;
  transition: background-color var(--transition-fast);
  cursor: pointer;
  border: none;
  background: none;
  width: 100%;
  text-align: left;
  font-size: 0.9375rem;
}

.dropdown-item:hover {
  background-color: var(--bg-secondary);
}

.dropdown-item.active {
  background-color: var(--color-primary);
  color: var(--color-white);
}

.dropdown-item-danger {
  color: var(--color-error);
}

.dropdown-divider {
  height: 1px;
  background-color: var(--border-color);
  margin: 0.5rem 0;
}

.org-name {
  font-weight: 500;
}

.org-badge {
  font-size: 0.75rem;
  padding: 0.25rem 0.5rem;
  border-radius: var(--border-radius-sm);
  background-color: var(--color-gray-200);
  color: var(--text-secondary);
  text-transform: capitalize;
}

.mobile-menu-toggle {
  display: none;
}

@media (max-width: 768px) {
  .navbar-menu {
    display: none;
    position: absolute;
    top: 64px;
    left: 0;
    right: 0;
    background-color: var(--color-white);
    border-bottom: 1px solid var(--border-color);
    flex-direction: column;
    padding: var(--spacing-lg);
    gap: var(--spacing-md);
    box-shadow: var(--shadow-lg);
  }

  .navbar-menu.is-active {
    display: flex;
  }

  .mobile-menu-toggle {
    display: block;
    padding: 0.5rem;
    cursor: pointer;
  }

  .hamburger {
    display: block;
    width: 24px;
    height: 2px;
    background-color: var(--text-primary);
    position: relative;
  }

  .hamburger::before,
  .hamburger::after {
    content: '';
    position: absolute;
    width: 24px;
    height: 2px;
    background-color: var(--text-primary);
    left: 0;
  }

  .hamburger::before {
    top: -8px;
  }

  .hamburger::after {
    bottom: -8px;
  }
}
</style>
