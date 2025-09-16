# PostgreSQL Service Restart Script
# Run this script as Administrator to apply shared_buffers and max_connections changes

Write-Host "PostgreSQL Service Restart for Configuration Changes" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

Write-Host "This script must be run as Administrator to restart the PostgreSQL service." -ForegroundColor Yellow
Write-Host "Current configuration changes requiring restart:" -ForegroundColor Cyan
Write-Host "  - shared_buffers: 128MB -> 4GB" -ForegroundColor White
Write-Host "  - max_connections: 100 -> 200" -ForegroundColor White

# Check if running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`nERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "`nStopping PostgreSQL service..." -ForegroundColor Yellow
    Stop-Service postgresql-x64-17 -Force
    
    Write-Host "Starting PostgreSQL service..." -ForegroundColor Yellow
    Start-Service postgresql-x64-17
    
    Write-Host "PostgreSQL service restarted successfully!" -ForegroundColor Green
    
    # Wait a moment for service to fully start
    Start-Sleep -Seconds 5
    
    # Verify the changes took effect
    Write-Host "`nVerifying configuration changes..." -ForegroundColor Cyan
    $result = psql -h localhost -U postgres -d gameforge_dev -c "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers', 'max_connections');"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Configuration verification:" -ForegroundColor Green
        Write-Host $result
    } else {
        Write-Host "Could not verify configuration. Please check database connection." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error restarting PostgreSQL service: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nConfiguration changes applied successfully!" -ForegroundColor Green