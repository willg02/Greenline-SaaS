-- 011_audit_role_changes.sql
-- Creates audit table & trigger for role_id changes in organization_members.

CREATE TABLE IF NOT EXISTS role_change_audit (
  id BIGSERIAL PRIMARY KEY,
  organization_id UUID NOT NULL,
  member_id UUID NOT NULL,
  changed_by UUID NOT NULL,
  old_role_id UUID,
  new_role_id UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_role_change_audit_org ON role_change_audit(organization_id);
CREATE INDEX IF NOT EXISTS idx_role_change_audit_member ON role_change_audit(member_id);

-- Trigger function (create or replace for idempotency)
CREATE OR REPLACE FUNCTION log_role_change() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role_id IS DISTINCT FROM OLD.role_id THEN
    INSERT INTO role_change_audit (organization_id, member_id, changed_by, old_role_id, new_role_id)
    VALUES (NEW.organization_id, NEW.user_id, auth.uid(), OLD.role_id, NEW.role_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if present then recreate
DROP TRIGGER IF EXISTS trg_log_role_change ON organization_members;
CREATE TRIGGER trg_log_role_change
AFTER UPDATE OF role_id ON organization_members
FOR EACH ROW
EXECUTE FUNCTION log_role_change();
