-- Complete RLS Policy Fix for Organization Creation
-- This script fixes all RLS policy issues preventing organization creation
-- Run this in your Supabase SQL Editor

-- ============================================
-- STEP 1: DROP FUNCTION AND ALL DEPENDENT POLICIES
-- ============================================

-- Drop the function with CASCADE to remove all dependent policies
DROP FUNCTION IF EXISTS is_organization_member(UUID, UUID) CASCADE;

-- Also explicitly drop any remaining policies just to be safe
DROP POLICY IF EXISTS "Users can view their organizations" ON organizations;
DROP POLICY IF EXISTS "Users can insert organizations" ON organizations;
DROP POLICY IF EXISTS "Users can create organizations" ON organizations;
DROP POLICY IF EXISTS "Users can update organizations they own" ON organizations;
DROP POLICY IF EXISTS "Owners can update their organizations" ON organizations;

DROP POLICY IF EXISTS "Users can view members of their organizations" ON organization_members;
DROP POLICY IF EXISTS "Owners and admins can manage members" ON organization_members;
DROP POLICY IF EXISTS "Members can view their org members" ON organization_members;
DROP POLICY IF EXISTS "Members can view org members" ON organization_members;
DROP POLICY IF EXISTS "Users can create memberships" ON organization_members;
DROP POLICY IF EXISTS "Owners can update member roles" ON organization_members;
DROP POLICY IF EXISTS "Owners can remove members" ON organization_members;

-- ============================================
-- STEP 2: CREATE HELPER FUNCTION (SECURITY DEFINER)
-- ============================================

-- This function bypasses RLS to check membership without recursion
CREATE FUNCTION is_organization_member(org_id UUID, check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 3: CREATE NEW ORGANIZATIONS POLICIES
-- ============================================

-- Allow users to view organizations they're members of
CREATE POLICY "Users can view their organizations"
  ON organizations FOR SELECT
  USING (
    is_organization_member(id, auth.uid())
  );

-- Allow any authenticated user to create an organization (becomes owner)
-- This is the key fix - no membership check during creation!
CREATE POLICY "Users can create organizations"
  ON organizations FOR INSERT
  WITH CHECK (
    owner_id = auth.uid()
  );

-- Allow owners to update their organizations
CREATE POLICY "Owners can update their organizations"
  ON organizations FOR UPDATE
  USING (
    owner_id = auth.uid()
  );

-- ============================================
-- STEP 4: CREATE NEW ORGANIZATION_MEMBERS POLICIES
-- ============================================

-- Allow users to view members of organizations they belong to
CREATE POLICY "Members can view org members"
  ON organization_members FOR SELECT
  USING (
    is_organization_member(organization_id, auth.uid())
  );

-- Allow users to insert themselves OR allow org owners to add others
-- In INSERT WITH CHECK, bare column names refer to the new row being inserted
CREATE POLICY "Users can create memberships"
  ON organization_members FOR INSERT
  WITH CHECK (
    -- User adding themselves: the user_id being inserted matches auth.uid()
    user_id = auth.uid()
    OR 
    -- Or the authenticated user is the owner of the organization being joined
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = organization_id
      AND owner_id = auth.uid()
    )
  );

-- Allow org owners to update member roles
CREATE POLICY "Owners can update member roles"
  ON organization_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = organization_members.organization_id
      AND organizations.owner_id = auth.uid()
    )
  );

-- Allow org owners to remove members
CREATE POLICY "Owners can remove members"
  ON organization_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = organization_members.organization_id
      AND organizations.owner_id = auth.uid()
    )
  );

-- ============================================
-- VERIFICATION QUERY (Optional - Run after to test)
-- ============================================
-- SELECT tablename, policyname, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename IN ('organizations', 'organization_members')
-- ORDER BY tablename, policyname;

