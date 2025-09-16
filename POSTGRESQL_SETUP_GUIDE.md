# GameForge PostgreSQL Setup Guide

## Current Situation
PostgreSQL 16 is installed and running on port 5433, but the postgres superuser doesn't have a password set.

## Solution Options

### Option 1: Use pgAdmin (Recommended - Easiest)

1. **Launch pgAdmin**:
   ```
   Start-Process "C:\Program Files\PostgreSQL\16\pgAdmin 4\runtime\pgAdmin4.exe"
   ```

2. **In pgAdmin**:
   - Click "Add New Server"
   - Name: "Local PostgreSQL"
   - Host: localhost
   - Port: 5433
   - Username: postgres
   - Password: (leave empty initially, then set one)

3. **Set postgres password**:
   - Right-click on "postgres" user
   - Select "Properties"
   - Go to "Definition" tab
   - Set password to: `postgres123`
   - Save

4. **Create GameForge database**:
   - Right-click "Databases"
   - Create -> Database
   - Name: `gameforge_dev`

5. **Create GameForge user**:
   - Right-click "Login/Group Roles"
   - Create -> Login/Group Role
   - Name: `gameforge_user`
   - Password: `securepassword`
   - Privileges: Can login
   - Grant privileges on gameforge_dev database

### Option 2: Command Line Setup (Advanced)

If you prefer command line, we need to temporarily modify authentication:

1. **Stop PostgreSQL service** (as Administrator):
   ```powershell
   Stop-Service postgresql-x64-16
   ```

2. **Edit pg_hba.conf** (as Administrator):
   - Open: `C:\Program Files\PostgreSQL\16\data\pg_hba.conf`
   - Change `scram-sha-256` to `trust` for local connections
   - Save file

3. **Start PostgreSQL service**:
   ```powershell
   Start-Service postgresql-x64-16
   ```

4. **Set passwords**:
   ```sql
   psql -U postgres -d postgres -p 5433
   ALTER USER postgres PASSWORD 'postgres123';
   CREATE DATABASE gameforge_dev;
   CREATE USER gameforge_user WITH PASSWORD 'securepassword';
   GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user;
   \q
   ```

5. **Restore pg_hba.conf security**:
   - Change `trust` back to `scram-sha-256`
   - Restart service

### Option 3: Use our PowerShell script (After setting postgres password)

Once postgres has a password set via Option 1 or 2:

```powershell
.\setup-database.ps1 -CreateDatabase -Setup -Test -Port 5433 -SuperUserPassword "postgres123"
```

## Recommended Next Steps

1. **Use Option 1 (pgAdmin)** - it's the safest and easiest
2. **Test connection**:
   ```powershell
   psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev
   ```
3. **Apply GameForge schema**:
   ```powershell
   psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev -f ..\schema.sql
   ```
4. **Load sample data**:
   ```powershell
   psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev -f ..\sample-data.sql
   ```

## Connection Details (After Setup)
- **Host**: localhost
- **Port**: 5433
- **Database**: gameforge_dev
- **Username**: gameforge_user
- **Password**: securepassword
- **Connection String**: `postgresql://gameforge_user:securepassword@localhost:5433/gameforge_dev`

## Troubleshooting

If you get "connection refused" errors:
- Check if PostgreSQL service is running: `Get-Service postgresql*`
- Verify port: `netstat -an | findstr :5433`
- Check PostgreSQL logs: `C:\Program Files\PostgreSQL\16\data\log\`