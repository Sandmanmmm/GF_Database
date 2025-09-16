-- Migration: 003_gameforge_integration_fixes
-- Description: Add missing structures for GameForge frontend/backend integration
-- Created: 2025-09-16
-- Author: GameForge Integration Team

-- This migration adds missing roles, permissions, and data classification
-- fields needed for proper GameForge application integration

BEGIN;

-- ==============================================
-- 1. Fix Authentication System
-- ==============================================

-- Add missing 'ai_user' role to user_role enum
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'ai_user';

-- Create user permissions table for granular access control
CREATE TABLE IF NOT EXISTS user_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50), -- 'asset', 'project', 'model', 'global'
    resource_id UUID, -- NULL for global permissions
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_permission UNIQUE(user_id, permission, resource_type, resource_id)
);

-- Create indexes for performance
CREATE INDEX idx_user_permissions_user_id ON user_permissions(user_id);
CREATE INDEX idx_user_permissions_permission ON user_permissions(permission);
CREATE INDEX idx_user_permissions_resource ON user_permissions(resource_type, resource_id);
CREATE INDEX idx_user_permissions_expires ON user_permissions(expires_at);

-- ==============================================
-- 2. Add Data Classification Support
-- ==============================================

-- Create data classification enum based on GameForge requirements
CREATE TYPE data_classification AS ENUM (
    'USER_IDENTITY',
    'USER_AUTH', 
    'PAYMENT_DATA',
    'BILLING_INFO',
    'PROJECT_METADATA',
    'ASSET_METADATA',
    'ASSET_BINARIES',
    'USER_UPLOADS',
    'MODEL_ARTIFACTS',
    'TRAINING_DATASETS',
    'MODEL_METADATA',
    'APPLICATION_LOGS',
    'ACCESS_LOGS',
    'AUDIT_LOGS',
    'SYSTEM_METRICS',
    'API_KEYS',
    'ENCRYPTION_KEYS',
    'TLS_CERTIFICATES',
    'VAULT_TOKENS',
    'USAGE_ANALYTICS',
    'BUSINESS_METRICS',
    'PERFORMANCE_METRICS'
);

-- Add data classification columns to relevant tables
ALTER TABLE users ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'USER_IDENTITY';
ALTER TABLE assets ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'ASSET_BINARIES';
ALTER TABLE ml_models ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'MODEL_ARTIFACTS';
ALTER TABLE datasets ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'TRAINING_DATASETS';
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'AUDIT_LOGS';
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'API_KEYS';
ALTER TABLE user_sessions ADD COLUMN IF NOT EXISTS data_classification data_classification DEFAULT 'USER_AUTH';

-- Add retention policy tracking
ALTER TABLE users ADD COLUMN IF NOT EXISTS retention_period_days INTEGER DEFAULT 2555; -- 7 years
ALTER TABLE assets ADD COLUMN IF NOT EXISTS retention_period_days INTEGER DEFAULT 1825; -- 5 years
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS retention_period_days INTEGER DEFAULT 2555; -- 7 years
ALTER TABLE user_sessions ADD COLUMN IF NOT EXISTS retention_period_days INTEGER DEFAULT 90; -- 3 months

-- Add encryption requirement indicators
ALTER TABLE users ADD COLUMN IF NOT EXISTS encryption_required BOOLEAN DEFAULT true;
ALTER TABLE assets ADD COLUMN IF NOT EXISTS encryption_required BOOLEAN DEFAULT true;
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS encryption_required BOOLEAN DEFAULT true;

-- ==============================================
-- 3. Storage Access Control Integration
-- ==============================================

-- Storage configuration table for multi-cloud support
CREATE TABLE IF NOT EXISTS storage_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    provider VARCHAR(50) NOT NULL, -- 'aws_s3', 'azure_blob', 'gcp_storage', 'local'
    bucket_name VARCHAR(255) NOT NULL,
    region VARCHAR(100),
    endpoint_url TEXT,
    access_key_id VARCHAR(255),
    secret_access_key_hash VARCHAR(255), -- Hashed for security
    configuration JSONB DEFAULT '{}', -- Provider-specific config
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    max_file_size_mb INTEGER DEFAULT 100,
    allowed_file_types TEXT[] DEFAULT ARRAY['*'],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_storage_name UNIQUE(name)
);

-- Access tokens table for short-lived credentials
CREATE TABLE IF NOT EXISTS access_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    token_prefix VARCHAR(10) NOT NULL, -- For identification without full token
    resource_type VARCHAR(50) NOT NULL, -- 'asset', 'model', 'dataset', 'bucket', 'storage'
    resource_id VARCHAR(255) NOT NULL,
    allowed_actions TEXT[] NOT NULL, -- ['read', 'write', 'delete', 'upload', 'download']
    conditions JSONB DEFAULT '{}', -- Additional conditions (IP restrictions, etc.)
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used TIMESTAMP WITH TIME ZONE,
    use_count INTEGER DEFAULT 0,
    max_uses INTEGER, -- NULL for unlimited
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Presigned URLs table for tracking direct access
CREATE TABLE IF NOT EXISTS presigned_urls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resource_id VARCHAR(255) NOT NULL,
    url_hash VARCHAR(255) NOT NULL, -- Hashed URL for security
    method VARCHAR(10) NOT NULL, -- GET, PUT, POST, DELETE
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    access_count INTEGER DEFAULT 0,
    max_accesses INTEGER DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for access control tables
CREATE INDEX idx_storage_configs_provider ON storage_configs(provider);
CREATE INDEX idx_storage_configs_active ON storage_configs(is_active);
CREATE INDEX idx_access_tokens_user_id ON access_tokens(user_id);
CREATE INDEX idx_access_tokens_hash ON access_tokens(token_hash);
CREATE INDEX idx_access_tokens_expires ON access_tokens(expires_at);
CREATE INDEX idx_access_tokens_resource ON access_tokens(resource_type, resource_id);
CREATE INDEX idx_presigned_urls_user_id ON presigned_urls(user_id);
CREATE INDEX idx_presigned_urls_expires ON presigned_urls(expires_at);

-- ==============================================
-- 4. Enhanced Audit and Compliance
-- ==============================================

-- Add compliance tracking fields to audit_logs
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS compliance_event BOOLEAN DEFAULT false;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS gdpr_relevant BOOLEAN DEFAULT false;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS retention_required BOOLEAN DEFAULT true;

-- Create compliance events table for detailed tracking
CREATE TABLE IF NOT EXISTS compliance_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL, -- 'data_access', 'data_export', 'data_deletion', 'consent_given'
    data_classification data_classification NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    legal_basis VARCHAR(100), -- 'consent', 'contract', 'legal_obligation', etc.
    purpose TEXT, -- Purpose of data processing
    retention_period INTEGER, -- Days
    automated_decision BOOLEAN DEFAULT false,
    cross_border_transfer BOOLEAN DEFAULT false,
    details JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_compliance_events_user_id ON compliance_events(user_id);
CREATE INDEX idx_compliance_events_type ON compliance_events(event_type);
CREATE INDEX idx_compliance_events_classification ON compliance_events(data_classification);
CREATE INDEX idx_compliance_events_timestamp ON compliance_events(timestamp);

-- ==============================================
-- 5. Default Storage Configuration
-- ==============================================

-- Insert default local storage configuration
INSERT INTO storage_configs (
    name, 
    provider, 
    bucket_name, 
    region, 
    endpoint_url, 
    is_default, 
    is_active,
    max_file_size_mb,
    allowed_file_types
) VALUES (
    'local_storage',
    'local',
    'gameforge_assets',
    'local',
    '/app/storage',
    true,
    true,
    500, -- 500MB max file size
    ARRAY['image/*', 'model/*', 'text/*', 'application/*']
) ON CONFLICT (name) DO NOTHING;

-- ==============================================
-- 6. Default Permissions for Role Types
-- ==============================================

-- Create function to assign default permissions based on user role
CREATE OR REPLACE FUNCTION assign_default_permissions(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
    user_role_value user_role;
BEGIN
    -- Get user role
    SELECT role INTO user_role_value FROM users WHERE id = user_uuid;
    
    -- Clear existing permissions (in case of role change)
    DELETE FROM user_permissions WHERE user_id = user_uuid AND resource_id IS NULL;
    
    -- Assign permissions based on role
    CASE user_role_value
        WHEN 'basic_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global');
            
        WHEN 'premium_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'assets:create', 'global'),
            (user_uuid, 'assets:update', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global'),
            (user_uuid, 'projects:update', 'global'),
            (user_uuid, 'models:read', 'global'),
            (user_uuid, 'models:create', 'global');
            
        WHEN 'ai_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'assets:create', 'global'),
            (user_uuid, 'assets:update', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global'),
            (user_uuid, 'projects:update', 'global'),
            (user_uuid, 'models:read', 'global'),
            (user_uuid, 'models:create', 'global'),
            (user_uuid, 'models:train', 'global'),
            (user_uuid, 'ai:generate', 'global');
            
        WHEN 'admin' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:*', 'global'),
            (user_uuid, 'projects:*', 'global'),
            (user_uuid, 'models:*', 'global'),
            (user_uuid, 'users:*', 'global'),
            (user_uuid, 'system:*', 'global');
            
        WHEN 'super_admin' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, '*:*', 'global');
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- 7. Update Existing Users with Default Permissions
-- ==============================================

-- Assign default permissions to all existing users
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM users LOOP
        PERFORM assign_default_permissions(user_record.id);
    END LOOP;
END $$;

-- ==============================================
-- 8. Create Triggers for Automatic Permission Assignment
-- ==============================================

-- Trigger function to assign permissions on user creation or role change
CREATE OR REPLACE FUNCTION trigger_assign_permissions()
RETURNS TRIGGER AS $$
BEGIN
    -- Only assign permissions if role changed or new user
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.role != NEW.role) THEN
        PERFORM assign_default_permissions(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for users table
DROP TRIGGER IF EXISTS assign_permissions_trigger ON users;
CREATE TRIGGER assign_permissions_trigger
    AFTER INSERT OR UPDATE OF role ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_assign_permissions();

-- ==============================================
-- 9. Update Schema Migration Record
-- ==============================================

-- Record this migration
INSERT INTO schema_migrations (version, description, applied_at)
VALUES ('003', 'GameForge Integration Fixes - Auth, Permissions, Data Classification', CURRENT_TIMESTAMP)
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- Migration complete message
SELECT 'GameForge integration migration 003 completed successfully!' as status;