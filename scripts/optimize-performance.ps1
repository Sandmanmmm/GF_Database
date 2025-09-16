# GameForge Database Performance Optimization Script
# Optimizes PostgreSQL configuration for production deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [int]$TotalRAMGB = 16,
    
    [Parameter(Mandatory=$false)]
    [int]$CPUCores = 4,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode,
    
    [Parameter(Mandatory=$false)]
    [switch]$ApplyChanges,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateBackup
)

Write-Host "🚀 GameForge Database Performance Optimization" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$startTime = Get-Date
Write-Host "🕐 Optimization started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "💻 System: ${TotalRAMGB}GB RAM, ${CPUCores} CPU cores" -ForegroundColor Cyan
Write-Host "🌍 Environment: $Environment" -ForegroundColor Cyan
Write-Host "🏭 Production Mode: $ProductionMode" -ForegroundColor Cyan

# Detect system specifications if not provided
if ($TotalRAMGB -eq 16 -and $CPUCores -eq 4) {
    Write-Host "`n🔍 Auto-detecting system specifications..." -ForegroundColor Yellow
    
    try {
        $detectedRAM = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object { [math]::Round($_.Sum / 1GB, 2) }
        $detectedCPU = (Get-WmiObject Win32_Processor | Select-Object -First 1).NumberOfCores
        
        if ($detectedRAM -gt 0) { $TotalRAMGB = $detectedRAM }
        if ($detectedCPU -gt 0) { $CPUCores = $detectedCPU }
        
        Write-Host "✅ Detected: ${TotalRAMGB}GB RAM, ${CPUCores} CPU cores" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not auto-detect specs, using defaults: ${TotalRAMGB}GB RAM, ${CPUCores} cores" -ForegroundColor Yellow
    }
}

# Calculate optimal PostgreSQL settings based on system specs
Write-Host "`n🧮 Calculating Optimal PostgreSQL Settings" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow

# PostgreSQL configuration calculations
$sharedBuffersGB = [math]::Max(1, [math]::Round($TotalRAMGB * 0.25, 1))  # 25% of RAM
$effectiveCacheSizeGB = [math]::Max(2, [math]::Round($TotalRAMGB * 0.75, 1))  # 75% of RAM
$workMemMB = if ($ProductionMode) { 
    [math]::Max(16, [math]::Round((($TotalRAMGB * 1024) / $CPUCores) / 4, 0))  # RAM/cores/4
} else { 
    16  # Conservative for development
}
$maintenanceWorkMemMB = [math]::Max(256, [math]::Round($TotalRAMGB * 32, 0))  # ~2% of RAM in MB
$maxConnections = if ($ProductionMode) { 200 } else { 100 }
$maxWorkerProcesses = [math]::Max(8, $CPUCores * 2)
$maxParallelWorkers = [math]::Max(2, [math]::Min($CPUCores, 8))

# Additional performance settings
$walBuffers = [math]::Max(16, [math]::Min(($sharedBuffersGB * 1024 / 32), 64))  # 3% of shared_buffers, max 64MB
$checkpointCompletionTarget = 0.9
$randomPageCost = 1.1  # For SSD storage
$seqPageCost = 1.0
$defaultStatisticsTarget = 1000

Write-Host "📊 Calculated Settings:" -ForegroundColor Cyan
Write-Host "  shared_buffers: ${sharedBuffersGB}GB" -ForegroundColor White
Write-Host "  effective_cache_size: ${effectiveCacheSizeGB}GB" -ForegroundColor White
Write-Host "  work_mem: ${workMemMB}MB" -ForegroundColor White
Write-Host "  maintenance_work_mem: ${maintenanceWorkMemMB}MB" -ForegroundColor White
Write-Host "  max_connections: $maxConnections" -ForegroundColor White
Write-Host "  max_worker_processes: $maxWorkerProcesses" -ForegroundColor White
Write-Host "  max_parallel_workers: $maxParallelWorkers" -ForegroundColor White
Write-Host "  wal_buffers: ${walBuffers}MB" -ForegroundColor White

# Current PostgreSQL configuration check
Write-Host "`n🔍 Checking Current PostgreSQL Configuration" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow

$currentSettings = @{}
try {
    $env:PGPASSWORD = "password"
    
    $settingsToCheck = @(
        'shared_buffers', 'effective_cache_size', 'work_mem', 'maintenance_work_mem',
        'max_connections', 'checkpoint_completion_target', 'wal_buffers',
        'max_worker_processes', 'max_parallel_workers', 'random_page_cost'
    )
    
    foreach ($setting in $settingsToCheck) {
        try {
            $result = psql -h localhost -U postgres -d postgres -c "SHOW $setting;" -t 2>$null
            if ($LASTEXITCODE -eq 0) {
                $currentSettings[$setting] = $result.Trim()
                Write-Host "  ${setting}: $($result.Trim())" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  ${setting}: Unable to retrieve" -ForegroundColor Red
        }
    }
    
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
} catch {
    Write-Host "❌ Could not connect to PostgreSQL to check current settings" -ForegroundColor Red
}

# Create optimized postgresql.conf additions
Write-Host "`n📝 Generating Optimized Configuration" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

$optimizedConfig = @"
# GameForge Database Performance Optimization
# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# System: ${TotalRAMGB}GB RAM, ${CPUCores} CPU cores
# Environment: $Environment

# Memory Configuration
shared_buffers = ${sharedBuffersGB}GB
effective_cache_size = ${effectiveCacheSizeGB}GB
work_mem = ${workMemMB}MB
maintenance_work_mem = ${maintenanceWorkMemMB}MB

# Connection Configuration
max_connections = $maxConnections

# Write-Ahead Logging (WAL) Configuration
wal_buffers = ${walBuffers}MB
wal_level = replica
max_wal_size = 4GB
min_wal_size = 1GB
checkpoint_completion_target = $checkpointCompletionTarget
checkpoint_timeout = 10min

# Parallel Query Configuration
max_worker_processes = $maxWorkerProcesses
max_parallel_workers = $maxParallelWorkers
max_parallel_workers_per_gather = $([math]::Min($maxParallelWorkers, 4))
max_parallel_maintenance_workers = $([math]::Min($maxParallelWorkers, 4))

# Planner Cost Configuration (optimized for SSD)
random_page_cost = $randomPageCost
seq_page_cost = $seqPageCost
cpu_tuple_cost = 0.01
cpu_index_tuple_cost = 0.005
cpu_operator_cost = 0.0025

# Query Planner Configuration
default_statistics_target = $defaultStatisticsTarget
constraint_exclusion = partition
cursor_tuple_fraction = 0.1

# Background Writer Configuration
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0
bgwriter_flush_after = 512kB

# Autovacuum Configuration
autovacuum = on
autovacuum_max_workers = $([math]::Min($CPUCores, 3))
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.02
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.01

# Logging Configuration for Performance Monitoring
log_min_duration_statement = 1000ms
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 10MB
log_autovacuum_min_duration = 0
log_statement = 'ddl'

# Additional Performance Settings
synchronous_commit = on
fsync = on
full_page_writes = on
wal_compression = on
wal_init_zero = on
wal_recycle = on

# Connection and Authentication
listen_addresses = 'localhost'
port = 5432
tcp_keepalives_idle = 600
tcp_keepalives_interval = 30
tcp_keepalives_count = 3
"@

# Save configuration to file
$configPath = Join-Path $PSScriptRoot "..\config\postgresql-performance.conf"
$configDir = Split-Path $configPath -Parent
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$optimizedConfig | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "✅ Configuration saved to: $configPath" -ForegroundColor Green

# Create backup of current postgresql.conf if requested
if ($CreateBackup) {
    Write-Host "`n💾 Creating Backup of Current Configuration" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    
    $pgDataDir = "C:\Program Files\PostgreSQL\17\data"
    $postgresqlConfPath = Join-Path $pgDataDir "postgresql.conf"
    
    if (Test-Path $postgresqlConfPath) {
        $backupPath = Join-Path $PSScriptRoot "..\config\postgresql.conf.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        try {
            Copy-Item $postgresqlConfPath $backupPath -Force
            Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create backup: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  PostgreSQL config file not found at: $postgresqlConfPath" -ForegroundColor Yellow
    }
}

# Apply changes if requested
if ($ApplyChanges) {
    Write-Host "`n🔧 Applying Configuration Changes" -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Yellow
    
    try {
        $env:PGPASSWORD = "password"
        
        Write-Host "📝 Applying memory settings..." -ForegroundColor Cyan
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET shared_buffers = '${sharedBuffersGB}GB';" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET effective_cache_size = '${effectiveCacheSizeGB}GB';" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET work_mem = '${workMemMB}MB';" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET maintenance_work_mem = '${maintenanceWorkMemMB}MB';" | Out-Null
        
        Write-Host "🔗 Applying connection settings..." -ForegroundColor Cyan
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET max_connections = $maxConnections;" | Out-Null
        
        Write-Host "⚡ Applying performance settings..." -ForegroundColor Cyan
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET wal_buffers = '${walBuffers}MB';" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET checkpoint_completion_target = $checkpointCompletionTarget;" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET max_worker_processes = $maxWorkerProcesses;" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET max_parallel_workers = $maxParallelWorkers;" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET random_page_cost = $randomPageCost;" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET default_statistics_target = $defaultStatisticsTarget;" | Out-Null
        
        Write-Host "📊 Applying monitoring settings..." -ForegroundColor Cyan
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_min_duration_statement = '1000ms';" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_checkpoints = on;" | Out-Null
        psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_lock_waits = on;" | Out-Null
        
        Write-Host "🔄 Reloading PostgreSQL configuration..." -ForegroundColor Cyan
        psql -h localhost -U postgres -d postgres -c "SELECT pg_reload_conf();" | Out-Null
        
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
        Write-Host "✅ Configuration changes applied successfully!" -ForegroundColor Green
        Write-Host "⚠️  Note: Some changes require PostgreSQL restart to take effect" -ForegroundColor Yellow
        
    } catch {
        Write-Host "❌ Failed to apply configuration changes: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Performance testing recommendations
Write-Host "`n🧪 Performance Testing Recommendations" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "1. Connection Testing:" -ForegroundColor Cyan
Write-Host "   pgbench -i -s 10 gameforge_dev" -ForegroundColor Gray
Write-Host "   pgbench -c 10 -j 2 -t 1000 gameforge_dev" -ForegroundColor Gray

Write-Host "`n2. Query Performance Analysis:" -ForegroundColor Cyan
Write-Host "   Enable pg_stat_statements extension for query analysis" -ForegroundColor Gray
Write-Host "   Monitor slow queries with log_min_duration_statement" -ForegroundColor Gray

Write-Host "`n3. Index Usage Analysis:" -ForegroundColor Cyan
Write-Host "   Check pg_stat_user_indexes for unused indexes" -ForegroundColor Gray
Write-Host "   Monitor index hit ratios in pg_statio_user_indexes" -ForegroundColor Gray

# Connection pooling recommendations
Write-Host "`n🏊 Connection Pooling Recommendations" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

Write-Host "📋 Application-Level Pooling (Recommended):" -ForegroundColor Cyan
Write-Host "  - SQLAlchemy: pool_size=20, max_overflow=30, pool_recycle=3600" -ForegroundColor Gray
Write-Host "  - Node.js pg-pool: max=20, idleTimeoutMillis=30000" -ForegroundColor Gray
Write-Host "  - Java HikariCP: maximumPoolSize=20, idleTimeout=600000" -ForegroundColor Gray

Write-Host "`n🔧 pgBouncer Configuration (Alternative):" -ForegroundColor Cyan
Write-Host "  - Transaction pooling mode for best performance" -ForegroundColor Gray
Write-Host "  - max_client_conn = 200, default_pool_size = 25" -ForegroundColor Gray
Write-Host "  - pool_mode = transaction, server_reset_query = DISCARD ALL" -ForegroundColor Gray

# Create monitoring script
Write-Host "`n📊 Creating Performance Monitoring Script" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

$monitoringScript = @"
# GameForge Database Performance Monitoring
# Quick performance check script

`$env:PGPASSWORD = "password"

Write-Host "🔍 GameForge Database Performance Check" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Database size and activity
Write-Host "`n📊 Database Statistics:" -ForegroundColor Yellow
psql -h localhost -U postgres -d gameforge_dev -c "
SELECT 
    pg_size_pretty(pg_database_size('gameforge_dev')) as database_size,
    (SELECT count(*) FROM pg_stat_activity WHERE datname = 'gameforge_dev') as active_connections;
"

# Index hit ratio (should be >95%)
Write-Host "`n📈 Cache Hit Ratios:" -ForegroundColor Yellow
psql -h localhost -U postgres -d gameforge_dev -c "
SELECT 
    'Index Hit Ratio' as metric,
    round(sum(idx_blks_hit) * 100.0 / nullif(sum(idx_blks_hit + idx_blks_read), 0), 2) as percentage
FROM pg_statio_user_indexes
UNION ALL
SELECT 
    'Table Hit Ratio' as metric,
    round(sum(heap_blks_hit) * 100.0 / nullif(sum(heap_blks_hit + heap_blks_read), 0), 2) as percentage
FROM pg_statio_user_tables;
"

# Table sizes
Write-Host "`n📋 Table Sizes:" -ForegroundColor Yellow
psql -h localhost -U postgres -d gameforge_dev -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 10;
"

# Active queries
Write-Host "`n🔄 Active Queries:" -ForegroundColor Yellow
psql -h localhost -U postgres -d gameforge_dev -c "
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    extract(epoch from now() - query_start) as duration_seconds,
    left(query, 100) as query_preview
FROM pg_stat_activity 
WHERE state != 'idle' AND datname = 'gameforge_dev'
ORDER BY query_start;
"

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
"@

$monitoringScriptPath = Join-Path $PSScriptRoot "monitor-performance.ps1"
$monitoringScript | Out-File -FilePath $monitoringScriptPath -Encoding UTF8
Write-Host "✅ Performance monitoring script created: $monitoringScriptPath" -ForegroundColor Green

# Summary and next steps
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n🎉 Performance Optimization Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor White
Write-Host "Configuration file: $configPath" -ForegroundColor White
Write-Host "Monitoring script: $monitoringScriptPath" -ForegroundColor White

Write-Host "`n🔧 Recommended Settings Applied:" -ForegroundColor Cyan
Write-Host "  shared_buffers: ${sharedBuffersGB}GB (25% of ${TotalRAMGB}GB RAM)" -ForegroundColor White
Write-Host "  effective_cache_size: ${effectiveCacheSizeGB}GB (75% of ${TotalRAMGB}GB RAM)" -ForegroundColor White
Write-Host "  work_mem: ${workMemMB}MB" -ForegroundColor White
Write-Host "  max_connections: $maxConnections" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
if (!$ApplyChanges) {
    Write-Host "1. Review the generated configuration: $configPath" -ForegroundColor White
    Write-Host "2. Apply changes: .\optimize-performance.ps1 -ApplyChanges" -ForegroundColor White
    Write-Host "3. Restart PostgreSQL service for all changes to take effect" -ForegroundColor White
} else {
    Write-Host "1. Restart PostgreSQL service for all changes to take effect" -ForegroundColor White
    Write-Host "2. Run performance monitoring: .\monitor-performance.ps1" -ForegroundColor White
    Write-Host "3. Implement connection pooling in your application" -ForegroundColor White
}
Write-Host "4. Set up automated performance monitoring" -ForegroundColor White
Write-Host "5. Conduct load testing to validate improvements" -ForegroundColor White

if ($ApplyChanges) {
    Write-Host "`n⚠️  IMPORTANT: PostgreSQL service restart required!" -ForegroundColor Yellow
    Write-Host "Some settings (like shared_buffers) require a restart to take effect." -ForegroundColor Yellow
    Write-Host "Run: Restart-Service postgresql-x64-17" -ForegroundColor Gray
}

Write-Host "`n🎯 Your database is now optimized for ${TotalRAMGB}GB RAM system!" -ForegroundColor Green