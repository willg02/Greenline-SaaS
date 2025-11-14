-- 007_permissions_seed_docs_quotes.sql
-- Seeds permissions for documents & quotes (idempotent)
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'documents', a.action
FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),('owner','publish'),('owner','manage_permissions'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),('admin','publish'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'quotes', a.action
FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;
