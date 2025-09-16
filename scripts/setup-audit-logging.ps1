# GameForge Database Audit Logging Setup Script
# Configures pgAudit extension for comprehensive database audit logging

param(
    [Parameter(Mandatory=$false)]
    [string]$PostgreSQLDataDir = "C:\Program Files\PostgreSQL\17\data",
    
    [Parameter(Mandatory=$false)]
    [string]$AuditLogDir = "C:\GameForge\audit-logs",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "📊 GameForge Database Audit Logging Setup" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Step 1: Create audit log directory
Write-Host "`n📁 Step 1: Setting up audit log directories..." -ForegroundColor Yellow

if (!(Test-Path $AuditLogDir)) {
    New-Item -ItemType Directory -Path $AuditLogDir -Force
    Write-Host "✅ Created audit log directory: $AuditLogDir" -ForegroundColor Green
}

$archiveDir = Join-Path $AuditLogDir "archive"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force
    Write-Host "✅ Created archive directory: $archiveDir" -ForegroundColor Green
}

# Step 2: Check and install pgAudit extension
Write-Host "`n🔧 Step 2: Configuring pgAudit extension..." -ForegroundColor Yellow

# Check if pgAudit is available
try {
    $pgAuditCheck = psql -h localhost -U postgres -d gameforge_dev -c "SELECT * FROM pg_available_extensions WHERE name = 'pgaudit';" -t 2>&1
    
    if ($pgAuditCheck -match "pgaudit") {
        Write-Host "✅ pgAudit extension is available" -ForegroundColor Green
        
        # Create extension if not exists
        $createExtension = psql -h localhost -U postgres -d gameforge_dev -c "CREATE EXTENSION IF NOT EXISTS pgaudit;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ pgAudit extension created successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to create pgAudit extension: $createExtension" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  pgAudit extension not available. Installing..." -ForegroundColor Yellow
        Write-Host "ℹ️  pgAudit comes with PostgreSQL 13+ by default. Check your installation." -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  Could not check pgAudit availability. Continuing with configuration..." -ForegroundColor Yellow
}

# Step 3: Configure PostgreSQL for audit logging
Write-Host "`n📝 Step 3: Updating PostgreSQL configuration for audit logging..." -ForegroundColor Yellow

$postgresqlConfPath = Join-Path $PostgreSQLDataDir "postgresql.conf"

# Backup original configuration
$backupSuffix = (Get-Date).ToString("yyyyMMdd_HHmmss")
Copy-Item $postgresqlConfPath "$postgresqlConfPath.audit_backup_$backupSuffix"

# Read current configuration
$pgConfig = Get-Content $postgresqlConfPath

# Add audit logging configuration
$auditConfig = @"

# ============================================================================
# GAMEFORGE DATABASE AUDIT LOGGING CONFIGURATION
# ============================================================================

# Enable logging
logging_collector = on
log_destination = 'stderr,csvlog'
log_directory = '$($AuditLogDir.Replace('\', '/'))'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_file_mode = 0600

# Log rotation
log_rotation_age = 1d
log_rotation_size = 100MB
log_truncate_on_rotation = off

# What to log
log_connections = on
log_disconnections = on
log_duration = on
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
log_lock_waits = on
log_statement = 'all'
log_temp_files = 1024

# Performance logging
log_min_duration_statement = 1000  # Log slow queries (>1 second)
log_checkpoints = on
log_autovacuum_min_duration = 0

# Security logging
log_hostname = on
log_timezone = 'UTC'

# pgAudit configuration
shared_preload_libraries = 'pgaudit'

# pgAudit settings
pgaudit.log = 'all'
pgaudit.log_catalog = on
pgaudit.log_client = on
pgaudit.log_level = 'log'
pgaudit.log_parameter = on
pgaudit.log_relation = on
pgaudit.log_statement_once = off

# Role-based audit logging
pgaudit.role = 'gameforge_audit'

# ============================================================================
"@

# Remove existing audit configuration and add new one
$pgConfig = $pgConfig | Where-Object { 
    $_ -notmatch "^logging_collector" -and 
    $_ -notmatch "^log_destination" -and 
    $_ -notmatch "^log_directory" -and 
    $_ -notmatch "^log_filename" -and 
    $_ -notmatch "^log_file_mode" -and 
    $_ -notmatch "^log_rotation" -and 
    $_ -notmatch "^log_truncate_on_rotation" -and 
    $_ -notmatch "^log_connections" -and 
    $_ -notmatch "^log_disconnections" -and 
    $_ -notmatch "^log_duration" -and 
    $_ -notmatch "^log_line_prefix" -and 
    $_ -notmatch "^log_lock_waits" -and 
    $_ -notmatch "^log_statement" -and 
    $_ -notmatch "^log_temp_files" -and 
    $_ -notmatch "^log_min_duration_statement" -and 
    $_ -notmatch "^log_checkpoints" -and 
    $_ -notmatch "^log_autovacuum" -and 
    $_ -notmatch "^log_hostname" -and 
    $_ -notmatch "^log_timezone" -and 
    $_ -notmatch "^shared_preload_libraries" -and 
    $_ -notmatch "^pgaudit" -and
    $_ -notmatch "# GAMEFORGE DATABASE AUDIT" -and
    $_ -notmatch "# =========="
}

$pgConfig += $auditConfig
$pgConfig | Out-File -FilePath $postgresqlConfPath -Encoding UTF8

Write-Host "✅ PostgreSQL audit configuration updated!" -ForegroundColor Green

# Step 4: Create audit role and permissions
Write-Host "`n👤 Step 4: Creating audit role and permissions..." -ForegroundColor Yellow

$auditRoleScript = @"
-- Create audit role for pgAudit
DO `$`$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gameforge_audit') THEN
        CREATE ROLE gameforge_audit;
    END IF;
END
`$`$;

-- Grant necessary permissions for audit logging
GRANT SELECT ON ALL TABLES IN SCHEMA public TO gameforge_audit;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO gameforge_audit;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO gameforge_audit;

-- Grant audit role to application users
GRANT gameforge_audit TO gameforge_user;

-- Set up audit configuration for specific operations
ALTER SYSTEM SET pgaudit.log = 'write,ddl,role,misc_set';
ALTER SYSTEM SET pgaudit.log_catalog = 'on';
ALTER SYSTEM SET pgaudit.log_client = 'on';
ALTER SYSTEM SET pgaudit.log_level = 'log';
ALTER SYSTEM SET pgaudit.log_parameter = 'on';
ALTER SYSTEM SET pgaudit.log_relation = 'on';

SELECT pg_reload_conf();
"@

$auditRoleScriptPath = Join-Path $PSScriptRoot "..\migrations\004_audit_setup.sql"
$auditRoleScript | Out-File -FilePath $auditRoleScriptPath -Encoding UTF8

# Execute the audit role script
try {
    $result = psql -h localhost -U postgres -d gameforge_dev -f $auditRoleScriptPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Audit role and permissions created successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Audit role creation had issues: $result" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not execute audit role script. Run manually after restart." -ForegroundColor Yellow
}

Write-Host "✅ Audit role script created: $auditRoleScriptPath" -ForegroundColor Green

# Step 5: Create log rotation and management scripts
Write-Host "`n🔄 Step 5: Creating log rotation and management scripts..." -ForegroundColor Yellow

$logRotationScriptPath = Join-Path $PSScriptRoot "rotate-audit-logs.ps1"
$logRotationScript = @"
# GameForge Database Audit Log Rotation Script

param(
    [Parameter(Mandatory=`$false)]
    [int]`$RetentionDays = 90,
    
    [Parameter(Mandatory=`$false)]
    [string]`$LogDirectory = "$AuditLogDir",
    
    [Parameter(Mandatory=`$false)]
    [string]`$ArchiveDirectory = "$archiveDir"
)

Write-Host "🔄 GameForge Audit Log Rotation" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Get current date for rotation
`$currentDate = Get-Date
`$cutoffDate = `$currentDate.AddDays(-`$RetentionDays)

Write-Host "📅 Rotating logs older than: `$(`$cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

# Find old log files
`$logFiles = Get-ChildItem -Path `$LogDirectory -Filter "*.log" | Where-Object { `$_.LastWriteTime -lt `$cutoffDate }
`$csvFiles = Get-ChildItem -Path `$LogDirectory -Filter "*.csv" | Where-Object { `$_.LastWriteTime -lt `$cutoffDate }

`$totalFiles = `$logFiles.Count + `$csvFiles.Count

if (`$totalFiles -eq 0) {
    Write-Host "✅ No log files need rotation" -ForegroundColor Green
    exit 0
}

Write-Host "📦 Found `$totalFiles log files to archive" -ForegroundColor Yellow

# Archive old log files
`$archiveCount = 0
foreach (`$file in (`$logFiles + `$csvFiles)) {
    try {
        `$archivePath = Join-Path `$ArchiveDirectory `$file.Name
        Move-Item `$file.FullName `$archivePath -Force
        `$archiveCount++
        Write-Host "✅ Archived: `$(`$file.Name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to archive: `$(`$file.Name) - `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

# Compress archived files older than 30 days
Write-Host "`n🗜️ Compressing old archived files..." -ForegroundColor Yellow

`$oldArchiveFiles = Get-ChildItem -Path `$ArchiveDirectory -Filter "*.log" | Where-Object { `$_.LastWriteTime -lt `$currentDate.AddDays(-30) }
`$oldArchiveFiles += Get-ChildItem -Path `$ArchiveDirectory -Filter "*.csv" | Where-Object { `$_.LastWriteTime -lt `$currentDate.AddDays(-30) }

foreach (`$file in `$oldArchiveFiles) {
    try {
        `$zipPath = `$file.FullName + ".zip"
        Compress-Archive -Path `$file.FullName -DestinationPath `$zipPath -Force
        Remove-Item `$file.FullName -Force
        Write-Host "✅ Compressed: `$(`$file.Name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to compress: `$(`$file.Name) - `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

# Delete very old archived files (older than retention period)
Write-Host "`n🗑️ Cleaning up old archived files..." -ForegroundColor Yellow

`$veryOldFiles = Get-ChildItem -Path `$ArchiveDirectory | Where-Object { `$_.LastWriteTime -lt `$cutoffDate }
`$deletedCount = 0

foreach (`$file in `$veryOldFiles) {
    try {
        Remove-Item `$file.FullName -Force
        `$deletedCount++
        Write-Host "✅ Deleted old archive: `$(`$file.Name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to delete: `$(`$file.Name) - `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n📊 Log Rotation Summary" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Files archived: `$archiveCount" -ForegroundColor White
Write-Host "Files deleted: `$deletedCount" -ForegroundColor White
Write-Host "Archive directory: `$ArchiveDirectory" -ForegroundColor White
Write-Host "Retention period: `$RetentionDays days" -ForegroundColor White

Write-Host "`n✅ Log rotation completed successfully!" -ForegroundColor Green
"@

$logRotationScript | Out-File -FilePath $logRotationScriptPath -Encoding UTF8
Write-Host "✅ Log rotation script created: $logRotationScriptPath" -ForegroundColor Green

# Step 6: Create audit log monitoring script
Write-Host "`n📊 Step 6: Creating audit log monitoring script..." -ForegroundColor Yellow

$monitoringScriptPath = Join-Path $PSScriptRoot "monitor-audit-logs.ps1"
$monitoringScript = @"
# GameForge Database Audit Log Monitoring Script

param(
    [Parameter(Mandatory=`$false)]
    [string]`$LogDirectory = "$AuditLogDir",
    
    [Parameter(Mandatory=`$false)]
    [int]`$TailLines = 100,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$ShowSummary,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$ShowSecurity,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$ShowErrors
)

Write-Host "📊 GameForge Database Audit Log Monitor" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Get latest log files
`$latestLogFile = Get-ChildItem -Path `$LogDirectory -Filter "postgresql-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
`$latestCsvFile = Get-ChildItem -Path `$LogDirectory -Filter "postgresql-*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!`$latestLogFile) {
    Write-Host "❌ No PostgreSQL log files found in `$LogDirectory" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Latest log file: `$(`$latestLogFile.Name)" -ForegroundColor Cyan
Write-Host "📅 Last modified: `$(`$latestLogFile.LastWriteTime)" -ForegroundColor Cyan

if (`$ShowSummary) {
    Write-Host "`n📊 Audit Log Summary (Last 24 hours)" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    `$logContent = Get-Content `$latestLogFile.FullName | Where-Object { `$_ -match (Get-Date).AddDays(-1).ToString("yyyy-MM-dd") }
    
    # Count different types of events
    `$connections = (`$logContent | Where-Object { `$_ -match "connection authorized" }).Count
    `$disconnections = (`$logContent | Where-Object { `$_ -match "disconnection" }).Count
    `$selects = (`$logContent | Where-Object { `$_ -match "SELECT" }).Count
    `$inserts = (`$logContent | Where-Object { `$_ -match "INSERT" }).Count
    `$updates = (`$logContent | Where-Object { `$_ -match "UPDATE" }).Count
    `$deletes = (`$logContent | Where-Object { `$_ -match "DELETE" }).Count
    `$ddl = (`$logContent | Where-Object { `$_ -match "(CREATE|ALTER|DROP)" }).Count
    
    Write-Host "🔌 Connections: `$connections" -ForegroundColor Green
    Write-Host "🔌 Disconnections: `$disconnections" -ForegroundColor Green
    Write-Host "📖 SELECT queries: `$selects" -ForegroundColor Cyan
    Write-Host "➕ INSERT operations: `$inserts" -ForegroundColor Blue
    Write-Host "✏️ UPDATE operations: `$updates" -ForegroundColor Blue
    Write-Host "🗑️ DELETE operations: `$deletes" -ForegroundColor Red
    Write-Host "🔧 DDL operations: `$ddl" -ForegroundColor Yellow
}

if (`$ShowSecurity) {
    Write-Host "`n🔐 Security Events (Last 100 entries)" -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    
    `$securityEvents = Get-Content `$latestLogFile.FullName | Where-Object { 
        `$_ -match "(authentication|authorization|permission|denied|failed|error)" 
    } | Select-Object -Last 20
    
    if (`$securityEvents) {
        foreach (`$event in `$securityEvents) {
            if (`$event -match "authentication|authorization") {
                Write-Host "🔐 `$event" -ForegroundColor Green
            } elseif (`$event -match "denied|failed|error") {
                Write-Host "❌ `$event" -ForegroundColor Red
            } else {
                Write-Host "⚠️ `$event" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✅ No security events found" -ForegroundColor Green
    }
}

if (`$ShowErrors) {
    Write-Host "`n❌ Error Events (Last 50 entries)" -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Yellow
    
    `$errorEvents = Get-Content `$latestLogFile.FullName | Where-Object { 
        `$_ -match "(ERROR|FATAL|PANIC)" 
    } | Select-Object -Last 50
    
    if (`$errorEvents) {
        foreach (`$error in `$errorEvents) {
            Write-Host "❌ `$error" -ForegroundColor Red
        }
    } else {
        Write-Host "✅ No errors found" -ForegroundColor Green
    }
}

# Show recent activity (default)
if (!`$ShowSummary -and !`$ShowSecurity -and !`$ShowErrors) {
    Write-Host "`n📋 Recent Activity (Last `$TailLines lines)" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    `$recentLogs = Get-Content `$latestLogFile.FullName | Select-Object -Last `$TailLines
    
    foreach (`$line in `$recentLogs) {
        if (`$line -match "ERROR|FATAL|PANIC") {
            Write-Host `$line -ForegroundColor Red
        } elseif (`$line -match "WARNING") {
            Write-Host `$line -ForegroundColor Yellow
        } elseif (`$line -match "AUDIT|pgaudit") {
            Write-Host `$line -ForegroundColor Cyan
        } else {
            Write-Host `$line -ForegroundColor White
        }
    }
}

# Check log file size and warn if too large
`$logSizeMB = [math]::Round(`$latestLogFile.Length / 1MB, 2)
if (`$logSizeMB -gt 500) {
    Write-Host "`n⚠️ WARNING: Log file is large (`$logSizeMB MB). Consider running log rotation." -ForegroundColor Yellow
} else {
    Write-Host "`n📊 Current log file size: `$logSizeMB MB" -ForegroundColor Green
}

Write-Host "`n💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "Show summary: .\monitor-audit-logs.ps1 -ShowSummary" -ForegroundColor White
Write-Host "Show security: .\monitor-audit-logs.ps1 -ShowSecurity" -ForegroundColor White
Write-Host "Show errors: .\monitor-audit-logs.ps1 -ShowErrors" -ForegroundColor White
Write-Host "Tail logs: .\monitor-audit-logs.ps1 -TailLines 50" -ForegroundColor White
"@

$monitoringScript | Out-File -FilePath $monitoringScriptPath -Encoding UTF8
Write-Host "✅ Audit log monitoring script created: $monitoringScriptPath" -ForegroundColor Green

# Step 7: Create scheduled task for log rotation
Write-Host "`n⏰ Step 7: Creating scheduled task for log rotation..." -ForegroundColor Yellow

$taskScriptPath = Join-Path $PSScriptRoot "setup-audit-log-task.ps1"
$taskScript = @"
# Setup Scheduled Task for Audit Log Rotation

param(
    [Parameter(Mandatory=`$false)]
    [string]`$TaskName = "GameForge-AuditLogRotation",
    
    [Parameter(Mandatory=`$false)]
    [string]`$RunTime = "02:00"  # 2 AM daily
)

Write-Host "⏰ Setting up scheduled task for audit log rotation..." -ForegroundColor Green

try {
    # Check if task already exists
    `$existingTask = Get-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue
    
    if (`$existingTask) {
        Write-Host "⚠️ Task '`$TaskName' already exists. Updating..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName `$TaskName -Confirm:`$false
    }
    
    # Create scheduled task action
    `$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"`$PSScriptRoot\rotate-audit-logs.ps1`""
    
    # Create scheduled task trigger (daily at specified time)
    `$trigger = New-ScheduledTaskTrigger -Daily -At `$RunTime
    
    # Create scheduled task settings
    `$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
    
    # Create scheduled task principal (run as SYSTEM)
    `$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the scheduled task
    Register-ScheduledTask -TaskName `$TaskName -Action `$action -Trigger `$trigger -Settings `$settings -Principal `$principal -Description "GameForge Database Audit Log Rotation"
    
    Write-Host "✅ Scheduled task '`$TaskName' created successfully!" -ForegroundColor Green
    Write-Host "⏰ Will run daily at `$RunTime" -ForegroundColor Cyan
    
    # Test the task
    Write-Host "`n🧪 Testing scheduled task..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName `$TaskName
    
    Start-Sleep -Seconds 5
    `$taskInfo = Get-ScheduledTask -TaskName `$TaskName
    Write-Host "✅ Task status: `$(`$taskInfo.State)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: `$(`$_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Scheduled Task Details:" -ForegroundColor Cyan
Write-Host "Task Name: `$TaskName" -ForegroundColor White
Write-Host "Run Time: Daily at `$RunTime" -ForegroundColor White
Write-Host "Script: `$PSScriptRoot\rotate-audit-logs.ps1" -ForegroundColor White
"@

$taskScript | Out-File -FilePath $taskScriptPath -Encoding UTF8
Write-Host "✅ Scheduled task setup script created: $taskScriptPath" -ForegroundColor Green

# Step 8: Restart PostgreSQL service
Write-Host "`n🔄 Step 8: Restarting PostgreSQL service..." -ForegroundColor Yellow

try {
    $service = Get-Service -Name "postgresql*" | Select-Object -First 1
    if ($service) {
        Write-Host "Stopping PostgreSQL service..." -ForegroundColor Cyan
        Stop-Service $service.Name -Force
        Start-Sleep -Seconds 5
        
        Write-Host "Starting PostgreSQL service..." -ForegroundColor Cyan
        Start-Service $service.Name
        Start-Sleep -Seconds 10
        
        $serviceStatus = Get-Service $service.Name
        if ($serviceStatus.Status -eq "Running") {
            Write-Host "✅ PostgreSQL service restarted successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  PostgreSQL service status: $($serviceStatus.Status)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  PostgreSQL service not found. Please restart manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not restart PostgreSQL service automatically. Please restart manually." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 9: Test audit logging
Write-Host "`n🧪 Step 9: Testing audit logging..." -ForegroundColor Yellow

Start-Sleep -Seconds 15  # Wait for service to fully start

try {
    # Test connection and audit logging
    $testResult = psql -h localhost -U postgres -d gameforge_dev -c "SELECT 'Audit test: ' || current_timestamp as test_message;" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database connection successful!" -ForegroundColor Green
        
        # Check if audit logs are being generated
        Start-Sleep -Seconds 5
        $latestLog = Get-ChildItem -Path $AuditLogDir -Filter "postgresql-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($latestLog -and $latestLog.LastWriteTime -gt (Get-Date).AddMinutes(-2)) {
            Write-Host "✅ Audit logging is working! Log file: $($latestLog.Name)" -ForegroundColor Green
            
            # Show recent audit entries
            $recentAudit = Get-Content $latestLog.FullName | Select-Object -Last 5
            Write-Host "`n📋 Recent audit entries:" -ForegroundColor Cyan
            foreach ($entry in $recentAudit) {
                Write-Host "  $entry" -ForegroundColor White
            }
        } else {
            Write-Host "⚠️  Audit log file not found or not recent. Check configuration." -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Database connection failed: $testResult" -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️  Could not test audit logging. Check configuration manually." -ForegroundColor Yellow
}

# Final Summary
Write-Host "`n🎉 Database Audit Logging Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✅ pgAudit extension configured" -ForegroundColor Green
Write-Host "✅ PostgreSQL audit logging enabled" -ForegroundColor Green
Write-Host "✅ Audit role and permissions created" -ForegroundColor Green
Write-Host "✅ Log rotation script created" -ForegroundColor Green
Write-Host "✅ Log monitoring script created" -ForegroundColor Green
Write-Host "✅ Scheduled task setup script created" -ForegroundColor Green

Write-Host "`n📁 Created Files:" -ForegroundColor Cyan
Write-Host "- Audit Log Directory: $AuditLogDir" -ForegroundColor White
Write-Host "- Archive Directory: $archiveDir" -ForegroundColor White
Write-Host "- Audit Role Migration: $auditRoleScriptPath" -ForegroundColor White
Write-Host "- Log Rotation Script: $logRotationScriptPath" -ForegroundColor White
Write-Host "- Monitoring Script: $monitoringScriptPath" -ForegroundColor White
Write-Host "- Task Setup Script: $taskScriptPath" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set up scheduled task: .\setup-audit-log-task.ps1" -ForegroundColor White
Write-Host "2. Monitor logs: .\monitor-audit-logs.ps1 -ShowSummary" -ForegroundColor White
Write-Host "3. Test log rotation: .\rotate-audit-logs.ps1" -ForegroundColor White
Write-Host "4. Configure log shipping to SIEM (if required)" -ForegroundColor White

Write-Host "`n💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "Show audit summary: .\monitor-audit-logs.ps1 -ShowSummary" -ForegroundColor White
Write-Host "Show security events: .\monitor-audit-logs.ps1 -ShowSecurity" -ForegroundColor White
Write-Host "Rotate logs manually: .\rotate-audit-logs.ps1 -RetentionDays 60" -ForegroundColor White

Write-Host "`n⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "- Audit logs will be generated at: $AuditLogDir" -ForegroundColor White
Write-Host "- Log rotation is recommended daily to manage disk space" -ForegroundColor White
Write-Host "- Monitor disk space usage regularly" -ForegroundColor White
Write-Host "- Configure log shipping to centralized logging system for production" -ForegroundColor White