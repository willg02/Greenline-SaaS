-- ============================================================================
-- Migration: 009 - Create RLS Policies for Core Tables
-- Description: Row Level Security policies for organizations, members, roles
-- Dependencies: 008_create_permission_function.sql
-- ============================================================================

-- ============================================
-- ORGANIZATIONS POLICIES
-- ============================================

-- SELECT: Can see organizations you're a member of
CREATE POLICY "organizations_select"
  ON organizations FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
        AND user_id = auth.uid()
    )
  );

-- INSERT: Anyone can create an organization (becomes owner)
CREATE POLICY "organizations_insert"
  ON organizations FOR INSERT TO authenticated
  WITH CHECK (
    owner_id = auth.uid()
  );

-- UPDATE: Only owner or those with manage_settings permission
CREATE POLICY "organizations_update"
  ON organizations FOR UPDATE TO authenticated
  USING (
    owner_id = auth.uid()
    OR has_org_permission(id, 'organization', 'manage_settings')
  )
  WITH CHECK (
    owner_id = auth.uid()
    OR has_org_permission(id, 'organization', 'manage_settings')
  );

-- DELETE: Only owner can soft-delete
CREATE POLICY "organizations_delete"
  ON organizations FOR UPDATE TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ============================================
-- ORGANIZATION_MEMBERS POLICIES
-- ============================================

-- SELECT: Can see members of your organizations
CREATE POLICY "org_members_select"
  ON organization_members FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.organization_id = organization_members.organization_id
        AND om.user_id = auth.uid()
    )
  );

-- INSERT: Those with manage_members permission can add members
CREATE POLICY "org_members_insert"
  ON organization_members FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'organization', 'manage_members')
  );

-- UPDATE: Those with manage_members permission can update roles
CREATE POLICY "org_members_update"
  ON organization_members FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'organization', 'manage_members')
  )
  WITH CHECK (
    has_org_permission(organization_id, 'organization', 'manage_members')
  );

-- DELETE: Those with manage_members permission can remove members
CREATE POLICY "org_members_delete"
  ON organization_members FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'organization', 'manage_members')
  );

-- ============================================
-- ORGANIZATION_INVITATIONS POLICIES
-- ============================================

-- SELECT: Members can view invitations for their org
CREATE POLICY "invitations_select"
  ON organization_invitations FOR SELECT TO authenticated
  USING (
    has_org_permission(organization_id, 'invitations', 'read')
  );

-- INSERT: Those with create permission can send invitations
CREATE POLICY "invitations_insert"
  ON organization_invitations FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'invitations', 'create')
    AND invited_by = auth.uid()
  );

-- UPDATE: Those with delete_any permission can update status
CREATE POLICY "invitations_update"
  ON organization_invitations FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'invitations', 'delete_any')
  )
  WITH CHECK (
    has_org_permission(organization_id, 'invitations', 'delete_any')
  );

-- DELETE: Those with delete_any permission can revoke invitations
CREATE POLICY "invitations_delete"
  ON organization_invitations FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'invitations', 'delete_any')
  );

-- ============================================
-- ROLE SYSTEM POLICIES (Read-only for most users)
-- ============================================

-- SELECT: All authenticated users can view role definitions
CREATE POLICY "role_definitions_select"
  ON role_definitions FOR SELECT TO authenticated
  USING (true);

-- SELECT: All authenticated users can view role permissions
CREATE POLICY "role_permissions_select"
  ON role_permissions FOR SELECT TO authenticated
  USING (true);

-- Note: INSERT/UPDATE/DELETE for roles should be admin-only via service role
-- Not exposed through RLS to regular users
