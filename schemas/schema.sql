-- GameForge Development Database Schema
-- PostgreSQL 16+ Compatible
-- Created: September 15, 2025

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
CREATE TYPE user_role AS ENUM ('basic_user', 'premium_user', 'admin', 'super_admin');
CREATE TYPE project_status AS ENUM ('active', 'archived', 'deleted');
CREATE TYPE asset_type AS ENUM ('model', 'dataset', 'texture', 'audio', 'script', 'config', 'other');
CREATE TYPE ai_request_type AS ENUM ('text_generation', 'image_generation', 'model_training', 'data_analysis', 'code_generation');
CREATE TYPE ai_request_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');
CREATE TYPE audit_action AS ENUM ('create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import');

-- Users table - Core user management
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email CITEXT UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    hashed_password TEXT, -- Made nullable for OAuth users
    role user_role DEFAULT 'basic_user',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    name VARCHAR(255), -- Display name for frontend
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    last_login TIMESTAMP WITH TIME ZONE,
    password_reset_token TEXT,
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret TEXT,
    api_quota_limit INTEGER DEFAULT 1000,
    api_quota_used INTEGER DEFAULT 0,
    api_quota_reset_date DATE DEFAULT CURRENT_DATE,
    -- OAuth Integration fields
    github_id VARCHAR(255) UNIQUE,
    github_username VARCHAR(255),
    provider VARCHAR(50) DEFAULT 'local', -- 'github', 'google', 'local'
    provider_id VARCHAR(255),
    -- JWT Token storage
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Preferences table - User settings and themes
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(50) DEFAULT 'system', -- 'light', 'dark', 'system'
    notifications_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(100) DEFAULT 'UTC',
    date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
    time_format VARCHAR(10) DEFAULT '24h', -- '12h' or '24h'
    items_per_page INTEGER DEFAULT 25,
    auto_save BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}', -- Additional flexible settings
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Game Templates table - Pre-built game templates and engines
CREATE TABLE game_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    engine VARCHAR(100) NOT NULL, -- 'unity', 'unreal', 'godot', 'custom'
    engine_version VARCHAR(50),
    category VARCHAR(100), -- 'starter', 'demo', 'complete'
    genre VARCHAR(100), -- 'rpg', 'fps', 'puzzle', 'strategy'
    template_url TEXT,
    repository_url TEXT,
    documentation_url TEXT,
    thumbnail_url TEXT,
    preview_images TEXT[],
    description TEXT,
    detailed_description TEXT,
    features TEXT[],
    requirements TEXT[],
    tags TEXT[],
    difficulty_level VARCHAR(20) DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced'
    estimated_time_hours INTEGER, -- Estimated development time
    file_size_mb INTEGER,
    downloads INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00, -- 0.00 to 5.00
    review_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    price_credits INTEGER DEFAULT 0, -- 0 for free templates
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Projects table - Game development projects
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    status project_status DEFAULT 'active',
    is_public BOOLEAN DEFAULT false,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    repository_url TEXT,
    documentation_url TEXT,
    demo_url TEXT,
    license VARCHAR(100),
    -- Game-specific fields
    template_id UUID REFERENCES game_templates(id),
    engine VARCHAR(100), -- 'unity', 'unreal', 'godot', 'custom', etc.
    engine_version VARCHAR(50),
    target_platforms TEXT[], -- 'windows', 'mac', 'linux', 'ios', 'android', 'web'
    genre VARCHAR(100), -- 'rpg', 'fps', 'puzzle', 'strategy', etc.
    art_style VARCHAR(100), -- '2d', '3d', 'pixel', 'cartoon', 'realistic'
    total_assets INTEGER DEFAULT 0,
    total_size_bytes BIGINT DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Project collaborators table - Team management
CREATE TABLE project_collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'viewer', -- viewer, editor, admin
    permissions JSONB DEFAULT '{}',
    invited_by UUID REFERENCES users(id),
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

-- Assets table - Project files and resources
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type asset_type NOT NULL,
    file_path TEXT NOT NULL,
    original_filename TEXT,
    file_size BIGINT NOT NULL DEFAULT 0,
    mime_type VARCHAR(255),
    checksum_md5 VARCHAR(32),
    checksum_sha256 VARCHAR(64),
    version INTEGER DEFAULT 1,
    is_latest_version BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    tags TEXT[],
    description TEXT,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    download_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI Requests table - Track AI service usage
CREATE TABLE ai_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    request_type ai_request_type NOT NULL,
    status ai_request_status DEFAULT 'pending',
    input_data JSONB NOT NULL DEFAULT '{}',
    output_data JSONB DEFAULT '{}',
    result_link TEXT,
    error_message TEXT,
    processing_time_ms INTEGER,
    cost_credits DECIMAL(10,4) DEFAULT 0,
    priority INTEGER DEFAULT 5, -- 1 (highest) to 10 (lowest)
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ML Models table - Track trained models
CREATE TABLE ml_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    model_type VARCHAR(100) NOT NULL,
    framework VARCHAR(50), -- tensorflow, pytorch, scikit-learn, etc.
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    accuracy DECIMAL(5,4),
    loss DECIMAL(10,6),
    training_data_id UUID REFERENCES assets(id),
    hyperparameters JSONB DEFAULT '{}',
    metrics JSONB DEFAULT '{}',
    is_deployed BOOLEAN DEFAULT false,
    deployment_url TEXT,
    trained_by UUID NOT NULL REFERENCES users(id),
    training_duration_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, name, version)
);

-- Datasets table - Track dataset versions
CREATE TABLE datasets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    row_count INTEGER,
    column_count INTEGER,
    schema_definition JSONB DEFAULT '{}',
    quality_score DECIMAL(3,2), -- 0.00 to 1.00
    data_drift_score DECIMAL(3,2), -- 0.00 to 1.00
    validation_rules JSONB DEFAULT '{}',
    created_by UUID NOT NULL REFERENCES users(id),
    parent_dataset_id UUID REFERENCES datasets(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, name, version)
);

-- Audit Logs table - Security and compliance tracking
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255),
    action audit_action NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    resource_name VARCHAR(255),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(255),
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Sessions table - Track active sessions
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API Keys table - Manage API access
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    key_prefix VARCHAR(10) NOT NULL,
    permissions JSONB DEFAULT '{}',
    rate_limit INTEGER DEFAULT 1000,
    is_active BOOLEAN DEFAULT true,
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- System Configuration table
CREATE TABLE system_config (
    key VARCHAR(255) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_provider ON users(provider);
CREATE INDEX idx_users_github_id ON users(github_id);
CREATE INDEX idx_users_provider_id ON users(provider_id);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

CREATE INDEX idx_game_templates_engine ON game_templates(engine);
CREATE INDEX idx_game_templates_category ON game_templates(category);
CREATE INDEX idx_game_templates_genre ON game_templates(genre);
CREATE INDEX idx_game_templates_slug ON game_templates(slug);
CREATE INDEX idx_game_templates_featured ON game_templates(is_featured);
CREATE INDEX idx_game_templates_active ON game_templates(is_active);
CREATE INDEX idx_game_templates_tags ON game_templates USING GIN(tags);

CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_projects_slug ON projects(slug);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_created_at ON projects(created_at);
CREATE INDEX idx_projects_template_id ON projects(template_id);
CREATE INDEX idx_projects_engine ON projects(engine);
CREATE INDEX idx_projects_genre ON projects(genre);
CREATE INDEX idx_projects_tags ON projects USING GIN(tags);
CREATE INDEX idx_projects_target_platforms ON projects USING GIN(target_platforms);

CREATE INDEX idx_project_collaborators_project_id ON project_collaborators(project_id);
CREATE INDEX idx_project_collaborators_user_id ON project_collaborators(user_id);

CREATE INDEX idx_assets_project_id ON assets(project_id);
CREATE INDEX idx_assets_type ON assets(type);
CREATE INDEX idx_assets_uploaded_by ON assets(uploaded_by);
CREATE INDEX idx_assets_created_at ON assets(created_at);
CREATE INDEX idx_assets_tags ON assets USING GIN(tags);

CREATE INDEX idx_ai_requests_user_id ON ai_requests(user_id);
CREATE INDEX idx_ai_requests_project_id ON ai_requests(project_id);
CREATE INDEX idx_ai_requests_status ON ai_requests(status);
CREATE INDEX idx_ai_requests_type ON ai_requests(request_type);
CREATE INDEX idx_ai_requests_created_at ON ai_requests(created_at);

CREATE INDEX idx_ml_models_project_id ON ml_models(project_id);
CREATE INDEX idx_ml_models_trained_by ON ml_models(trained_by);
CREATE INDEX idx_ml_models_created_at ON ml_models(created_at);

CREATE INDEX idx_datasets_project_id ON datasets(project_id);
CREATE INDEX idx_datasets_created_by ON datasets(created_by);
CREATE INDEX idx_datasets_created_at ON datasets(created_at);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);

-- Create full-text search indexes
CREATE INDEX idx_projects_search ON projects USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));
CREATE INDEX idx_assets_search ON assets USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Create trigger functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_templates_updated_at BEFORE UPDATE ON game_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_requests_updated_at BEFORE UPDATE ON ai_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ml_models_updated_at BEFORE UPDATE ON ml_models
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_datasets_updated_at BEFORE UPDATE ON datasets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default system configuration
INSERT INTO system_config (key, value, description, is_public) VALUES
('max_file_size_mb', '1024', 'Maximum file upload size in MB', true),
('ai_request_timeout_minutes', '30', 'Default timeout for AI requests in minutes', true),
('max_projects_per_user', '10', 'Maximum projects per basic user', true),
('maintenance_mode', 'false', 'System maintenance mode flag', true),
('api_version', '"v1"', 'Current API version', true),
('template_approval_required', 'true', 'Whether game templates require approval', false),
('featured_templates_count', '6', 'Number of featured templates to display', true),
('oauth_github_enabled', 'true', 'Enable GitHub OAuth integration', true),
('oauth_google_enabled', 'false', 'Enable Google OAuth integration', true),
('default_theme', '"system"', 'Default theme for new users', true),
('supported_engines', '["unity", "unreal", "godot", "custom"]', 'List of supported game engines', true);

-- Create a view for user statistics
CREATE VIEW user_stats AS
SELECT 
    u.id,
    u.email,
    u.username,
    u.role,
    u.created_at,
    COUNT(DISTINCT p.id) as project_count,
    COUNT(DISTINCT a.id) as asset_count,
    COUNT(DISTINCT ar.id) as ai_request_count,
    COALESCE(SUM(a.file_size), 0) as total_storage_bytes
FROM users u
LEFT JOIN projects p ON u.id = p.owner_id AND p.status = 'active'
LEFT JOIN assets a ON p.id = a.project_id
LEFT JOIN ai_requests ar ON u.id = ar.user_id
GROUP BY u.id, u.email, u.username, u.role, u.created_at;

-- Create a view for project statistics
CREATE VIEW project_stats AS
SELECT 
    p.id,
    p.name,
    p.owner_id,
    p.status,
    p.created_at,
    COUNT(DISTINCT a.id) as asset_count,
    COUNT(DISTINCT ml.id) as model_count,
    COUNT(DISTINCT d.id) as dataset_count,
    COUNT(DISTINCT pc.id) as collaborator_count,
    COALESCE(SUM(a.file_size), 0) as total_size_bytes,
    MAX(a.created_at) as last_asset_upload
FROM projects p
LEFT JOIN assets a ON p.id = a.project_id
LEFT JOIN ml_models ml ON p.id = ml.project_id
LEFT JOIN datasets d ON p.id = d.project_id
LEFT JOIN project_collaborators pc ON p.id = pc.project_id
GROUP BY p.id, p.name, p.owner_id, p.status, p.created_at;

-- Create stored procedures for common operations
CREATE OR REPLACE FUNCTION create_project_with_owner(
    p_owner_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT false
) RETURNS UUID AS $$
DECLARE
    project_uuid UUID;
    project_slug VARCHAR(255);
BEGIN
    -- Generate slug from name
    project_slug := lower(regexp_replace(p_name, '[^a-zA-Z0-9]+', '-', 'g'));
    project_slug := trim(both '-' from project_slug);
    
    -- Ensure unique slug
    WHILE EXISTS (SELECT 1 FROM projects WHERE slug = project_slug) LOOP
        project_slug := project_slug || '-' || substr(md5(random()::text), 1, 6);
    END LOOP;
    
    -- Create project
    INSERT INTO projects (owner_id, name, slug, description, is_public)
    VALUES (p_owner_id, p_name, project_slug, p_description, p_is_public)
    RETURNING id INTO project_uuid;
    
    -- Add owner as admin collaborator
    INSERT INTO project_collaborators (project_id, user_id, role, accepted_at)
    VALUES (project_uuid, p_owner_id, 'admin', CURRENT_TIMESTAMP);
    
    RETURN project_uuid;
END;
$$ LANGUAGE plpgsql;

-- Permissions and security
-- Create read-only role for reporting
CREATE ROLE gameforge_readonly;
GRANT CONNECT ON DATABASE gameforge_dev TO gameforge_readonly;
GRANT USAGE ON SCHEMA public TO gameforge_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO gameforge_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO gameforge_readonly;

-- Grant appropriate permissions to gameforge_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gameforge_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gameforge_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO gameforge_user;

-- Schema creation complete
SELECT 'GameForge database schema created successfully!' as status;