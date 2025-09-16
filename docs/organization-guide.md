# pgAdmin 4 Database Organization Guide for GameForge

## 🎯 Goal
Organize GameForge database access in pgAdmin with logical folder structure and visual schema documentation.

## 📁 Recommended Folder Organization in pgAdmin

### 1. Users & Roles Management
**Purpose**: Manage user accounts, authentication, and permissions

**Tables to Monitor**:
- `users` - Core user accounts with OAuth support
- `user_preferences` - User settings and customization
- `user_sessions` - Active login sessions and JWT tokens
- `api_keys` - User API authentication keys

**Key Queries for Users & Roles**:
```sql
-- User Overview
SELECT 
    username, 
    email, 
    provider, 
    role, 
    is_active, 
    created_at 
FROM users 
ORDER BY created_at DESC;

-- OAuth Provider Distribution
SELECT 
    provider,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM users 
GROUP BY provider
ORDER BY user_count DESC;

-- Active Sessions
SELECT 
    u.username,
    s.session_token,
    s.expires_at,
    s.created_at
FROM user_sessions s
JOIN users u ON s.user_id = u.id
WHERE s.expires_at > NOW()
ORDER BY s.created_at DESC;
```

### 2. Projects Management
**Purpose**: Track game development projects and collaboration

**Tables to Monitor**:
- `projects` - Game development projects
- `project_collaborators` - Team collaboration
- `game_templates` - Template marketplace
- `project_stats` - Project analytics (view)

**Key Queries for Projects**:
```sql
-- Project Overview
SELECT 
    p.name,
    p.description,
    u.username as owner,
    p.visibility,
    p.created_at,
    COUNT(pc.user_id) as collaborator_count
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN project_collaborators pc ON p.id = pc.project_id
GROUP BY p.id, p.name, p.description, u.username, p.visibility, p.created_at
ORDER BY p.created_at DESC;

-- Template Marketplace
SELECT 
    name,
    template_type,
    engine,
    price,
    rating,
    downloads,
    creator_username,
    created_at
FROM game_templates
ORDER BY downloads DESC, rating DESC;

-- Collaboration Activity
SELECT 
    p.name as project_name,
    u.username as collaborator,
    pc.role,
    pc.joined_at
FROM project_collaborators pc
JOIN projects p ON pc.project_id = p.id
JOIN users u ON pc.user_id = u.id
ORDER BY pc.joined_at DESC;
```

### 3. Assets Management
**Purpose**: Track game assets, uploads, and versioning

**Tables to Monitor**:
- `assets` - Game assets with metadata
- `datasets` - AI/ML training datasets
- `ml_models` - Trained AI models

**Key Queries for Assets**:
```sql
-- Asset Overview
SELECT 
    name,
    asset_type,
    file_size,
    version,
    u.username as uploaded_by,
    created_at
FROM assets a
JOIN users u ON a.uploaded_by = u.id
ORDER BY created_at DESC;

-- Asset Type Distribution
SELECT 
    asset_type,
    COUNT(*) as asset_count,
    SUM(file_size) as total_size_bytes,
    pg_size_pretty(SUM(file_size)) as total_size_formatted
FROM assets
GROUP BY asset_type
ORDER BY asset_count DESC;

-- Version History
SELECT 
    name,
    version,
    file_size,
    created_at,
    metadata
FROM assets
WHERE name = 'your_asset_name'
ORDER BY version DESC;
```

### 4. AI Logs & Monitoring
**Purpose**: Audit system activity and AI/ML operations

**Tables to Monitor**:
- `audit_logs` - System activity tracking
- `ai_requests` - AI assistance requests
- `system_config` - Application configuration

**Key Queries for AI Logs**:
```sql
-- Recent Activity Audit
SELECT 
    al.action,
    al.table_name,
    u.username,
    al.timestamp,
    al.changes
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
ORDER BY al.timestamp DESC
LIMIT 50;

-- AI Request Analytics
SELECT 
    request_type,
    COUNT(*) as request_count,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_duration_seconds,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_requests
FROM ai_requests
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY request_type
ORDER BY request_count DESC;

-- System Configuration
SELECT 
    key,
    value,
    description,
    is_public,
    updated_at
FROM system_config
ORDER BY key;
```

## 🎨 Creating the Database Organization in pgAdmin

### Step 1: Create Custom Folders (Bookmarks)
1. **Right-click on "GameForge Dev DB"** in pgAdmin
2. **Select "Properties"**
3. **Go to "Advanced" tab**
4. **Add custom categories** in comments field

### Step 2: Organize Queries by Category
1. **Open Query Tool** (Tools → Query Tool)
2. **Create new files** for each category:
   - `users-and-roles-queries.sql`
   - `projects-queries.sql`
   - `assets-queries.sql`
   - `ai-logs-queries.sql`

### Step 3: Create Bookmarks for Frequent Queries
1. **Run a query** in Query Tool
2. **Click "Save"** button
3. **Name the bookmark** (e.g., "User Overview", "Active Projects")
4. **Organize in folders** by prepending category names

## 📊 Schema Visualization Setup

### ERD Tool Instructions:
1. **Right-click on "gameforge_dev" database**
2. **Select "Generate ERD"**
3. **Include all tables** (15 tables)
4. **Arrange layout** logically:
   - **Users cluster**: users, user_preferences, user_sessions, api_keys
   - **Projects cluster**: projects, project_collaborators, game_templates
   - **Assets cluster**: assets, datasets, ml_models
   - **System cluster**: audit_logs, system_config, ai_requests

### Export Options:
- **Format**: PNG (for documentation)
- **Resolution**: High (300 DPI)
- **Size**: Large (for readability)
- **Include**: Table names, column names, data types, relationships

## 🔍 Essential Test Queries

### Database Health Check:
```sql
-- Overall database status
SELECT 
    'Total Tables' as metric, COUNT(*) as value
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 
    'Total Users', COUNT(*)::text
FROM users
UNION ALL
SELECT 
    'Total Projects', COUNT(*)::text
FROM projects
UNION ALL
SELECT 
    'Total Assets', COUNT(*)::text
FROM assets;
```

### Performance Monitoring:
```sql
-- Table sizes and activity
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Relationship Verification:
```sql
-- Foreign key relationships
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```

## 📁 File Organization Structure

```
GameForge/
├── database/
│   ├── docs/
│   │   ├── schema-diagram.png          # ERD export
│   │   ├── organization-guide.md       # This file
│   │   └── query-reference.md          # Query library
│   ├── queries/
│   │   ├── users-and-roles/
│   │   │   ├── user-overview.sql
│   │   │   ├── oauth-analytics.sql
│   │   │   └── session-management.sql
│   │   ├── projects/
│   │   │   ├── project-overview.sql
│   │   │   ├── collaboration.sql
│   │   │   └── template-marketplace.sql
│   │   ├── assets/
│   │   │   ├── asset-management.sql
│   │   │   ├── version-tracking.sql
│   │   │   └── storage-analytics.sql
│   │   └── monitoring/
│   │       ├── audit-logs.sql
│   │       ├── ai-requests.sql
│   │       └── performance.sql
│   └── scripts/
│       └── organization-setup.sql
```