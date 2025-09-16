# GameForge Database Setup - Final Step
# Run this AFTER setting postgres password in pgAdmin

param(
    [string]$PostgresPassword = "postgres123",
    [string]$Port = "5433"
)

Write-Host "=== GameForge Database Final Setup ===" -ForegroundColor Green
Write-Host "This script assumes postgres password has been set to: $PostgresPassword" -ForegroundColor Yellow
Write-Host ""

# Set environment for PostgreSQL
$env:PGPASSWORD = $PostgresPassword

try {
    # Test postgres connection
    Write-Host "Testing postgres connection..." -ForegroundColor Cyan
    $testResult = psql -U postgres -h localhost -p $Port -d postgres -c "SELECT version();" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Cannot connect to PostgreSQL. Please ensure:" -ForegroundColor Red
        Write-Host "1. PostgreSQL service is running" -ForegroundColor Yellow
        Write-Host "2. postgres user password is set to: $PostgresPassword" -ForegroundColor Yellow
        Write-Host "3. Use pgAdmin to set the password first" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✓ Connected to PostgreSQL successfully" -ForegroundColor Green
    
    # Create database and user
    Write-Host "Creating GameForge database and user..." -ForegroundColor Cyan
    
    $setupSQL = @"
-- Create database
CREATE DATABASE gameforge_dev;

-- Create user
CREATE USER gameforge_user WITH PASSWORD 'securepassword';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user;

-- Show success
SELECT 'GameForge database setup completed!' as status;
"@
    
    $tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $setupSQL | Out-File -FilePath $tempFile -Encoding UTF8
    
    $result = psql -U postgres -h localhost -p $Port -d postgres -f $tempFile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database and user created successfully" -ForegroundColor Green
        
        # Apply schema
        Write-Host "Applying GameForge schema..." -ForegroundColor Cyan
        $env:PGPASSWORD = "securepassword"
        
        $schemaPath = Join-Path $PSScriptRoot "..\schema.sql"
        $schemaResult = psql -U gameforge_user -h localhost -p $Port -d gameforge_dev -f $schemaPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Schema applied successfully" -ForegroundColor Green
            
            # Apply sample data
            Write-Host "Loading sample data..." -ForegroundColor Cyan
            $samplePath = Join-Path $PSScriptRoot "..\sample-data.sql"
            $sampleResult = psql -U gameforge_user -h localhost -p $Port -d gameforge_dev -f $samplePath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Sample data loaded successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠ Sample data loading failed (not critical)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Schema application failed" -ForegroundColor Red
            Write-Host $schemaResult
        }
    } else {
        Write-Host "✗ Database creation failed" -ForegroundColor Red
        Write-Host $result
    }
    
    # Clean up
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    # Test final connection
    Write-Host ""
    Write-Host "Testing GameForge database connection..." -ForegroundColor Cyan
    $testGameForge = psql -U gameforge_user -h localhost -p $Port -d gameforge_dev -c "SELECT COUNT(*) FROM users;" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ GameForge database is ready!" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== Connection Information ===" -ForegroundColor Cyan
        Write-Host "Host: localhost" -ForegroundColor White
        Write-Host "Port: $Port" -ForegroundColor White
        Write-Host "Database: gameforge_dev" -ForegroundColor White
        Write-Host "Username: gameforge_user" -ForegroundColor White
        Write-Host "Password: securepassword" -ForegroundColor White
        Write-Host ""
        Write-Host "Connection String:" -ForegroundColor Cyan
        Write-Host "postgresql://gameforge_user:securepassword@localhost:$Port/gameforge_dev" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Test Command:" -ForegroundColor Cyan
        Write-Host "psql -U gameforge_user -h localhost -p $Port -d gameforge_dev" -ForegroundColor Yellow
    } else {
        Write-Host "✗ GameForge database test failed" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Setup failed: $_" -ForegroundColor Red
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}