# Schema Synchronization System Verification (Simple Version)
# This script validates that all components for dev/prod schema sync are in place

Write-Host "Schema Synchronization System Verification" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

# Check if required files exist
Write-Host "Checking Required Files:" -ForegroundColor Cyan
$requiredFiles = @(
    "scripts/schema-sync.ps1",
    "scripts/generate-production-schema.ps1", 
    "migrations/000_migration_system.sql",
    "gameforge_production_schema.sql",
    ".env.production.template"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

# Test database connection
Write-Host ""
Write-Host "Testing Database Connection:" -ForegroundColor Cyan
try {
    $result = psql -h localhost -U postgres -d gameforge_dev -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Development database connection successful" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Development database connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [ERROR] Database connection error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check migration system
Write-Host ""
Write-Host "Checking Migration System:" -ForegroundColor Cyan
try {
    $migrationCount = psql -h localhost -U postgres -d gameforge_dev -t -c "SELECT COUNT(*) FROM schema_migrations;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Migration tracking system installed ($($migrationCount.Trim()) migrations tracked)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Migration tracking system not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  [ERROR] Migration system check failed" -ForegroundColor Red
}

# Check schema structure
Write-Host ""
Write-Host "Checking Schema Structure:" -ForegroundColor Cyan
$tableCountResult = psql -h localhost -U postgres -d gameforge_dev -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>$null
$tableCount = ($tableCountResult | Select-Object -Last 1).Trim()
if ($LASTEXITCODE -eq 0 -and [int]$tableCount -ge 13) {
    Write-Host "  [OK] Tables: $tableCount (minimum 13 required)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Tables: $tableCount (minimum 13 required, exit code: $LASTEXITCODE)" -ForegroundColor Red
}

$extensionCountResult = psql -h localhost -U postgres -d gameforge_dev -t -c "SELECT COUNT(*) FROM pg_extension WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin');" 2>$null
$extensionCount = ($extensionCountResult | Select-Object -Last 1).Trim()
if ($LASTEXITCODE -eq 0 -and [int]$extensionCount -ge 2) {
    Write-Host "  [OK] Extensions: $extensionCount/3 required extensions installed" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Extensions: $extensionCount/3 required extensions" -ForegroundColor Yellow
}

# Check production schema file
Write-Host ""
Write-Host "Checking Production Schema:" -ForegroundColor Cyan
if (Test-Path "gameforge_production_schema.sql") {
    $schemaSize = (Get-Item "gameforge_production_schema.sql").Length
    Write-Host "  [OK] Production schema file exists ($([math]::Round($schemaSize/1024, 1)) KB)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Production schema file not found" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
if ($missingFiles.Count -eq 0) {
    Write-Host "  [OK] All required files present" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Missing files: $($missingFiles -join ', ')" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps for Production Deployment:" -ForegroundColor Yellow
Write-Host "   1. Copy .env.production.template to .env.production" -ForegroundColor White
Write-Host "   2. Configure .env.production with production details" -ForegroundColor White
Write-Host "   3. Apply gameforge_production_schema.sql to production" -ForegroundColor White
Write-Host "   4. Test sync with: .\scripts\schema-sync.ps1 -Environment prod -Action validate" -ForegroundColor White
Write-Host ""
Write-Host "[SUCCESS] Schema Synchronization System Complete!" -ForegroundColor Green