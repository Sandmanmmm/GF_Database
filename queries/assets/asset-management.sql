-- GameForge Assets Management Queries
-- Use these queries in pgAdmin to manage game assets, uploads, and versioning

-- ==============================================
-- ASSET OVERVIEW & ANALYTICS
-- ==============================================

-- 1. Asset Overview Dashboard
SELECT 
    a.id,
    a.name,
    a.asset_type,
    a.file_size,
    pg_size_pretty(a.file_size) as file_size_formatted,
    a.version,
    u.username as uploaded_by,
    p.name as project_name,
    a.created_at,
    a.updated_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
LEFT JOIN projects p ON a.project_id = p.id
ORDER BY a.created_at DESC;

-- 2. Asset Type Distribution
SELECT 
    asset_type,
    COUNT(*) as asset_count,
    SUM(file_size) as total_size_bytes,
    pg_size_pretty(SUM(file_size)) as total_size_formatted,
    AVG(file_size) as avg_file_size,
    pg_size_pretty(AVG(file_size)::bigint) as avg_size_formatted
FROM assets
GROUP BY asset_type
ORDER BY asset_count DESC;

-- 3. Storage Usage by User
SELECT 
    u.username,
    u.email,
    COUNT(a.id) as asset_count,
    SUM(a.file_size) as total_storage_bytes,
    pg_size_pretty(SUM(a.file_size)) as total_storage_formatted,
    COUNT(DISTINCT a.asset_type) as asset_types_used
FROM users u
JOIN assets a ON u.id = a.uploaded_by
GROUP BY u.id, u.username, u.email
ORDER BY total_storage_bytes DESC;

-- 4. Storage Usage by Project
SELECT 
    p.name as project_name,
    u.username as project_owner,
    COUNT(a.id) as asset_count,
    SUM(a.file_size) as total_storage_bytes,
    pg_size_pretty(SUM(a.file_size)) as total_storage_formatted,
    COUNT(DISTINCT a.asset_type) as asset_types
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN assets a ON p.id = a.project_id
WHERE a.id IS NOT NULL
GROUP BY p.id, p.name, u.username
ORDER BY total_storage_bytes DESC;

-- ==============================================
-- ASSET VERSIONING
-- ==============================================

-- 5. Asset Version History
-- Replace 'asset_name' with actual asset name
SELECT 
    name,
    version,
    file_size,
    pg_size_pretty(file_size) as file_size_formatted,
    u.username as uploaded_by,
    created_at,
    metadata
FROM assets a
JOIN users u ON a.uploaded_by = u.id
WHERE name = 'asset_name'
ORDER BY version DESC;

-- 6. Assets with Multiple Versions
SELECT 
    name,
    COUNT(*) as version_count,
    MIN(version) as first_version,
    MAX(version) as latest_version,
    SUM(file_size) as total_size_all_versions,
    pg_size_pretty(SUM(file_size)) as total_size_formatted
FROM assets
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY version_count DESC;

-- 7. Latest Version of Each Asset
SELECT DISTINCT ON (name)
    name,
    version,
    asset_type,
    file_size,
    pg_size_pretty(file_size) as file_size_formatted,
    u.username as uploaded_by,
    p.name as project_name,
    created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
LEFT JOIN projects p ON a.project_id = p.id
ORDER BY name, version DESC;

-- ==============================================
-- AI/ML DATASETS
-- ==============================================

-- 8. Dataset Overview
SELECT 
    d.id,
    d.name,
    d.description,
    d.dataset_type,
    d.size_mb,
    d.record_count,
    u.username as created_by,
    d.created_at,
    d.updated_at
FROM datasets d
JOIN users u ON d.created_by = u.id
ORDER BY d.created_at DESC;

-- 9. Dataset Usage Statistics
SELECT 
    dataset_type,
    COUNT(*) as dataset_count,
    SUM(size_mb) as total_size_mb,
    SUM(record_count) as total_records,
    AVG(size_mb) as avg_size_mb
FROM datasets
GROUP BY dataset_type
ORDER BY total_size_mb DESC;

-- 10. Large Datasets (> 100MB)
SELECT 
    name,
    description,
    dataset_type,
    size_mb,
    record_count,
    u.username as created_by,
    created_at
FROM datasets d
JOIN users u ON d.created_by = u.id
WHERE size_mb > 100
ORDER BY size_mb DESC;

-- ==============================================
-- ML MODELS
-- ==============================================

-- 11. ML Model Overview
SELECT 
    m.id,
    m.name,
    m.description,
    m.model_type,
    m.framework,
    m.version,
    m.accuracy,
    u.username as trained_by,
    m.created_at,
    m.updated_at
FROM ml_models m
JOIN users u ON m.trained_by = u.id
ORDER BY m.created_at DESC;

-- 12. Model Performance Analytics
SELECT 
    model_type,
    framework,
    COUNT(*) as model_count,
    AVG(accuracy) as avg_accuracy,
    MAX(accuracy) as best_accuracy,
    MIN(accuracy) as worst_accuracy
FROM ml_models
WHERE accuracy IS NOT NULL
GROUP BY model_type, framework
ORDER BY avg_accuracy DESC;

-- 13. Best Performing Models
SELECT 
    name,
    model_type,
    framework,
    accuracy,
    u.username as trained_by,
    created_at
FROM ml_models m
JOIN users u ON m.trained_by = u.id
WHERE accuracy IS NOT NULL
ORDER BY accuracy DESC
LIMIT 10;

-- ==============================================
-- ASSET RELATIONSHIPS & DEPENDENCIES
-- ==============================================

-- 14. Assets by Project Relationship
SELECT 
    p.name as project_name,
    a.name as asset_name,
    a.asset_type,
    a.version,
    pg_size_pretty(a.file_size) as file_size,
    u.username as uploaded_by
FROM projects p
JOIN assets a ON p.id = a.project_id
JOIN users u ON a.uploaded_by = u.id
ORDER BY p.name, a.asset_type, a.name;

-- 15. Orphaned Assets (No Project Association)
SELECT 
    a.name,
    a.asset_type,
    a.version,
    pg_size_pretty(a.file_size) as file_size,
    u.username as uploaded_by,
    a.created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
WHERE a.project_id IS NULL
ORDER BY a.created_at DESC;

-- ==============================================
-- STORAGE OPTIMIZATION
-- ==============================================

-- 16. Largest Assets (Storage Optimization)
SELECT 
    name,
    asset_type,
    version,
    file_size,
    pg_size_pretty(file_size) as file_size_formatted,
    u.username as uploaded_by,
    created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
ORDER BY file_size DESC
LIMIT 20;

-- 17. Old Asset Versions (Cleanup Candidates)
SELECT 
    a1.name,
    a1.version as old_version,
    a2.version as latest_version,
    a1.file_size as old_size,
    pg_size_pretty(a1.file_size) as old_size_formatted,
    a1.created_at as old_created_date,
    EXTRACT(DAYS FROM NOW() - a1.created_at) as days_old
FROM assets a1
JOIN (
    SELECT name, MAX(version) as max_version
    FROM assets
    GROUP BY name
) latest ON a1.name = latest.name
JOIN assets a2 ON a2.name = latest.name AND a2.version = latest.max_version
WHERE a1.version < latest.max_version
  AND a1.created_at < NOW() - INTERVAL '30 days'
ORDER BY a1.file_size DESC;

-- ==============================================
-- ASSET METADATA & SEARCH
-- ==============================================

-- 18. Asset Search by Name or Type
-- Replace 'search_term' with actual search text
SELECT 
    name,
    asset_type,
    version,
    pg_size_pretty(file_size) as file_size,
    u.username as uploaded_by,
    p.name as project_name,
    created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
LEFT JOIN projects p ON a.project_id = p.id
WHERE a.name ILIKE '%search_term%' 
   OR a.asset_type ILIKE '%search_term%'
ORDER BY created_at DESC;

-- 19. Asset Metadata Analysis
SELECT 
    name,
    asset_type,
    version,
    metadata,
    u.username as uploaded_by,
    created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
WHERE metadata IS NOT NULL
  AND metadata != '{}'::jsonb
ORDER BY created_at DESC;

-- 20. Recent Asset Activity (Last 7 days)
SELECT 
    DATE(created_at) as upload_date,
    COUNT(*) as assets_uploaded,
    COUNT(DISTINCT uploaded_by) as unique_uploaders,
    SUM(file_size) as total_size_bytes,
    pg_size_pretty(SUM(file_size)) as total_size_formatted
FROM assets
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY upload_date DESC;