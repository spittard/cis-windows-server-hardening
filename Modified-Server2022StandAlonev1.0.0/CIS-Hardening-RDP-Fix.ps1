# ---
# THE ALL-IN-ONE CIS HARDENING & RDP FIX SCRIPT
# ---

# --- Step 1: Set Up File Paths ---
Write-Host "--- Step 1: Setting up file paths... ---" -ForegroundColor Cyan
$lgpoPath = "C:\CIS\LGPO.exe"
$cisGpoBackupFolder = "C:\CIS\Server2022StandAlonev1.0.0"
$msL1GpoFolder = Join-Path -Path $cisGpoBackupFolder -ChildPath "MS-L1"
$polFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\registry.pol"
$infFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit\GptTmpl.inf"
$editableTxtPath = Join-Path -Path (Split-Path $polFilePath) -ChildPath "registry.txt"

# --- Step 2: Fix Folder Permissions ---
Write-Host "--- Step 2: Fixing permissions on the CIS GPO folder... ---" -ForegroundColor Cyan
takeown /F $cisGpoBackupFolder /R /D Y
icacls $cisGpoBackupFolder /grant '*S-1-5-32-544:(OI)(CI)F' /T

# --- Step 3: Modify the GPO Source Files with RDP Fixes ---
Write-Host "--- Step 3: Modifying the GPO source files... ---" -ForegroundColor Cyan

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

# --- Step 4: Reset Local Policy to Defaults and Reboot ---
Write-Host "--- Step 4: Resetting local policy and preparing to reboot... ---" -ForegroundColor Cyan
secedit /configure /cfg $env:windir\inf\defltbase.inf /db defltbase.sdb /verbose
Write-Host "Policy reset. The server will now reboot in 15 seconds." -ForegroundColor Yellow
Start-Sleep -Seconds 15
Restart-Computer -Force

# The script will stop here. You must reconnect with AWS Session Manager after the reboot to continue.
# The following steps are for after you reconnect.
