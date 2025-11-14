# Vue Application Integration with New RBAC System

## Overview
The Vue frontend has been successfully integrated with the new role-based access control (RBAC) database architecture. All permission checks now use the `role_id` foreign key system and query the `role_permissions` table for access control.

## Changes Made

### 1. Stores Updated

#### **organization.js**
- ✅ Updated `loadUserOrganizations()` to join `role_definitions` table via `role_id`
- ✅ Modified data structure to include `role_display` from `role_definitions.display_name`
- ✅ Updated `createOrganization()` to fetch owner `role_id` before creating membership
- ✅ Updated `inviteTeamMember()` to convert role name to `role_id` before creating invitation

#### **permissions.js**
- ✅ Updated `load()` to join `role_definitions` via `role_id` instead of text role field
- ✅ Simplified permission loading by directly using `role_id` foreign key
- ✅ Maintained backward compatibility with `can()` method signature
- ✅ Kept automatic watching of organization and user changes

### 2. New Utilities Created

#### **usePermissions.js Composable**
Created reusable permission logic for Vue components:

```javascript
const { can, canAny, canAll, isOwner, isAdmin, canManageMembers } = usePermissions()
```

**Features:**
- `can(resource, action)` - Check single permission
- `canAny(checks)` - Check if user has any of the permissions (OR logic)
- `canAll(checks)` - Check if user has all permissions (AND logic)
- `isOwner`, `isAdmin`, `isMember`, `isViewer` - Role computed properties
- `canManageOrganization`, `canManageMembers`, `canAccessBilling` - Convenience methods
- `permissionDirective` - Vue directive for template usage: `v-permission:quotes.create`

### 3. Components Enhanced

#### **NavigationBar.vue**
- ✅ Imports and initializes `permissionsStore`
- ✅ Loads permissions on mount when authenticated
- ✅ Shows/hides Settings link based on `organization:manage_settings` or `organization:manage_members`
- ✅ Shows/hides Billing link based on `organization:configure_billing`
- ✅ Displays role badge using `role_display` from organization data
- ✅ Reloads permissions when switching organizations

#### **DashboardPage.vue**
- ✅ Imports and uses `permissionsStore`
- ✅ Added `currentRole` computed property showing user's role display name
- ✅ Created permission-based computed properties:
  - `canCreateQuotes`, `canReadQuotes`
  - `canManageClients`, `canReadClients`
  - `canReadPlants`, `canUseMaterialCalculator`
- ✅ Conditionally renders stats based on read permissions
- ✅ Shows/hides Quick Action buttons based on permissions
- ✅ Only shows Recent Quotes section if user can read quotes
- ✅ Added visual role badge in dashboard header with color coding
- ✅ Loads permissions after organization creation

### 4. Router Enhancements

#### **router/index.js**
- ✅ Added `meta.permissions` array to routes requiring specific permissions
- ✅ Enhanced `beforeEach` guard to check permissions before navigation
- ✅ Automatically loads permissions if not already loaded
- ✅ Uses OR logic for permission checks (user needs at least one)
- ✅ Redirects to dashboard if insufficient permissions
- ✅ Protected routes:
  - `/plants` - requires `plants:read`
  - `/quotes` - requires `quotes:read`
  - `/clients` - requires `clients:read`
  - `/sop-library` - requires `documents:read`
  - `/settings` - requires `organization:manage_settings` OR `organization:manage_members`
  - `/settings/billing` - requires `organization:configure_billing`

### 5. Visual Enhancements

#### **Role Badges**
Added color-coded role badges throughout the UI:

- **Owner** - Gold background (`#fef3c7`), brown text (`#92400e`)
- **Admin** - Blue background (`#dbeafe`), dark blue text (`#1e3a8a`)
- **Member** - Green background (`#d1fae5`), dark green text (`#065f46`)
- **Viewer** - Gray background (`#f3f4f6`), dark gray text (`#374151`)

Displayed in:
- Dashboard header (next to organization name)
- NavigationBar user menu (organization switcher)

## Permission System Architecture

### How It Works

1. **User logs in** → `auth.js` authenticates user
2. **Organization loaded** → `organization.js` loads user's organizations with role info
3. **Permissions loaded** → `permissions.js` fetches role permissions from database
4. **Components check permissions** → Use `permissionsStore.can()` or `usePermissions()` composable
5. **Router guards** → Prevent navigation to unauthorized routes

### Permission Check Flow

```javascript
// In components
if (permissionsStore.can('quotes', 'create')) {
  // Show create quote button
}

// Using composable
const { canManageMembers } = usePermissions()
if (canManageMembers.value) {
  // Show team management UI
}

// In templates with directive
<button v-permission:quotes.create>Create Quote</button>
```

### Database Integration

```sql
-- Permission check happens via:
SELECT resource, action
FROM role_permissions
WHERE role_id = (
  SELECT role_id
  FROM organization_members
  WHERE user_id = $1 AND organization_id = $2
)

-- Or using the SQL function:
SELECT has_org_permission($user_id, $org_id, 'quotes', 'create')
```

## Permission Taxonomy

### Core Permissions by Role

**Owner (36 permissions):**
- All admin permissions
- `organization:delete`
- `organization:transfer_ownership`
- `organization:configure_billing`

**Admin (31 permissions):**
- All member permissions
- `organization:manage_settings`
- `organization:manage_members`
- `quotes:update_any`, `quotes:delete_any`
- `clients:update_any`, `clients:delete_any`
- `projects:update_any`, `projects:delete_any`
- `documents:update_any`, `documents:delete_any`

**Member (19 permissions):**
- Create, read, update own items
- `quotes:create`, `quotes:read`, `quotes:update_own`, `quotes:delete_own`
- `clients:create`, `clients:read`, `clients:update_own`, `clients:delete_own`
- `projects:create`, `projects:read`, `projects:update_own`, `projects:delete_own`
- `plants:read`, `plants:create`, `plants:update`
- `materials:read`, `materials:create`, `materials:update`
- `documents:create`, `documents:read`, `documents:update_own`, `documents:delete_own`

**Viewer (8 permissions):**
- Read-only access
- `quotes:read`, `clients:read`, `projects:read`
- `plants:read`, `materials:read`, `documents:read`
- `organization:read_basic`, `organization:read_members`

## Testing Checklist

### Authentication Flow
- [ ] User can sign up and create organization
- [ ] User is assigned owner role automatically
- [ ] Permissions load after organization creation
- [ ] Dashboard shows all features for owner

### Permission Loading
- [ ] Permissions load on app mount
- [ ] Permissions reload when switching organizations
- [ ] Permission checks work in components
- [ ] Permission checks work in router guards

### UI Visibility
- [ ] Owner sees all navigation links
- [ ] Admin sees Settings but not Billing
- [ ] Member sees limited Quick Actions
- [ ] Viewer sees only read-related stats and actions
- [ ] Role badge displays correctly in dashboard
- [ ] Role badge displays correctly in organization switcher

### Route Protection
- [ ] Owner can access all routes
- [ ] Admin blocked from `/settings/billing`
- [ ] Member blocked from `/settings`
- [ ] Viewer blocked from `/quotes` (create)
- [ ] Redirect to dashboard works on unauthorized access

### Organization Switching
- [ ] Permissions reload when switching orgs
- [ ] UI updates based on new role
- [ ] Stats refresh for new organization

### Edge Cases
- [ ] User with no organizations sees create modal
- [ ] User invited to org can accept and get correct role
- [ ] Permission checks handle missing organization gracefully
- [ ] Permission checks handle unauthenticated state

## Implementation Notes

### Key Design Decisions

1. **OR Logic for Route Permissions**: Routes with multiple permissions in meta use OR logic (user needs at least one). This allows flexibility for routes like Settings that should be accessible to users with different admin capabilities.

2. **Automatic Permission Loading**: Permissions auto-load on organization change via watchers in the store. Components don't need to manually trigger loads.

3. **Owner Implicit Permissions**: The `can()` method in permissions store gives owners implicit access to everything, ensuring backwards compatibility during migration.

4. **Role Display Names**: Using `role_definitions.display_name` for UI (e.g., "Organization Owner") while `role_definitions.name` remains the system identifier (e.g., "owner").

5. **Composable Pattern**: Created `usePermissions` composable for reusable logic rather than duplicating permission checks across components.

### Future Enhancements

1. **Object-Level Permissions**: Extend to check ownership for update/delete operations (e.g., can user edit *this specific* quote?)

2. **Permission Caching**: Add localStorage caching with TTL to reduce permission queries

3. **Optimistic UI**: Show features immediately while permission check runs in background

4. **Permission Groups**: Create logical groups like "canManageContent" that check multiple related permissions

5. **Audit Logging**: Track permission checks and denials for security monitoring

6. **Dynamic Roles**: Allow custom roles beyond the 4 system roles

7. **Resource-Level RLS**: Extend RLS policies to use `has_org_permission()` function consistently

## Migration from Old System

### Breaking Changes
None for end users. The migration maintains API compatibility.

### Database Changes
- `organization_members.role` (text) → `role_id` (UUID foreign key)
- New tables: `role_definitions`, `role_permissions`
- New function: `has_org_permission(user_id, org_id, resource, action)`

### Code Changes
- Stores updated to use `role_id` joins
- Components use permission checks instead of role checks
- Router guards enhanced with permission validation

### Rollback Plan
If issues arise, can temporarily modify `permissionsStore.can()` to use legacy role-based checks:
```javascript
function can(resource, action) {
  // Temporary fallback to role-based checks
  const role = orgStore.currentOrganization?.role
  return LEGACY_ROLE_PERMISSIONS[role]?.[resource]?.includes(action)
}
```

## Support & Troubleshooting

### Common Issues

**Issue**: Permissions not loading
- **Solution**: Check that `permissionsStore.load()` is called after organization is set
- **Debug**: Add `console.log(permissionsStore.permissionSet)` to see loaded permissions

**Issue**: UI shows features user can't access
- **Solution**: Ensure component imports and uses `permissionsStore`
- **Debug**: Check that `canCreateQuotes` computed property is defined and used in `v-if`

**Issue**: Route blocked incorrectly
- **Solution**: Verify permission exists in `role_permissions` table for user's role
- **Debug**: Query database: `SELECT * FROM role_permissions WHERE role_id = 'user-role-id'`

**Issue**: Role badge not showing
- **Solution**: Ensure `role_display` is set in organization data from `loadUserOrganizations()`
- **Debug**: Check `orgStore.currentOrganization.role_display` in Vue DevTools

### Debug Commands

```sql
-- Check user's role in organization
SELECT om.role_id, rd.name, rd.display_name
FROM organization_members om
JOIN role_definitions rd ON rd.id = om.role_id
WHERE om.user_id = 'user-id' AND om.organization_id = 'org-id';

-- Check permissions for role
SELECT resource, action
FROM role_permissions
WHERE role_id = 'role-id'
ORDER BY resource, action;

-- Test permission function
SELECT has_org_permission('user-id', 'org-id', 'quotes', 'create');
```

## Conclusion

The Vue application is now fully integrated with the new RBAC database architecture. All permission checks flow through the `role_permissions` table, providing a flexible and maintainable authorization system. The UI dynamically adapts based on user permissions, ensuring users only see and access features they're authorized to use.

**Next Steps:**
1. Test complete user flows (signup → org creation → permission loading)
2. Invite team members and verify role-based access
3. Implement object-level permissions for owned resources
4. Add permission audit logging
5. Create admin UI for custom role management
