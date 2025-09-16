# GameForge Database Schema Synchronization System
# PowerShell-based migration and sync tools for dev/prod environments

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod", "staging")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("migrate", "sync", "dump-schema", "compare", "validate")]
    [string]$Action = "validate",
    
    [Parameter(Mandatory=$false)]
    [string]$MigrationFile = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Color output functions
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

# Load environment configuration
function Get-DatabaseConfig {
    param([string]$env)
    
    $configFile = switch ($env) {
        "dev" { ".env.database" }
        "prod" { ".env.production" }
        "staging" { ".env.staging" }
        default { ".env.database" }
    }
    
    if (-not (Test-Path $configFile)) {
        Write-Error "Configuration file $configFile not found!"
        return $null
    }
    
    $config = @{}
    Get-Content $configFile | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.*)$') {
            $config[$matches[1].Trim()] = $matches[2].Trim().Trim('"')
        }
    }
    
    return $config
}

# Test database connection
function Test-DatabaseConnection {
    param([hashtable]$config)
    
    $connectionString = "postgresql://$($config.DB_USER):$($config.DB_PASSWORD)@$($config.DB_HOST):$($config.DB_PORT)/$($config.DB_NAME)"
    
    try {
        $result = psql $connectionString -c "SELECT 1 as test;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        } else {
            Write-Error "Connection failed: $result"
            return $false
        }
    } catch {
        Write-Error "Connection error: $($_.Exception.Message)"
        return $false
    }
}

# Get current schema version
function Get-SchemaVersion {
    param([hashtable]$config)
    
    $connectionString = "postgresql://$($config.DB_USER):$($config.DB_PASSWORD)@$($config.DB_HOST):$($config.DB_PORT)/$($config.DB_NAME)"
    
    try {
        # Create migrations tracking table if it doesn't exist
        $createTable = @"
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64)
);
"@
        
        psql $connectionString -c $createTable | Out-Null
        
        # Get latest migration
        $query = "SELECT version, applied_at FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;"
        $result = psql $connectionString -t -c $query 2>/dev/null
        
        if ($result -and $result.Trim()) {
            return $result.Trim().Split('|')[0].Trim()
        } else {
            return "000_baseline"
        }
    } catch {
        Write-Warning "Could not determine schema version: $($_.Exception.Message)"
        return "unknown"
    }
}

# Dump clean schema (structure only)
function Export-CleanSchema {
    param(
        [hashtable]$config,
        [string]$outputFile
    )
    
    Write-Info "Exporting clean schema from $($config.DB_NAME)..."
    
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
        "--file=$outputFile"
    )
    
    $env:PGPASSWORD = $config.DB_PASSWORD
    
    try {
        & pg_dump @pgDumpArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Schema exported to: $outputFile"
            return $true
        } else {
            Write-Error "Failed to export schema"
            return $false
        }
    } finally {
        $env:PGPASSWORD = $null
    }
}

# Apply migration
function Invoke-Migration {
    param(
        [hashtable]$config,
        [string]$migrationFile,
        [bool]$dryRun = $false
    )
    
    if (-not (Test-Path $migrationFile)) {
        Write-Error "Migration file not found: $migrationFile"
        return $false
    }
    
    $migrationName = [System.IO.Path]::GetFileNameWithoutExtension($migrationFile)
    $connectionString = "postgresql://$($config.DB_USER):$($config.DB_PASSWORD)@$($config.DB_HOST):$($config.DB_PORT)/$($config.DB_NAME)"
    
    Write-Info "Applying migration: $migrationName"
    
    if ($dryRun) {
        Write-Warning "DRY RUN - Migration would be applied but not executed"
        Get-Content $migrationFile | Write-Host -ForegroundColor Gray
        return $true
    }
    
    try {
        # Check if migration already applied
        $checkQuery = "SELECT COUNT(*) FROM schema_migrations WHERE version = '$migrationName';"
        $existing = psql $connectionString -t -c $checkQuery 2>/dev/null
        
        if ($existing -and $existing.Trim() -gt 0) {
            Write-Warning "Migration $migrationName already applied"
            return $true
        }
        
        # Apply migration
        $result = psql $connectionString -f $migrationFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Record migration
            $recordQuery = "INSERT INTO schema_migrations (version, description) VALUES ('$migrationName', 'Applied via sync script');"
            psql $connectionString -c $recordQuery | Out-Null
            
            Write-Success "Migration $migrationName applied successfully"
            return $true
        } else {
            Write-Error "Migration failed: $result"
            return $false
        }
    } catch {
        Write-Error "Migration error: $($_.Exception.Message)"
        return $false
    }
}

# Compare schemas between environments
function Compare-Schemas {
    param(
        [hashtable]$devConfig,
        [hashtable]$prodConfig
    )
    
    Write-Info "Comparing schemas between dev and prod..."
    
    # Export schemas
    $devSchema = "temp_dev_schema.sql"
    $prodSchema = "temp_prod_schema.sql"
    
    try {
        if (-not (Export-CleanSchema $devConfig $devSchema)) {
            return $false
        }
        
        if (-not (Export-CleanSchema $prodConfig $prodSchema)) {
            return $false
        }
        
        # Compare files
        $devContent = Get-Content $devSchema | Where-Object { $_ -notmatch '^--' -and $_.Trim() -ne '' }
        $prodContent = Get-Content $prodSchema | Where-Object { $_ -notmatch '^--' -and $_.Trim() -ne '' }
        
        $differences = Compare-Object $devContent $prodContent
        
        if ($differences) {
            Write-Warning "Schema differences found:"
            $differences | ForEach-Object {
                $indicator = if ($_.SideIndicator -eq "<=") { "DEV ONLY" } else { "PROD ONLY" }
                Write-Host "[$indicator] $($_.InputObject)" -ForegroundColor Yellow
            }
            return $false
        } else {
            Write-Success "Schemas are identical!"
            return $true
        }
    } finally {
        # Cleanup
        Remove-Item $devSchema -ErrorAction SilentlyContinue
        Remove-Item $prodSchema -ErrorAction SilentlyContinue
    }
}

# Validate database structure
function Test-DatabaseStructure {
    param([hashtable]$config)
    
    Write-Info "Validating database structure for $($config.DB_NAME)..."
    
    $connectionString = "postgresql://$($config.DB_USER):$($config.DB_PASSWORD)@$($config.DB_HOST):$($config.DB_PORT)/$($config.DB_NAME)"
    
    # Check required tables
    $requiredTables = @(
        'users', 'projects', 'assets', 'game_templates', 'ai_requests',
        'ml_models', 'datasets', 'project_collaborators', 'user_preferences',
        'user_sessions', 'api_keys', 'audit_logs', 'system_config'
    )
    
    $tableQuery = @"
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
"@
    
    try {
        $existingTables = psql $connectionString -t -c $tableQuery | Where-Object { $_.Trim() }
        $existingTables = $existingTables | ForEach-Object { $_.Trim() }
        
        $missingTables = $requiredTables | Where-Object { $_ -notin $existingTables }
        $extraTables = $existingTables | Where-Object { $_ -notin $requiredTables }
        
        if ($missingTables) {
            Write-Error "Missing required tables: $($missingTables -join ', ')"
            return $false
        }
        
        if ($extraTables) {
            Write-Warning "Extra tables found: $($extraTables -join ', ')"
        }
        
        # Check required extensions
        $extensionQuery = "SELECT extname FROM pg_extension WHERE extname IN ('uuid-ossp', 'citext', 'pg_trgm');"
        $extensions = psql $connectionString -t -c $extensionQuery | Where-Object { $_.Trim() }
        
        $requiredExtensions = @('uuid-ossp', 'citext', 'pg_trgm')
        $missingExtensions = $requiredExtensions | Where-Object { $_.Trim() -notin ($extensions | ForEach-Object { $_.Trim() }) }
        
        if ($missingExtensions) {
            Write-Error "Missing required extensions: $($missingExtensions -join ', ')"
            return $false
        }
        
        Write-Success "Database structure validation passed!"
        return $true
    } catch {
        Write-Error "Validation error: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "=== GameForge Schema Synchronization Tool ===" -ForegroundColor Green
    Write-Host "Environment: $Environment | Action: $Action" -ForegroundColor Cyan
    Write-Host ""
    
    # Load configuration
    $config = Get-DatabaseConfig $Environment
    if (-not $config) {
        return 1
    }
    
    # Test connection
    Write-Info "Testing database connection..."
    if (-not (Test-DatabaseConnection $config)) {
        Write-Error "Cannot connect to database. Please check configuration."
        return 1
    }
    Write-Success "Database connection successful"
    
    switch ($Action) {
        "validate" {
            $result = Test-DatabaseStructure $config
            if ($result) { return 0 } else { return 1 }
        }
        
        "dump-schema" {
            $outputFile = "schema_export_$Environment`_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
            $result = Export-CleanSchema $config $outputFile
            if ($result) { return 0 } else { return 1 }
        }
        
        "migrate" {
            if (-not $MigrationFile) {
                Write-Error "Migration file required for migrate action"
                return 1
            }
            $result = Invoke-Migration $config $MigrationFile $DryRun
            if ($result) { return 0 } else { return 1 }
        }
        
        "compare" {
            if ($Environment -eq "prod") {
                Write-Error "Cannot compare prod to itself. Use -Environment dev for comparison."
                return 1
            }
            
            $prodConfig = Get-DatabaseConfig "prod"
            if (-not $prodConfig) {
                Write-Error "Production configuration not found"
                return 1
            }
            
            $result = Compare-Schemas $config $prodConfig
            if ($result) { return 0 } else { return 1 }
        }
        
        "sync" {
            Write-Info "Starting schema synchronization..."
            # This would implement full sync logic
            Write-Warning "Sync action not yet implemented. Use migrate for individual migrations."
            return 1
        }
        
        default {
            Write-Error "Unknown action: $Action"
            return 1
        }
    }
}

# Execute main function
exit (Main)