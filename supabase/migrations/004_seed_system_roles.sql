-- ============================================================================
-- Migration: 004 - Seed System Roles
-- Description: Insert core system roles (owner, admin, member, viewer)
-- Dependencies: 003_create_role_system.sql
-- ============================================================================

-- Insert system roles
INSERT INTO role_definitions (name, display_name, description, is_system) VALUES
  ('owner', 'Owner', 'Full control: billing, members, all data', true),
  ('admin', 'Administrator', 'Manage team and data, no billing access', true),
  ('member', 'Member', 'Standard access: create/edit own data', true),
  ('viewer', 'Viewer', 'Read-only access to organization data', true)
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE role_definitions IS 'System roles seeded: owner, admin, member, viewer';
