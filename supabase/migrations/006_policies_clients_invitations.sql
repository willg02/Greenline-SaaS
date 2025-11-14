-- 006_policies_clients_invitations.sql
-- Drops & recreates phase0 clients and invitations policies (idempotent)

-- Clients
DROP POLICY IF EXISTS "phase0_clients_select" ON clients;
DROP POLICY IF EXISTS "phase0_clients_insert" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_update_own" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_any" ON clients;
DROP POLICY IF EXISTS "phase0_clients_delete_own" ON clients;

CREATE POLICY "phase0_clients_select" ON clients FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'clients','read'));
CREATE POLICY "phase0_clients_insert" ON clients FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'clients','create'));
CREATE POLICY "phase0_clients_update_any" ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'clients','update_any'))
  WITH CHECK (has_org_permission(organization_id,'clients','update_any'));
CREATE POLICY "phase0_clients_update_own" ON clients FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'clients','update_own') AND created_by = auth.uid())
  WITH CHECK (has_org_permission(organization_id,'clients','update_own') AND created_by = auth.uid());
CREATE POLICY "phase0_clients_delete_any" ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'clients','delete_any'));
CREATE POLICY "phase0_clients_delete_own" ON clients FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'clients','delete_own') AND created_by = auth.uid());

-- Invitations
DROP POLICY IF EXISTS "phase0_invitations_select" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_insert" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_update" ON organization_invitations;
DROP POLICY IF EXISTS "phase0_invitations_delete" ON organization_invitations;

CREATE POLICY "phase0_invitations_select" ON organization_invitations FOR SELECT TO authenticated
  USING (has_org_permission(organization_id,'invitations','read'));
CREATE POLICY "phase0_invitations_insert" ON organization_invitations FOR INSERT TO authenticated
  WITH CHECK (has_org_permission(organization_id,'invitations','create'));
CREATE POLICY "phase0_invitations_update" ON organization_invitations FOR UPDATE TO authenticated
  USING (has_org_permission(organization_id,'invitations','delete_any'))
  WITH CHECK (has_org_permission(organization_id,'invitations','delete_any'));
CREATE POLICY "phase0_invitations_delete" ON organization_invitations FOR DELETE TO authenticated
  USING (has_org_permission(organization_id,'invitations','delete_any'));
