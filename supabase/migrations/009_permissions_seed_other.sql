-- 009_permissions_seed_other.sql
-- Seeds plants, materials, folders, quote_items permissions
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'plants', a.action FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action) WHERE a.role_name = r.name ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'materials', a.action FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action) WHERE a.role_name = r.name ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'folders', a.action FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action) WHERE a.role_name = r.name ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'quote_items', a.action FROM r CROSS JOIN (
  VALUES ('owner','read'),('owner','create'),('owner','update_any'),('owner','delete_any'),
         ('admin','read'),('admin','create'),('admin','update_any'),('admin','delete_any'),
         ('member','read'),('member','create'),('member','update_own'),('member','delete_own')
) AS a(role_name, action) WHERE a.role_name = r.name ON CONFLICT DO NOTHING;
