-- ============================================================================
-- Migration: 018 - Create Triggers and Functions
-- Description: Automated triggers for timestamps, versioning, and auditing
-- Dependencies: 017_create_audit_tables.sql
-- ============================================================================

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================

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

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at
  BEFORE UPDATE ON quotes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plants_updated_at
  BEFORE UPDATE ON plants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_materials_updated_at
  BEFORE UPDATE ON materials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_folders_updated_at
  BEFORE UPDATE ON folders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- QUOTE NUMBER GENERATION
-- ============================================

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

-- ============================================
-- DOCUMENT VERSIONING
-- ============================================

CREATE OR REPLACE FUNCTION create_document_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create version if content or title changed
  IF NEW.content IS DISTINCT FROM OLD.content OR NEW.title IS DISTINCT FROM OLD.title THEN
    -- Increment version number
    NEW.version := OLD.version + 1;
    
    -- Create version record
    INSERT INTO document_versions (
      document_id,
      version_number,
      title,
      content,
      content_type,
      status,
      changed_fields,
      created_by
    )
    VALUES (
      NEW.id,
      NEW.version,
      NEW.title,
      NEW.content,
      NEW.content_type,
      NEW.status,
      ARRAY['content', 'title'],
      NEW.updated_by
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_version_trigger
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION create_document_version();

-- ============================================
-- AUDIT LOGGING FOR SENSITIVE CHANGES
-- ============================================

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

-- Apply to critical tables
CREATE TRIGGER audit_organizations
  AFTER INSERT OR UPDATE OR DELETE ON organizations
  FOR EACH ROW EXECUTE FUNCTION audit_sensitive_changes();

CREATE TRIGGER audit_organization_members
  AFTER INSERT OR UPDATE OR DELETE ON organization_members
  FOR EACH ROW EXECUTE FUNCTION audit_sensitive_changes();

-- ============================================
-- ROLE CHANGE AUDITING
-- ============================================

CREATE OR REPLACE FUNCTION audit_role_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.role_id IS DISTINCT FROM NEW.role_id THEN
    INSERT INTO role_change_audit (
      organization_id,
      member_id,
      user_id,
      old_role_id,
      new_role_id,
      changed_by
    ) VALUES (
      NEW.organization_id,
      NEW.id,
      NEW.user_id,
      OLD.role_id,
      NEW.role_id,
      auth.uid()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER role_change_audit_trigger
  AFTER UPDATE ON organization_members
  FOR EACH ROW EXECUTE FUNCTION audit_role_changes();

-- Comments
COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates updated_at timestamp on row changes';
COMMENT ON FUNCTION generate_quote_number IS 'Generates sequential quote numbers per organization (YYYY-0001)';
COMMENT ON FUNCTION create_document_version IS 'Creates version snapshot when document content changes';
COMMENT ON FUNCTION audit_sensitive_changes IS 'Logs changes to critical tables in audit_logs';
COMMENT ON FUNCTION audit_role_changes IS 'Tracks role changes in role_change_audit table';
