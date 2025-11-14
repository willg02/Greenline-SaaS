-- SIMPLE RLS FIX - No recursion, no complexity
-- This uses the simplest possible policies that actually work
-- Run this in your Supabase SQL Editor

-- ============================================
-- STEP 1: CLEAN SLATE
-- ============================================

-- Drop everything
DROP FUNCTION IF EXISTS is_organization_member(UUID, UUID) CASCADE;

DROP POLICY IF EXISTS "Users can view their organizations" ON organizations;
DROP POLICY IF EXISTS "Users can insert organizations" ON organizations;
DROP POLICY IF EXISTS "Users can create organizations" ON organizations;
DROP POLICY IF EXISTS "Users can update organizations they own" ON organizations;
DROP POLICY IF EXISTS "Owners can update their organizations" ON organizations;
DROP POLICY IF EXISTS "authenticated_users_can_create_orgs" ON organizations;
DROP POLICY IF EXISTS "users_can_view_owned_orgs" ON organizations;
DROP POLICY IF EXISTS "owners_can_update_orgs" ON organizations;

DROP POLICY IF EXISTS "Users can view members of their organizations" ON organization_members;
DROP POLICY IF EXISTS "Owners and admins can manage members" ON organization_members;
DROP POLICY IF EXISTS "Members can view their org members" ON organization_members;
DROP POLICY IF EXISTS "Members can view org members" ON organization_members;
DROP POLICY IF EXISTS "Users can create memberships" ON organization_members;
DROP POLICY IF EXISTS "Owners can update member roles" ON organization_members;
DROP POLICY IF EXISTS "Owners can remove members" ON organization_members;
DROP POLICY IF EXISTS "users_can_join_or_owners_can_add" ON organization_members;
DROP POLICY IF EXISTS "members_can_view_fellow_members" ON organization_members;
DROP POLICY IF EXISTS "owners_can_manage_members" ON organization_members;
DROP POLICY IF EXISTS "owners_can_remove_members" ON organization_members;

-- ============================================
-- STEP 2: CREATE SECURITY DEFINER FUNCTION
-- ============================================
-- This bypasses RLS to prevent recursion

CREATE OR REPLACE FUNCTION public.user_is_member_of_org(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- STEP 3: ORGANIZATIONS - SIMPLE POLICIES
-- ============================================

-- Anyone authenticated can create an organization
CREATE POLICY "authenticated_users_can_create_orgs"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

-- Users can view organizations they own or are members of
CREATE POLICY "users_can_view_owned_orgs"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR
    user_is_member_of_org(id)
  );

-- Owners can update their organizations
CREATE POLICY "owners_can_update_orgs"
  ON organizations FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ============================================
-- STEP 4: ORGANIZATION_MEMBERS - SIMPLE POLICIES
-- ============================================

-- Users can add themselves OR owners can add anyone
CREATE POLICY "users_can_join_or_owners_can_add"
  ON organization_members FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Scenario 1: User adding themselves (during org creation)
    user_id = auth.uid()
    OR
    -- Scenario 2: Organization owner adding someone
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = organization_members.organization_id
      AND organizations.owner_id = auth.uid()
    )
  );

-- Users can view members of organizations they belong to
-- Using the SECURITY DEFINER function to avoid recursion
CREATE POLICY "members_can_view_fellow_members"
  ON organization_members FOR SELECT
  TO authenticated
  USING (
    user_is_member_of_org(organization_id)
  );

-- Owners can update member roles
CREATE POLICY "owners_can_manage_members"
  ON organization_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = organization_members.organization_id
      AND organizations.owner_id = auth.uid()
    )
  );

-- Owners can remove members
CREATE POLICY "owners_can_remove_members"
  ON organization_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = organization_members.organization_id
      AND organizations.owner_id = auth.uid()
    )
  );

-- ============================================
-- DONE! Test by creating an organization
-- ============================================
