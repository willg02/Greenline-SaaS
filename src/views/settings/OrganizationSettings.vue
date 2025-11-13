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
                <select
                  v-if="canEditMember(member)"
                  v-model="member.role"
                  @change="updateMemberRole(member)"
                  class="role-select"
                >
                  <option value="owner">Owner</option>
                  <option value="admin">Admin</option>
                  <option value="member">Member</option>
                </select>
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

          <div style="margin-bottom:2rem;">
            <h3>Role Definitions</h3>
            <div v-if="loadingRoles">Loading roles...</div>
            <table v-else class="roles-table">
              <thead>
                <tr>
                  <th>Role</th>
                  <th>Description</th>
                  <th>Documents</th>
                  <th>Quotes</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="role in roleDefinitions" :key="role.id">
                  <td>{{ role.name }}</td>
                  <td>{{ role.description || '—' }}</td>
                  <td class="perm-cell">{{ summarizePermissions(role.name, 'documents') }}</td>
                  <td class="perm-cell">{{ summarizePermissions(role.name, 'quotes') }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-if="permissionsStore.can('organization','manage_members')" style="margin-bottom:2rem;">
            <h3>Role Change History</h3>
            <div v-if="loadingAudit">Loading audit logs...</div>
            <div v-else-if="!auditLogs.length">No role changes yet.</div>
            <table v-else class="audit-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>User</th>
                  <th>Change</th>
                  <th>Changed By</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="log in auditLogs" :key="log.id">
                  <td>{{ new Date(log.created_at).toLocaleDateString() }}</td>
                  <td>{{ log.target?.email || 'Unknown' }}</td>
                  <td>{{ log.old_role }} → {{ log.new_role }}</td>
                  <td>{{ log.changer?.email || 'System' }}</td>
                </tr>
              </tbody>
            </table>
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
import { usePermissionsStore } from '@/stores/permissions'
import { supabase } from '@/lib/supabase'

const orgStore = useOrganizationStore()
const authStore = useAuthStore()
const permissionsStore = usePermissionsStore()

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
    .select('id, user_id, role, role_id, users ( email )')
    .eq('organization_id', organization.value.id)
  if (error) {
    teamMembers.value = []
    return
  }
  teamMembers.value = data.map(m => ({
    id: m.id,
    user_id: m.user_id,
    role: m.role,
    role_id: m.role_id,
    email: m.users?.email || 'Unknown',
    original_role: m.role
  }))
}

onMounted(async () => {
  if (organization.value) orgName.value = organization.value.name
  fetchTeamMembers()
  loadRoleDefinitions()
  loadPermissions()
  await permissionsStore.load()
  loadAuditLogs()
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

// ---------------------------
// Role Definitions / Permissions
// ---------------------------
const roleDefinitions = ref([])
const rolePermissions = ref([])
const loadingRoles = ref(false)
const auditLogs = ref([])
const loadingAudit = ref(false)

async function loadRoleDefinitions() {
  loadingRoles.value = true
  const { data, error } = await supabase.from('role_definitions').select('*').order('name')
  if (!error) roleDefinitions.value = data
  loadingRoles.value = false
}

async function loadPermissions() {
  const { data, error } = await supabase.from('role_permissions').select('*')
  if (!error) rolePermissions.value = data
}

async function loadAuditLogs() {
  if (!organization.value || !permissionsStore.can('organization','manage_members')) return
  loadingAudit.value = true
  const { data, error } = await supabase
    .from('role_change_audit')
    .select('*, target:auth.users!target_user_id(email), changer:auth.users!changed_by(email)')
    .eq('organization_id', organization.value.id)
    .order('created_at', { ascending: false })
    .limit(20)
  if (!error) auditLogs.value = data
  loadingAudit.value = false
}

function summarizePermissions(roleName, resource) {
  const perms = rolePermissions.value.filter(p => p.resource === resource && matchesRoleId(p.role_id, roleName))
  if (!perms.length) return '—'
  // Group actions simplifying for display
  return perms.map(p => p.action).sort().join(', ')
}

function matchesRoleId(roleId, roleName) {
  const rd = roleDefinitions.value.find(r => r.id === roleId)
  return rd ? rd.name === roleName : false
}

function canEditMember(member) {
  // Use permission instead of manual role logic
  if (!authStore.user) return false
  if (!permissionsStore.can('organization','manage_members')) return false
  // Prevent self demotion edge-case: editing own role allowed only if owner
  const myMember = teamMembers.value.find(m => m.user_id === authStore.user.id)
  if (!myMember) return false
  if (myMember.user_id === member.user_id && myMember.role !== 'owner') return false
  // Disallow changing owner if not owner
  if (member.role === 'owner' && myMember.role !== 'owner') return false
  return true
}

async function updateMemberRole(member) {
  if (!canEditMember(member)) return
  // If unchanged, skip
  if (member.role === member.original_role) return
  // Fetch role_id for selected role
  const rd = roleDefinitions.value.find(r => r.name === member.role)
  if (!rd) {
    member.role = member.original_role
    return
  }
  const { error } = await supabase
    .from('organization_members')
    .update({ role: member.role, role_id: rd.id })
    .eq('id', member.id)
  if (error) {
    member.role = member.original_role
    return
  }
  member.original_role = member.role
  loadAuditLogs() // refresh audit after role change
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

.roles-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 0.75rem;
  font-size: 0.9rem;
}
.roles-table th, .roles-table td {
  border: 1px solid var(--border-color);
  padding: 0.4rem 0.5rem;
  text-align: left;
  vertical-align: top;
}
.roles-table th {
  background: var(--bg-tertiary);
  font-weight: 600;
}
.perm-cell {
  font-family: monospace;
  white-space: normal;
}
.role-select {
  margin-left: 0.75rem;
  padding: 0.25rem 0.4rem;
  font-size: 0.8rem;
}
.audit-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 0.75rem;
  font-size: 0.9rem;
}
.audit-table th, .audit-table td {
  border: 1px solid var(--border-color);
  padding: 0.4rem 0.5rem;
  text-align: left;
}
.audit-table th {
  background: var(--bg-tertiary);
  font-weight: 600;
}
</style>
