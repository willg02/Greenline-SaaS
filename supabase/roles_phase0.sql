-- Phase 0 Roles & Permissions Migration
-- Run in Supabase SQL editor. Executes additive changes; existing policies remain until explicitly replaced.
-- Safe to rollback by dropping created tables/column/policies (see end section).

-- ============================================
-- PREREQUISITES
-- ============================================
-- Ensure extension uuid-ossp is enabled (already done in schema.sql)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ROLE DEFINITIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS role_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_system BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 2. ROLE PERMISSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  resource TEXT NOT NULL,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role_id, resource, action)
);

-- Helpful index for permission lookups
CREATE INDEX IF NOT EXISTS idx_role_permissions_role_resource_action
  ON role_permissions(role_id, resource, action);

-- ============================================
-- 3. AUGMENT ORGANIZATION_MEMBERS WITH role_id (TRANSITIONAL)
-- ============================================
ALTER TABLE organization_members
  ADD COLUMN IF NOT EXISTS role_id UUID;  -- nullable during transition

-- Index for role joins
CREATE INDEX IF NOT EXISTS idx_org_members_role_id ON organization_members(role_id);

-- Add FK constraint (defer NOT NULL until after backfill & app update)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'organization_members' AND constraint_name = 'organization_members_role_id_fkey'
  ) THEN
    ALTER TABLE organization_members
      ADD CONSTRAINT organization_members_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES role_definitions(id) ON DELETE SET NULL;
  END IF;
END$$;

-- ============================================
-- 4. SEED SYSTEM ROLES (idempotent inserts)
-- ============================================
INSERT INTO role_definitions (name, description)
VALUES
  ('owner', 'Full control over organization, billing, permissions'),
  ('admin', 'Manage operational data; cannot configure billing (optional)'),
  ('member', 'Standard contributor with limited update/delete scope')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 5. BACKFILL role_id FROM EXISTING TEXT role COLUMN
-- ============================================
UPDATE organization_members om
SET role_id = rd.id
FROM role_definitions rd
WHERE om.role_id IS NULL AND rd.name = om.role;

-- (Optional) Enforce NOT NULL once app reads role_id:
-- ALTER TABLE organization_members ALTER COLUMN role_id SET NOT NULL;

-- ============================================
-- 6. PERMISSION MODEL SEEDING
-- Resource taxonomy (Phase 0 focus): organization, clients (exemplar), documents, quotes.
-- Action taxonomy (generic): read, create, update_any, update_own, delete_any, delete_own, manage_members, manage_org_settings, configure_billing.
-- Only seeding for 'clients' + organization-level actions now; extend later.

-- Helper CTE to fetch role ids
WITH r AS (
  SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member')
)
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'organization', a.action
FROM r
CROSS JOIN (
  VALUES
    ('owner','manage_members'), ('owner','manage_org_settings'), ('owner','configure_billing'),
    ('admin','manage_members'), ('admin','manage_org_settings'),
    ('member','read')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- Clients resource permissions
WITH r AS (
  SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member')
)
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'clients', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin full scope
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member limited scope
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- Invitations resource permissions
WITH r AS (
  SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member')
)
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'invitations', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin can manage invitations
    ('owner','read'), ('owner','create'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','delete_any'),
    -- Member can only read
    ('member','read')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. PERMISSION CHECK FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION public.has_org_permission(org_id UUID, resource TEXT, action TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM organization_members om
    JOIN role_definitions rd ON om.role_id = rd.id
    JOIN role_permissions rp ON rp.role_id = rd.id
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND rp.resource = resource
      AND rp.action = action
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- 8. EXEMPLAR NEW POLICIES (CLIENTS) - PREFIX phase0_
-- Keep original policies during transition for safety; test then drop old ones.
-- NOTE: Ensure RLS already enabled on clients.

-- Drop any existing phase0 policies if re-running script
DROP POLICY IF EXISTS "phase0_clients_select" ON clients;
DROP POLICY IF EXISTS "phase0_clients_insert" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_own" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_own" ON clients;

-- SELECT
CREATE POLICY "phase0_clients_select"
  ON clients FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'read'));

-- INSERT
CREATE POLICY "phase0_clients_insert"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'clients', 'create'));

-- UPDATE (any)
CREATE POLICY "phase0_clients_update_any"
  ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'update_any'))
  WITH CHECK (has_org_permission(organization_id, 'clients', 'update_any'));

-- UPDATE (own) - separate policy allowing members to update their own records
CREATE POLICY "phase0_clients_update_own"
  ON clients FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'update_own') AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'update_own') AND created_by = auth.uid()
  );

-- DELETE (any)
CREATE POLICY "phase0_clients_delete_any"
  ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'delete_any'));

-- DELETE (own)
CREATE POLICY "phase0_clients_delete_own"
  ON clients FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'delete_own') AND created_by = auth.uid()
  );

-- ============================================
-- ORGANIZATION_INVITATIONS POLICIES (phase0_)
-- ============================================

-- Drop any existing policies that might conflict
DROP POLICY IF EXISTS "Users can view invitations in their organizations" ON organization_invitations;
DROP POLICY IF EXISTS "Owners and admins can create invitations" ON organization_invitations;
DROP POLICY IF EXISTS "Owners and admins can delete invitations" ON organization_invitations;

-- Read: Members can view invitations for their org
CREATE POLICY "phase0_invitations_select"
  ON organization_invitations FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'invitations', 'read'));

-- Create: Admins and owners can send invitations
CREATE POLICY "phase0_invitations_insert"
  ON organization_invitations FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'invitations', 'create'));

-- Update: Admins and owners can update invitation status
CREATE POLICY "phase0_invitations_update"
  ON organization_invitations FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'invitations', 'delete_any'))
  WITH CHECK (has_org_permission(organization_id, 'invitations', 'delete_any'));

-- Delete: Admins and owners can delete/revoke invitations
CREATE POLICY "phase0_invitations_delete"
  ON organization_invitations FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'invitations', 'delete_any'));

-- ============================================
-- 9. VALIDATION QUERIES (Run manually after migration)
-- SELECT has_org_permission('<org_uuid>', 'clients', 'read');
-- SELECT * FROM clients LIMIT 1;  -- confirm access patterns

-- ============================================
-- 10. NEXT STEPS (MANUAL)
-- - Update backend/frontend to rely on role_id (Pinia store: map returned role_id -> role name via role_definitions or include join).
-- - After verification, DROP old clients policies & rename phase0_ policies.
-- - Extend permission seeds & policies to other resources (documents, quotes, etc.).
-- - Eventually: remove organization_members.role TEXT column.

-- ============================================
-- 11. OPTIONAL CLEANUP (Rollback Instructions)
-- (Only if reverting Phase 0)
-- DROP POLICY IF EXISTS phase0_clients_select ON clients;
-- DROP POLICY IF EXISTS phase0_clients_insert ON clients;
-- DROP POLICY IF EXISTS phase0_clients_update_any ON clients;
-- DROP POLICY IF EXISTS phase0_clients_update_own ON clients;
-- DROP POLICY IF EXISTS phase0_clients_delete_any ON clients;
-- DROP POLICY IF EXISTS phase0_clients_delete_own ON clients;
-- DROP FUNCTION IF EXISTS public.has_org_permission(UUID, TEXT, TEXT);
-- ALTER TABLE organization_members DROP CONSTRAINT IF EXISTS organization_members_role_id_fkey;
-- ALTER TABLE organization_members DROP COLUMN IF EXISTS role_id;
-- DROP TABLE IF EXISTS role_permissions;
-- DROP TABLE IF EXISTS role_definitions;

-- ============================================
-- END Phase 0 Migration
