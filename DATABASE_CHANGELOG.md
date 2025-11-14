# Database Changelog

This document records the ordered, idempotent Phase 0 RBAC & related policy migrations. Each numbered SQL file in `supabase/migrations/` can be re-run safely; use the ordering to apply on a fresh database.

## Migration Sequence
1. 001_roles_tables.sql – Core RBAC tables (`role_definitions`, `role_permissions`).
2. 002_augment_org_members.sql – Adds `role_id` to `organization_members`, backfills from legacy text role, adds FK & indexes.
3. 003_seed_system_roles.sql – Seeds system roles (owner, admin, member) & baseline permissions scaffolding.
4. 004_function_has_org_permission.sql – Defines `has_org_permission(org_id, perm_resource, perm_action)`.
5. 005_permissions_seed_core.sql – Seeds permissions for organization, clients, invitations.
6. 006_policies_clients_invitations.sql – Idempotent RLS policies for clients & invitations tables.
7. 007_permissions_seed_docs_quotes.sql – Seeds documents + quotes permissions.
8. 008_policies_documents_quotes.sql – RLS policies for documents, document_permissions & quotes.
9. 009_permissions_seed_other.sql – Seeds plants, materials, folders, quote_items permissions.
10. 010_policies_other.sql – RLS policies for plants, materials, folders, quote_items.
11. 011_audit_role_changes.sql – Audit table + trigger for tracking member role changes.

## Idempotency Conventions
- Tables: `CREATE TABLE IF NOT EXISTS`.
- Functions: `CREATE OR REPLACE FUNCTION` (avoid dropping due to dependency chains).
- Policies: `DROP POLICY IF EXISTS` followed by `CREATE POLICY`.
- Triggers: `DROP TRIGGER IF EXISTS` before create.
- Inserts: Use `ON CONFLICT DO NOTHING` when uniqueness is enforced.

## Applying Migrations
On a fresh database, run files sequentially (001→011). For existing deployments, you can re-run any file after a change; only modified files need redeployment.

## Rollback Guidance
- Permissions / policies: Re-run prior file versions or drop specific policy names.
- Function changes: Adjust in place via `CREATE OR REPLACE FUNCTION`; avoid drops unless all dependent policies are removed.
- Table structural rollback: Requires manual `ALTER TABLE` statements (not automated here).

## Future Extensions
- Add granular actions: introduce new rows in `role_permissions` then create policies referencing them.
- Additional audit domains: replicate pattern from `011_audit_role_changes.sql`.
- Version tagging: optionally add an internal meta table recording applied migration numbers & timestamps.

## Deprecated Legacy Scripts
Legacy monolithic files (`roles_phase0.sql`, `roles_phase0_extend.sql`, `roles_phase0_final.sql`) are superseded; retain short-term for reference, then remove after verifying parity.

