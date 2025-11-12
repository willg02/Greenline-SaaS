import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

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
    meta: { requiresAuth: true }
  },
  {
    path: '/quotes',
    name: 'QuoteEstimator',
    component: () => import('@/views/QuoteEstimator.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/quotes/:id',
    name: 'QuoteDetail',
    component: () => import('@/views/QuoteDetail.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/calculator',
    name: 'MaterialCalculator',
    component: () => import('@/views/MaterialCalculator.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/clients',
    name: 'ClientManagement',
    component: () => import('@/views/ClientManagement.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/sop-library',
    name: 'SOPLibrary',
    component: () => import('@/views/SOPLibrary.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/SettingsPage.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/settings/organization',
    name: 'OrganizationSettings',
    component: () => import('@/views/settings/OrganizationSettings.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/settings/billing',
    name: 'BillingSettings',
    component: () => import('@/views/settings/BillingSettings.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation guard for authentication
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  if (requiresAuth && !authStore.user) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
  } else if ((to.name === 'Login' || to.name === 'Signup') && authStore.user) {
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router
