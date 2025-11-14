-- ============================================================================
-- Migration: 003 - Create Role & Permission System
-- Description: Flexible RBAC system with role definitions and permissions
-- Dependencies: 002_create_organizations.sql
-- ============================================================================

-- Role Definitions Table
CREATE TABLE role_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  is_system BOOLEAN NOT NULL DEFAULT false,
  scope TEXT NOT NULL DEFAULT 'organization' 
    CHECK (scope IN ('organization', 'project', 'document')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_role_definitions_name ON role_definitions(name);
CREATE INDEX idx_role_definitions_system ON role_definitions(is_system) 
  WHERE is_system = true;

-- Role Permissions Table
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  resource TEXT NOT NULL,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role_id, resource, action)
);

CREATE INDEX idx_role_permissions_lookup ON role_permissions(role_id, resource, action);
CREATE INDEX idx_role_permissions_resource ON role_permissions(resource);

-- Enable RLS
ALTER TABLE role_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE role_definitions IS 'System and custom role definitions';
COMMENT ON TABLE role_permissions IS 'Permission mappings for roles (resource + action)';
COMMENT ON COLUMN role_definitions.is_system IS 'Prevents deletion of core system roles';
COMMENT ON COLUMN role_definitions.scope IS 'Future-proof: org, project, or document-level roles';
