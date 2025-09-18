# CIS Windows Server 2022 Hardening Scripts

This repository contains PowerShell scripts for implementing CIS (Center for Internet Security) hardening on Windows Server 2022 while maintaining RDP connectivity and creating a secure administrative account.

## Contents

- **CIS-Hardening-Script.ps1**: **RECOMMENDED** - Main hardening script with automatic CISADMIN account creation
- **Post-Reboot-Script.ps1**: Commands to run after reboot, including CISADMIN to Administrator rename
- **Final-CIS-Hardening-Script.ps1**: Legacy streamlined script (deprecated)
- **All-In-One-CIS-Hardening.ps1**: Comprehensive script with automatic downloads and full verification

## Features

### CIS Hardening
- Applies Microsoft Security Level 1 baseline policies
- Implements security configurations from CIS benchmarks
- Uses LGPO (Local Group Policy Object) for policy management
- **Removes RDP deny policies** that block local user access

### RDP Connectivity Fixes
- Enables RDP connections (`fDenyTSConnections` = 0)
- Allows password saving for RDP sessions
- Enables protected credentials delegation
- Configures proper user rights for Remote Desktop Users
- **Removes SeDenyRemoteInteractiveLogonRight restrictions**

### Administrative Account Management
- **Automatically creates CISADMIN account** with secure password
- Adds CISADMIN to Administrators and Remote Desktop Users groups
- **Post-reboot rename** of CISADMIN to Administrator
- Configurable password via script parameters
- Group membership verification

### Automated Process
- Fixes folder permissions automatically
- Modifies GPO source files with RDP-friendly settings
- Creates and configures administrative account
- Includes automatic reboot for policy application

## Prerequisites

- Windows Server 2022
- LGPO.exe (Local Group Policy Object utility)
- CIS Server 2022 Standalone v1.0.0 GPO backup files
- Administrative privileges

## Quick Start (Recommended)

1. **Prepare the server:**
   - Clone this repository to `C:\projects\cis-windows-server-hardening\`
   - Ensure `LGPO.exe` is in `LGPO_30\` folder
   - Ensure `Server2022StandAlonev1.0.0\` folder is present
   - **No manual account creation needed** - CISADMIN will be created automatically

2. **Run the main hardening script:**
   ```powershell
   .\CIS-Hardening-Script.ps1
   ```
   The script will:
   - Create CISADMIN account with secure password
   - Apply CIS hardening policies
   - Remove RDP deny restrictions
   - Reboot automatically

3. **After reboot, reconnect with AWS Session Manager and run:**
   ```powershell
   .\Post-Reboot-Script.ps1
   ```
   This will:
   - Rename CISADMIN to Administrator
   - Verify RDP connectivity
   - Confirm account configurations

## Script Parameters

The main script supports several parameters:

```powershell
# Use default password
.\CIS-Hardening-Script.ps1

# Use custom password
.\CIS-Hardening-Script.ps1 -CISAdminPassword "MySecurePass123!"

# Skip account creation
.\CIS-Hardening-Script.ps1 -SkipAccountCreation
```

## Alternative Usage

For legacy scripts:
1. Ensure LGPO.exe is available at `C:\CIS\LGPO.exe`
2. Place CIS GPO backup files in `C:\CIS\Server2022StandAlonev1.0.0\`
3. Run the script as Administrator:
   ```powershell
   .\All-In-One-CIS-Hardening.ps1
   ```
4. The server will reboot automatically after policy application
5. Reconnect via AWS Session Manager after reboot

## File Structure

```
├── CIS-Hardening-Script.ps1        # Main hardening script (RECOMMENDED)
├── Post-Reboot-Script.ps1          # Post-reboot commands and account rename
├── Server2022StandAlonev1.0.0/     # Original CIS policies (RDP deny policies removed)
├── Modified-Server2022StandAlonev1.0.0/
│   ├── CIS-Hardening-RDP-Fix.ps1   # Legacy hardening script
│   ├── MS-L1/                      # Modified Microsoft Level 1 baseline
│   ├── MS-L2/                      # Modified Microsoft Level 2 baseline
│   └── [Other modified CIS components...]
├── LGPO_30/                        # LGPO utility and documentation
├── Policy Analyzer/                # Policy analysis tools
├── Tenable-3/                      # Tenable configuration files
└── TestBackup/                     # Test backup files
```

## Security Considerations

- This script modifies security policies to balance CIS compliance with operational requirements
- RDP access is maintained for administrative purposes
- **RDP deny policies are removed** to allow local user access
- CISADMIN account is created with secure password and proper group memberships
- All changes are logged and can be audited
- **Original CIS policies are preserved** in `Server2022StandAlonev1.0.0/` for reference and comparison
- **Modified policies** are in `Modified-Server2022StandAlonev1.0.0/` with RDP-friendly configurations

## Key Changes Made

### RDP Access Improvements
- Removed `SeDenyRemoteInteractiveLogonRight` restrictions
- Enabled RDP connections for local users
- Maintained security while allowing administrative access

### Account Management
- Automatic CISADMIN account creation
- Secure password generation
- Proper group membership assignment
- Post-reboot rename to Administrator

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is provided as-is for educational and operational purposes.
