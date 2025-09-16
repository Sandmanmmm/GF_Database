Write-Host "=== PostgreSQL Status Check ===" -ForegroundColor Green

# Check PostgreSQL service
Write-Host "Checking PostgreSQL service..." -ForegroundColor Cyan
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
if ($pgService) {
    Write-Host "✓ PostgreSQL service: $($pgService.Name) - $($pgService.Status)" -ForegroundColor Green
} else {
    Write-Host "✗ PostgreSQL service not found" -ForegroundColor Red
}

# Check port 5433
Write-Host "Checking port 5433..." -ForegroundColor Cyan
$test5433 = Test-NetConnection -ComputerName localhost -Port 5433 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($test5433) {
    Write-Host "✓ Port 5433 is listening" -ForegroundColor Green
} else {
    Write-Host "✗ Port 5433 not responding" -ForegroundColor Red
}

# Check port 5432
Write-Host "Checking port 5432..." -ForegroundColor Cyan
$test5432 = Test-NetConnection -ComputerName localhost -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($test5432) {
    Write-Host "✓ Port 5432 is listening" -ForegroundColor Green
} else {
    Write-Host "✗ Port 5432 not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Use pgAdmin 4 to set postgres password"
Write-Host "2. Run setup-gameforge-final.ps1"