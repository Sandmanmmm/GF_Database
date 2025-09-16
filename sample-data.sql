-- GameForge Sample Data
-- Development environment sample data for testing and development
-- This file creates sample users, projects, and assets for development

BEGIN;

-- Sample users (updated with OAuth and display name fields)
INSERT INTO users (id, email, username, hashed_password, role, first_name, last_name, name, is_active, email_verified, provider) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'admin@gameforge.dev', 'admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXlFgf6XaKZO', 'admin', 'Admin', 'User', 'Administrator', true, true, 'local'),
    ('550e8400-e29b-41d4-a716-446655440002', 'developer@gameforge.dev', 'developer', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXlFgf6XaKZO', 'premium_user', 'John', 'Developer', 'John Developer', true, true, 'local'),
    ('550e8400-e29b-41d4-a716-446655440003', 'user@gameforge.dev', 'basicuser', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXlFgf6XaKZO', 'basic_user', 'Jane', 'User', 'Jane User', true, true, 'local'),
    ('550e8400-e29b-41d4-a716-446655440004', 'github.user@gameforge.dev', 'githubuser', NULL, 'basic_user', 'GitHub', 'User', 'GitHub User', true, true, 'github'),
    ('550e8400-e29b-41d4-a716-446655440005', 'template.creator@gameforge.dev', 'templatecreator', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXlFgf6XaKZO', 'premium_user', 'Template', 'Creator', 'Template Creator', true, true, 'local');

-- Update GitHub user with OAuth data
UPDATE users SET 
    github_id = '12345678',
    github_username = 'githubuser',
    provider_id = '12345678'
WHERE id = '550e8400-e29b-41d4-a716-446655440004';

-- Sample user preferences
INSERT INTO user_preferences (user_id, theme, notifications_enabled, email_notifications, language, timezone) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'dark', true, true, 'en', 'UTC'),
    ('550e8400-e29b-41d4-a716-446655440002', 'light', true, false, 'en', 'America/New_York'),
    ('550e8400-e29b-41d4-a716-446655440003', 'system', false, true, 'en', 'UTC'),
    ('550e8400-e29b-41d4-a716-446655440004', 'dark', true, true, 'en', 'Europe/London'),
    ('550e8400-e29b-41d4-a716-446655440005', 'light', true, true, 'en', 'UTC');

-- Sample game templates
INSERT INTO game_templates (id, name, slug, engine, engine_version, category, genre, template_url, thumbnail_url, description, detailed_description, features, requirements, tags, difficulty_level, estimated_time_hours, file_size_mb, downloads, rating, review_count, is_featured, is_active, price_credits, created_by, approved_at, approved_by) VALUES
    ('tt111111-1111-1111-1111-111111111111', '2D Platformer Starter', '2d-platformer-starter', 'unity', '2022.3', 'starter', 'platformer', 'https://templates.gameforge.dev/2d-platformer.zip', 'https://images.gameforge.dev/templates/2d-platformer-thumb.jpg', 'Basic 2D platformer template with character controller and physics', 'Complete 2D platformer template featuring player movement, jumping mechanics, collectibles, and basic enemy AI. Perfect for beginners starting their first platformer game. Includes pre-built character animations, tilemap system, and example levels.', ARRAY['Player Controller', 'Physics2D', 'Collectibles System', 'Basic Enemy AI', 'Level Manager', 'Sound Effects', 'Particle Effects'], ARRAY['Unity 2022.3+', 'Basic C# Knowledge', '2GB RAM', '500MB Storage'], ARRAY['2d', 'platformer', 'starter', 'beginner', 'unity'], 'beginner', 20, 150, 1250, 4.5, 87, true, true, 0, '550e8400-e29b-41d4-a716-446655440005', CURRENT_TIMESTAMP, '550e8400-e29b-41d4-a716-446655440001'),
    ('tt222222-2222-2222-2222-222222222222', 'RPG Character System', 'rpg-character-system', 'unity', '2022.3', 'demo', 'rpg', 'https://templates.gameforge.dev/rpg-character.zip', 'https://images.gameforge.dev/templates/rpg-character-thumb.jpg', 'Advanced RPG character system with inventory and stats', 'Comprehensive RPG system including character stats, inventory management, equipment system, skill trees, and save/load functionality. Features modular design for easy customization and extension. Includes sample items, weapons, and character progression system.', ARRAY['Character Stats', 'Inventory System', 'Equipment Manager', 'Skill Trees', 'Save/Load System', 'Item Database', 'Quest System'], ARRAY['Unity 2022.3+', 'Intermediate C#', 'Understanding of ScriptableObjects', '4GB RAM', '1GB Storage'], ARRAY['rpg', 'character', 'inventory', 'stats', 'intermediate'], 'intermediate', 40, 300, 856, 4.7, 64, true, true, 50, '550e8400-e29b-41d4-a716-446655440005', CURRENT_TIMESTAMP, '550e8400-e29b-41d4-a716-446655440001'),
    ('tt333333-3333-3333-3333-333333333333', 'Godot FPS Template', 'godot-fps-template', 'godot', '4.1', 'complete', 'fps', 'https://templates.gameforge.dev/godot-fps.zip', 'https://images.gameforge.dev/templates/godot-fps-thumb.jpg', 'Complete FPS game template for Godot', 'Full-featured FPS template with weapon systems, enemy AI, level design tools, and multiplayer support. Includes advanced graphics settings, audio management, and performance optimization. Ready for advanced developers to build upon with extensive documentation.', ARRAY['Weapon System', 'Enemy AI', 'Multiplayer Ready', 'Level Design Tools', 'Audio Manager', 'Graphics Settings', 'Performance Optimization'], ARRAY['Godot 4.1+', 'GDScript Experience', 'Basic 3D Modeling Knowledge', '8GB RAM', '2GB Storage'], ARRAY['fps', 'godot', 'multiplayer', 'complete', 'advanced'], 'advanced', 60, 500, 423, 4.3, 31, false, true, 100, '550e8400-e29b-41d4-a716-446655440005', CURRENT_TIMESTAMP, '550e8400-e29b-41d4-a716-446655440001'),
    ('tt444444-4444-4444-4444-444444444444', 'Puzzle Game Kit', 'puzzle-game-kit', 'unity', '2023.1', 'starter', 'puzzle', 'https://templates.gameforge.dev/puzzle-kit.zip', 'https://images.gameforge.dev/templates/puzzle-kit-thumb.jpg', 'Versatile puzzle game template with multiple mechanics', 'Flexible puzzle game framework supporting various puzzle types including match-3, block puzzles, and logic games. Features level editor, progression system, and social features integration.', ARRAY['Level Editor', 'Multiple Puzzle Types', 'Progression System', 'Social Integration', 'Analytics Ready'], ARRAY['Unity 2023.1+', 'Basic C#', '2GB RAM'], ARRAY['puzzle', 'casual', 'mobile', 'starter'], 'beginner', 25, 200, 967, 4.6, 52, true, true, 25, '550e8400-e29b-41d4-a716-446655440005', CURRENT_TIMESTAMP, '550e8400-e29b-41d4-a716-446655440001'),
    ('tt555555-5555-5555-5555-555555555555', 'Unreal Racing Game', 'unreal-racing-game', 'unreal', '5.3', 'complete', 'racing', 'https://templates.gameforge.dev/unreal-racing.zip', 'https://images.gameforge.dev/templates/unreal-racing-thumb.jpg', 'High-performance racing game template for Unreal Engine', 'Professional racing game template with realistic physics, multiple vehicle types, track editor, and competitive multiplayer. Optimized for both PC and console deployment.', ARRAY['Realistic Physics', 'Vehicle Variety', 'Track Editor', 'Multiplayer Racing', 'Performance Optimized'], ARRAY['Unreal Engine 5.3+', 'Blueprint Knowledge', 'C++ Basics', '16GB RAM', '5GB Storage'], ARRAY['racing', 'unreal', 'multiplayer', 'realistic', 'complete'], 'advanced', 80, 800, 234, 4.8, 19, true, true, 200, '550e8400-e29b-41d4-a716-446655440005', CURRENT_TIMESTAMP, '550e8400-e29b-41d4-a716-446655440001');

-- Sample projects (updated with game-specific fields)
INSERT INTO projects (id, owner_id, name, slug, description, status, is_public, tags, template_id, engine, engine_version, target_platforms, genre, art_style) VALUES
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Fantasy RPG AI', 'fantasy-rpg-ai', 'AI-powered NPCs and procedural content generation for fantasy RPG', 'active', true, ARRAY['rpg', 'ai', 'fantasy', 'npc'], 'tt222222-2222-2222-2222-222222222222', 'unity', '2022.3', ARRAY['windows', 'mac', 'linux'], 'rpg', '3d'),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Space Shooter ML', 'space-shooter-ml', 'Machine learning for enemy behavior and difficulty balancing', 'active', false, ARRAY['shooter', 'ml', 'space', 'balance'], NULL, 'unity', '2023.1', ARRAY['windows', 'mac', 'web'], 'shooter', '2d'),
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Puzzle Game Analytics', 'puzzle-game-analytics', 'Player behavior analysis and level recommendation system', 'active', true, ARRAY['puzzle', 'analytics', 'recommendation'], 'tt444444-4444-4444-4444-444444444444', 'unity', '2023.1', ARRAY['ios', 'android', 'web'], 'puzzle', '2d'),
    ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'Retro Platformer', 'retro-platformer', 'Classic 2D platformer with modern AI features', 'active', true, ARRAY['platformer', 'retro', '2d'], 'tt111111-1111-1111-1111-111111111111', 'unity', '2022.3', ARRAY['windows', 'mac', 'linux', 'web'], 'platformer', 'pixel');

-- Sample user project collaborators
INSERT INTO project_collaborators (project_id, user_id, role, accepted_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'admin', CURRENT_TIMESTAMP),
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'viewer', CURRENT_TIMESTAMP),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'admin', CURRENT_TIMESTAMP),
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'admin', CURRENT_TIMESTAMP),
    ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'admin', CURRENT_TIMESTAMP);

-- Sample assets
INSERT INTO assets (id, project_id, name, type, file_path, original_filename, file_size, mime_type, metadata, tags, description, uploaded_by) VALUES
    ('770e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'NPC Behavior Dataset', 'dataset', '/data/npc_behavior_v1.csv', 'npc_behavior_training.csv', 1024000, 'text/csv', '{"rows": 10000, "features": 15, "quality_score": 0.95}', ARRAY['npc', 'behavior', 'training'], 'Training data for NPC behavior classification', '550e8400-e29b-41d4-a716-446655440002'),
    ('770e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'Character Textures', 'texture', '/assets/character_pack_v2.zip', 'fantasy_characters.zip', 5120000, 'application/zip', '{"texture_count": 50, "resolution": "1024x1024", "format": "PNG"}', ARRAY['texture', 'character', 'fantasy'], 'High-resolution character textures for fantasy NPCs', '550e8400-e29b-41d4-a716-446655440002'),
    ('770e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440002', 'Enemy AI Script', 'script', '/scripts/enemy_ai_v3.py', 'smart_enemy_ai.py', 8192, 'text/x-python', '{"language": "python", "version": "3.9", "dependencies": ["tensorflow", "numpy"]}', ARRAY['ai', 'script', 'enemy'], 'Advanced enemy AI behavior script with ML integration', '550e8400-e29b-41d4-a716-446655440002'),
    ('770e8400-e29b-41d4-a716-446655440004', '660e8400-e29b-41d4-a716-446655440004', 'Pixel Art Sprites', 'texture', '/assets/retro_sprites.zip', 'pixel_characters.zip', 2048000, 'application/zip', '{"sprite_count": 32, "resolution": "32x32", "format": "PNG"}', ARRAY['pixel', 'sprite', 'character'], 'Retro pixel art character sprites', '550e8400-e29b-41d4-a716-446655440004');

-- Sample AI requests
INSERT INTO ai_requests (id, user_id, project_id, request_type, status, input_data, output_data, processing_time_ms, cost_credits) VALUES
    ('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'text_generation', 'completed', '{"prompt": "Generate NPC dialogue for tavern keeper", "max_tokens": 100}', '{"generated_text": "Welcome to the Prancing Pony, traveler! What brings you to our humble establishment?", "tokens_used": 18}', 1500, 0.05),
    ('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440002', 'model_training', 'completed', '{"dataset_id": "770e8400-e29b-41d4-a716-446655440001", "model_type": "classification", "epochs": 10}', '{"model_id": "model_123", "accuracy": 0.94, "loss": 0.12}', 45000, 2.50),
    ('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440003', 'data_analysis', 'processing', '{"dataset": "player_behavior.csv", "analysis_type": "clustering"}', '{}', NULL, 1.00);

-- Sample ML models
INSERT INTO ml_models (id, project_id, name, version, model_type, framework, file_path, file_size, accuracy, training_data_id, hyperparameters, metrics, trained_by) VALUES
    ('990e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'NPC Behavior Classifier', 'v1.0', 'classification', 'tensorflow', '/models/npc_behavior_v1.h5', 10240000, 0.94, '770e8400-e29b-41d4-a716-446655440001', '{"learning_rate": 0.001, "batch_size": 32, "epochs": 50}', '{"precision": 0.93, "recall": 0.95, "f1_score": 0.94}', '550e8400-e29b-41d4-a716-446655440002'),
    ('990e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440002', 'Enemy Difficulty Predictor', 'v2.1', 'regression', 'pytorch', '/models/difficulty_predictor_v2.pt', 8192000, 0.87, NULL, '{"learning_rate": 0.0001, "hidden_layers": 3, "dropout": 0.2}', '{"mse": 0.13, "mae": 0.08, "r2_score": 0.87}', '550e8400-e29b-41d4-a716-446655440002');

-- Sample datasets
INSERT INTO datasets (id, project_id, name, version, description, file_path, file_size, row_count, column_count, quality_score, created_by) VALUES
    ('aa0e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'NPC Behavior Training', 'v1.0', 'Labeled dataset for NPC behavior classification', '/datasets/npc_behavior_v1.parquet', 2048000, 10000, 15, 0.95, '550e8400-e29b-41d4-a716-446655440002'),
    ('aa0e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440003', 'Player Analytics Data', 'v1.2', 'Anonymized player behavior and progression data', '/datasets/player_analytics_v1_2.parquet', 15360000, 50000, 25, 0.92, '550e8400-e29b-41d4-a716-446655440003');

-- Sample audit logs
INSERT INTO audit_logs (user_id, action, resource_type, resource_id, resource_name, details, ip_address, success) VALUES
    ('550e8400-e29b-41d4-a716-446655440002', 'create', 'project', '660e8400-e29b-41d4-a716-446655440001', 'Fantasy RPG AI', '{"description": "Created new project"}', '192.168.1.100', true),
    ('550e8400-e29b-41d4-a716-446655440002', 'create', 'asset', '770e8400-e29b-41d4-a716-446655440001', 'NPC Behavior Dataset', '{"file_size": 1024000, "type": "dataset"}', '192.168.1.100', true),
    ('550e8400-e29b-41d4-a716-446655440003', 'read', 'project', '660e8400-e29b-41d4-a716-446655440001', 'Fantasy RPG AI', '{"action": "viewed project details"}', '192.168.1.101', true);

-- Sample system configuration (updated with OAuth and game features)
INSERT INTO system_config (key, value, description, is_public) VALUES
    ('welcome_message', '"Welcome to GameForge Development Environment"', 'Welcome message for new users', true),
    ('max_upload_size_dev', '100', 'Maximum upload size in MB for development', false),
    ('ai_api_endpoint', '"http://localhost:8000/api/v1"', 'AI service API endpoint', false),
    ('template_approval_required', 'true', 'Whether game templates require approval', false),
    ('featured_templates_count', '6', 'Number of featured templates to display', true),
    ('oauth_github_enabled', 'true', 'Enable GitHub OAuth integration', true),
    ('oauth_google_enabled', 'false', 'Enable Google OAuth integration', true),
    ('default_theme', '"system"', 'Default theme for new users', true),
    ('supported_engines', '["unity", "unreal", "godot", "custom"]', 'List of supported game engines', true),
    ('max_templates_per_user', '5', 'Maximum templates a user can create', true);

-- Update project statistics
UPDATE projects SET 
    total_assets = (SELECT COUNT(*) FROM assets WHERE project_id = projects.id),
    total_size_bytes = (SELECT COALESCE(SUM(file_size), 0) FROM assets WHERE project_id = projects.id);

COMMIT;

-- Display sample data summary
SELECT 'Sample data created successfully!' as message;
SELECT 
    (SELECT COUNT(*) FROM users) as users_created,
    (SELECT COUNT(*) FROM projects) as projects_created,
    (SELECT COUNT(*) FROM assets) as assets_created,
    (SELECT COUNT(*) FROM ai_requests) as ai_requests_created;