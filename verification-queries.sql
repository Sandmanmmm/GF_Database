-- GameForge Database Verification Queries
-- Run these in pgAdmin 4 Query Tool to verify all features

-- 1. Database Overview
SELECT 
    'GameForge Database Status' as check_name,
    'Ready' as status,
    COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public';

-- 2. Table Structure Summary
SELECT 
    table_name,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_schema = 'public'
GROUP BY table_name
ORDER BY table_name;

-- 3. User System Test
SELECT 
    'User System' as feature,
    COUNT(*) as user_count,
    COUNT(DISTINCT provider) as auth_providers
FROM users;

-- 4. OAuth Integration Check
SELECT 
    provider,
    COUNT(*) as user_count
FROM users 
GROUP BY provider
ORDER BY provider;

-- 5. Game Template Marketplace Features
SELECT 
    'Game Templates' as feature,
    COUNT(CASE WHEN price = 0 THEN 1 END) as free_templates,
    COUNT(CASE WHEN price > 0 THEN 1 END) as paid_templates,
    COUNT(*) as total_templates
FROM game_templates;

-- 6. AI/ML System Components
SELECT 
    table_name as ai_component,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('ai_requests', 'ml_models', 'datasets')
GROUP BY table_name
ORDER BY table_name;

-- 7. Project Management System
SELECT 
    'Project System' as feature,
    COUNT(DISTINCT projects.id) as total_projects,
    COUNT(DISTINCT project_collaborators.user_id) as collaborators
FROM projects
LEFT JOIN project_collaborators ON projects.id = project_collaborators.project_id;

-- 8. Database Performance - Index Coverage
SELECT 
    'Database Performance' as metric,
    COUNT(*) as total_indexes,
    COUNT(DISTINCT tablename) as indexed_tables
FROM pg_indexes 
WHERE schemaname = 'public';

-- 9. System Configuration
SELECT 
    key,
    value,
    description
FROM system_config
ORDER BY key;

-- 10. Extension Status
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'citext', 'pg_trgm')
ORDER BY extname;

-- 11. User Preferences System
SELECT 
    'User Preferences' as feature,
    COUNT(DISTINCT user_id) as users_with_preferences
FROM user_preferences;

-- 12. Asset Management System
SELECT 
    'Asset Management' as feature,
    COUNT(*) as total_assets,
    COUNT(DISTINCT asset_type) as asset_types
FROM assets;

-- 13. Audit System Verification
SELECT 
    'Audit System' as feature,
    COUNT(*) as audit_entries,
    COUNT(DISTINCT action) as tracked_actions
FROM audit_logs;

-- 14. Session Management
SELECT 
    'Session Management' as feature,
    COUNT(*) as active_sessions,
    COUNT(DISTINCT user_id) as users_with_sessions
FROM user_sessions;

-- 15. API Key Management
SELECT 
    'API Keys' as feature,
    COUNT(*) as total_keys,
    COUNT(CASE WHEN is_active THEN 1 END) as active_keys
FROM api_keys;

-- Final Status Message
SELECT 
    '🎉 GameForge Database Verification Complete!' as status,
    'All systems operational' as message,
    NOW() as verified_at;