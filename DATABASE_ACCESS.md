# Database Management Tools

## pgAdmin 4 (Primary Tool)
- **Location**: `C:\Users\ya754\AppData\Local\Programs\pgAdmin 4\runtime\pgAdmin4.exe`
- **Connection Details**:
  - Host: `localhost`
  - Port: `5432`
  - Database: `gameforge_dev`
  - Username: `postgres`
  - Password: `postgres`

## Command Line Access
```powershell
# Connect to database via psql
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -h localhost -p 5432 -d gameforge_dev

# Quick commands:
# \dt          - List all tables
# \d tablename - Describe table structure
# \q           - Quit psql
```

## Alternative Web-based Tool (Adminer)
1. Download `adminer.php` from https://www.adminer.org/
2. Place it in the `tools/` directory
3. Run with PHP: `php -S localhost:8080 tools/adminer.php`
4. Open browser to `http://localhost:8080`

## Database Status
- ✅ PostgreSQL 16 running on port 5432
- ✅ gameforge_dev database with 22 tables
- ✅ Migration system active
- ✅ User permissions and advanced features ready