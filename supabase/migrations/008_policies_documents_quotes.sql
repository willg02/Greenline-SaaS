-- 008_policies_documents_quotes.sql
-- Drops & recreates phase0 policies for documents, document_permissions, quotes

-- Documents
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

-- Document permissions table
CREATE POLICY "phase0_document_permissions_select" ON document_permissions FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')));
CREATE POLICY "phase0_document_permissions_all" ON document_permissions FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')))
  WITH CHECK (EXISTS (SELECT 1 FROM documents d WHERE d.id = document_permissions.document_id AND has_org_permission(d.organization_id,'documents','manage_permissions')));

-- Quotes
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
