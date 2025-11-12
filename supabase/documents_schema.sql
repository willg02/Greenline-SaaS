-- ============================================
-- DOCUMENT MANAGEMENT SYSTEM (SOPs & Internal Docs)
-- Add this to your Supabase project after the main schema.sql
-- ============================================

-- ============================================
-- FOLDERS
-- ============================================

CREATE TABLE folders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  parent_folder_id UUID REFERENCES folders(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- DOCUMENTS
-- ============================================

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  content TEXT, -- Rich HTML content
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- DOCUMENT VERSIONS (Auto-versioning for history/rollback)
-- ============================================

CREATE TABLE document_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  version_number INT NOT NULL,
  content TEXT NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  change_description TEXT
);

-- ============================================
-- DOCUMENT PERMISSIONS (Role-based access control)
-- ============================================

CREATE TABLE document_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  organization_role TEXT NOT NULL CHECK (organization_role IN ('owner', 'admin', 'member')),
  can_view BOOLEAN NOT NULL DEFAULT true,
  can_edit BOOLEAN NOT NULL DEFAULT false,
  can_delete BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(document_id, organization_role)
);

-- ============================================
-- DOCUMENT ACTIVITY LOG (Track who did what)
-- ============================================

CREATE TABLE document_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'published', 'archived', 'restored', 'version_reverted')),
  changes TEXT, -- JSON of what changed
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_folders_org_id ON folders(organization_id);
CREATE INDEX idx_folders_parent_id ON folders(parent_folder_id);
CREATE INDEX idx_documents_org_id ON documents(organization_id);
CREATE INDEX idx_documents_folder_id ON documents(folder_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_created_by ON documents(created_by);
CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_version_num ON document_versions(document_id, version_number);
CREATE INDEX idx_document_permissions_doc_id ON document_permissions(document_id);
CREATE INDEX idx_document_activity_document_id ON document_activity(document_id);
CREATE INDEX idx_document_activity_user_id ON document_activity(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_activity ENABLE ROW LEVEL SECURITY;

-- FOLDERS: Users can view/manage folders in their organizations
CREATE POLICY "Users can view folders in their organizations"
  ON folders FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create folders in their organizations"
  ON folders FOR INSERT
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update folders in their organizations"
  ON folders FOR UPDATE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins and owners can delete folders"
  ON folders FOR DELETE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- DOCUMENTS: Users can view documents based on permissions
CREATE POLICY "Users can view documents they have access to"
  ON documents FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create documents in their organizations"
  ON documents FOR INSERT
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update documents they can edit"
  ON documents FOR UPDATE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
    AND (
      created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM organization_members om
        WHERE om.organization_id = documents.organization_id
        AND om.user_id = auth.uid()
        AND om.role IN ('owner', 'admin')
      )
      OR EXISTS (
        SELECT 1 FROM document_permissions dp
        WHERE dp.document_id = documents.id
        AND dp.organization_role = (
          SELECT om.role FROM organization_members om
          WHERE om.organization_id = documents.organization_id
          AND om.user_id = auth.uid()
        )
        AND dp.can_edit = true
      )
    )
  );

CREATE POLICY "Owners and admins can delete documents"
  ON documents FOR DELETE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- DOCUMENT VERSIONS: Users can view versions of accessible documents
CREATE POLICY "Users can view versions of accessible documents"
  ON document_versions FOR SELECT
  USING (
    document_id IN (
      SELECT id FROM documents
      WHERE organization_id IN (
        SELECT organization_id FROM organization_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- DOCUMENT PERMISSIONS: Owners/admins can manage permissions
CREATE POLICY "Admins and owners can view document permissions"
  ON document_permissions FOR SELECT
  USING (
    document_id IN (
      SELECT id FROM documents
      WHERE organization_id IN (
        SELECT organization_id FROM organization_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
      )
    )
  );

CREATE POLICY "Admins and owners can manage document permissions"
  ON document_permissions FOR ALL
  USING (
    document_id IN (
      SELECT id FROM documents
      WHERE organization_id IN (
        SELECT organization_id FROM organization_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
      )
    )
  );

-- DOCUMENT ACTIVITY: Users can view activity logs for their org
CREATE POLICY "Users can view document activity in their organizations"
  ON document_activity FOR SELECT
  USING (
    document_id IN (
      SELECT id FROM documents
      WHERE organization_id IN (
        SELECT organization_id FROM organization_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "System can create activity logs"
  ON document_activity FOR INSERT
  WITH CHECK (true);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update folder updated_at
CREATE OR REPLACE FUNCTION update_folders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_folders_timestamp
  BEFORE UPDATE ON folders
  FOR EACH ROW EXECUTE FUNCTION update_folders_updated_at();

-- Function to create version when document is updated
CREATE OR REPLACE FUNCTION create_document_version()
RETURNS TRIGGER AS $$
DECLARE
  last_version INT;
BEGIN
  -- Get the last version number
  SELECT COALESCE(MAX(version_number), 0) INTO last_version
  FROM document_versions
  WHERE document_id = NEW.id;

  -- Create new version record
  INSERT INTO document_versions (document_id, version_number, content, title, status, created_by, change_description)
  VALUES (NEW.id, last_version + 1, NEW.content, NEW.title, NEW.status, NEW.updated_by, 'Auto-saved version');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_version_trigger
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION create_document_version();

-- Function to log document activity
CREATE OR REPLACE FUNCTION log_document_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO document_activity (document_id, user_id, action)
    VALUES (NEW.id, NEW.created_by, 'created');
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO document_activity (document_id, user_id, action)
    VALUES (NEW.id, NEW.updated_by, 'updated');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_activity_trigger
  AFTER INSERT OR UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION log_document_activity();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE folders IS 'Hierarchical folder structure for organizing documents';
COMMENT ON TABLE documents IS 'SOP and internal procedure documents with rich content';
COMMENT ON TABLE document_versions IS 'Auto-versioned history of document changes';
COMMENT ON TABLE document_permissions IS 'Role-based access control for documents';
COMMENT ON TABLE document_activity IS 'Activity audit log for compliance and tracking';
