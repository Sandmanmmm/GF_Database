# GameForge Database Vault Integration Setup Script
# Configures HashiCorp Vault for secret management and dynamic database credentials

param(
    [Parameter(Mandatory=$false)]
    [string]$VaultAddress = "http://127.0.0.1:8200",
    
    [Parameter(Mandatory=$false)]
    [string]$VaultToken = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallVault = $false
)

Write-Host "🔐 GameForge Database Vault Integration Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Step 1: Install Vault if requested
if ($InstallVault) {
    Write-Host "`n📦 Step 1: Installing HashiCorp Vault..." -ForegroundColor Yellow
    
    # Check if Chocolatey is installed
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if (!$chocoPath) {
        Write-Host "Installing Chocolatey first..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    }
    
    # Install Vault
    choco install vault -y
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    Write-Host "✅ Vault installation completed!" -ForegroundColor Green
}

# Step 2: Create Vault configuration directory
Write-Host "`n📁 Step 2: Setting up Vault configuration..." -ForegroundColor Yellow

$vaultConfigDir = "C:\GameForge\vault"
$vaultDataDir = "C:\GameForge\vault\data"
$vaultLogsDir = "C:\GameForge\vault\logs"

foreach ($dir in @($vaultConfigDir, $vaultDataDir, $vaultLogsDir)) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "✅ Created directory: $dir" -ForegroundColor Green
    }
}

# Step 3: Create Vault server configuration
Write-Host "`n⚙️ Step 3: Creating Vault server configuration..." -ForegroundColor Yellow

$vaultConfigPath = Join-Path $vaultConfigDir "vault.hcl"
$vaultConfig = @"
# GameForge Vault Configuration

# Storage backend
storage "file" {
  path = "$($vaultDataDir.Replace('\', '/'))"
}

# Listener
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

# API and cluster addresses
api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"

# UI
ui = true

# Disable mlock (for development - enable in production)
disable_mlock = true

# Log level
log_level = "Info"

# Log file
log_file = "$($vaultLogsDir.Replace('\', '/'))/vault.log"

# Seal configuration (for production use auto-unseal)
# seal "awskms" {
#   region     = "us-east-1"
#   kms_key_id = "your-kms-key-id"
# }
"@

$vaultConfig | Out-File -FilePath $vaultConfigPath -Encoding UTF8
Write-Host "✅ Vault configuration created: $vaultConfigPath" -ForegroundColor Green

# Step 4: Create Vault service startup scripts
Write-Host "`n🚀 Step 4: Creating Vault service scripts..." -ForegroundColor Yellow

$startVaultScriptPath = Join-Path $vaultConfigDir "start-vault.ps1"
$startVaultScript = @"
# Start Vault Server Script

Write-Host "🚀 Starting HashiCorp Vault server..." -ForegroundColor Green

# Set environment variables
`$env:VAULT_ADDR = "$VaultAddress"

# Start Vault server
Start-Process -FilePath "vault" -ArgumentList "server", "-config=`"$vaultConfigPath`"" -NoNewWindow -PassThru

Write-Host "✅ Vault server started at $VaultAddress" -ForegroundColor Green
Write-Host "🌐 Vault UI available at: $VaultAddress/ui" -ForegroundColor Cyan
Write-Host "📋 To initialize Vault, run: vault operator init" -ForegroundColor Yellow
"@

$startVaultScript | Out-File -FilePath $startVaultScriptPath -Encoding UTF8

$stopVaultScriptPath = Join-Path $vaultConfigDir "stop-vault.ps1"
$stopVaultScript = @"
# Stop Vault Server Script

Write-Host "🛑 Stopping HashiCorp Vault server..." -ForegroundColor Yellow

# Find and stop Vault processes
Get-Process -Name "vault" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "✅ Vault server stopped" -ForegroundColor Green
"@

$stopVaultScript | Out-File -FilePath $stopVaultScriptPath -Encoding UTF8

Write-Host "✅ Vault service scripts created" -ForegroundColor Green

# Step 5: Create database secrets engine configuration
Write-Host "`n🗄️ Step 5: Creating database secrets engine configuration..." -ForegroundColor Yellow

$dbSecretsConfigPath = Join-Path $vaultConfigDir "setup-database-secrets.ps1"
$dbSecretsConfig = @"
# GameForge Database Secrets Engine Setup

param(
    [Parameter(Mandatory=`$true)]
    [string]`$VaultToken,
    
    [Parameter(Mandatory=`$false)]
    [string]`$DatabasePassword = "password"
)

Write-Host "🗄️ Setting up Database Secrets Engine..." -ForegroundColor Green

# Set environment variables
`$env:VAULT_ADDR = "$VaultAddress"
`$env:VAULT_TOKEN = `$VaultToken

# Enable database secrets engine
Write-Host "Enabling database secrets engine..." -ForegroundColor Cyan
vault secrets enable -path=gameforge-database database

# Configure PostgreSQL connection
Write-Host "Configuring PostgreSQL connection..." -ForegroundColor Cyan
vault write gameforge-database/config/gameforge-postgres ``
    plugin_name=postgresql-database-plugin ``
    connection_url="postgresql://{{username}}:{{password}}@localhost:5432/gameforge_dev?sslmode=require" ``
    allowed_roles="gameforge-app,gameforge-readonly" ``
    username="postgres" ``
    password="`$DatabasePassword"

# Create application role with read/write permissions
Write-Host "Creating application database role..." -ForegroundColor Cyan
vault write gameforge-database/roles/gameforge-app ``
    db_name=gameforge-postgres ``
    creation_statements="CREATE ROLE `\"{{name}}`\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO `\"{{name}}`\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO `\"{{name}}`\"; GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO `\"{{name}}`\";" ``
    default_ttl="1h" ``
    max_ttl="24h"

# Create read-only role
Write-Host "Creating read-only database role..." -ForegroundColor Cyan
vault write gameforge-database/roles/gameforge-readonly ``
    db_name=gameforge-postgres ``
    creation_statements="CREATE ROLE `\"{{name}}`\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO `\"{{name}}`\";" ``
    default_ttl="1h" ``
    max_ttl="8h"

Write-Host "✅ Database secrets engine configured successfully!" -ForegroundColor Green

# Test database credentials generation
Write-Host "`n🧪 Testing credential generation..." -ForegroundColor Yellow

Write-Host "Generating application credentials..." -ForegroundColor Cyan
vault read gameforge-database/creds/gameforge-app

Write-Host "`nGenerating read-only credentials..." -ForegroundColor Cyan
vault read gameforge-database/creds/gameforge-readonly

Write-Host "✅ Credential generation test completed!" -ForegroundColor Green
"@

$dbSecretsConfig | Out-File -FilePath $dbSecretsConfigPath -Encoding UTF8
Write-Host "✅ Database secrets configuration created: $dbSecretsConfigPath" -ForegroundColor Green

# Step 6: Create application integration scripts
Write-Host "`n🔧 Step 6: Creating application integration scripts..." -ForegroundColor Yellow

$vaultIntegrationPath = Join-Path $PSScriptRoot "..\configs\vault-integration.py"
$vaultIntegration = @"
# GameForge Vault Integration Module
# Provides dynamic database credentials and secret management

import os
import time
import logging
import hvac
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple
import asyncio
import aiohttp

logger = logging.getLogger(__name__)

class VaultManager:
    """Manages HashiCorp Vault integration for GameForge database secrets"""
    
    def __init__(self, vault_url: str = None, vault_token: str = None):
        self.vault_url = vault_url or os.getenv('VAULT_ADDR', '$VaultAddress')
        self.vault_token = vault_token or os.getenv('VAULT_TOKEN')
        self.client = None
        self.current_credentials = None
        self.credentials_expiry = None
        
    def initialize(self):
        """Initialize Vault client and verify connection"""
        try:
            self.client = hvac.Client(url=self.vault_url, token=self.vault_token)
            
            if not self.client.is_authenticated():
                raise Exception("Vault authentication failed")
                
            logger.info(f"Vault client initialized successfully: {self.vault_url}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize Vault client: {e}")
            return False
    
    def get_database_credentials(self, role: str = "gameforge-app") -> Optional[Dict]:
        """Get dynamic database credentials from Vault"""
        try:
            if not self.client:
                raise Exception("Vault client not initialized")
            
            # Check if current credentials are still valid
            if self._credentials_valid():
                return self.current_credentials
            
            # Generate new credentials
            response = self.client.secrets.database.generate_credentials(
                name=role,
                mount_point='gameforge-database'
            )
            
            if 'data' not in response:
                raise Exception("Invalid response from Vault")
            
            self.current_credentials = {
                'username': response['data']['username'],
                'password': response['data']['password'],
                'lease_id': response['lease_id'],
                'lease_duration': response['lease_duration']
            }
            
            # Set expiry time (renew before expiration)
            self.credentials_expiry = datetime.now() + timedelta(
                seconds=response['lease_duration'] - 300  # Renew 5 minutes early
            )
            
            logger.info(f"New database credentials generated for role: {role}")
            return self.current_credentials
            
        except Exception as e:
            logger.error(f"Failed to get database credentials: {e}")
            return None
    
    def get_connection_string(self, database: str = "gameforge_dev", ssl: bool = True) -> Optional[str]:
        """Get PostgreSQL connection string with dynamic credentials"""
        credentials = self.get_database_credentials()
        if not credentials:
            return None
        
        ssl_params = "?ssl=require&sslmode=require" if ssl else ""
        
        return (
            f"postgresql+asyncpg://{credentials['username']}:"
            f"{credentials['password']}@localhost:5432/{database}{ssl_params}"
        )
    
    def _credentials_valid(self) -> bool:
        """Check if current credentials are still valid"""
        if not self.current_credentials or not self.credentials_expiry:
            return False
        
        return datetime.now() < self.credentials_expiry
    
    def revoke_credentials(self):
        """Revoke current database credentials"""
        try:
            if self.current_credentials and 'lease_id' in self.current_credentials:
                self.client.sys.revoke_lease(self.current_credentials['lease_id'])
                logger.info("Database credentials revoked successfully")
            
            self.current_credentials = None
            self.credentials_expiry = None
            
        except Exception as e:
            logger.error(f"Failed to revoke credentials: {e}")
    
    def get_secret(self, path: str) -> Optional[Dict]:
        """Get secret from Vault KV store"""
        try:
            response = self.client.secrets.kv.v2.read_secret_version(path=path)
            return response['data']['data']
            
        except Exception as e:
            logger.error(f"Failed to get secret from {path}: {e}")
            return None
    
    def store_secret(self, path: str, secret_data: Dict) -> bool:
        """Store secret in Vault KV store"""
        try:
            self.client.secrets.kv.v2.create_or_update_secret(
                path=path,
                secret=secret_data
            )
            logger.info(f"Secret stored successfully at {path}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to store secret at {path}: {e}")
            return False

# Global Vault manager instance
vault_manager = VaultManager()

# Async context manager for database connections with Vault
class VaultDatabaseConnection:
    """Async context manager for database connections using Vault credentials"""
    
    def __init__(self, database: str = "gameforge_dev"):
        self.database = database
        self.connection = None
        
    async def __aenter__(self):
        from sqlalchemy.ext.asyncio import create_async_engine
        
        connection_string = vault_manager.get_connection_string(self.database)
        if not connection_string:
            raise Exception("Failed to get database connection string from Vault")
        
        engine = create_async_engine(connection_string)
        self.connection = await engine.connect()
        return self.connection
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.connection:
            await self.connection.close()

# Example usage functions
async def example_vault_usage():
    """Example of how to use Vault integration in GameForge application"""
    
    # Initialize Vault
    if not vault_manager.initialize():
        logger.error("Failed to initialize Vault")
        return
    
    # Get database credentials
    credentials = vault_manager.get_database_credentials()
    if credentials:
        logger.info(f"Database username: {credentials['username']}")
        logger.info(f"Credentials expire in: {vault_manager.credentials_expiry}")
    
    # Use connection with automatic credential management
    async with VaultDatabaseConnection("gameforge_dev") as conn:
        result = await conn.execute("SELECT version()")
        logger.info(f"Database version: {result.fetchone()}")
    
    # Store application secrets
    app_secrets = {
        "jwt_secret": "your-jwt-secret-here",
        "encryption_key": "your-encryption-key-here"
    }
    vault_manager.store_secret("gameforge/app-secrets", app_secrets)
    
    # Retrieve secrets
    retrieved_secrets = vault_manager.get_secret("gameforge/app-secrets")
    if retrieved_secrets:
        logger.info("Application secrets retrieved successfully")

if __name__ == "__main__":
    # Test the Vault integration
    asyncio.run(example_vault_usage())
"@

$vaultIntegration | Out-File -FilePath $vaultIntegrationPath -Encoding UTF8
Write-Host "✅ Vault integration module created: $vaultIntegrationPath" -ForegroundColor Green

# Step 7: Create Vault initialization script
Write-Host "`n🔑 Step 7: Creating Vault initialization script..." -ForegroundColor Yellow

$initVaultScriptPath = Join-Path $vaultConfigDir "initialize-vault.ps1"
$initVaultScript = @"
# GameForge Vault Initialization Script

Write-Host "🔑 Initializing GameForge Vault..." -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Set environment
`$env:VAULT_ADDR = "$VaultAddress"

# Check if Vault is running
try {
    `$status = vault status 2>`$null
    if (`$LASTEXITCODE -ne 0) {
        Write-Host "❌ Vault server is not running. Start it first with start-vault.ps1" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Vault CLI not available or server not running" -ForegroundColor Red
    exit 1
}

# Initialize Vault (only if not already initialized)
Write-Host "`n🔐 Initializing Vault..." -ForegroundColor Yellow

`$initOutput = vault operator init -key-shares=5 -key-threshold=3 -format=json 2>`$null

if (`$LASTEXITCODE -eq 0) {
    `$initData = `$initOutput | ConvertFrom-Json
    
    # Save unseal keys and root token securely
    `$vaultKeysPath = Join-Path "$vaultConfigDir" "vault-keys.json"
    `$initData | ConvertTo-Json -Depth 10 | Out-File -FilePath `$vaultKeysPath -Encoding UTF8
    
    Write-Host "✅ Vault initialized successfully!" -ForegroundColor Green
    Write-Host "🔑 Unseal keys and root token saved to: `$vaultKeysPath" -ForegroundColor Cyan
    Write-Host "⚠️  IMPORTANT: Store these keys securely and delete the file after backing up!" -ForegroundColor Yellow
    
    # Auto-unseal Vault
    Write-Host "`n🔓 Unsealing Vault..." -ForegroundColor Yellow
    
    for (`$i = 0; `$i -lt 3; `$i++) {
        vault operator unseal `$initData.unseal_keys_b64[`$i] | Out-Null
        Write-Host "✅ Unseal key `$(`$i + 1) applied" -ForegroundColor Green
    }
    
    # Set root token
    `$env:VAULT_TOKEN = `$initData.root_token
    
    Write-Host "✅ Vault unsealed and ready!" -ForegroundColor Green
    Write-Host "🌐 Vault UI: $VaultAddress/ui" -ForegroundColor Cyan
    Write-Host "🔑 Root Token: `$(`$initData.root_token)" -ForegroundColor Yellow
    
} else {
    Write-Host "ℹ️  Vault appears to already be initialized" -ForegroundColor Cyan
    
    # Try to read saved keys
    `$vaultKeysPath = Join-Path "$vaultConfigDir" "vault-keys.json"
    if (Test-Path `$vaultKeysPath) {
        `$savedKeys = Get-Content `$vaultKeysPath | ConvertFrom-Json
        
        Write-Host "`n🔓 Unsealing Vault with saved keys..." -ForegroundColor Yellow
        
        for (`$i = 0; `$i -lt 3; `$i++) {
            try {
                vault operator unseal `$savedKeys.unseal_keys_b64[`$i] | Out-Null
                Write-Host "✅ Unseal key `$(`$i + 1) applied" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Failed to apply unseal key `$(`$i + 1)" -ForegroundColor Yellow
            }
        }
        
        `$env:VAULT_TOKEN = `$savedKeys.root_token
        Write-Host "✅ Vault unsealed with saved keys!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No saved keys found. Please unseal manually or re-initialize." -ForegroundColor Yellow
    }
}

# Enable KV secrets engine for application secrets
Write-Host "`n🗂️ Setting up secrets engines..." -ForegroundColor Yellow

vault secrets enable -path=gameforge/kv kv-v2 2>`$null
if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ KV secrets engine enabled at gameforge/kv" -ForegroundColor Green
} else {
    Write-Host "ℹ️  KV secrets engine already enabled" -ForegroundColor Cyan
}

# Create initial application secrets
Write-Host "`n🔑 Creating initial application secrets..." -ForegroundColor Yellow

`$jwtSecret = [System.Web.Security.Membership]::GeneratePassword(64, 10)
`$sessionSecret = [System.Web.Security.Membership]::GeneratePassword(32, 5)
`$encryptionKey = [System.Web.Security.Membership]::GeneratePassword(32, 8)

vault kv put gameforge/kv/app-secrets ``
    jwt_secret="`$jwtSecret" ``
    session_secret="`$sessionSecret" ``
    encryption_key="`$encryptionKey" ``
    created_at="`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ Application secrets created successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Failed to create application secrets" -ForegroundColor Yellow
}

Write-Host "`n🎉 Vault initialization complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "✅ Vault server initialized and unsealed" -ForegroundColor Green
Write-Host "✅ KV secrets engine configured" -ForegroundColor Green
Write-Host "✅ Application secrets created" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set up database secrets engine: .\setup-database-secrets.ps1 -VaultToken `$env:VAULT_TOKEN" -ForegroundColor White
Write-Host "2. Configure your application to use Vault for secrets" -ForegroundColor White
Write-Host "3. Secure the vault-keys.json file and remove it from this location" -ForegroundColor White
Write-Host "4. Set up Vault policies for application access" -ForegroundColor White

Write-Host "`n🔗 Vault Access:" -ForegroundColor Cyan
Write-Host "Vault Address: $VaultAddress" -ForegroundColor White
Write-Host "Vault UI: $VaultAddress/ui" -ForegroundColor White
Write-Host "Root Token: `$env:VAULT_TOKEN" -ForegroundColor Yellow
"@

$initVaultScript | Out-File -FilePath $initVaultScriptPath -Encoding UTF8
Write-Host "✅ Vault initialization script created: $initVaultScriptPath" -ForegroundColor Green

# Step 8: Create environment configuration template
Write-Host "`n📝 Step 8: Creating Vault environment configuration..." -ForegroundColor Yellow

$vaultEnvPath = Join-Path $PSScriptRoot "..\configs\vault.env"
$vaultEnv = @"
# GameForge Vault Configuration
# Use these environment variables in your application

# Vault server configuration
VAULT_ADDR=$VaultAddress
VAULT_TOKEN=your-vault-token-here

# Database secrets engine
VAULT_DATABASE_PATH=gameforge-database
VAULT_DATABASE_ROLE=gameforge-app
VAULT_DATABASE_READONLY_ROLE=gameforge-readonly

# Application secrets path
VAULT_APP_SECRETS_PATH=gameforge/kv/app-secrets

# Vault policies
VAULT_APP_POLICY=gameforge-app-policy
VAULT_READONLY_POLICY=gameforge-readonly-policy

# SSL/TLS configuration
VAULT_CACERT=
VAULT_CLIENT_CERT=
VAULT_CLIENT_KEY=
VAULT_TLS_SKIP_VERIFY=true

# Credential refresh settings
VAULT_CREDENTIAL_REFRESH_THRESHOLD=300  # Refresh 5 minutes before expiry
VAULT_MAX_RETRIES=3
VAULT_RETRY_DELAY=5

# Logging
VAULT_LOG_LEVEL=INFO
VAULT_AUDIT_LOG_PATH=C:/GameForge/vault/logs/audit.log
"@

$vaultEnv | Out-File -FilePath $vaultEnvPath -Encoding UTF8
Write-Host "✅ Vault environment configuration created: $vaultEnvPath" -ForegroundColor Green

# Final Summary
Write-Host "`n🎉 Vault Integration Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "✅ Vault server configuration created" -ForegroundColor Green
Write-Host "✅ Database secrets engine configuration ready" -ForegroundColor Green
Write-Host "✅ Application integration module created" -ForegroundColor Green
Write-Host "✅ Initialization and management scripts created" -ForegroundColor Green

Write-Host "`n📋 Quick Start Guide:" -ForegroundColor Cyan
Write-Host "1. Start Vault server: .\start-vault.ps1" -ForegroundColor White
Write-Host "2. Initialize Vault: .\initialize-vault.ps1" -ForegroundColor White
Write-Host "3. Setup database secrets: .\setup-database-secrets.ps1 -VaultToken <token>" -ForegroundColor White
Write-Host "4. Integrate with your application using vault-integration.py" -ForegroundColor White

Write-Host "`n📁 Created Files:" -ForegroundColor Cyan
Write-Host "- Vault Config: $vaultConfigPath" -ForegroundColor White
Write-Host "- Start Script: $startVaultScriptPath" -ForegroundColor White
Write-Host "- Init Script: $initVaultScriptPath" -ForegroundColor White
Write-Host "- DB Secrets: $dbSecretsConfigPath" -ForegroundColor White
Write-Host "- Python Module: $vaultIntegrationPath" -ForegroundColor White
Write-Host "- Environment: $vaultEnvPath" -ForegroundColor White

Write-Host "`n⚠️  Security Notes:" -ForegroundColor Yellow
Write-Host "- Store Vault unseal keys securely" -ForegroundColor White
Write-Host "- Use proper Vault policies for application access" -ForegroundColor White
Write-Host "- Enable auto-unseal in production" -ForegroundColor White
Write-Host "- Configure Vault audit logging" -ForegroundColor White
Write-Host "- Use HTTPS for Vault in production" -ForegroundColor White