-- GameForge Database Quick Start Queries for pgAdmin 4
-- Copy and paste these into the pgAdmin Query Tool

-- 1. Database Overview
SELECT 
    'GameForge Database Status' as metric,
    'Operational' as status,
    COUNT(*) as total_tables
FROM information_schema.tables 
WHERE table_schema = 'public';

-- 2. All Available Tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 3. System Configuration
SELECT 
    key,
    value,
    description
FROM system_config
ORDER BY key;

-- 4. User System Check
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_active THEN 1 END) as active_users,
    COUNT(CASE WHEN provider = 'github' THEN 1 END) as github_users,
    COUNT(CASE WHEN provider = 'email' THEN 1 END) as email_users
FROM users;

-- 5. Project System Check  
SELECT 
    COUNT(*) as total_projects,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_projects,
    COUNT(CASE WHEN visibility = 'public' THEN 1 END) as public_projects
FROM projects;

-- 6. Database Health Summary
SELECT 
    'System Status' as component,
    'Ready for Development' as status,
    NOW() as timestamp;