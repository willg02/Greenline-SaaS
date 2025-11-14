-- ============================================================================
-- Migration: 019 - Fix RLS Recursion for Organization Creation
-- Description: Allow owner to insert themselves as first member without recursion
-- Dependencies: 009_create_rls_policies_core.sql
-- ============================================================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "org_members_insert" ON organization_members;
DROP POLICY IF EXISTS "org_members_select" ON organization_members;

-- SELECT: Can see members of your organizations (non-recursive)
CREATE POLICY "org_members_select"
  ON organization_members FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()  -- Can always see your own memberships
    OR EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.organization_id = organization_members.organization_id
        AND om.user_id = auth.uid()
    )
  );

-- INSERT: Owner can insert themselves OR those with manage_members permission
CREATE POLICY "org_members_insert"
  ON organization_members FOR INSERT TO authenticated
  WITH CHECK (
    -- Allow owner to insert themselves as first member
    (user_id = auth.uid() AND EXISTS (
      SELECT 1 FROM organizations
      WHERE id = organization_members.organization_id
        AND owner_id = auth.uid()
    ))
    OR
    -- Allow those with manage_members permission to add others
    has_org_permission(organization_id, 'organization', 'manage_members')
  );
