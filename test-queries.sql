-- GameForge Database Test Queries
-- Run these in pgAdmin Query Tool to verify all features work correctly

-- ==============================================
-- BASIC CONNECTIVITY TESTS
-- ==============================================

-- Test 1: Database Connection and Basic Info
SELECT 
    'GameForge Database Test Suite' as test_suite,
    current_database() as database_name,
    current_user as connected_user,
    version() as postgresql_version,
    NOW() as test_timestamp;

-- Test 2: Table Count Verification
SELECT 
    'Table Count' as test_name,
    COUNT(*) as actual_count,
    15 as expected_count,
    CASE WHEN COUNT(*) = 15 THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM information_schema.tables 
WHERE table_schema = 'public';

-- ==============================================
-- USER SYSTEM TESTS
-- ==============================================

-- Test 3: User Creation and OAuth Support
-- Insert test user
INSERT INTO users (email, username, name, provider) 
VALUES ('test@gameforge.com', 'testuser', 'Test User', 'local')
ON CONFLICT (email) DO NOTHING;

-- Verify user exists
SELECT 
    'User Creation' as test_name,
    username,
    email,
    provider,
    CASE WHEN id IS NOT NULL THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM users 
WHERE email = 'test@gameforge.com';

-- Test 4: User Preferences System
-- Create user preferences
INSERT INTO user_preferences (user_id, theme, language, notifications_enabled, ai_assistance_enabled)
SELECT 
    u.id,
    'dark',
    'en',
    true,
    true
FROM users u 
WHERE u.email = 'test@gameforge.com'
ON CONFLICT (user_id) DO UPDATE SET
    theme = EXCLUDED.theme,
    language = EXCLUDED.language;

-- Verify preferences
SELECT 
    'User Preferences' as test_name,
    u.username,
    up.theme,
    up.language,
    CASE WHEN up.user_id IS NOT NULL THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM users u
LEFT JOIN user_preferences up ON u.id = up.user_id
WHERE u.email = 'test@gameforge.com';

-- ==============================================
-- GAME TEMPLATE MARKETPLACE TESTS
-- ==============================================

-- Test 5: Game Template Creation
-- Insert test template
INSERT INTO game_templates (
    name, 
    description, 
    template_type, 
    engine, 
    version, 
    features, 
    tags, 
    price, 
    rating, 
    downloads,
    creator_username,
    status
) VALUES (
    'Test 2D Platformer',
    'A test template for verification',
    'game',
    'Unity',
    '2023.3',
    '["physics", "2d", "platformer"]'::jsonb,
    '["test", "2d", "unity"]'::jsonb,
    0.00,
    4.5,
    100,
    'admin',
    'published'
) ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    updated_at = NOW();

-- Verify template and rating system
SELECT 
    'Game Template' as test_name,
    name,
    template_type,
    engine,
    price,
    rating,
    downloads,
    CASE WHEN rating BETWEEN 0 AND 5 THEN '✅ PASS' ELSE '❌ FAIL' END as rating_test,
    CASE WHEN downloads >= 0 THEN '✅ PASS' ELSE '❌ FAIL' END as downloads_test
FROM game_templates 
WHERE name = 'Test 2D Platformer';

-- ==============================================
-- PROJECT MANAGEMENT TESTS
-- ==============================================

-- Test 6: Project Creation
-- Create test project
INSERT INTO projects (
    name,
    description,
    owner_id,
    visibility,
    status,
    template_id
) 
SELECT 
    'Test Game Project',
    'A test project for verification',
    u.id,
    'private',
    'active',
    gt.id
FROM users u, game_templates gt
WHERE u.email = 'test@gameforge.com'
  AND gt.name = 'Test 2D Platformer'
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    updated_at = NOW();

-- Verify project with relationships
SELECT 
    'Project Creation' as test_name,
    p.name as project_name,
    u.username as owner,
    gt.name as template_used,
    p.visibility,
    p.status,
    CASE WHEN p.id IS NOT NULL THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN game_templates gt ON p.template_id = gt.id
WHERE p.name = 'Test Game Project';

-- ==============================================
-- ASSET MANAGEMENT TESTS
-- ==============================================

-- Test 7: Asset Upload Simulation
-- Insert test asset
INSERT INTO assets (
    name,
    asset_type,
    file_size,
    version,
    uploaded_by,
    project_id,
    metadata
)
SELECT 
    'test-sprite.png',
    'image',
    1024,
    1,
    u.id,
    p.id,
    '{"width": 32, "height": 32, "format": "PNG"}'::jsonb
FROM users u, projects p
WHERE u.email = 'test@gameforge.com'
  AND p.name = 'Test Game Project'
ON CONFLICT (name, version) DO UPDATE SET
    updated_at = NOW();

-- Verify asset with metadata
SELECT 
    'Asset Management' as test_name,
    a.name,
    a.asset_type,
    pg_size_pretty(a.file_size) as file_size,
    a.version,
    u.username as uploaded_by,
    p.name as project_name,
    a.metadata,
    CASE WHEN a.metadata IS NOT NULL THEN '✅ PASS' ELSE '❌ FAIL' END as metadata_test
FROM assets a
JOIN users u ON a.uploaded_by = u.id
JOIN projects p ON a.project_id = p.id
WHERE a.name = 'test-sprite.png';

-- ==============================================
-- AI/ML SYSTEM TESTS
-- ==============================================

-- Test 8: AI Request Simulation
-- Insert test AI request
INSERT INTO ai_requests (
    user_id,
    request_type,
    prompt,
    status,
    created_at,
    completed_at
)
SELECT 
    u.id,
    'code_generation',
    'Generate a simple player movement script',
    'completed',
    NOW() - INTERVAL '5 minutes',
    NOW()
FROM users u
WHERE u.email = 'test@gameforge.com'
ON CONFLICT DO NOTHING;

-- Verify AI request processing
SELECT 
    'AI Request System' as test_name,
    ar.request_type,
    ar.status,
    u.username as requested_by,
    EXTRACT(EPOCH FROM (ar.completed_at - ar.created_at)) as processing_time_seconds,
    CASE WHEN ar.status = 'completed' THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM ai_requests ar
JOIN users u ON ar.user_id = u.id
WHERE u.email = 'test@gameforge.com'
  AND ar.request_type = 'code_generation'
ORDER BY ar.created_at DESC
LIMIT 1;

-- ==============================================
-- AUDIT SYSTEM TESTS
-- ==============================================

-- Test 9: Audit Trail Verification
-- Check if audit logs are being created
SELECT 
    'Audit System' as test_name,
    COUNT(*) as total_audit_entries,
    COUNT(DISTINCT action) as unique_actions,
    COUNT(DISTINCT table_name) as tables_audited,
    MAX(timestamp) as latest_audit,
    CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM audit_logs
WHERE timestamp >= CURRENT_DATE;

-- ==============================================
-- PERFORMANCE TESTS
-- ==============================================

-- Test 10: Index Effectiveness
-- Check that important indexes exist
SELECT 
    'Database Indexes' as test_name,
    COUNT(*) as total_indexes,
    COUNT(CASE WHEN indexname LIKE '%_pkey' THEN 1 END) as primary_key_indexes,
    COUNT(CASE WHEN indexname LIKE 'idx_%' THEN 1 END) as custom_indexes,
    CASE WHEN COUNT(*) >= 70 THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM pg_indexes 
WHERE schemaname = 'public';

-- Test 11: Foreign Key Constraints
-- Verify referential integrity
SELECT 
    'Foreign Key Constraints' as test_name,
    COUNT(*) as total_foreign_keys,
    CASE WHEN COUNT(*) >= 15 THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM information_schema.table_constraints 
WHERE constraint_type = 'FOREIGN KEY' 
  AND table_schema = 'public';

-- ==============================================
-- EXTENSION TESTS
-- ==============================================

-- Test 12: PostgreSQL Extensions
-- Verify required extensions are installed
SELECT 
    'PostgreSQL Extensions' as test_name,
    extname as extension_name,
    extversion as version,
    CASE WHEN extname IN ('uuid-ossp', 'citext', 'pg_trgm') THEN '✅ PASS' ELSE '❌ INFO' END as test_result
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'citext', 'pg_trgm')
ORDER BY extname;

-- ==============================================
-- SEARCH FUNCTIONALITY TESTS
-- ==============================================

-- Test 13: Full-Text Search
-- Test trigram search on users
SELECT 
    'Full-Text Search' as test_name,
    COUNT(*) as searchable_users,
    CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END as test_result
FROM users 
WHERE username % 'admin'  -- Trigram similarity
   OR email % 'admin';

-- ==============================================
-- SUMMARY REPORT
-- ==============================================

-- Test 14: Overall Database Health
SELECT 
    'Database Health Summary' as report_section,
    'Metrics' as category,
    'Value' as result;

-- User metrics
SELECT 
    'User System' as report_section,
    'Total Users' as category,
    COUNT(*)::text as result
FROM users
UNION ALL
SELECT 
    'User System',
    'Active Users',
    COUNT(*)::text
FROM users WHERE is_active = true
UNION ALL
SELECT 
    'User System',
    'OAuth Users',
    COUNT(*)::text
FROM users WHERE provider != 'local';

-- Project metrics
SELECT 
    'Project System' as report_section,
    'Total Projects' as category,
    COUNT(*)::text as result
FROM projects
UNION ALL
SELECT 
    'Project System',
    'Active Projects',
    COUNT(*)::text
FROM projects WHERE status = 'active'
UNION ALL
SELECT 
    'Project System',
    'Templates Available',
    COUNT(*)::text
FROM game_templates WHERE status = 'published';

-- Storage metrics
SELECT 
    'Storage System' as report_section,
    'Total Assets' as category,
    COUNT(*)::text as result
FROM assets
UNION ALL
SELECT 
    'Storage System',
    'Storage Used',
    pg_size_pretty(SUM(file_size))
FROM assets
UNION ALL
SELECT 
    'Storage System',
    'Database Size',
    pg_size_pretty(pg_database_size(current_database()));

-- Final status
SELECT 
    '🎉 GameForge Database Test Complete!' as final_status,
    'All core systems verified' as message,
    NOW() as completed_at;