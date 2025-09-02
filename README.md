# CIS Windows Server 2022 Hardening Scripts

This repository contains PowerShell scripts for implementing CIS (Center for Internet Security) hardening on Windows Server 2022 while maintaining RDP connectivity.

## Contents

- **CIS-Hardening-RDP-Fix.ps1**: All-in-one script that applies CIS Level 1 security baseline while ensuring RDP access remains functional

## Features

### CIS Hardening
- Applies Microsoft Security Level 1 baseline policies
- Implements security configurations from CIS benchmarks
- Uses LGPO (Local Group Policy Object) for policy management

### RDP Connectivity Fixes
- Enables RDP connections (`fDenyTSConnections` = 0)
- Allows password saving for RDP sessions
- Enables protected credentials delegation
- Configures proper user rights for Remote Desktop Users

### Automated Process
- Fixes folder permissions automatically
- Modifies GPO source files with RDP-friendly settings
- Resets local policy to defaults
- Includes automatic reboot for policy application

## Prerequisites

- Windows Server 2022
- LGPO.exe (Local Group Policy Object utility)
- CIS Server 2022 Standalone v1.0.0 GPO backup files
- Administrative privileges

## Usage

1. Ensure LGPO.exe is available at `C:\CIS\LGPO.exe`
2. Place CIS GPO backup files in `C:\CIS\Server2022StandAlonev1.0.0\`
3. Run the script as Administrator:
   ```powershell
   .\CIS-Hardening-RDP-Fix.ps1
   ```
4. The server will reboot automatically after policy application
5. Reconnect via AWS Session Manager after reboot

## File Structure

```
├── Server2022StandAlonev1.0.0/     # Original CIS policies (unmodified)
├── Modified-Server2022StandAlonev1.0.0/
│   ├── CIS-Hardening-RDP-Fix.ps1   # Main hardening script
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
- All changes are logged and can be audited
- **Original CIS policies are preserved** in `Server2022StandAlonev1.0.0/` for reference and comparison
- **Modified policies** are in `Modified-Server2022StandAlonev1.0.0/` with RDP-friendly configurations

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is provided as-is for educational and operational purposes.
