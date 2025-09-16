@echo off
echo Setting up GameForge PostgreSQL Database...
echo.

REM Set PostgreSQL environment
set PGPORT=5433
set PGHOST=localhost

echo Attempting to set postgres user password...
echo This requires the postgres user to already have a password set during installation.
echo.

REM Try to connect and set up database
echo Creating temporary SQL file...
echo ALTER USER postgres PASSWORD 'postgres123'; > setup.sql
echo CREATE DATABASE gameforge_dev; >> setup.sql
echo CREATE USER gameforge_user WITH PASSWORD 'securepassword'; >> setup.sql
echo GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user; >> setup.sql
echo SELECT 'Database setup completed successfully!' as status; >> setup.sql

echo.
echo Please enter the postgres user password when prompted...
echo (If no password was set during installation, this will fail)
echo.

psql -U postgres -d postgres -f setup.sql

if %ERRORLEVEL% == 0 (
    echo.
    echo SUCCESS: GameForge database has been set up!
    echo.
    echo Connection details:
    echo Host: localhost
    echo Port: 5433
    echo Database: gameforge_dev
    echo Username: gameforge_user
    echo Password: securepassword
    echo.
    echo Test connection:
    echo psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev
) else (
    echo.
    echo FAILED: Could not set up database.
    echo.
    echo This usually means:
    echo 1. No password was set for postgres user during installation
    echo 2. You need to run PostgreSQL's initdb or use pgAdmin to set password
    echo.
    echo Alternative: Use pgAdmin or PostgreSQL installer to set postgres password first
)

echo.
del setup.sql 2>nul
pause