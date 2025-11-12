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
          role,
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
        role: item.role
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

      // Add user as owner member
      const { error: memberError } = await supabase
        .from('organization_members')
        .insert({
          organization_id: data.id,
          user_id: owner_id,
          role: 'owner'
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

  async function inviteTeamMember(email, role = 'member') {
    try {
      if (!currentOrganization.value) throw new Error('No organization selected')

      const { data, error } = await supabase
        .from('organization_invitations')
        .insert({
          organization_id: currentOrganization.value.id,
          email,
          role,
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
