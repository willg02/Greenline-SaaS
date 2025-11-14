// Permission utilities composable
import { computed } from 'vue'
import { usePermissionsStore } from '@/stores/permissions'
import { useOrganizationStore } from '@/stores/organization'

/**
 * Composable for checking permissions in components
 * Usage: const { can, canAny, canAll, role } = usePermissions()
 */
export function usePermissions() {
  const permissionsStore = usePermissionsStore()
  const orgStore = useOrganizationStore()

  // Check if user has a specific permission
  const can = (resource, action) => {
    return permissionsStore.can(resource, action)
  }

  // Check if user has ANY of the specified permissions
  const canAny = (...permissions) => {
    return permissions.some(([resource, action]) => 
      permissionsStore.can(resource, action)
    )
  }

  // Check if user has ALL of the specified permissions
  const canAll = (...permissions) => {
    return permissions.every(([resource, action]) => 
      permissionsStore.can(resource, action)
    )
  }

  // Get current role information
  const role = computed(() => permissionsStore.roleName)
  const roleDisplay = computed(() => {
    return orgStore.currentOrganization?.role_display || 'Member'
  })

  // Quick role checks (for convenience)
  const isOwner = computed(() => role.value === 'owner')
  const isAdmin = computed(() => role.value === 'admin')
  const isMember = computed(() => role.value === 'member')
  const isViewer = computed(() => role.value === 'viewer')

  // Check if user can manage organization settings
  const canManageOrganization = computed(() => 
    can('organization', 'manage_settings')
  )

  // Check if user can manage team members
  const canManageMembers = computed(() => 
    can('organization', 'manage_members')
  )

  // Check if user can access billing
  const canAccessBilling = computed(() => 
    can('organization', 'configure_billing')
  )

  return {
    can,
    canAny,
    canAll,
    role,
    roleDisplay,
    isOwner,
    isAdmin,
    isMember,
    isViewer,
    canManageOrganization,
    canManageMembers,
    canAccessBilling,
    loading: computed(() => permissionsStore.loading)
  }
}

/**
 * Permission directive for v-permission usage in templates
 * Usage: <button v-permission="['clients', 'create']">Add Client</button>
 */
export const permissionDirective = {
  mounted(el, binding) {
    const permissionsStore = usePermissionsStore()
    const [resource, action] = binding.value
    
    if (!permissionsStore.can(resource, action)) {
      // Hide element if no permission
      el.style.display = 'none'
    }
  },
  updated(el, binding) {
    const permissionsStore = usePermissionsStore()
    const [resource, action] = binding.value
    
    if (!permissionsStore.can(resource, action)) {
      el.style.display = 'none'
    } else {
      el.style.display = ''
    }
  }
}

/**
 * Helper to check permissions for resource actions
 */
export const PermissionActions = {
  // CRUD operations
  canRead: (resource) => ['read'],
  canCreate: (resource) => ['create'],
  canUpdate: (resource) => ['update_any', 'update_own'],
  canDelete: (resource) => ['delete_any', 'delete_own'],
  
  // Specific operations
  canPublish: (resource) => ['publish'],
  canArchive: (resource) => ['archive'],
  canExport: (resource) => ['export'],
}
