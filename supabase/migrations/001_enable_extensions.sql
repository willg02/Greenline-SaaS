-- ============================================================================
-- Migration: 001 - Enable Required Extensions
-- Description: Enable PostgreSQL extensions needed for the application
-- Dependencies: None
-- ============================================================================

-- Enable UUID generation (preferred over uuid-ossp in newer PostgreSQL)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable full-text search (already included but explicit for clarity)
-- CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Uncomment if using fuzzy text search

COMMENT ON EXTENSION pgcrypto IS 'Cryptographic functions including gen_random_uuid()';
