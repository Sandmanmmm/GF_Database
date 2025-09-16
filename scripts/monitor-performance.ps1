# GameForge Database Performance Monitoring Script
# Monitors database performance metrics and provides optimization insights

param(
    [Parameter(Mandatory=$false)]
    [switch]$Continuous,
    
    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 30
)

Write-Host "📊 GameForge Database Performance Monitor" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "🕐 Monitor started at: $timestamp" -ForegroundColor Cyan

function Get-DatabaseMetrics {
    try {
        $env:PGPASSWORD = "password"
        
        Write-Host "`n📊 Database Performance Metrics" -ForegroundColor Yellow
        Write-Host "===============================" -ForegroundColor Yellow
        
        # Database size and connections
        Write-Host "`n📈 Database Overview:" -ForegroundColor Cyan
        $overview = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT 
            pg_size_pretty(pg_database_size('gameforge_dev')) as database_size,
            (SELECT count(*) FROM pg_stat_activity WHERE datname = 'gameforge_dev') as active_connections,
            (SELECT setting FROM pg_settings WHERE name = 'max_connections') as max_connections;
        " -t
        Write-Host $overview -ForegroundColor White
        
        # Cache hit ratios (should be >95%)
        Write-Host "`n💾 Cache Performance:" -ForegroundColor Cyan
        $cacheStats = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT 
            'Buffer Cache Hit Ratio' as metric,
            CASE 
                WHEN sum(heap_blks_hit + heap_blks_read) = 0 THEN 0
                ELSE round(sum(heap_blks_hit) * 100.0 / sum(heap_blks_hit + heap_blks_read), 2)
            END as percentage
        FROM pg_statio_user_tables
        UNION ALL
        SELECT 
            'Index Cache Hit Ratio' as metric,
            CASE 
                WHEN sum(idx_blks_hit + idx_blks_read) = 0 THEN 0
                ELSE round(sum(idx_blks_hit) * 100.0 / sum(idx_blks_hit + idx_blks_read), 2)
            END as percentage
        FROM pg_statio_user_indexes;
        " -t
        Write-Host $cacheStats -ForegroundColor White
        
        # Current PostgreSQL settings
        Write-Host "`n⚙️  Current Settings:" -ForegroundColor Cyan
        $settings = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT name, setting, unit 
        FROM pg_settings 
        WHERE name IN ('shared_buffers', 'effective_cache_size', 'work_mem', 'maintenance_work_mem', 'max_connections')
        ORDER BY name;
        " -t
        Write-Host $settings -ForegroundColor White
        
        # Table sizes (top 5)
        Write-Host "`n📋 Largest Tables:" -ForegroundColor Cyan
        $tableSizes = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
            pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
        FROM pg_tables 
        WHERE schemaname = 'public' 
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
        LIMIT 5;
        " -t
        Write-Host $tableSizes -ForegroundColor White
        
        # Active queries
        Write-Host "`n🔄 Active Queries:" -ForegroundColor Cyan
        $activeQueries = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT 
            pid,
            usename,
            application_name,
            state,
            round(extract(epoch from now() - query_start)) as duration_seconds,
            left(query, 80) as query_preview
        FROM pg_stat_activity 
        WHERE state != 'idle' AND datname = 'gameforge_dev' AND query != '<IDLE>'
        ORDER BY query_start;
        " -t
        
        if ($activeQueries.Trim()) {
            Write-Host $activeQueries -ForegroundColor White
        } else {
            Write-Host "  No active queries" -ForegroundColor Gray
        }
        
        # Index usage analysis
        Write-Host "`n📊 Index Usage Analysis:" -ForegroundColor Cyan
        $indexUsage = psql -h localhost -U postgres -d gameforge_dev -c "
        SELECT 
            schemaname,
            tablename,
            indexname,
            idx_tup_read as index_reads,
            idx_tup_fetch as index_fetches,
            CASE 
                WHEN idx_tup_read = 0 THEN 0
                ELSE round((idx_tup_fetch::numeric / idx_tup_read) * 100, 2)
            END as efficiency_percent
        FROM pg_stat_user_indexes 
        WHERE idx_tup_read > 0
        ORDER BY idx_tup_read DESC 
        LIMIT 10;
        " -t
        
        if ($indexUsage.Trim()) {
            Write-Host $indexUsage -ForegroundColor White
        } else {
            Write-Host "  No index usage data available" -ForegroundColor Gray
        }
        
        # Performance recommendations
        Write-Host "`n💡 Performance Recommendations:" -ForegroundColor Yellow
        
        # Extract cache hit ratio for analysis
        $bufferHitRatio = 0
        $indexHitRatio = 0
        
        try {
            $cacheLines = $cacheStats -split "`n"
            foreach ($line in $cacheLines) {
                if ($line -match "Buffer.*?(\d+\.?\d*)") {
                    $bufferHitRatio = [double]$matches[1]
                }
                if ($line -match "Index.*?(\d+\.?\d*)") {
                    $indexHitRatio = [double]$matches[1]
                }
            }
        } catch {
            Write-Host "  Could not parse cache statistics" -ForegroundColor Red
        }
        
        if ($bufferHitRatio -lt 95) {
            Write-Host "  ⚠️  Buffer cache hit ratio is ${bufferHitRatio}% (should be >95%)" -ForegroundColor Yellow
            Write-Host "     Consider increasing shared_buffers" -ForegroundColor Gray
        } else {
            Write-Host "  ✅ Buffer cache hit ratio is good (${bufferHitRatio}%)" -ForegroundColor Green
        }
        
        if ($indexHitRatio -lt 95) {
            Write-Host "  ⚠️  Index cache hit ratio is ${indexHitRatio}% (should be >95%)" -ForegroundColor Yellow
            Write-Host "     Consider increasing shared_buffers or effective_cache_size" -ForegroundColor Gray
        } else {
            Write-Host "  ✅ Index cache hit ratio is good (${indexHitRatio}%)" -ForegroundColor Green
        }
        
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "❌ Error collecting metrics: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
}

function Show-PerformanceOptimizationStatus {
    Write-Host "`n🔧 Applied Performance Optimizations:" -ForegroundColor Yellow
    
    try {
        $env:PGPASSWORD = "password"
        
        $currentSharedBuffers = psql -h localhost -U postgres -d postgres -c "SHOW shared_buffers;" -t | ForEach-Object { $_.Trim() }
        $currentEffectiveCache = psql -h localhost -U postgres -d postgres -c "SHOW effective_cache_size;" -t | ForEach-Object { $_.Trim() }
        $currentWorkMem = psql -h localhost -U postgres -d postgres -c "SHOW work_mem;" -t | ForEach-Object { $_.Trim() }
        $currentMaxConnections = psql -h localhost -U postgres -d postgres -c "SHOW max_connections;" -t | ForEach-Object { $_.Trim() }
        
        Write-Host "  shared_buffers: $currentSharedBuffers (target: 4GB)" -ForegroundColor $(if ($currentSharedBuffers -eq "4GB") { "Green" } else { "Yellow" })
        Write-Host "  effective_cache_size: $currentEffectiveCache (target: 12GB)" -ForegroundColor $(if ($currentEffectiveCache -eq "12GB") { "Green" } else { "Yellow" })
        Write-Host "  work_mem: $currentWorkMem (target: 64MB)" -ForegroundColor $(if ($currentWorkMem -eq "64MB") { "Green" } else { "Yellow" })
        Write-Host "  max_connections: $currentMaxConnections (target: 200)" -ForegroundColor $(if ($currentMaxConnections -eq "200") { "Green" } else { "Yellow" })
        
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "  ❌ Could not check current settings" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Enable pg_stat_statements if available
try {
    $env:PGPASSWORD = "password"
    $extensionCheck = psql -h localhost -U postgres -d gameforge_dev -c "SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements';" -t
    if (!$extensionCheck.Trim()) {
        Write-Host "`n🔧 Enabling pg_stat_statements for query analysis..." -ForegroundColor Yellow
        psql -h localhost -U postgres -d gameforge_dev -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" | Out-Null
        Write-Host "✅ pg_stat_statements enabled" -ForegroundColor Green
    }
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️  Could not enable pg_stat_statements extension" -ForegroundColor Yellow
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}

# Show current optimization status
Show-PerformanceOptimizationStatus

# Run monitoring
if ($Continuous) {
    Write-Host "`n🔄 Starting continuous monitoring (Ctrl+C to stop)..." -ForegroundColor Cyan
    Write-Host "Update interval: $IntervalSeconds seconds" -ForegroundColor Gray
    
    try {
        while ($true) {
            Get-DatabaseMetrics
            Start-Sleep -Seconds $IntervalSeconds
            Clear-Host
            Write-Host "📊 GameForge Database Performance Monitor (Continuous)" -ForegroundColor Green
            Write-Host "=====================================================" -ForegroundColor Green
            Write-Host "🕐 Last update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "`n⏹️  Monitoring stopped" -ForegroundColor Yellow
    }
} else {
    # Single run
    Get-DatabaseMetrics
}

Write-Host "`n🎯 Performance monitoring complete!" -ForegroundColor Green
Write-Host "`n💡 Tips:" -ForegroundColor Cyan
Write-Host "  - Run with -Continuous for real-time monitoring" -ForegroundColor White
Write-Host "  - Monitor cache hit ratios regularly (should be >95%)" -ForegroundColor White
Write-Host "  - Watch for long-running queries in Active Queries section" -ForegroundColor White
Write-Host "  - Consider connection pooling if max_connections is frequently reached" -ForegroundColor White