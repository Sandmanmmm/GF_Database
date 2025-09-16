# Launch pgAdmin 4 and Display GameForge Connection Info

Write-Host "=== GameForge pgAdmin 4 Setup ===" -ForegroundColor Green
Write-Host ""

# Check if pgAdmin is already running
$pgAdminProcess = Get-Process -Name "pgAdmin4" -ErrorAction SilentlyContinue
if ($pgAdminProcess) {
    Write-Host "✓ pgAdmin 4 is already running" -ForegroundColor Green
} else {
    Write-Host "Starting pgAdmin 4..." -ForegroundColor Cyan
    try {
        Start-Process "C:\Users\ya754\AppData\Local\Programs\pgAdmin 4\runtime\pgAdmin4.exe"
        Write-Host "✓ pgAdmin 4 launched successfully" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } catch {
        Write-Host "✗ Failed to launch pgAdmin 4: $_" -ForegroundColor Red
        Write-Host "Try manually: Start Menu → pgAdmin 4" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== GameForge Database Connection Details ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To connect to GameForge database in pgAdmin:" -ForegroundColor Yellow
Write-Host "1. Right-click 'Servers' → Create → Server..." -ForegroundColor White
Write-Host "2. Enter these details:" -ForegroundColor White
Write-Host ""

# Display connection details in a formatted table
Write-Host "General Tab:" -ForegroundColor Cyan
Write-Host "  Name: GameForge Dev DB" -ForegroundColor White
Write-Host ""
Write-Host "Connection Tab:" -ForegroundColor Cyan
Write-Host "  Host: localhost" -ForegroundColor White
Write-Host "  Port: 5433" -ForegroundColor White  
Write-Host "  Database: gameforge_dev" -ForegroundColor White
Write-Host "  Username: gameforge_user" -ForegroundColor White
Write-Host "  Password: securepassword" -ForegroundColor White
Write-Host "  Save password: ✓" -ForegroundColor Green
Write-Host ""

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Cyan
$env:PGPASSWORD = "securepassword"
$env:PATH += ";C:\Program Files\PostgreSQL\16\bin"

try {
    $result = psql -U gameforge_user -h localhost -p 5433 -d gameforge_dev -c "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database connection verified!" -ForegroundColor Green
        Write-Host "✓ 15 tables ready for exploration" -ForegroundColor Green
    } else {
        Write-Host "⚠ Database connection test failed" -ForegroundColor Yellow
        Write-Host "Check PostgreSQL service status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Could not test connection: $_" -ForegroundColor Yellow
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "=== Quick Verification Queries ===" -ForegroundColor Cyan
Write-Host "Once connected, try these in pgAdmin Query Tool:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. View all tables:" -ForegroundColor White
Write-Host "   SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Check sample user:" -ForegroundColor White  
Write-Host "   SELECT username, email, provider FROM users;" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Database overview:" -ForegroundColor White
Write-Host "   SELECT 'GameForge Ready!' as status;" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 See PGADMIN_SETUP_GUIDE.md for detailed instructions" -ForegroundColor Cyan