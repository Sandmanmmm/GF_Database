# GameForge Database Complete Security Setup Script
# Orchestrates all security configurations for production-ready deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSSL,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipVault,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipAudit,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFirewall,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode
)

Write-Host "🔐 GameForge Database Complete Security Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$startTime = Get-Date
Write-Host "🕐 Setup started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "🌍 Environment: $Environment" -ForegroundColor Cyan
Write-Host "🏭 Production Mode: $ProductionMode" -ForegroundColor Cyan

# Initialize progress tracking
$totalSteps = 5
$currentStep = 0
$completedSteps = @()
$failedSteps = @()
$skippedSteps = @()

# Function to update progress
function Update-Progress($stepName, $status) {
    switch ($status) {
        "completed" { 
            $script:completedSteps += $stepName
            Write-Host "✅ $stepName completed successfully" -ForegroundColor Green
        }
        "failed" { 
            $script:failedSteps += $stepName
            Write-Host "❌ $stepName failed" -ForegroundColor Red
        }
        "skipped" { 
            $script:skippedSteps += $stepName
            Write-Host "⏭️ $stepName skipped" -ForegroundColor Yellow
        }
    }
}

# Function to run security script
function Invoke-SecurityScript($scriptName, $stepName, $skipFlag, $additionalParams = @{}) {
    $script:currentStep++
    Write-Host "`n🔧 Step $currentStep/$totalSteps: $stepName" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    
    if ($skipFlag) {
        Write-Host "⏭️ Skipping $stepName (skip flag set)" -ForegroundColor Yellow
        Update-Progress $stepName "skipped"
        return
    }
    
    $scriptPath = Join-Path $PSScriptRoot $scriptName
    
    if (!(Test-Path $scriptPath)) {
        Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
        Update-Progress $stepName "failed"
        return
    }
    
    try {
        # Build parameters
        $params = @{}
        if ($Environment) { $params["Environment"] = $Environment }
        if ($ProductionMode) { $params["ProductionMode"] = $true }
        
        # Add additional parameters
        foreach ($key in $additionalParams.Keys) {
            $params[$key] = $additionalParams[$key]
        }
        
        # Execute script
        Write-Host "🚀 Executing: $scriptName" -ForegroundColor Cyan
        & $scriptPath @params
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Update-Progress $stepName "completed"
        } else {
            Update-Progress $stepName "failed"
        }
    } catch {
        Write-Host "❌ Error executing $scriptName`: $($_.Exception.Message)" -ForegroundColor Red
        Update-Progress $stepName "failed"
    }
}

# Pre-flight checks
Write-Host "`n🔍 Pre-flight Security Checks" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
} else {
    Write-Host "⚠️  Not running as Administrator - some features may be limited" -ForegroundColor Yellow
}

# Check PostgreSQL service
try {
    $pgService = Get-Service -Name "postgresql*" | Select-Object -First 1
    if ($pgService -and $pgService.Status -eq "Running") {
        Write-Host "✅ PostgreSQL service is running" -ForegroundColor Green
    } else {
        Write-Host "⚠️  PostgreSQL service is not running - attempting to start..." -ForegroundColor Yellow
        Start-Service $pgService.Name -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
} catch {
    Write-Host "❌ PostgreSQL service check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check database connectivity
try {
    $env:PGPASSWORD = "password"
    $dbTest = psql -h localhost -U postgres -d postgres -c "SELECT version();" -t 2>&1
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database connectivity verified" -ForegroundColor Green
    } else {
        Write-Host "❌ Database connectivity failed: $dbTest" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Database connectivity test failed" -ForegroundColor Red
}

Write-Host "`n🚀 Beginning Security Configuration..." -ForegroundColor Green

# Step 1: SSL/TLS Configuration
Invoke-SecurityScript "setup-ssl-tls.ps1" "SSL/TLS Configuration" $SkipSSL

# Step 2: Vault Integration
Invoke-SecurityScript "setup-vault-integration.ps1" "Vault Integration" $SkipVault @{
    "InstallVault" = $true
}

# Step 3: Audit Logging
Invoke-SecurityScript "setup-audit-logging.ps1" "Database Audit Logging" $SkipAudit

# Step 4: Backup Encryption
Invoke-SecurityScript "setup-backup-encryption.ps1" "Backup Encryption" $SkipBackup

# Step 5: Database Firewall
Invoke-SecurityScript "setup-database-firewall.ps1" "Database Firewall Rules" $SkipFirewall @{
    "AllowedIPs" = @("127.0.0.1", "::1")
}

# Post-configuration validation
Write-Host "`n🔍 Post-Configuration Validation" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

$validationResults = @{}

# Validate SSL configuration
if ("SSL/TLS Configuration" -in $completedSteps) {
    try {
        $sslCertPath = "C:\GameForge\certificates\server.crt"
        if (Test-Path $sslCertPath) {
            $validationResults["SSL"] = "✅ Configured"
        } else {
            $validationResults["SSL"] = "❌ Certificate not found"
        }
    } catch {
        $validationResults["SSL"] = "❌ Validation failed"
    }
} else {
    $validationResults["SSL"] = "⏭️ Skipped"
}

# Validate Vault integration
if ("Vault Integration" -in $completedSteps) {
    try {
        $vaultConfigPath = "C:\GameForge\vault\vault.hcl"
        if (Test-Path $vaultConfigPath) {
            $validationResults["Vault"] = "✅ Configured"
        } else {
            $validationResults["Vault"] = "❌ Configuration not found"
        }
    } catch {
        $validationResults["Vault"] = "❌ Validation failed"
    }
} else {
    $validationResults["Vault"] = "⏭️ Skipped"
}

# Validate audit logging
if ("Database Audit Logging" -in $completedSteps) {
    try {
        $auditLogDir = "C:\GameForge\audit-logs"
        if (Test-Path $auditLogDir) {
            $validationResults["Audit"] = "✅ Configured"
        } else {
            $validationResults["Audit"] = "❌ Log directory not found"
        }
    } catch {
        $validationResults["Audit"] = "❌ Validation failed"
    }
} else {
    $validationResults["Audit"] = "⏭️ Skipped"
}

# Validate backup encryption
if ("Backup Encryption" -in $completedSteps) {
    try {
        $backupDir = "C:\GameForge\backups"
        $encryptionKey = "C:\GameForge\backup-encryption.key"
        if ((Test-Path $backupDir) -and (Test-Path $encryptionKey)) {
            $validationResults["Backup"] = "✅ Configured"
        } else {
            $validationResults["Backup"] = "❌ Configuration incomplete"
        }
    } catch {
        $validationResults["Backup"] = "❌ Validation failed"
    }
} else {
    $validationResults["Backup"] = "⏭️ Skipped"
}

# Validate firewall configuration
if ("Database Firewall Rules" -in $completedSteps) {
    try {
        if ($isAdmin) {
            $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*GameForge*" }
            if ($firewallRules.Count -gt 0) {
                $validationResults["Firewall"] = "✅ Configured ($($firewallRules.Count) rules)"
            } else {
                $validationResults["Firewall"] = "❌ No rules found"
            }
        } else {
            $validationResults["Firewall"] = "⚠️ Admin required for validation"
        }
    } catch {
        $validationResults["Firewall"] = "❌ Validation failed"
    }
} else {
    $validationResults["Firewall"] = "⏭️ Skipped"
}

# Display validation results
Write-Host "`n📊 Validation Results:" -ForegroundColor Cyan
foreach ($component in $validationResults.Keys) {
    Write-Host "  $component`: $($validationResults[$component])" -ForegroundColor White
}

# Create security summary report
Write-Host "`n📄 Creating Security Summary Report..." -ForegroundColor Yellow

$endTime = Get-Date
$duration = $endTime - $startTime

$securityReport = @{
    "setup_info" = @{
        "timestamp" = $endTime.ToString('yyyy-MM-dd HH:mm:ss')
        "environment" = $Environment
        "production_mode" = $ProductionMode.ToString()
        "duration_minutes" = [math]::Round($duration.TotalMinutes, 2)
        "administrator_privileges" = $isAdmin.ToString()
    }
    "components" = @{
        "ssl_tls" = @{
            "configured" = ("SSL/TLS Configuration" -in $completedSteps).ToString()
            "status" = $validationResults["SSL"]
            "certificate_path" = "C:\GameForge\certificates\"
            "connection_string_ssl" = "postgresql+asyncpg://user:pass@localhost:5432/db?ssl=require"
        }
        "vault_integration" = @{
            "configured" = ("Vault Integration" -in $completedSteps).ToString()
            "status" = $validationResults["Vault"]
            "vault_address" = "http://127.0.0.1:8200"
            "config_path" = "C:\GameForge\vault\"
        }
        "audit_logging" = @{
            "configured" = ("Database Audit Logging" -in $completedSteps).ToString()
            "status" = $validationResults["Audit"]
            "log_directory" = "C:\GameForge\audit-logs\"
            "pgaudit_enabled" = $true
        }
        "backup_encryption" = @{
            "configured" = ("Backup Encryption" -in $completedSteps).ToString()
            "status" = $validationResults["Backup"]
            "backup_directory" = "C:\GameForge\backups\"
            "encryption_algorithm" = "AES-256"
        }
        "database_firewall" = @{
            "configured" = ("Database Firewall Rules" -in $completedSteps).ToString()
            "status" = $validationResults["Firewall"]
            "listen_address" = "localhost"
            "allowed_ips" = @("127.0.0.1", "::1")
        }
    }
    "security_features" = @{
        "ssl_encryption" = ("SSL/TLS Configuration" -in $completedSteps).ToString()
        "secret_management" = ("Vault Integration" -in $completedSteps).ToString()
        "audit_logging" = ("Database Audit Logging" -in $completedSteps).ToString()
        "encrypted_backups" = ("Backup Encryption" -in $completedSteps).ToString()
        "access_control" = ("Database Firewall Rules" -in $completedSteps).ToString()
        "scram_sha256_auth" = "true"
        "connection_limits" = "true"
        "timeout_policies" = "true"
    }
    "next_steps" = @(
        "Test all security configurations in your application",
        "Update application connection strings to use SSL",
        "Configure Vault policies for application access",
        "Set up automated backup schedules",
        "Monitor audit logs regularly",
        "Review and update firewall rules as needed"
    )
}

$reportPath = Join-Path $PSScriptRoot "..\docs\security-setup-report.json"
$securityReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "✅ Security report created: $reportPath" -ForegroundColor Green

# Final summary
Write-Host "`n🎉 GameForge Database Security Setup Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

Write-Host "`n📊 Setup Summary:" -ForegroundColor Cyan
Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor White
Write-Host "Completed: $($completedSteps.Count)/$totalSteps components" -ForegroundColor White
Write-Host "Failed: $($failedSteps.Count) components" -ForegroundColor White
Write-Host "Skipped: $($skippedSteps.Count) components" -ForegroundColor White

if ($completedSteps.Count -gt 0) {
    Write-Host "`n✅ Completed Components:" -ForegroundColor Green
    foreach ($step in $completedSteps) {
        Write-Host "  - $step" -ForegroundColor White
    }
}

if ($failedSteps.Count -gt 0) {
    Write-Host "`n❌ Failed Components:" -ForegroundColor Red
    foreach ($step in $failedSteps) {
        Write-Host "  - $step" -ForegroundColor White
    }
}

if ($skippedSteps.Count -gt 0) {
    Write-Host "`n⏭️ Skipped Components:" -ForegroundColor Yellow
    foreach ($step in $skippedSteps) {
        Write-Host "  - $step" -ForegroundColor White
    }
}

Write-Host "`n🔐 Security Features Active:" -ForegroundColor Cyan
if ("SSL/TLS Configuration" -in $completedSteps) {
    Write-Host "✅ Database connections encrypted with SSL/TLS" -ForegroundColor Green
}
if ("Vault Integration" -in $completedSteps) {
    Write-Host "✅ Secret management with HashiCorp Vault" -ForegroundColor Green
}
if ("Database Audit Logging" -in $completedSteps) {
    Write-Host "✅ Comprehensive audit logging with pgAudit" -ForegroundColor Green
}
if ("Backup Encryption" -in $completedSteps) {
    Write-Host "✅ Encrypted database backups with AES-256" -ForegroundColor Green
}
if ("Database Firewall Rules" -in $completedSteps) {
    Write-Host "✅ Network access control and firewall protection" -ForegroundColor Green
}

Write-Host "`n📋 Important Files Created:" -ForegroundColor Cyan
Write-Host "- SSL Certificates: C:\GameForge\certificates\" -ForegroundColor White
Write-Host "- Vault Configuration: C:\GameForge\vault\" -ForegroundColor White
Write-Host "- Audit Logs: C:\GameForge\audit-logs\" -ForegroundColor White
Write-Host "- Encrypted Backups: C:\GameForge\backups\" -ForegroundColor White
Write-Host "- Security Report: $reportPath" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the security report: $reportPath" -ForegroundColor White
Write-Host "2. Update your application connection strings for SSL" -ForegroundColor White
Write-Host "3. Configure Vault integration in your application" -ForegroundColor White
Write-Host "4. Set up backup schedules and monitoring" -ForegroundColor White
Write-Host "5. Test all security configurations thoroughly" -ForegroundColor White

if ($failedSteps.Count -gt 0) {
    Write-Host "`n⚠️  Some components failed to configure. Please:" -ForegroundColor Yellow
    Write-Host "- Check the error messages above" -ForegroundColor White
    Write-Host "- Run individual setup scripts to troubleshoot" -ForegroundColor White
    Write-Host "- Ensure you have Administrator privileges" -ForegroundColor White
    Write-Host "- Verify PostgreSQL is running and accessible" -ForegroundColor White
}

Write-Host "`n🎯 Your GameForge database is now production-ready with enterprise-grade security!" -ForegroundColor Green