# PostgreSQL Password Setup Script
# This script helps set up the postgres superuser password

Write-Host "Setting up PostgreSQL authentication..." -ForegroundColor Cyan

# Try connecting without password first (might work with peer authentication)
Write-Host "Attempting to connect to PostgreSQL..." -ForegroundColor Yellow

try {
    # Try to connect and set password
    $sqlCommands = @"
-- Set password for postgres superuser
ALTER USER postgres PASSWORD 'postgres123';

-- Create gameforge database and user
CREATE DATABASE gameforge_dev;
CREATE USER gameforge_user WITH PASSWORD 'securepassword';
GRANT ALL PRIVILEGES ON DATABASE gameforge_dev TO gameforge_user;

-- Show success message
SELECT 'PostgreSQL setup completed successfully!' as status;
"@

    # Save SQL commands to temp file
    $tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $sqlCommands | Out-File -FilePath $tempFile -Encoding UTF8

    Write-Host "Executing setup commands..." -ForegroundColor Yellow
    
    # Try multiple connection methods
    $connectionMethods = @(
        @{Args = @("-U", "postgres", "-d", "postgres", "-f", $tempFile)},
        @{Args = @("-U", "$env:USERNAME", "-d", "postgres", "-f", $tempFile)},
        @{Args = @("-d", "postgres", "-f", $tempFile)}
    )

    $success = $false
    foreach ($method in $connectionMethods) {
        try {
            Write-Host "Trying connection method: $($method.Args -join ' ')" -ForegroundColor Gray
            & psql @($method.Args) 2>&1 | Out-Host
            
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                Write-Host "Successfully connected and configured PostgreSQL!" -ForegroundColor Green
                break
            }
        }
        catch {
            Write-Host "Connection method failed: $_" -ForegroundColor Red
        }
    }

    # Clean up temp file
    Remove-Item $tempFile -ErrorAction SilentlyContinue

    if ($success) {
        Write-Host ""
        Write-Host "PostgreSQL Configuration Complete!" -ForegroundColor Green
        Write-Host "postgres superuser password: postgres123" -ForegroundColor Yellow
        Write-Host "gameforge_user password: securepassword" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Test connection:" -ForegroundColor Cyan
        Write-Host "psql -U gameforge_user -h localhost -d gameforge_dev" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "Automatic setup failed. Manual setup required:" -ForegroundColor Red
        Write-Host "1. Find your PostgreSQL installation directory" -ForegroundColor Yellow
        Write-Host "2. Look for pg_hba.conf file (usually in data directory)" -ForegroundColor Yellow
        Write-Host "3. Modify authentication method or set password manually" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Setup failed: $_" -ForegroundColor Red
}