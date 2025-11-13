-- Phase 0 Final Extension: All Remaining Resources + Audit Logging
-- Apply after roles_phase0.sql and roles_phase0_extend.sql

-- ============================================
-- 1. SEED PERMISSIONS FOR plants, materials, folders, quote_items
-- ============================================

-- Plants permissions (custom org plants + global read)
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'plants', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin full control
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member limited
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- Materials permissions
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'materials', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin full control
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member limited
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- Folders permissions (documents structure)
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'folders', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin full control
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member: read + create, update/delete only own
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- Quote_items permissions (tied to parent quote permissions)
WITH r AS (SELECT id, name FROM role_definitions WHERE name IN ('owner','admin','member'))
INSERT INTO role_permissions (role_id, resource, action)
SELECT r.id, 'quote_items', a.action
FROM r
CROSS JOIN (
  VALUES
    -- Owner & Admin full control
    ('owner','read'), ('owner','create'), ('owner','update_any'), ('owner','delete_any'),
    ('admin','read'), ('admin','create'), ('admin','update_any'), ('admin','delete_any'),
    -- Member limited (typically tied to parent quote ownership)
    ('member','read'), ('member','create'), ('member','update_own'), ('member','delete_own')
) AS a(role_name, action)
WHERE a.role_name = r.name
ON CONFLICT DO NOTHING;

-- ============================================
-- 2. PLANTS POLICIES (phase0_)
-- Assumes plants table: organization_id (nullable for global), created_by
-- ============================================

CREATE POLICY "phase0_plants_select"
  ON plants FOR SELECT TO authenticated
  USING (
    organization_id IS NULL  -- global plants visible to all
    OR
    has_org_permission(organization_id, 'plants', 'read')
  );

CREATE POLICY "phase0_plants_insert"
  ON plants FOR INSERT TO authenticated
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'create')
  );

CREATE POLICY "phase0_plants_update_any"
  ON plants FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_any')
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_any')
  );

CREATE POLICY "phase0_plants_update_own"
  ON plants FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_own')
    AND created_by = auth.uid()
  );

CREATE POLICY "phase0_plants_delete_any"
  ON plants FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'delete_any')
  );

CREATE POLICY "phase0_plants_delete_own"
  ON plants FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'delete_own')
    AND created_by = auth.uid()
  );

-- ============================================
-- 3. MATERIALS POLICIES (phase0_)
-- ============================================

CREATE POLICY "phase0_materials_select"
  ON materials FOR SELECT TO authenticated
  USING (
    organization_id IS NULL
    OR
    has_org_permission(organization_id, 'materials', 'read')
  );

CREATE POLICY "phase0_materials_insert"
  ON materials FOR INSERT TO authenticated
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'create')
  );

CREATE POLICY "phase0_materials_update_any"
  ON materials FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_any')
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_any')
  );

CREATE POLICY "phase0_materials_update_own"
  ON materials FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_own')
    AND created_by = auth.uid()
  );

CREATE POLICY "phase0_materials_delete_any"
  ON materials FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'delete_any')
  );

CREATE POLICY "phase0_materials_delete_own"
  ON materials FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'delete_own')
    AND created_by = auth.uid()
  );

-- ============================================
-- 4. FOLDERS POLICIES (phase0_)
-- ============================================

CREATE POLICY "phase0_folders_select"
  ON folders FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'read'));

CREATE POLICY "phase0_folders_insert"
  ON folders FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'folders', 'create'));

CREATE POLICY "phase0_folders_update_any"
  ON folders FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'update_any'))
  WITH CHECK (has_org_permission(organization_id, 'folders', 'update_any'));

CREATE POLICY "phase0_folders_update_own"
  ON folders FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'folders', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'folders', 'update_own')
    AND created_by = auth.uid()
  );

CREATE POLICY "phase0_folders_delete_any"
  ON folders FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'folders', 'delete_any'));

CREATE POLICY "phase0_folders_delete_own"
  ON folders FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'folders', 'delete_own')
    AND created_by = auth.uid()
  );

-- ============================================
-- 5. QUOTE_ITEMS POLICIES (phase0_)
-- quote_items have quote_id FK; check permission via parent quote's organization
-- ============================================

CREATE POLICY "phase0_quote_items_select"
  ON quote_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes q
      WHERE q.id = quote_items.quote_id
        AND has_org_permission(q.organization_id, 'quote_items', 'read')
    )
  );

CREATE POLICY "phase0_quote_items_insert"
  ON quote_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quotes q
      WHERE q.id = quote_items.quote_id
        AND has_org_permission(q.organization_id, 'quote_items', 'create')
    )
  );

CREATE POLICY "phase0_quote_items_update"
  ON quote_items FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes q
      WHERE q.id = quote_items.quote_id
        AND has_org_permission(q.organization_id, 'quote_items', 'update_any')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quotes q
      WHERE q.id = quote_items.quote_id
        AND has_org_permission(q.organization_id, 'quote_items', 'update_any')
    )
  );

CREATE POLICY "phase0_quote_items_delete"
  ON quote_items FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes q
      WHERE q.id = quote_items.quote_id
        AND has_org_permission(q.organization_id, 'quote_items', 'delete_any')
    )
  );

-- ============================================
-- 6. AUDIT LOG TABLE FOR ROLE CHANGES
-- ============================================

CREATE TABLE IF NOT EXISTS role_change_audit (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  old_role TEXT,
  old_role_id UUID REFERENCES role_definitions(id) ON DELETE SET NULL,
  new_role TEXT,
  new_role_id UUID REFERENCES role_definitions(id) ON DELETE SET NULL,
  changed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  change_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_role_audit_org ON role_change_audit(organization_id);
CREATE INDEX IF NOT EXISTS idx_role_audit_target_user ON role_change_audit(target_user_id);
CREATE INDEX IF NOT EXISTS idx_role_audit_created_at ON role_change_audit(created_at DESC);

-- Enable RLS (owners/admins can view their org's audit)
ALTER TABLE role_change_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "phase0_role_audit_select"
  ON role_change_audit FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'organization', 'manage_members'));

-- Insertion allowed via trigger or admin-only inserts
CREATE POLICY "phase0_role_audit_insert"
  ON role_change_audit FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id, 'organization', 'manage_members'));

-- ============================================
-- 7. TRIGGER TO AUTO-LOG ROLE CHANGES
-- ============================================

CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role OR OLD.role_id IS DISTINCT FROM NEW.role_id THEN
    INSERT INTO role_change_audit (
      organization_id,
      target_user_id,
      old_role,
      old_role_id,
      new_role,
      new_role_id,
      changed_by
    ) VALUES (
      NEW.organization_id,
      NEW.user_id,
      OLD.role,
      OLD.role_id,
      NEW.role,
      NEW.role_id,
      auth.uid()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS role_change_audit_trigger ON organization_members;
CREATE TRIGGER role_change_audit_trigger
  AFTER UPDATE ON organization_members
  FOR EACH ROW
  WHEN (OLD.role IS DISTINCT FROM NEW.role OR OLD.role_id IS DISTINCT FROM NEW.role_id)
  EXECUTE FUNCTION log_role_change();

-- ============================================
-- 8. VALIDATION QUERIES (Manual)
-- SELECT has_org_permission('<org_uuid>','plants','create');
-- SELECT has_org_permission('<org_uuid>','materials','delete_any');
-- SELECT * FROM role_change_audit WHERE organization_id = '<org_uuid>';

-- ============================================
-- END FINAL EXTENSION
