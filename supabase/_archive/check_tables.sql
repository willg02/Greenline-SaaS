-- Quick verification query
SELECT 
  to_regclass('role_definitions') AS role_definitions_exists,
  to_regclass('role_permissions') AS role_permissions_exists,
  to_regclass('role_change_audit') AS role_change_audit_exists,
  to_regclass('organization_members') AS org_members_exists;

-- Check if role_id column exists
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'organization_members' AND column_name = 'role_id';

-- Check function
SELECT proname FROM pg_proc WHERE proname = 'has_org_permission';
