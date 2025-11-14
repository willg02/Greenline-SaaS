-- ============================================================================
-- Migration: 013 - Create Plants & Materials Tables
-- Description: Product catalog for plants and landscaping materials
-- Dependencies: 012_create_quotes.sql
-- ============================================================================

-- Plants table
CREATE TABLE plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  scientific_name TEXT,
  common_names TEXT[],
  
  -- Classification
  type TEXT NOT NULL CHECK (type IN ('tree', 'shrub', 'perennial', 'grass', 'groundcover', 'vine', 'annual', 'bulb')),
  category TEXT,
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
  bloom_time TEXT,
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

-- Indexes
CREATE INDEX idx_plants_global ON plants(id) WHERE organization_id IS NULL AND deleted_at IS NULL;
CREATE INDEX idx_plants_org ON plants(organization_id) WHERE organization_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_plants_type ON plants(organization_id, type) WHERE deleted_at IS NULL;
CREATE INDEX idx_plants_native ON plants(is_native) WHERE is_native = true AND deleted_at IS NULL;
CREATE INDEX idx_plants_hardiness ON plants(hardiness_zone_min, hardiness_zone_max) WHERE deleted_at IS NULL;
CREATE INDEX idx_plants_name_search ON plants USING gin(to_tsvector('english', name || ' ' || COALESCE(scientific_name, '')));
CREATE INDEX idx_plants_tags ON plants USING gin(tags);

-- Enable RLS
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

-- Materials table
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Identity
  name TEXT NOT NULL,
  description TEXT,
  
  -- Classification
  type TEXT NOT NULL CHECK (type IN ('soil', 'mulch', 'compost', 'gravel', 'stone', 'sand', 'edging', 'fabric', 'other')),
  category TEXT,
  
  -- Measurement
  unit TEXT NOT NULL DEFAULT 'cubic_yard',
  coverage_per_unit DECIMAL(10,2),
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

-- Indexes
CREATE INDEX idx_materials_global ON materials(id) WHERE organization_id IS NULL AND deleted_at IS NULL;
CREATE INDEX idx_materials_org ON materials(organization_id) WHERE organization_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_materials_type ON materials(organization_id, type) WHERE deleted_at IS NULL;
CREATE INDEX idx_materials_name_search ON materials USING gin(to_tsvector('english', name));

-- Enable RLS
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;

-- Add foreign key constraints to quote_items now that plants/materials exist
ALTER TABLE quote_items
  ADD CONSTRAINT fk_quote_items_plant 
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE SET NULL;

ALTER TABLE quote_items
  ADD CONSTRAINT fk_quote_items_material 
  FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE SET NULL;

CREATE INDEX idx_quote_items_plant_id ON quote_items(plant_id) WHERE plant_id IS NOT NULL;
CREATE INDEX idx_quote_items_material_id ON quote_items(material_id) WHERE material_id IS NOT NULL;

-- Comments
COMMENT ON TABLE plants IS 'Plant database - global (org_id NULL) and org-specific custom plants';
COMMENT ON TABLE materials IS 'Landscaping materials - global and org-specific';
COMMENT ON COLUMN plants.organization_id IS 'NULL = global plant, UUID = org-specific custom plant';
