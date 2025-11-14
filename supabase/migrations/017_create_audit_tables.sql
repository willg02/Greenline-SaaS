-- ============================================================================
-- Migration: 017 - Create Audit Tables
-- Description: Comprehensive audit logging system
-- Dependencies: 016_create_rls_policies_documents.sql
-- ============================================================================

-- General audit logs table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Actor
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT,
  
  -- Action
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID NOT NULL,
  
  -- Changes
  changes JSONB,
  metadata JSONB,
  
  -- Timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_org_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(organization_id, action);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(created_at DESC);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Role change audit table
CREATE TABLE role_change_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  member_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Change details
  old_role_id UUID REFERENCES role_definitions(id),
  new_role_id UUID REFERENCES role_definitions(id),
  reason TEXT,
  
  -- Actor
  changed_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_role_change_audit_org ON role_change_audit(organization_id);
CREATE INDEX idx_role_change_audit_user ON role_change_audit(user_id);
CREATE INDEX idx_role_change_audit_timestamp ON role_change_audit(created_at DESC);

ALTER TABLE role_change_audit ENABLE ROW LEVEL SECURITY;

-- RLS Policies for audit tables

-- Audit logs: Members can view logs for their org
CREATE POLICY "audit_logs_select"
  ON audit_logs FOR SELECT TO authenticated
  USING (
    organization_id IS NULL
    OR EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_members.organization_id = audit_logs.organization_id
        AND organization_members.user_id = auth.uid()
    )
  );

-- System can insert audit logs
CREATE POLICY "audit_logs_insert"
  ON audit_logs FOR INSERT TO authenticated
  WITH CHECK (true);

-- Role change audit: Members can view for their org
CREATE POLICY "role_change_audit_select"
  ON role_change_audit FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_members.organization_id = role_change_audit.organization_id
        AND organization_members.user_id = auth.uid()
    )
  );

-- System can insert role change audits
CREATE POLICY "role_change_audit_insert"
  ON role_change_audit FOR INSERT TO authenticated
  WITH CHECK (true);

-- Comments
COMMENT ON TABLE audit_logs IS 'Comprehensive audit trail for all system actions';
COMMENT ON TABLE role_change_audit IS 'Specific audit log for member role changes';
