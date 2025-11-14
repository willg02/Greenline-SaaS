-- 010_policies_other.sql
-- Drops & recreates phase0 policies for plants, materials, folders, quote_items

-- Plants
DROP POLICY IF EXISTS "phase0_plants_select" ON plants;
DROP POLICY IF EXISTS "phase0_plants_insert" ON plants;
DROP POLICY IF EXISTS "phase0_plants_update_any" ON plants;
DROP POLICY IF EXISTS "phase0_plants_update_own" ON plants;
DROP POLICY IF EXISTS "phase0_plants_delete_any" ON plants;
DROP POLICY IF EXISTS "phase0_plants_delete_own" ON plants;
CREATE POLICY "phase0_plants_select" ON plants FOR SELECT TO authenticated USING (organization_id IS NULL OR has_org_permission(organization_id,'plants','read'));
CREATE POLICY "phase0_plants_insert" ON plants FOR INSERT TO authenticated WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','create'));
CREATE POLICY "phase0_plants_update_any" ON plants FOR UPDATE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_any')) WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_any'));
CREATE POLICY "phase0_plants_update_own" ON plants FOR UPDATE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_own') AND created_by = auth.uid()) WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_plants_delete_any" ON plants FOR DELETE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','delete_any'));
CREATE POLICY "phase0_plants_delete_own" ON plants FOR DELETE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'plants','delete_own') AND created_by = auth.uid());

-- Materials
DROP POLICY IF EXISTS "phase0_materials_select" ON materials;
DROP POLICY IF EXISTS "phase0_materials_insert" ON materials;
DROP POLICY IF EXISTS "phase0_materials_update_any" ON materials;
DROP POLICY IF EXISTS "phase0_materials_update_own" ON materials;
DROP POLICY IF EXISTS "phase0_materials_delete_any" ON materials;
DROP POLICY IF EXISTS "phase0_materials_delete_own" ON materials;
CREATE POLICY "phase0_materials_select" ON materials FOR SELECT TO authenticated USING (organization_id IS NULL OR has_org_permission(organization_id,'materials','read'));
CREATE POLICY "phase0_materials_insert" ON materials FOR INSERT TO authenticated WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','create'));
CREATE POLICY "phase0_materials_update_any" ON materials FOR UPDATE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_any')) WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_any'));
CREATE POLICY "phase0_materials_update_own" ON materials FOR UPDATE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_own') AND created_by = auth.uid()) WITH CHECK (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_materials_delete_any" ON materials FOR DELETE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','delete_any'));
CREATE POLICY "phase0_materials_delete_own" ON materials FOR DELETE TO authenticated USING (organization_id IS NOT NULL AND has_org_permission(organization_id,'materials','delete_own') AND created_by = auth.uid());

-- Folders
DROP POLICY IF EXISTS "phase0_folders_select" ON folders;
DROP POLICY IF EXISTS "phase0_folders_insert" ON folders;
DROP POLICY IF EXISTS "phase0_folders_update_any" ON folders;
DROP POLICY IF EXISTS "phase0_folders_update_own" ON folders;
DROP POLICY IF EXISTS "phase0_folders_delete_any" ON folders;
DROP POLICY IF EXISTS "phase0_folders_delete_own" ON folders;
CREATE POLICY "phase0_folders_select" ON folders FOR SELECT TO authenticated USING (has_org_permission(organization_id,'folders','read'));
CREATE POLICY "phase0_folders_insert" ON folders FOR INSERT TO authenticated WITH CHECK (has_org_permission(organization_id,'folders','create'));
CREATE POLICY "phase0_folders_update_any" ON folders FOR UPDATE TO authenticated USING (has_org_permission(organization_id,'folders','update_any')) WITH CHECK (has_org_permission(organization_id,'folders','update_any'));
CREATE POLICY "phase0_folders_update_own" ON folders FOR UPDATE TO authenticated USING (has_org_permission(organization_id,'folders','update_own') AND created_by = auth.uid()) WITH CHECK (has_org_permission(organization_id,'folders','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_folders_delete_any" ON folders FOR DELETE TO authenticated USING (has_org_permission(organization_id,'folders','delete_any'));
CREATE POLICY "phase0_folders_delete_own" ON folders FOR DELETE TO authenticated USING (has_org_permission(organization_id,'folders','delete_own') AND created_by = auth.uid());

-- Quote Items
DROP POLICY IF EXISTS "phase0_quote_items_select" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_insert" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_update" ON quote_items;
DROP POLICY IF EXISTS "phase0_quote_items_delete" ON quote_items;
CREATE POLICY "phase0_quote_items_select" ON quote_items FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','read')));
CREATE POLICY "phase0_quote_items_insert" ON quote_items FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','create')));
CREATE POLICY "phase0_quote_items_update" ON quote_items FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','update_any'))) WITH CHECK (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','update_any')));
CREATE POLICY "phase0_quote_items_delete" ON quote_items FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM quotes q WHERE q.id = quote_items.quote_id AND has_org_permission(q.organization_id,'quote_items','delete_any')));
