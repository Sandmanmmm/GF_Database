# pgAdmin 4 Setup Guide for GameForge Database

## 🎯 Goal
Configure pgAdmin 4 as the official GameForge database administration tool for development.

## ✅ Step 1: Installation Complete
pgAdmin 4 v9.8 has been successfully installed and should be launching now.

## 🔗 Step 2: Connect to GameForge Database

### Manual Connection Steps:

1. **Open pgAdmin 4** (should be launching now)
   - If not open, use: Start Menu → pgAdmin 4

2. **Add New Server Connection**
   - Right-click "Servers" in the left panel
   - Select "Create" → "Server..."

3. **Configure Connection - General Tab:**
   ```
   Name: GameForge Dev DB
   Server Group: (leave as Servers)
   Comments: GameForge development database with ML platform schema
   ```

4. **Configure Connection - Connection Tab:**
   ```
   Host name/address: localhost
   Port: 5433
   Maintenance database: gameforge_dev
   Username: gameforge_user
   Password: securepassword
   Save password?: ✓ (check this box)
   ```

5. **Advanced Settings (Optional):**
   - SSL mode: Prefer
   - Connection timeout: 10 seconds

6. **Click "Save"** to create the connection

### Connection Details Summary:
```
Server Name: GameForge Dev DB
Host: localhost
Port: 5433
Database: gameforge_dev
Username: gameforge_user
Password: securepassword
```

## 🗄️ Database Schema Overview
Once connected, you'll see these 15 tables:

### Core Tables:
- **users** - User accounts with OAuth support (GitHub/Google)
- **user_preferences** - User settings and preferences
- **user_sessions** - Active user sessions and JWT tokens
- **api_keys** - API authentication keys

### Game Development:
- **game_templates** - Marketplace of game templates
- **projects** - User game development projects
- **project_collaborators** - Team collaboration
- **assets** - Game assets with versioning

### AI/ML Features:
- **ai_requests** - AI assistance request tracking
- **ml_models** - Machine learning models
- **datasets** - Training data management

### System:
- **audit_logs** - All system activity tracking
- **system_config** - Application configuration
- **project_stats** - Project analytics (view)
- **user_stats** - User analytics (view)

## 🧪 Step 3: Verification Queries

Once connected, try these queries in pgAdmin's Query Tool:

### 1. Check Database Structure:
```sql
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, ordinal_position;
```

### 2. Verify Sample Data:
```sql
SELECT 
    'users' as table_name, COUNT(*) as record_count 
FROM users
UNION ALL
SELECT 'game_templates', COUNT(*) FROM game_templates
UNION ALL  
SELECT 'projects', COUNT(*) FROM projects;
```

### 3. Test OAuth Features:
```sql
SELECT 
    username,
    provider,
    github_username,
    created_at
FROM users 
WHERE provider IS NOT NULL;
```

### 4. Check Indexes and Performance:
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

## 🔧 Troubleshooting

### If Connection Fails:
1. **Check PostgreSQL Service:**
   ```powershell
   Get-Service -Name "postgresql*"
   ```

2. **Test Direct Connection:**
   ```powershell
   $env:PGPASSWORD = "securepassword"
   psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev -c "SELECT version();"
   ```

3. **Verify Port:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 5433
   ```

### Common Issues:
- **Password Authentication Failed**: Ensure password is "securepassword"
- **Connection Refused**: Check PostgreSQL is running on port 5433
- **Database Not Found**: Verify gameforge_dev database exists

## 🎯 Next Steps After Connection:
1. **Explore Schema**: Browse all 15 tables and their relationships
2. **Test Queries**: Run sample queries to verify functionality  
3. **Create Bookmarks**: Save frequently used queries
4. **Set Up Monitoring**: Configure pgAdmin for database monitoring

## 📝 Development Workflow:
- Use pgAdmin for visual database exploration
- Test complex queries before implementing in code
- Monitor database performance and queries
- Manage database users and permissions
- Backup and restore operations

---
**Connection String for Applications:**
```
postgresql://gameforge_user:securepassword@localhost:5433/gameforge_dev
```