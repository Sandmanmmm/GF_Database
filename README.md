# GameForge Database Setup Guide

This guide covers the complete setup and management of the PostgreSQL database for the GameForge ML platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Manual Installation](#manual-installation)
4. [Database Schema](#database-schema)
5. [Configuration](#configuration)
6. [Migrations](#migrations)
7. [Backup & Restore](#backup--restore)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

- **PostgreSQL 16+**: Latest stable version recommended
- **PowerShell 5.1+**: For Windows automation scripts
- **Windows 10/11**: Development environment
- **8GB RAM**: Minimum for development
- **10GB free space**: For database and backups

## Quick Start

### 1. Automated Setup (Recommended)

Run the automated setup script to install PostgreSQL, create the database, and apply the schema:

```powershell
# Navigate to the database scripts directory
cd database/scripts

# Run complete setup (install + configure + test)
.\setup-database.ps1 -All
```

This will:
- Install PostgreSQL 16 via winget/chocolatey
- Create `gameforge_dev` database
- Create `gameforge_user` with appropriate permissions
- Apply the complete schema
- Create sample data for development
- Generate configuration files

### 2. Manual Setup Steps

If you prefer manual setup or the automated script fails:

#### Install PostgreSQL

1. Download PostgreSQL 16 from [postgresql.org](https://www.postgresql.org/download/windows/)
2. Run installer with these settings:
   - Port: `5432` (default)
   - Superuser: `postgres`
   - Remember the superuser password
3. Add PostgreSQL bin to your PATH

#### Create Database and User

```powershell
# Connect to PostgreSQL as superuser
psql -U postgres -h localhost

# In psql prompt:
CREATE DATABASE gameforge_dev;
CREATE USER gameforge_user WITH PASSWORD 'securepassword';
GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user;
\q
```

#### Apply Schema

```powershell
# Apply the schema
psql -U gameforge_user -h localhost -d gameforge_dev -f database/schema.sql

# Apply sample data (optional)
psql -U gameforge_user -h localhost -d gameforge_dev -f database/sample-data.sql
```

## Database Schema

### Core Tables

The GameForge database includes the following core tables:

#### Users (`users`)
- User account management
- Role-based access control (basic_user, premium_user, admin, super_admin)
- Authentication and security features
- API quota tracking

#### Projects (`projects`) 
- Game development projects
- Collaboration and team management
- Project metadata and settings

#### Assets (`assets`)
- File storage tracking (models, datasets, textures, etc.)
- Version control and metadata
- Access control and download tracking

#### AI Requests (`ai_requests`)
- Track AI service usage
- Request status and cost tracking
- Performance monitoring

#### ML Models (`ml_models`)
- Model registry and versioning
- Training metadata and metrics
- Deployment tracking

#### Datasets (`datasets`)
- Dataset versioning and lineage
- Quality metrics and validation
- Data drift detection

#### Audit Logs (`audit_logs`)
- Security and compliance tracking
- User action logging
- System audit trail

### Advanced Features

- **UUID Primary Keys**: For distributed systems
- **Full-text Search**: On projects and assets
- **Automated Timestamps**: Created/updated tracking
- **Enum Types**: For consistent status values
- **JSON Columns**: For flexible metadata storage
- **Performance Indexes**: Optimized for common queries

## Configuration

### Environment Variables

Copy the template and customize:

```powershell
cp database/.env.template database/.env.database
```

Key configuration options:

```bash
# Database Connection
DATABASE_URL=postgresql://gameforge_user:securepassword@localhost:5432/gameforge_dev
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gameforge_dev
DB_USER=gameforge_user
DB_PASSWORD=securepassword

# Connection Pool Settings
DB_POOL_SIZE=20
DB_POOL_TIMEOUT=30

# Security
DB_SSL_MODE=prefer
DB_AUDIT_ENABLED=true
```

### Connection Testing

Test your database connection:

```powershell
# Test connection
psql -U gameforge_user -h localhost -d gameforge_dev -c "SELECT version();"

# Test with script
.\database\scripts\setup-database.ps1 -Test
```

## Migrations

### Migration Management

Use the migration script to manage schema changes:

```powershell
cd database/scripts

# Check migration status
.\migrate.ps1 -Action status

# Apply pending migrations
.\migrate.ps1 -Action migrate

# Create new migration
.\migrate.ps1 -Action create -MigrationName "add_user_preferences"

# Dry run (preview changes)
.\migrate.ps1 -Action migrate -DryRun
```

### Creating Migrations

1. Create new migration file:
   ```powershell
   .\migrate.ps1 -Action create -MigrationName "add_feature_x"
   ```

2. Edit the generated file in `database/migrations/`

3. Apply the migration:
   ```powershell
   .\migrate.ps1 -Action migrate
   ```

### Migration Best Practices

- **Atomic Operations**: Wrap in BEGIN/COMMIT
- **Rollback Plan**: Consider reverse migrations
- **Test First**: Use `-DryRun` flag
- **Backup**: Create backup before major changes
- **Index Creation**: Use `CONCURRENTLY` for large tables

## Backup & Restore

### Automated Backups

```powershell
cd database/scripts

# Create backup
.\backup.ps1 -Action backup

# Create backup with custom path
.\backup.ps1 -Action backup -BackupPath "C:\backups\gameforge_$(Get-Date -Format 'yyyyMMdd').sql"

# Create backup and clean old files
.\backup.ps1 -Action backup -CleanOld -RetentionDays 30
```

### Restore Database

```powershell
# Restore from backup (WARNING: This overwrites existing data)
.\backup.ps1 -Action restore -RestoreFile "path\to\backup.sql"
```

### Manual Backup/Restore

```powershell
# Manual backup
pg_dump -U gameforge_user -h localhost -d gameforge_dev -f backup.sql

# Manual restore
psql -U gameforge_user -h localhost -d gameforge_dev -f backup.sql
```

## Monitoring

### Database Health

Monitor database performance and health:

```powershell
# Database health check
.\backup.ps1 -Action monitor

# Maintenance tasks
.\backup.ps1 -Action maintain
```

### Key Metrics to Monitor

- **Database Size**: Growth over time
- **Active Connections**: Connection pool usage
- **Query Performance**: Slow query identification
- **Table Statistics**: Insert/update/delete rates
- **Index Usage**: Index efficiency

### Performance Queries

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('gameforge_dev'));

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_stat_user_tables 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## Troubleshooting

### Common Issues

#### Connection Refused
```
Error: could not connect to server: Connection refused
```

**Solutions:**
1. Check if PostgreSQL service is running
2. Verify port 5432 is not blocked
3. Check connection parameters

#### Authentication Failed
```
Error: password authentication failed for user "gameforge_user"
```

**Solutions:**
1. Verify username and password
2. Check `pg_hba.conf` configuration
3. Ensure user exists with correct permissions

#### Database Does Not Exist
```
Error: database "gameforge_dev" does not exist
```

**Solutions:**
1. Create database: `CREATE DATABASE gameforge_dev;`
2. Run setup script: `.\setup-database.ps1 -CreateDatabase`

#### Permission Denied
```
Error: permission denied for table users
```

**Solutions:**
1. Grant permissions: `GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user;`
2. Check role membership
3. Verify table ownership

### Diagnostic Commands

```powershell
# Check PostgreSQL service status
Get-Service postgresql*

# Test basic connectivity
psql -U postgres -h localhost -c "SELECT version();"

# Check database users
psql -U postgres -h localhost -c "\du"

# Check databases
psql -U postgres -h localhost -c "\l"

# Check table permissions
psql -U gameforge_user -h localhost -d gameforge_dev -c "\dp"
```

### Log Analysis

PostgreSQL logs are typically located at:
- Windows: `C:\Program Files\PostgreSQL\16\data\log\`
- Check for error messages and connection issues

## Development Workflows

### Daily Development

1. **Start Development Session**:
   ```powershell
   # Quick health check
   .\backup.ps1 -Action monitor
   ```

2. **Schema Changes**:
   ```powershell
   # Create migration for schema changes
   .\migrate.ps1 -Action create -MigrationName "your_change"
   # Edit migration file
   # Apply migration
   .\migrate.ps1 -Action migrate
   ```

3. **Data Refresh**:
   ```powershell
   # Reset to sample data
   psql -U gameforge_user -h localhost -d gameforge_dev -f database/sample-data.sql
   ```

### Testing

1. **Create Test Database**:
   ```sql
   CREATE DATABASE gameforge_test;
   GRANT ALL PRIVILEGES ON DATABASE gameforge_test TO gameforge_user;
   ```

2. **Apply Schema to Test DB**:
   ```powershell
   psql -U gameforge_user -h localhost -d gameforge_test -f database/schema.sql
   ```

3. **Run Tests**:
   ```powershell
   # Set test database in environment
   $env:DB_NAME = "gameforge_test"
   # Run your tests
   ```

## Security Considerations

### Production Checklist

- [ ] Change default passwords
- [ ] Use SSL connections (`DB_SSL_MODE=require`)
- [ ] Restrict network access
- [ ] Enable audit logging
- [ ] Regular security updates
- [ ] Backup encryption
- [ ] Monitor access logs

### Security Configuration

```sql
-- Enable row-level security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create security policies
CREATE POLICY user_policy ON users 
FOR ALL TO gameforge_user 
USING (id = current_setting('app.current_user_id')::UUID);
```

## Integration

### Application Connection

**Python (SQLAlchemy)**:
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://gameforge_user:securepassword@localhost:5432/gameforge_dev"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

**Node.js (pg)**:
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  user: 'gameforge_user',
  host: 'localhost',
  database: 'gameforge_dev',
  password: 'securepassword',
  port: 5432,
});
```

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [GameForge API Documentation](../DATASET_VERSIONING_API_GUIDE.md)
- [MLflow Integration Guide](../ml-platform/registry/)
- [Security Policies](../security/README.md)

---

For support or questions, please refer to the [main project documentation](../README.md) or create an issue in the project repository.