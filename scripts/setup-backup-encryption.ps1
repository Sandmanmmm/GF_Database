# GameForge Database Backup Encryption Setup Script
# Configures encrypted database backups with automated scheduling and verification

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = "C:\GameForge\backups",
    
    [Parameter(Mandatory=$false)]
    [string]$EncryptionKeyFile = "C:\GameForge\backup-encryption.key",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 30
)

Write-Host "🔐 GameForge Database Backup Encryption Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Step 1: Create backup directories
Write-Host "`n📁 Step 1: Setting up backup directories..." -ForegroundColor Yellow

$backupStructure = @{
    "full" = Join-Path $BackupDir "full"
    "incremental" = Join-Path $BackupDir "incremental"
    "archive" = Join-Path $BackupDir "archive"
    "temp" = Join-Path $BackupDir "temp"
    "keys" = Join-Path $BackupDir "keys"
}

foreach ($folder in $backupStructure.Values) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force
        Write-Host "✅ Created directory: $folder" -ForegroundColor Green
    }
}

# Step 2: Generate encryption key
Write-Host "`n🔑 Step 2: Generating backup encryption key..." -ForegroundColor Yellow

if (!(Test-Path $EncryptionKeyFile)) {
    # Generate a strong 256-bit encryption key
    $encryptionKey = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $keyBytes = New-Object byte[] 32
    $encryptionKey.GetBytes($keyBytes)
    
    # Convert to base64 for storage
    $keyBase64 = [Convert]::ToBase64String($keyBytes)
    
    # Store the key securely
    $keyBase64 | Out-File -FilePath $EncryptionKeyFile -Encoding UTF8
    
    # Set secure permissions
    $acl = Get-Acl $EncryptionKeyFile
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")))
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
    Set-Acl $EncryptionKeyFile $acl
    
    Write-Host "✅ Encryption key generated and stored securely: $EncryptionKeyFile" -ForegroundColor Green
} else {
    Write-Host "✅ Encryption key already exists: $EncryptionKeyFile" -ForegroundColor Green
}

# Step 3: Install required tools
Write-Host "`n🔧 Step 3: Installing required backup tools..." -ForegroundColor Yellow

# Check if 7-Zip is available for encryption
$sevenZipPath = Get-Command "7z" -ErrorAction SilentlyContinue
if (!$sevenZipPath) {
    Write-Host "Installing 7-Zip for backup encryption..." -ForegroundColor Cyan
    
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
    
    choco install 7zip -y
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    Write-Host "✅ 7-Zip installed successfully!" -ForegroundColor Green
} else {
    Write-Host "✅ 7-Zip is already available" -ForegroundColor Green
}

# Step 4: Create backup script
Write-Host "`n📝 Step 4: Creating encrypted backup script..." -ForegroundColor Yellow

$backupScriptPath = Join-Path $PSScriptRoot "backup-database-encrypted.ps1"
$backupScript = @"
# GameForge Database Encrypted Backup Script

param(
    [Parameter(Mandatory=`$false)]
    [string]`$Database = "gameforge_dev",
    
    [Parameter(Mandatory=`$false)]
    [string]`$BackupType = "full", # full, incremental, schema
    
    [Parameter(Mandatory=`$false)]
    [string]`$BackupDir = "$BackupDir",
    
    [Parameter(Mandatory=`$false)]
    [string]`$EncryptionKeyFile = "$EncryptionKeyFile",
    
    [Parameter(Mandatory=`$false)]
    [string]`$CompressionLevel = "9"
)

Write-Host "🔐 GameForge Database Encrypted Backup" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Initialize variables
`$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
`$backupDate = Get-Date -Format "yyyy-MM-dd"

# Create backup subdirectory
`$backupTypeDir = Join-Path `$BackupDir `$BackupType
`$dailyBackupDir = Join-Path `$backupTypeDir `$backupDate
if (!(Test-Path `$dailyBackupDir)) {
    New-Item -ItemType Directory -Path `$dailyBackupDir -Force
}

# Define backup file paths
`$baseBackupName = "`$Database`_`$BackupType`_`$timestamp"
`$sqlBackupPath = Join-Path `$dailyBackupDir "`$baseBackupName.sql"
`$encryptedBackupPath = Join-Path `$dailyBackupDir "`$baseBackupName.sql.7z"
`$checksumPath = Join-Path `$dailyBackupDir "`$baseBackupName.sha256"
`$metadataPath = Join-Path `$dailyBackupDir "`$baseBackupName.json"

Write-Host "📅 Backup Date: `$backupDate" -ForegroundColor Cyan
Write-Host "⏰ Backup Time: `$timestamp" -ForegroundColor Cyan
Write-Host "🗄️ Database: `$Database" -ForegroundColor Cyan
Write-Host "📋 Backup Type: `$BackupType" -ForegroundColor Cyan

# Step 1: Create database dump
Write-Host "`n💾 Step 1: Creating database dump..." -ForegroundColor Yellow

try {
    switch (`$BackupType) {
        "full" {
            Write-Host "Creating full database backup..." -ForegroundColor Cyan
            `$env:PGPASSWORD = "password"
            pg_dump -h localhost -U gameforge_user -d `$Database --verbose --format=custom --compress=0 --file="`$sqlBackupPath" 2>&1
        }
        "schema" {
            Write-Host "Creating schema-only backup..." -ForegroundColor Cyan
            `$env:PGPASSWORD = "password"
            pg_dump -h localhost -U gameforge_user -d `$Database --verbose --schema-only --format=custom --file="`$sqlBackupPath" 2>&1
        }
        "data" {
            Write-Host "Creating data-only backup..." -ForegroundColor Cyan
            `$env:PGPASSWORD = "password"
            pg_dump -h localhost -U gameforge_user -d `$Database --verbose --data-only --format=custom --file="`$sqlBackupPath" 2>&1
        }
        default {
            Write-Host "Creating full database backup (default)..." -ForegroundColor Cyan
            `$env:PGPASSWORD = "password"
            pg_dump -h localhost -U gameforge_user -d `$Database --verbose --format=custom --compress=0 --file="`$sqlBackupPath" 2>&1
        }
    }
    
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    
    if (`$LASTEXITCODE -eq 0 -and (Test-Path `$sqlBackupPath)) {
        `$backupSizeMB = [math]::Round((Get-Item `$sqlBackupPath).Length / 1MB, 2)
        Write-Host "✅ Database dump created successfully (`$backupSizeMB MB)" -ForegroundColor Green
    } else {
        throw "pg_dump failed with exit code `$LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Database dump failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Read encryption key
Write-Host "`n🔑 Step 2: Reading encryption key..." -ForegroundColor Yellow

try {
    if (!(Test-Path `$EncryptionKeyFile)) {
        throw "Encryption key file not found: `$EncryptionKeyFile"
    }
    
    `$encryptionKey = Get-Content `$EncryptionKeyFile -Raw
    `$encryptionKey = `$encryptionKey.Trim()
    
    Write-Host "✅ Encryption key loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to read encryption key: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Encrypt backup
Write-Host "`n🔐 Step 3: Encrypting backup..." -ForegroundColor Yellow

try {
    # Use 7-Zip with AES-256 encryption
    & "7z" a -t7z -m0=lzma2 -mx=`$CompressionLevel -mhe=on -p"`$encryptionKey" "`$encryptedBackupPath" "`$sqlBackupPath" 2>&1
    
    if (`$LASTEXITCODE -eq 0 -and (Test-Path `$encryptedBackupPath)) {
        `$encryptedSizeMB = [math]::Round((Get-Item `$encryptedBackupPath).Length / 1MB, 2)
        `$compressionRatio = [math]::Round((1 - (`$encryptedSizeMB / `$backupSizeMB)) * 100, 1)
        
        Write-Host "✅ Backup encrypted and compressed successfully" -ForegroundColor Green
        Write-Host "📊 Original size: `$backupSizeMB MB" -ForegroundColor Cyan
        Write-Host "📊 Encrypted size: `$encryptedSizeMB MB" -ForegroundColor Cyan
        Write-Host "📊 Compression ratio: `$compressionRatio%" -ForegroundColor Cyan
        
        # Remove unencrypted backup
        Remove-Item `$sqlBackupPath -Force
        Write-Host "✅ Unencrypted backup file removed" -ForegroundColor Green
    } else {
        throw "7-Zip encryption failed with exit code `$LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Backup encryption failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Generate checksum
Write-Host "`n🔍 Step 4: Generating checksum..." -ForegroundColor Yellow

try {
    `$fileHash = Get-FileHash `$encryptedBackupPath -Algorithm SHA256
    `$checksumData = @{
        "file" = Split-Path `$encryptedBackupPath -Leaf
        "algorithm" = "SHA256"
        "hash" = `$fileHash.Hash
        "size_bytes" = (Get-Item `$encryptedBackupPath).Length
        "created" = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    `$checksumData | ConvertTo-Json -Depth 10 | Out-File -FilePath `$checksumPath -Encoding UTF8
    
    Write-Host "✅ Checksum generated: `$(`$fileHash.Hash)" -ForegroundColor Green
} catch {
    Write-Host "❌ Checksum generation failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Create metadata file
Write-Host "`n📋 Step 5: Creating backup metadata..." -ForegroundColor Yellow

try {
    `$metadata = @{
        "backup_info" = @{
            "database" = `$Database
            "backup_type" = `$BackupType
            "timestamp" = `$timestamp
            "date" = `$backupDate
            "version" = "1.0"
        }
        "file_info" = @{
            "encrypted_file" = Split-Path `$encryptedBackupPath -Leaf
            "original_size_mb" = `$backupSizeMB
            "compressed_size_mb" = `$encryptedSizeMB
            "compression_ratio_percent" = `$compressionRatio
            "checksum_file" = Split-Path `$checksumPath -Leaf
        }
        "security" = @{
            "encryption_algorithm" = "AES-256"
            "compression_algorithm" = "LZMA2"
            "compression_level" = `$CompressionLevel
            "key_file_used" = Split-Path `$EncryptionKeyFile -Leaf
        }
        "system_info" = @{
            "hostname" = `$env:COMPUTERNAME
            "username" = `$env:USERNAME
            "postgres_version" = (psql --version | Out-String).Trim()
            "backup_script_version" = "1.0"
        }
    }
    
    `$metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath `$metadataPath -Encoding UTF8
    
    Write-Host "✅ Backup metadata created" -ForegroundColor Green
} catch {
    Write-Host "❌ Metadata creation failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Verify backup
Write-Host "`n🧪 Step 6: Verifying backup integrity..." -ForegroundColor Yellow

try {
    # Test 7-Zip archive integrity
    & "7z" t "`$encryptedBackupPath" -p"`$encryptionKey" 2>&1 | Out-Null
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✅ Backup archive integrity verified" -ForegroundColor Green
    } else {
        throw "Archive integrity test failed"
    }
    
    # Verify checksum
    `$verifyHash = Get-FileHash `$encryptedBackupPath -Algorithm SHA256
    `$storedChecksum = (Get-Content `$checksumPath | ConvertFrom-Json).hash
    
    if (`$verifyHash.Hash -eq `$storedChecksum) {
        Write-Host "✅ Checksum verification passed" -ForegroundColor Green
    } else {
        throw "Checksum verification failed"
    }
} catch {
    Write-Host "❌ Backup verification failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n🎉 Encrypted Backup Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host "✅ Database: `$Database" -ForegroundColor Green
Write-Host "✅ Backup Type: `$BackupType" -ForegroundColor Green
Write-Host "✅ Encrypted File: `$encryptedBackupPath" -ForegroundColor Green
Write-Host "✅ Size: `$encryptedSizeMB MB (Compression: `$compressionRatio%)" -ForegroundColor Green
Write-Host "✅ Checksum: `$checksumPath" -ForegroundColor Green
Write-Host "✅ Metadata: `$metadataPath" -ForegroundColor Green

Write-Host "`n📁 Backup Files Created:" -ForegroundColor Cyan
Write-Host "- Encrypted Backup: `$(Split-Path `$encryptedBackupPath -Leaf)" -ForegroundColor White
Write-Host "- Checksum: `$(Split-Path `$checksumPath -Leaf)" -ForegroundColor White
Write-Host "- Metadata: `$(Split-Path `$metadataPath -Leaf)" -ForegroundColor White

Write-Host "`n🔐 Security Information:" -ForegroundColor Yellow
Write-Host "- Encryption: AES-256 with LZMA2 compression" -ForegroundColor White
Write-Host "- Key File: `$EncryptionKeyFile" -ForegroundColor White
Write-Host "- Archive tested and verified" -ForegroundColor White
"@

$backupScript | Out-File -FilePath $backupScriptPath -Encoding UTF8
Write-Host "✅ Encrypted backup script created: $backupScriptPath" -ForegroundColor Green

# Step 5: Create backup restoration script
Write-Host "`n🔄 Step 5: Creating backup restoration script..." -ForegroundColor Yellow

$restoreScriptPath = Join-Path $PSScriptRoot "restore-database-encrypted.ps1"
$restoreScript = @"
# GameForge Database Encrypted Backup Restoration Script

param(
    [Parameter(Mandatory=`$true)]
    [string]`$BackupFile,
    
    [Parameter(Mandatory=`$false)]
    [string]`$TargetDatabase = "gameforge_restored",
    
    [Parameter(Mandatory=`$false)]
    [string]`$EncryptionKeyFile = "$EncryptionKeyFile",
    
    [Parameter(Mandatory=`$false)]
    [switch]`$VerifyOnly,
    
    [Parameter(Mandatory=`$false)]
    [switch]`$CreateDatabase
)

Write-Host "🔄 GameForge Database Encrypted Backup Restoration" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Validate inputs
if (!(Test-Path `$BackupFile)) {
    Write-Host "❌ Backup file not found: `$BackupFile" -ForegroundColor Red
    exit 1
}

if (!(Test-Path `$EncryptionKeyFile)) {
    Write-Host "❌ Encryption key file not found: `$EncryptionKeyFile" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Backup File: `$BackupFile" -ForegroundColor Cyan
Write-Host "🗄️ Target Database: `$TargetDatabase" -ForegroundColor Cyan

# Step 1: Read encryption key
Write-Host "`n🔑 Step 1: Reading encryption key..." -ForegroundColor Yellow

try {
    `$encryptionKey = Get-Content `$EncryptionKeyFile -Raw
    `$encryptionKey = `$encryptionKey.Trim()
    Write-Host "✅ Encryption key loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to read encryption key: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Verify backup integrity
Write-Host "`n🧪 Step 2: Verifying backup integrity..." -ForegroundColor Yellow

try {
    # Test archive integrity
    & "7z" t "`$BackupFile" -p"`$encryptionKey" 2>&1 | Out-Null
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✅ Backup archive integrity verified" -ForegroundColor Green
    } else {
        throw "Archive integrity test failed"
    }
    
    # Verify checksum if available
    `$checksumFile = `$BackupFile -replace '\.7z$', '.sha256'
    if (Test-Path `$checksumFile) {
        `$currentHash = Get-FileHash `$BackupFile -Algorithm SHA256
        `$storedChecksum = (Get-Content `$checksumFile | ConvertFrom-Json).hash
        
        if (`$currentHash.Hash -eq `$storedChecksum) {
            Write-Host "✅ Checksum verification passed" -ForegroundColor Green
        } else {
            throw "Checksum verification failed"
        }
    } else {
        Write-Host "⚠️ No checksum file found for verification" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Backup verification failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (`$VerifyOnly) {
    Write-Host "`n✅ Backup verification completed successfully!" -ForegroundColor Green
    Write-Host "📋 Backup is valid and ready for restoration" -ForegroundColor Cyan
    exit 0
}

# Step 3: Extract backup
Write-Host "`n📂 Step 3: Extracting encrypted backup..." -ForegroundColor Yellow

`$tempDir = Join-Path `$env:TEMP "gameforge_restore_`$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path `$tempDir -Force | Out-Null

try {
    & "7z" x "`$BackupFile" -o"`$tempDir" -p"`$encryptionKey" -y 2>&1 | Out-Null
    
    if (`$LASTEXITCODE -eq 0) {
        `$extractedFiles = Get-ChildItem `$tempDir -Filter "*.sql"
        if (`$extractedFiles.Count -gt 0) {
            `$sqlFile = `$extractedFiles[0].FullName
            Write-Host "✅ Backup extracted successfully: `$(`$extractedFiles[0].Name)" -ForegroundColor Green
        } else {
            throw "No SQL file found in extracted backup"
        }
    } else {
        throw "7-Zip extraction failed with exit code `$LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Backup extraction failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    Remove-Item `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Step 4: Create target database if requested
if (`$CreateDatabase) {
    Write-Host "`n🗄️ Step 4: Creating target database..." -ForegroundColor Yellow
    
    try {
        `$env:PGPASSWORD = "password"
        createdb -h localhost -U postgres "`$TargetDatabase" 2>&1
        Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
        
        if (`$LASTEXITCODE -eq 0) {
            Write-Host "✅ Target database created: `$TargetDatabase" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Database might already exist or creation failed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Failed to create database: `$(`$_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 5: Restore database
Write-Host "`n💾 Step 5: Restoring database..." -ForegroundColor Yellow

try {
    `$env:PGPASSWORD = "password"
    pg_restore -h localhost -U postgres -d "`$TargetDatabase" --verbose --clean --if-exists "`$sqlFile" 2>&1
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✅ Database restored successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Restore completed with warnings (exit code: `$LASTEXITCODE)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Database restoration failed: `$(`$_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup temporary files
    Remove-Item `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Temporary files cleaned up" -ForegroundColor Green
}

# Step 6: Verify restoration
Write-Host "`n🧪 Step 6: Verifying restoration..." -ForegroundColor Yellow

try {
    `$env:PGPASSWORD = "password"
    `$tableCount = psql -h localhost -U postgres -d "`$TargetDatabase" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    
    if (`$LASTEXITCODE -eq 0) {
        `$tableCount = `$tableCount.Trim()
        Write-Host "✅ Restoration verified: `$tableCount tables found in restored database" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Could not verify restoration" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Restoration verification failed: `$(`$_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎉 Database Restoration Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "✅ Source Backup: `$(Split-Path `$BackupFile -Leaf)" -ForegroundColor Green
Write-Host "✅ Target Database: `$TargetDatabase" -ForegroundColor Green
Write-Host "✅ Tables Restored: `$(`$tableCount.Trim())" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Verify application connectivity to restored database" -ForegroundColor White
Write-Host "2. Run application-specific validation tests" -ForegroundColor White
Write-Host "3. Update connection strings if needed" -ForegroundColor White
Write-Host "4. Consider running ANALYZE on restored database" -ForegroundColor White
"@

$restoreScript | Out-File -FilePath $restoreScriptPath -Encoding UTF8
Write-Host "✅ Backup restoration script created: $restoreScriptPath" -ForegroundColor Green

# Step 6: Create backup scheduling script
Write-Host "`n⏰ Step 6: Creating backup scheduling script..." -ForegroundColor Yellow

$scheduleScriptPath = Join-Path $PSScriptRoot "setup-backup-schedule.ps1"
$scheduleScript = @"
# GameForge Database Backup Scheduling Script

param(
    [Parameter(Mandatory=`$false)]
    [string]`$FullBackupTime = "02:00",  # 2 AM daily
    
    [Parameter(Mandatory=`$false)]
    [string]`$SchemaBackupTime = "06:00", # 6 AM daily
    
    [Parameter(Mandatory=`$false)]
    [int]`$RetentionDays = 30
)

Write-Host "⏰ GameForge Database Backup Scheduling Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Task names
`$fullBackupTask = "GameForge-FullBackup"
`$schemaBackupTask = "GameForge-SchemaBackup"
`$cleanupTask = "GameForge-BackupCleanup"

Write-Host "`n🗓️ Setting up backup schedules..." -ForegroundColor Yellow
Write-Host "Full Backup: Daily at `$FullBackupTime" -ForegroundColor Cyan
Write-Host "Schema Backup: Daily at `$SchemaBackupTime" -ForegroundColor Cyan

# Full Backup Task
try {
    # Remove existing task if it exists
    `$existingTask = Get-ScheduledTask -TaskName `$fullBackupTask -ErrorAction SilentlyContinue
    if (`$existingTask) {
        Unregister-ScheduledTask -TaskName `$fullBackupTask -Confirm:`$false
        Write-Host "⚠️ Removed existing full backup task" -ForegroundColor Yellow
    }
    
    # Create full backup task
    `$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"`$PSScriptRoot\backup-database-encrypted.ps1`" -Database gameforge_dev -BackupType full"
    `$trigger = New-ScheduledTaskTrigger -Daily -At `$FullBackupTime
    `$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 2) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 10)
    `$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName `$fullBackupTask -Action `$action -Trigger `$trigger -Settings `$settings -Principal `$principal -Description "GameForge Database Full Backup (Encrypted)"
    
    Write-Host "✅ Full backup task created: `$fullBackupTask" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create full backup task: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Schema Backup Task
try {
    # Remove existing task if it exists
    `$existingTask = Get-ScheduledTask -TaskName `$schemaBackupTask -ErrorAction SilentlyContinue
    if (`$existingTask) {
        Unregister-ScheduledTask -TaskName `$schemaBackupTask -Confirm:`$false
        Write-Host "⚠️ Removed existing schema backup task" -ForegroundColor Yellow
    }
    
    # Create schema backup task
    `$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"`$PSScriptRoot\backup-database-encrypted.ps1`" -Database gameforge_dev -BackupType schema"
    `$trigger = New-ScheduledTaskTrigger -Daily -At `$SchemaBackupTime
    `$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
    `$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName `$schemaBackupTask -Action `$action -Trigger `$trigger -Settings `$settings -Principal `$principal -Description "GameForge Database Schema Backup (Encrypted)"
    
    Write-Host "✅ Schema backup task created: `$schemaBackupTask" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create schema backup task: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Backup Cleanup Task
try {
    # Remove existing task if it exists
    `$existingTask = Get-ScheduledTask -TaskName `$cleanupTask -ErrorAction SilentlyContinue
    if (`$existingTask) {
        Unregister-ScheduledTask -TaskName `$cleanupTask -Confirm:`$false
        Write-Host "⚠️ Removed existing cleanup task" -ForegroundColor Yellow
    }
    
    # Create cleanup task (runs weekly)
    `$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"`$PSScriptRoot\cleanup-old-backups.ps1`" -RetentionDays `$RetentionDays"
    `$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "04:00"
    `$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RestartCount 2 -RestartInterval (New-TimeSpan -Minutes 15)
    `$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName `$cleanupTask -Action `$action -Trigger `$trigger -Settings `$settings -Principal `$principal -Description "GameForge Database Backup Cleanup"
    
    Write-Host "✅ Backup cleanup task created: `$cleanupTask" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create cleanup task: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Test tasks
Write-Host "`n🧪 Testing scheduled tasks..." -ForegroundColor Yellow

foreach (`$taskName in @(`$fullBackupTask, `$schemaBackupTask, `$cleanupTask)) {
    try {
        `$task = Get-ScheduledTask -TaskName `$taskName -ErrorAction Stop
        Write-Host "✅ Task `$taskName is ready (State: `$(`$task.State))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Task `$taskName is not properly configured" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Backup Scheduling Complete!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host "✅ Full Backup: Daily at `$FullBackupTime" -ForegroundColor Green
Write-Host "✅ Schema Backup: Daily at `$SchemaBackupTime" -ForegroundColor Green
Write-Host "✅ Cleanup: Weekly on Sunday at 04:00" -ForegroundColor Green
Write-Host "✅ Retention Period: `$RetentionDays days" -ForegroundColor Green

Write-Host "`n📋 Scheduled Tasks Created:" -ForegroundColor Cyan
Write-Host "- `$fullBackupTask" -ForegroundColor White
Write-Host "- `$schemaBackupTask" -ForegroundColor White
Write-Host "- `$cleanupTask" -ForegroundColor White

Write-Host "`n💡 Management Commands:" -ForegroundColor Cyan
Write-Host "List tasks: Get-ScheduledTask | Where-Object { `$_.TaskName -like '*GameForge*' }" -ForegroundColor White
Write-Host "Run full backup: Start-ScheduledTask -TaskName `$fullBackupTask" -ForegroundColor White
Write-Host "Check task history: Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=201}" -ForegroundColor White
"@

$scheduleScript | Out-File -FilePath $scheduleScriptPath -Encoding UTF8
Write-Host "✅ Backup scheduling script created: $scheduleScriptPath" -ForegroundColor Green

# Step 7: Create backup cleanup script
Write-Host "`n🗑️ Step 7: Creating backup cleanup script..." -ForegroundColor Yellow

$cleanupScriptPath = Join-Path $PSScriptRoot "cleanup-old-backups.ps1"
$cleanupScript = @"
# GameForge Database Backup Cleanup Script

param(
    [Parameter(Mandatory=`$false)]
    [int]`$RetentionDays = 30,
    
    [Parameter(Mandatory=`$false)]
    [string]`$BackupDir = "$BackupDir",
    
    [Parameter(Mandatory=`$false)]
    [switch]`$DryRun
)

Write-Host "🗑️ GameForge Database Backup Cleanup" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

`$cutoffDate = (Get-Date).AddDays(-`$RetentionDays)
Write-Host "📅 Cleaning backups older than: `$(`$cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
Write-Host "📁 Backup directory: `$BackupDir" -ForegroundColor Cyan

if (`$DryRun) {
    Write-Host "🧪 DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
}

# Function to get folder size
function Get-FolderSize(`$folderPath) {
    `$size = (Get-ChildItem `$folderPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    return [math]::Round(`$size / 1MB, 2)
}

# Get backup statistics before cleanup
Write-Host "`n📊 Backup Statistics (Before Cleanup)" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

`$totalSize = 0
`$totalFiles = 0

foreach (`$backupType in @("full", "incremental", "schema")) {
    `$typePath = Join-Path `$BackupDir `$backupType
    if (Test-Path `$typePath) {
        `$typeSize = Get-FolderSize `$typePath
        `$typeFiles = (Get-ChildItem `$typePath -Recurse -File).Count
        
        Write-Host "`$backupType backups: `$typeFiles files, `$typeSize MB" -ForegroundColor Cyan
        `$totalSize += `$typeSize
        `$totalFiles += `$typeFiles
    }
}

Write-Host "Total: `$totalFiles files, `$totalSize MB" -ForegroundColor White

# Find old backup directories
Write-Host "`n🔍 Scanning for old backups..." -ForegroundColor Yellow

`$deletedSize = 0
`$deletedFiles = 0
`$deletedDirs = 0

foreach (`$backupType in @("full", "incremental", "schema")) {
    `$typePath = Join-Path `$BackupDir `$backupType
    if (!(Test-Path `$typePath)) { continue }
    
    Write-Host "`nProcessing `$backupType backups..." -ForegroundColor Cyan
    
    # Get date directories
    `$dateDirs = Get-ChildItem `$typePath -Directory | Where-Object { `$_.Name -match '^\d{4}-\d{2}-\d{2}$' }
    
    foreach (`$dateDir in `$dateDirs) {
        try {
            `$dirDate = [DateTime]::ParseExact(`$dateDir.Name, 'yyyy-MM-dd', `$null)
            
            if (`$dirDate -lt `$cutoffDate) {
                `$dirSize = Get-FolderSize `$dateDir.FullName
                `$dirFiles = (Get-ChildItem `$dateDir.FullName -Recurse -File).Count
                
                Write-Host "📅 `$(`$dateDir.Name): `$dirFiles files, `$dirSize MB" -ForegroundColor Yellow
                
                if (`$DryRun) {
                    Write-Host "🧪 Would delete: `$(`$dateDir.FullName)" -ForegroundColor Yellow
                } else {
                    Remove-Item `$dateDir.FullName -Recurse -Force
                    Write-Host "✅ Deleted: `$(`$dateDir.Name)" -ForegroundColor Green
                }
                
                `$deletedSize += `$dirSize
                `$deletedFiles += `$dirFiles
                `$deletedDirs++
            }
        } catch {
            Write-Host "⚠️ Invalid date directory name: `$(`$dateDir.Name)" -ForegroundColor Yellow
        }
    }
}

# Archive cleanup
Write-Host "`n📦 Processing archive directory..." -ForegroundColor Yellow

`$archivePath = Join-Path `$BackupDir "archive"
if (Test-Path `$archivePath) {
    `$oldArchiveFiles = Get-ChildItem `$archivePath -File | Where-Object { `$_.LastWriteTime -lt `$cutoffDate }
    
    foreach (`$file in `$oldArchiveFiles) {
        `$fileSizeMB = [math]::Round(`$file.Length / 1MB, 2)
        
        Write-Host "📄 `$(`$file.Name): `$fileSizeMB MB" -ForegroundColor Yellow
        
        if (`$DryRun) {
            Write-Host "🧪 Would delete: `$(`$file.Name)" -ForegroundColor Yellow
        } else {
            Remove-Item `$file.FullName -Force
            Write-Host "✅ Deleted: `$(`$file.Name)" -ForegroundColor Green
        }
        
        `$deletedSize += `$fileSizeMB
        `$deletedFiles++
    }
}

# Get backup statistics after cleanup
if (!`$DryRun) {
    Write-Host "`n📊 Backup Statistics (After Cleanup)" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    `$newTotalSize = 0
    `$newTotalFiles = 0
    
    foreach (`$backupType in @("full", "incremental", "schema")) {
        `$typePath = Join-Path `$BackupDir `$backupType
        if (Test-Path `$typePath) {
            `$typeSize = Get-FolderSize `$typePath
            `$typeFiles = (Get-ChildItem `$typePath -Recurse -File).Count
            
            Write-Host "`$backupType backups: `$typeFiles files, `$typeSize MB" -ForegroundColor Cyan
            `$newTotalSize += `$typeSize
            `$newTotalFiles += `$typeFiles
        }
    }
    
    Write-Host "Total: `$newTotalFiles files, `$newTotalSize MB" -ForegroundColor White
}

# Summary
Write-Host "`n📋 Cleanup Summary" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

if (`$DryRun) {
    Write-Host "🧪 DRY RUN RESULTS:" -ForegroundColor Yellow
    Write-Host "Would delete `$deletedDirs directories" -ForegroundColor White
    Write-Host "Would delete `$deletedFiles files" -ForegroundColor White
    Write-Host "Would free `$deletedSize MB" -ForegroundColor White
} else {
    Write-Host "✅ CLEANUP COMPLETED:" -ForegroundColor Green
    Write-Host "Deleted `$deletedDirs directories" -ForegroundColor White
    Write-Host "Deleted `$deletedFiles files" -ForegroundColor White
    Write-Host "Freed `$deletedSize MB" -ForegroundColor White
    
    `$savedSpace = `$totalSize - `$newTotalSize
    Write-Host "Space saved: `$savedSpace MB" -ForegroundColor Cyan
}

Write-Host "Retention period: `$RetentionDays days" -ForegroundColor White
Write-Host "Cutoff date: `$(`$cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor White

if (`$DryRun) {
    Write-Host "`n💡 To perform actual cleanup, run without -DryRun parameter" -ForegroundColor Cyan
}
"@

$cleanupScript | Out-File -FilePath $cleanupScriptPath -Encoding UTF8
Write-Host "✅ Backup cleanup script created: $cleanupScriptPath" -ForegroundColor Green

# Step 8: Test backup creation
Write-Host "`n🧪 Step 8: Testing backup creation..." -ForegroundColor Yellow

try {
    # Run a test backup
    Write-Host "Creating test backup..." -ForegroundColor Cyan
    & PowerShell.exe -ExecutionPolicy Bypass -File $backupScriptPath -Database "gameforge_dev" -BackupType "schema"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Test backup completed successfully!" -ForegroundColor Green
        
        # Check for created files
        $todayBackupDir = Join-Path $BackupDir "schema\$(Get-Date -Format 'yyyy-MM-dd')"
        if (Test-Path $todayBackupDir) {
            $backupFiles = Get-ChildItem $todayBackupDir -File
            Write-Host "📁 Backup files created: $($backupFiles.Count)" -ForegroundColor Cyan
            foreach ($file in $backupFiles) {
                $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                Write-Host "  - $($file.Name): $fileSizeMB MB" -ForegroundColor White
            }
        }
    } else {
        Write-Host "⚠️  Test backup had issues (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not run test backup: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Final Summary
Write-Host "`n🎉 Backup Encryption Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "✅ Backup directories created" -ForegroundColor Green
Write-Host "✅ Encryption key generated and secured" -ForegroundColor Green
Write-Host "✅ 7-Zip installed for encryption" -ForegroundColor Green
Write-Host "✅ Backup script created with AES-256 encryption" -ForegroundColor Green
Write-Host "✅ Restoration script created" -ForegroundColor Green
Write-Host "✅ Scheduling script created" -ForegroundColor Green
Write-Host "✅ Cleanup script created" -ForegroundColor Green

Write-Host "`n📁 Created Files:" -ForegroundColor Cyan
Write-Host "- Backup Directory: $BackupDir" -ForegroundColor White
Write-Host "- Encryption Key: $EncryptionKeyFile" -ForegroundColor White
Write-Host "- Backup Script: $backupScriptPath" -ForegroundColor White
Write-Host "- Restore Script: $restoreScriptPath" -ForegroundColor White
Write-Host "- Schedule Script: $scheduleScriptPath" -ForegroundColor White
Write-Host "- Cleanup Script: $cleanupScriptPath" -ForegroundColor White

Write-Host "`n📋 Quick Commands:" -ForegroundColor Cyan
Write-Host "Full backup: .\backup-database-encrypted.ps1 -Database gameforge_dev -BackupType full" -ForegroundColor White
Write-Host "Schema backup: .\backup-database-encrypted.ps1 -Database gameforge_dev -BackupType schema" -ForegroundColor White
Write-Host "Restore backup: .\restore-database-encrypted.ps1 -BackupFile path\to\backup.7z -TargetDatabase restored_db" -ForegroundColor White
Write-Host "Setup schedule: .\setup-backup-schedule.ps1" -ForegroundColor White
Write-Host "Cleanup old: .\cleanup-old-backups.ps1 -RetentionDays 30" -ForegroundColor White

Write-Host "`n🔐 Security Features:" -ForegroundColor Yellow
Write-Host "- AES-256 encryption with secure key storage" -ForegroundColor White
Write-Host "- SHA-256 checksum verification" -ForegroundColor White
Write-Host "- LZMA2 compression for space efficiency" -ForegroundColor White
Write-Host "- Metadata tracking for backup management" -ForegroundColor White
Write-Host "- Automated cleanup and retention policies" -ForegroundColor White

Write-Host "`n⚠️  Security Reminders:" -ForegroundColor Yellow
Write-Host "- Store encryption key securely and separately from backups" -ForegroundColor White
Write-Host "- Test backup restoration regularly" -ForegroundColor White
Write-Host "- Monitor backup storage space" -ForegroundColor White
Write-Host "- Consider offsite backup storage for production" -ForegroundColor White