-- Fix infinite recursion in organization_members RLS policies
-- Run this in your Supabase SQL Editor

-- Drop the problematic policies
DROP POLICY IF EXISTS "Users can view members of their organizations" ON organization_members;
DROP POLICY IF EXISTS "Owners and admins can manage members" ON organization_members;

-- Create a helper function to check organization membership without recursion
CREATE OR REPLACE FUNCTION is_organization_member(org_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Now create simplified policies using the function

-- Allow users to view all members of organizations they belong to
CREATE POLICY "Members can view their org members"
  ON organization_members FOR SELECT
  USING (
    is_organization_member(organization_id, auth.uid())
  );

-- Allow users to insert themselves as members (for org creation)
-- Or allow org owners to insert new members
CREATE POLICY "Users can create memberships"
  ON organization_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = organization_id
      AND owner_id = auth.uid()
    )
  );

-- Allow owners to update member roles
CREATE POLICY "Owners can update member roles"
  ON organization_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = organization_id
      AND owner_id = auth.uid()
    )
  );

-- Allow owners to remove members
CREATE POLICY "Owners can remove members"
  ON organization_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = organization_id
      AND owner_id = auth.uid()
    )
  );

