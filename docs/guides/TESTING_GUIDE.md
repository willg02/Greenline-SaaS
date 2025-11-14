# Testing Guide - New RBAC System

## Prerequisites
- Supabase database with all 18 migrations applied
- Vue development server running (`npm run dev`)
- Clear browser cache and localStorage

## Test Scenarios

### 1. New User Signup & Organization Creation

**Steps:**
1. Navigate to signup page
2. Create new account with email/password
3. After signup, should redirect to dashboard
4. Dashboard should show "Create Your Organization" modal
5. Enter organization name (e.g., "Test Landscaping Co")
6. Click "Create Organization"

**Expected Results:**
- ✅ Organization created successfully
- ✅ User assigned as owner (role_id points to owner role)
- ✅ Dashboard loads with owner badge visible
- ✅ All navigation links visible (Settings, Billing, etc.)
- ✅ All Quick Actions visible (Create Quote, Add Client, etc.)
- ✅ All stats cards visible

**Verification Queries:**
```sql
-- Check organization was created
SELECT * FROM organizations WHERE name = 'Test Landscaping Co';

-- Check user is owner
SELECT om.*, rd.name as role_name, rd.display_name
FROM organization_members om
JOIN role_definitions rd ON rd.id = om.role_id
WHERE om.user_id = 'your-user-id';

-- Should return 36 permissions for owner
SELECT COUNT(*) FROM role_permissions rp
JOIN organization_members om ON om.role_id = rp.role_id
WHERE om.user_id = 'your-user-id';
```

---

### 2. Owner Permissions Test

**Steps (as Owner):**
1. Check navigation bar - should see Settings and Billing links
2. Navigate to Dashboard - should see role badge "Owner" (gold)
3. Check Quick Actions - should see all 4 actions
4. Navigate to `/settings` - should load successfully
5. Navigate to `/settings/billing` - should load successfully
6. Navigate to `/quotes` - should load successfully
7. Navigate to `/clients` - should load successfully

**Expected Results:**
- ✅ All routes accessible
- ✅ All UI elements visible
- ✅ Role badge shows "Owner" with gold styling
- ✅ Organization switcher shows "owner" badge next to org name

**Console Check:**
```javascript
// In browser DevTools console
$pinia.state.value.permissions.roleName // Should be 'owner'
$pinia.state.value.permissions.permissionSet.size // Should be 36
```

---

### 3. Invite Admin User

**Steps (as Owner):**
1. Navigate to Settings → Team Management
2. Click "Invite Team Member"
3. Enter email: `admin@test.com`
4. Select role: "Admin"
5. Send invitation

**Expected Results:**
- ✅ Invitation created in `invitations` table
- ✅ `role_id` field set to admin role UUID (not text)
- ✅ Invitation email sent (if configured)

**Verification Query:**
```sql
-- Check invitation
SELECT i.*, rd.name as role_name
FROM invitations i
JOIN role_definitions rd ON rd.id = i.role_id
WHERE i.email = 'admin@test.com';
```

---

### 4. Admin User Acceptance & Permissions

**Steps (as invited admin):**
1. Sign up with invited email
2. Accept invitation
3. Verify role badge shows "Admin" (blue)
4. Check navigation - Settings visible, Billing hidden
5. Try to access `/settings/billing` directly

**Expected Results:**
- ✅ User added to organization_members with admin role_id
- ✅ Role badge shows "Admin" with blue styling
- ✅ Settings link visible in navigation
- ✅ Billing link hidden in navigation
- ✅ Direct navigation to `/settings/billing` redirects to dashboard
- ✅ 31 permissions loaded for admin

**Console Check:**
```javascript
$pinia.state.value.permissions.roleName // Should be 'admin'
$pinia.state.value.permissions.permissionSet.size // Should be 31
$pinia.state.value.permissions.can('organization', 'configure_billing') // Should be false
```

---

### 5. Member Permissions Test

**Steps:**
1. Invite user as "Member"
2. Accept invitation and log in
3. Check Dashboard - should see "Member" badge (green)
4. Verify Quick Actions limited
5. Try to access `/settings`

**Expected Results:**
- ✅ Role badge shows "Member" with green styling
- ✅ Quick Actions shows Create Quote, Browse Plants, Material Calculator
- ✅ Add Client button hidden (members can't create clients in current schema)
- ✅ Settings link hidden in navigation
- ✅ Direct navigation to `/settings` redirects to dashboard
- ✅ 19 permissions loaded

**Permissions to Test:**
```javascript
// These should be true
$pinia.state.value.permissions.can('quotes', 'create') // true
$pinia.state.value.permissions.can('quotes', 'read') // true
$pinia.state.value.permissions.can('plants', 'read') // true

// These should be false
$pinia.state.value.permissions.can('organization', 'manage_settings') // false
$pinia.state.value.permissions.can('clients', 'delete_any') // false
```

---

### 6. Viewer Permissions Test

**Steps:**
1. Invite user as "Viewer"
2. Accept invitation and log in
3. Check Dashboard - should see "Viewer" badge (gray)
4. Verify extremely limited UI
5. Try to access various routes

**Expected Results:**
- ✅ Role badge shows "Viewer" with gray styling
- ✅ Quick Actions section shows only "Browse Plants" and "Material Calculator"
- ✅ "Create New Quote" and "Add Client" hidden
- ✅ Can view `/plants` (read-only)
- ✅ Can view `/quotes` list but can't create
- ✅ Can't access `/settings`
- ✅ 8 permissions loaded

**Read-Only Verification:**
```javascript
// These should be true
$pinia.state.value.permissions.can('quotes', 'read') // true
$pinia.state.value.permissions.can('clients', 'read') // true
$pinia.state.value.permissions.can('plants', 'read') // true

// These should be false
$pinia.state.value.permissions.can('quotes', 'create') // false
$pinia.state.value.permissions.can('quotes', 'update_any') // false
$pinia.state.value.permissions.can('clients', 'create') // false
```

---

### 7. Organization Switching

**Steps:**
1. Create second organization as owner
2. Open organization switcher in navigation
3. Switch to second organization
4. Verify role badge updates
5. Verify permissions reload

**Expected Results:**
- ✅ Organization switcher shows both orgs with role badges
- ✅ Clicking different org switches context
- ✅ Dashboard shows new organization name
- ✅ Stats refresh for new organization
- ✅ Permissions reload automatically
- ✅ Role badge updates if user has different role in new org

**Console Verification:**
```javascript
// Watch for organization change
$pinia.state.value.organization.organizationId
// Should change when switching

// Permissions should reload
$pinia.state.value.permissions.initializedForOrg
// Should match new organization ID
```

---

### 8. Direct Navigation Permission Check

**Steps (as Member):**
1. Copy URL: `http://localhost:5173/settings/billing`
2. Paste in address bar and press Enter

**Expected Results:**
- ✅ Route guard blocks navigation
- ✅ User redirected to `/dashboard`
- ✅ No error in console

**Steps (as Admin):**
1. Copy URL: `http://localhost:5173/settings/billing`
2. Paste in address bar and press Enter

**Expected Results:**
- ✅ Route guard blocks navigation (admin lacks `configure_billing`)
- ✅ User redirected to `/dashboard`

**Steps (as Owner):**
1. Copy URL: `http://localhost:5173/settings/billing`
2. Paste in address bar and press Enter

**Expected Results:**
- ✅ Page loads successfully
- ✅ Owner can access billing

---

### 9. Permission Loading Edge Cases

**Test A: No Organization**
1. Create user but don't create organization
2. Check dashboard

**Expected:**
- ✅ Shows "Create Your Organization" modal
- ✅ No permission checks attempted
- ✅ No errors in console

**Test B: Multiple Organizations**
1. User is member of Org A (as member) and Org B (as admin)
2. Switch between organizations
3. Verify UI updates

**Expected:**
- ✅ Permissions reload on switch
- ✅ UI shows member features in Org A
- ✅ UI shows admin features in Org B

**Test C: Logout/Login**
1. Log out
2. Log back in
3. Verify permissions reload

**Expected:**
- ✅ Permissions load on mount
- ✅ No stale permission data from previous session

---

## Automated Testing Script

Run in browser console after logging in:

```javascript
// Quick Permission Test
const permStore = $pinia.state.value.permissions;
const orgStore = $pinia.state.value.organization;

console.log('=== Permission Test Results ===');
console.log('Current Role:', permStore.roleName);
console.log('Role ID:', permStore.roleId);
console.log('Organization:', orgStore.currentOrganization?.name);
console.log('Permission Count:', permStore.permissionSet.size);
console.log('\n=== Sample Permission Checks ===');
console.log('Can create quotes:', permStore.can('quotes', 'create'));
console.log('Can read clients:', permStore.can('clients', 'read'));
console.log('Can manage settings:', permStore.can('organization', 'manage_settings'));
console.log('Can configure billing:', permStore.can('organization', 'configure_billing'));
console.log('Can delete any quotes:', permStore.can('quotes', 'delete_any'));
console.log('\n=== All Permissions ===');
console.log([...permStore.permissionSet]);
```

---

## Database Verification Queries

### Check User's Current Role
```sql
SELECT 
  u.email,
  o.name as organization,
  rd.name as role,
  rd.display_name,
  om.joined_at
FROM organization_members om
JOIN auth.users u ON u.id = om.user_id
JOIN organizations o ON o.id = om.organization_id
JOIN role_definitions rd ON rd.id = om.role_id
WHERE u.email = 'your-email@example.com';
```

### Check All Permissions for Role
```sql
SELECT 
  rd.name as role,
  rp.resource,
  rp.action
FROM role_permissions rp
JOIN role_definitions rd ON rd.id = rp.role_id
WHERE rd.name = 'member'  -- or 'owner', 'admin', 'viewer'
ORDER BY rp.resource, rp.action;
```

### Verify Permission Function
```sql
SELECT has_org_permission(
  'user-uuid'::uuid,
  'org-uuid'::uuid,
  'quotes',
  'create'
);
```

### Check Invitation Status
```sql
SELECT 
  i.email,
  i.status,
  i.expires_at,
  rd.name as invited_as_role,
  o.name as organization
FROM invitations i
JOIN organizations o ON o.id = i.organization_id
JOIN role_definitions rd ON rd.id = i.role_id
WHERE i.email = 'invited@example.com';
```

---

## Common Issues & Solutions

### Issue: Permissions not loading
**Symptoms:** UI shows nothing, no error
**Solution:** 
1. Check browser console for errors
2. Verify `permissionsStore.load()` is called in component's `onMounted`
3. Check network tab - should see query to `organization_members` and `role_permissions`

### Issue: Wrong role badge showing
**Symptoms:** Shows "Member" but user is owner
**Solution:**
1. Check `organization.js` correctly joins `role_definitions`
2. Verify `role_display` is set in organization data
3. Check `organization_members.role_id` points to correct role

### Issue: Can access unauthorized routes
**Symptoms:** Member can access `/settings`
**Solution:**
1. Verify router guard imports `usePermissionsStore`
2. Check route has `meta.permissions` array
3. Ensure `permissionsStore.load()` is called before check

### Issue: All features hidden
**Symptoms:** Owner sees nothing in dashboard
**Solution:**
1. Check permission count in console (should be 36 for owner)
2. Verify `role_permissions` table has all 36 entries for owner role
3. Run seed script if permissions missing: `supabase db push`

---

## Success Criteria

✅ **New User Flow**
- Sign up → Create org → See owner UI → All features visible

✅ **Permission Enforcement**
- Owner: Full access (36 permissions)
- Admin: No billing access (31 permissions)
- Member: Limited create access (19 permissions)
- Viewer: Read-only access (8 permissions)

✅ **UI Adaptation**
- Navigation links show/hide based on permissions
- Quick Actions filtered by role
- Stats visible only if user can read data
- Role badges display with correct colors

✅ **Route Protection**
- Unauthorized routes redirect to dashboard
- No console errors on blocked navigation
- Permission checks happen before route loads

✅ **Organization Switching**
- Permissions reload automatically
- UI updates based on role in new org
- No stale data from previous org

✅ **Edge Cases**
- No organization: Shows create modal
- Multiple organizations: Switches correctly
- Logout/Login: Fresh permission load

---

## Performance Benchmarks

**Permission Load Time:**
- Should complete in < 500ms
- Network requests: 2 (membership + permissions)

**UI Render Time:**
- Permission-based v-if should not cause visible lag
- Role badge should appear immediately

**Route Guard:**
- Permission check should complete in < 100ms
- No flash of unauthorized content

---

## Next Steps After Testing

1. **Fix any failing tests** - Update migrations or code as needed
2. **Add error handling** - Show user-friendly messages for permission errors
3. **Implement audit logging** - Track permission checks and denials
4. **Create admin UI** - Allow owners to manage custom roles and permissions
5. **Add object-level permissions** - Check ownership for specific records
6. **Optimize permission loading** - Cache permissions in localStorage with TTL
7. **Add permission tooltips** - Explain why features are hidden

---

## Feedback & Bug Reports

When reporting issues, include:
- User role (owner/admin/member/viewer)
- Organization context
- Browser console output
- Network tab showing API calls
- Expected vs actual behavior
- Steps to reproduce

**Quick Debug Export:**
```javascript
// Copy this output when reporting bugs
JSON.stringify({
  role: $pinia.state.value.permissions.roleName,
  roleId: $pinia.state.value.permissions.roleId,
  permCount: $pinia.state.value.permissions.permissionSet.size,
  orgId: $pinia.state.value.organization.organizationId,
  orgName: $pinia.state.value.organization.organizationName,
  userId: $pinia.state.value.auth.user?.id,
  permissions: [...$pinia.state.value.permissions.permissionSet]
}, null, 2)
```
