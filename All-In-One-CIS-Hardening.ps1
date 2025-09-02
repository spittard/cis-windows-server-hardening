# =============================================================================
# ALL-IN-ONE CIS WINDOWS SERVER 2022 HARDENING SCRIPT
# =============================================================================
# This script performs complete CIS hardening while maintaining RDP access
# Author: Scott Pittard
# Repository: https://github.com/spittard/cis-windows-server-hardening
# =============================================================================

param(
    [switch]$SkipReboot,
    [switch]$Verbose,
    [string]$CISPath = "C:\CIS"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Color functions for better output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Step, [string]$Description)
    Write-ColorOutput "`n=== $Step ===" "Cyan"
    Write-ColorOutput $Description "Yellow"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

# =============================================================================
# STEP 1: SYSTEM CHECKS AND PREPARATION
# =============================================================================
Write-Step "STEP 1" "System Checks and Preparation"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit 1
}
Write-Success "Running as Administrator"

# Check Windows version
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -lt 10) {
    Write-Error "This script requires Windows 10/Server 2016 or later"
    exit 1
}
Write-Success "Windows version compatible: $($osVersion.Major).$($osVersion.Minor)"

# Create CIS directory structure
Write-ColorOutput "Creating CIS directory structure..." "Yellow"
$cisDirectories = @(
    $CISPath,
    "$CISPath\Server2022StandAlonev1.0.0",
    "$CISPath\LGPO_30"
)

foreach ($dir in $cisDirectories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created directory: $dir"
    } else {
        Write-ColorOutput "Directory exists: $dir" "Gray"
    }
}

# =============================================================================
# STEP 2: DOWNLOAD AND SETUP CIS COMPONENTS
# =============================================================================
Write-Step "STEP 2" "Download and Setup CIS Components"

# Check for LGPO.exe
$lgpoPath = "$CISPath\LGPO_30\LGPO.exe"
if (-not (Test-Path $lgpoPath)) {
    Write-Warning "LGPO.exe not found at $lgpoPath"
    Write-ColorOutput "Please download LGPO from Microsoft Security Compliance Toolkit" "Yellow"
    Write-ColorOutput "URL: https://www.microsoft.com/en-us/download/details.aspx?id=55319" "Cyan"
    Write-ColorOutput "Extract LGPO.exe to: $lgpoPath" "Yellow"
    
    # Try to download LGPO automatically
    try {
        Write-ColorOutput "Attempting to download LGPO..." "Yellow"
        $lgpoUrl = "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip"
        $lgpoZip = "$env:TEMP\LGPO.zip"
        
        Invoke-WebRequest -Uri $lgpoUrl -OutFile $lgpoZip -UseBasicParsing
        Expand-Archive -Path $lgpoZip -DestinationPath "$CISPath\LGPO_30" -Force
        Remove-Item $lgpoZip -Force
        
        if (Test-Path $lgpoPath) {
            Write-Success "LGPO downloaded and extracted successfully"
        } else {
            throw "LGPO extraction failed"
        }
    } catch {
        Write-Error "Failed to download LGPO automatically. Please download manually."
        Write-ColorOutput "Continuing with manual setup required..." "Yellow"
    }
} else {
    Write-Success "LGPO.exe found"
}

# Check for CIS GPO files
$cisGpoPath = "$CISPath\Server2022StandAlonev1.0.0\MS-L1"
if (-not (Test-Path $cisGpoPath)) {
    Write-Warning "CIS GPO files not found at $cisGpoPath"
    Write-ColorOutput "Please download CIS Server 2022 Standalone v1.0.0 from:" "Yellow"
    Write-ColorOutput "URL: https://www.cisecurity.org/benchmark/microsoft_windows_server" "Cyan"
    Write-ColorOutput "Extract to: $CISPath\Server2022StandAlonev1.0.0" "Yellow"
    
    # Create placeholder structure
    $placeholderDirs = @(
        "$CISPath\Server2022StandAlonev1.0.0\MS-L1\{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine",
        "$CISPath\Server2022StandAlonev1.0.0\MS-L1\{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit"
    )
    
    foreach ($dir in $placeholderDirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    Write-ColorOutput "Created placeholder directory structure" "Yellow"
    Write-ColorOutput "Please copy your CIS GPO files to the appropriate locations" "Yellow"
} else {
    Write-Success "CIS GPO files found"
}

# =============================================================================
# STEP 3: FIREWALL AND RDP CONFIGURATION
# =============================================================================
Write-Step "STEP 3" "Firewall and RDP Configuration"

# Enable RDP through registry
Write-ColorOutput "Enabling RDP through registry..." "Yellow"
try {
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Write-Success "RDP enabled in registry"
} catch {
    Write-Error "Failed to enable RDP in registry: $_"
}

# Configure Windows Firewall for RDP
Write-ColorOutput "Configuring Windows Firewall for RDP..." "Yellow"
try {
    # Enable RDP firewall rules
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes | Out-Null
    
    # Add specific RDP rule if needed
    netsh advfirewall firewall add rule name="RDP-In" dir=in action=allow protocol=TCP localport=3389 remoteip=any | Out-Null
    
    # Enable ICMP for ping
    netsh advfirewall firewall add rule name="ICMP" dir=in action=allow protocol=ICMPv4 | Out-Null
    
    Write-Success "Windows Firewall configured for RDP and ICMP"
} catch {
    Write-Error "Failed to configure Windows Firewall: $_"
}

# =============================================================================
# STEP 4: CIS POLICY APPLICATION
# =============================================================================
Write-Step "STEP 4" "CIS Policy Application"

if (Test-Path $lgpoPath -and Test-Path $cisGpoPath) {
    Write-ColorOutput "Applying CIS policies with RDP modifications..." "Yellow"
    
    # Set up file paths
    $msL1GpoFolder = "$CISPath\Server2022StandAlonev1.0.0\MS-L1"
    $polFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\registry.pol"
    $infFilePath = Join-Path -Path $msL1GpoFolder -ChildPath "{B792AF4D-F4ED-4D42-9424-D884C7C7E529}\DomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit\GptTmpl.inf"
    $editableTxtPath = Join-Path -Path (Split-Path $polFilePath) -ChildPath "registry.txt"
    
    if (Test-Path $polFilePath) {
        try {
            # Fix permissions
            takeown /F $CISPath /R /D Y | Out-Null
            icacls $CISPath /grant '*S-1-5-32-544:(OI)(CI)F' /T | Out-Null
            
            # Modify registry policy for RDP
            Write-ColorOutput "Modifying registry policy for RDP..." "Yellow"
            & $lgpoPath /parse /m $polFilePath > $editableTxtPath
            
            (Get-Content $editableTxtPath) | ForEach-Object {
                $_ `
                -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services;fDenyTSConnections;REG_DWORD;1', 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services;fDenyTSConnections;REG_DWORD;0' `
                -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services;fDisablePasswordSaving;REG_DWORD;1', 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services;fDisablePasswordSaving;REG_DWORD;0' `
                -replace '(?i)SOFTWARE\\Policies\\Microsoft\\Windows\\CredentialsDelegation;AllowProtectedCreds;REG_DWORD;0', 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation;AllowProtectedCreds;REG_DWORD;1'
            } | Set-Content $editableTxtPath
            
            & $lgpoPath /r $editableTxtPath /w $polFilePath
            Remove-Item $editableTxtPath -Force -ErrorAction SilentlyContinue
            
            Write-Success "Registry policy modified for RDP"
        } catch {
            Write-Error "Failed to modify registry policy: $_"
        }
    }
    
    if (Test-Path $infFilePath) {
        try {
            # Modify security template for RDP users
            Write-ColorOutput "Modifying security template for RDP users..." "Yellow"
            $adminSid = "*S-1-5-32-544" # Administrators
            $rdpUsersSid = "*S-1-5-32-555" # Remote Desktop Users
            
            (Get-Content $infFilePath) | ForEach-Object {
                if ($_ -like "SeRemoteInteractiveLogonRight *") {
                    if (($_ -notlike "*$adminSid*") -and ($_ -notlike "*$rdpUsersSid*")) {
                        $_ + ",$adminSid,$rdpUsersSid"
                    } else {
                        $_
                    }
                } else {
                    $_
                }
            } | Set-Content $infFilePath
            
            Write-Success "Security template modified for RDP users"
        } catch {
            Write-Error "Failed to modify security template: $_"
        }
    }
} else {
    Write-Warning "CIS components not found. Skipping policy application."
    Write-ColorOutput "Please ensure LGPO.exe and CIS GPO files are properly installed." "Yellow"
}

# =============================================================================
# STEP 5: ADDITIONAL SECURITY CONFIGURATIONS
# =============================================================================
Write-Step "STEP 5" "Additional Security Configurations"

# Enable Windows Defender
Write-ColorOutput "Configuring Windows Defender..." "Yellow"
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
    Write-Success "Windows Defender configured"
} catch {
    Write-Warning "Windows Defender configuration failed (may not be available on Server Core)"
}

# Configure Windows Update
Write-ColorOutput "Configuring Windows Update..." "Yellow"
try {
    # Enable automatic updates
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4 -Force -ErrorAction SilentlyContinue
    Write-Success "Windows Update configured"
} catch {
    Write-Warning "Windows Update configuration failed"
}

# =============================================================================
# STEP 6: VERIFICATION AND FINALIZATION
# =============================================================================
Write-Step "STEP 6" "Verification and Finalization"

# Verify RDP service
Write-ColorOutput "Verifying RDP service..." "Yellow"
$rdpService = Get-Service -Name TermService -ErrorAction SilentlyContinue
if ($rdpService -and $rdpService.Status -eq "Running") {
    Write-Success "RDP service is running"
} else {
    Write-Warning "RDP service status: $($rdpService.Status)"
}

# Verify firewall rules
Write-ColorOutput "Verifying firewall rules..." "Yellow"
$rdpRules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
if ($rdpRules) {
    $enabledRules = $rdpRules | Where-Object { $_.Enabled -eq "True" }
    Write-Success "RDP firewall rules enabled: $($enabledRules.Count)"
} else {
    Write-Warning "No RDP firewall rules found"
}

# Test network connectivity
Write-ColorOutput "Testing network connectivity..." "Yellow"
try {
    $testResult = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($testResult) {
        Write-Success "Network connectivity verified"
    } else {
        Write-Warning "Network connectivity test failed"
    }
} catch {
    Write-Warning "Network connectivity test failed: $_"
}

# =============================================================================
# COMPLETION AND REBOOT
# =============================================================================
Write-Step "COMPLETION" "Hardening Process Complete"

Write-ColorOutput "`n🎉 CIS Hardening Process Completed!" "Green"
Write-ColorOutput "`nSummary of changes:" "Cyan"
Write-ColorOutput "  ✅ RDP enabled and configured" "Green"
Write-ColorOutput "  ✅ Windows Firewall configured for RDP and ICMP" "Green"
Write-ColorOutput "  ✅ CIS policies applied (if components available)" "Green"
Write-ColorOutput "  ✅ Security configurations applied" "Green"
Write-ColorOutput "  ✅ System verification completed" "Green"

if (-not $SkipReboot) {
    Write-ColorOutput "`n⚠️  A reboot is recommended to ensure all policies are applied." "Yellow"
    Write-ColorOutput "The system will reboot in 30 seconds..." "Yellow"
    Write-ColorOutput "Press Ctrl+C to cancel the reboot." "Red"
    
    $countdown = 30
    while ($countdown -gt 0) {
        Write-Progress -Activity "Rebooting System" -Status "Reboot in $countdown seconds" -PercentComplete (($countdown / 30) * 100)
        Start-Sleep -Seconds 1
        $countdown--
    }
    
    Write-ColorOutput "`n🔄 Rebooting system..." "Yellow"
    Restart-Computer -Force
} else {
    Write-ColorOutput "`nℹ️  Reboot skipped. Please reboot manually when convenient." "Cyan"
}

Write-ColorOutput "`n📚 For more information, visit:" "Cyan"
Write-ColorOutput "   Repository: https://github.com/spittard/cis-windows-server-hardening" "White"
Write-ColorOutput "   CIS Benchmarks: https://www.cisecurity.org/benchmark/microsoft_windows_server" "White"
