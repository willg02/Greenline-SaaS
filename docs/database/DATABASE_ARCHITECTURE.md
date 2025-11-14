# Greenline SaaS - Comprehensive Database Architecture v2.0

> **Purpose**: Clean, scalable PostgreSQL database architecture for a multi-tenant landscaping SaaS platform.
> **Design Philosophy**: Extensible, normalized, secure by default, migration-friendly.

---

## 🎯 Core Design Principles

1. **Multi-Tenancy First**: All business data scoped to `organization_id`
2. **Flexible RBAC**: Permission-based access control, not hard-coded roles
3. **Audit-Ready**: Track who did what, when (created_by, updated_by, timestamps)
4. **Soft Architecture**: Use constraints, not application logic, for data integrity
5. **Extension-Friendly**: Add features without altering core schema
6. **Performance-Aware**: Strategic indexes, optimized RLS policies
7. **Migration-Safe**: No DROP-CREATE cycles; only additive changes

---

## 📊 Entity Relationship Overview

```
┌─────────────────┐
│   auth.users    │ (Supabase managed)
└────────┬────────┘
         │
         │ 1:N
         ├──────────────────────────┐
         │                          │
┌────────▼────────┐        ┌────────▼───────────┐
│ organizations   │◄───────┤ organization_      │
│                 │   N:1  │ members            │
└────────┬────────┘        └────────┬───────────┘
         │                          │
         │                          │ N:1
         │                   ┌──────▼──────────┐
         │                   │ role_          │
         │                   │ definitions    │
         │                   └──────┬──────────┘
         │                          │ 1:N
         │                   ┌──────▼──────────┐
         │                   │ role_          │
         │                   │ permissions    │
         │                   └─────────────────┘
         │
         │ 1:N (org-scoped data)
         ├────────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
         │                │              │              │              │              │
    ┌────▼─────┐   ┌─────▼────┐   ┌────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
    │ clients  │   │ quotes   │   │ plants   │  │ materials │  │ folders   │  │ projects  │
    └──────────┘   └────┬─────┘   └──────────┘  └───────────┘  └─────┬─────┘  └───────────┘
                        │                                              │
                        │ 1:N                                          │ 1:N
                   ┌────▼──────┐                                  ┌────▼────────┐
                   │ quote_    │                                  │ documents   │
                   │ items     │                                  └─────┬───────┘
                   └───────────┘                                        │ 1:N
                                                                   ┌────▼──────────┐
                                                                   │ document_     │
                                                                   │ versions      │
                                                                   └───────────────┘
```

---

## 🗄️ Database Schema

### 1. **Core Identity & Tenancy**

#### 1.1 `organizations` (Root tenant entity)

```sql
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  
  -- Subscription management
  subscription_tier TEXT NOT NULL DEFAULT 'solo' 
    CHECK (subscription_tier IN ('solo', 'team', 'enterprise')),
  subscription_status TEXT NOT NULL DEFAULT 'trialing' 
    CHECK (subscription_status IN ('trialing', 'active', 'past_due', 'canceled')),
  trial_ends_at TIMESTAMPTZ,
  
  -- External integrations
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  
  -- Metadata
  settings JSONB DEFAULT '{}'::jsonb, -- Flexible org settings
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ -- Soft delete support
);

CREATE INDEX idx_organizations_owner_id ON organizations(owner_id);
CREATE INDEX idx_organizations_slug ON organizations(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_active ON organizations(subscription_status) 
  WHERE deleted_at IS NULL AND subscription_status = 'active';
```

**Design Notes**:
- `owner_id` uses `RESTRICT` to prevent accidental cascade deletion
- `slug` for friendly URLs (e.g., `/org/greenline-landscaping`)
- `settings` JSONB for org-specific configs without schema changes
- Soft delete via `deleted_at` (preserves data, prevents accidental loss)

---

#### 1.2 `role_definitions` (Flexible role system)

```sql
CREATE TABLE role_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  is_system BOOLEAN NOT NULL DEFAULT false, -- Prevent deletion of core roles
  scope TEXT NOT NULL DEFAULT 'organization' 
    CHECK (scope IN ('organization', 'project', 'document')), -- Future-proof
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_role_definitions_name ON role_definitions(name);
CREATE INDEX idx_role_definitions_system ON role_definitions(is_system) 
  WHERE is_system = true;

-- System roles (seed data)
INSERT INTO role_definitions (name, display_name, description, is_system) VALUES
  ('owner', 'Owner', 'Full control: billing, members, all data', true),
  ('admin', 'Administrator', 'Manage team and data, no billing access', true),
  ('member', 'Member', 'Standard access: create/edit own data', true),
  ('viewer', 'Viewer', 'Read-only access to organization data', true);
```

**Design Notes**:
- Extensible: Add custom roles without schema changes
- `is_system` prevents accidental deletion of critical roles
- `scope` enables future project-level or document-level roles
- Clear `display_name` for UI, `name` for code references

---

#### 1.3 `role_permissions` (Permission definitions)

```sql
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  resource TEXT NOT NULL, -- e.g., 'clients', 'quotes', 'documents'
  action TEXT NOT NULL,   -- e.g., 'read', 'create', 'update_any', 'delete_own'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role_id, resource, action)
);

CREATE INDEX idx_role_permissions_lookup ON role_permissions(role_id, resource, action);
CREATE INDEX idx_role_permissions_resource ON role_permissions(resource);
```

**Permission Taxonomy**:

| Action | Scope | Description |
|--------|-------|-------------|
| `read` | All records | View any record in organization |
| `create` | New records | Create new records |
| `update_own` | Own records | Update records you created |
| `update_any` | All records | Update any record in organization |
| `delete_own` | Own records | Delete records you created |
| `delete_any` | All records | Delete any record in organization |
| `manage_members` | Organization | Add/remove team members |
| `manage_settings` | Organization | Update org settings |
| `configure_billing` | Organization | Manage subscription and billing |
| `publish` | Documents | Publish/unpublish documents |
| `archive` | Documents | Archive/restore documents |
| `export` | Reports | Export data/reports |

**Standard Permission Sets** (seed data):

```sql
-- Owner: Full access
INSERT INTO role_permissions (role_id, resource, action)
SELECT id, resource, action FROM role_definitions, 
  (VALUES 
    ('organization', 'manage_members'),
    ('organization', 'manage_settings'),
    ('organization', 'configure_billing'),
    ('clients', 'read'), ('clients', 'create'), ('clients', 'update_any'), ('clients', 'delete_any'),
    ('quotes', 'read'), ('quotes', 'create'), ('quotes', 'update_any'), ('quotes', 'delete_any'),
    ('documents', 'read'), ('documents', 'create'), ('documents', 'update_any'), 
    ('documents', 'delete_any'), ('documents', 'publish'), ('documents', 'archive'),
    ('plants', 'read'), ('plants', 'create'), ('plants', 'update_any'), ('plants', 'delete_any'),
    ('materials', 'read'), ('materials', 'create'), ('materials', 'update_any'), ('materials', 'delete_any')
  ) AS perms(resource, action)
WHERE name = 'owner';

-- Admin: Operational management, no billing
INSERT INTO role_permissions (role_id, resource, action)
SELECT id, resource, action FROM role_definitions,
  (VALUES
    ('organization', 'manage_members'),
    ('organization', 'manage_settings'),
    ('clients', 'read'), ('clients', 'create'), ('clients', 'update_any'), ('clients', 'delete_any'),
    ('quotes', 'read'), ('quotes', 'create'), ('quotes', 'update_any'), ('quotes', 'delete_any'),
    ('documents', 'read'), ('documents', 'create'), ('documents', 'update_any'), 
    ('documents', 'publish'), ('documents', 'archive'),
    ('plants', 'read'), ('plants', 'create'), ('plants', 'update_any'),
    ('materials', 'read'), ('materials', 'create'), ('materials', 'update_any')
  ) AS perms(resource, action)
WHERE name = 'admin';

-- Member: Create/edit own, read all
INSERT INTO role_permissions (role_id, resource, action)
SELECT id, resource, action FROM role_definitions,
  (VALUES
    ('clients', 'read'), ('clients', 'create'), ('clients', 'update_own'), ('clients', 'delete_own'),
    ('quotes', 'read'), ('quotes', 'create'), ('quotes', 'update_own'), ('quotes', 'delete_own'),
    ('documents', 'read'), ('documents', 'create'), ('documents', 'update_own'),
    ('plants', 'read'), ('materials', 'read')
  ) AS perms(resource, action)
WHERE name = 'member';

-- Viewer: Read-only
INSERT INTO role_permissions (role_id, resource, action)
SELECT id, resource, action FROM role_definitions,
  (VALUES
    ('clients', 'read'), ('quotes', 'read'), ('documents', 'read'),
    ('plants', 'read'), ('materials', 'read')
  ) AS perms(resource, action)
WHERE name = 'viewer';
```

---

#### 1.4 `organization_members` (User-Org-Role junction)

```sql
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE RESTRICT,
  
  -- Metadata
  invited_by UUID REFERENCES auth.users(id),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(organization_id, user_id)
);

CREATE INDEX idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX idx_org_members_role_id ON organization_members(role_id);
CREATE INDEX idx_org_members_composite ON organization_members(organization_id, user_id, role_id);
```

**Design Notes**:
- One user can belong to multiple organizations
- `role_id` uses `RESTRICT` to prevent orphaned members
- `invited_by` tracks who added the member (audit trail)
- Composite index optimizes permission checks

---

#### 1.5 `organization_invitations` (Team invitations)

```sql
CREATE TABLE organization_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  
  status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(organization_id, email, status) -- Prevent duplicate active invitations
);

CREATE INDEX idx_org_invitations_org_status ON organization_invitations(organization_id, status);
CREATE INDEX idx_org_invitations_token ON organization_invitations(token) WHERE status = 'pending';
CREATE INDEX idx_org_invitations_expires ON organization_invitations(expires_at) WHERE status = 'pending';
```

**Design Notes**:
- Secure random token for invitation links
- Auto-expire after 7 days
- Prevent duplicate active invitations per email
- Track who invited and when accepted

---

### 2. **Business Core Entities**

#### 2.1 `clients` (Customer records)

```sql
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Basic info
  name TEXT NOT NULL,
  company_name TEXT,
  email TEXT,
  phone TEXT,
  
  -- Address
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  country TEXT DEFAULT 'US',
  
  -- Metadata
  notes TEXT,
  tags TEXT[], -- Array for flexible categorization
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' 
    CHECK (status IN ('active', 'inactive', 'archived')),
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_clients_org_id ON clients(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_status ON clients(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_created_by ON clients(created_by);
CREATE INDEX idx_clients_name_search ON clients USING gin(to_tsvector('english', name));
CREATE INDEX idx_clients_tags ON clients USING gin(tags);
```

**Design Notes**:
- `tags` array for flexible categorization (e.g., `['residential', 'vip']`)
- `custom_fields` JSONB for org-specific data
- Full-text search on name via GIN index
- Soft delete support

---

#### 2.2 `projects` (Optional: Project management)

```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  
  -- Basic info
  name TEXT NOT NULL,
  description TEXT,
  
  -- Address (can differ from client address)
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  
  -- Status & Timeline
  status TEXT NOT NULL DEFAULT 'planning' 
    CHECK (status IN ('planning', 'quoted', 'approved', 'in_progress', 'completed', 'on_hold', 'canceled')),
  priority TEXT DEFAULT 'medium' 
    CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  start_date DATE,
  target_completion_date DATE,
  actual_completion_date DATE,
  
  -- Financial
  estimated_budget DECIMAL(12,2),
  actual_cost DECIMAL(12,2),
  
  -- Metadata
  tags TEXT[],
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_projects_org_id ON projects(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_client_id ON projects(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_status ON projects(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_dates ON projects(start_date, target_completion_date) WHERE deleted_at IS NULL;
```

**Design Notes**:
- Links clients to specific projects
- Tracks project lifecycle from planning to completion
- Financial tracking separate from quotes
- Extensible for future features (tasks, milestones, etc.)

---

#### 2.3 `quotes` (Estimate/Quote generation)

```sql
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  
  -- Quote identification
  quote_number TEXT NOT NULL, -- Auto-generated: "2025-0001"
  version INTEGER NOT NULL DEFAULT 1,
  
  -- Client info snapshot (persists even if client deleted)
  client_name TEXT NOT NULL,
  client_email TEXT,
  client_phone TEXT,
  client_address TEXT,
  
  -- Project details
  project_name TEXT,
  project_description TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' 
    CHECK (status IN ('draft', 'pending_review', 'sent', 'viewed', 'accepted', 'rejected', 'expired', 'revised')),
  
  -- Pricing breakdown
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_rate DECIMAL(5,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  discount_reason TEXT,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  
  -- Terms & Validity
  notes TEXT,
  terms_and_conditions TEXT,
  payment_terms TEXT,
  valid_until DATE,
  
  -- Metadata
  tags TEXT[],
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Tracking
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  UNIQUE(organization_id, quote_number, version)
);

CREATE INDEX idx_quotes_org_id ON quotes(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_client_id ON quotes(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_project_id ON quotes(project_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_status ON quotes(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_number ON quotes(organization_id, quote_number);
CREATE INDEX idx_quotes_date_range ON quotes(created_at, valid_until) WHERE deleted_at IS NULL;
```

**Design Notes**:
- `quote_number` + `version` for revision tracking
- Client info snapshotted (immutable record)
- Comprehensive status lifecycle
- Track sent/viewed/accepted timestamps
- Discounts with reason tracking

---

#### 2.4 `quote_items` (Line items in quotes)

```sql
CREATE TABLE quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  
  -- Item reference (optional link to plants/materials)
  plant_id UUID REFERENCES plants(id) ON DELETE SET NULL,
  material_id UUID REFERENCES materials(id) ON DELETE SET NULL,
  
  -- Item details (snapshot for immutability)
  item_type TEXT NOT NULL CHECK (item_type IN ('plant', 'material', 'labor', 'service', 'other')),
  item_name TEXT NOT NULL,
  description TEXT,
  
  -- Pricing
  quantity DECIMAL(10,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit TEXT NOT NULL DEFAULT 'each',
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  
  -- Metadata
  sort_order INTEGER NOT NULL DEFAULT 0,
  category TEXT, -- e.g., "Site Prep", "Planting", "Maintenance"
  notes TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quote_items_quote_id ON quote_items(quote_id);
CREATE INDEX idx_quote_items_plant_id ON quote_items(plant_id) WHERE plant_id IS NOT NULL;
CREATE INDEX idx_quote_items_material_id ON quote_items(material_id) WHERE material_id IS NOT NULL;
CREATE INDEX idx_quote_items_sort ON quote_items(quote_id, sort_order);
```

**Design Notes**:
- Links to `plants`/`materials` optional (for dynamic pricing updates)
- Item details snapshotted (quote remains unchanged if source changes)
- `sort_order` for custom item ordering in PDF exports
- `category` for grouping items in quotes

---

### 3. **Plant & Material Library**

#### 3.1 `plants` (Plant database)

```sql
CREATE TABLE plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  scientific_name TEXT,
  common_names TEXT[], -- Multiple common names
  
  -- Classification
  type TEXT NOT NULL CHECK (type IN ('tree', 'shrub', 'perennial', 'grass', 'groundcover', 'vine', 'annual', 'bulb')),
  category TEXT, -- e.g., "Native", "Ornamental", "Edible"
  is_native BOOLEAN DEFAULT false,
  
  -- Growing conditions
  sun_requirement TEXT CHECK (sun_requirement IN ('full_sun', 'part_sun', 'part_shade', 'full_shade', 'any')),
  water_requirement TEXT CHECK (water_requirement IN ('low', 'medium', 'high', 'very_high')),
  soil_preference TEXT CHECK (soil_preference IN ('clay', 'loam', 'sand', 'any')),
  hardiness_zone_min INTEGER,
  hardiness_zone_max INTEGER,
  
  -- Size
  mature_height_min_inches INTEGER,
  mature_height_max_inches INTEGER,
  mature_width_min_inches INTEGER,
  mature_width_max_inches INTEGER,
  growth_rate TEXT CHECK (growth_rate IN ('slow', 'medium', 'fast')),
  
  -- Characteristics
  bloom_time TEXT, -- e.g., "Spring", "Summer-Fall"
  bloom_color TEXT[],
  foliage_color TEXT[],
  fall_color TEXT,
  
  -- Care
  description TEXT,
  care_notes TEXT,
  maintenance_level TEXT CHECK (maintenance_level IN ('low', 'medium', 'high')),
  deer_resistant BOOLEAN,
  drought_tolerant BOOLEAN,
  pollinator_friendly BOOLEAN,
  
  -- Pricing & Sourcing
  price DECIMAL(10,2),
  price_unit TEXT DEFAULT 'each',
  supplier TEXT,
  supplier_sku TEXT,
  availability_status TEXT DEFAULT 'available' 
    CHECK (availability_status IN ('available', 'limited', 'out_of_stock', 'seasonal', 'discontinued')),
  
  -- Media
  image_url TEXT,
  additional_images TEXT[],
  
  -- Metadata
  tags TEXT[],
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Global plants: organization_id IS NULL
-- Org-specific plants: organization_id is set
CREATE INDEX idx_plants_global ON plants(id) WHERE organization_id IS NULL AND deleted_at IS NULL;
CREATE INDEX idx_plants_org ON plants(organization_id) WHERE organization_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_plants_type ON plants(organization_id, type) WHERE deleted_at IS NULL;
CREATE INDEX idx_plants_native ON plants(is_native) WHERE is_native = true AND deleted_at IS NULL;
CREATE INDEX idx_plants_hardiness ON plants(hardiness_zone_min, hardiness_zone_max) WHERE deleted_at IS NULL;
CREATE INDEX idx_plants_name_search ON plants USING gin(to_tsvector('english', name || ' ' || COALESCE(scientific_name, '')));
CREATE INDEX idx_plants_tags ON plants USING gin(tags);
```

**Design Notes**:
- Global plants (`organization_id IS NULL`) visible to all
- Org-specific custom plants isolated per tenant
- Comprehensive growing requirements for filtering
- Full-text search on name and scientific name
- Flexible arrays for multi-value attributes

---

#### 3.2 `materials` (Construction/landscape materials)

```sql
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  description TEXT,
  
  -- Classification
  type TEXT NOT NULL CHECK (type IN ('soil', 'mulch', 'compost', 'gravel', 'stone', 'sand', 'edging', 'fabric', 'other')),
  category TEXT, -- e.g., "Organic", "Inorganic", "Hardscape"
  
  -- Measurement
  unit TEXT NOT NULL DEFAULT 'cubic_yard',
  coverage_per_unit DECIMAL(10,2), -- sq ft per unit at standard depth
  standard_depth_inches DECIMAL(4,2),
  
  -- Pricing
  price_per_unit DECIMAL(10,2) NOT NULL,
  minimum_order DECIMAL(10,2),
  
  -- Sourcing
  supplier TEXT,
  supplier_sku TEXT,
  availability_status TEXT DEFAULT 'available' 
    CHECK (availability_status IN ('available', 'limited', 'out_of_stock', 'seasonal', 'discontinued')),
  
  -- Media
  image_url TEXT,
  
  -- Metadata
  notes TEXT,
  tags TEXT[],
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_materials_global ON materials(id) WHERE organization_id IS NULL AND deleted_at IS NULL;
CREATE INDEX idx_materials_org ON materials(organization_id) WHERE organization_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_materials_type ON materials(organization_id, type) WHERE deleted_at IS NULL;
CREATE INDEX idx_materials_name_search ON materials USING gin(to_tsvector('english', name));
```

---

### 4. **Document Management (SOPs/Internal Docs)**

#### 4.1 `folders` (Hierarchical organization)

```sql
CREATE TABLE folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  parent_folder_id UUID REFERENCES folders(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  description TEXT,
  color TEXT, -- Hex color for UI
  icon TEXT,  -- Icon name for UI
  
  -- Metadata
  sort_order INTEGER NOT NULL DEFAULT 0,
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_folders_org_id ON folders(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_folders_parent_id ON folders(parent_folder_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_folders_hierarchy ON folders(organization_id, parent_folder_id, sort_order);
```

---

#### 4.2 `documents` (SOPs, procedures, internal docs)

```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
  
  -- Identity
  title TEXT NOT NULL,
  slug TEXT, -- URL-friendly title
  
  -- Content
  content TEXT, -- Rich HTML or Markdown
  content_type TEXT NOT NULL DEFAULT 'html' CHECK (content_type IN ('html', 'markdown', 'plain')),
  
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' 
    CHECK (status IN ('draft', 'review', 'published', 'archived')),
  
  -- Versioning
  version INTEGER NOT NULL DEFAULT 1,
  
  -- Metadata
  tags TEXT[],
  template_id UUID REFERENCES documents(id), -- If created from template
  custom_fields JSONB DEFAULT '{}'::jsonb,
  
  -- Collaboration
  is_locked BOOLEAN DEFAULT false,
  locked_by UUID REFERENCES auth.users(id),
  locked_at TIMESTAMPTZ,
  
  -- Publishing
  published_at TIMESTAMPTZ,
  published_by UUID REFERENCES auth.users(id),
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_documents_org_id ON documents(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_folder_id ON documents(folder_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_status ON documents(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_slug ON documents(organization_id, slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_title_search ON documents USING gin(to_tsvector('english', title));
CREATE INDEX idx_documents_tags ON documents USING gin(tags);
```

---

#### 4.3 `document_versions` (Version history)

```sql
CREATE TABLE document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  
  -- Version snapshot
  version_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_type TEXT NOT NULL,
  status TEXT NOT NULL,
  
  -- Change tracking
  change_description TEXT,
  changed_fields TEXT[], -- Array of field names that changed
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(document_id, version_number)
);

CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_lookup ON document_versions(document_id, version_number DESC);
```

---

#### 4.4 `document_permissions` (Granular access control)

```sql
CREATE TABLE document_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES role_definitions(id) ON DELETE CASCADE,
  
  -- Permissions
  can_view BOOLEAN NOT NULL DEFAULT true,
  can_edit BOOLEAN NOT NULL DEFAULT false,
  can_publish BOOLEAN NOT NULL DEFAULT false,
  can_delete BOOLEAN NOT NULL DEFAULT false,
  can_manage_permissions BOOLEAN NOT NULL DEFAULT false,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(document_id, role_id)
);

CREATE INDEX idx_document_permissions_document ON document_permissions(document_id);
CREATE INDEX idx_document_permissions_role ON document_permissions(role_id);
```

---

### 5. **Audit & Activity Tracking**

#### 5.1 `audit_logs` (Comprehensive audit trail)

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Actor
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT, -- Snapshot in case user deleted
  
  -- Action
  action TEXT NOT NULL, -- e.g., 'created', 'updated', 'deleted', 'published'
  resource_type TEXT NOT NULL, -- e.g., 'client', 'quote', 'document'
  resource_id UUID NOT NULL,
  
  -- Changes
  changes JSONB, -- Before/after values
  metadata JSONB, -- Additional context (IP, user agent, etc.)
  
  -- Timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_org_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(organization_id, action);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(created_at DESC);

-- Partition by month for large datasets (optional, future-proof)
-- CREATE TABLE audit_logs_y2025m01 PARTITION OF audit_logs
--   FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

---

#### 5.2 `role_change_audit` (Specific audit for role changes)

```sql
CREATE TABLE role_change_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  member_id UUID NOT NULL, -- organization_members.id
  user_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Change details
  old_role_id UUID REFERENCES role_definitions(id),
  new_role_id UUID REFERENCES role_definitions(id),
  reason TEXT,
  
  -- Actor
  changed_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_role_change_audit_org ON role_change_audit(organization_id);
CREATE INDEX idx_role_change_audit_user ON role_change_audit(user_id);
CREATE INDEX idx_role_change_audit_timestamp ON role_change_audit(created_at DESC);
```

---

## 🔒 Row Level Security (RLS) Policies

### Core RLS Principles

1. **All policies use `TO authenticated`** - no anonymous access
2. **Organization isolation is ALWAYS enforced** via `organization_id`
3. **Permission checks via `has_org_permission()` function** (see below)
4. **Separate policies for different CRUD operations** (not combined `FOR ALL`)
5. **Owner checks separate from creator checks** (distinguishes update_any from update_own)

---

### Permission Check Function

```sql
CREATE OR REPLACE FUNCTION public.has_org_permission(
  org_id UUID,
  perm_resource TEXT,
  perm_action TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM organization_members om
    JOIN role_permissions rp ON rp.role_id = om.role_id
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND rp.resource = perm_resource
      AND rp.action = perm_action
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Performance: Index on (role_id, resource, action) ensures fast lookups
```

---

### Example RLS Policies

#### `clients` Table

```sql
-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- SELECT: Can read if has 'read' permission
CREATE POLICY "clients_select"
  ON clients FOR SELECT TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'read')
  );

-- INSERT: Can create if has 'create' permission
CREATE POLICY "clients_insert"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'create')
    AND created_by = auth.uid() -- Enforce creator
    AND updated_by = auth.uid()
  );

-- UPDATE: Can update ANY if has 'update_any' OR own if has 'update_own'
CREATE POLICY "clients_update_any"
  ON clients FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'update_any')
  )
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'update_any')
    AND updated_by = auth.uid() -- Track who updated
  );

CREATE POLICY "clients_update_own"
  ON clients FOR UPDATE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'update_own')
    AND created_by = auth.uid() -- Only own records
  )
  WITH CHECK (
    has_org_permission(organization_id, 'clients', 'update_own')
    AND created_by = auth.uid()
    AND updated_by = auth.uid()
  );

-- DELETE: Can delete ANY if has 'delete_any' OR own if has 'delete_own'
CREATE POLICY "clients_delete_any"
  ON clients FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'delete_any')
  );

CREATE POLICY "clients_delete_own"
  ON clients FOR DELETE TO authenticated
  USING (
    has_org_permission(organization_id, 'clients', 'delete_own')
    AND created_by = auth.uid()
  );
```

#### `organizations` Table

```sql
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- SELECT: Can see organizations you're a member of
CREATE POLICY "organizations_select"
  ON organizations FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
        AND user_id = auth.uid()
    )
  );

-- UPDATE: Only owner can update organization settings
CREATE POLICY "organizations_update"
  ON organizations FOR UPDATE TO authenticated
  USING (
    owner_id = auth.uid()
    OR has_org_permission(id, 'organization', 'manage_settings')
  )
  WITH CHECK (
    owner_id = auth.uid()
    OR has_org_permission(id, 'organization', 'manage_settings')
  );

-- INSERT: Anyone can create an organization (becomes owner)
CREATE POLICY "organizations_insert"
  ON organizations FOR INSERT TO authenticated
  WITH CHECK (
    owner_id = auth.uid()
  );

-- DELETE: Only owner can soft-delete (set deleted_at)
CREATE POLICY "organizations_delete"
  ON organizations FOR UPDATE TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());
```

#### `plants` Table (Global + Org-specific)

```sql
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

-- SELECT: Can see global plants OR org-specific plants
CREATE POLICY "plants_select"
  ON plants FOR SELECT TO authenticated
  USING (
    organization_id IS NULL -- Global plants
    OR has_org_permission(organization_id, 'plants', 'read')
  );

-- INSERT: Can create org-specific plants if has permission
CREATE POLICY "plants_insert"
  ON plants FOR INSERT TO authenticated
  WITH CHECK (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'create')
    AND created_by = auth.uid()
  );

-- UPDATE: Can update org-specific plants if has permission
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

-- DELETE: Can delete org-specific plants if has permission
CREATE POLICY "plants_delete_any"
  ON plants FOR DELETE TO authenticated
  USING (
    organization_id IS NOT NULL
    AND has_org_permission(organization_id, 'plants', 'delete_any')
  );
```

---

## ⚙️ Functions & Triggers

### Auto-Update `updated_at` Timestamp

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Repeat for: plants, materials, quotes, documents, folders, projects
```

---

### Auto-Generate Quote Numbers

```sql
CREATE SEQUENCE quote_number_seq START 1;

CREATE OR REPLACE FUNCTION generate_quote_number(org_id UUID)
RETURNS TEXT AS $$
DECLARE
  year_prefix TEXT;
  next_num INTEGER;
BEGIN
  year_prefix := TO_CHAR(NOW(), 'YYYY');
  
  -- Get next sequence number for this org
  SELECT COALESCE(MAX(
    CAST(SUBSTRING(quote_number FROM '\d+$') AS INTEGER)
  ), 0) + 1
  INTO next_num
  FROM quotes
  WHERE organization_id = org_id
    AND quote_number LIKE year_prefix || '-%';
  
  RETURN year_prefix || '-' || LPAD(next_num::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Auto-generate on INSERT if quote_number not provided
CREATE OR REPLACE FUNCTION auto_generate_quote_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quote_number IS NULL OR NEW.quote_number = '' THEN
    NEW.quote_number := generate_quote_number(NEW.organization_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_quote_number
  BEFORE INSERT ON quotes
  FOR EACH ROW EXECUTE FUNCTION auto_generate_quote_number();
```

---

### Auto-Create Document Versions

```sql
CREATE OR REPLACE FUNCTION create_document_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create version if content changed
  IF NEW.content IS DISTINCT FROM OLD.content THEN
    INSERT INTO document_versions (
      document_id, version_number, title, content, content_type, status,
      changed_fields, created_by
    )
    VALUES (
      NEW.id,
      NEW.version,
      NEW.title,
      NEW.content,
      NEW.content_type,
      NEW.status,
      ARRAY['content'], -- Could detect which fields changed
      NEW.updated_by
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_version_trigger
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION create_document_version();
```

---

### Audit Log on Sensitive Changes

```sql
CREATE OR REPLACE FUNCTION audit_sensitive_changes()
RETURNS TRIGGER AS $$
DECLARE
  changes_json JSONB;
  user_email TEXT;
BEGIN
  -- Capture user email
  SELECT email INTO user_email FROM auth.users WHERE id = auth.uid();
  
  -- Build changes JSON
  IF TG_OP = 'UPDATE' THEN
    changes_json := jsonb_build_object(
      'before', to_jsonb(OLD),
      'after', to_jsonb(NEW)
    );
  ELSIF TG_OP = 'DELETE' THEN
    changes_json := to_jsonb(OLD);
  ELSE
    changes_json := to_jsonb(NEW);
  END IF;
  
  -- Insert audit log
  INSERT INTO audit_logs (
    organization_id,
    user_id,
    user_email,
    action,
    resource_type,
    resource_id,
    changes
  ) VALUES (
    COALESCE(NEW.organization_id, OLD.organization_id),
    auth.uid(),
    user_email,
    LOWER(TG_OP),
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    changes_json
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply to sensitive tables
CREATE TRIGGER audit_organizations
  AFTER INSERT OR UPDATE OR DELETE ON organizations
  FOR EACH ROW EXECUTE FUNCTION audit_sensitive_changes();

CREATE TRIGGER audit_organization_members
  AFTER INSERT OR UPDATE OR DELETE ON organization_members
  FOR EACH ROW EXECUTE FUNCTION audit_sensitive_changes();

-- Add to other critical tables as needed
```

---

## 📋 Migration Strategy

### Phase 1: Core Foundation (Week 1)

1. **Identity & Tenancy**
   - Create `organizations` table
   - Create `role_definitions` + seed system roles
   - Create `role_permissions` + seed permissions
   - Create `organization_members` table
   - Create `organization_invitations` table
   - Create `has_org_permission()` function
   - Create RLS policies for above tables

2. **Verification**
   - Create test organization
   - Add test members with different roles
   - Verify permission checks work correctly

---

### Phase 2: Business Core (Week 2)

3. **Clients & Projects**
   - Create `clients` table + RLS policies
   - Create `projects` table + RLS policies (optional)
   - Seed permissions for clients/projects
   - Test CRUD operations with different roles

4. **Quotes**
   - Create `quotes` table + RLS policies
   - Create `quote_items` table + RLS policies
   - Seed permissions for quotes
   - Create quote number generator function
   - Test quote lifecycle

---

### Phase 3: Product Catalog (Week 3)

5. **Plants & Materials**
   - Create `plants` table + RLS policies
   - Create `materials` table + RLS policies
   - Seed global plants/materials
   - Seed permissions for plants/materials
   - Test global vs org-specific access

---

### Phase 4: Document Management (Week 4)

6. **Documents**
   - Create `folders` table + RLS policies
   - Create `documents` table + RLS policies
   - Create `document_versions` table + trigger
   - Create `document_permissions` table + RLS
   - Seed permissions for documents
   - Test version history

---

### Phase 5: Audit & Monitoring (Week 5)

7. **Audit System**
   - Create `audit_logs` table
   - Create `role_change_audit` table
   - Create audit triggers on key tables
   - Test audit trail completeness

---

### Phase 6: Optimization (Week 6)

8. **Performance Tuning**
   - Review slow query logs
   - Add missing indexes
   - Optimize RLS policies
   - Add database-level caching hints
   - Test under load

---

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] Run all migration scripts in order
- [ ] Verify all indexes created
- [ ] Seed system roles and permissions
- [ ] Seed global plants/materials (optional)
- [ ] Enable RLS on ALL tables
- [ ] Test permission function performance
- [ ] Verify audit triggers on critical tables

### Post-Deployment

- [ ] Create first organization via app
- [ ] Test all CRUD operations per role
- [ ] Verify multi-tenancy isolation (cross-org access denied)
- [ ] Test invitation flow
- [ ] Verify quote number generation
- [ ] Test document versioning
- [ ] Review audit logs for completeness

---

## 🔧 Maintenance & Extensions

### Adding New Permissions

```sql
-- 1. Add permission to role_permissions
INSERT INTO role_permissions (role_id, resource, action)
SELECT id, 'new_resource', 'new_action'
FROM role_definitions
WHERE name IN ('owner', 'admin'); -- Which roles get it

-- 2. Update RLS policies to check new permission
CREATE POLICY "new_resource_action"
  ON new_table FOR SELECT TO authenticated
  USING (has_org_permission(organization_id, 'new_resource', 'new_action'));
```

### Adding New Resource

```sql
-- 1. Create table with standard structure
CREATE TABLE new_resource (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  -- ... other fields ...
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- 2. Add standard indexes
CREATE INDEX idx_new_resource_org ON new_resource(organization_id) WHERE deleted_at IS NULL;

-- 3. Seed permissions for new resource
INSERT INTO role_permissions (role_id, resource, action)
-- ... (see permission seeding above)

-- 4. Create RLS policies
-- ... (see RLS policy examples above)

-- 5. Add updated_at trigger
CREATE TRIGGER update_new_resource_updated_at
  BEFORE UPDATE ON new_resource
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 📊 Performance Optimization

### Query Patterns

**✅ Good: Use has_org_permission() in RLS**
```sql
-- Efficient: Single function call, indexed joins
USING (has_org_permission(organization_id, 'clients', 'read'))
```

**❌ Bad: Inline subqueries**
```sql
-- Inefficient: Subquery per row
USING (
  EXISTS (
    SELECT 1 FROM organization_members om
    JOIN role_permissions rp ...
  )
)
```

**✅ Good: Separate policies for CRUD operations**
```sql
CREATE POLICY "clients_select" ON clients FOR SELECT ...
CREATE POLICY "clients_insert" ON clients FOR INSERT ...
CREATE POLICY "clients_update" ON clients FOR UPDATE ...
```

**❌ Bad: Combined policy with OR**
```sql
-- Hard to optimize
CREATE POLICY "clients_all" ON clients FOR ALL
USING (can_read OR can_update OR ...)
```

---

### Index Strategy

1. **Always index foreign keys**: `organization_id`, `user_id`, `role_id`, etc.
2. **Composite indexes for common joins**: `(organization_id, user_id, role_id)`
3. **Partial indexes with WHERE**: Filter out soft-deleted rows
4. **GIN indexes for arrays**: `tags`, `common_names`, etc.
5. **Full-text search**: GIN indexes on `to_tsvector()`

---

## 🎓 Best Practices Summary

1. **Never DROP tables** - Use `deleted_at` for soft deletes
2. **Never change column types** - Add new column, migrate, drop old
3. **Always use transactions** - Wrap related migrations in BEGIN/COMMIT
4. **Test migrations on staging** - Never run untested SQL on production
5. **Keep migrations small** - One logical change per file
6. **Version everything** - Migration files numbered sequentially
7. **Document breaking changes** - Clear upgrade notes in migration comments
8. **Backup before migrations** - Always have a rollback plan
9. **Monitor after deployment** - Watch slow query logs and error rates
10. **Iterate on permissions** - Start restrictive, loosen as needed

---

## 📚 Additional Resources

- **Supabase RLS Docs**: https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL RBAC Guide**: https://www.postgresql.org/docs/current/sql-grant.html
- **Multi-Tenancy Patterns**: https://docs.microsoft.com/azure/architecture/patterns/
- **Database Normalization**: https://en.wikipedia.org/wiki/Database_normalization
- **Indexing Best Practices**: https://wiki.postgresql.org/wiki/Index_Maintenance

---

## 🎉 You're Ready to Rebuild!

This architecture provides:
- ✅ Clean, extensible foundation
- ✅ Flexible role-based access control
- ✅ Multi-tenancy isolation
- ✅ Comprehensive audit trails
- ✅ Migration-friendly design
- ✅ Performance-optimized queries
- ✅ Production-ready security

**Next Steps**:
1. Review this architecture with your team
2. Start with Phase 1 migrations (Core Foundation)
3. Test thoroughly at each phase
4. Deploy incrementally
5. Monitor and optimize

Happy building! 🌿
