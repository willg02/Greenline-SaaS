# Phase 0 Roles & Permissions Rollout Strategy

This document outlines the incremental steps to fully adopt the new role + permission system introduced in `roles_phase0.sql` and `roles_phase0_extend.sql` while minimizing risk and ensuring a clean migration path.

## Goals
- Replace hardcoded role checks (owner/admin/member) across UI with permission-based gating.
- Maintain backward compatibility during transition (legacy policies coexist with phase0_ policies).
- Provide easy rollback until final cut-over.
- Avoid breaking existing organization member management flows.

## Sequence Overview
1. Foundation (Completed)
   - Tables: `role_definitions`, `role_permissions`.
   - Column: `organization_members.role_id` added & backfilled.
   - Function: `has_org_permission(org_id, resource, action)`.
   - Seed permissions: organization, clients, documents, quotes.
   - Phase0 policies: clients, documents, document_permissions, quotes.
   - UI: Role table + role editing.
2. Permission Abstraction (In Progress)
   - Add frontend `permissions` store (`can(resource, action)` helper).
   - Hook into organization selection & user membership.
3. UI Gating (Pending)
   - Replace `isOwner/isAdmin` checks with `can()` where appropriate.
   - Gate create buttons (documents, quotes, clients) by `create` action.
   - Gate update/delete flows by `update_any/delete_any` or `update_own/delete_own` (ownership via `created_by`).
   - Gate publish/document permission management by `publish` / `manage_permissions` actions.
   - Gate team invite & role change by `manage_members`.
   - Gate billing controls by `configure_billing` (owner only).
4. Policy Cut-over (Pending)
   - Validate new phase0 policies produce identical result sets under typical user roles.
   - Drop legacy policies (non phase0_) after validation.
   - Rename phase0 policies to final names (remove prefix) for clarity.
5. Legacy Field Cleanup (Pending)
   - Remove `organization_members.role` TEXT column (after ensuring all code uses `role_id` + join).
6. Extended Resources (Optional Next)
   - Plants, materials, folders, document_versions, quote_items.
   - Add corresponding permission seeds + policies.
7. Auditing & Observability (Optional)
   - Add audit log for role changes & permission modifications.
   - Add monitoring query or Supabase function to list orphaned memberships (role_id null).

## Detailed Steps

### Step 2: Permission Store
- Implement Pinia store: loads current membership row (organization_id + user_id) retrieving `role_id`.
- Query `role_permissions` filtered by `role_id` into local set.
- Expose `can(resource, action)` returning boolean.
- Listen to organization changes (re-load permissions).

### Step 3: UI Gating Pass
- Inventory actionable UI elements: create/edit/delete/publish buttons; settings sections; invite forms.
- Wrap each with `v-if="permissions.can('documents','create')"` pattern.
- Fallback placeholder (disabled state + tooltip) for unauthorized actions.

### Step 4: Policy Validation
Execute sample queries manually for each role to compare legacy vs phase0 results:
```sql
-- Documents SELECT parity check
EXPLAIN ANALYZE SELECT id FROM documents WHERE organization_id = '<org>';
-- Ensure counts match between enabling/disabling phase0 policies (temporarily comment out if needed).
```

### Step 5: Dropping Legacy Policies
- Script to `DROP POLICY` for each original non phase0 policy.
- Rename phase0 policies to concise names (e.g., `phase0_documents_select` -> `documents_select`).

### Rollback Plan
- If issues detected before final cut-over: revert UI gating (switch to old role-based checks), drop phase0 policies, keep original ones.
- Keep `role_id` column even if rolled back (harmless); can remove later.

## Risk Mitigations
- Parallel policies allow safe comparison.
- No destructive operations performed yet (legacy column still present).
- UI gating uses additive approach; failure fallback is still owner/admin string logic until fully removed.

## Completion Criteria
- All create/edit/delete/publish actions hidden appropriately per role.
- Legacy policies removed & phase0 renamed.
- No references to `organization_members.role` remain in codebase.
- Documentation updated reflecting new permission system for developers.

## Future (Phase 1+ Preview)
- Custom role creation UI: define new roles, assign permissions via multi-select.
- Per-document granular overrides (object-level ACL) replacing `document_permissions` global role matrix.
- Audit trail for permission changes.

## Tracking Checklist
- [ ] Permission store implemented
- [ ] Documents UI gated
- [ ] Quotes UI gated
- [ ] Clients UI gated
- [ ] Organization settings gated (invites, role edits, billing)
- [ ] Legacy policies dropped
- [ ] Policies renamed
- [ ] Legacy `role` column removed
- [ ] Developer docs updated

