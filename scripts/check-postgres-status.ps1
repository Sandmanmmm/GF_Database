# Quick PostgreSQL Status Check

Write-Host "=== PostgreSQL Status Check ===" -ForegroundColor Green

# Check if PostgreSQL service is running
Write-Host "Checking PostgreSQL service..." -ForegroundColor Cyan
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
if ($pgService) {
    Write-Host "[OK] PostgreSQL service found: $($pgService.Name) - Status: $($pgService.Status)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] PostgreSQL service not found" -ForegroundColor Red
}

# Check port 5433
Write-Host "Checking port 5433..." -ForegroundColor Cyan
$connection = Test-NetConnection -ComputerName localhost -Port 5433 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($connection) {
    Write-Host "[OK] Port 5433 is listening" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Port 5433 is not responding" -ForegroundColor Red
}

# Check port 5432
Write-Host "Checking port 5432..." -ForegroundColor Cyan
$connection2 = Test-NetConnection -ComputerName localhost -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($connection2) {
    Write-Host "[OK] Port 5432 is listening" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Port 5432 is not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Use pgAdmin 4 to set postgres user password"
Write-Host "2. Right-click 'PostgreSQL 16' in pgAdmin"
Write-Host "3. Go to Properties > Definition"
Write-Host "4. Set password to: postgres123"
Write-Host "5. Run setup-gameforge-final.ps1"
Write-Host ""
Write-Host "Alternative: Follow POSTGRESQL_SETUP_GUIDE.md for detailed instructions"
