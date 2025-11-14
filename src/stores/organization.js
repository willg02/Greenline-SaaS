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
      console.log('Loading user organizations...')

      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        console.log('No authenticated user')
        return
      }

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
        .eq('user_id', user.id)
        .order('created_at', { foreignTable: 'organizations', ascending: true })

      if (error) {
        console.error('Supabase error loading organizations:', error)
        throw error
      }

      console.log('Loaded organizations:', data)

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
      console.log('Creating organization:', name)
      console.log('Inserting organization (DB will generate slug)...')
      const { data: orgData, error: orgError } = await supabase
        .from('organizations')
        .insert({
          name,
          owner_id,
          subscription_tier: 'solo',
          subscription_status: 'trialing'
        })
        .select()
        .single()

      if (orgError) {
        console.error('Error inserting organization:', orgError)
        throw orgError
      }
      console.log('Organization created:', orgData)

      // Get owner role_id
      console.log('Fetching owner role...')
      const { data: ownerRole, error: roleError } = await supabase
        .from('role_definitions')
        .select('id')
        .eq('name', 'owner')
        .single()

      if (roleError) {
        console.error('Error fetching owner role:', roleError)
        throw roleError
      }
      console.log('Owner role:', ownerRole)

      // Add user as owner member
      console.log('Adding user as owner member...')
      const { error: memberError } = await supabase
        .from('organization_members')
        .insert({
          organization_id: orgData.id,
          user_id: owner_id,
          role_id: ownerRole.id,
          invited_by: owner_id
        })

      if (memberError) {
        console.error('Error inserting member:', memberError)
        throw memberError
      }
      console.log('Member added successfully')

      console.log('Reloading organizations...')
      await loadUserOrganizations()
      console.log('Organization creation complete')
      
      return { data: orgData, error: null }
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
