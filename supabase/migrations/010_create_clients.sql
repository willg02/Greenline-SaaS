-- ============================================================================
-- Migration: 010 - Create Clients Table
-- Description: Customer records for organizations
-- Dependencies: 009_create_rls_policies_core.sql
-- ============================================================================

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
  tags TEXT[],
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

-- Indexes
CREATE INDEX idx_clients_org_id ON clients(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_status ON clients(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_created_by ON clients(created_by);
CREATE INDEX idx_clients_name_search ON clients USING gin(to_tsvector('english', name));
CREATE INDEX idx_clients_tags ON clients USING gin(tags);

-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE clients IS 'Customer records with contact information and project history';
COMMENT ON COLUMN clients.tags IS 'Flexible categorization (e.g., residential, commercial, vip)';
COMMENT ON COLUMN clients.custom_fields IS 'Org-specific custom data in JSONB format';
