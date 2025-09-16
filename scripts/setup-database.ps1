# GameForge PostgreSQL Development Setup Script
# PowerShell Script for Windows Development Environment
# Requires: PowerShell 5.1+ and Administrator privileges

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$CreateDatabase,
    [switch]$Setup,
    [switch]$Test,
    [switch]$All,
    [string]$PostgreSQLVersion = "16",
    [string]$DatabaseName = "gameforge_dev",
    [string]$Username = "gameforge_user",
    [string]$Password = "securepassword",
    [string]$SuperUser = "postgres",
    [string]$SuperUserPassword = "",
    [string]$Port = "5432",
    [string]$DatabaseHost = "localhost"
)

# Color output functions
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

# Check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install PostgreSQL using winget or Chocolatey
function Install-PostgreSQL {
    Write-Info "Installing PostgreSQL $PostgreSQLVersion..."
    
    if (-not (Test-IsAdmin)) {
        Write-Error "Administrator privileges required for PostgreSQL installation"
        Write-Info "Please run PowerShell as Administrator and try again"
        return $false
    }
    
    # Try winget first (Windows 10 1709+ / Windows 11)
    try {
        $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetAvailable) {
            Write-Info "Installing PostgreSQL via winget..."
            winget install --id PostgreSQL.PostgreSQL --version $PostgreSQLVersion --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "PostgreSQL installed successfully via winget"
                return $true
            }
        }
    }
    catch {
        Write-Warning "winget installation failed, trying Chocolatey..."
    }
    
    # Try Chocolatey as fallback
    try {
        $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoAvailable) {
            Write-Info "Installing PostgreSQL via Chocolatey..."
            choco install postgresql$PostgreSQLVersion --yes --force
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "PostgreSQL installed successfully via Chocolatey"
                return $true
            }
        } else {
            Write-Warning "Chocolatey not available. Installing Chocolatey first..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            Write-Info "Installing PostgreSQL via Chocolatey..."
            choco install postgresql$PostgreSQLVersion --yes --force
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "PostgreSQL installed successfully via Chocolatey"
                return $true
            }
        }
    }
    catch {
        Write-Error "Failed to install PostgreSQL via Chocolatey: $_"
    }
    
    # Manual installation instructions
    Write-Error "Automated installation failed. Please install PostgreSQL manually:"
    Write-Info "1. Download PostgreSQL $PostgreSQLVersion from: https://www.postgresql.org/download/windows/"
    Write-Info "2. Run the installer and follow the setup wizard"
    Write-Info "3. Make note of the superuser password you set during installation"
    Write-Info "4. Ensure PostgreSQL service is running"
    Write-Info "5. Add PostgreSQL bin directory to your PATH environment variable"
    
    return $false
}

# Test PostgreSQL connection
function Test-PostgreSQLConnection {
    param(
        [string]$TestUser = $SuperUser,
        [string]$TestPassword = $SuperUserPassword,
        [string]$TestDatabase = "postgres"
    )
    
    Write-Info "Testing PostgreSQL connection..."
    
    # Set PGPASSWORD environment variable for authentication
    if ($TestPassword) {
        $env:PGPASSWORD = $TestPassword
    }
    
    try {
        $result = psql -U $TestUser -h $DatabaseHost -p $Port -d $TestDatabase -c "SELECT version();" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL connection successful"
            Write-Info "Version: $($result | Select-String 'PostgreSQL')"
            return $true
        } else {
            Write-Error "PostgreSQL connection failed: $result"
            return $false
        }
    }
    catch {
        Write-Error "Failed to test PostgreSQL connection: $_"
        return $false
    }
    finally {
        # Clear password from environment
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Create database and user
function New-GameForgeDatabase {
    Write-Info "Creating GameForge database and user..."
    
    if (-not $SuperUserPassword) {
        $SuperUserPassword = Read-Host "Enter PostgreSQL superuser ($SuperUser) password" -AsSecureString
        $SuperUserPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SuperUserPassword))
    }
    
    # Set password for psql
    $env:PGPASSWORD = $SuperUserPassword
    
    try {
        # Create database
        Write-Info "Creating database: $DatabaseName"
        $createDbResult = psql -U $SuperUser -h $DatabaseHost -p $Port -d postgres -c "CREATE DATABASE $DatabaseName;" 2>&1
        
        if ($LASTEXITCODE -ne 0 -and $createDbResult -notmatch "already exists") {
            Write-Error "Failed to create database: $createDbResult"
            return $false
        }
        
        # Create user
        Write-Info "Creating user: $Username"
        $createUserResult = psql -U $SuperUser -h $DatabaseHost -p $Port -d postgres -c "CREATE USER $Username WITH PASSWORD '$Password';" 2>&1
        
        if ($LASTEXITCODE -ne 0 -and $createUserResult -notmatch "already exists") {
            Write-Error "Failed to create user: $createUserResult"
            return $false
        }
        
        # Grant privileges
        Write-Info "Granting privileges to user: $Username"
        $grantResult = psql -U $SuperUser -h $DatabaseHost -p $Port -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DatabaseName TO $Username;" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to grant privileges: $grantResult"
            return $false
        }
        
        Write-Success "Database and user created successfully"
        return $true
    }
    catch {
        Write-Error "Failed to create database: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Apply database schema
function Initialize-GameForgeSchema {
    Write-Info "Applying GameForge database schema..."
    
    $schemaPath = Join-Path $PSScriptRoot "..\schema.sql"
    
    if (-not (Test-Path $schemaPath)) {
        Write-Error "Schema file not found: $schemaPath"
        return $false
    }
    
    # Set password for psql
    $env:PGPASSWORD = $Password
    
    try {
        Write-Info "Executing schema.sql..."
        $schemaResult = psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName -f $schemaPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database schema applied successfully"
            return $true
        } else {
            Write-Error "Failed to apply schema: $schemaResult"
            return $false
        }
    }
    catch {
        Write-Error "Failed to apply schema: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Create sample data
function New-SampleData {
    Write-Info "Creating sample data..."
    
    $sampleDataPath = Join-Path $PSScriptRoot "..\sample-data.sql"
    
    if (Test-Path $sampleDataPath) {
        $env:PGPASSWORD = $Password
        
        try {
            $sampleResult = psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName -f $sampleDataPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Sample data created successfully"
                return $true
            } else {
                Write-Warning "Failed to create sample data: $sampleResult"
                return $false
            }
        }
        catch {
            Write-Warning "Failed to create sample data: $_"
            return $false
        }
        finally {
            Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        }
    } else {
        Write-Info "No sample data file found, skipping..."
        return $true
    }
}

# Test database connectivity and basic operations
function Test-GameForgeDatabase {
    Write-Info "Testing GameForge database..."
    
    $env:PGPASSWORD = $Password
    
    try {
        # Test connection
        Write-Info "Testing database connection..."
        $connResult = psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName -c "SELECT current_database(), current_user, version();" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Database connection test failed: $connResult"
            return $false
        }
        
        # Test table creation
        Write-Info "Testing table access..."
        $tableResult = psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName -c "\dt" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Table access test failed: $tableResult"
            return $false
        }
        
        # Test basic operations
        Write-Info "Testing basic operations..."
        $testQueries = @(
            "SELECT COUNT(*) FROM users;",
            "SELECT COUNT(*) FROM projects;",
            "SELECT COUNT(*) FROM system_config;"
        )
        
        foreach ($query in $testQueries) {
            $queryResult = psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName -c $query 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Query test failed: $query - $queryResult"
                return $false
            }
        }
        
        Write-Success "All database tests passed"
        return $true
    }
    catch {
        Write-Error "Database testing failed: $_"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Create .env file for database configuration
function New-DatabaseConfig {
    Write-Info "Creating database configuration files..."
    
    $envContent = @"
# GameForge Database Configuration
# Development Environment

# Database Connection
DATABASE_URL=postgresql://$Username`:$Password@$DatabaseHost`:$Port/$DatabaseName
DB_HOST=$DatabaseHost
DB_PORT=$Port
DB_NAME=$DatabaseName
DB_USER=$Username
DB_PASSWORD=$Password

# Connection Pool Settings
DB_POOL_SIZE=20
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600

# SSL Settings (Development)
DB_SSL_MODE=prefer

# Migrations
MIGRATE_URL=postgresql://$Username`:$Password@$Host`:$Port/$DatabaseName

# Backup Settings
BACKUP_RETENTION_DAYS=30
"@
    
    $envPath = Join-Path $PSScriptRoot "..\.env.database"
    $envContent | Out-File -FilePath $envPath -Encoding UTF8
    
    Write-Success "Database configuration saved to: $envPath"
    Write-Warning "Remember to add .env.database to your .gitignore file"
}

# Display connection information
function Show-ConnectionInfo {
    Write-Info "=== GameForge Database Connection Information ==="
    Write-Host "Host: $DatabaseHost" -ForegroundColor White
    Write-Host "Port: $Port" -ForegroundColor White
    Write-Host "Database: $DatabaseName" -ForegroundColor White
    Write-Host "Username: $Username" -ForegroundColor White
    Write-Host "Password: $Password" -ForegroundColor White
    Write-Host ""
    Write-Info "Connection String:"
    Write-Host "postgresql://$Username`:$Password@$DatabaseHost`:$Port/$DatabaseName" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "psql Command:"
    Write-Host "psql -U $Username -h $DatabaseHost -p $Port -d $DatabaseName" -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
function Main {
    Write-Info "=== GameForge PostgreSQL Setup ==="
    Write-Info "Starting PostgreSQL development environment setup..."
    
    # Check prerequisites
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        if ($Install -or $All) {
            if (-not (Install-PostgreSQL)) {
                Write-Error "PostgreSQL installation failed. Please install manually and rerun this script."
                exit 1
            }
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Wait for service to start
            Write-Info "Waiting for PostgreSQL service to start..."
            Start-Sleep -Seconds 10
        } else {
            Write-Error "PostgreSQL (psql) not found in PATH. Please install PostgreSQL or use -Install flag."
            exit 1
        }
    }
    
    # Test initial connection
    if (-not (Test-PostgreSQLConnection)) {
        if (-not $SuperUserPassword) {
            Write-Warning "Please ensure PostgreSQL is running and you have the superuser password"
        }
    }
    
    # Create database and user
    if ($CreateDatabase -or $Setup -or $All) {
        if (-not (New-GameForgeDatabase)) {
            Write-Error "Failed to create database and user"
            exit 1
        }
    }
    
    # Apply schema
    if ($Setup -or $All) {
        if (-not (Initialize-GameForgeSchema)) {
            Write-Error "Failed to apply database schema"
            exit 1
        }
        
        # Create sample data
        New-SampleData | Out-Null
        
        # Create configuration files
        New-DatabaseConfig
    }
    
    # Test database
    if ($Test -or $All) {
        if (-not (Test-GameForgeDatabase)) {
            Write-Error "Database testing failed"
            exit 1
        }
    }
    
    # Show connection info
    Show-ConnectionInfo
    
    Write-Success "GameForge PostgreSQL setup completed successfully!"
    Write-Info "Next steps:"
    Write-Host "1. Update your application configuration with the database connection details" -ForegroundColor Cyan
    Write-Host "2. Install required dependencies (psycopg2, SQLAlchemy, etc.)" -ForegroundColor Cyan
    Write-Host "3. Test database connectivity from your application" -ForegroundColor Cyan
}

# Parameter handling
if ($All) {
    $Install = $true
    $CreateDatabase = $true
    $Setup = $true
    $Test = $true
}

# Validate parameters
if (-not ($Install -or $CreateDatabase -or $Setup -or $Test -or $All)) {
    Write-Host ""
    Write-Host "GameForge PostgreSQL Setup Script" -ForegroundColor Green
    Write-Host "Usage: .\setup-database.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Install              Install PostgreSQL using winget/chocolatey" -ForegroundColor White
    Write-Host "  -CreateDatabase       Create gameforge_dev database and user" -ForegroundColor White
    Write-Host "  -Setup                Apply schema and create configuration" -ForegroundColor White
    Write-Host "  -Test                 Test database connectivity and operations" -ForegroundColor White
    Write-Host "  -All                  Perform all above operations" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -PostgreSQLVersion    PostgreSQL version to install (default: 16)" -ForegroundColor White
    Write-Host "  -DatabaseName         Database name (default: gameforge_dev)" -ForegroundColor White
    Write-Host "  -Username             Database username (default: gameforge_user)" -ForegroundColor White
    Write-Host "  -Password             Database password (default: securepassword)" -ForegroundColor White
    Write-Host "  -SuperUser            PostgreSQL superuser (default: postgres)" -ForegroundColor White
    Write-Host "  -SuperUserPassword    Superuser password (will prompt if not provided)" -ForegroundColor White
    Write-Host "  -DatabaseHost         Database host (default: localhost)" -ForegroundColor White
    Write-Host "  -Port                 Database port (default: 5432)" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\setup-database.ps1 -All" -ForegroundColor Cyan
    Write-Host "  .\setup-database.ps1 -Install -CreateDatabase -Setup" -ForegroundColor Cyan
    Write-Host "  .\setup-database.ps1 -Test" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Setup failed with error: $_"
    exit 1
}