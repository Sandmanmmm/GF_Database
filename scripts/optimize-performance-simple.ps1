# GameForge Database Performance Optimization (Simplified)
# Applies optimized PostgreSQL settings based on system specifications

param(
    [Parameter(Mandatory=$false)]
    [switch]$ApplyChanges,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode
)

Write-Host "🚀 GameForge Database Performance Optimization" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Detect system specifications
Write-Host "`n🔍 Detecting system specifications..." -ForegroundColor Yellow

$TotalRAMGB = 16
$CPUCores = 4

try {
    $TotalRAMGB = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object { [math]::Round($_.Sum / 1GB, 2) }
    $CPUCores = (Get-WmiObject Win32_Processor | Select-Object -First 1).NumberOfCores
    Write-Host "✅ Detected: ${TotalRAMGB}GB RAM, ${CPUCores} CPU cores" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Using defaults: ${TotalRAMGB}GB RAM, ${CPUCores} cores" -ForegroundColor Yellow
}

# Calculate optimal settings
$sharedBuffersGB = [math]::Max(1, [math]::Round($TotalRAMGB * 0.25, 1))
$effectiveCacheSizeGB = [math]::Max(2, [math]::Round($TotalRAMGB * 0.75, 1))
$workMemMB = if ($ProductionMode) { [math]::Max(16, [math]::Round((($TotalRAMGB * 1024) / $CPUCores) / 4, 0)) } else { 16 }
$maintenanceWorkMemMB = [math]::Max(256, [math]::Round($TotalRAMGB * 32, 0))
$maxConnections = if ($ProductionMode) { 200 } else { 100 }

Write-Host "`n📊 Calculated Settings:" -ForegroundColor Cyan
Write-Host "  shared_buffers: ${sharedBuffersGB}GB" -ForegroundColor White
Write-Host "  effective_cache_size: ${effectiveCacheSizeGB}GB" -ForegroundColor White
Write-Host "  work_mem: ${workMemMB}MB" -ForegroundColor White
Write-Host "  maintenance_work_mem: ${maintenanceWorkMemMB}MB" -ForegroundColor White
Write-Host "  max_connections: $maxConnections" -ForegroundColor White

# Check current settings
Write-Host "`n🔍 Current PostgreSQL Configuration:" -ForegroundColor Yellow
try {
    $env:PGPASSWORD = "password"
    
    $currentSharedBuffers = psql -h localhost -U postgres -d postgres -c "SHOW shared_buffers;" -t | ForEach-Object { $_.Trim() }
    $currentEffectiveCache = psql -h localhost -U postgres -d postgres -c "SHOW effective_cache_size;" -t | ForEach-Object { $_.Trim() }
    $currentWorkMem = psql -h localhost -U postgres -d postgres -c "SHOW work_mem;" -t | ForEach-Object { $_.Trim() }
    $currentMaxConnections = psql -h localhost -U postgres -d postgres -c "SHOW max_connections;" -t | ForEach-Object { $_.Trim() }
    
    Write-Host "  shared_buffers: $currentSharedBuffers" -ForegroundColor Gray
    Write-Host "  effective_cache_size: $currentEffectiveCache" -ForegroundColor Gray
    Write-Host "  work_mem: $currentWorkMem" -ForegroundColor Gray
    Write-Host "  max_connections: $currentMaxConnections" -ForegroundColor Gray
    
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
} catch {
    Write-Host "❌ Could not connect to PostgreSQL" -ForegroundColor Red
}

# Apply changes if requested
if ($ApplyChanges) {
    Write-Host "`n🔧 Applying Configuration Changes..." -ForegroundColor Yellow
    
    try {
        $env:PGPASSWORD = "password"
        
        Write-Host "📝 Applying memory settings..." -ForegroundColor Cyan
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET shared_buffers = '${sharedBuffersGB}GB';"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET effective_cache_size = '${effectiveCacheSizeGB}GB';"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET work_mem = '${workMemMB}MB';"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET maintenance_work_mem = '${maintenanceWorkMemMB}MB';"
        
        Write-Host "🔗 Applying connection settings..." -ForegroundColor Cyan
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET max_connections = $maxConnections;"
        
        Write-Host "⚡ Applying performance settings..." -ForegroundColor Cyan
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET checkpoint_completion_target = 0.9;"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET random_page_cost = 1.1;"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET default_statistics_target = 1000;"
        
        Write-Host "📊 Applying monitoring settings..." -ForegroundColor Cyan
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_min_duration_statement = '1000ms';"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_checkpoints = on;"
        $null = psql -h localhost -U postgres -d postgres -c "ALTER SYSTEM SET log_lock_waits = on;"
        
        Write-Host "🔄 Reloading configuration..." -ForegroundColor Cyan
        $null = psql -h localhost -U postgres -d postgres -c "SELECT pg_reload_conf();"
        
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
        Write-Host "✅ Configuration changes applied successfully!" -ForegroundColor Green
        Write-Host "⚠️  PostgreSQL restart required for shared_buffers change" -ForegroundColor Yellow
        
    } catch {
        Write-Host "❌ Failed to apply changes: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "`n💡 To apply these settings, run:" -ForegroundColor Yellow
    Write-Host "   .\optimize-performance-simple.ps1 -ApplyChanges -ProductionMode" -ForegroundColor Gray
}

Write-Host "`n🏊 Connection Pooling Recommendations:" -ForegroundColor Yellow
Write-Host "  Application-level pooling recommended:" -ForegroundColor Cyan
Write-Host "  - Pool size: 20-30 connections" -ForegroundColor White
Write-Host "  - Max overflow: 10-20 connections" -ForegroundColor White
Write-Host "  - Pool recycle: 3600 seconds" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
if ($ApplyChanges) {
    Write-Host "1. Restart PostgreSQL: Restart-Service postgresql-x64-17" -ForegroundColor White
    Write-Host "2. Verify settings with SHOW commands" -ForegroundColor White
    Write-Host "3. Monitor performance improvements" -ForegroundColor White
} else {
    Write-Host "1. Review calculated settings above" -ForegroundColor White
    Write-Host "2. Run with -ApplyChanges to implement" -ForegroundColor White
    Write-Host "3. Restart PostgreSQL after applying" -ForegroundColor White
}

Write-Host "`n🎯 Optimization complete!" -ForegroundColor Green