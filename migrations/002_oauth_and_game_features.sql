-- Migration: 002_oauth_and_game_features
-- Description: Add OAuth integration, user preferences, and game-specific features
-- Created: 2025-09-15
-- Author: GameForge Team

-- This migration adds OAuth support, user preferences, game templates, and enhanced project features

BEGIN;

-- Add OAuth and JWT fields to users table
ALTER TABLE users 
    ALTER COLUMN hashed_password DROP NOT NULL,
    ADD COLUMN name VARCHAR(255),
    ADD COLUMN github_id VARCHAR(255) UNIQUE,
    ADD COLUMN github_username VARCHAR(255),
    ADD COLUMN provider VARCHAR(50) DEFAULT 'local',
    ADD COLUMN provider_id VARCHAR(255),
    ADD COLUMN access_token TEXT,
    ADD COLUMN refresh_token TEXT,
    ADD COLUMN token_expires_at TIMESTAMP WITH TIME ZONE;

-- Create indexes for new user fields
CREATE INDEX idx_users_provider ON users(provider);
CREATE INDEX idx_users_github_id ON users(github_id);
CREATE INDEX idx_users_provider_id ON users(provider_id);

-- Create user_preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(50) DEFAULT 'system',
    notifications_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(100) DEFAULT 'UTC',
    date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
    time_format VARCHAR(10) DEFAULT '24h',
    items_per_page INTEGER DEFAULT 25,
    auto_save BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Create user preferences index and trigger
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create game_templates table
CREATE TABLE game_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    engine VARCHAR(100) NOT NULL,
    engine_version VARCHAR(50),
    category VARCHAR(100),
    genre VARCHAR(100),
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
    difficulty_level VARCHAR(20) DEFAULT 'beginner',
    estimated_time_hours INTEGER,
    file_size_mb INTEGER,
    downloads INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    price_credits INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create game templates indexes and trigger
CREATE INDEX idx_game_templates_engine ON game_templates(engine);
CREATE INDEX idx_game_templates_category ON game_templates(category);
CREATE INDEX idx_game_templates_genre ON game_templates(genre);
CREATE INDEX idx_game_templates_slug ON game_templates(slug);
CREATE INDEX idx_game_templates_featured ON game_templates(is_featured);
CREATE INDEX idx_game_templates_active ON game_templates(is_active);
CREATE INDEX idx_game_templates_tags ON game_templates USING GIN(tags);

CREATE TRIGGER update_game_templates_updated_at BEFORE UPDATE ON game_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add game-specific fields to projects table
ALTER TABLE projects 
    ADD COLUMN template_id UUID REFERENCES game_templates(id),
    ADD COLUMN engine VARCHAR(100),
    ADD COLUMN engine_version VARCHAR(50),
    ADD COLUMN target_platforms TEXT[],
    ADD COLUMN genre VARCHAR(100),
    ADD COLUMN art_style VARCHAR(100);

-- Create new project indexes
CREATE INDEX idx_projects_template_id ON projects(template_id);
CREATE INDEX idx_projects_engine ON projects(engine);
CREATE INDEX idx_projects_genre ON projects(genre);
CREATE INDEX idx_projects_target_platforms ON projects USING GIN(target_platforms);

-- Insert sample game templates
INSERT INTO game_templates (id, name, slug, engine, engine_version, category, genre, description, detailed_description, features, requirements, tags, difficulty_level, estimated_time_hours, file_size_mb, is_featured, is_active, created_by) VALUES
    ('11111111-1111-1111-1111-111111111111', '2D Platformer Starter', '2d-platformer-starter', 'unity', '2022.3', 'starter', 'platformer', 'Basic 2D platformer template with character controller and physics', 'Complete 2D platformer template featuring player movement, jumping mechanics, collectibles, and basic enemy AI. Perfect for beginners starting their first platformer game.', ARRAY['Player Controller', 'Physics2D', 'Collectibles System', 'Basic AI', 'Level Manager'], ARRAY['Unity 2022.3+', 'Basic C# Knowledge'], ARRAY['2d', 'platformer', 'starter', 'beginner'], 'beginner', 20, 150, true, true, NULL),
    ('22222222-2222-2222-2222-222222222222', 'RPG Character System', 'rpg-character-system', 'unity', '2022.3', 'demo', 'rpg', 'Advanced RPG character system with inventory and stats', 'Comprehensive RPG system including character stats, inventory management, equipment system, skill trees, and save/load functionality. Ideal for intermediate developers.', ARRAY['Character Stats', 'Inventory System', 'Equipment Manager', 'Skill Trees', 'Save System'], ARRAY['Unity 2022.3+', 'Intermediate C#', 'Understanding of ScriptableObjects'], ARRAY['rpg', 'character', 'inventory', 'stats'], 'intermediate', 40, 300, true, true, NULL),
    ('33333333-3333-3333-3333-333333333333', 'Godot FPS Template', 'godot-fps-template', 'godot', '4.1', 'complete', 'fps', 'Complete FPS game template for Godot', 'Full-featured FPS template with weapon systems, enemy AI, level design tools, and multiplayer support. Ready for advanced developers to build upon.', ARRAY['Weapon System', 'Enemy AI', 'Multiplayer Ready', 'Level Tools', 'Audio Manager'], ARRAY['Godot 4.1+', 'GDScript Experience', 'Basic 3D Modeling'], ARRAY['fps', 'godot', 'multiplayer', 'complete'], 'advanced', 60, 500, false, true, NULL);

-- Create default user preferences for existing users
INSERT INTO user_preferences (user_id, theme, notifications_enabled, email_notifications, language)
SELECT id, 'system', true, true, 'en' FROM users
ON CONFLICT (user_id) DO NOTHING;

-- Add new system configuration
INSERT INTO system_config (key, value, description, is_public) VALUES
    ('template_approval_required', 'true', 'Whether game templates require approval', false),
    ('featured_templates_count', '6', 'Number of featured templates to display', true),
    ('oauth_github_enabled', 'true', 'Enable GitHub OAuth integration', true),
    ('oauth_google_enabled', 'false', 'Enable Google OAuth integration', true),
    ('default_theme', '"system"', 'Default theme for new users', true),
    ('supported_engines', '["unity", "unreal", "godot", "custom"]', 'List of supported game engines', true)
ON CONFLICT (key) DO NOTHING;

-- Record this migration
INSERT INTO migrations (migration_name, checksum) 
VALUES ('002_oauth_and_game_features', md5('002_oauth_and_game_features_v1'));

COMMIT;