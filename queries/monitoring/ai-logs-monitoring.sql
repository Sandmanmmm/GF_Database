-- GameForge AI Logs & Monitoring Queries
-- Use these queries in pgAdmin for audit trails and system monitoring

-- ==============================================
-- AUDIT LOGS & SYSTEM ACTIVITY
-- ==============================================

-- 1. Recent Audit Activity (Last 24 hours)
SELECT 
    al.timestamp,
    al.action,
    al.table_name,
    u.username,
    al.record_id,
    al.changes,
    al.ip_address
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
WHERE al.timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY al.timestamp DESC;

-- 2. Audit Activity by Action Type
SELECT 
    action,
    COUNT(*) as action_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT table_name) as tables_affected,
    MIN(timestamp) as first_occurrence,
    MAX(timestamp) as last_occurrence
FROM audit_logs
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY action
ORDER BY action_count DESC;

-- 3. Most Active Users (Audit Trail)
SELECT 
    u.username,
    u.email,
    COUNT(al.id) as total_actions,
    COUNT(CASE WHEN al.action = 'INSERT' THEN 1 END) as creates,
    COUNT(CASE WHEN al.action = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN al.action = 'DELETE' THEN 1 END) as deletes,
    MAX(al.timestamp) as last_activity
FROM users u
JOIN audit_logs al ON u.id = al.user_id
WHERE al.timestamp >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.username, u.email
ORDER BY total_actions DESC;

-- 4. Table Activity Summary
SELECT 
    table_name,
    COUNT(*) as total_changes,
    COUNT(CASE WHEN action = 'INSERT' THEN 1 END) as inserts,
    COUNT(CASE WHEN action = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN action = 'DELETE' THEN 1 END) as deletes,
    COUNT(DISTINCT user_id) as unique_users
FROM audit_logs
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY table_name
ORDER BY total_changes DESC;

-- ==============================================
-- AI REQUEST ANALYTICS
-- ==============================================

-- 5. AI Request Overview
SELECT 
    ar.id,
    ar.request_type,
    ar.status,
    u.username as requested_by,
    ar.created_at,
    ar.completed_at,
    EXTRACT(EPOCH FROM (COALESCE(ar.completed_at, NOW()) - ar.created_at)) as duration_seconds
FROM ai_requests ar
JOIN users u ON ar.user_id = u.id
ORDER BY ar.created_at DESC;

-- 6. AI Request Performance Metrics
SELECT 
    request_type,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_requests,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
    ROUND(
        COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(*), 2
    ) as success_rate,
    AVG(
        CASE WHEN status = 'completed' 
        THEN EXTRACT(EPOCH FROM (completed_at - created_at))
        END
    ) as avg_completion_time_seconds
FROM ai_requests
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY request_type
ORDER BY total_requests DESC;

-- 7. AI Request Usage by User
SELECT 
    u.username,
    u.email,
    COUNT(ar.id) as total_requests,
    COUNT(CASE WHEN ar.status = 'completed' THEN 1 END) as successful_requests,
    MAX(ar.created_at) as last_request,
    ARRAY_AGG(DISTINCT ar.request_type) as request_types_used
FROM users u
JOIN ai_requests ar ON u.id = ar.user_id
WHERE ar.created_at >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.username, u.email
ORDER BY total_requests DESC;

-- 8. AI Request Timeline (Daily Activity)
SELECT 
    DATE(created_at) as request_date,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_requests,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(
        CASE WHEN status = 'completed' 
        THEN EXTRACT(EPOCH FROM (completed_at - created_at))
        END
    ) as avg_completion_time_seconds
FROM ai_requests
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY request_date DESC;

-- ==============================================
-- SYSTEM CONFIGURATION MONITORING
-- ==============================================

-- 9. System Configuration Overview
SELECT 
    key,
    value,
    description,
    is_public,
    u.username as last_updated_by,
    updated_at
FROM system_config sc
LEFT JOIN users u ON sc.updated_by = u.id
ORDER BY updated_at DESC;

-- 10. Recent Configuration Changes
SELECT 
    sc.key,
    sc.value,
    sc.description,
    u.username as updated_by,
    sc.updated_at,
    al.changes as audit_changes
FROM system_config sc
LEFT JOIN users u ON sc.updated_by = u.id
LEFT JOIN audit_logs al ON al.table_name = 'system_config' 
    AND al.record_id = sc.key::text
    AND al.timestamp = sc.updated_at
WHERE sc.updated_at >= NOW() - INTERVAL '30 days'
ORDER BY sc.updated_at DESC;

-- ==============================================
-- ERROR MONITORING & DIAGNOSTICS
-- ==============================================

-- 11. Failed AI Requests Analysis
SELECT 
    request_type,
    COUNT(*) as failure_count,
    ARRAY_AGG(DISTINCT error_message) as error_messages,
    COUNT(DISTINCT user_id) as affected_users,
    MIN(created_at) as first_failure,
    MAX(created_at) as last_failure
FROM ai_requests
WHERE status = 'failed'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY request_type
ORDER BY failure_count DESC;

-- 12. Suspicious Activity Detection
SELECT 
    u.username,
    COUNT(al.id) as action_count,
    COUNT(DISTINCT al.ip_address) as unique_ips,
    ARRAY_AGG(DISTINCT al.action) as actions_performed,
    MIN(al.timestamp) as first_action,
    MAX(al.timestamp) as last_action
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY u.id, u.username
HAVING COUNT(al.id) > 100  -- More than 100 actions in 1 hour
ORDER BY action_count DESC;

-- ==============================================
-- PERFORMANCE MONITORING
-- ==============================================

-- 13. Database Performance Metrics
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_tup_hot_upd as hot_updates,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC;

-- 14. Table Sizes and Growth
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                   pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 15. Index Usage Statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read as index_reads,
    idx_tup_fetch as index_fetches,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_tup_read DESC;

-- ==============================================
-- SECURITY MONITORING
-- ==============================================

-- 16. Login Attempts and Sessions
SELECT 
    DATE(created_at) as login_date,
    COUNT(*) as session_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN expires_at > NOW() THEN 1 END) as active_sessions
FROM user_sessions
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY login_date DESC;

-- 17. API Key Usage Monitoring
SELECT 
    u.username,
    ak.key_name,
    ak.last_used,
    ak.usage_count,
    ak.created_at,
    CASE 
        WHEN ak.expires_at IS NULL THEN 'No expiration'
        WHEN ak.expires_at > NOW() THEN 'Valid'
        ELSE 'Expired'
    END as key_status
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
WHERE ak.last_used >= NOW() - INTERVAL '7 days'
ORDER BY ak.last_used DESC;

-- ==============================================
-- DATA QUALITY MONITORING
-- ==============================================

-- 18. Data Integrity Checks
SELECT 
    'Users without preferences' as check_name,
    COUNT(*) as issue_count
FROM users u
LEFT JOIN user_preferences up ON u.id = up.user_id
WHERE up.user_id IS NULL

UNION ALL

SELECT 
    'Projects without owners',
    COUNT(*)
FROM projects p
LEFT JOIN users u ON p.owner_id = u.id
WHERE u.id IS NULL

UNION ALL

SELECT 
    'Assets without uploaders',
    COUNT(*)
FROM assets a
LEFT JOIN users u ON a.uploaded_by = u.id
WHERE u.id IS NULL;

-- 19. Cleanup Recommendations
SELECT 
    'Expired sessions' as cleanup_item,
    COUNT(*) as items_to_cleanup,
    'DELETE FROM user_sessions WHERE expires_at < NOW()' as cleanup_query
FROM user_sessions
WHERE expires_at < NOW()

UNION ALL

SELECT 
    'Old audit logs (>90 days)',
    COUNT(*),
    'DELETE FROM audit_logs WHERE timestamp < NOW() - INTERVAL ''90 days'''
FROM audit_logs
WHERE timestamp < NOW() - INTERVAL '90 days'

UNION ALL

SELECT 
    'Inactive API keys',
    COUNT(*),
    'UPDATE api_keys SET is_active = false WHERE last_used < NOW() - INTERVAL ''30 days'''
FROM api_keys
WHERE last_used < NOW() - INTERVAL '30 days'
  AND is_active = true;

-- 20. System Health Dashboard
SELECT 
    'Total Users' as metric,
    COUNT(*)::text as value,
    'users' as unit
FROM users
WHERE is_active = true

UNION ALL

SELECT 
    'Active Projects',
    COUNT(*)::text,
    'projects'
FROM projects
WHERE status = 'active'

UNION ALL

SELECT 
    'Total Storage Used',
    pg_size_pretty(SUM(file_size)),
    'bytes'
FROM assets

UNION ALL

SELECT 
    'AI Requests Today',
    COUNT(*)::text,
    'requests'
FROM ai_requests
WHERE created_at >= CURRENT_DATE

UNION ALL

SELECT 
    'Database Size',
    pg_size_pretty(pg_database_size('gameforge_dev')),
    'bytes';