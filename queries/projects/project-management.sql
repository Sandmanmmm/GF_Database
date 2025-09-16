-- GameForge Projects Management Queries
-- Use these queries in pgAdmin to manage game projects and collaboration

-- ==============================================
-- PROJECT OVERVIEW & ANALYTICS
-- ==============================================

-- 1. Project Overview Dashboard
SELECT 
    p.id,
    p.name,
    p.description,
    u.username as owner,
    p.visibility,
    p.status,
    p.created_at,
    p.updated_at,
    COUNT(DISTINCT pc.user_id) as collaborator_count,
    COUNT(DISTINCT a.id) as asset_count
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN project_collaborators pc ON p.id = pc.project_id
LEFT JOIN assets a ON p.id = a.project_id
GROUP BY p.id, p.name, p.description, u.username, p.visibility, p.status, p.created_at, p.updated_at
ORDER BY p.updated_at DESC;

-- 2. Project Status Distribution
SELECT 
    status,
    COUNT(*) as project_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM projects
GROUP BY status
ORDER BY project_count DESC;

-- 3. Project Visibility Analysis
SELECT 
    visibility,
    COUNT(*) as project_count,
    COUNT(DISTINCT owner_id) as unique_owners
FROM projects
GROUP BY visibility
ORDER BY project_count DESC;

-- 4. Most Active Project Owners
SELECT 
    u.username,
    u.email,
    COUNT(p.id) as project_count,
    COUNT(CASE WHEN p.status = 'active' THEN 1 END) as active_projects,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) as completed_projects,
    MAX(p.updated_at) as last_project_update
FROM users u
JOIN projects p ON u.id = p.owner_id
GROUP BY u.id, u.username, u.email
ORDER BY project_count DESC;

-- ==============================================
-- COLLABORATION ANALYTICS
-- ==============================================

-- 5. Project Collaboration Overview
SELECT 
    p.name as project_name,
    u_owner.username as project_owner,
    u_collab.username as collaborator,
    pc.role as collaborator_role,
    pc.permissions,
    pc.joined_at,
    pc.last_activity
FROM project_collaborators pc
JOIN projects p ON pc.project_id = p.id
JOIN users u_owner ON p.owner_id = u_owner.id
JOIN users u_collab ON pc.user_id = u_collab.id
ORDER BY pc.joined_at DESC;

-- 6. Most Collaborative Projects
SELECT 
    p.name,
    u.username as owner,
    COUNT(pc.user_id) as collaborator_count,
    ARRAY_AGG(DISTINCT pc.role) as roles_involved,
    MAX(pc.last_activity) as last_collaboration
FROM projects p
JOIN users u ON p.owner_id = u.id
JOIN project_collaborators pc ON p.id = pc.project_id
GROUP BY p.id, p.name, u.username
ORDER BY collaborator_count DESC;

-- 7. Most Active Collaborators
SELECT 
    u.username,
    u.email,
    COUNT(DISTINCT pc.project_id) as projects_collaborated,
    ARRAY_AGG(DISTINCT pc.role) as roles_held,
    MAX(pc.last_activity) as last_activity
FROM users u
JOIN project_collaborators pc ON u.id = pc.user_id
GROUP BY u.id, u.username, u.email
ORDER BY projects_collaborated DESC;

-- ==============================================
-- GAME TEMPLATE MARKETPLACE
-- ==============================================

-- 8. Template Marketplace Overview
SELECT 
    id,
    name,
    description,
    template_type,
    engine,
    version,
    price,
    rating,
    downloads,
    creator_username,
    status,
    created_at
FROM game_templates
ORDER BY downloads DESC, rating DESC;

-- 9. Template Performance Analytics
SELECT 
    template_type,
    engine,
    COUNT(*) as template_count,
    AVG(rating) as avg_rating,
    SUM(downloads) as total_downloads,
    AVG(price) as avg_price
FROM game_templates
WHERE status = 'published'
GROUP BY template_type, engine
ORDER BY total_downloads DESC;

-- 10. Top Performing Templates
SELECT 
    name,
    template_type,
    engine,
    rating,
    downloads,
    price,
    creator_username,
    (downloads * rating) as popularity_score
FROM game_templates
WHERE status = 'published'
ORDER BY popularity_score DESC
LIMIT 10;

-- 11. Template Revenue Analysis (Paid Templates)
SELECT 
    template_type,
    COUNT(*) as paid_templates,
    SUM(downloads * price) as estimated_revenue,
    AVG(price) as avg_price,
    MAX(price) as highest_price
FROM game_templates
WHERE price > 0 AND status = 'published'
GROUP BY template_type
ORDER BY estimated_revenue DESC;

-- ==============================================
-- PROJECT ASSETS & RESOURCES
-- ==============================================

-- 12. Project Asset Summary
SELECT 
    p.name as project_name,
    u.username as owner,
    COUNT(a.id) as total_assets,
    COUNT(DISTINCT a.asset_type) as asset_types,
    SUM(a.file_size) as total_size_bytes,
    pg_size_pretty(SUM(a.file_size)) as total_size_formatted,
    MAX(a.created_at) as last_asset_upload
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN assets a ON p.id = a.project_id
GROUP BY p.id, p.name, u.username
ORDER BY total_assets DESC;

-- 13. Asset Type Distribution by Project
SELECT 
    a.asset_type,
    COUNT(*) as asset_count,
    COUNT(DISTINCT a.project_id) as projects_using,
    AVG(a.file_size) as avg_file_size,
    pg_size_pretty(SUM(a.file_size)) as total_size
FROM assets a
GROUP BY a.asset_type
ORDER BY asset_count DESC;

-- ==============================================
-- PROJECT TIMELINE & ACTIVITY
-- ==============================================

-- 14. Recent Project Activity
SELECT 
    p.name as project_name,
    u.username as owner,
    p.status,
    p.updated_at,
    CASE 
        WHEN p.updated_at >= NOW() - INTERVAL '1 day' THEN 'Today'
        WHEN p.updated_at >= NOW() - INTERVAL '7 days' THEN 'This week'
        WHEN p.updated_at >= NOW() - INTERVAL '30 days' THEN 'This month'
        ELSE 'Older'
    END as activity_period
FROM projects p
JOIN users u ON p.owner_id = u.id
ORDER BY p.updated_at DESC;

-- 15. Project Development Timeline
SELECT 
    p.name,
    u.username as owner,
    p.created_at,
    p.updated_at,
    EXTRACT(DAYS FROM p.updated_at - p.created_at) as development_days,
    p.status
FROM projects p
JOIN users u ON p.owner_id = u.id
WHERE p.status IN ('active', 'completed')
ORDER BY development_days DESC;

-- ==============================================
-- SEARCH & FILTER UTILITIES
-- ==============================================

-- 16. Find Projects by Name or Description
-- Replace 'search_term' with actual search text
SELECT 
    p.name,
    p.description,
    u.username as owner,
    p.status,
    p.visibility,
    p.created_at
FROM projects p
JOIN users u ON p.owner_id = u.id
WHERE p.name ILIKE '%search_term%' 
   OR p.description ILIKE '%search_term%';

-- 17. Projects by Technology/Engine
SELECT 
    gt.engine,
    COUNT(DISTINCT p.id) as projects_using,
    ARRAY_AGG(DISTINCT p.name) as project_names
FROM projects p
JOIN game_templates gt ON p.template_id = gt.id
GROUP BY gt.engine
ORDER BY projects_using DESC;

-- 18. Inactive Projects (No updates in 30+ days)
SELECT 
    p.name,
    u.username as owner,
    p.status,
    p.updated_at,
    EXTRACT(DAYS FROM NOW() - p.updated_at) as days_since_update
FROM projects p
JOIN users u ON p.owner_id = u.id
WHERE p.updated_at < NOW() - INTERVAL '30 days'
  AND p.status = 'active'
ORDER BY p.updated_at ASC;