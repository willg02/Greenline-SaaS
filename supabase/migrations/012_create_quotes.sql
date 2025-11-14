-- ============================================================================
-- Migration: 012 - Create Quotes & Quote Items Tables
-- Description: Quote generation with line items
-- Dependencies: 011_create_projects.sql
-- ============================================================================

-- Create sequence for quote numbers
CREATE SEQUENCE IF NOT EXISTS quote_number_seq START 1;

-- Quotes table
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  
  -- Quote identification
  quote_number TEXT NOT NULL,
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

-- Indexes
CREATE INDEX idx_quotes_org_id ON quotes(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_client_id ON quotes(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_project_id ON quotes(project_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_status ON quotes(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_quotes_number ON quotes(organization_id, quote_number);
CREATE INDEX idx_quotes_date_range ON quotes(created_at, valid_until) WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- Quote Items table
CREATE TABLE quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  
  -- Item reference (will link to plants/materials later)
  plant_id UUID, -- Will reference plants table in next migration
  material_id UUID, -- Will reference materials table in next migration
  
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
  category TEXT,
  notes TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_quote_items_quote_id ON quote_items(quote_id);
CREATE INDEX idx_quote_items_sort ON quote_items(quote_id, sort_order);

-- Enable RLS
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE quotes IS 'Customer quotes with pricing breakdown and lifecycle tracking';
COMMENT ON TABLE quote_items IS 'Line items within quotes';
COMMENT ON COLUMN quotes.quote_number IS 'Auto-generated: YYYY-0001 format';
COMMENT ON COLUMN quote_items.category IS 'Grouping for PDF export (e.g., Site Prep, Planting)';
