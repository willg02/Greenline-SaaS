-- ============================================================================
-- Migration: 006 - Create Organization Invitations Table
-- Description: Team invitation system with secure tokens
-- Dependencies: 005_create_organization_members.sql
-- ============================================================================

CREATE TABLE organization_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  
  status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  token TEXT UNIQUE NOT NULL DEFAULT encode(extensions.gen_random_bytes(32), 'hex'),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(organization_id, email, status)
);

-- Indexes
CREATE INDEX idx_org_invitations_org_status ON organization_invitations(organization_id, status);
CREATE INDEX idx_org_invitations_token ON organization_invitations(token) WHERE status = 'pending';
CREATE INDEX idx_org_invitations_expires ON organization_invitations(expires_at) WHERE status = 'pending';

-- Enable RLS
ALTER TABLE organization_invitations ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE organization_invitations IS 'Team invitation system with secure tokens';
COMMENT ON COLUMN organization_invitations.token IS 'Secure random token for invitation links';
