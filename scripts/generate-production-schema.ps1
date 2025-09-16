# Generate Production-Ready Schema
# This script creates a clean schema file suitable for production deployment

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "schema_production_ready.sql",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeData = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExcludeTestData = $true
)

# Color output functions
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

Write-Host "=== GameForge Production Schema Generator ===" -ForegroundColor Green
Write-Host ""

# Load dev database configuration
if (-not (Test-Path ".env.database")) {
    Write-Error ".env.database not found! Please ensure development database is configured."
    exit 1
}

$config = @{}
Get-Content ".env.database" | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') {
        $config[$matches[1].Trim()] = $matches[2].Trim().Trim('"')
    }
}

Write-Info "Connecting to development database: $($config.DB_NAME)"

# Test connection
try {
    $testResult = psql -U $config.DB_USER -h $config.DB_HOST -p $config.DB_PORT -d $config.DB_NAME -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot connect to development database: $testResult"
        exit 1
    }
    Write-Success "Database connection successful"
} catch {
    Write-Error "Connection failed: $($_.Exception.Message)"
    exit 1
}

# Generate schema dump
Write-Info "Generating production schema..."

$pgDumpArgs = @(
    "--host=$($config.DB_HOST)",
    "--port=$($config.DB_PORT)", 
    "--username=$($config.DB_USER)",
    "--dbname=$($config.DB_NAME)",
    "--schema-only",
    "--no-owner",
    "--no-privileges",
    "--clean",
    "--if-exists",
    "--file=$OutputFile"
)

$env:PGPASSWORD = $config.DB_PASSWORD

try {
    & pg_dump @pgDumpArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Schema exported to: $OutputFile"
    } else {
        Write-Error "Failed to export schema"
        exit 1
    }
} finally {
    $env:PGPASSWORD = $null
}

# Post-process the schema file for production
Write-Info "Post-processing schema for production..."

$schemaContent = Get-Content $OutputFile
$productionSchema = @()

# Add production-specific header
$productionSchema += @"
-- GameForge Production Database Schema
-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Source: Development Database ($($config.DB_NAME))
-- 
-- This schema is production-ready and excludes:
-- - Development-specific data
-- - Test users and sample data
-- - Debug configurations
--
-- Required PostgreSQL version: 16+
-- Required extensions: uuid-ossp, citext, pg_trgm

-- Ensure we're in the correct database
\c gameforge_prod

"@

# Process each line
$skipSampleData = $false
foreach ($line in $schemaContent) {
    # Skip comments about pg_dump version, etc.
    if ($line -match "^-- Dumped from database version" -or 
        $line -match "^-- Dumped by pg_dump version" -or
        $line -match "^-- Started on" -or
        $line -match "^-- Completed on") {
        continue
    }
    
    # Skip sample data inserts if requested
    if ($ExcludeTestData -and $line -match "INSERT INTO.*VALUES.*sample|test|demo") {
        continue
    }
    
    # Replace development-specific configurations
    if ($line -match "gameforge_dev") {
        $line = $line -replace "gameforge_dev", "gameforge_prod"
    }
    
    # Update system configuration for production
    if ($line -match "INSERT INTO system_config.*maintenance_mode.*false") {
        $line = $line -replace "false", "false"
    }
    
    if ($line -match "INSERT INTO system_config.*debug_mode.*true") {
        $line = $line -replace "true", "false"
    }
    
    $productionSchema += $line
}

# Add production-specific data
$productionSchema += @"

-- Production-specific system configuration
UPDATE system_config SET value = 'false' WHERE key = 'maintenance_mode';
UPDATE system_config SET value = 'false' WHERE key = 'debug_mode';
UPDATE system_config SET value = '"production"' WHERE key = 'environment';
UPDATE system_config SET value = '50' WHERE key = 'max_projects_per_user';

-- Create production admin user (requires manual password setup)
-- This is commented out for security - create admin users manually
-- INSERT INTO users (id, email, username, role, is_active, email_verified, provider)
-- VALUES (
--     uuid_generate_v4(),
--     'admin@gameforge.com',
--     'admin',
--     'super_admin',
--     true,
--     true,
--     'email'
-- );

SELECT 'Production schema installation complete!' as status;
SELECT 'Remember to:' as reminder;
SELECT '1. Create admin users manually' as step_1;
SELECT '2. Configure SSL certificates' as step_2;
SELECT '3. Set up backup schedules' as step_3;
SELECT '4. Configure monitoring' as step_4;
"@

# Write the production schema
$productionSchema | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Success "Production schema created: $OutputFile"
Write-Info "Schema size: $((Get-Item $OutputFile).Length) bytes"

# Validate the schema
Write-Info "Validating generated schema..."

$tableCount = ($schemaContent | Where-Object { $_ -match "^CREATE TABLE" }).Count
$indexCount = ($schemaContent | Where-Object { $_ -match "^CREATE.*INDEX" }).Count
$typeCount = ($schemaContent | Where-Object { $_ -match "^CREATE TYPE" }).Count
$extensionCount = ($schemaContent | Where-Object { $_ -match "^CREATE EXTENSION" }).Count

Write-Host ""
Write-Host "=== Schema Validation ===" -ForegroundColor Cyan
Write-Host "Tables: $tableCount" -ForegroundColor White
Write-Host "Indexes: $indexCount" -ForegroundColor White
Write-Host "Custom Types: $typeCount" -ForegroundColor White
Write-Host "Extensions: $extensionCount" -ForegroundColor White
Write-Host ""

if ($tableCount -ge 13 -and $extensionCount -ge 3) {
    Write-Success "Schema validation passed!"
    Write-Host ""
    Write-Host "=== Next Steps ===" -ForegroundColor Yellow
    Write-Host "1. Copy $OutputFile to your production server" -ForegroundColor White
    Write-Host "2. Create production database: CREATE DATABASE gameforge_prod;" -ForegroundColor White
    Write-Host "3. Apply schema: psql -U postgres -d gameforge_prod -f $OutputFile" -ForegroundColor White
    Write-Host "4. Create production users and set passwords" -ForegroundColor White
    Write-Host "5. Configure SSL and security settings" -ForegroundColor White
    Write-Host ""
} else {
    Write-Error "Schema validation failed! Expected at least 13 tables and 3 extensions."
    exit 1
}

Write-Success "Production schema generation complete!"