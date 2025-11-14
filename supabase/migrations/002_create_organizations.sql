-- ============================================================================
-- Migration: 002 - Create Organizations Table
-- Description: Root tenant entity for multi-tenant architecture
-- Dependencies: 001_enable_extensions.sql
-- ============================================================================

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
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
  
  -- External integrations
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  
  -- Metadata
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_organizations_owner_id ON organizations(owner_id);
CREATE INDEX idx_organizations_slug ON organizations(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_active ON organizations(subscription_status) 
  WHERE deleted_at IS NULL AND subscription_status = 'active';

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE organizations IS 'Multi-tenant organizations - root entity for business accounts';
COMMENT ON COLUMN organizations.slug IS 'URL-friendly identifier for organization';
COMMENT ON COLUMN organizations.settings IS 'Flexible JSONB for org-specific configuration';
COMMENT ON COLUMN organizations.deleted_at IS 'Soft delete timestamp';
