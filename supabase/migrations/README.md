# Database Migrations v2.0

This directory contains the complete database schema for Greenline SaaS v2.0 architecture.

## Quick Start

Apply all migrations:
```powershell
supabase db push
```

## Migration Files (Apply in Order)

1. ✅ `001_enable_extensions.sql` - PostgreSQL extensions
2. ✅ `002_create_organizations.sql` - Organizations table
3. ✅ `003_create_role_system.sql` - RBAC tables
4. ✅ `004_seed_system_roles.sql` - System roles (owner, admin, member, viewer)
5. ✅ `005_create_organization_members.sql` - User-org junction
6. ✅ `006_create_invitations.sql` - Team invitations
7. ✅ `007_seed_permissions.sql` - Permission matrix
8. ✅ `008_create_permission_function.sql` - has_org_permission()
9. ✅ `009_create_rls_policies_core.sql` - Core RLS policies
10. ✅ `010_create_clients.sql` - Clients table
11. ✅ `011_create_projects.sql` - Projects table
12. ✅ `012_create_quotes.sql` - Quotes + quote items
13. ✅ `013_create_plants_materials.sql` - Plants & materials catalog
14. ✅ `014_create_documents.sql` - Document management system
15. ✅ `015_create_rls_policies_business.sql` - Business tables RLS
16. ✅ `016_create_rls_policies_documents.sql` - Documents RLS
17. ✅ `017_create_audit_tables.sql` - Audit logging
18. ✅ `018_create_triggers.sql` - Automation triggers

## Features

- 🔐 **Row Level Security** on all tables
- 👥 **Flexible RBAC** with permissions system
- 🏢 **Multi-Tenancy** with organization isolation
- 📝 **Audit Trails** for compliance
- 🔄 **Auto-Versioning** for documents
- 📊 **Performance Optimized** with strategic indexes
- 🚀 **Migration Safe** - idempotent, additive changes only

## Documentation

- **Full Guide**: See `/MIGRATION_GUIDE_V2.md` in project root
- **Architecture**: See `/DATABASE_ARCHITECTURE.md` in project root

## Tables Created (21 Total)

**Core Identity:**
- organizations
- role_definitions
- role_permissions
- organization_members
- organization_invitations

**Business Data:**
- clients
- projects
- quotes
- quote_items
- plants
- materials

**Documents:**
- folders
- documents
- document_versions
- document_permissions

**Audit:**
- audit_logs
- role_change_audit

## Post-Migration

After running migrations, verify:

```sql
-- Check tables
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
-- Expected: 21

-- Check roles
SELECT name FROM role_definitions;
-- Expected: owner, admin, member, viewer

-- Check policies
SELECT COUNT(*) FROM pg_policies 
WHERE schemaname = 'public';
-- Expected: 60+
```

## Need Help?

Refer to the comprehensive migration guide: `/MIGRATION_GUIDE_V2.md`
