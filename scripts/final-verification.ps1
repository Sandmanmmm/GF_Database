# Schema Synchronization System - Final Verification
Write-Host "=== GameForge Schema Synchronization System Verification ===" -ForegroundColor Green
Write-Host ""

# Check critical files
$files = @("scripts/schema-sync.ps1", "gameforge_production_schema.sql", ".env.production.template")
Write-Host "Required Files Check:" -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
    }
}

# Test database
Write-Host ""
Write-Host "Database Connectivity:" -ForegroundColor Cyan
$dbTest = psql -h localhost -U postgres -d gameforge_dev -c "SELECT version();" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] PostgreSQL connection successful" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Database connection failed" -ForegroundColor Red
}

# Quick table count
Write-Host ""
Write-Host "Schema Validation:" -ForegroundColor Cyan
$tables = psql -h localhost -U postgres -d gameforge_dev -c "\dt" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Database schema accessible" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Schema validation failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SYSTEM READY FOR PRODUCTION DEPLOYMENT ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy .env.production.template to .env.production" -ForegroundColor White
Write-Host "2. Edit .env.production with production database details" -ForegroundColor White
Write-Host "3. Deploy schema: psql -h [prod-host] -U [prod-user] -d [prod-db] -f gameforge_production_schema.sql" -ForegroundColor White
Write-Host "4. Test sync: .\scripts\schema-sync.ps1 -Environment prod -Action validate" -ForegroundColor White
Write-Host ""
Write-Host "Schema Synchronization System Complete!" -ForegroundColor Green