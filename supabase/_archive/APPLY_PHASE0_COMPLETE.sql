-- ============================================================================
-- PHASE 0 RBAC - COMPLETE CONSOLIDATED MIGRATION
-- ============================================================================
-- This file consolidates migrations 001-011 into a single executable script.
-- Fully idempotent - safe to re-run. Copy/paste into Supabase SQL Editor.
-- ============================================================================

-- ============================================================================
-- 001: ROLE TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_system BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  resource TEXT NOT NULL,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role_id, resource, action)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_resource_action
  ON role_permissions(role_id, resource, action);

-- ============================================================================
-- 002: AUGMENT ORGANIZATION_MEMBERS
-- ============================================================================
ALTER TABLE organization_members ADD COLUMN IF NOT EXISTS role_id UUID;
CREATE INDEX IF NOT EXISTS idx_org_members_role_id ON organization_members(role_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name='organization_members' AND constraint_name='organization_members_role_id_fkey'
  ) THEN
    ALTER TABLE organization_members
      ADD CONSTRAINT organization_members_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES role_definitions(id) ON DELETE SET NULL;
  END IF;
END$$;

-- ============================================================================
-- 003: SEED SYSTEM ROLES
-- ============================================================================
INSERT INTO role_definitions (name, description)
VALUES
  ('owner','Full control over organization, billing, permissions'),
  ('admin','Manage operational data; cannot configure billing'),
  ('member','Standard contributor with limited scope')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 002 (continued): BACKFILL role_id
-- ============================================================================
UPDATE organization_members om
SET role_id = rd.id
FROM role_definitions rd
WHERE om.role_id IS NULL AND rd.name = om.role;

-- ============================================================================
-- 004: PERMISSION CHECK FUNCTION
-- ============================================================================
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

-- ============================================================================
-- 005: CORE PERMISSIONS (organization, clients, invitations)
-- ============================================================================
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

-- ============================================================================
-- 006: POLICIES - CLIENTS & INVITATIONS
-- ============================================================================
DROP POLICY IF EXISTS "phase0_clients_select" ON clients;
DROP POLICY IF EXISTS "phase0_clients_insert" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_own" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_own" ON clients;

CREATE POLICY "phase0_clients_select" ON clients FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'clients','read'));
CREATE POLICY "phase0_clients_insert" ON clients FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'clients','create'));
CREATE POLICY "phase0_clients_update_any" ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'clients','update_any'))
  WITH CHECK (has_org_permission(organization_id,'clients','update_any'));
CREATE POLICY "phase0_clients_update_own" ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'clients','update_own') AND created_by = auth.uid())
  WITH CHECK (has_org_permission(organization_id,'clients','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_clients_delete_any" ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'clients','delete_any'));
CREATE POLICY "phase0_clients_delete_own" ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'clients','delete_own') AND created_by = auth.uid());

DROP POLICY IF EXISTS "phase0_invitations_select" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_insert" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_update" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_delete" ON organization_invitations;

CREATE POLICY "phase0_invitations_select" ON organization_invitations FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'invitations','read'));
CREATE POLICY "phase0_invitations_insert" ON organization_invitations FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'invitations','create'));
CREATE POLICY "phase0_invitations_update" ON organization_invitations FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'invitations','delete_any'))
  WITH CHECK (has_org_permission(organization_id,'invitations','delete_any'));
CREATE POLICY "phase0_invitations_delete" ON organization_invitations FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'invitations','delete_any'));

-- ============================================================================
-- 007: DOCUMENTS & QUOTES PERMISSIONS
-- ============================================================================
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

-- ============================================================================
-- 008: POLICIES - DOCUMENTS & QUOTES
-- ============================================================================
DROP POLICY IF EXISTS "phase0_documents_select" ON documents;
DROP POLICY IF EXISTS "phase0_documents_insert" ON documents;
DROP POLICY IF EXISTS "phase0_documents_update_any" ON documents;
DROP POLICY IF EXISTS "phase0_documents_update_own" ON documents;
DROP POLICY IF EXISTS "phase0_documents_delete_any" ON documents;
DROP POLICY IF EXISTS "phase0_documents_delete_own" ON documents;
DROP POLICY IF EXISTS "phase0_documents_publish" ON documents;
DROP POLICY IF EXISTS "phase0_document_permissions_select" ON document_permissions;
DROP POLICY IF EXISTS "phase0_document_permissions_all" ON document_permissions;

CREATE POLICY "phase0_documents_select" ON documents FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'documents','read'));
CREATE POLICY "phase0_documents_insert" ON documents FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'documents','create'));
CREATE POLICY "phase0_documents_update_any" ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'documents','update_any'))
  WITH CHECK (has_org_permission(organization_id,'documents','update_any'));
CREATE POLICY "phase0_documents_update_own" ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'documents','update_own') AND created_by = auth.uid())
  WITH CHECK (has_org_permission(organization_id,'documents','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_documents_delete_any" ON documents FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'documents','delete_any'));
CREATE POLICY "phase0_documents_delete_own" ON documents FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'documents','delete_own') AND created_by = auth.uid());
CREATE POLICY "phase0_documents_publish" ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'documents','publish'))
  WITH CHECK (has_org_permission(organization_id,'documents','publish'));

CREATE POLICY "phase0_document_permissions_select" ON document_permissions FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')));
CREATE POLICY "phase0_document_permissions_all" ON document_permissions FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')))
  WITH CHECK (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')));

DROP POLICY IF EXISTS "phase0_quotes_select" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_insert" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_update_any" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_update_own" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_delete_any" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_delete_own" ON quotes;

CREATE POLICY "phase0_quotes_select" ON quotes FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'quotes','read'));
CREATE POLICY "phase0_quotes_insert" ON quotes FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'quotes','create'));
CREATE POLICY "phase0_quotes_update_any" ON quotes FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'quotes','update_any'))
  WITH CHECK (has_org_permission(organization_id,'quotes','update_any'));
CREATE POLICY "phase0_quotes_update_own" ON quotes FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'quotes','update_own') AND created_by = auth.uid())
  WITH CHECK (has_org_permission(organization_id,'quotes','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_quotes_delete_any" ON quotes FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'quotes','delete_any'));
CREATE POLICY "phase0_quotes_delete_own" ON quotes FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'quotes','delete_own') AND created_by = auth.uid());

-- ============================================================================
-- 009: OTHER RESOURCE PERMISSIONS (plants, materials, folders, quote_items)
-- ============================================================================
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

-- ============================================================================
-- 010: POLICIES - OTHER RESOURCES
-- ============================================================================
-- Plants
DROP POLICY IF EXISTS "phase0_plants_select" ON plants;
DROP POLICY IF EXISTS "phase0_plants_insert" ON plants;
DROP POLICY IF EXISTS "phase0_plants_update_any" ON plants;
DROP POLICY IF EXISTS "phase0_plants_update_own" ON plants;
DROP POLICY IF EXISTS "phase0_plants_delete_any" ON plants;
DROP POLICY IF EXISTS "phase0_plants_delete_own" ON plants;

CREATE POLICY "phase0_plants_select" ON plants FOR SELECT TO authenticated 
  USING (organization_id IS NULL OR has_org_permission(organization_id,'plants','read'));
CREATE POLICY "phase0_plants_insert" ON plants FOR INSERT TO authenticated 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','create'));
CREATE POLICY "phase0_plants_update_any" ON plants FOR UPDATE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_any')) 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_any'));
CREATE POLICY "phase0_plants_update_own" ON plants FOR UPDATE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_own') AND created_by = auth.uid()) 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_plants_delete_any" ON plants FOR DELETE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','delete_any'));
CREATE POLICY "phase0_plants_delete_own" ON plants FOR DELETE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','delete_own') AND created_by = auth.uid());

-- Materials
DROP POLICY IF EXISTS "phase0_materials_select" ON materials;
DROP POLICY IF EXISTS "phase0_materials_insert" ON materials;
DROP POLICY IF EXISTS "phase0_materials_update_any" ON materials;
DROP POLICY IF EXISTS "phase0_materials_update_own" ON materials;
DROP POLICY IF EXISTS "phase0_materials_delete_any" ON materials;
DROP POLICY IF EXISTS "phase0_materials_delete_own" ON materials;

CREATE POLICY "phase0_materials_select" ON materials FOR SELECT TO authenticated 
  USING (organization_id IS NULL OR has_org_permission(organization_id,'materials','read'));
CREATE POLICY "phase0_materials_insert" ON materials FOR INSERT TO authenticated 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','create'));
CREATE POLICY "phase0_materials_update_any" ON materials FOR UPDATE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_any')) 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_any'));
CREATE POLICY "phase0_materials_update_own" ON materials FOR UPDATE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_own') AND created_by = auth.uid()) 
  WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_materials_delete_any" ON materials FOR DELETE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','delete_any'));
CREATE POLICY "phase0_materials_delete_own" ON materials FOR DELETE TO authenticated 
  USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','delete_own') AND created_by = auth.uid());

-- Folders
DROP POLICY IF EXISTS "phase0_folders_select" ON folders;
DROP POLICY IF EXISTS "phase0_folders_insert" ON folders;
DROP POLICY IF EXISTS "phase0_folders_update_any" ON folders;
DROP POLICY IF EXISTS "phase0_folders_update_own" ON folders;
DROP POLICY IF EXISTS "phase0_folders_delete_any" ON folders;
DROP POLICY IF EXISTS "phase0_folders_delete_own" ON folders;

CREATE POLICY "phase0_folders_select" ON folders FOR SELECT TO authenticated 
  USING (has_org_permission(organization_id,'folders','read'));
CREATE POLICY "phase0_folders_insert" ON folders FOR INSERT TO authenticated 
  WITH CHECK (has_org_permission(organization_id,'folders','create'));
CREATE POLICY "phase0_folders_update_any" ON folders FOR UPDATE TO authenticated 
  USING (has_org_permission(organization_id,'folders','update_any')) 
  WITH CHECK (has_org_permission(organization_id,'folders','update_any'));
CREATE POLICY "phase0_folders_update_own" ON folders FOR UPDATE TO authenticated 
  USING (has_org_permission(organization_id,'folders','update_own') AND created_by = auth.uid()) 
  WITH CHECK (has_org_permission(organization_id,'folders','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_folders_delete_any" ON folders FOR DELETE TO authenticated 
  USING (has_org_permission(organization_id,'folders','delete_any'));
CREATE POLICY "phase0_folders_delete_own" ON folders FOR DELETE TO authenticated 
  USING (has_org_permission(organization_id,'folders','delete_own') AND created_by = auth.uid());

-- Quote Items
DROP POLICY IF EXISTS "phase0_quote_items_select" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_insert" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_update" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_delete" ON quote_items;

CREATE POLICY "phase0_quote_items_select" ON quote_items FOR SELECT TO authenticated 
  USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','read')));
CREATE POLICY "phase0_quote_items_insert" ON quote_items FOR INSERT TO authenticated 
  WITH CHECK (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','create')));
CREATE POLICY "phase0_quote_items_update" ON quote_items FOR UPDATE TO authenticated 
  USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','update_any'))) 
  WITH CHECK (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','update_any')));
CREATE POLICY "phase0_quote_items_delete" ON quote_items FOR DELETE TO authenticated 
  USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','delete_any')));

-- ============================================================================
-- 011: AUDIT LOGGING
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_change_audit (
  id BIGSERIAL PRIMARY KEY,
  organization_id UUID NOT NULL,
  member_id UUID NOT NULL,
  changed_by UUID NOT NULL,
  old_role_id UUID,
  new_role_id UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_role_change_audit_org ON role_change_audit(organization_id);
CREATE INDEX IF NOT EXISTS idx_role_change_audit_member ON role_change_audit(member_id);

CREATE OR REPLACE FUNCTION log_role_change() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role_id IS DISTINCT FROM OLD.role_id THEN
    INSERT INTO role_change_audit (organization_id, member_id, changed_by, old_role_id, new_role_id)
    VALUES (NEW.organization_id, NEW.user_id, auth.uid(), OLD.role_id, NEW.role_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_role_change ON organization_members;
CREATE TRIGGER trg_log_role_change
AFTER UPDATE OF role_id ON organization_members
FOR EACH ROW
EXECUTE FUNCTION log_role_change();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Uncomment and run these after the migration to verify success:

-- Check tables exist
-- SELECT 
--   to_regclass('role_definitions') AS role_definitions_exists,
--   to_regclass('role_permissions') AS role_permissions_exists,
--   to_regclass('role_change_audit') AS role_change_audit_exists;

-- Check role_id backfill
-- SELECT COUNT(*) AS members_missing_role_id FROM organization_members WHERE role_id IS NULL;

-- Check function exists
-- SELECT proname FROM pg_proc WHERE proname = 'has_org_permission';

-- Check permissions seeded
-- SELECT COUNT(*) AS total_permissions FROM role_permissions;

-- Check policies (example for clients)
-- SELECT policyname FROM pg_policies WHERE tablename = 'clients' AND policyname LIKE 'phase0_%';

-- Test permission function (replace with real org UUID)
-- SELECT has_org_permission('<your_org_uuid_here>','clients','read');

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
