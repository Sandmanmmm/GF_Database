# GameForge Database Performance Monitor (Simple Version)

Write-Host "GameForge Database Performance Monitor" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Check PostgreSQL connection
try {
    $connectionTest = psql -h localhost -U postgres -d gameforge_dev -c "SELECT version();" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database Connection: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "Database Connection: FAILED" -ForegroundColor Red
        Write-Host "Error: $connectionTest" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Database Connection: ERROR - $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nCurrent Configuration:" -ForegroundColor Cyan
$configQuery = @"
SELECT 
    name,
    setting,
    unit,
    context
FROM pg_settings 
WHERE name IN (
    'shared_buffers', 
    'effective_cache_size', 
    'work_mem', 
    'maintenance_work_mem',
    'max_connections',
    'random_page_cost',
    'default_statistics_target'
)
ORDER BY name;
"@

psql -h localhost -U postgres -d gameforge_dev -c "$configQuery"

Write-Host "`nCache Performance:" -ForegroundColor Cyan
$cacheQuery = @"
SELECT 
    'Buffer Cache Hit Ratio' as metric,
    ROUND(
        (sum(heap_blks_hit) * 100.0 / 
         NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0)
        ), 2
    ) as percentage
FROM pg_statio_user_tables
UNION ALL
SELECT 
    'Index Cache Hit Ratio' as metric,
    ROUND(
        (sum(idx_blks_hit) * 100.0 / 
         NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0)
        ), 2
    ) as percentage
FROM pg_statio_user_indexes;
"@

psql -h localhost -U postgres -d gameforge_dev -c "$cacheQuery"

Write-Host "`nConnection Statistics:" -ForegroundColor Cyan
$connQuery = @"
SELECT 
    count(*) as total_connections,
    count(*) filter (where state = 'active') as active_connections,
    count(*) filter (where state = 'idle') as idle_connections
FROM pg_stat_activity 
WHERE datname = 'gameforge_dev';
"@

psql -h localhost -U postgres -d gameforge_dev -c "$connQuery"

Write-Host "`nDatabase Size Information:" -ForegroundColor Cyan
$sizeQuery = @"
SELECT 
    pg_size_pretty(pg_database_size('gameforge_dev')) as database_size,
    pg_size_pretty(pg_total_relation_size('users')) as users_table_size,
    pg_size_pretty(pg_total_relation_size('projects')) as projects_table_size;
"@

psql -h localhost -U postgres -d gameforge_dev -c "$sizeQuery"

Write-Host "`nTop 5 Largest Tables:" -ForegroundColor Cyan
$tablesQuery = @"
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 5;
"@

psql -h localhost -U postgres -d gameforge_dev -c "$tablesQuery"

Write-Host "`nIndex Usage Statistics:" -ForegroundColor Cyan
$indexQuery = @"
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE idx_tup_read > 0
ORDER BY idx_tup_read DESC 
LIMIT 10;
"@

psql -h localhost -U postgres -d gameforge_dev -c "$indexQuery"

Write-Host "`nPerformance Summary Complete" -ForegroundColor Green
Write-Host "Note: For shared_buffers changes to take full effect, PostgreSQL service restart may be required." -ForegroundColor Yellow