import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useOrganizationStore = defineStore('organization', () => {
  const currentOrganization = ref(null)
  const userOrganizations = ref([])
  const loading = ref(false)

  const organizationId = computed(() => currentOrganization.value?.id)
  const organizationName = computed(() => currentOrganization.value?.name)
  const isOwner = computed(() => currentOrganization.value?.role === 'owner')
  const isAdmin = computed(() => 
    currentOrganization.value?.role === 'owner' || 
    currentOrganization.value?.role === 'admin'
  )

  async function loadUserOrganizations() {
    try {
      loading.value = true

      const { data, error } = await supabase
        .from('organization_members')
        .select(`
          role_id,
          role_definitions (
            id,
            name,
            display_name
          ),
          organizations (
            id,
            name,
            slug,
            subscription_tier,
            subscription_status,
            created_at
          )
        `)
        .order('created_at', { foreignTable: 'organizations', ascending: true })

      if (error) throw error

      userOrganizations.value = data.map(item => ({
        ...item.organizations,
        role_id: item.role_id,
        role: item.role_definitions?.name || 'member',
        role_display: item.role_definitions?.display_name || 'Member'
      }))

      // Set first organization as current if none selected
      if (!currentOrganization.value && userOrganizations.value.length > 0) {
        await setCurrentOrganization(userOrganizations.value[0].id)
      }
    } catch (error) {
      console.error('Error loading organizations:', error)
    } finally {
      loading.value = false
    }
  }

  async function setCurrentOrganization(orgId) {
    const org = userOrganizations.value.find(o => o.id === orgId)
    if (org) {
      currentOrganization.value = org
      // Store in localStorage for persistence
      localStorage.setItem('currentOrganizationId', orgId)
    }
  }

  async function createOrganization({ name, owner_id }) {
    try {
      loading.value = true

      // Generate slug from name
      const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-')

      const { data, error } = await supabase
        .from('organizations')
        .insert({
          name,
          slug,
          owner_id,
          subscription_tier: 'solo',
          subscription_status: 'trialing'
        })
        .select()
        .single()

      if (error) throw error

      // Get owner role_id
      const { data: ownerRole, error: roleError } = await supabase
        .from('role_definitions')
        .select('id')
        .eq('name', 'owner')
        .single()

      if (roleError) throw roleError

      // Add user as owner member
      const { error: memberError } = await supabase
        .from('organization_members')
        .insert({
          organization_id: data.id,
          user_id: owner_id,
          role_id: ownerRole.id,
          invited_by: owner_id
        })

      if (memberError) throw memberError

      await loadUserOrganizations()
      return { data, error: null }
    } catch (error) {
      console.error('Error creating organization:', error)
      return { data: null, error }
    } finally {
      loading.value = false
    }
  }

  async function updateOrganization(updates) {
    try {
      if (!currentOrganization.value) throw new Error('No organization selected')

      const { data, error } = await supabase
        .from('organizations')
        .update(updates)
        .eq('id', currentOrganization.value.id)
        .select()
        .single()

      if (error) throw error

      currentOrganization.value = { ...currentOrganization.value, ...data }
      await loadUserOrganizations()

      return { data, error: null }
    } catch (error) {
      console.error('Error updating organization:', error)
      return { data: null, error }
    }
  }

  async function inviteTeamMember(email, roleName = 'member') {
    try {
      if (!currentOrganization.value) throw new Error('No organization selected')

      // Get role_id for the specified role
      const { data: roleData, error: roleError } = await supabase
        .from('role_definitions')
        .select('id')
        .eq('name', roleName)
        .single()

      if (roleError) throw roleError

      const { data, error } = await supabase
        .from('organization_invitations')
        .insert({
          organization_id: currentOrganization.value.id,
          email,
          role_id: roleData.id,
          status: 'pending'
        })
        .select()
        .single()

      if (error) throw error

      // TODO: Send invitation email via Supabase Edge Function

      return { data, error: null }
    } catch (error) {
      console.error('Error inviting team member:', error)
      return { data: null, error }
    }
  }

  function clearOrganization() {
    currentOrganization.value = null
    userOrganizations.value = []
    localStorage.removeItem('currentOrganizationId')
  }

  return {
    currentOrganization,
    userOrganizations,
    loading,
    organizationId,
    organizationName,
    isOwner,
    isAdmin,
    loadUserOrganizations,
    setCurrentOrganization,
    createOrganization,
    updateOrganization,
    inviteTeamMember,
    clearOrganization
  }
})
