# GameForge Database Backup and Restore Script
# PowerShell script for database backup, restore, and maintenance

[CmdletBinding()]
param(
    [string]$Action = "backup",  # backup, restore, maintain, monitor
    [string]$BackupPath = "",
    [string]$RestoreFile = "",
    [string]$ConfigFile = ".env.database",
    [switch]$Compress,
    [switch]$CleanOld,
    [int]$RetentionDays = 30
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
    
    return $config
}

# Create database backup
function New-DatabaseBackup {
    param(
        [hashtable]$Config,
        [string]$OutputPath,
        [switch]$Compress
    )
    
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "gameforge_backup_$timestamp.sql"
        $OutputPath = Join-Path (Get-Location) $fileName
    }
    
    Write-Host "Creating database backup..." -ForegroundColor Cyan
    Write-Host "Output: $OutputPath" -ForegroundColor White
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        $pgDumpArgs = @(
            "-U", $Config.DB_USER
            "-h", $Config.DB_HOST
            "-p", $Config.DB_PORT
            "-d", $Config.DB_NAME
            "--verbose"
            "--no-password"
            "--format=custom"
            "--compress=9"
            "--file=$OutputPath"
        )
        
        $startTime = Get-Date
        & pg_dump @pgDumpArgs
        $endTime = Get-Date
        
        if ($LASTEXITCODE -eq 0) {
            $duration = ($endTime - $startTime).TotalSeconds
            $fileSize = (Get-Item $OutputPath).Length / 1MB
            
            Write-Host "Backup completed successfully!" -ForegroundColor Green
            Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
            Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
            
            return $OutputPath
        } else {
            Write-Error "Backup failed with exit code: $LASTEXITCODE"
            return $null
        }
    }
    catch {
        Write-Error "Backup failed: $_"
        return $null
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Restore database from backup
function Restore-Database {
    param(
        [hashtable]$Config,
        [string]$BackupFile
    )
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        return $false
    }
    
    Write-Host "Restoring database from backup..." -ForegroundColor Cyan
    Write-Host "Backup file: $BackupFile" -ForegroundColor White
    
    # Warning about data loss
    Write-Warning "This will OVERWRITE the existing database!"
    $confirm = Read-Host "Type 'YES' to continue"
    
    if ($confirm -ne "YES") {
        Write-Host "Restore cancelled" -ForegroundColor Yellow
        return $false
    }
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        # Drop and recreate database
        Write-Host "Dropping existing database..." -ForegroundColor Yellow
        
        $env:PGPASSWORD = $Config.DB_PASSWORD
        $dropResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d postgres -c "DROP DATABASE IF EXISTS $($Config.DB_NAME);" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to drop database: $dropResult"
            return $false
        }
        
        Write-Host "Creating new database..." -ForegroundColor Yellow
        $createResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d postgres -c "CREATE DATABASE $($Config.DB_NAME);" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create database: $createResult"
            return $false
        }
        
        # Restore from backup
        Write-Host "Restoring data..." -ForegroundColor Yellow
        
        $pgRestoreArgs = @(
            "-U", $Config.DB_USER
            "-h", $Config.DB_HOST
            "-p", $Config.DB_PORT
            "-d", $Config.DB_NAME
            "--verbose"
            "--no-password"
            "--clean"
            "--if-exists"
            $BackupFile
        )
        
        $startTime = Get-Date
        & pg_restore @pgRestoreArgs
        $endTime = Get-Date
        
        if ($LASTEXITCODE -eq 0) {
            $duration = ($endTime - $startTime).TotalSeconds
            Write-Host "Restore completed successfully!" -ForegroundColor Green
            Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
            return $true
        } else {
            Write-Error "Restore failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Restore failed: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Database maintenance tasks
function Invoke-DatabaseMaintenance {
    param([hashtable]$Config)
    
    Write-Host "=== Database Maintenance ===" -ForegroundColor Cyan
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        # Analyze database
        Write-Host "Analyzing database..." -ForegroundColor Yellow
        $analyzeResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -c "ANALYZE;" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database analysis completed" -ForegroundColor Green
        } else {
            Write-Warning "Database analysis failed: $analyzeResult"
        }
        
        # Vacuum database
        Write-Host "Vacuuming database..." -ForegroundColor Yellow
        $vacuumResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -c "VACUUM;" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database vacuum completed" -ForegroundColor Green
        } else {
            Write-Warning "Database vacuum failed: $vacuumResult"
        }
        
        # Update statistics
        Write-Host "Updating statistics..." -ForegroundColor Yellow
        $statsResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -c "UPDATE pg_stat_user_tables SET n_tup_ins = 0, n_tup_upd = 0, n_tup_del = 0;" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Statistics updated" -ForegroundColor Green
        } else {
            Write-Warning "Statistics update failed: $statsResult"
        }
        
        Write-Host "Maintenance completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Maintenance failed: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Monitor database health
function Get-DatabaseHealth {
    param([hashtable]$Config)
    
    Write-Host "=== Database Health Monitor ===" -ForegroundColor Cyan
    
    $env:PGPASSWORD = $Config.DB_PASSWORD
    
    try {
        # Database size
        $sizeQuery = "SELECT pg_size_pretty(pg_database_size('$($Config.DB_NAME)')) as database_size;"
        $sizeResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -t -c $sizeQuery 2>&1
        
        # Connection count
        $connQuery = "SELECT count(*) as active_connections FROM pg_stat_activity WHERE datname = '$($Config.DB_NAME)';"
        $connResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -t -c $connQuery 2>&1
        
        # Table statistics
        $tableQuery = @"
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 10;
"@
        
        $tableResult = psql -U $Config.DB_USER -h $Config.DB_HOST -p $Config.DB_PORT -d $Config.DB_NAME -c $tableQuery 2>&1
        
        Write-Host ""
        Write-Host "Database Size: $($sizeResult.Trim())" -ForegroundColor White
        Write-Host "Active Connections: $($connResult.Trim())" -ForegroundColor White
        Write-Host ""
        Write-Host "Top 10 Tables by Size:" -ForegroundColor Yellow
        Write-Host $tableResult -ForegroundColor White
        
        return $true
    }
    catch {
        Write-Error "Health check failed: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Clean old backups
function Remove-OldBackups {
    param(
        [string]$BackupDirectory,
        [int]$RetentionDays
    )
    
    if (-not (Test-Path $BackupDirectory)) {
        Write-Warning "Backup directory not found: $BackupDirectory"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldBackups = Get-ChildItem -Path $BackupDirectory -Filter "gameforge_backup_*.sql" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldBackups.Count -gt 0) {
        Write-Host "Removing $($oldBackups.Count) old backup(s)..." -ForegroundColor Yellow
        
        foreach ($backup in $oldBackups) {
            try {
                Remove-Item $backup.FullName -Force
                Write-Host "  ✓ Removed: $($backup.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "  ✗ Failed to remove: $($backup.Name) - $_"
            }
        }
    } else {
        Write-Host "No old backups to clean" -ForegroundColor Green
    }
}

# Main execution
function Main {
    Write-Host "GameForge Database Management" -ForegroundColor Green
    Write-Host ""
    
    # Load configuration
    $configPath = Join-Path $PSScriptRoot $ConfigFile
    $config = Get-DatabaseConfig -ConfigPath $configPath
    
    switch ($Action.ToLower()) {
        "backup" {
            $result = New-DatabaseBackup -Config $config -OutputPath $BackupPath -Compress:$Compress
            if ($result -and $CleanOld) {
                $backupDir = Split-Path $result -Parent
                Remove-OldBackups -BackupDirectory $backupDir -RetentionDays $RetentionDays
            }
        }
        "restore" {
            if (-not $RestoreFile) {
                Write-Error "Restore file required. Use -RestoreFile parameter"
                exit 1
            }
            if (-not (Restore-Database -Config $config -BackupFile $RestoreFile)) {
                exit 1
            }
        }
        "maintain" {
            if (-not (Invoke-DatabaseMaintenance -Config $config)) {
                exit 1
            }
        }
        "monitor" {
            if (-not (Get-DatabaseHealth -Config $config)) {
                exit 1
            }
        }
        default {
            Write-Host "Available actions:" -ForegroundColor Yellow
            Write-Host "  backup   - Create database backup" -ForegroundColor White
            Write-Host "  restore  - Restore from backup file" -ForegroundColor White
            Write-Host "  maintain - Run maintenance tasks" -ForegroundColor White
            Write-Host "  monitor  - Show database health" -ForegroundColor White
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\backup.ps1 -Action backup" -ForegroundColor Cyan
            Write-Host "  .\backup.ps1 -Action backup -BackupPath 'C:\backups\my_backup.sql'" -ForegroundColor Cyan
            Write-Host "  .\backup.ps1 -Action restore -RestoreFile 'backup.sql'" -ForegroundColor Cyan
            Write-Host "  .\backup.ps1 -Action maintain" -ForegroundColor Cyan
            Write-Host "  .\backup.ps1 -Action monitor" -ForegroundColor Cyan
        }
    }
}

# Run main function
Main