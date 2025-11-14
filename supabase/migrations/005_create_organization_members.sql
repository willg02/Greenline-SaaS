-- ============================================================================
-- Migration: 005 - Create Organization Members Table
-- Description: Junction table linking users to organizations with roles
-- Dependencies: 003_create_role_system.sql
-- ============================================================================

CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE RESTRICT,
  
  -- Metadata
  invited_by UUID REFERENCES auth.users(id),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(organization_id, user_id)
);

-- Indexes
CREATE INDEX idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX idx_org_members_role_id ON organization_members(role_id);
CREATE INDEX idx_org_members_composite ON organization_members(organization_id, user_id, role_id);

-- Enable RLS
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE organization_members IS 'User-organization-role junction table';
COMMENT ON COLUMN organization_members.invited_by IS 'Tracks who added this member';
