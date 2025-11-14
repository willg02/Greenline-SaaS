-- ============================================================================
-- DEPRECATED: This file is superseded by APPLY_PHASE0_COMPLETE.sql
-- Use supabase/APPLY_PHASE0_COMPLETE.sql or individual migrations in supabase/migrations/001-011
-- Kept for reference only.
-- ============================================================================
-- Phase 0 Extension: Documents & Quotes Permissions + Policies
-- Apply after roles_phase0.sql

-- ============================================
-- 1. SEED PERMISSIONS FOR documents & quotes
-- ============================================
-- Actions: read, create, update_any, update_own, delete_any, delete_own, publish (documents), manage_permissions (documents)

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'documents', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner full
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'), ('owner','publish'), ('owner','manage_permissions'),
    -- Admin full except manage_permissions
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'), ('admin','publish'),
    -- Member limited
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'quotes', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner full
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    -- Admin full
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member limited
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- ============================================
-- 2. DOCUMENT POLICIES (phase0_) USING has_org_permission()
-- Keep originals until validated; then drop/rename.
-- Assumes documents table has columns: organization_id, created_by

-- Drop any existing phase0 policies if re-running script
DROP POLICY IF EXISTS "phase0_documents_select" ON documents;
DROP POLICY IF EXISTS "phase0_documents_insert" ON documents;
DROP POLICY IF EXISTS "phase0_documents_update_any" ON documents;
DROP POLICY IF EXISTS "phase0_documents_update_own" ON documents;
DROP POLICY IF EXISTS "phase0_documents_delete_any" ON documents;
DROP POLICY IF EXISTS "phase0_documents_delete_own" ON documents;
DROP POLICY IF EXISTS "phase0_documents_publish" ON documents;
DROP POLICY IF EXISTS "phase0_document_permissions_select" ON document_permissions;
DROP POLICY IF EXISTS "phase0_document_permissions_all" ON document_permissions;

CREATE POLICY "phase0_documents_select"
  ON documents FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'read'));

CREATE POLICY "phase0_documents_insert"
  ON documents FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'documents', 'create'));

CREATE POLICY "phase0_documents_update_any"
  ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'update_any'))
  WITH CHECK (has_org_permission(organization_id, 'documents', 'update_any'));

CREATE POLICY "phase0_documents_update_own"
  ON documents FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'documents', 'update_own') AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'documents', 'update_own') AND created_by = auth.uid()
  );

CREATE POLICY "phase0_documents_delete_any"
  ON documents FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'delete_any'));

CREATE POLICY "phase0_documents_delete_own"
  ON documents FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'documents', 'delete_own') AND created_by = auth.uid()
  );

-- Publish (status transition) - treat as UPDATE with additional action check
CREATE POLICY "phase0_documents_publish"
  ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'publish'))
  WITH CHECK (has_org_permission(organization_id, 'documents', 'publish'));

-- Manage permissions table (document_permissions) via manage_permissions
CREATE POLICY "phase0_document_permissions_select"
  ON document_permissions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = document_permissions.document_id
        AND has_org_permission(d.organization_id, 'documents', 'manage_permissions')
    )
  );

CREATE POLICY "phase0_document_permissions_all"
  ON document_permissions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = document_permissions.document_id
        AND has_org_permission(d.organization_id, 'documents', 'manage_permissions')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = document_permissions.document_id
        AND has_org_permission(d.organization_id, 'documents', 'manage_permissions')
    )
  );

-- ============================================
-- 3. QUOTE POLICIES (phase0_) USING has_org_permission()
-- quotes table: organization_id, created_by

-- Drop any existing phase0 policies if re-running script
DROP POLICY IF EXISTS "phase0_quotes_select" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_insert" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_update_any" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_update_own" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_delete_any" ON quotes;
DROP POLICY IF EXISTS "phase0_quotes_delete_own" ON quotes;

CREATE POLICY "phase0_quotes_select"
  ON quotes FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'read'));

CREATE POLICY "phase0_quotes_insert"
  ON quotes FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'quotes', 'create'));

CREATE POLICY "phase0_quotes_update_any"
  ON quotes FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'update_any'))
  WITH CHECK (has_org_permission(organization_id, 'quotes', 'update_any'));

CREATE POLICY "phase0_quotes_update_own"
  ON quotes FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'quotes', 'update_own') AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'quotes', 'update_own') AND created_by = auth.uid()
  );

CREATE POLICY "phase0_quotes_delete_any"
  ON quotes FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'delete_any'));

CREATE POLICY "phase0_quotes_delete_own"
  ON quotes FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'quotes', 'delete_own') AND created_by = auth.uid()
  );

-- ============================================
-- 4. VALIDATION QUERIES (Run manually)
-- SELECT has_org_permission('<org_uuid>','documents','publish');
-- SELECT has_org_permission('<org_uuid>','quotes','create');

-- ============================================
-- END EXTENSION
