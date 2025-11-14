-- 002_augment_org_members.sql
-- Adds role_id column & FK if missing; backfills from legacy role text
ALTER TABLE organization_members ADD COLUMN IF NOT EXISTS role_id UUID;
CREATE INDEX IF NOT EXISTS idx_org_members_role_id ON organization_members(role_id);
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name='organization_members' AND constraint_name='organization_members_role_id_fkey'
  ) THEN
    ALTER TABLE organization_members
      ADD CONSTRAINT organization_members_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES role_definitions(id) ON DELETE SET NULL;
  END IF;
END$$;

-- Backfill
UPDATE organization_members om
SET role_id = rd.id
FROM role_definitions rd
WHERE om.role_id IS NULL AND rd.name = om.role;
