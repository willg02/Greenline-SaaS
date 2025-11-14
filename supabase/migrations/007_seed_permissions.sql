-- ============================================================================
-- Migration: 007 - Seed Role Permissions
-- Description: Seed permission mappings for system roles
-- Dependencies: 004_seed_system_roles.sql
-- ============================================================================

-- Owner: Full access to everything
WITH owner_role AS (SELECT id FROM role_definitions WHERE name = 'owner')
INSERT INTO role_permissions (role_id, resource, action)
SELECT owner_role.id, perms.resource, perms.action
FROM owner_role
CROSS JOIN (VALUES
  ('organization', 'manage_members'),
  ('organization', 'manage_settings'),
  ('organization', 'configure_billing'),
  ('clients', 'read'),
  ('clients', 'create'),
  ('clients', 'update_any'),
  ('clients', 'delete_any'),
  ('quotes', 'read'),
  ('quotes', 'create'),
  ('quotes', 'update_any'),
  ('quotes', 'delete_any'),
  ('documents', 'read'),
  ('documents', 'create'),
  ('documents', 'update_any'),
  ('documents', 'delete_any'),
  ('documents', 'publish'),
  ('documents', 'archive'),
  ('plants', 'read'),
  ('plants', 'create'),
  ('plants', 'update_any'),
  ('plants', 'delete_any'),
  ('materials', 'read'),
  ('materials', 'create'),
  ('materials', 'update_any'),
  ('materials', 'delete_any'),
  ('folders', 'read'),
  ('folders', 'create'),
  ('folders', 'update_any'),
  ('folders', 'delete_any'),
  ('projects', 'read'),
  ('projects', 'create'),
  ('projects', 'update_any'),
  ('projects', 'delete_any'),
  ('invitations', 'read'),
  ('invitations', 'create'),
  ('invitations', 'delete_any')
) AS perms(resource, action)
ON CONFLICT (role_id, resource, action) DO NOTHING;

-- Admin: Operational management, no billing
WITH admin_role AS (SELECT id FROM role_definitions WHERE name = 'admin')
INSERT INTO role_permissions (role_id, resource, action)
SELECT admin_role.id, perms.resource, perms.action
FROM admin_role
CROSS JOIN (VALUES
  ('organization', 'manage_members'),
  ('organization', 'manage_settings'),
  ('clients', 'read'),
  ('clients', 'create'),
  ('clients', 'update_any'),
  ('clients', 'delete_any'),
  ('quotes', 'read'),
  ('quotes', 'create'),
  ('quotes', 'update_any'),
  ('quotes', 'delete_any'),
  ('documents', 'read'),
  ('documents', 'create'),
  ('documents', 'update_any'),
  ('documents', 'publish'),
  ('documents', 'archive'),
  ('plants', 'read'),
  ('plants', 'create'),
  ('plants', 'update_any'),
  ('materials', 'read'),
  ('materials', 'create'),
  ('materials', 'update_any'),
  ('folders', 'read'),
  ('folders', 'create'),
  ('folders', 'update_any'),
  ('projects', 'read'),
  ('projects', 'create'),
  ('projects', 'update_any'),
  ('projects', 'delete_any'),
  ('invitations', 'read'),
  ('invitations', 'create'),
  ('invitations', 'delete_any')
) AS perms(resource, action)
ON CONFLICT (role_id, resource, action) DO NOTHING;

-- Member: Create/edit own, read all
WITH member_role AS (SELECT id FROM role_definitions WHERE name = 'member')
INSERT INTO role_permissions (role_id, resource, action)
SELECT member_role.id, perms.resource, perms.action
FROM member_role
CROSS JOIN (VALUES
  ('clients', 'read'),
  ('clients', 'create'),
  ('clients', 'update_own'),
  ('clients', 'delete_own'),
  ('quotes', 'read'),
  ('quotes', 'create'),
  ('quotes', 'update_own'),
  ('quotes', 'delete_own'),
  ('documents', 'read'),
  ('documents', 'create'),
  ('documents', 'update_own'),
  ('plants', 'read'),
  ('materials', 'read'),
  ('folders', 'read'),
  ('folders', 'create'),
  ('projects', 'read'),
  ('projects', 'create'),
  ('projects', 'update_own'),
  ('invitations', 'read')
) AS perms(resource, action)
ON CONFLICT (role_id, resource, action) DO NOTHING;

-- Viewer: Read-only
WITH viewer_role AS (SELECT id FROM role_definitions WHERE name = 'viewer')
INSERT INTO role_permissions (role_id, resource, action)
SELECT viewer_role.id, perms.resource, perms.action
FROM viewer_role
CROSS JOIN (VALUES
  ('clients', 'read'),
  ('quotes', 'read'),
  ('documents', 'read'),
  ('plants', 'read'),
  ('materials', 'read'),
  ('folders', 'read'),
  ('projects', 'read'),
  ('invitations', 'read')
) AS perms(resource, action)
ON CONFLICT (role_id, resource, action) DO NOTHING;
