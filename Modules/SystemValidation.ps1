# System Validation Module for Hyper-V Deployment
# Contains functions for validating system prerequisites

function Test-HyperVPrerequisites {
    <#
    .SYNOPSIS
        Validates all system prerequisites for Hyper-V deployment
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting comprehensive system validation..." -Level "INFO"
    
    $validationResults = @{
        HardwareValidation = Test-HardwareRequirements
        SoftwareValidation = Test-SoftwareRequirements
        NetworkValidation = Test-NetworkReadiness
        StorageValidation = Test-StorageRequirements
        RoleValidation = Test-CurrentRoles
    }
    
    # Generate validation summary
    $overallStatus = $true
    foreach ($key in $validationResults.Keys) {
        if (-not $validationResults[$key].Status) {
            $overallStatus = $false
        }
    }
    
    Show-ValidationSummary -Results $validationResults -OverallStatus $overallStatus
    
    return @{
        Status = $overallStatus
        Results = $validationResults
    }
}

function Test-HardwareRequirements {
    <#
    .SYNOPSIS
        Validates hardware requirements for Hyper-V
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nValidating Hardware Requirements..." -ForegroundColor Yellow
    $results = @{
        Status = $true
        Details = @()
        Issues = @()
    }
    
    try {
        # Check for virtualization support
        $cpu = Get-WmiObject -Class Win32_Processor
        $vtSupport = $false
        
        # Check for Intel VT-x or AMD-V
        $systemInfo = systeminfo | Select-String "Hyper-V Requirements"
        if ($systemInfo) {
            $hyperVInfo = systeminfo | Select-String "VM Monitor Mode Extensions|Virtualization Enabled In Firmware|Second Level Address Translation|Data Execution Prevention Available"
            $vtSupport = ($hyperVInfo | Where-Object { $_ -match "Yes" }).Count -ge 3
        }
        
        if ($vtSupport) {
            $results.Details += "✓ Virtualization Technology: Supported"
            Write-Host "  ✓ Virtualization Technology: Supported" -ForegroundColor Green
        } else {
            $results.Status = $false
            $results.Issues += "✗ Virtualization Technology: Not detected or not enabled in BIOS"
            Write-Host "  ✗ Virtualization Technology: Not detected or not enabled in BIOS" -ForegroundColor Red
        }
        
        # Check RAM
        $totalRAM = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        if ($totalRAM -ge 4) {
            $results.Details += "✓ RAM: $totalRAM GB (Minimum 4GB required)"
            Write-Host "  ✓ RAM: $totalRAM GB (Minimum 4GB required)" -ForegroundColor Green
        } else {
            $results.Status = $false
            $results.Issues += "✗ RAM: $totalRAM GB (Minimum 4GB required)"
            Write-Host "  ✗ RAM: $totalRAM GB (Minimum 4GB required)" -ForegroundColor Red
        }
        
        # Check available disk space
        $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -ge 20) {
            $results.Details += "✓ Free Disk Space: $freeSpaceGB GB (Minimum 20GB recommended)"
            Write-Host "  ✓ Free Disk Space: $freeSpaceGB GB (Minimum 20GB recommended)" -ForegroundColor Green
        } else {
            $results.Status = $false
            $results.Issues += "✗ Free Disk Space: $freeSpaceGB GB (Minimum 20GB recommended)"
            Write-Host "  ✗ Free Disk Space: $freeSpaceGB GB (Minimum 20GB recommended)" -ForegroundColor Red
        }
        
        # Check CPU cores
        $cores = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
        if ($cores -ge 2) {
            $results.Details += "✓ CPU Cores: $cores (Minimum 2 recommended)"
            Write-Host "  ✓ CPU Cores: $cores (Minimum 2 recommended)" -ForegroundColor Green
        } else {
            $results.Issues += "⚠ CPU Cores: $cores (Minimum 2 recommended for optimal performance)"
            Write-Host "  ⚠ CPU Cores: $cores (Minimum 2 recommended for optimal performance)" -ForegroundColor Yellow
        }
        
    }
    catch {
        $results.Status = $false
        $results.Issues += "Error during hardware validation: $($_.Exception.Message)"
        Write-Log -Message "Hardware validation error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

function Test-SoftwareRequirements {
    <#
    .SYNOPSIS
        Validates software requirements for Hyper-V
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nValidating Software Requirements..." -ForegroundColor Yellow
    $results = @{
        Status = $true
        Details = @()
        Issues = @()
    }
    
    try {
        # Check Windows Server version
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $osVersion = $os.Caption
        $buildNumber = $os.BuildNumber
        
        $supportedVersions = @(
            @{ Name = "Windows Server 2016"; MinBuild = 14393 },
            @{ Name = "Windows Server 2019"; MinBuild = 17763 },
            @{ Name = "Windows Server 2022"; MinBuild = 20348 },
            @{ Name = "Windows Server 2025"; MinBuild = 26100 }
        )
        
        $versionSupported = $false
        foreach ($version in $supportedVersions) {
            if ($buildNumber -ge $version.MinBuild) {
                $versionSupported = $true
                break
            }
        }
        
        if ($versionSupported) {
            $results.Details += "✓ Operating System: $osVersion (Build $buildNumber)"
            Write-Host "  ✓ Operating System: $osVersion (Build $buildNumber)" -ForegroundColor Green
        } else {
            $results.Status = $false
            $results.Issues += "✗ Operating System: $osVersion not supported for Hyper-V"
            Write-Host "  ✗ Operating System: $osVersion not supported for Hyper-V" -ForegroundColor Red
        }
        
        # Check PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -ge 5) {
            $results.Details += "✓ PowerShell Version: $($psVersion.ToString())"
            Write-Host "  ✓ PowerShell Version: $($psVersion.ToString())" -ForegroundColor Green
        } else {
            $results.Status = $false
            $results.Issues += "✗ PowerShell Version: $($psVersion.ToString()) (Minimum 5.1 required)"
            Write-Host "  ✗ PowerShell Version: $($psVersion.ToString()) (Minimum 5.1 required)" -ForegroundColor Red
        }
        
        # Check execution policy
        $executionPolicy = Get-ExecutionPolicy
        if ($executionPolicy -in @("Unrestricted", "RemoteSigned", "Bypass")) {
            $results.Details += "✓ PowerShell Execution Policy: $executionPolicy"
            Write-Host "  ✓ PowerShell Execution Policy: $executionPolicy" -ForegroundColor Green
        } else {
            $results.Issues += "⚠ PowerShell Execution Policy: $executionPolicy (May need adjustment)"
            Write-Host "  ⚠ PowerShell Execution Policy: $executionPolicy (May need adjustment)" -ForegroundColor Yellow
        }
        
        # Check if Hyper-V is already installed
        $hyperVFeature = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
        if ($hyperVFeature) {
            if ($hyperVFeature.InstallState -eq "Installed") {
                $results.Details += "ℹ Hyper-V Role: Already installed"
                Write-Host "  ℹ Hyper-V Role: Already installed" -ForegroundColor Cyan
            } else {
                $results.Details += "✓ Hyper-V Role: Available for installation"
                Write-Host "  ✓ Hyper-V Role: Available for installation" -ForegroundColor Green
            }
        }
        
    }
    catch {
        $results.Status = $false
        $results.Issues += "Error during software validation: $($_.Exception.Message)"
        Write-Log -Message "Software validation error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

function Test-NetworkReadiness {
    <#
    .SYNOPSIS
        Tests network connectivity and readiness
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nValidating Network Readiness..." -ForegroundColor Yellow
    $results = @{
        Status = $true
        Details = @()
        Issues = @()
    }
    
    try {
        # Check network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if ($adapters.Count -gt 0) {
            $results.Details += "✓ Active Network Adapters: $($adapters.Count) found"
            Write-Host "  ✓ Active Network Adapters: $($adapters.Count) found" -ForegroundColor Green
            
            foreach ($adapter in $adapters) {
                $results.Details += "    - $($adapter.Name) ($($adapter.InterfaceDescription))"
                Write-Host "    - $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            }
        } else {
            $results.Status = $false
            $results.Issues += "✗ No active network adapters found"
            Write-Host "  ✗ No active network adapters found" -ForegroundColor Red
        }
        
        # Test DNS resolution
        try {
            $dnsTest = Resolve-DnsName "google.com" -ErrorAction Stop
            $results.Details += "✓ DNS Resolution: Working"
            Write-Host "  ✓ DNS Resolution: Working" -ForegroundColor Green
        }
        catch {
            $results.Issues += "⚠ DNS Resolution: May have issues"
            Write-Host "  ⚠ DNS Resolution: May have issues" -ForegroundColor Yellow
        }
        
        # Check domain connectivity if domain joined
        if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
            $domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
            $results.Details += "ℹ Domain Status: Joined to $domain"
            Write-Host "  ℹ Domain Status: Joined to $domain" -ForegroundColor Cyan
            
            # Test domain controller connectivity
            try {
                $dcTest = Test-ComputerSecureChannel -ErrorAction Stop
                if ($dcTest) {
                    $results.Details += "✓ Domain Controller Connectivity: Verified"
                    Write-Host "  ✓ Domain Controller Connectivity: Verified" -ForegroundColor Green
                } else {
                    $results.Issues += "⚠ Domain Controller Connectivity: Issues detected"
                    Write-Host "  ⚠ Domain Controller Connectivity: Issues detected" -ForegroundColor Yellow
                }
            }
            catch {
                $results.Issues += "⚠ Domain Controller Connectivity: Cannot verify"
                Write-Host "  ⚠ Domain Controller Connectivity: Cannot verify" -ForegroundColor Yellow
            }
        } else {
            $results.Details += "ℹ Domain Status: Workgroup (not domain joined)"
            Write-Host "  ℹ Domain Status: Workgroup (not domain joined)" -ForegroundColor Cyan
        }
        
    }
    catch {
        $results.Status = $false
        $results.Issues += "Error during network validation: $($_.Exception.Message)"
        Write-Log -Message "Network validation error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

function Test-StorageRequirements {
    <#
    .SYNOPSIS
        Validates storage requirements and configuration
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nValidating Storage Requirements..." -ForegroundColor Yellow
    $results = @{
        Status = $true
        Details = @()
        Issues = @()
    }
    
    try {
        # Check all drives
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $totalSpace = 0
        $totalFree = 0
        
        foreach ($drive in $drives) {
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $totalSpace += $sizeGB
            $totalFree += $freeGB
            
            $results.Details += "✓ Drive $($drive.DeviceID) - Size: $sizeGB GB, Free: $freeGB GB"
            Write-Host "  ✓ Drive $($drive.DeviceID) - Size: $sizeGB GB, Free: $freeGB GB" -ForegroundColor Green
        }
        
        # Check for SAN/iSCSI connectivity
        $iscsiSessions = Get-IscsiSession -ErrorAction SilentlyContinue
        if ($iscsiSessions) {
            $results.Details += "ℹ iSCSI Sessions: $($iscsiSessions.Count) active"
            Write-Host "  ℹ iSCSI Sessions: $($iscsiSessions.Count) active" -ForegroundColor Cyan
        }
        
        # Check for multipathing (MPIO)
        $mpioFeature = Get-WindowsFeature -Name Multipath-IO -ErrorAction SilentlyContinue
        if ($mpioFeature -and $mpioFeature.InstallState -eq "Installed") {
            $results.Details += "✓ Multipath-IO: Installed"
            Write-Host "  ✓ Multipath-IO: Installed" -ForegroundColor Green
        } else {
            $results.Details += "ℹ Multipath-IO: Not installed (install if using SAN)"
            Write-Host "  ℹ Multipath-IO: Not installed (install if using SAN)" -ForegroundColor Cyan
        }
        
        # Overall storage assessment
        if ($totalFree -ge 100) {
            $results.Details += "✓ Total Available Space: $totalFree GB (Recommended for VM storage)"
            Write-Host "  ✓ Total Available Space: $totalFree GB (Recommended for VM storage)" -ForegroundColor Green
        } else {
            $results.Issues += "⚠ Total Available Space: $totalFree GB (Consider additional storage for VMs)"
            Write-Host "  ⚠ Total Available Space: $totalFree GB (Consider additional storage for VMs)" -ForegroundColor Yellow
        }
        
    }
    catch {
        $results.Status = $false
        $results.Issues += "Error during storage validation: $($_.Exception.Message)"
        Write-Log -Message "Storage validation error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

function Test-CurrentRoles {
    <#
    .SYNOPSIS
        Validates current server roles and identifies conflicts
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nValidating Current Server Roles..." -ForegroundColor Yellow
    $results = @{
        Status = $true
        Details = @()
        Issues = @()
    }
    
    try {
        # Get installed roles and features
        $installedFeatures = Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" }
        
        # Roles that may conflict with Hyper-V
        $conflictingRoles = @(
            "DHCP",
            "DNS",
            "AD-Domain-Services",
            "ADCS-Cert-Authority",
            "NPAS",
            "Remote-Desktop-Services"
        )
        
        $conflicts = @()
        $installedRoles = @()
        
        foreach ($feature in $installedFeatures) {
            if ($feature.FeatureType -eq "Role") {
                $installedRoles += $feature.Name
                if ($feature.Name -in $conflictingRoles) {
                    $conflicts += $feature.DisplayName
                }
            }
        }
        
        if ($installedRoles.Count -gt 0) {
            $results.Details += "ℹ Installed Roles: $($installedRoles.Count) found"
            Write-Host "  ℹ Installed Roles: $($installedRoles.Count) found" -ForegroundColor Cyan
        } else {
            $results.Details += "✓ No conflicting roles detected"
            Write-Host "  ✓ No conflicting roles detected" -ForegroundColor Green
        }
        
        if ($conflicts.Count -gt 0) {
            $results.Issues += "⚠ Potentially conflicting roles found: $($conflicts -join ', ')"
            Write-Host "  ⚠ Potentially conflicting roles found: $($conflicts -join ', ')" -ForegroundColor Yellow
            Write-Host "    Consider dedicating this server to Hyper-V for optimal performance" -ForegroundColor Yellow
        }
        
        # Check for Hyper-V specifically
        $hyperVRole = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
        if ($hyperVRole -and $hyperVRole.InstallState -eq "Installed") {
            $results.Details += "ℹ Hyper-V Role: Already installed"
            Write-Host "  ℹ Hyper-V Role: Already installed" -ForegroundColor Cyan
        }
        
    }
    catch {
        $results.Status = $false
        $results.Issues += "Error during role validation: $($_.Exception.Message)"
        Write-Log -Message "Role validation error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $results
}

function Show-ValidationSummary {
    <#
    .SYNOPSIS
        Displays a summary of all validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory = $true)]
        [bool]$OverallStatus
    )
    
    Write-Host "`n===============================================================================" -ForegroundColor Cyan
    Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    
    foreach ($category in $Results.Keys) {
        $result = $Results[$category]
        $status = if ($result.Status) { "PASS" } else { "FAIL" }
        $color = if ($result.Status) { "Green" } else { "Red" }
        
        Write-Host "$category : $status" -ForegroundColor $color
        
        if ($result.Issues.Count -gt 0) {
            foreach ($issue in $result.Issues) {
                Write-Host "  $issue" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nOverall Status: " -NoNewline
    if ($OverallStatus) {
        Write-Host "READY FOR HYPER-V DEPLOYMENT" -ForegroundColor Green
    } else {
        Write-Host "ISSUES MUST BE RESOLVED BEFORE DEPLOYMENT" -ForegroundColor Red
    }
    
    Write-Host "===============================================================================" -ForegroundColor Cyan
}
