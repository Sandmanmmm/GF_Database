# GameForge Database Security Management Script
# Provides unified management interface for all security components

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("status", "start", "stop", "restart", "rotate", "backup", "test", "monitor", "maintenance")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("ssl", "vault", "audit", "backup", "firewall", "all")]
    [string]$Component = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

Write-Host "🔐 GameForge Database Security Management" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "🕐 Operation: $Action on $Component at $timestamp" -ForegroundColor Cyan

# Security component definitions
$securityComponents = @{
    "ssl" = @{
        "name" = "SSL/TLS Configuration"
        "cert_path" = "C:\GameForge\certificates"
        "config_files" = @("C:\Program Files\PostgreSQL\17\data\postgresql.conf", "C:\Program Files\PostgreSQL\17\data\pg_hba.conf")
        "validation_script" = "test-ssl-connection.ps1"
    }
    "vault" = @{
        "name" = "HashiCorp Vault"
        "config_path" = "C:\GameForge\vault"
        "service_name" = "vault"
        "address" = "http://127.0.0.1:8200"
        "management_script" = "manage-vault.ps1"
    }
    "audit" = @{
        "name" = "Database Audit Logging"
        "log_path" = "C:\GameForge\audit-logs"
        "extension" = "pgaudit"
        "rotation_script" = "rotate-audit-logs.ps1"
    }
    "backup" = @{
        "name" = "Encrypted Backup System"
        "backup_path" = "C:\GameForge\backups"
        "encryption_key" = "C:\GameForge\backup-encryption.key"
        "backup_script" = "create-encrypted-backup.ps1"
    }
    "firewall" = @{
        "name" = "Database Firewall Rules"
        "whitelist_path" = "C:\GameForge\security\ip-whitelist.json"
        "monitoring_script" = "monitor-database-connections.ps1"
        "management_script" = "manage-database-firewall.ps1"
    }
}

# Function to check component status
function Get-ComponentStatus($componentKey) {
    $component = $securityComponents[$componentKey]
    $status = @{
        "name" = $component.name
        "status" = "unknown"
        "details" = @()
    }
    
    switch ($componentKey) {
        "ssl" {
            try {
                $certExists = Test-Path (Join-Path $component.cert_path "server.crt")
                $keyExists = Test-Path (Join-Path $component.cert_path "server.key")
                
                if ($certExists -and $keyExists) {
                    # Check certificate expiry
                    $certInfo = openssl x509 -in (Join-Path $component.cert_path "server.crt") -text -noout 2>$null
                    if ($certInfo) {
                        $status.status = "active"
                        $status.details += "Certificate and key files present"
                        
                        # Parse expiry date
                        $expiryMatch = [regex]::Match($certInfo, "Not After\s*:\s*(.+)")
                        if ($expiryMatch.Success) {
                            $expiryDate = [DateTime]::Parse($expiryMatch.Groups[1].Value)
                            $daysUntilExpiry = ($expiryDate - (Get-Date)).Days
                            $status.details += "Certificate expires in $daysUntilExpiry days"
                            
                            if ($daysUntilExpiry -lt 30) {
                                $status.status = "warning"
                                $status.details += "⚠️ Certificate expires soon!"
                            }
                        }
                    } else {
                        $status.status = "error"
                        $status.details += "Certificate files exist but cannot be read"
                    }
                } else {
                    $status.status = "inactive"
                    $status.details += "Certificate or key files missing"
                }
            } catch {
                $status.status = "error"
                $status.details += "Error checking SSL status: $($_.Exception.Message)"
            }
        }
        
        "vault" {
            try {
                $vaultProcess = Get-Process -Name "vault" -ErrorAction SilentlyContinue
                if ($vaultProcess) {
                    # Try to check vault status
                    $env:VAULT_ADDR = $component.address
                    $vaultStatus = vault status 2>&1
                    Remove-Item Env:\VAULT_ADDR -ErrorAction SilentlyContinue
                    
                    if ($LASTEXITCODE -eq 0) {
                        $status.status = "active"
                        $status.details += "Vault process running and accessible"
                    } elseif ($vaultStatus -like "*sealed*") {
                        $status.status = "sealed"
                        $status.details += "Vault is sealed"
                    } else {
                        $status.status = "error"
                        $status.details += "Vault process running but not responding properly"
                    }
                } else {
                    $status.status = "inactive"
                    $status.details += "Vault process not running"
                }
            } catch {
                $status.status = "error"
                $status.details += "Error checking Vault status: $($_.Exception.Message)"
            }
        }
        
        "audit" {
            try {
                $logDirExists = Test-Path $component.log_path
                if ($logDirExists) {
                    # Check for recent audit logs
                    $recentLogs = Get-ChildItem $component.log_path -Filter "*.log" | 
                                 Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) }
                    
                    if ($recentLogs.Count -gt 0) {
                        $status.status = "active"
                        $status.details += "Audit logging active with recent logs"
                        $status.details += "Recent log files: $($recentLogs.Count)"
                    } else {
                        $status.status = "warning"
                        $status.details += "Audit log directory exists but no recent activity"
                    }
                    
                    # Check disk usage
                    $logSize = (Get-ChildItem $component.log_path -Recurse | Measure-Object -Property Length -Sum).Sum
                    $logSizeMB = [math]::Round($logSize / 1MB, 2)
                    $status.details += "Total log size: $logSizeMB MB"
                } else {
                    $status.status = "inactive"
                    $status.details += "Audit log directory not found"
                }
            } catch {
                $status.status = "error"
                $status.details += "Error checking audit status: $($_.Exception.Message)"
            }
        }
        
        "backup" {
            try {
                $backupDirExists = Test-Path $component.backup_path
                $keyExists = Test-Path $component.encryption_key
                
                if ($backupDirExists -and $keyExists) {
                    # Check for recent backups
                    $recentBackups = Get-ChildItem $component.backup_path -Filter "*.7z" | 
                                    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }
                    
                    if ($recentBackups.Count -gt 0) {
                        $status.status = "active"
                        $status.details += "Backup system active with recent backups"
                        $status.details += "Recent backups: $($recentBackups.Count)"
                        
                        # Show latest backup
                        $latestBackup = $recentBackups | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                        $status.details += "Latest: $($latestBackup.Name) ($([math]::Round($latestBackup.Length / 1MB, 2)) MB)"
                    } else {
                        $status.status = "warning"
                        $status.details += "Backup system configured but no recent backups"
                    }
                } else {
                    $status.status = "inactive"
                    $status.details += "Backup directory or encryption key missing"
                }
            } catch {
                $status.status = "error"
                $status.details += "Error checking backup status: $($_.Exception.Message)"
            }
        }
        
        "firewall" {
            try {
                $whitelistExists = Test-Path $component.whitelist_path
                
                # Check Windows Firewall rules
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
                
                if ($isAdmin) {
                    $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*GameForge*" -and $_.Enabled -eq "True" }
                    
                    if ($firewallRules.Count -gt 0 -and $whitelistExists) {
                        $status.status = "active"
                        $status.details += "Firewall rules active: $($firewallRules.Count) rules"
                        $status.details += "IP whitelist configured"
                    } elseif ($firewallRules.Count -gt 0) {
                        $status.status = "warning"
                        $status.details += "Firewall rules active but whitelist missing"
                    } else {
                        $status.status = "inactive"
                        $status.details += "No GameForge firewall rules found"
                    }
                } else {
                    $status.status = "warning"
                    $status.details += "Administrator privileges required for firewall status"
                    if ($whitelistExists) {
                        $status.details += "IP whitelist file exists"
                    }
                }
            } catch {
                $status.status = "error"
                $status.details += "Error checking firewall status: $($_.Exception.Message)"
            }
        }
    }
    
    return $status
}

# Function to display status with colors
function Show-StatusWithColor($status) {
    switch ($status.status) {
        "active" { $color = "Green"; $icon = "✅" }
        "warning" { $color = "Yellow"; $icon = "⚠️" }
        "inactive" { $color = "Red"; $icon = "❌" }
        "error" { $color = "Red"; $icon = "🔥" }
        "sealed" { $color = "Yellow"; $icon = "🔒" }
        default { $color = "Gray"; $icon = "❓" }
    }
    
    Write-Host "$icon $($status.name): $($status.status.ToUpper())" -ForegroundColor $color
    foreach ($detail in $status.details) {
        Write-Host "   $detail" -ForegroundColor White
    }
}

# Main action handling
switch ($Action) {
    "status" {
        Write-Host "`n📊 Security Component Status" -ForegroundColor Yellow
        Write-Host "============================" -ForegroundColor Yellow
        
        if ($Component -eq "all") {
            foreach ($componentKey in $securityComponents.Keys) {
                $status = Get-ComponentStatus $componentKey
                Show-StatusWithColor $status
                Write-Host ""
            }
        } else {
            $status = Get-ComponentStatus $Component
            Show-StatusWithColor $status
        }
    }
    
    "start" {
        Write-Host "`n🚀 Starting Security Component: $Component" -ForegroundColor Yellow
        
        if ($Component -eq "vault" -or $Component -eq "all") {
            Write-Host "Starting HashiCorp Vault..." -ForegroundColor Cyan
            try {
                $vaultConfigPath = "C:\GameForge\vault\vault.hcl"
                if (Test-Path $vaultConfigPath) {
                    Start-Process -FilePath "vault" -ArgumentList "server", "-config=$vaultConfigPath" -WindowStyle Hidden
                    Start-Sleep -Seconds 3
                    Write-Host "✅ Vault server started" -ForegroundColor Green
                } else {
                    Write-Host "❌ Vault configuration not found" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Failed to start Vault: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Other components don't need explicit starting as they're configurations
        if ($Component -ne "vault" -and $Component -ne "all") {
            Write-Host "✅ $Component is configuration-based and doesn't require starting" -ForegroundColor Green
        }
    }
    
    "stop" {
        Write-Host "`n🛑 Stopping Security Component: $Component" -ForegroundColor Yellow
        
        if ($Component -eq "vault" -or $Component -eq "all") {
            Write-Host "Stopping HashiCorp Vault..." -ForegroundColor Cyan
            try {
                $vaultProcesses = Get-Process -Name "vault" -ErrorAction SilentlyContinue
                if ($vaultProcesses) {
                    $vaultProcesses | Stop-Process -Force
                    Write-Host "✅ Vault server stopped" -ForegroundColor Green
                } else {
                    Write-Host "ℹ️ Vault is not running" -ForegroundColor Blue
                }
            } catch {
                Write-Host "❌ Failed to stop Vault: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        if ($Component -ne "vault" -and $Component -ne "all") {
            Write-Host "ℹ️ $Component is configuration-based and doesn't require stopping" -ForegroundColor Blue
        }
    }
    
    "restart" {
        Write-Host "`n🔄 Restarting Security Component: $Component" -ForegroundColor Yellow
        
        # Stop then start
        & $PSCommandPath -Action stop -Component $Component
        Start-Sleep -Seconds 2
        & $PSCommandPath -Action start -Component $Component
    }
    
    "rotate" {
        Write-Host "`n🔄 Rotating Security Component: $Component" -ForegroundColor Yellow
        
        switch ($Component) {
            "ssl" {
                Write-Host "Rotating SSL certificates..." -ForegroundColor Cyan
                $sslScript = Join-Path $PSScriptRoot "setup-ssl-tls.ps1"
                if (Test-Path $sslScript) {
                    & $sslScript -RenewCertificates
                } else {
                    Write-Host "❌ SSL setup script not found" -ForegroundColor Red
                }
            }
            "audit" {
                Write-Host "Rotating audit logs..." -ForegroundColor Cyan
                $rotateScript = Join-Path $PSScriptRoot "rotate-audit-logs.ps1"
                if (Test-Path $rotateScript) {
                    & $rotateScript
                } else {
                    Write-Host "❌ Audit log rotation script not found" -ForegroundColor Red
                }
            }
            "backup" {
                Write-Host "Rotating backup encryption key..." -ForegroundColor Cyan
                Write-Host "⚠️ Backup key rotation requires manual intervention" -ForegroundColor Yellow
                Write-Host "Please run setup-backup-encryption.ps1 with -RotateKey parameter" -ForegroundColor Yellow
            }
            default {
                Write-Host "❌ Rotation not supported for $Component" -ForegroundColor Red
            }
        }
    }
    
    "backup" {
        Write-Host "`n💾 Creating Security Backup" -ForegroundColor Yellow
        
        $backupScript = Join-Path $PSScriptRoot "create-encrypted-backup.ps1"
        if (Test-Path $backupScript) {
            & $backupScript
        } else {
            Write-Host "❌ Backup script not found" -ForegroundColor Red
        }
    }
    
    "test" {
        Write-Host "`n🧪 Testing Security Component: $Component" -ForegroundColor Yellow
        
        switch ($Component) {
            "ssl" {
                Write-Host "Testing SSL connection..." -ForegroundColor Cyan
                try {
                    $env:PGPASSWORD = "password"
                    $sslTest = psql -h localhost -U postgres -d postgres -c "SHOW ssl;" 2>&1
                    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
                    
                    if ($sslTest -like "*on*") {
                        Write-Host "✅ SSL is enabled" -ForegroundColor Green
                    } else {
                        Write-Host "❌ SSL test failed: $sslTest" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "❌ SSL test error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            "vault" {
                Write-Host "Testing Vault connection..." -ForegroundColor Cyan
                try {
                    $env:VAULT_ADDR = "http://127.0.0.1:8200"
                    $vaultStatus = vault status 2>&1
                    Remove-Item Env:\VAULT_ADDR -ErrorAction SilentlyContinue
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Vault is accessible" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️ Vault status: $vaultStatus" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "❌ Vault test error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            "audit" {
                Write-Host "Testing audit logging..." -ForegroundColor Cyan
                try {
                    $env:PGPASSWORD = "password"
                    $auditTest = psql -h localhost -U postgres -d postgres -c "SHOW shared_preload_libraries;" 2>&1
                    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
                    
                    if ($auditTest -like "*pgaudit*") {
                        Write-Host "✅ pgAudit extension is loaded" -ForegroundColor Green
                    } else {
                        Write-Host "❌ pgAudit not found in shared_preload_libraries" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "❌ Audit test error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            "all" {
                foreach ($comp in @("ssl", "vault", "audit")) {
                    & $PSCommandPath -Action test -Component $comp
                    Write-Host ""
                }
            }
            default {
                Write-Host "❌ Testing not implemented for $Component" -ForegroundColor Red
            }
        }
    }
    
    "monitor" {
        Write-Host "`n👁️ Starting Security Monitoring" -ForegroundColor Yellow
        
        $monitoringScript = Join-Path $PSScriptRoot "monitor-database-connections.ps1"
        if (Test-Path $monitoringScript) {
            & $monitoringScript
        } else {
            Write-Host "❌ Monitoring script not found" -ForegroundColor Red
        }
    }
    
    "maintenance" {
        Write-Host "`n🔧 Running Security Maintenance" -ForegroundColor Yellow
        
        # Run status check
        & $PSCommandPath -Action status -Component all
        
        # Clean up old logs
        Write-Host "`n🧹 Cleaning up old logs..." -ForegroundColor Cyan
        $auditLogPath = "C:\GameForge\audit-logs"
        if (Test-Path $auditLogPath) {
            $oldLogs = Get-ChildItem $auditLogPath -Filter "*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
            if ($oldLogs.Count -gt 0) {
                $oldLogs | Remove-Item -Force
                Write-Host "✅ Removed $($oldLogs.Count) old audit log files" -ForegroundColor Green
            } else {
                Write-Host "ℹ️ No old audit logs to clean up" -ForegroundColor Blue
            }
        }
        
        # Clean up old backups
        Write-Host "🧹 Cleaning up old backups..." -ForegroundColor Cyan
        $backupPath = "C:\GameForge\backups"
        if (Test-Path $backupPath) {
            $oldBackups = Get-ChildItem $backupPath -Filter "*.7z" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) }
            if ($oldBackups.Count -gt 0) {
                $oldBackups | Remove-Item -Force
                Write-Host "✅ Removed $($oldBackups.Count) old backup files" -ForegroundColor Green
            } else {
                Write-Host "ℹ️ No old backups to clean up" -ForegroundColor Blue
            }
        }
        
        Write-Host "`n✅ Security maintenance completed" -ForegroundColor Green
    }
}

Write-Host "`n🔐 Security management operation completed" -ForegroundColor Green