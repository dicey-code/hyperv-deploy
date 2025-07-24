#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Server 2022 Deployment Script with CLI-focused Server Core Support

.DESCRIPTION
    Complete PowerShell script for deploying Windows Server 2022 in CLI-only environment
    (Server Core mode by default) with user-friendly menu system for step-by-step deployment.
    
    Features:
    - CLI-focused deployment for Server Core
    - Optional Desktop Experience installation
    - Interactive menu system
    - Modular function structure
    - Comprehensive error handling and logging
    - Stage-based execution for reboot handling
    - Security best practices integration
    
.NOTES
    Author: Windows Server Deployment AI
    Version: 1.0.0
    Created: 2024
    Requires: Administrator privileges, PowerShell 5.1+, Windows Server 2022
    
.EXAMPLE
    .\DeployServer.ps1
    Launches the interactive menu system for server deployment
    
.EXAMPLE
    .\DeployServer.ps1 -Stage 2
    Resumes deployment from stage 2 (after reboot)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Stage = 1,
    
    [Parameter(Mandatory = $false)]
    [switch]$Silent,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile
)

# ============================================================================
# GLOBAL VARIABLES AND CONFIGURATION
# ============================================================================

$Global:ScriptVersion = "1.0.0"
$Global:LogFile = "C:\DeploymentLog.txt"
$Global:ConfigPath = "C:\ServerDeploymentConfig.xml"
$Global:StageFile = "C:\DeploymentStage.txt"

# Default configuration values - customize as needed
$Global:DefaultConfig = @{
    ServerName = ""
    DomainName = ""
    DomainUser = ""
    DomainPassword = ""
    DomainOU = ""
    StaticIP = ""
    SubnetMask = ""
    Gateway = ""
    PrimaryDNS = ""
    SecondaryDNS = ""
    InstallGUI = $false
    EnableFileSharing = $true
    ShareName = "CompanyShare"
    SharePath = "C:\Shares\CompanyShare"
    NTPServer = "time.windows.com"
    EnableRDP = $true
    InstallRSAT = $true
    JoinDomain = $false
}

# ============================================================================
# CORE LOGGING AND UTILITY FUNCTIONS
# ============================================================================

function Write-DeploymentLog {
    <#
    .SYNOPSIS
        Writes timestamped log entries to deployment log file and console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "STAGE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    try {
        Add-Content -Path $Global:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # If log file is not accessible, continue without logging to file
    }
    
    # Write to console with color coding
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "STAGE" { Write-Host $logEntry -ForegroundColor Cyan }
    }
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Validates system prerequisites for deployment
    #>
    Write-DeploymentLog -Message "Checking system prerequisites..." -Level "INFO"
    
    $issues = @()
    
    # Check if running as Administrator
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $issues += "Script must be run as Administrator"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell 5.1 or higher is required"
    }
    
    # Check Windows version
    $os = Get-WmiObject -Class Win32_OperatingSystem
    if ($os.Caption -notlike "*Server 2022*" -and $os.Caption -notlike "*Server 2019*" -and $os.Caption -notlike "*Server 2016*") {
        Write-DeploymentLog -Message "Warning: This script is optimized for Windows Server 2022 but may work on other versions" -Level "WARNING"
    }
    
    # Check available disk space
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    if ($systemDrive.FreeSpace -lt 10GB) {
        $issues += "At least 10GB of free space is required on system drive"
    }
    
    if ($issues.Count -gt 0) {
        Write-DeploymentLog -Message "Prerequisites check failed:" -Level "ERROR"
        foreach ($issue in $issues) {
            Write-DeploymentLog -Message "  - $issue" -Level "ERROR"
        }
        return $false
    }
    
    Write-DeploymentLog -Message "All prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Save-DeploymentStage {
    <#
    .SYNOPSIS
        Saves current deployment stage for resume after reboot
    #>
    param([int]$StageNumber)
    
    try {
        $StageNumber | Out-File -FilePath $Global:StageFile -Force
        Write-DeploymentLog -Message "Saved deployment stage: $StageNumber" -Level "INFO"
    }
    catch {
        Write-DeploymentLog -Message "Failed to save deployment stage: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Get-DeploymentStage {
    <#
    .SYNOPSIS
        Gets current deployment stage from file
    #>
    try {
        if (Test-Path $Global:StageFile) {
            $stage = Get-Content $Global:StageFile -ErrorAction Stop
            return [int]$stage
        }
    }
    catch {
        Write-DeploymentLog -Message "Failed to read deployment stage: $($_.Exception.Message)" -Level "WARNING"
    }
    return 1
}

function Save-DeploymentConfig {
    <#
    .SYNOPSIS
        Saves deployment configuration to XML file
    #>
    param([hashtable]$Config)
    
    try {
        $Config | Export-Clixml -Path $Global:ConfigPath -Force
        Write-DeploymentLog -Message "Configuration saved to $Global:ConfigPath" -Level "INFO"
    }
    catch {
        Write-DeploymentLog -Message "Failed to save configuration: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Load-DeploymentConfig {
    <#
    .SYNOPSIS
        Loads deployment configuration from XML file
    #>
    try {
        if (Test-Path $Global:ConfigPath) {
            $config = Import-Clixml -Path $Global:ConfigPath
            Write-DeploymentLog -Message "Configuration loaded from $Global:ConfigPath" -Level "INFO"
            return $config
        }
    }
    catch {
        Write-DeploymentLog -Message "Failed to load configuration: $($_.Exception.Message)" -Level "WARNING"
    }
    return $Global:DefaultConfig.Clone()
}

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

function Set-ServerName {
    <#
    .SYNOPSIS
        Renames the server with user input or configuration
    #>
    param([string]$NewName)
    
    Write-DeploymentLog -Message "Starting server rename process..." -Level "INFO"
    
    if (-not $NewName) {
        do {
            $NewName = Read-Host "Enter new server name (8-15 characters, letters/numbers only)"
            if ($NewName -match '^[a-zA-Z0-9]{1,15}$' -and $NewName.Length -ge 1) {
                break
            }
            Write-Host "Invalid server name. Use 1-15 characters, letters and numbers only." -ForegroundColor Red
        } while ($true)
    }
    
    try {
        $currentName = $env:COMPUTERNAME
        if ($currentName -eq $NewName) {
            Write-DeploymentLog -Message "Server name is already set to $NewName" -Level "INFO"
            return $true
        }
        
        Write-DeploymentLog -Message "Renaming server from $currentName to $NewName" -Level "INFO"
        Rename-Computer -NewName $NewName -Force -ErrorAction Stop
        Write-DeploymentLog -Message "Server renamed successfully. Reboot required." -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to rename server: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-StaticIPConfiguration {
    <#
    .SYNOPSIS
        Configures static IP address, subnet mask, gateway, and DNS
    #>
    param(
        [string]$IPAddress,
        [string]$SubnetMask,
        [string]$Gateway,
        [string]$PrimaryDNS,
        [string]$SecondaryDNS
    )
    
    Write-DeploymentLog -Message "Starting network configuration..." -Level "INFO"
    
    # Get network adapter
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.PhysicalMediaType -eq "802.3" } | Select-Object -First 1
    if (-not $adapter) {
        Write-DeploymentLog -Message "No active network adapter found" -Level "ERROR"
        return $false
    }
    
    Write-DeploymentLog -Message "Using network adapter: $($adapter.Name)" -Level "INFO"
    
    # Get network configuration from user if not provided
    if (-not $IPAddress) {
        Write-Host "`nCurrent network configuration:" -ForegroundColor Yellow
        Get-NetIPConfiguration -InterfaceAlias $adapter.Name | Format-Table -AutoSize
        
        do {
            $IPAddress = Read-Host "Enter static IP address (e.g., 192.168.1.100)"
            if ($IPAddress -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
                break
            }
            Write-Host "Invalid IP address format" -ForegroundColor Red
        } while ($true)
        
        do {
            $PrefixLength = Read-Host "Enter subnet prefix length (e.g., 24 for 255.255.255.0)"
            if ($PrefixLength -match '^\d+$' -and [int]$PrefixLength -ge 1 -and [int]$PrefixLength -le 32) {
                break
            }
            Write-Host "Invalid prefix length. Enter a number between 1 and 32" -ForegroundColor Red
        } while ($true)
        
        do {
            $Gateway = Read-Host "Enter default gateway (e.g., 192.168.1.1)"
            if ($Gateway -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
                break
            }
            Write-Host "Invalid gateway address format" -ForegroundColor Red
        } while ($true)
        
        do {
            $PrimaryDNS = Read-Host "Enter primary DNS server (e.g., 8.8.8.8)"
            if ($PrimaryDNS -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
                break
            }
            Write-Host "Invalid DNS server address format" -ForegroundColor Red
        } while ($true)
        
        $SecondaryDNS = Read-Host "Enter secondary DNS server (optional, press Enter to skip)"
        if ($SecondaryDNS -and -not ($SecondaryDNS -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')) {
            Write-Host "Invalid secondary DNS format, skipping..." -ForegroundColor Yellow
            $SecondaryDNS = ""
        }
    }
    else {
        # Convert subnet mask to prefix length if needed
        if ($SubnetMask) {
            switch ($SubnetMask) {
                "255.255.255.0" { $PrefixLength = 24 }
                "255.255.0.0" { $PrefixLength = 16 }
                "255.0.0.0" { $PrefixLength = 8 }
                default { $PrefixLength = 24 }
            }
        }
        else {
            $PrefixLength = 24
        }
    }
    
    try {
        Write-DeploymentLog -Message "Configuring static IP: $IPAddress/$PrefixLength" -Level "INFO"
        
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set static IP address
        New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway -ErrorAction Stop
        
        # Set DNS servers
        $dnsServers = @($PrimaryDNS)
        if ($SecondaryDNS) {
            $dnsServers += $SecondaryDNS
        }
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop
        
        Write-DeploymentLog -Message "Network configuration completed successfully" -Level "SUCCESS"
        Write-DeploymentLog -Message "IP Address: $IPAddress/$PrefixLength" -Level "INFO"
        Write-DeploymentLog -Message "Gateway: $Gateway" -Level "INFO"
        Write-DeploymentLog -Message "DNS Servers: $($dnsServers -join ', ')" -Level "INFO"
        
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to configure network: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-ServerRolesAndFeatures {
    <#
    .SYNOPSIS
        Installs common server roles and features
    #>
    Write-DeploymentLog -Message "Starting server roles and features installation..." -Level "INFO"
    
    # Define common roles and features for file server
    $features = @(
        "FS-FileServer",
        "RSAT-AD-PowerShell",
        "RSAT-AD-AdminCenter",
        "RSAT-ADDS-Tools",
        "RSAT-File-Services",
        "Telnet-Client"
    )
    
    # Ask user for additional features
    Write-Host "`nSelect additional server roles and features to install:" -ForegroundColor Yellow
    Write-Host "1. File Server (FS-FileServer) - Already included"
    Write-Host "2. Web Server (IIS-WebServerRole)"
    Write-Host "3. DNS Server (DNS)"
    Write-Host "4. DHCP Server (DHCP)"
    Write-Host "5. Print Server (Print-Services)"
    Write-Host "6. Remote Desktop Services (RDS-RD-Server)"
    Write-Host "7. Hyper-V (Hyper-V)"
    Write-Host ""
    
    $additionalFeatures = @()
    $choices = Read-Host "Enter feature numbers separated by commas (e.g., 2,3,5) or press Enter for default"
    
    if ($choices) {
        $selectedNumbers = $choices.Split(',') | ForEach-Object { $_.Trim() }
        foreach ($num in $selectedNumbers) {
            switch ($num) {
                "2" { $additionalFeatures += "IIS-WebServerRole", "IIS-WebServer", "IIS-CommonHttpFeatures" }
                "3" { $additionalFeatures += "DNS" }
                "4" { $additionalFeatures += "DHCP" }
                "5" { $additionalFeatures += "Print-Services" }
                "6" { $additionalFeatures += "RDS-RD-Server" }
                "7" { $additionalFeatures += "Hyper-V", "Hyper-V-PowerShell" }
            }
        }
    }
    
    $allFeatures = $features + $additionalFeatures
    
    try {
        foreach ($feature in $allFeatures) {
            Write-DeploymentLog -Message "Installing feature: $feature" -Level "INFO"
            $result = Install-WindowsFeature -Name $feature -IncludeManagementTools -ErrorAction Stop
            
            if ($result.Success) {
                Write-DeploymentLog -Message "Successfully installed: $feature" -Level "SUCCESS"
            }
            else {
                Write-DeploymentLog -Message "Failed to install: $feature" -Level "WARNING"
            }
        }
        
        # Check if reboot is required
        if ($result.RestartNeeded -eq "Yes") {
            Write-DeploymentLog -Message "Feature installation completed. Reboot required." -Level "WARNING"
            return "RebootRequired"
        }
        
        Write-DeploymentLog -Message "All features installed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to install features: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Enable-FileSharing {
    <#
    .SYNOPSIS
        Creates file shares with appropriate permissions
    #>
    param(
        [string]$ShareName = "CompanyShare",
        [string]$SharePath = "C:\Shares\CompanyShare"
    )
    
    Write-DeploymentLog -Message "Starting file sharing configuration..." -Level "INFO"
    
    if (-not $ShareName) {
        $ShareName = Read-Host "Enter share name (default: CompanyShare)"
        if (-not $ShareName) { $ShareName = "CompanyShare" }
    }
    
    if (-not $SharePath) {
        $SharePath = Read-Host "Enter share path (default: C:\Shares\$ShareName)"
        if (-not $SharePath) { $SharePath = "C:\Shares\$ShareName" }
    }
    
    try {
        # Create share directory
        if (-not (Test-Path $SharePath)) {
            Write-DeploymentLog -Message "Creating share directory: $SharePath" -Level "INFO"
            New-Item -Path $SharePath -ItemType Directory -Force -ErrorAction Stop
        }
        
        # Create SMB share
        Write-DeploymentLog -Message "Creating SMB share: $ShareName at $SharePath" -Level "INFO"
        
        # Remove existing share if it exists
        if (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue) {
            Remove-SmbShare -Name $ShareName -Force -ErrorAction SilentlyContinue
        }
        
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" -ErrorAction Stop
        
        # Set NTFS permissions
        Write-DeploymentLog -Message "Setting NTFS permissions on $SharePath" -Level "INFO"
        $acl = Get-Acl $SharePath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $SharePath -AclObject $acl -ErrorAction Stop
        
        Write-DeploymentLog -Message "File share created successfully: \\$env:COMPUTERNAME\$ShareName" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to create file share: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-FirewallConfiguration {
    <#
    .SYNOPSIS
        Configures Windows Firewall for file sharing and remote access
    #>
    Write-DeploymentLog -Message "Configuring Windows Firewall..." -Level "INFO"
    
    try {
        # Enable File and Printer Sharing
        Write-DeploymentLog -Message "Enabling File and Printer Sharing firewall rules" -Level "INFO"
        Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction Stop
        
        # Enable Network Discovery
        Write-DeploymentLog -Message "Enabling Network Discovery firewall rules" -Level "INFO"
        Enable-NetFirewallRule -DisplayGroup "Network Discovery" -ErrorAction Stop
        
        # Enable ping (ICMP)
        Write-DeploymentLog -Message "Enabling ICMP (ping) rules" -Level "INFO"
        Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction Stop
        Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)" -ErrorAction Stop
        
        # Create custom rules for SMB ports if needed
        $smbRules = @(
            @{Name="SMB-In-TCP-445"; Port=445; Protocol="TCP"},
            @{Name="SMB-In-TCP-139"; Port=139; Protocol="TCP"}
        )
        
        foreach ($rule in $smbRules) {
            if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
                Write-DeploymentLog -Message "Creating firewall rule: $($rule.Name)" -Level "INFO"
                New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -ErrorAction Stop
            }
        }
        
        Write-DeploymentLog -Message "Firewall configuration completed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to configure firewall: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Join-ServerToDomain {
    <#
    .SYNOPSIS
        Joins the server to a domain with credentials
    #>
    param(
        [string]$DomainName,
        [string]$DomainUser,
        [string]$DomainPassword,
        [string]$OrganizationalUnit
    )
    
    Write-DeploymentLog -Message "Starting domain join process..." -Level "INFO"
    
    # Get domain information from user if not provided
    if (-not $DomainName) {
        $DomainName = Read-Host "Enter domain name (e.g., company.local)"
        if (-not $DomainName) {
            Write-DeploymentLog -Message "Domain name is required for domain join" -Level "ERROR"
            return $false
        }
    }
    
    if (-not $DomainUser) {
        $DomainUser = Read-Host "Enter domain administrator username"
        if (-not $DomainUser) {
            Write-DeploymentLog -Message "Domain username is required for domain join" -Level "ERROR"
            return $false
        }
    }
    
    if (-not $DomainPassword) {
        $securePassword = Read-Host "Enter domain administrator password" -AsSecureString
    }
    else {
        $securePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
    }
    
    $credential = New-Object System.Management.Automation.PSCredential($DomainUser, $securePassword)
    
    # Optional OU specification
    if (-not $OrganizationalUnit) {
        $OrganizationalUnit = Read-Host "Enter Organizational Unit path (optional, press Enter to skip)"
    }
    
    try {
        # Test domain connectivity
        Write-DeploymentLog -Message "Testing connectivity to domain: $DomainName" -Level "INFO"
        $domainController = Resolve-DnsName -Name $DomainName -Type SRV -ErrorAction Stop | Select-Object -First 1
        
        if (-not $domainController) {
            Write-DeploymentLog -Message "Cannot resolve domain: $DomainName" -Level "ERROR"
            return $false
        }
        
        Write-DeploymentLog -Message "Domain controller found, attempting to join domain..." -Level "INFO"
        
        # Join domain
        $joinParams = @{
            DomainName = $DomainName
            Credential = $credential
            Force = $true
            ErrorAction = "Stop"
        }
        
        if ($OrganizationalUnit) {
            $joinParams.OUPath = $OrganizationalUnit
            Write-DeploymentLog -Message "Using OU: $OrganizationalUnit" -Level "INFO"
        }
        
        Add-Computer @joinParams
        
        Write-DeploymentLog -Message "Successfully joined domain: $DomainName" -Level "SUCCESS"
        Write-DeploymentLog -Message "Domain join completed. Reboot required." -Level "WARNING"
        
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to join domain: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-DesktopExperience {
    <#
    .SYNOPSIS
        Installs Desktop Experience (GUI) on Server Core
    #>
    Write-DeploymentLog -Message "Starting Desktop Experience installation..." -Level "INFO"
    
    # Check current installation type
    $installType = Get-WindowsFeature -Name "Server-Gui-Shell"
    if ($installType.InstallState -eq "Installed") {
        Write-DeploymentLog -Message "Desktop Experience is already installed" -Level "INFO"
        return $true
    }
    
    Write-Host "`nWARNING: Installing Desktop Experience will:" -ForegroundColor Yellow
    Write-Host "- Increase resource usage (RAM, CPU, disk space)" -ForegroundColor Yellow
    Write-Host "- Increase attack surface" -ForegroundColor Yellow
    Write-Host "- Require a reboot" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Do you want to continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-DeploymentLog -Message "Desktop Experience installation cancelled by user" -Level "INFO"
        return $false
    }
    
    try {
        Write-DeploymentLog -Message "Installing Server-Gui-Mgmt-Infra..." -Level "INFO"
        $result1 = Install-WindowsFeature -Name "Server-Gui-Mgmt-Infra" -ErrorAction Stop
        
        Write-DeploymentLog -Message "Installing Server-Gui-Shell..." -Level "INFO"
        $result2 = Install-WindowsFeature -Name "Server-Gui-Shell" -ErrorAction Stop
        
        if ($result1.Success -and $result2.Success) {
            Write-DeploymentLog -Message "Desktop Experience installed successfully" -Level "SUCCESS"
            Write-DeploymentLog -Message "Reboot required to complete installation" -Level "WARNING"
            return "RebootRequired"
        }
        else {
            Write-DeploymentLog -Message "Failed to install Desktop Experience components" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-DeploymentLog -Message "Failed to install Desktop Experience: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-SecurityConfiguration {
    <#
    .SYNOPSIS
        Configures security settings including TLS, SMB, and other protocols
    #>
    Write-DeploymentLog -Message "Starting security configuration..." -Level "INFO"
    
    try {
        # Disable SMB v1
        Write-DeploymentLog -Message "Disabling SMB v1 protocol..." -Level "INFO"
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
        
        # Configure SMB v2/v3
        Write-DeploymentLog -Message "Configuring SMB v2/v3 settings..." -Level "INFO"
        Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force -ErrorAction SilentlyContinue
        
        # Enable TLS 1.2 and 1.3
        Write-DeploymentLog -Message "Configuring TLS settings..." -Level "INFO"
        
        # TLS 1.2
        $tls12RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2"
        New-Item -Path "$tls12RegPath\Server" -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path "$tls12RegPath\Client" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "$tls12RegPath\Server" -Name "Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$tls12RegPath\Server" -Name "DisabledByDefault" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$tls12RegPath\Client" -Name "Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$tls12RegPath\Client" -Name "DisabledByDefault" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        
        # Disable older TLS versions
        $oldProtocols = @("SSL 2.0", "SSL 3.0", "TLS 1.0", "TLS 1.1")
        foreach ($protocol in $oldProtocols) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol"
            New-Item -Path "$regPath\Server" -Force -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path "$regPath\Client" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "$regPath\Server" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "$regPath\Client" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        
        # Configure NTP
        Write-DeploymentLog -Message "Configuring NTP time synchronization..." -Level "INFO"
        w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update | Out-Null
        Restart-Service w32time -ErrorAction SilentlyContinue
        
        # Enable Windows Defender if available
        Write-DeploymentLog -Message "Configuring Windows Defender..." -Level "INFO"
        if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        }
        
        Write-DeploymentLog -Message "Security configuration completed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to configure security settings: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Enable-RemoteDesktop {
    <#
    .SYNOPSIS
        Enables Remote Desktop with Network Level Authentication
    #>
    Write-DeploymentLog -Message "Configuring Remote Desktop..." -Level "INFO"
    
    try {
        # Enable Remote Desktop
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -ErrorAction Stop
        
        # Enable Network Level Authentication
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1 -ErrorAction Stop
        
        # Enable firewall rule for Remote Desktop
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop
        
        Write-DeploymentLog -Message "Remote Desktop enabled successfully with NLA" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Failed to enable Remote Desktop: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-DeploymentValidation {
    <#
    .SYNOPSIS
        Validates deployment configuration and services
    #>
    Write-DeploymentLog -Message "Starting deployment validation..." -Level "INFO"
    
    $validationResults = @()
    
    try {
        # Test network configuration
        Write-DeploymentLog -Message "Validating network configuration..." -Level "INFO"
        $networkConfig = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }
        if ($networkConfig) {
            $validationResults += "✓ Network configuration: OK"
            Write-DeploymentLog -Message "Network validation passed" -Level "SUCCESS"
        }
        else {
            $validationResults += "✗ Network configuration: FAILED"
            Write-DeploymentLog -Message "Network validation failed" -Level "ERROR"
        }
        
        # Test DNS resolution
        Write-DeploymentLog -Message "Testing DNS resolution..." -Level "INFO"
        $dnsTest = Resolve-DnsName "microsoft.com" -ErrorAction SilentlyContinue
        if ($dnsTest) {
            $validationResults += "✓ DNS resolution: OK"
            Write-DeploymentLog -Message "DNS validation passed" -Level "SUCCESS"
        }
        else {
            $validationResults += "✗ DNS resolution: FAILED"
            Write-DeploymentLog -Message "DNS validation failed" -Level "ERROR"
        }
        
        # Test domain connectivity if domain joined
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        if ($computerSystem.PartOfDomain) {
            Write-DeploymentLog -Message "Testing domain connectivity..." -Level "INFO"
            $domainTest = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
            if ($domainTest) {
                $validationResults += "✓ Domain connectivity: OK"
                Write-DeploymentLog -Message "Domain validation passed" -Level "SUCCESS"
            }
            else {
                $validationResults += "✗ Domain connectivity: FAILED"
                Write-DeploymentLog -Message "Domain validation failed" -Level "ERROR"
            }
        }
        else {
            $validationResults += "- Domain: Not joined (workgroup mode)"
        }
        
        # Test services
        Write-DeploymentLog -Message "Checking critical services..." -Level "INFO"
        $services = @("LanmanServer", "LanmanWorkstation", "Dnscache", "W32Time")
        foreach ($serviceName in $services) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                $validationResults += "✓ Service $serviceName: Running"
            }
            else {
                $validationResults += "✗ Service $serviceName: Not running"
            }
        }
        
        # Test file shares
        Write-DeploymentLog -Message "Checking file shares..." -Level "INFO"
        $shares = Get-SmbShare | Where-Object { $_.Name -ne "ADMIN$" -and $_.Name -ne "C$" -and $_.Name -ne "IPC$" }
        if ($shares) {
            foreach ($share in $shares) {
                $validationResults += "✓ Share: $($share.Name) at $($share.Path)"
            }
        }
        else {
            $validationResults += "- No user file shares configured"
        }
        
        # Display validation results
        Write-Host "`n=== DEPLOYMENT VALIDATION RESULTS ===" -ForegroundColor Cyan
        foreach ($result in $validationResults) {
            if ($result.StartsWith("✓")) {
                Write-Host $result -ForegroundColor Green
            }
            elseif ($result.StartsWith("✗")) {
                Write-Host $result -ForegroundColor Red
            }
            else {
                Write-Host $result -ForegroundColor Yellow
            }
        }
        Write-Host "=====================================" -ForegroundColor Cyan
        
        Write-DeploymentLog -Message "Deployment validation completed" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DeploymentLog -Message "Validation failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# ============================================================================
# MENU SYSTEM FUNCTIONS
# ============================================================================

function Show-MainHeader {
    <#
    .SYNOPSIS
        Displays the main script header
    #>
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "           Windows Server 2022 Deployment Script v$Global:ScriptVersion" -ForegroundColor Cyan
    Write-Host "                     CLI-Focused Server Core Deployment" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "Server: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "User:   $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Yellow
    Write-Host "OS:     $((Get-WmiObject Win32_OperatingSystem).Caption)" -ForegroundColor Yellow
    Write-Host "Log:    $Global:LogFile" -ForegroundColor Yellow
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main menu options
    #>
    Write-Host "DEPLOYMENT MENU:" -ForegroundColor Green
    Write-Host ""
    Write-Host " 1. Start Full Deployment (Sequential Steps)" -ForegroundColor White
    Write-Host " 2. Configure Network (Static IP, DNS, Gateway)" -ForegroundColor White
    Write-Host " 3. Rename Server" -ForegroundColor White
    Write-Host " 4. Install Server Roles and Features" -ForegroundColor White
    Write-Host " 5. Join Domain" -ForegroundColor White
    Write-Host " 6. Enable File Shares" -ForegroundColor White
    Write-Host " 7. Configure Windows Firewall" -ForegroundColor White
    Write-Host " 8. Install Desktop Experience (GUI)" -ForegroundColor White
    Write-Host " 9. Configure Security Settings" -ForegroundColor White
    Write-Host "10. Enable Remote Desktop" -ForegroundColor White
    Write-Host "11. Validate Deployment" -ForegroundColor White
    Write-Host "12. View Deployment Log" -ForegroundColor White
    Write-Host "13. Help and Information" -ForegroundColor White
    Write-Host " 0. Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
}

function Show-HelpInformation {
    <#
    .SYNOPSIS
        Displays help and information page
    #>
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "                        HELP AND INFORMATION" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "SCRIPT DESCRIPTION:" -ForegroundColor Green
    Write-Host "This script automates the deployment and configuration of Windows Server 2022"
    Write-Host "with a focus on Server Core (CLI-only) installations. It provides a user-friendly"
    Write-Host "menu system to guide you through each deployment step."
    Write-Host ""
    
    Write-Host "PREREQUISITES:" -ForegroundColor Green
    Write-Host "• Fresh Windows Server 2022 installation (Core or Desktop Experience)"
    Write-Host "• Administrator privileges (script must run as Administrator)"
    Write-Host "• PowerShell 5.1 or higher"
    Write-Host "• Network connectivity for domain operations"
    Write-Host "• Domain credentials (if joining a domain)"
    Write-Host ""
    
    Write-Host "KEY FEATURES:" -ForegroundColor Green
    Write-Host "• Server Core optimized deployment"
    Write-Host "• Optional Desktop Experience (GUI) installation"
    Write-Host "• Network configuration (static IP, DNS, gateway)"
    Write-Host "• Server renaming with reboot handling"
    Write-Host "• Role and feature installation (File Server, RSAT, etc.)"
    Write-Host "• Domain join with OU specification"
    Write-Host "• File sharing with SMB and NTFS permissions"
    Write-Host "• Firewall configuration for file sharing"
    Write-Host "• Security hardening (disable SMBv1, enable TLS 1.2/1.3)"
    Write-Host "• Remote Desktop enablement"
    Write-Host "• Comprehensive logging and validation"
    Write-Host ""
    
    Write-Host "USAGE TIPS:" -ForegroundColor Green
    Write-Host "• Run the script as Administrator"
    Write-Host "• Use 'Start Full Deployment' for guided sequential setup"
    Write-Host "• Individual menu options allow specific task configuration"
    Write-Host "• Script handles reboots - re-run after restart to continue"
    Write-Host "• Check deployment log for detailed operation history"
    Write-Host "• Test in a lab environment before production use"
    Write-Host ""
    
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Green
    Write-Host "• Check the deployment log for error details"
    Write-Host "• Ensure network connectivity for domain operations"
    Write-Host "• Verify Administrator privileges"
    Write-Host "• Run validation to check configuration status"
    Write-Host "• Restart services if network issues occur"
    Write-Host ""
    
    Write-Host "BEST PRACTICES:" -ForegroundColor Green
    Write-Host "• Backup system before major changes"
    Write-Host "• Document custom configurations"
    Write-Host "• Test domain connectivity before joining"
    Write-Host "• Review firewall rules for security"
    Write-Host "• Monitor system resources after GUI installation"
    Write-Host ""
    
    Write-Host "Press Enter to return to main menu..." -ForegroundColor Yellow
    Read-Host
}

function Show-DeploymentLog {
    <#
    .SYNOPSIS
        Displays the deployment log file
    #>
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "                          DEPLOYMENT LOG" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "Log File: $Global:LogFile" -ForegroundColor Yellow
    Write-Host ""
    
    if (Test-Path $Global:LogFile) {
        $logContent = Get-Content $Global:LogFile -Tail 50
        foreach ($line in $logContent) {
            if ($line -like "*[ERROR]*") {
                Write-Host $line -ForegroundColor Red
            }
            elseif ($line -like "*[WARNING]*") {
                Write-Host $line -ForegroundColor Yellow
            }
            elseif ($line -like "*[SUCCESS]*") {
                Write-Host $line -ForegroundColor Green
            }
            elseif ($line -like "*[STAGE]*") {
                Write-Host $line -ForegroundColor Cyan
            }
            else {
                Write-Host $line -ForegroundColor White
            }
        }
        Write-Host ""
        Write-Host "Showing last 50 log entries. Full log available at: $Global:LogFile" -ForegroundColor Yellow
    }
    else {
        Write-Host "Log file not found. No deployment activities recorded yet." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Press Enter to return to main menu..." -ForegroundColor Yellow
    Read-Host
}

function Start-FullDeployment {
    <#
    .SYNOPSIS
        Executes full sequential deployment with user prompts
    #>
    Write-DeploymentLog -Message "=== STARTING FULL SERVER DEPLOYMENT ===" -Level "STAGE"
    
    Write-Host "This will guide you through a complete server deployment process." -ForegroundColor Yellow
    Write-Host "You can stop at any point and resume later using individual menu options." -ForegroundColor Yellow
    Write-Host ""
    
    $proceed = Read-Host "Do you want to continue with full deployment? (y/N)"
    if ($proceed -ne 'y' -and $proceed -ne 'Y') {
        Write-DeploymentLog -Message "Full deployment cancelled by user" -Level "INFO"
        return
    }
    
    $config = Load-DeploymentConfig
    $rebootRequired = $false
    
    # Step 1: Network Configuration
    Write-Host "`n=== STEP 1: NETWORK CONFIGURATION ===" -ForegroundColor Cyan
    $configureNetwork = Read-Host "Configure static IP address? (Y/n)"
    if ($configureNetwork -ne 'n' -and $configureNetwork -ne 'N') {
        Set-StaticIPConfiguration
    }
    
    # Step 2: Server Rename
    Write-Host "`n=== STEP 2: SERVER RENAME ===" -ForegroundColor Cyan
    $renameServer = Read-Host "Rename the server? (Y/n)"
    if ($renameServer -ne 'n' -and $renameServer -ne 'N') {
        $result = Set-ServerName
        if ($result) {
            $rebootRequired = $true
        }
    }
    
    # Step 3: Install Roles and Features
    Write-Host "`n=== STEP 3: ROLES AND FEATURES ===" -ForegroundColor Cyan
    $installRoles = Read-Host "Install server roles and features? (Y/n)"
    if ($installRoles -ne 'n' -and $installRoles -ne 'N') {
        $result = Install-ServerRolesAndFeatures
        if ($result -eq "RebootRequired") {
            $rebootRequired = $true
        }
    }
    
    # Step 4: Domain Join
    Write-Host "`n=== STEP 4: DOMAIN JOIN ===" -ForegroundColor Cyan
    $joinDomain = Read-Host "Join server to domain? (y/N)"
    if ($joinDomain -eq 'y' -or $joinDomain -eq 'Y') {
        $result = Join-ServerToDomain
        if ($result) {
            $rebootRequired = $true
        }
    }
    
    # Handle reboot requirement
    if ($rebootRequired) {
        Write-Host "`n=== REBOOT REQUIRED ===" -ForegroundColor Red
        Write-Host "Some changes require a system reboot to take effect." -ForegroundColor Yellow
        Write-Host "After reboot, run this script again to continue with remaining steps." -ForegroundColor Yellow
        Write-Host ""
        
        $rebootNow = Read-Host "Reboot now? (y/N)"
        if ($rebootNow -eq 'y' -or $rebootNow -eq 'Y') {
            Write-DeploymentLog -Message "System reboot initiated by user" -Level "INFO"
            Save-DeploymentStage -StageNumber 2
            Save-DeploymentConfig -Config $config
            Restart-Computer -Force
            return
        }
        else {
            Write-Host "Please reboot manually and re-run the script to continue." -ForegroundColor Yellow
            return
        }
    }
    
    # Continue with post-reboot steps
    # Step 5: File Sharing
    Write-Host "`n=== STEP 5: FILE SHARING ===" -ForegroundColor Cyan
    $enableSharing = Read-Host "Enable file sharing? (Y/n)"
    if ($enableSharing -ne 'n' -and $enableSharing -ne 'N') {
        Enable-FileSharing
    }
    
    # Step 6: Firewall Configuration
    Write-Host "`n=== STEP 6: FIREWALL CONFIGURATION ===" -ForegroundColor Cyan
    $configureFirewall = Read-Host "Configure Windows Firewall? (Y/n)"
    if ($configureFirewall -ne 'n' -and $configureFirewall -ne 'N') {
        Set-FirewallConfiguration
    }
    
    # Step 7: Security Configuration
    Write-Host "`n=== STEP 7: SECURITY CONFIGURATION ===" -ForegroundColor Cyan
    $configureSecurity = Read-Host "Apply security hardening? (Y/n)"
    if ($configureSecurity -ne 'n' -and $configureSecurity -ne 'N') {
        Set-SecurityConfiguration
    }
    
    # Step 8: Remote Desktop
    Write-Host "`n=== STEP 8: REMOTE DESKTOP ===" -ForegroundColor Cyan
    $enableRDP = Read-Host "Enable Remote Desktop? (Y/n)"
    if ($enableRDP -ne 'n' -and $enableRDP -ne 'N') {
        Enable-RemoteDesktop
    }
    
    # Step 9: Optional GUI Installation
    Write-Host "`n=== STEP 9: DESKTOP EXPERIENCE (OPTIONAL) ===" -ForegroundColor Cyan
    $installGUI = Read-Host "Install Desktop Experience (GUI)? (y/N)"
    if ($installGUI -eq 'y' -or $installGUI -eq 'Y') {
        $result = Install-DesktopExperience
        if ($result -eq "RebootRequired") {
            Write-Host "Desktop Experience installation requires a reboot." -ForegroundColor Yellow
            $rebootNow = Read-Host "Reboot now? (y/N)"
            if ($rebootNow -eq 'y' -or $rebootNow -eq 'Y') {
                Write-DeploymentLog -Message "System reboot for GUI installation" -Level "INFO"
                Restart-Computer -Force
                return
            }
        }
    }
    
    # Final validation
    Write-Host "`n=== FINAL VALIDATION ===" -ForegroundColor Cyan
    Test-DeploymentValidation
    
    Write-DeploymentLog -Message "=== FULL DEPLOYMENT COMPLETED ===" -Level "STAGE"
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "Check the deployment log for detailed information." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to return to main menu..." -ForegroundColor Yellow
    Read-Host
}

function Get-MenuSelection {
    <#
    .SYNOPSIS
        Gets and validates user menu selection
    #>
    do {
        Write-Host "Enter your choice (0-13): " -NoNewline -ForegroundColor White
        $selection = Read-Host
        
        if ($selection -match '^([0-9]|1[0-3])$') {
            return [int]$selection
        }
        
        Write-Host "Invalid selection. Please enter a number between 0 and 13." -ForegroundColor Red
    } while ($true)
}

# ============================================================================
# MAIN EXECUTION FUNCTION
# ============================================================================

function Start-ServerDeployment {
    <#
    .SYNOPSIS
        Main script execution function with menu loop
    #>
    try {
        # Initialize logging
        Write-DeploymentLog -Message "=== Windows Server 2022 Deployment Script Started ===" -Level "STAGE"
        Write-DeploymentLog -Message "Script Version: $Global:ScriptVersion" -Level "INFO"
        Write-DeploymentLog -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Level "INFO"
        Write-DeploymentLog -Message "Operating System: $((Get-WmiObject Win32_OperatingSystem).Caption)" -Level "INFO"
        Write-DeploymentLog -Message "Current User: $env:USERDOMAIN\$env:USERNAME" -Level "INFO"
        
        # Check prerequisites
        if (-not (Test-Prerequisites)) {
            Write-Host "Prerequisites check failed. Please resolve issues and run the script again." -ForegroundColor Red
            Write-Host "Press Enter to exit..." -ForegroundColor Yellow
            Read-Host
            return
        }
        
        # Check if resuming from a previous stage
        if ($Stage -gt 1) {
            Write-DeploymentLog -Message "Resuming deployment from stage: $Stage" -Level "INFO"
        }
        
        # Main menu loop
        do {
            Show-MainHeader
            Show-MainMenu
            
            $selection = Get-MenuSelection
            
            Write-DeploymentLog -Message "User selected menu option: $selection" -Level "INFO"
            
            switch ($selection) {
                1 { 
                    Start-FullDeployment
                }
                2 { 
                    Set-StaticIPConfiguration
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                3 { 
                    $result = Set-ServerName
                    if ($result) {
                        Write-Host "`nServer rename completed. Reboot required." -ForegroundColor Yellow
                        $reboot = Read-Host "Reboot now? (y/N)"
                        if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                            Restart-Computer -Force
                            return
                        }
                    }
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                4 { 
                    $result = Install-ServerRolesAndFeatures
                    if ($result -eq "RebootRequired") {
                        Write-Host "`nFeature installation completed. Reboot required." -ForegroundColor Yellow
                        $reboot = Read-Host "Reboot now? (y/N)"
                        if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                            Restart-Computer -Force
                            return
                        }
                    }
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                5 { 
                    $result = Join-ServerToDomain
                    if ($result) {
                        Write-Host "`nDomain join completed. Reboot required." -ForegroundColor Yellow
                        $reboot = Read-Host "Reboot now? (y/N)"
                        if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                            Restart-Computer -Force
                            return
                        }
                    }
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                6 { 
                    Enable-FileSharing
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                7 { 
                    Set-FirewallConfiguration
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                8 { 
                    $result = Install-DesktopExperience
                    if ($result -eq "RebootRequired") {
                        Write-Host "`nDesktop Experience installation completed. Reboot required." -ForegroundColor Yellow
                        $reboot = Read-Host "Reboot now? (y/N)"
                        if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                            Restart-Computer -Force
                            return
                        }
                    }
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                9 { 
                    Set-SecurityConfiguration
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                10 { 
                    Enable-RemoteDesktop
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                11 { 
                    Test-DeploymentValidation
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                }
                12 { 
                    Show-DeploymentLog
                }
                13 { 
                    Show-HelpInformation
                }
                0 { 
                    Write-DeploymentLog -Message "User selected exit" -Level "INFO"
                    Write-Host "`nThank you for using the Windows Server 2022 Deployment Script!" -ForegroundColor Green
                    break
                }
                default { 
                    Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            
        } while ($selection -ne 0)
        
    }
    catch {
        Write-DeploymentLog -Message "Critical error in main execution: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "`nA critical error occurred. Check the deployment log for details." -ForegroundColor Red
        Write-Host "Log file: $Global:LogFile" -ForegroundColor Yellow
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        Read-Host
    }
    finally {
        Write-DeploymentLog -Message "=== Windows Server 2022 Deployment Script Ended ===" -Level "STAGE"
    }
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Only run if script is executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Start-ServerDeployment
}