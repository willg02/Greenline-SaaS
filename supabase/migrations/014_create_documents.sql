-- ============================================================================
-- Migration: 014 - Create Document Management Tables
-- Description: Folders, documents, versions, and permissions for SOPs
-- Dependencies: 013_create_plants_materials.sql
-- ============================================================================

-- Folders table
CREATE TABLE folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  parent_folder_id UUID REFERENCES folders(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,
  icon TEXT,
  
  -- Metadata
  sort_order INTEGER NOT NULL DEFAULT 0,
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_folders_org_id ON folders(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_folders_parent_id ON folders(parent_folder_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_folders_hierarchy ON folders(organization_id, parent_folder_id, sort_order);

ALTER TABLE folders ENABLE ROW LEVEL SECURITY;

-- Documents table
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
  
  -- Identity
  title TEXT NOT NULL,
  slug TEXT,
  
  -- Content
  content TEXT,
  content_type TEXT NOT NULL DEFAULT 'html' CHECK (content_type IN ('html', 'markdown', 'plain')),
  
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' 
    CHECK (status IN ('draft', 'review', 'published', 'archived')),
  
  -- Versioning
  version INTEGER NOT NULL DEFAULT 1,
  
  -- Metadata
  tags TEXT[],
  template_id UUID REFERENCES documents(id),
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Collaboration
  is_locked BOOLEAN DEFAULT false,
  locked_by UUID REFERENCES auth.users(id),
  locked_at TIMESTAMPTZ,
  
  -- Publishing
  published_at TIMESTAMPTZ,
  published_by UUID REFERENCES auth.users(id),
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_documents_org_id ON documents(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_folder_id ON documents(folder_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_status ON documents(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_slug ON documents(organization_id, slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_title_search ON documents USING gin(to_tsvector('english', title));
CREATE INDEX idx_documents_tags ON documents USING gin(tags);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Document versions table
CREATE TABLE document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  
  -- Version snapshot
  version_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_type TEXT NOT NULL,
  status TEXT NOT NULL,
  
  -- Change tracking
  change_description TEXT,
  changed_fields TEXT[],
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(document_id, version_number)
);

CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_lookup ON document_versions(document_id, version_number DESC);

ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;

-- Document permissions table
CREATE TABLE document_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  
  -- Permissions
  can_view BOOLEAN NOT NULL DEFAULT true,
  can_edit BOOLEAN NOT NULL DEFAULT false,
  can_publish BOOLEAN NOT NULL DEFAULT false,
  can_delete BOOLEAN NOT NULL DEFAULT false,
  can_manage_permissions BOOLEAN NOT NULL DEFAULT false,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(document_id, role_id)
);

CREATE INDEX idx_document_permissions_document ON document_permissions(document_id);
CREATE INDEX idx_document_permissions_role ON document_permissions(role_id);

ALTER TABLE document_permissions ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE folders IS 'Hierarchical folder structure for organizing documents';
COMMENT ON TABLE documents IS 'SOP and internal procedure documents with rich content';
COMMENT ON TABLE document_versions IS 'Version history for document changes';
COMMENT ON TABLE document_permissions IS 'Granular role-based access control for documents';
