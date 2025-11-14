import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useOrganizationStore } from '@/stores/organization'
import { usePermissionsStore } from '@/stores/permissions'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/LandingPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/LoginPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/signup',
    name: 'Signup',
    component: () => import('@/views/auth/SignupPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('@/views/DashboardPage.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/plants',
    name: 'PlantCompendium',
    component: () => import('@/views/PlantCompendium.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['plants', 'read']]
    }
  },
  {
    path: '/quotes',
    name: 'QuoteEstimator',
    component: () => import('@/views/QuoteEstimator.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['quotes', 'read']]
    }
  },
  {
    path: '/quotes/:id',
    name: 'QuoteDetail',
    component: () => import('@/views/QuoteDetail.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['quotes', 'read']]
    }
  },
  {
    path: '/calculator',
    name: 'MaterialCalculator',
    component: () => import('@/views/MaterialCalculator.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['quotes', 'read']]
    }
  },
  {
    path: '/clients',
    name: 'ClientManagement',
    component: () => import('@/views/ClientManagement.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['clients', 'read']]
    }
  },
  {
    path: '/sop-library',
    name: 'SOPLibrary',
    component: () => import('@/views/SOPLibrary.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['documents', 'read']]
    }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/SettingsPage.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['organization', 'manage_settings'], ['organization', 'manage_members']]
    }
  },
  {
    path: '/settings/organization',
    name: 'OrganizationSettings',
    component: () => import('@/views/settings/OrganizationSettings.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['organization', 'manage_settings']]
    }
  },
  {
    path: '/settings/billing',
    name: 'BillingSettings',
    component: () => import('@/views/settings/BillingSettings.vue'),
    meta: { 
      requiresAuth: true,
      permissions: [['organization', 'configure_billing']]
    }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation guard for authentication and permissions
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  const orgStore = useOrganizationStore()
  const permissionsStore = usePermissionsStore()
  
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  // Check authentication
  if (requiresAuth && !authStore.user) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }
  
  // Redirect authenticated users away from login/signup
  if ((to.name === 'Login' || to.name === 'Signup') && authStore.user) {
    next({ name: 'Dashboard' })
    return
  }

  // Check permissions if route requires them
  const requiredPermissions = to.meta.permissions
  if (requiresAuth && requiredPermissions && Array.isArray(requiredPermissions)) {
    // Ensure permissions are loaded
    if (!permissionsStore.roleName && orgStore.currentOrganization) {
      await permissionsStore.load()
    }

    // Check if user has at least one of the required permissions (OR logic)
    const hasPermission = requiredPermissions.some(([resource, action]) => 
      permissionsStore.can(resource, action)
    )

    if (!hasPermission) {
      // Redirect to dashboard with error message
      next({ name: 'Dashboard' })
      return
    }
  }

  next()
})

export default router
