-- GameForge Users & Roles Management Queries
-- Use these queries in pgAdmin to manage user accounts and authentication

-- ==============================================
-- USER OVERVIEW & ANALYTICS
-- ==============================================

-- 1. User Account Overview
SELECT 
    id,
    username, 
    email, 
    provider, 
    role, 
    is_active, 
    email_verified,
    last_login,
    created_at 
FROM users 
ORDER BY created_at DESC;

-- 2. OAuth Provider Distribution
SELECT 
    provider,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM users 
GROUP BY provider
ORDER BY user_count DESC;

-- 3. User Role Distribution
SELECT 
    role,
    COUNT(*) as user_count,
    COUNT(CASE WHEN is_active THEN 1 END) as active_users,
    COUNT(CASE WHEN email_verified THEN 1 END) as verified_users
FROM users 
GROUP BY role
ORDER BY user_count DESC;

-- 4. Recent User Registrations (Last 30 days)
SELECT 
    DATE(created_at) as registration_date,
    COUNT(*) as new_users,
    COUNT(CASE WHEN provider = 'github' THEN 1 END) as github_users,
    COUNT(CASE WHEN provider = 'google' THEN 1 END) as google_users,
    COUNT(CASE WHEN provider = 'local' THEN 1 END) as local_users
FROM users 
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY registration_date DESC;

-- ==============================================
-- SESSION MANAGEMENT
-- ==============================================

-- 5. Active User Sessions
SELECT 
    u.username,
    u.email,
    s.session_token,
    s.expires_at,
    s.created_at,
    s.last_activity,
    CASE 
        WHEN s.expires_at > NOW() THEN 'Active'
        ELSE 'Expired'
    END as session_status
FROM user_sessions s
JOIN users u ON s.user_id = u.id
ORDER BY s.last_activity DESC;

-- 6. Session Analytics
SELECT 
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN expires_at > NOW() THEN 1 END) as active_sessions,
    COUNT(CASE WHEN expires_at <= NOW() THEN 1 END) as expired_sessions,
    AVG(EXTRACT(EPOCH FROM (expires_at - created_at))/3600) as avg_session_hours
FROM user_sessions;

-- ==============================================
-- API KEY MANAGEMENT
-- ==============================================

-- 7. API Key Overview
SELECT 
    u.username,
    ak.key_name,
    ak.is_active,
    ak.last_used,
    ak.expires_at,
    ak.created_at,
    CASE 
        WHEN ak.expires_at IS NULL THEN 'No expiration'
        WHEN ak.expires_at > NOW() THEN 'Valid'
        ELSE 'Expired'
    END as key_status
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
ORDER BY ak.created_at DESC;

-- 8. API Usage Statistics
SELECT 
    u.username,
    COUNT(ak.id) as total_keys,
    COUNT(CASE WHEN ak.is_active THEN 1 END) as active_keys,
    MAX(ak.last_used) as last_api_usage
FROM users u
LEFT JOIN api_keys ak ON u.id = ak.user_id
GROUP BY u.id, u.username
HAVING COUNT(ak.id) > 0
ORDER BY COUNT(ak.id) DESC;

-- ==============================================
-- USER PREFERENCES
-- ==============================================

-- 9. User Preference Settings
SELECT 
    u.username,
    up.theme,
    up.language,
    up.notifications_enabled,
    up.ai_assistance_enabled,
    up.updated_at
FROM user_preferences up
JOIN users u ON up.user_id = u.id
ORDER BY up.updated_at DESC;

-- 10. Preference Analytics
SELECT 
    theme,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM user_preferences
GROUP BY theme
ORDER BY user_count DESC;

-- ==============================================
-- USER SECURITY & VERIFICATION
-- ==============================================

-- 11. Two-Factor Authentication Status
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN two_factor_enabled THEN 1 END) as users_with_2fa,
    ROUND(COUNT(CASE WHEN two_factor_enabled THEN 1 END) * 100.0 / COUNT(*), 2) as tfa_adoption_rate
FROM users;

-- 12. Email Verification Status
SELECT 
    email_verified,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM users
GROUP BY email_verified
ORDER BY email_verified DESC;

-- ==============================================
-- ADMIN UTILITIES
-- ==============================================

-- 13. Find User by Email or Username
-- Replace 'search_term' with actual email or username
SELECT 
    id,
    username,
    email,
    provider,
    role,
    is_active,
    email_verified,
    created_at,
    last_login
FROM users 
WHERE email ILIKE '%search_term%' 
   OR username ILIKE '%search_term%';

-- 14. User Activity Summary
SELECT 
    u.username,
    u.email,
    u.last_login,
    COUNT(DISTINCT p.id) as project_count,
    COUNT(DISTINCT a.id) as asset_count,
    COUNT(DISTINCT ar.id) as ai_request_count
FROM users u
LEFT JOIN projects p ON u.id = p.owner_id
LEFT JOIN assets a ON u.id = a.uploaded_by
LEFT JOIN ai_requests ar ON u.id = ar.user_id
GROUP BY u.id, u.username, u.email, u.last_login
ORDER BY u.last_login DESC NULLS LAST;

-- 15. Inactive Users (No login in 30+ days)
SELECT 
    username,
    email,
    last_login,
    created_at,
    CASE 
        WHEN last_login IS NULL THEN 'Never logged in'
        ELSE EXTRACT(DAYS FROM NOW() - last_login)::text || ' days ago'
    END as last_activity
FROM users
WHERE last_login < NOW() - INTERVAL '30 days' 
   OR last_login IS NULL
ORDER BY last_login ASC NULLS FIRST;