import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { useOrganizationStore } from './organization'
import { useAuthStore } from './auth'

// Simple permission cache for current user's membership in current organization.
// Phase 0: permissions are role-based only (no object-level overrides except document_permissions still legacy).
export const usePermissionsStore = defineStore('permissions', () => {
  const loading = ref(false)
  const roleId = ref(null)
  const roleName = ref(null)
  const permissionSet = ref(new Set()) // entries like `${resource}:${action}`
  const initializedForOrg = ref(null)

  const orgStore = useOrganizationStore()
  const authStore = useAuthStore()

  async function load() {
    if (!authStore.user || !orgStore.currentOrganization) return
    const orgId = orgStore.currentOrganization.id
    if (initializedForOrg.value === orgId) return // already loaded for this org

    loading.value = true
    permissionSet.value = new Set()
    roleId.value = null
    roleName.value = null

    // Fetch membership
    const { data: memberRows, error: memberError } = await supabase
      .from('organization_members')
      .select('role, role_id')
      .eq('organization_id', orgId)
      .eq('user_id', authStore.user.id)
      .limit(1)

    if (memberError || !memberRows.length) {
      loading.value = false
      initializedForOrg.value = orgId
      return
    }

    const membership = memberRows[0]
    roleId.value = membership.role_id || null
    roleName.value = membership.role

    // If role_id missing (older rows), we can fallback to role name join.
    let effectiveRoleId = roleId.value
    if (!effectiveRoleId) {
      const { data: roleDefRows } = await supabase
        .from('role_definitions')
        .select('id')
        .eq('name', membership.role)
        .limit(1)
      if (roleDefRows && roleDefRows.length) effectiveRoleId = roleDefRows[0].id
    }

    if (effectiveRoleId) {
      const { data: permRows, error: permError } = await supabase
        .from('role_permissions')
        .select('resource, action')
        .eq('role_id', effectiveRoleId)

      if (!permError && permRows) {
        permRows.forEach(p => {
          permissionSet.value.add(`${p.resource}:${p.action}`)
        })
      }
    }

    loading.value = false
    initializedForOrg.value = orgId
  }

  function can(resource, action) {
    // Owners implicitly all actions (temporary until legacy policies removed)
    if (roleName.value === 'owner') return true
    return permissionSet.value.has(`${resource}:${action}`)
  }

  function clear() {
    loading.value = false
    roleId.value = null
    roleName.value = null
    permissionSet.value = new Set()
    initializedForOrg.value = null
  }

  // React to organization change or auth change
  watch(() => orgStore.currentOrganization?.id, () => {
    initializedForOrg.value = null
    load()
  })
  watch(() => authStore.user?.id, () => {
    initializedForOrg.value = null
    load()
  })

  return {
    loading,
    roleId,
    roleName,
    can,
    load,
    clear
  }
})
