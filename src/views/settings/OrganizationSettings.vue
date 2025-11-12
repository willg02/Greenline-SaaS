<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>Organization Settings</h1>
        </div>

        <div class="content-card card">
          <form @submit.prevent="handleUpdateOrg" style="margin-bottom: 2rem;">
            <h3>Organization Details</h3>
            <div class="input-group">
              <label for="orgName">Name</label>
              <input id="orgName" v-model="orgName" type="text" class="input-field" :disabled="updatingOrg" required />
            </div>
            <div class="input-group">
              <label>Subscription</label>
              <span class="input-field" style="background: #f5f5f5;">{{ organization?.subscription_tier || 'N/A' }}</span>
            </div>
            <div v-if="updateOrgError" class="alert alert-error">{{ updateOrgError }}</div>
            <div v-if="updateOrgSuccess" class="alert alert-success">{{ updateOrgSuccess }}</div>
            <button class="btn btn-primary" type="submit" :disabled="updatingOrg">{{ updatingOrg ? 'Saving...' : 'Save Changes' }}</button>
          </form>

          <div style="margin-bottom: 2rem;">
            <h3>Team Members</h3>
            <ul v-if="teamMembers.length">
              <li v-for="member in teamMembers" :key="member.user_id" style="margin-bottom: 0.5rem;">
                <span>{{ member.email }}</span>
                <span class="org-badge" style="margin-left: 0.5rem;">{{ member.role }}</span>
                <span v-if="member.user_id === organization.owner_id" style="color: var(--color-primary); margin-left: 0.5rem;">(Owner)</span>
              </li>
            </ul>
            <div v-else>No team members found.</div>
            <form @submit.prevent="handleInvite" style="margin-top: 1rem; display: flex; gap: 0.5rem; align-items: flex-end;">
              <div>
                <label for="inviteEmail">Invite by Email</label>
                <input id="inviteEmail" v-model="inviteEmail" type="email" class="input-field" placeholder="user@email.com" :disabled="inviting" required />
              </div>
              <div>
                <label for="inviteRole">Role</label>
                <select id="inviteRole" v-model="inviteRole" class="input-field" :disabled="inviting">
                  <option value="member">Member</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <button class="btn btn-secondary" type="submit" :disabled="inviting">{{ inviting ? 'Inviting...' : 'Invite' }}</button>
            </form>
            <div v-if="inviteError" class="alert alert-error">{{ inviteError }}</div>
            <div v-if="inviteSuccess" class="alert alert-success">{{ inviteSuccess }}</div>
          </div>

          <div v-if="isOwner" style="margin-top: 2rem;">
            <h3>Danger Zone</h3>
            <button class="btn btn-danger" @click="handleDeleteOrg" :disabled="deletingOrg">{{ deletingOrg ? 'Deleting...' : 'Delete Organization' }}</button>
            <div v-if="deleteOrgError" class="alert alert-error">{{ deleteOrgError }}</div>
          </div>

          <router-link to="/dashboard" class="btn btn-primary" style="margin-top: 2rem;">Back to Dashboard</router-link>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import NavigationBar from '@/components/NavigationBar.vue'
import { useOrganizationStore } from '@/stores/organization'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const orgStore = useOrganizationStore()
const authStore = useAuthStore()

const organization = computed(() => orgStore.currentOrganization)
const isOwner = computed(() => orgStore.isOwner)
const orgName = ref(organization.value?.name || '')
const updatingOrg = ref(false)
const updateOrgError = ref(null)
const updateOrgSuccess = ref(null)

const teamMembers = ref([])
const inviteEmail = ref('')
const inviteRole = ref('member')
const inviting = ref(false)
const inviteError = ref(null)
const inviteSuccess = ref(null)

const deletingOrg = ref(false)
const deleteOrgError = ref(null)

async function fetchTeamMembers() {
  if (!organization.value) return
  const { data, error } = await supabase
    .from('organization_members')
    .select('user_id, role, users ( email )')
    .eq('organization_id', organization.value.id)
  if (error) {
    teamMembers.value = []
    return
  }
  teamMembers.value = data.map(m => ({
    user_id: m.user_id,
    role: m.role,
    email: m.users?.email || 'Unknown'
  }))
}

onMounted(() => {
  if (organization.value) orgName.value = organization.value.name
  fetchTeamMembers()
})

async function handleUpdateOrg() {
  updateOrgError.value = null
  updateOrgSuccess.value = null
  updatingOrg.value = true
  const { error } = await orgStore.updateOrganization({ name: orgName.value })
  if (error) {
    updateOrgError.value = error.message || 'Failed to update organization.'
  } else {
    updateOrgSuccess.value = 'Organization updated!'
  }
  updatingOrg.value = false
}

async function handleInvite() {
  inviteError.value = null
  inviteSuccess.value = null
  inviting.value = true
  const { error } = await orgStore.inviteTeamMember(inviteEmail.value, inviteRole.value)
  if (error) {
    inviteError.value = error.message || 'Failed to send invite.'
  } else {
    inviteSuccess.value = 'Invitation sent!'
    inviteEmail.value = ''
    inviteRole.value = 'member'
    fetchTeamMembers()
  }
  inviting.value = false
}

async function handleDeleteOrg() {
  if (!confirm('Are you sure you want to delete this organization? This cannot be undone.')) return
  deleteOrgError.value = null
  deletingOrg.value = true
  // Delete org from DB (owner only)
  const { error } = await supabase.from('organizations').delete().eq('id', organization.value.id)
  if (error) {
    deleteOrgError.value = error.message || 'Failed to delete organization.'
    deletingOrg.value = false
    return
  }
  // Remove org from store and redirect
  await orgStore.loadUserOrganizations()
  window.location.href = '/dashboard'
}
</script>

<style scoped>
.page-layout {
  min-height: 100vh;
  background-color: var(--bg-secondary);
}

.page-main {
  padding: 2rem 0 4rem;
}

.page-header {
  margin-bottom: 2rem;
}

.content-card {
  max-width: 800px;
  margin: 0 auto;
}

.input-group {
  margin-bottom: 1rem;
}

.input-field {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  font-size: 1rem;
}

.org-badge {
  display: inline-block;
  background: var(--color-gray-200);
  color: var(--text-secondary);
  border-radius: var(--border-radius-sm);
  padding: 0.15rem 0.5rem;
  font-size: 0.85em;
  margin-left: 0.25rem;
}

.btn-danger {
  background: var(--color-error);
  color: #fff;
  border: none;
  padding: 0.5rem 1.25rem;
  border-radius: var(--border-radius);
  cursor: pointer;
  margin-top: 1rem;
}
</style>
