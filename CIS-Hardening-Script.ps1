# ---
# THE ALL-IN-ONE CIS HARDENING & RDP FIX SCRIPT
# ---
# This script applies CIS hardening policies while maintaining RDP access
# and creates a CISADMIN account for administrative access.
#
# Usage Examples:
#   .\CIS-Hardening-Script.ps1                                    # Use default password
#   .\CIS-Hardening-Script.ps1 -CISAdminPassword "MySecurePass123!" # Custom password
#   .\CIS-Hardening-Script.ps1 -SkipAccountCreation               # Skip account creation
# ---

# Parameters
param(
    [string]$CISAdminPassword = "CIS@dmin2024!",
    [switch]$SkipAccountCreation
)

# --- Step 1: Set Up File Paths ---
Write-Host "--- Step 1: Setting up file paths... ---" -ForegroundColor Cyan
$lgpoPath = "C:\projects\cis-windows-server-hardening\LGPO_30\LGPO.exe"
$cisGpoBackupFolder = "C:\projects\cis-windows-server-hardening\Server2022StandAlonev1.0.0"
$msL1GpoFolder = Join-Path -Path $cisGpoBackupFolder -ChildPath "MS-L1"
$polFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\registry.pol"
$infFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit\GptTmpl.inf"
$editableTxtPath = Join-Path -Path (Split-Path $polFilePath) -ChildPath "registry.txt"

# --- Step 2: Create CISADMIN Account ---
if (-not $SkipAccountCreation) {
    Write-Host "--- Step 2: Creating CISADMIN account... ---" -ForegroundColor Cyan

    # Check if CISADMIN account already exists
    $cisAdminExists = Get-LocalUser -Name "CISADMIN" -ErrorAction SilentlyContinue

    if ($cisAdminExists) {
        Write-Host "CISADMIN account already exists. Updating group memberships..." -ForegroundColor Yellow
    } else {
        Write-Host "Creating CISADMIN account..." -ForegroundColor Yellow
        # Create CISADMIN account with specified password
        $securePassword = ConvertTo-SecureString $CISAdminPassword -AsPlainText -Force
        New-LocalUser -Name "CISADMIN" -Password $securePassword -Description "CIS Hardening Administrative Account" -PasswordNeverExpires $false
        Write-Host "CISADMIN account created successfully." -ForegroundColor Green
    }

    # Add CISADMIN to Administrators group
    Write-Host "Adding CISADMIN to Administrators group..." -ForegroundColor Yellow
    Add-LocalGroupMember -Group "Administrators" -Member "CISADMIN" -ErrorAction SilentlyContinue

    # Add CISADMIN to Remote Desktop Users group
    Write-Host "Adding CISADMIN to Remote Desktop Users group..." -ForegroundColor Yellow
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CISADMIN" -ErrorAction SilentlyContinue

    # Verify group memberships
    Write-Host "Verifying CISADMIN group memberships..." -ForegroundColor Yellow
    $adminMembers = Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -like "*CISADMIN*"}
    $rdpMembers = Get-LocalGroupMember -Group "Remote Desktop Users" | Where-Object {$_.Name -like "*CISADMIN*"}
    
    if ($adminMembers) {
        Write-Host "✓ CISADMIN is a member of Administrators group" -ForegroundColor Green
    } else {
        Write-Host "✗ CISADMIN is NOT a member of Administrators group" -ForegroundColor Red
    }
    
    if ($rdpMembers) {
        Write-Host "✓ CISADMIN is a member of Remote Desktop Users group" -ForegroundColor Green
    } else {
        Write-Host "✗ CISADMIN is NOT a member of Remote Desktop Users group" -ForegroundColor Red
    }

    Write-Host "CISADMIN account configured successfully." -ForegroundColor Green
} else {
    Write-Host "--- Step 2: Skipping CISADMIN account creation (SkipAccountCreation flag set) ---" -ForegroundColor Yellow
}

# --- Step 3: Fix Folder Permissions ---
Write-Host "--- Step 3: Fixing permissions on the CIS GPO folder... ---" -ForegroundColor Cyan
takeown /F $cisGpoBackupFolder /R /D Y
icacls $cisGpoBackupFolder /grant '*S-1-5-32-544:(OI)(CI)F' /T

# --- Step 4: Modify the GPO Source Files with RDP Fixes ---
Write-Host "--- Step 4: Modifying the GPO source files... ---" -ForegroundColor Cyan

# Modify the Registry Policy (.pol file)
Write-Host "Modifying registry.pol..." -ForegroundColor Yellow
& $lgpoPath /parse /m $polFilePath > $editableTxtPath
(Get-Content $editableTxtPath) | ForEach-Object {
    $_ `
    -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services;fDenyTSConnections;REG_DWORD;1', 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services;fDenyTSConnections;REG_DWORD;0' `
    -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services;fDisablePasswordSaving;REG_DWORD;1', 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services;fDisablePasswordSaving;REG_DWORD;0' `
    -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows\\CredentialsDelegation;AllowProtectedCreds;REG_DWORD;0', 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation;AllowProtectedCreds;REG_DWORD;1'
} | Set-Content $editableTxtPath
& $lgpoPath /r $editableTxtPath /w $polFilePath
Remove-Item $editableTxtPath -Force
Write-Host "registry.pol has been modified." -ForegroundColor Green

# Modify the Security Template (.inf file)
Write-Host "Modifying GptTmpl.inf..." -ForegroundColor Yellow
$adminSid = "*S-1-5-32-544" # Administrators
$rdpUsersSid = "*S-1-5-32-555" # Remote Desktop Users
(Get-Content $infFilePath) | ForEach-Object {
    if ($_ -like "SeRemoteInteractiveLogonRight *") {
        if (($_ -notlike "*$adminSid*") -and ($_ -notlike "*$rdpUsersSid*")) {
            $_ + ",$adminSid,$rdpUsersSid"
        }
        else {
            $_
        }
    }
    else {
        $_
    }
} | Set-Content $infFilePath
Write-Host "GptTmpl.inf has been modified." -ForegroundColor Green

# --- Step 5: Apply Modified CIS Policies and Reboot ---
Write-Host "--- Step 5: Applying modified CIS policies and preparing to reboot... ---" -ForegroundColor Cyan

# Apply the modified registry policy
Write-Host "Applying modified registry policy..." -ForegroundColor Yellow
& $lgpoPath /t $polFilePath

# Apply the modified security template
Write-Host "Applying modified security template..." -ForegroundColor Yellow
secedit /configure /cfg $infFilePath /db secedit.sdb /verbose

# Enable RDP through registry (backup method)
Write-Host "Enabling RDP through registry..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force

# Configure Windows Firewall for RDP
Write-Host "Configuring Windows Firewall for RDP..." -ForegroundColor Yellow
netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes | Out-Null
netsh advfirewall firewall add rule name="RDP-In" dir=in action=allow protocol=TCP localport=3389 remoteip=any | Out-Null

Write-Host "Modified CIS policies applied successfully. The server will now reboot in 15 seconds." -ForegroundColor Green
Start-Sleep -Seconds 15
Restart-Computer -Force

# The script will stop here. You must reconnect with AWS Session Manager after the reboot to continue.
# The following steps are for after you reconnect.
