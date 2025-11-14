-- 003_seed_system_roles.sql
-- Idempotent seed of system roles
INSERT INTO role_definitions (name, description)
VALUES
  ('owner','Full control over organization, billing, permissions'),
  ('admin','Manage operational data; cannot configure billing'),
  ('member','Standard contributor with limited scope')
ON CONFLICT (name) DO NOTHING;
