-- 005_permissions_seed_core.sql
-- Seeds organization, clients, invitations core permissions
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'organization', a.action
FROM r CROSS JOIN (
  VALUES ('owner','manage_members'),('owner','manage_org_settings'),('owner','configure_billing'),
         ('admin','manage_members'),('admin','manage_org_settings'),('member','read')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'clients', a.action
FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'invitations', a.action
FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','delete_any'),
         ('member','read')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;
