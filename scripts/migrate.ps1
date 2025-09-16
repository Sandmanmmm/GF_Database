# GameForge Database Migration Manager
# PowerShell Script for managing database migrations

[CmdletBinding()]
param(
    [string]$Action = "status",  # status, migrate, rollback, create
    [string]$MigrationName = "",
    [string]$DatabaseUrl = "",
    [string]$ConfigFile = "../.env.database",
    [switch]$DryRun,
    [switch]$Force
)

# Load database configuration
function Get-DatabaseConfig {
    param([string]$ConfigPath)
    
    $config = @{}
    
    if (Test-Path $ConfigPath) {
        Get-Content $ConfigPath | ForEach-Object {
            if ($_ -match '^([^#=]+)=(.*)$') {
                $config[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }
    
    # Set defaults if not found in config
    if (-not $config.DB_HOST) { $config.DB_HOST = "localhost" }
    if (-not $config.DB_PORT) { $config.DB_PORT = "5432" }
    if (-not $config.DB_NAME) { $config.DB_NAME = "gameforge_dev" }
    if (-not $config.DB_USER) { $config.DB_USER = "gameforge_user" }
    if (-not $config.DB_PASSWORD) { $config.DB_PASSWORD = "securepassword" }
    
    return $config
}

# Execute SQL command
function Invoke-SqlCommand {
    param(
        [string]$Query,
        [hashtable]$Config,
        [switch]$ReturnResult
    )
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        if ($ReturnResult) {
            $result = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -t -c $Query 2>&1
        } else {
            $result = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -c $Query 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            return $result
        } else {
            throw "SQL command failed: $result"
        }
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Execute SQL file
function Invoke-SqlFile {
    param(
        [string]$FilePath,
        [hashtable]$Config
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "Migration file not found: $FilePath"
    }
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        $startTime = Get-Date
        $result = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -f $FilePath 2>&1
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Output = $result
                ExecutionTime = [int]$executionTime
            }
        } else {
            return @{
                Success = $false
                Output = $result
                ExecutionTime = [int]$executionTime
            }
        }
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Initialize migrations table
function Initialize-MigrationsTable {
    param([hashtable]$Config)
    
    $createTableSql = @"
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64),
    execution_time_ms INTEGER
);
"@
    
    try {
        Invoke-SqlCommand -Query $createTableSql -Config $Config
        Write-Host "Migrations table initialized" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to initialize migrations table: $_"
        return $false
    }
    
    return $true
}

# Get applied migrations
function Get-AppliedMigrations {
    param([hashtable]$Config)
    
    try {
        $result = Invoke-SqlCommand -Query "SELECT migration_name, applied_at FROM migrations ORDER BY applied_at;" -Config $Config -ReturnResult
        
        $migrations = @()
        if ($result) {
            $result | ForEach-Object {
                $line = $_.Trim()
                if ($line -and $line -ne "(0 rows)") {
                    $parts = $line -split '\|'
                    if ($parts.Length -ge 2) {
                        $migrations += @{
                            Name = $parts[0].Trim()
                            AppliedAt = $parts[1].Trim()
                        }
                    }
                }
            }
        }
        
        return $migrations
    }
    catch {
        Write-Warning "Could not retrieve applied migrations: $_"
        return @()
    }
}

# Get available migrations
function Get-AvailableMigrations {
    $migrationsPath = Join-Path $PSScriptRoot ".."
    $migrationFiles = Get-ChildItem -Path $migrationsPath -Filter "*.sql" | Sort-Object Name
    
    $migrations = @()
    foreach ($file in $migrationFiles) {
        $migrations += @{
            Name = $file.BaseName
            Path = $file.FullName
            Size = $file.Length
        }
    }
    
    return $migrations
}

# Show migration status
function Show-MigrationStatus {
    param([hashtable]$Config)
    
    Write-Host "=== GameForge Migration Status ===" -ForegroundColor Cyan
    Write-Host ""
    
    $applied = Get-AppliedMigrations -Config $Config
    $available = Get-AvailableMigrations
    
    Write-Host "Applied Migrations:" -ForegroundColor Green
    if ($applied.Count -eq 0) {
        Write-Host "  None" -ForegroundColor Yellow
    } else {
        foreach ($migration in $applied) {
            Write-Host "  ✓ $($migration.Name) (applied: $($migration.AppliedAt))" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "Available Migrations:" -ForegroundColor Blue
    if ($available.Count -eq 0) {
        Write-Host "  None" -ForegroundColor Yellow
    } else {
        foreach ($migration in $available) {
            $isApplied = $applied | Where-Object { $_.Name -eq $migration.Name }
            if ($isApplied) {
                Write-Host "  ✓ $($migration.Name)" -ForegroundColor Green
            } else {
                Write-Host "  ○ $($migration.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    
    # Count pending migrations
    $pending = $available | Where-Object { 
        $migrationName = $_.Name
        -not ($applied | Where-Object { $_.Name -eq $migrationName })
    }
    
    if ($pending.Count -gt 0) {
        Write-Host "$($pending.Count) pending migration(s)" -ForegroundColor Yellow
    } else {
        Write-Host "Database is up to date" -ForegroundColor Green
    }
}

# Apply pending migrations
function Invoke-Migrations {
    param(
        [hashtable]$Config,
        [switch]$DryRun
    )
    
    Write-Host "=== Applying Migrations ===" -ForegroundColor Cyan
    
    $applied = Get-AppliedMigrations -Config $Config
    $available = Get-AvailableMigrations
    
    # Find pending migrations
    $pending = $available | Where-Object { 
        $migrationName = $_.Name
        -not ($applied | Where-Object { $_.Name -eq $migrationName })
    }
    
    if ($pending.Count -eq 0) {
        Write-Host "No pending migrations" -ForegroundColor Green
        return $true
    }
    
    Write-Host "Found $($pending.Count) pending migration(s):" -ForegroundColor Yellow
    foreach ($migration in $pending) {
        Write-Host "  ○ $($migration.Name)" -ForegroundColor Yellow
    }
    
    if ($DryRun) {
        Write-Host "Dry run mode - no changes will be applied" -ForegroundColor Cyan
        return $true
    }
    
    # Apply each migration
    $success = $true
    foreach ($migration in $pending) {
        Write-Host ""
        Write-Host "Applying migration: $($migration.Name)" -ForegroundColor Blue
        
        try {
            $result = Invoke-SqlFile -FilePath $migration.Path -Config $Config
            
            if ($result.Success) {
                # Record migration in database
                $checksum = (Get-FileHash -Path $migration.Path -Algorithm MD5).Hash.ToLower()
                $recordSql = "INSERT INTO migrations (migration_name, checksum, execution_time_ms) VALUES ('$($migration.Name)', '$checksum', $($result.ExecutionTime));"
                
                Invoke-SqlCommand -Query $recordSql -Config $Config
                
                Write-Host "  ✓ Applied successfully ($($result.ExecutionTime)ms)" -ForegroundColor Green
            } else {
                Write-Error "  ✗ Migration failed: $($result.Output)"
                $success = $false
                break
            }
        }
        catch {
            Write-Error "  ✗ Migration failed: $_"
            $success = $false
            break
        }
    }
    
    if ($success) {
        Write-Host ""
        Write-Host "All migrations applied successfully!" -ForegroundColor Green
    }
    
    return $success
}

# Create new migration file
function New-Migration {
    param(
        [string]$Name
    )
    
    if (-not $Name) {
        Write-Error "Migration name is required"
        return $false
    }
    
    # Generate migration number
    $existing = Get-AvailableMigrations
    $nextNumber = ($existing.Count + 1).ToString("000")
    
    # Clean migration name
    $cleanName = $Name -replace '[^a-zA-Z0-9_]', '_'
    $fileName = "${nextNumber}_${cleanName}.sql"
    
    $migrationPath = Join-Path $PSScriptRoot ".." $fileName
    
    $template = @"
-- Migration: ${nextNumber}_${cleanName}
-- Description: ${Name}
-- Created: $(Get-Date -Format 'yyyy-MM-dd')
-- Author: GameForge Team

-- Add your migration SQL here
-- Remember to wrap in BEGIN/COMMIT for atomicity

BEGIN;

-- Example:
-- CREATE TABLE example (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- Record this migration
INSERT INTO migrations (migration_name, checksum) 
VALUES ('${nextNumber}_${cleanName}', md5('${nextNumber}_${cleanName}_v1'));

COMMIT;
"@
    
    try {
        $template | Out-File -FilePath $migrationPath -Encoding UTF8
        Write-Host "Created migration: $migrationPath" -ForegroundColor Green
        Write-Host "Edit the file to add your migration SQL" -ForegroundColor Cyan
        return $true
    }
    catch {
        Write-Error "Failed to create migration file: $_"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "GameForge Migration Manager" -ForegroundColor Green
    Write-Host ""
    
    # Load configuration
    $configPath = Join-Path $PSScriptRoot $ConfigFile
    $config = Get-DatabaseConfig -ConfigPath $configPath
    
    # Initialize migrations table
    if (-not (Initialize-MigrationsTable -Config $config)) {
        exit 1
    }
    
    switch ($Action.ToLower()) {
        "status" {
            Show-MigrationStatus -Config $config
        }
        "migrate" {
            if (-not (Invoke-Migrations -Config $config -DryRun:$DryRun)) {
                exit 1
            }
        }
        "create" {
            if (-not $MigrationName) {
                Write-Error "Migration name required for create action. Use -MigrationName parameter"
                exit 1
            }
            if (-not (New-Migration -Name $MigrationName)) {
                exit 1
            }
        }
        default {
            Write-Host "Available actions:" -ForegroundColor Yellow
            Write-Host "  status   - Show migration status" -ForegroundColor White
            Write-Host "  migrate  - Apply pending migrations" -ForegroundColor White
            Write-Host "  create   - Create new migration file" -ForegroundColor White
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\migrate.ps1 -Action status" -ForegroundColor Cyan
            Write-Host "  .\migrate.ps1 -Action migrate" -ForegroundColor Cyan
            Write-Host "  .\migrate.ps1 -Action migrate -DryRun" -ForegroundColor Cyan
            Write-Host "  .\migrate.ps1 -Action create -MigrationName 'add_user_preferences'" -ForegroundColor Cyan
        }
    }
}

# Run main function
Main