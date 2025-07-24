# Windows Server 2022 Deployment Script

## Overview

**DeployServer.ps1** is a comprehensive, single-file PowerShell script designed for deploying Windows Server 2022 in CLI-only environments (Server Core mode by default). The script provides a user-friendly menu system to guide users through the deployment process step by step.

## Key Features

### ✅ CLI-Focused Deployment
- Designed primarily for Server Core installation (no GUI by default)
- Lightweight, secure setup with reduced attack surface
- Uses PowerShell commands that work in command-line interface

### ✅ Optional Desktop Experience
- Includes optional feature to install Desktop Experience (GUI)
- Handles required reboots and feature installations
- Uses `Install-WindowsFeature` for `Server-Gui-Mgmt-Infra` and `Server-Gui-Shell`

### ✅ Modular Structure
- Organized with functions for each major task
- Variables defined at the top for easy customization
- Comprehensive error handling with Try-Catch blocks
- Logging to file (`C:\DeploymentLog.txt`)

### ✅ Key Deployment Features
- **Server Naming**: Rename server and configure static IP, subnet, gateway, and DNS
- **Role Installation**: Install common roles and features like `FS-FileServer`, `RSAT-AD-PowerShell`
- **Service Setup**: Ensure WMI service is setup and necessary firewall rules are enabled
- **Domain Join**: Join domain with credentials and optional OU path
- **File Sharing**: Enable file shares with permissions (SMB shares, NTFS settings)
- **Firewall Config**: Configure Windows Firewall for file sharing (ports 445, 139, File and Printer Sharing)
- **Security**: Enable ICMP ping, manage SMB versions (disable SMBv1), set NTP, enable RDP
- **Validation**: Verification steps like `Test-ComputerSecureChannel`
- **Security Features**: TLS 1.3 enablement, disable outdated protocols

### ✅ Reboot Handling
- Structured to run in stages for handling required reboots
- Uses parameters and menu options to resume from specific stage after reboot
- Automatic stage tracking and configuration persistence

### ✅ Interactive Menu System
- Clean, text-based menu using PowerShell with loop and Read-Host input
- 13 comprehensive menu options including help and log viewing
- Error handling for invalid menu choices
- User guidance with prompts and confirmations

## Menu Options

1. **Start Full Deployment** - Guide through all steps sequentially
2. **Configure Network** - Static IP, DNS, gateway configuration
3. **Rename Server** - Server renaming with reboot handling
4. **Install Server Roles/Features** - File Server, RSAT, IIS, DNS, DHCP options
5. **Join Domain** - Domain join with OU specification
6. **Enable File Shares** - SMB shares with NTFS permissions
7. **Configure Firewall** - Windows Firewall for file sharing
8. **Install Desktop Experience** - Optional GUI installation with warnings
9. **Configure Security** - TLS, SMB, NTP, security hardening
10. **Enable Remote Desktop** - RDP with Network Level Authentication
11. **Validate Deployment** - Comprehensive validation checks
12. **View Deployment Log** - Display deployment log with color coding
13. **Help and Information** - Prerequisites, best practices, troubleshooting
14. **Exit** - Clean script termination

## Prerequisites

- Fresh Windows Server 2022 installation (Core or Desktop Experience)
- Administrator privileges (script must run as Administrator)
- PowerShell 5.1 or higher
- Network connectivity for domain operations
- At least 10GB free disk space
- Domain credentials (if joining a domain)

## Usage

### Basic Usage
```powershell
# Run PowerShell as Administrator
.\DeployServer.ps1
```

### Resume After Reboot
```powershell
# Resume from specific stage after reboot
.\DeployServer.ps1 -Stage 2
```

### Command Line Parameters
- `-Stage <number>`: Resume from specific deployment stage
- `-Silent`: Run in silent mode (minimal user interaction)
- `-ConfigFile <path>`: Specify configuration file for automated deployment

## Best Practices

### Security
- **Secured-core elements**: TPM and Secure Boot handling where applicable
- **TLS 1.3**: Enabled with older protocol disabling
- **SMB Security**: SMBv1 disabled, SMBv2/v3 configured
- **Firewall**: Proper rule configuration for services
- **Digital Signing**: Script includes notes for signing best practices

### Testing
- Test in VM/lab environment first
- Handle reboots manually during testing
- Customize variables in script header as needed
- Review deployment log for detailed operation history

### Multiple Servers
- Script supports configuration file input for automation
- Flexible design allows input file processing
- Configuration export/import capability for standardization

## Technical Implementation

### Logging System
- Timestamped log entries to `C:\DeploymentLog.txt`
- Color-coded console output (INFO, WARNING, ERROR, SUCCESS, STAGE)
- Detailed operation tracking and error reporting

### Error Handling
- Comprehensive Try-Catch blocks throughout
- Graceful failure handling with user notification
- Validation checks before operations
- Recovery options and user guidance

### Configuration Management
- XML-based configuration persistence
- Stage tracking for reboot scenarios
- Default configuration values with user override
- Configuration validation and sanitization

## Integration Options

The script includes basic setup preparation for:
- **MDT/WDS**: Microsoft Deployment Toolkit integration
- **Azure Arc**: Azure hybrid management preparation
- **Storage Spaces Direct**: Storage configuration foundation

## Files Created

- `C:\DeploymentLog.txt` - Detailed deployment log
- `C:\ServerDeploymentConfig.xml` - Configuration persistence
- `C:\DeploymentStage.txt` - Stage tracking for reboots
- `C:\Shares\<ShareName>\` - Default file share location

## Compatibility

- **Windows Server 2022** (Primary target)
- **Windows Server 2019** (Compatible)
- **Windows Server 2016** (Compatible with warnings)
- **PowerShell 5.1+** (Required)

## Support and Troubleshooting

### Common Issues
1. **Administrator Privileges**: Ensure script runs as Administrator
2. **PowerShell Version**: Verify PowerShell 5.1 or higher
3. **Network Connectivity**: Check DNS resolution and domain connectivity
4. **Disk Space**: Ensure sufficient space for operations

### Validation Commands
The script includes comprehensive validation that checks:
- Network configuration and DNS resolution
- Domain connectivity (if joined)
- Critical service status
- File share configuration
- Security settings compliance

### Log Analysis
- View deployment log through menu option 12
- Color-coded entries for easy issue identification
- Detailed error messages with timestamps
- Operation tracking for audit purposes

This script represents a complete solution for Windows Server 2022 deployment, meeting all requirements specified for CLI-focused, menu-driven, secure server deployment with comprehensive error handling and logging.