# Database Migration Guide - v2.0

> **Complete rebuild of Greenline SaaS database with clean, extensible architecture**

---

## 📋 Overview

This guide walks you through applying the new v2 database architecture to your Supabase project. The migrations are designed to be run sequentially and are fully idempotent (safe to re-run).

### What's Included

- **18 Migration Files** in `supabase/migrations/v2/`
- **Comprehensive Architecture** documented in `DATABASE_ARCHITECTURE.md`
- **Clean Foundation** for future feature development

---

## 🎯 Prerequisites

✅ Supabase CLI installed (v2.58.5+)  
✅ Supabase project created and linked  
✅ Database cleared (you've already done this!)  
✅ Backup of any critical data (if applicable)

---

## 🚀 Option 1: Apply All Migrations at Once (Recommended)

### Step 1: Navigate to Project Directory

```powershell
cd "C:\Users\jendg\OneDrive\Documents\greenline SaaS"
```

### Step 2: Link to Your Supabase Project (if not already linked)

```powershell
supabase link --project-ref your-project-ref
```

Find your project ref in Supabase Dashboard → Settings → General → Reference ID

### Step 3: Push All Migrations

```powershell
# This applies all migrations in v2/ folder in order
supabase db push --db-url "your-connection-string"
```

Or if linked:

```powershell
supabase db push
```

This will automatically:
- Run migrations 001 through 018 in order
- Create all tables, indexes, and constraints
- Set up RLS policies
- Create triggers and functions
- Seed system roles and permissions

### Step 4: Verify Deployment

```powershell
# Check if tables were created
supabase db diff
```

Or visit your Supabase Dashboard → Table Editor to see all tables.

---

## 🔧 Option 2: Apply Migrations Manually (Step-by-Step)

If you prefer to apply migrations one at a time or want to understand what each does:

### Via Supabase SQL Editor (Web)

1. Go to your Supabase Dashboard
2. Click **SQL Editor**
3. Copy and paste each migration file in order (001 → 018)
4. Click **Run** for each migration
5. Verify no errors in the output

### Via Supabase CLI

```powershell
# Apply specific migration
supabase db push --file .\supabase\migrations\v2\001_enable_extensions.sql
supabase db push --file .\supabase\migrations\v2\002_create_organizations.sql
# ... continue through 018
```

---

## 📦 Migration Files Overview

| File | Description | Key Components |
|------|-------------|----------------|
| `001_enable_extensions.sql` | Enable PostgreSQL extensions | pgcrypto for UUIDs |
| `002_create_organizations.sql` | Root tenant table | Organizations + indexes + RLS |
| `003_create_role_system.sql` | RBAC tables | role_definitions, role_permissions |
| `004_seed_system_roles.sql` | Seed roles | owner, admin, member, viewer |
| `005_create_organization_members.sql` | User-org junction | Members with role assignments |
| `006_create_invitations.sql` | Team invitations | Invitation system with tokens |
| `007_seed_permissions.sql` | Seed permissions | Full permission matrix for roles |
| `008_create_permission_function.sql` | Permission check | has_org_permission() function |
| `009_create_rls_policies_core.sql` | Core RLS policies | Organizations, members, roles |
| `010_create_clients.sql` | Clients table | Customer records |
| `011_create_projects.sql` | Projects table | Project management |
| `012_create_quotes.sql` | Quotes + items | Quote generation system |
| `013_create_plants_materials.sql` | Product catalog | Plants & materials tables |
| `014_create_documents.sql` | Document system | Folders, documents, versions |
| `015_create_rls_policies_business.sql` | Business RLS | Clients, projects, quotes, plants |
| `016_create_rls_policies_documents.sql` | Document RLS | Folders, documents, permissions |
| `017_create_audit_tables.sql` | Audit system | Comprehensive audit logging |
| `018_create_triggers.sql` | Automation | Timestamps, versioning, auditing |

---

## ✅ Post-Migration Verification

### 1. Check Table Count

```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
```

**Expected**: 21 tables

### 2. Check System Roles

```sql
SELECT name, display_name, is_system FROM role_definitions;
```

**Expected**: 4 roles (owner, admin, member, viewer)

### 3. Check Permissions Count

```sql
SELECT rd.name, COUNT(rp.id) as permission_count
FROM role_definitions rd
LEFT JOIN role_permissions rp ON rp.role_id = rd.id
GROUP BY rd.name;
```

**Expected**:
- owner: ~35 permissions
- admin: ~28 permissions
- member: ~15 permissions
- viewer: ~8 permissions

### 4. Test Permission Function

```sql
-- This should return false (no user context yet)
SELECT has_org_permission(
  'some-uuid'::uuid, 
  'clients', 
  'read'
);
```

### 5. Check RLS Policies

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Expected**: ~60+ policies across all tables

---

## 🧪 Testing the New Database

### Create Your First Organization

1. Sign up in your app at `/signup`
2. Enter organization name (e.g., "Test Landscaping")
3. System will:
   - Create organization record
   - Add you as owner (via trigger/application logic)
   - Assign owner role

### Verify Multi-Tenancy

```sql
-- Should see your organization
SELECT * FROM organizations;

-- Should see your membership
SELECT om.*, rd.name as role_name
FROM organization_members om
JOIN role_definitions rd ON rd.id = om.role_id;
```

### Test Permission System

```sql
-- Check your permissions (run after signup)
SELECT DISTINCT rp.resource, rp.action
FROM organization_members om
JOIN role_permissions rp ON rp.role_id = om.role_id
WHERE om.user_id = auth.uid()
ORDER BY rp.resource, rp.action;
```

---

## 🔄 Rollback Instructions (If Needed)

If something goes wrong and you need to start over:

### Option A: Drop All Tables (Nuclear)

```sql
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
```

Then re-run all migrations.

### Option B: Use Supabase Reset (Local Only)

```powershell
supabase db reset
```

**WARNING**: This only works for local development databases started with `supabase start`.

---

## 🎓 Next Steps After Migration

### 1. Update Application Code

Your frontend/backend needs to be updated to work with the new schema:

#### Auth Store (`src/stores/auth.js`)
- Update to fetch `role_id` from `organization_members`
- Join with `role_definitions` to get role name
- Cache permissions for current user

Example query:
```javascript
const { data, error } = await supabase
  .from('organization_members')
  .select(`
    *,
    role:role_definitions(name, display_name),
    organization:organizations(*)
  `)
  .eq('user_id', user.id)
  .single();
```

#### Permission Checks
Replace hard-coded role checks with permission checks:

**Old:**
```javascript
if (userRole === 'admin' || userRole === 'owner') {
  // allow action
}
```

**New:**
```javascript
import { hasPermission } from '@/lib/permissions'

if (hasPermission('clients', 'update_any')) {
  // allow action
}
```

### 2. Seed Initial Data (Optional)

If you want global plants/materials available to all orgs:

```sql
-- Example: Insert global plant
INSERT INTO plants (
  organization_id,  -- NULL for global
  name,
  scientific_name,
  type,
  price
) VALUES (
  NULL,
  'Red Maple',
  'Acer rubrum',
  'tree',
  125.00
);
```

Create a seed file in `supabase/seed_global_data.sql` for this.

### 3. Configure Application Signup Flow

When users sign up, ensure your application:
1. Creates organization record
2. Creates organization_member record linking user to org
3. Assigns appropriate role_id (owner for first user)

Example service function:
```javascript
async function createOrganizationForUser(userId, orgName, orgSlug) {
  // 1. Create organization
  const { data: org, error: orgError } = await supabase
    .from('organizations')
    .insert({
      name: orgName,
      slug: orgSlug,
      owner_id: userId
    })
    .select()
    .single();

  if (orgError) throw orgError;

  // 2. Get owner role_id
  const { data: ownerRole } = await supabase
    .from('role_definitions')
    .select('id')
    .eq('name', 'owner')
    .single();

  // 3. Add user as member with owner role
  const { error: memberError } = await supabase
    .from('organization_members')
    .insert({
      organization_id: org.id,
      user_id: userId,
      role_id: ownerRole.id
    });

  if (memberError) throw memberError;

  return org;
}
```

---

## 📊 Monitoring & Performance

### Slow Query Monitoring

```sql
-- Enable query stats
ALTER DATABASE postgres SET track_activity_stats = on;

-- View slow queries (run after some usage)
SELECT query, calls, mean_exec_time, stddev_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- milliseconds
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### RLS Policy Performance

If you notice slow queries, check if policies are optimized:

```sql
-- Example: Explain analyze a query
EXPLAIN ANALYZE
SELECT * FROM clients WHERE organization_id = 'some-uuid';
```

Look for `Seq Scan` (bad) vs `Index Scan` (good).

---

## 🐛 Common Issues & Solutions

### Issue: "permission denied for table X"

**Cause**: RLS is enabled but no policies match your user context.  
**Solution**: Verify you're authenticated and have organization membership:

```sql
SELECT auth.uid();  -- Should return your user UUID
SELECT * FROM organization_members WHERE user_id = auth.uid();
```

### Issue: "null value in column violates not-null constraint"

**Cause**: Missing required fields (created_by, updated_by, etc.).  
**Solution**: Always set these fields in your application inserts:

```javascript
.insert({
  // ... other fields
  created_by: user.id,
  updated_by: user.id
})
```

### Issue: Migrations fail partway through

**Cause**: Dependency issue or syntax error.  
**Solution**: Check the error message, fix the migration file, then:

```powershell
# Continue from where it failed
supabase db push --file .\supabase\migrations\v2\XXX_failed_migration.sql
```

---

## 📚 Additional Resources

- **Database Architecture**: `DATABASE_ARCHITECTURE.md`
- **Supabase RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL Functions**: https://www.postgresql.org/docs/current/sql-createfunction.html
- **Old Migrations (archived)**: `supabase/_archive/`

---

## 🎉 You're All Set!

Your database now has:
- ✅ Clean, normalized schema
- ✅ Flexible RBAC system
- ✅ Multi-tenancy with RLS
- ✅ Comprehensive audit trails
- ✅ Auto-versioning for documents
- ✅ Performance-optimized indexes
- ✅ Production-ready security

**Next**: Update your application code to use the new schema and start building features! 🚀

---

## 💬 Need Help?

If you encounter issues during migration:
1. Check the error message carefully
2. Review the specific migration file causing the issue
3. Verify your Supabase project is accessible
4. Check that you have the latest Supabase CLI version

Good luck! 🌿
