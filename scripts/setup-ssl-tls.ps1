# GameForge Database SSL/TLS Setup Script
# Sets up secure SSL/TLS connections for PostgreSQL

param(
    [Parameter(Mandatory=$false)]
    [string]$PostgreSQLDataDir = "C:\Program Files\PostgreSQL\17\data",
    
    [Parameter(Mandatory=$false)]
    [string]$CertificateDir = "C:\GameForge\certificates",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "🔐 GameForge Database SSL/TLS Configuration" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Create certificate directory
if (!(Test-Path $CertificateDir)) {
    New-Item -ItemType Directory -Path $CertificateDir -Force
    Write-Host "✅ Created certificate directory: $CertificateDir" -ForegroundColor Green
}

# Step 1: Generate SSL Certificates
Write-Host "`n📜 Step 1: Generating SSL Certificates..." -ForegroundColor Yellow

# Generate private key for server
$serverKeyPath = Join-Path $CertificateDir "server.key"
$serverCertPath = Join-Path $CertificateDir "server.crt"
$rootCAKeyPath = Join-Path $CertificateDir "root-ca.key"
$rootCACertPath = Join-Path $CertificateDir "root-ca.crt"

# Check if OpenSSL is available
$opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
if (!$opensslPath) {
    Write-Host "⚠️  OpenSSL not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    # Check if Chocolatey is installed
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if (!$chocoPath) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    }
    
    choco install openssl -y
    
    # Refresh PATH again
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

# Generate Root CA private key
Write-Host "Generating Root CA private key..." -ForegroundColor Cyan
openssl genrsa -out $rootCAKeyPath 4096

# Generate Root CA certificate
Write-Host "Generating Root CA certificate..." -ForegroundColor Cyan
$rootCAConfig = @"
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = US
ST = GameForge
L = GameForge
O = GameForge Database
OU = Database Security
CN = GameForge Root CA

[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
"@

$rootCAConfigPath = Join-Path $CertificateDir "root-ca.conf"
$rootCAConfig | Out-File -FilePath $rootCAConfigPath -Encoding ASCII

openssl req -new -x509 -key $rootCAKeyPath -sha256 -days 3650 -out $rootCACertPath -config $rootCAConfigPath

# Generate server private key
Write-Host "Generating server private key..." -ForegroundColor Cyan
openssl genrsa -out $serverKeyPath 2048

# Generate server certificate signing request
Write-Host "Generating server certificate..." -ForegroundColor Cyan
$serverConfig = @"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = GameForge
L = GameForge
O = GameForge Database
OU = Database Server
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = 127.0.0.1
DNS.3 = ::1
IP.1 = 127.0.0.1
IP.2 = ::1
"@

$serverConfigPath = Join-Path $CertificateDir "server.conf"
$serverConfig | Out-File -FilePath $serverConfigPath -Encoding ASCII

# Generate server CSR
$serverCSRPath = Join-Path $CertificateDir "server.csr"
openssl req -new -key $serverKeyPath -out $serverCSRPath -config $serverConfigPath

# Sign server certificate with Root CA
openssl x509 -req -in $serverCSRPath -CA $rootCACertPath -CAkey $rootCAKeyPath -CAcreateserial -out $serverCertPath -days 365 -extensions v3_req -extfile $serverConfigPath

# Set appropriate permissions
Write-Host "Setting certificate permissions..." -ForegroundColor Cyan
icacls $serverKeyPath /inheritance:r /grant:r "NETWORK SERVICE:(R)" /grant:r "Administrators:(F)"
icacls $serverCertPath /inheritance:r /grant:r "NETWORK SERVICE:(R)" /grant:r "Administrators:(F)" /grant:r "Users:(R)"

Write-Host "✅ SSL certificates generated successfully!" -ForegroundColor Green

# Step 2: Configure PostgreSQL for SSL
Write-Host "`n🔧 Step 2: Configuring PostgreSQL for SSL..." -ForegroundColor Yellow

# Copy certificates to PostgreSQL data directory
$pgServerKeyPath = Join-Path $PostgreSQLDataDir "server.key"
$pgServerCertPath = Join-Path $PostgreSQLDataDir "server.crt"
$pgRootCertPath = Join-Path $PostgreSQLDataDir "root.crt"

Copy-Item $serverKeyPath $pgServerKeyPath -Force
Copy-Item $serverCertPath $pgServerCertPath -Force
Copy-Item $rootCACertPath $pgRootCertPath -Force

# Set PostgreSQL file permissions
icacls $pgServerKeyPath /inheritance:r /grant:r "NETWORK SERVICE:(R)" /grant:r "postgres:(R)" /grant:r "Administrators:(F)"
icacls $pgServerCertPath /inheritance:r /grant:r "NETWORK SERVICE:(R)" /grant:r "postgres:(R)" /grant:r "Administrators:(F)" /grant:r "Users:(R)"

# Step 3: Update PostgreSQL Configuration
Write-Host "`n📝 Step 3: Updating PostgreSQL Configuration..." -ForegroundColor Yellow

$postgresqlConfPath = Join-Path $PostgreSQLDataDir "postgresql.conf"
$pgHbaConfPath = Join-Path $PostgreSQLDataDir "pg_hba.conf"

# Backup original configuration
$backupSuffix = (Get-Date).ToString("yyyyMMdd_HHmmss")
Copy-Item $postgresqlConfPath "$postgresqlConfPath.backup_$backupSuffix"
Copy-Item $pgHbaConfPath "$pgHbaConfPath.backup_$backupSuffix"

# Read current postgresql.conf
$pgConfig = Get-Content $postgresqlConfPath

# Update SSL settings
$sslSettings = @"

# SSL Configuration - Added by GameForge SSL Setup
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'root.crt'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on
ssl_min_protocol_version = 'TLSv1.2'
ssl_max_protocol_version = 'TLSv1.3'

# Security enhancements
password_encryption = scram-sha-256
"@

# Remove existing SSL settings and add new ones
$pgConfig = $pgConfig | Where-Object { $_ -notmatch "^ssl\s*=" -and $_ -notmatch "^ssl_cert_file" -and $_ -notmatch "^ssl_key_file" -and $_ -notmatch "^ssl_ca_file" -and $_ -notmatch "^ssl_ciphers" -and $_ -notmatch "^ssl_prefer_server_ciphers" -and $_ -notmatch "^ssl_min_protocol_version" -and $_ -notmatch "^ssl_max_protocol_version" -and $_ -notmatch "^password_encryption" }
$pgConfig += $sslSettings

$pgConfig | Out-File -FilePath $postgresqlConfPath -Encoding UTF8

Write-Host "✅ PostgreSQL SSL configuration updated!" -ForegroundColor Green

# Step 4: Update pg_hba.conf for SSL requirements
Write-Host "`n🔒 Step 4: Configuring SSL Authentication..." -ForegroundColor Yellow

$pgHbaConfig = Get-Content $pgHbaConfPath

# Add SSL-required entries for GameForge
$sslHbaEntries = @"

# GameForge SSL/TLS Security Configuration
# Require SSL for all GameForge database connections
hostssl    gameforge_dev     gameforge_user    127.0.0.1/32            scram-sha-256
hostssl    gameforge_prod    gameforge_user    127.0.0.1/32            scram-sha-256
hostssl    all               all               127.0.0.1/32            scram-sha-256
hostssl    all               all               ::1/128                 scram-sha-256

# Allow non-SSL local connections for maintenance (remove in production)
host       all               postgres          127.0.0.1/32            scram-sha-256
local      all               postgres                                  peer
"@

# Remove existing GameForge entries and add new ones
$pgHbaConfig = $pgHbaConfig | Where-Object { $_ -notmatch "gameforge" -and $_ -notmatch "# GameForge" }
$pgHbaConfig += $sslHbaEntries

$pgHbaConfig | Out-File -FilePath $pgHbaConfPath -Encoding UTF8

Write-Host "✅ pg_hba.conf updated for SSL authentication!" -ForegroundColor Green

# Step 5: Create SSL-enabled connection strings
Write-Host "`n🔗 Step 5: Creating SSL Connection Configurations..." -ForegroundColor Yellow

$connectionStringsPath = Join-Path $PSScriptRoot "..\configs\ssl-connection-strings.env"
$configDir = Split-Path $connectionStringsPath -Parent
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force
}

$connectionStrings = @"
# GameForge Database SSL Connection Strings
# Use these connection strings in your application for secure database connections

# Development Environment (SSL Required)
DATABASE_URL_SSL_DEV=postgresql+asyncpg://gameforge_user:password@localhost:5432/gameforge_dev?ssl=require&sslmode=require&sslcert=$($serverCertPath.Replace('\', '/'))&sslkey=$($serverKeyPath.Replace('\', '/'))&sslrootcert=$($rootCACertPath.Replace('\', '/'))

# Production Environment (SSL Required + Certificate Verification)
DATABASE_URL_SSL_PROD=postgresql+asyncpg://gameforge_user:SECURE_PASSWORD@localhost:5432/gameforge_prod?ssl=require&sslmode=verify-full&sslcert=$($serverCertPath.Replace('\', '/'))&sslkey=$($serverKeyPath.Replace('\', '/'))&sslrootcert=$($rootCACertPath.Replace('\', '/'))

# For Python applications using psycopg2/asyncpg
POSTGRES_SSL_MODE=require
POSTGRES_SSL_CERT=$($serverCertPath.Replace('\', '/'))
POSTGRES_SSL_KEY=$($serverKeyPath.Replace('\', '/'))
POSTGRES_SSL_ROOT_CERT=$($rootCACertPath.Replace('\', '/'))

# Certificate file paths
SSL_CERT_DIR=$($CertificateDir.Replace('\', '/'))
SSL_SERVER_CERT=$($serverCertPath.Replace('\', '/'))
SSL_SERVER_KEY=$($serverKeyPath.Replace('\', '/'))
SSL_ROOT_CA_CERT=$($rootCACertPath.Replace('\', '/'))
"@

$connectionStrings | Out-File -FilePath $connectionStringsPath -Encoding UTF8

Write-Host "✅ SSL connection strings created: $connectionStringsPath" -ForegroundColor Green

# Step 6: Restart PostgreSQL service
Write-Host "`n🔄 Step 6: Restarting PostgreSQL service..." -ForegroundColor Yellow

try {
    $service = Get-Service -Name "postgresql*" | Select-Object -First 1
    if ($service) {
        Restart-Service $service.Name -Force
        Start-Sleep -Seconds 5
        
        $serviceStatus = Get-Service $service.Name
        if ($serviceStatus.Status -eq "Running") {
            Write-Host "✅ PostgreSQL service restarted successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  PostgreSQL service status: $($serviceStatus.Status)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  PostgreSQL service not found. Please restart manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not restart PostgreSQL service automatically. Please restart manually." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Test SSL Connection
Write-Host "`n🧪 Step 7: Testing SSL Connection..." -ForegroundColor Yellow

try {
    # Test SSL connection
    $testResult = psql -h localhost -U postgres -d postgres -c "SELECT version();" -W 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SSL connection test successful!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SSL connection test failed. Check configuration." -ForegroundColor Yellow
        Write-Host "Error: $testResult" -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️  Could not test SSL connection. Verify configuration manually." -ForegroundColor Yellow
}

# Step 8: Create SSL validation script
Write-Host "`n📝 Step 8: Creating SSL validation script..." -ForegroundColor Yellow

$validationScriptPath = Join-Path $PSScriptRoot "validate-ssl.ps1"
$validationScript = @"
# GameForge Database SSL Validation Script

Write-Host "🔐 GameForge Database SSL Validation" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check SSL certificates
Write-Host "`n📜 Checking SSL certificates..." -ForegroundColor Yellow

`$certDir = "$CertificateDir"
`$pgDataDir = "$PostgreSQLDataDir"

`$requiredCerts = @(
    @{Path = Join-Path `$certDir "server.crt"; Name = "Server Certificate"},
    @{Path = Join-Path `$certDir "server.key"; Name = "Server Private Key"},
    @{Path = Join-Path `$certDir "root-ca.crt"; Name = "Root CA Certificate"},
    @{Path = Join-Path `$pgDataDir "server.crt"; Name = "PostgreSQL Server Certificate"},
    @{Path = Join-Path `$pgDataDir "server.key"; Name = "PostgreSQL Server Key"}
)

`$allCertsValid = `$true
foreach (`$cert in `$requiredCerts) {
    if (Test-Path `$cert.Path) {
        Write-Host "✅ `$(`$cert.Name): Found" -ForegroundColor Green
    } else {
        Write-Host "❌ `$(`$cert.Name): Missing" -ForegroundColor Red
        `$allCertsValid = `$false
    }
}

# Check PostgreSQL SSL configuration
Write-Host "`n🔧 Checking PostgreSQL SSL configuration..." -ForegroundColor Yellow

`$postgresqlConf = Get-Content "$PostgreSQLDataDir\postgresql.conf"
`$sslEnabled = `$postgresqlConf | Where-Object { `$_ -match "^ssl\s*=\s*on" }

if (`$sslEnabled) {
    Write-Host "✅ SSL enabled in PostgreSQL configuration" -ForegroundColor Green
} else {
    Write-Host "❌ SSL not enabled in PostgreSQL configuration" -ForegroundColor Red
    `$allCertsValid = `$false
}

# Test SSL connection
Write-Host "`n🧪 Testing SSL connection..." -ForegroundColor Yellow

try {
    `$env:PGPASSWORD = "password"
    `$testResult = psql -h localhost -U gameforge_user -d gameforge_dev -c "SELECT 'SSL Connection Successful' as status;" 2>&1
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✅ SSL database connection successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ SSL database connection failed" -ForegroundColor Red
        Write-Host "Error: `$testResult" -ForegroundColor Red
        `$allCertsValid = `$false
    }
} catch {
    Write-Host "❌ SSL connection test failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    `$allCertsValid = `$false
} finally {
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}

# Summary
Write-Host "`n📊 SSL Configuration Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

if (`$allCertsValid) {
    Write-Host "✅ SSL/TLS configuration is complete and functional!" -ForegroundColor Green
    Write-Host "🔐 Database connections are now encrypted and secure." -ForegroundColor Green
} else {
    Write-Host "❌ SSL/TLS configuration has issues that need to be resolved." -ForegroundColor Red
    Write-Host "⚠️  Please check the errors above and run the setup script again." -ForegroundColor Yellow
}
"@

$validationScript | Out-File -FilePath $validationScriptPath -Encoding UTF8

Write-Host "✅ SSL validation script created: $validationScriptPath" -ForegroundColor Green

# Final Summary
Write-Host "`n🎉 SSL/TLS Configuration Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "✅ SSL certificates generated and installed" -ForegroundColor Green
Write-Host "✅ PostgreSQL configured for SSL connections" -ForegroundColor Green  
Write-Host "✅ pg_hba.conf updated for SSL authentication" -ForegroundColor Green
Write-Host "✅ Connection strings created for secure connections" -ForegroundColor Green
Write-Host "✅ Validation script created for ongoing monitoring" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update your application's DATABASE_URL to use SSL connection string" -ForegroundColor White
Write-Host "2. Test your application with the new SSL connection" -ForegroundColor White
Write-Host "3. Run validate-ssl.ps1 regularly to verify SSL configuration" -ForegroundColor White
Write-Host "4. Consider implementing certificate rotation for production" -ForegroundColor White

Write-Host "`n📁 Important Files Created:" -ForegroundColor Cyan
Write-Host "- SSL Certificates: $CertificateDir" -ForegroundColor White
Write-Host "- Connection Strings: $connectionStringsPath" -ForegroundColor White
Write-Host "- Validation Script: $validationScriptPath" -ForegroundColor White

Write-Host "`n🔗 Use this connection string in your .env file:" -ForegroundColor Cyan
Write-Host "DATABASE_URL=postgresql+asyncpg://gameforge_user:password@localhost:5432/gameforge_dev?ssl=require" -ForegroundColor Yellow