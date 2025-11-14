-- ============================================================================
-- Migration: 008 - Create Permission Check Function
-- Description: Core function for checking user permissions in RLS policies
-- Dependencies: 007_seed_permissions.sql
-- ============================================================================

CREATE OR REPLACE FUNCTION public.has_org_permission(
  org_id UUID,
  perm_resource TEXT,
  perm_action TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM organization_members om
    JOIN role_permissions rp ON rp.role_id = om.role_id
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND rp.resource = perm_resource
      AND rp.action = perm_action
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.has_org_permission IS 'Check if current user has specific permission in organization';
