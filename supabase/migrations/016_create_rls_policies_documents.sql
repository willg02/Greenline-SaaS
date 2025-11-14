-- ============================================================================
-- Migration: 016 - Create RLS Policies for Documents
-- Description: Row Level Security for folders, documents, versions, permissions
-- Dependencies: 015_create_rls_policies_business.sql
-- ============================================================================

-- ============================================
-- FOLDERS POLICIES
-- ============================================

CREATE POLICY "folders_select"
  ON folders FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'read'));

CREATE POLICY "folders_insert"
  ON folders FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'folders', 'create')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "folders_update_any"
  ON folders FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'update_any'))
  WITH CHECK (
    has_org_permission(organization_id, 'folders', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "folders_delete_any"
  ON folders FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'delete_any'));

-- ============================================
-- DOCUMENTS POLICIES
-- ============================================

CREATE POLICY "documents_select"
  ON documents FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'read'));

CREATE POLICY "documents_insert"
  ON documents FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'documents', 'create')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "documents_update_any"
  ON documents FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'update_any'))
  WITH CHECK (
    has_org_permission(organization_id, 'documents', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "documents_update_own"
  ON documents FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'documents', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'documents', 'update_own')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "documents_delete_any"
  ON documents FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'documents', 'delete_any'));

-- ============================================
-- DOCUMENT VERSIONS POLICIES
-- ============================================

CREATE POLICY "document_versions_select"
  ON document_versions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_versions.document_id
        AND has_org_permission(documents.organization_id, 'documents', 'read')
    )
  );

-- Versions are created automatically via triggers, not manually
CREATE POLICY "document_versions_insert"
  ON document_versions FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_versions.document_id
        AND has_org_permission(documents.organization_id, 'documents', 'update_any')
    )
  );

-- ============================================
-- DOCUMENT PERMISSIONS POLICIES
-- ============================================

CREATE POLICY "document_permissions_select"
  ON document_permissions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_permissions.document_id
        AND has_org_permission(documents.organization_id, 'documents', 'read')
    )
  );

CREATE POLICY "document_permissions_manage"
  ON document_permissions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_permissions.document_id
        AND (
          has_org_permission(documents.organization_id, 'organization', 'manage_settings')
          OR has_org_permission(documents.organization_id, 'documents', 'delete_any')
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_permissions.document_id
        AND (
          has_org_permission(documents.organization_id, 'organization', 'manage_settings')
          OR has_org_permission(documents.organization_id, 'documents', 'delete_any')
        )
    )
  );
