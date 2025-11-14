-- ============================================================================
-- Migration: 015 - Create RLS Policies for Business Tables
-- Description: Row Level Security for clients, projects, quotes, plants, materials
-- Dependencies: 014_create_documents.sql
-- ============================================================================

-- ============================================
-- CLIENTS POLICIES
-- ============================================

CREATE POLICY "clients_select"
  ON clients FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'read'));

CREATE POLICY "clients_insert"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'create')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "clients_update_any"
  ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'update_any'))
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "clients_update_own"
  ON clients FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'update_own')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "clients_delete_any"
  ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'clients', 'delete_any'));

CREATE POLICY "clients_delete_own"
  ON clients FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'delete_own')
    AND created_by = auth.uid()
  );

-- ============================================
-- PROJECTS POLICIES
-- ============================================

CREATE POLICY "projects_select"
  ON projects FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'projects', 'read'));

CREATE POLICY "projects_insert"
  ON projects FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'projects', 'create')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "projects_update_any"
  ON projects FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'projects', 'update_any'))
  WITH CHECK (
    has_org_permission(organization_id, 'projects', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "projects_update_own"
  ON projects FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'projects', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'projects', 'update_own')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "projects_delete_any"
  ON projects FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'projects', 'delete_any'));

-- ============================================
-- QUOTES POLICIES
-- ============================================

CREATE POLICY "quotes_select"
  ON quotes FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'read'));

CREATE POLICY "quotes_insert"
  ON quotes FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'quotes', 'create')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "quotes_update_any"
  ON quotes FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'update_any'))
  WITH CHECK (
    has_org_permission(organization_id, 'quotes', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "quotes_update_own"
  ON quotes FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'quotes', 'update_own')
    AND created_by = auth.uid()
  )
  WITH CHECK (
    has_org_permission(organization_id, 'quotes', 'update_own')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

CREATE POLICY "quotes_delete_any"
  ON quotes FOR DELETE TO authenticated
  USING (has_org_permission(organization_id, 'quotes', 'delete_any'));

CREATE POLICY "quotes_delete_own"
  ON quotes FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'quotes', 'delete_own')
    AND created_by = auth.uid()
  );

-- ============================================
-- QUOTE ITEMS POLICIES
-- ============================================

CREATE POLICY "quote_items_select"
  ON quote_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
        AND has_org_permission(quotes.organization_id, 'quotes', 'read')
    )
  );

CREATE POLICY "quote_items_insert"
  ON quote_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
        AND has_org_permission(quotes.organization_id, 'quotes', 'create')
    )
  );

CREATE POLICY "quote_items_update"
  ON quote_items FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
        AND (
          has_org_permission(quotes.organization_id, 'quotes', 'update_any')
          OR (has_org_permission(quotes.organization_id, 'quotes', 'update_own') 
              AND quotes.created_by = auth.uid())
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
        AND (
          has_org_permission(quotes.organization_id, 'quotes', 'update_any')
          OR (has_org_permission(quotes.organization_id, 'quotes', 'update_own') 
              AND quotes.created_by = auth.uid())
        )
    )
  );

CREATE POLICY "quote_items_delete"
  ON quote_items FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
        AND (
          has_org_permission(quotes.organization_id, 'quotes', 'delete_any')
          OR (has_org_permission(quotes.organization_id, 'quotes', 'delete_own') 
              AND quotes.created_by = auth.uid())
        )
    )
  );

-- ============================================
-- PLANTS POLICIES
-- ============================================

CREATE POLICY "plants_select"
  ON plants FOR SELECT TO authenticated
  USING (
    organization_id IS NULL  -- Global plants
    OR has_org_permission(organization_id, 'plants', 'read')
  );

CREATE POLICY "plants_insert"
  ON plants FOR INSERT TO authenticated
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'create')
    AND created_by = auth.uid()
  );

CREATE POLICY "plants_update_any"
  ON plants FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_any')
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "plants_delete_any"
  ON plants FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'delete_any')
  );

-- ============================================
-- MATERIALS POLICIES
-- ============================================

CREATE POLICY "materials_select"
  ON materials FOR SELECT TO authenticated
  USING (
    organization_id IS NULL  -- Global materials
    OR has_org_permission(organization_id, 'materials', 'read')
  );

CREATE POLICY "materials_insert"
  ON materials FOR INSERT TO authenticated
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'create')
    AND created_by = auth.uid()
  );

CREATE POLICY "materials_update_any"
  ON materials FOR UPDATE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_any')
  )
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'update_any')
    AND updated_by = auth.uid()
  );

CREATE POLICY "materials_delete_any"
  ON materials FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'materials', 'delete_any')
  );
