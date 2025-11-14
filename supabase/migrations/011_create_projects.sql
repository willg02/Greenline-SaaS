-- ============================================================================
-- Migration: 011 - Create Projects Table
-- Description: Project management and tracking
-- Dependencies: 010_create_clients.sql
-- ============================================================================

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

-- Indexes
CREATE INDEX idx_projects_org_id ON projects(organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_client_id ON projects(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_status ON projects(organization_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_dates ON projects(start_date, target_completion_date) WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE projects IS 'Project tracking with timeline and financial data';
COMMENT ON COLUMN projects.status IS 'Project lifecycle from planning to completion';
