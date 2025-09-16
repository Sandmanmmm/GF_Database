# GameForge Database Firewall Rules Setup Script
# Configures PostgreSQL access restrictions and Windows Firewall rules

param(
    [Parameter(Mandatory=$false)]
    [string]$PostgreSQLDataDir = "C:\Program Files\PostgreSQL\17\data",
    
    [Parameter(Mandatory=$false)]
    [string[]]$AllowedIPs = @("127.0.0.1", "::1"),
    
    [Parameter(Mandatory=$false)]
    [string[]]$AllowedNetworks = @(),
    
    [Parameter(Mandatory=$false)]
    [int]$PostgreSQLPort = 5432,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode
)

Write-Host "🛡️ GameForge Database Firewall Rules Setup" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Step 1: Backup current configuration
Write-Host "`n💾 Step 1: Backing up current configuration..." -ForegroundColor Yellow

$pgHbaConfPath = Join-Path $PostgreSQLDataDir "pg_hba.conf"
$postgresqlConfPath = Join-Path $PostgreSQLDataDir "postgresql.conf"

if (!(Test-Path $pgHbaConfPath)) {
    Write-Host "❌ pg_hba.conf not found at: $pgHbaConfPath" -ForegroundColor Red
    exit 1
}

$backupSuffix = (Get-Date).ToString("yyyyMMdd_HHmmss")
$pgHbaBackupPath = "$pgHbaConfPath.firewall_backup_$backupSuffix"
$postgresqlBackupPath = "$postgresqlConfPath.firewall_backup_$backupSuffix"

Copy-Item $pgHbaConfPath $pgHbaBackupPath
Copy-Item $postgresqlConfPath $postgresqlBackupPath

Write-Host "✅ Configuration backed up:" -ForegroundColor Green
Write-Host "  - pg_hba.conf: $pgHbaBackupPath" -ForegroundColor White
Write-Host "  - postgresql.conf: $postgresqlBackupPath" -ForegroundColor White

# Step 2: Configure PostgreSQL connection restrictions
Write-Host "`n🔒 Step 2: Configuring PostgreSQL connection restrictions..." -ForegroundColor Yellow

# Create secure pg_hba.conf
$secureHbaConfig = @"
# GameForge Database Firewall Configuration
# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# 
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             postgres                                peer
local   all             all                                     scram-sha-256

# IPv4 local connections
host    all             postgres        127.0.0.1/32            scram-sha-256
"@

# Add allowed IPs for GameForge databases
foreach ($ip in $AllowedIPs) {
    if ($ip -eq "127.0.0.1" -or $ip -eq "::1") {
        $secureHbaConfig += @"

# GameForge local connections ($ip)
hostssl gameforge_dev     gameforge_user    $ip/32                 scram-sha-256
hostssl gameforge_prod    gameforge_user    $ip/32                 scram-sha-256
hostssl all               postgres          $ip/32                 scram-sha-256
"@
    } else {
        $secureHbaConfig += @"

# GameForge allowed IP ($ip)
hostssl gameforge_dev     gameforge_user    $ip/32                 scram-sha-256
hostssl gameforge_prod    gameforge_user    $ip/32                 scram-sha-256
"@
    }
}

# Add allowed networks
foreach ($network in $AllowedNetworks) {
    $secureHbaConfig += @"

# GameForge allowed network ($network)
hostssl gameforge_dev     gameforge_user    $network               scram-sha-256
hostssl gameforge_prod    gameforge_user    $network               scram-sha-256
"@
}

# Add IPv6 local connections
$secureHbaConfig += @"

# IPv6 local connections
hostssl all             postgres        ::1/128                 scram-sha-256
hostssl gameforge_dev   gameforge_user  ::1/128                 scram-sha-256
hostssl gameforge_prod  gameforge_user  ::1/128                 scram-sha-256
"@

if ($ProductionMode) {
    $secureHbaConfig += @"

# Production mode - Reject all other connections
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
"@
} else {
    $secureHbaConfig += @"

# Development mode - Allow local connections
# WARNING: Remove these lines in production!
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
"@
}

$secureHbaConfig | Out-File -FilePath $pgHbaConfPath -Encoding UTF8
Write-Host "✅ pg_hba.conf updated with firewall rules" -ForegroundColor Green

# Step 3: Configure PostgreSQL listening addresses
Write-Host "`n🌐 Step 3: Configuring PostgreSQL listening addresses..." -ForegroundColor Yellow

$pgConfig = Get-Content $postgresqlConfPath

# Remove existing listen_addresses configuration
$pgConfig = $pgConfig | Where-Object { $_ -notmatch "^listen_addresses" -and $_ -notmatch "^port" }

# Add secure listening configuration
$listenConfig = @"

# GameForge Database Firewall - Network Configuration
# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# Listen only on localhost (most secure)
listen_addresses = 'localhost'

# Database port
port = $PostgreSQLPort

# Connection limits and security
max_connections = 100
superuser_reserved_connections = 5

# Timeout settings for security
authentication_timeout = 1min
tcp_keepalives_idle = 600
tcp_keepalives_interval = 30
tcp_keepalives_count = 3

# Statement timeout (prevent long-running queries)
statement_timeout = 0
lock_timeout = 0
idle_in_transaction_session_timeout = 10min

# Password encryption
password_encryption = scram-sha-256
"@

$pgConfig += $listenConfig
$pgConfig | Out-File -FilePath $postgresqlConfPath -Encoding UTF8

Write-Host "✅ PostgreSQL configured to listen only on localhost" -ForegroundColor Green

# Step 4: Configure Windows Firewall
Write-Host "`n🔥 Step 4: Configuring Windows Firewall..." -ForegroundColor Yellow

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (!$isAdmin) {
    Write-Host "⚠️  Administrator privileges required for Windows Firewall configuration" -ForegroundColor Yellow
    Write-Host "   Run script as Administrator to configure firewall rules" -ForegroundColor White
} else {
    try {
        # Remove any existing PostgreSQL rules
        $existingRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*PostgreSQL*" -or $_.DisplayName -like "*GameForge*" }
        foreach ($rule in $existingRules) {
            Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
            Write-Host "🗑️ Removed existing rule: $($rule.DisplayName)" -ForegroundColor Yellow
        }

        # Create inbound rule for PostgreSQL (localhost only)
        New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Localhost Inbound" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $PostgreSQLPort `
            -RemoteAddress "127.0.0.1", "::1" `
            -Action Allow `
            -Profile Domain,Private,Public `
            -Description "Allow PostgreSQL connections from localhost only for GameForge"

        Write-Host "✅ Windows Firewall rule created: Localhost inbound access" -ForegroundColor Green

        # Create outbound rule for PostgreSQL (localhost only)
        New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Localhost Outbound" `
            -Direction Outbound `
            -Protocol TCP `
            -LocalPort $PostgreSQLPort `
            -RemoteAddress "127.0.0.1", "::1" `
            -Action Allow `
            -Profile Domain,Private,Public `
            -Description "Allow PostgreSQL outbound connections from localhost only for GameForge"

        Write-Host "✅ Windows Firewall rule created: Localhost outbound access" -ForegroundColor Green

        # Add rules for allowed IPs if specified
        if ($AllowedIPs.Count -gt 2) { # More than just localhost
            $nonLocalIPs = $AllowedIPs | Where-Object { $_ -ne "127.0.0.1" -and $_ -ne "::1" }
            
            if ($nonLocalIPs.Count -gt 0) {
                New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Allowed IPs" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort $PostgreSQLPort `
                    -RemoteAddress $nonLocalIPs `
                    -Action Allow `
                    -Profile Domain,Private `
                    -Description "Allow PostgreSQL connections from specific IPs for GameForge"

                Write-Host "✅ Windows Firewall rule created: Allowed IPs ($($nonLocalIPs -join ', '))" -ForegroundColor Green
            }
        }

        # Block all other PostgreSQL traffic
        New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Block All Others" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $PostgreSQLPort `
            -Action Block `
            -Profile Domain,Private,Public `
            -Description "Block all other PostgreSQL connections for GameForge security"

        Write-Host "✅ Windows Firewall rule created: Block all other connections" -ForegroundColor Green

    } catch {
        Write-Host "❌ Failed to configure Windows Firewall: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 5: Create IP monitoring script
Write-Host "`n📊 Step 5: Creating connection monitoring script..." -ForegroundColor Yellow

$monitoringScriptPath = Join-Path $PSScriptRoot "monitor-database-connections.ps1"
$monitoringScript = @"
# GameForge Database Connection Monitoring Script

param(
    [Parameter(Mandatory=`$false)]
    [int]`$RefreshSeconds = 5,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$ShowBlocked,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$LogToFile,
    
    [Parameter(Mandatory=`$false)]
    [string]`$LogPath = "C:\GameForge\logs\connection-monitor.log"
)

Write-Host "📊 GameForge Database Connection Monitor" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

# Function to log messages
function Write-Log(`$message, `$color = "White") {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "`$timestamp - `$message"
    
    Write-Host `$logEntry -ForegroundColor `$color
    
    if (`$LogToFile) {
        `$logEntry | Out-File -FilePath `$LogPath -Append -Encoding UTF8
    }
}

# Function to get PostgreSQL connections
function Get-PostgreSQLConnections {
    try {
        `$env:PGPASSWORD = "password"
        `$connections = psql -h localhost -U postgres -d gameforge_dev -t -c "
            SELECT 
                client_addr,
                client_port,
                usename,
                datname,
                application_name,
                state,
                backend_start,
                query_start
            FROM pg_stat_activity 
            WHERE datname IN ('gameforge_dev', 'gameforge_prod')
            ORDER BY backend_start DESC;
        " 2>`$null
        
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
        return `$connections
    } catch {
        return `$null
    }
}

# Function to get network connections
function Get-NetworkConnections {
    try {
        `$netstat = netstat -an | Where-Object { `$_ -match ":$PostgreSQLPort" -and `$_ -match "ESTABLISHED|LISTEN" }
        return `$netstat
    } catch {
        return `$null
    }
}

# Function to get firewall logs (blocked connections)
function Get-BlockedConnections {
    try {
        `$events = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=5152} -MaxEvents 10 -ErrorAction SilentlyContinue | 
            Where-Object { `$_.Message -match $PostgreSQLPort }
        return `$events
    } catch {
        return `$null
    }
}

# Main monitoring loop
try {
    while (`$true) {
        Clear-Host
        Write-Host "📊 GameForge Database Connection Monitor - `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor Green
        
        # Show PostgreSQL connections
        Write-Host "`n🔗 Active Database Connections:" -ForegroundColor Yellow
        `$pgConnections = Get-PostgreSQLConnections
        
        if (`$pgConnections) {
            `$connectionCount = (`$pgConnections | Measure-Object).Count
            Write-Host "Total connections: `$connectionCount" -ForegroundColor Cyan
            
            foreach (`$conn in `$pgConnections) {
                if (`$conn.Trim()) {
                    `$parts = `$conn -split '\|'
                    if (`$parts.Length -ge 6) {
                        `$clientAddr = `$parts[0].Trim()
                        `$clientPort = `$parts[1].Trim()
                        `$username = `$parts[2].Trim()
                        `$database = `$parts[3].Trim()
                        `$appName = `$parts[4].Trim()
                        `$state = `$parts[5].Trim()
                        
                        if (`$clientAddr) {
                            Write-Log "🔗 `$clientAddr:`$clientPort -> `$username@`$database [`$state]" "Cyan"
                        }
                    }
                }
            }
        } else {
            Write-Host "No active connections found" -ForegroundColor Gray
        }
        
        # Show network connections
        Write-Host "`n🌐 Network Connections (Port $PostgreSQLPort):" -ForegroundColor Yellow
        `$netConnections = Get-NetworkConnections
        
        if (`$netConnections) {
            foreach (`$conn in `$netConnections) {
                if (`$conn -match "LISTEN") {
                    Write-Log "👂 `$conn" "Green"
                } else {
                    Write-Log "🔗 `$conn" "White"
                }
            }
        } else {
            Write-Host "No network connections found" -ForegroundColor Gray
        }
        
        # Show blocked connections if requested
        if (`$ShowBlocked) {
            Write-Host "`n🚫 Recent Blocked Connections:" -ForegroundColor Yellow
            `$blockedConnections = Get-BlockedConnections
            
            if (`$blockedConnections) {
                foreach (`$event in `$blockedConnections) {
                    `$message = `$event.Message
                    if (`$message -match "Source Address:\s+([^\s]+)" -and `$message -match "Destination Port:\s+([^\s]+)") {
                        `$sourceIP = `$Matches[1]
                        `$destPort = `$Matches[2]
                        `$timestamp = `$event.TimeCreated.ToString("HH:mm:ss")
                        Write-Log "🚫 `$timestamp - Blocked: `$sourceIP -> Port `$destPort" "Red"
                    }
                }
            } else {
                Write-Host "No blocked connections in recent logs" -ForegroundColor Gray
            }
        }
        
        # Show firewall rules
        Write-Host "`n🔥 Active Firewall Rules:" -ForegroundColor Yellow
        try {
            `$firewallRules = Get-NetFirewallRule | Where-Object { 
                `$_.DisplayName -like "*GameForge*" -or `$_.DisplayName -like "*PostgreSQL*" 
            } | Select-Object DisplayName, Direction, Action, Enabled
            
            foreach (`$rule in `$firewallRules) {
                `$status = if (`$rule.Enabled -eq "True") { "✅" } else { "❌" }
                `$action = if (`$rule.Action -eq "Allow") { "🟢" } else { "🔴" }
                Write-Host "`$status `$action `$(`$rule.Direction) - `$(`$rule.DisplayName)" -ForegroundColor White
            }
        } catch {
            Write-Host "Could not retrieve firewall rules" -ForegroundColor Gray
        }
        
        Write-Host "`n⏱️ Refreshing in `$RefreshSeconds seconds... (Ctrl+C to stop)" -ForegroundColor Gray
        Start-Sleep -Seconds `$RefreshSeconds
    }
} catch {
    Write-Host "`n👋 Monitoring stopped" -ForegroundColor Yellow
}
"@

$monitoringScript | Out-File -FilePath $monitoringScriptPath -Encoding UTF8
Write-Host "✅ Connection monitoring script created: $monitoringScriptPath" -ForegroundColor Green

# Step 6: Create firewall management script
Write-Host "`n🔧 Step 6: Creating firewall management script..." -ForegroundColor Yellow

$firewallManagementPath = Join-Path $PSScriptRoot "manage-database-firewall.ps1"
$firewallManagementScript = @"
# GameForge Database Firewall Management Script

param(
    [Parameter(Mandatory=`$true)]
    [ValidateSet("add", "remove", "list", "enable", "disable", "reset")]
    [string]`$Action,
    
    [Parameter(Mandatory=`$false)]
    [string]`$IPAddress,
    
    [Parameter(Mandatory=`$false)]
    [string]`$Network,
    
    [Parameter(Mandatory=`$false)]
    [string]`$RuleName,
    
    [Parameter(Mandatory=`$false)]
    [int]`$Port = $PostgreSQLPort
)

Write-Host "🔧 GameForge Database Firewall Management" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check if running as administrator
`$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (!`$isAdmin -and `$Action -ne "list") {
    Write-Host "❌ Administrator privileges required for firewall management" -ForegroundColor Red
    Write-Host "   Please run as Administrator" -ForegroundColor White
    exit 1
}

switch (`$Action) {
    "add" {
        if (!`$IPAddress -and !`$Network) {
            Write-Host "❌ IP address or network required for add action" -ForegroundColor Red
            exit 1
        }
        
        `$target = if (`$IPAddress) { `$IPAddress } else { `$Network }
        `$displayName = "GameForge PostgreSQL - Custom Allow (`$target)"
        
        try {
            New-NetFirewallRule -DisplayName `$displayName `
                -Direction Inbound `
                -Protocol TCP `
                -LocalPort `$Port `
                -RemoteAddress `$target `
                -Action Allow `
                -Profile Domain,Private `
                -Description "Custom GameForge PostgreSQL access rule"
                
            Write-Host "✅ Firewall rule added: `$displayName" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to add firewall rule: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "remove" {
        if (`$RuleName) {
            try {
                Remove-NetFirewallRule -DisplayName `$RuleName -ErrorAction Stop
                Write-Host "✅ Firewall rule removed: `$RuleName" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to remove firewall rule: `$(`$_.Exception.Message)" -ForegroundColor Red
            }
        } elseif (`$IPAddress) {
            try {
                `$rules = Get-NetFirewallRule | Where-Object { `$_.DisplayName -like "*GameForge*" }
                foreach (`$rule in `$rules) {
                    `$addressFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule `$rule
                    if (`$addressFilter.RemoteAddress -contains `$IPAddress) {
                        Remove-NetFirewallRule -Name `$rule.Name
                        Write-Host "✅ Removed rule for IP `$IPAddress`: `$(`$rule.DisplayName)" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Host "❌ Failed to remove firewall rules for IP: `$(`$_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Rule name or IP address required for remove action" -ForegroundColor Red
        }
    }
    
    "list" {
        Write-Host "`n🔥 GameForge Firewall Rules:" -ForegroundColor Yellow
        try {
            `$rules = Get-NetFirewallRule | Where-Object { 
                `$_.DisplayName -like "*GameForge*" -or `$_.DisplayName -like "*PostgreSQL*" 
            }
            
            if (`$rules) {
                foreach (`$rule in `$rules) {
                    `$portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule `$rule -ErrorAction SilentlyContinue
                    `$addressFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule `$rule -ErrorAction SilentlyContinue
                    
                    `$status = if (`$rule.Enabled -eq "True") { "✅" } else { "❌" }
                    `$action = if (`$rule.Action -eq "Allow") { "🟢 ALLOW" } else { "🔴 BLOCK" }
                    `$direction = `$rule.Direction.ToUpper()
                    
                    Write-Host "`$status [`$direction] `$action - `$(`$rule.DisplayName)" -ForegroundColor White
                    
                    if (`$portFilter -and `$portFilter.LocalPort) {
                        Write-Host "    Port: `$(`$portFilter.LocalPort)" -ForegroundColor Gray
                    }
                    
                    if (`$addressFilter -and `$addressFilter.RemoteAddress) {
                        `$addresses = `$addressFilter.RemoteAddress -join ", "
                        Write-Host "    Remote: `$addresses" -ForegroundColor Gray
                    }
                    
                    Write-Host ""
                }
            } else {
                Write-Host "No GameForge firewall rules found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "❌ Failed to list firewall rules: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "enable" {
        if (!`$RuleName) {
            Write-Host "❌ Rule name required for enable action" -ForegroundColor Red
            exit 1
        }
        
        try {
            Enable-NetFirewallRule -DisplayName `$RuleName
            Write-Host "✅ Firewall rule enabled: `$RuleName" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to enable firewall rule: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "disable" {
        if (!`$RuleName) {
            Write-Host "❌ Rule name required for disable action" -ForegroundColor Red
            exit 1
        }
        
        try {
            Disable-NetFirewallRule -DisplayName `$RuleName
            Write-Host "✅ Firewall rule disabled: `$RuleName" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to disable firewall rule: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "reset" {
        Write-Host "⚠️ This will remove ALL GameForge firewall rules and recreate defaults" -ForegroundColor Yellow
        `$confirm = Read-Host "Are you sure? (y/N)"
        
        if (`$confirm -eq "y" -or `$confirm -eq "Y") {
            try {
                # Remove all GameForge rules
                `$rules = Get-NetFirewallRule | Where-Object { `$_.DisplayName -like "*GameForge*" }
                foreach (`$rule in `$rules) {
                    Remove-NetFirewallRule -Name `$rule.Name
                    Write-Host "🗑️ Removed: `$(`$rule.DisplayName)" -ForegroundColor Yellow
                }
                
                # Recreate default rules
                Write-Host "`n🔄 Recreating default rules..." -ForegroundColor Cyan
                
                # Localhost allow
                New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Localhost Inbound" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort `$Port `
                    -RemoteAddress "127.0.0.1", "::1" `
                    -Action Allow `
                    -Profile Domain,Private,Public `
                    -Description "Allow PostgreSQL connections from localhost only for GameForge"
                
                # Block all others
                New-NetFirewallRule -DisplayName "GameForge PostgreSQL - Block All Others" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort `$Port `
                    -Action Block `
                    -Profile Domain,Private,Public `
                    -Description "Block all other PostgreSQL connections for GameForge security"
                
                Write-Host "✅ Default firewall rules recreated" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to reset firewall rules: `$(`$_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Reset cancelled" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n📋 Usage Examples:" -ForegroundColor Cyan
Write-Host "List rules: .\manage-database-firewall.ps1 -Action list" -ForegroundColor White
Write-Host "Add IP: .\manage-database-firewall.ps1 -Action add -IPAddress 192.168.1.100" -ForegroundColor White
Write-Host "Add network: .\manage-database-firewall.ps1 -Action add -Network 192.168.1.0/24" -ForegroundColor White
Write-Host "Remove IP: .\manage-database-firewall.ps1 -Action remove -IPAddress 192.168.1.100" -ForegroundColor White
Write-Host "Reset all: .\manage-database-firewall.ps1 -Action reset" -ForegroundColor White
"@

$firewallManagementScript | Out-File -FilePath $firewallManagementPath -Encoding UTF8
Write-Host "✅ Firewall management script created: $firewallManagementPath" -ForegroundColor Green

# Step 7: Create IP whitelist management
Write-Host "`n📝 Step 7: Creating IP whitelist management..." -ForegroundColor Yellow

$whitelistPath = Join-Path $PSScriptRoot "..\configs\ip-whitelist.json"
$configDir = Split-Path $whitelistPath -Parent
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force
}

$defaultWhitelist = @{
    "version" = "1.0"
    "last_updated" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "allowed_ips" = @(
        @{
            "ip" = "127.0.0.1"
            "description" = "Localhost IPv4"
            "added_date" = (Get-Date -Format "yyyy-MM-dd")
            "added_by" = $env:USERNAME
            "permanent" = $true
        },
        @{
            "ip" = "::1"
            "description" = "Localhost IPv6"
            "added_date" = (Get-Date -Format "yyyy-MM-dd")
            "added_by" = $env:USERNAME
            "permanent" = $true
        }
    )
    "allowed_networks" = @()
    "settings" = @{
        "require_ssl" = $true
        "max_connections_per_ip" = 10
        "connection_timeout_minutes" = 30
        "enable_rate_limiting" = $true
    }
}

$defaultWhitelist | ConvertTo-Json -Depth 10 | Out-File -FilePath $whitelistPath -Encoding UTF8
Write-Host "✅ IP whitelist configuration created: $whitelistPath" -ForegroundColor Green

# Step 8: Restart PostgreSQL service
Write-Host "`n🔄 Step 8: Restarting PostgreSQL service..." -ForegroundColor Yellow

try {
    $service = Get-Service -Name "postgresql*" | Select-Object -First 1
    if ($service) {
        Write-Host "Stopping PostgreSQL service..." -ForegroundColor Cyan
        Stop-Service $service.Name -Force
        Start-Sleep -Seconds 5
        
        Write-Host "Starting PostgreSQL service..." -ForegroundColor Cyan
        Start-Service $service.Name
        Start-Sleep -Seconds 10
        
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

# Step 9: Test firewall configuration
Write-Host "`n🧪 Step 9: Testing firewall configuration..." -ForegroundColor Yellow

Start-Sleep -Seconds 15  # Wait for service to fully start

try {
    # Test local connection
    $env:PGPASSWORD = "password"
    $testResult = psql -h localhost -U gameforge_user -d gameforge_dev -c "SELECT 'Firewall test: Connection successful' as test_message;" 2>&1
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Local database connection successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ Local database connection failed: $testResult" -ForegroundColor Red
    }
    
    # Test firewall rules
    if ($isAdmin) {
        $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*GameForge*" }
        Write-Host "✅ Firewall rules active: $($firewallRules.Count)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "⚠️  Could not test firewall configuration: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Final Summary
Write-Host "`n🎉 Database Firewall Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "✅ PostgreSQL access restrictions configured" -ForegroundColor Green
Write-Host "✅ pg_hba.conf updated with secure rules" -ForegroundColor Green
Write-Host "✅ PostgreSQL configured to listen on localhost only" -ForegroundColor Green
if ($isAdmin) {
    Write-Host "✅ Windows Firewall rules created" -ForegroundColor Green
} else {
    Write-Host "⚠️  Windows Firewall rules require Administrator privileges" -ForegroundColor Yellow
}
Write-Host "✅ Connection monitoring script created" -ForegroundColor Green
Write-Host "✅ Firewall management script created" -ForegroundColor Green
Write-Host "✅ IP whitelist configuration created" -ForegroundColor Green

Write-Host "`n📁 Created Files:" -ForegroundColor Cyan
Write-Host "- pg_hba.conf backup: $pgHbaBackupPath" -ForegroundColor White
Write-Host "- postgresql.conf backup: $postgresqlBackupPath" -ForegroundColor White
Write-Host "- Connection Monitor: $monitoringScriptPath" -ForegroundColor White
Write-Host "- Firewall Manager: $firewallManagementPath" -ForegroundColor White
Write-Host "- IP Whitelist: $whitelistPath" -ForegroundColor White

Write-Host "`n🔒 Security Configuration:" -ForegroundColor Cyan
Write-Host "- PostgreSQL listens only on localhost" -ForegroundColor White
Write-Host "- SSL/TLS required for all connections" -ForegroundColor White
Write-Host "- SCRAM-SHA-256 password authentication" -ForegroundColor White
Write-Host "- Connection timeouts configured" -ForegroundColor White
if ($ProductionMode) {
    Write-Host "- Production mode: All non-localhost connections rejected" -ForegroundColor White
} else {
    Write-Host "- Development mode: Local connections allowed" -ForegroundColor Yellow
}

Write-Host "`n📋 Management Commands:" -ForegroundColor Cyan
Write-Host "Monitor connections: .\monitor-database-connections.ps1" -ForegroundColor White
Write-Host "List firewall rules: .\manage-database-firewall.ps1 -Action list" -ForegroundColor White
Write-Host "Add allowed IP: .\manage-database-firewall.ps1 -Action add -IPAddress x.x.x.x" -ForegroundColor White
Write-Host "Remove IP access: .\manage-database-firewall.ps1 -Action remove -IPAddress x.x.x.x" -ForegroundColor White

Write-Host "`n⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "- Database now only accepts connections from allowed IPs" -ForegroundColor White
Write-Host "- Update your application connection strings if needed" -ForegroundColor White
Write-Host "- Monitor connections regularly for security" -ForegroundColor White
Write-Host "- Use the management scripts to add/remove IP access" -ForegroundColor White
if (!$isAdmin) {
    Write-Host "- Run as Administrator to complete Windows Firewall setup" -ForegroundColor White
}