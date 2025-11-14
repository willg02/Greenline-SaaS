-- 004_function_has_org_permission.sql
-- Safe create/update of permission check function
CREATE OR REPLACE FUNCTION public.has_org_permission(org_id UUID, perm_resource TEXT, perm_action TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM organization_members om
    JOIN role_definitions rd ON om.role_id = rd.id
    JOIN role_permissions rp ON rp.role_id = rd.id
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND rp.resource = perm_resource
      AND rp.action = perm_action
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
