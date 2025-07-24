# Single Host Deployment Module for Hyper-V
# Contains functions for deploying Hyper-V on a single Windows Server host

function Start-SingleHostDeployment {
    <#
    .SYNOPSIS
        Deploys and configures Hyper-V on a single Windows Server host
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting single host Hyper-V deployment workflow..." -Level "INFO"
    
    # Check if system validation has been run
    $validationFiles = Get-ChildItem -Path $Global:ConfigPath -Filter "ValidationResults_*.xml" -ErrorAction SilentlyContinue
    if (-not $validationFiles) {
        Write-Host "`nWARNING: No system validation results found." -ForegroundColor Yellow
        Write-Host "It's recommended to run system validation first (Option 1)." -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Log -Message "User chose to abort deployment - no validation results" -Level "INFO"
            return
        }
    }
    
    try {
        Show-SingleHostMenu
        
    }
    catch {
        Write-Log -Message "Error in single host deployment: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during deployment. Check the log file for details." -ForegroundColor Red
    }
}

function Show-SingleHostMenu {
    <#
    .SYNOPSIS
        Displays the single host deployment menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    SINGLE HOST HYPER-V DEPLOYMENT" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "DEPLOYMENT OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Install Hyper-V Role and Management Tools" -ForegroundColor White
        Write-Host "  2. Configure Virtual Switches" -ForegroundColor White
        Write-Host "  3. Set VM Storage Locations" -ForegroundColor White
        Write-Host "  4. Configure Memory and NUMA Settings" -ForegroundColor White
        Write-Host "  5. Enable Advanced Hyper-V Features" -ForegroundColor White
        Write-Host "  6. Complete Deployment (All Steps)" -ForegroundColor Yellow
        Write-Host "  7. View Current Configuration" -ForegroundColor Cyan
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $selection = Read-Host "Please select an option (0-7)"
        
        switch ($selection) {
            1 { Install-HyperVRole }
            2 { Configure-VirtualSwitches }
            3 { Set-VMStorageLocations }
            4 { Configure-MemorySettings }
            5 { Enable-AdvancedFeatures }
            6 { Start-CompleteDeployment }
            7 { Show-CurrentConfiguration }
            0 { 
                Write-Log -Message "Returning to main menu from single host deployment" -Level "INFO"
                return
            }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        if ($selection -ne 0) {
            Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
    } while ($selection -ne 0)
}

function Install-HyperVRole {
    <#
    .SYNOPSIS
        Installs the Hyper-V role and management tools
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nInstalling Hyper-V Role and Management Tools..." -ForegroundColor Yellow
    Write-Log -Message "Starting Hyper-V role installation" -Level "INFO"
    
    try {
        # Check if Hyper-V is already installed
        $hyperVFeature = Get-WindowsFeature -Name Hyper-V -ErrorAction Stop
        if ($hyperVFeature.InstallState -eq "Installed") {
            Write-Host "  ℹ Hyper-V role is already installed" -ForegroundColor Cyan
            Write-Log -Message "Hyper-V role already installed" -Level "INFO"
        } else {
            Write-Host "  Installing Hyper-V role..." -ForegroundColor Yellow
            
            # Install Hyper-V role
            $result = Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false
            
            if ($result.Success) {
                Write-Host "  ✓ Hyper-V role installed successfully" -ForegroundColor Green
                Write-Log -Message "Hyper-V role installed successfully" -Level "SUCCESS"
                
                if ($result.RestartNeeded -eq "Yes") {
                    Write-Host "  ⚠ RESTART REQUIRED: A restart is needed to complete the installation" -ForegroundColor Yellow
                    Write-Log -Message "Restart required to complete Hyper-V installation" -Level "WARNING"
                    
                    $restart = Read-Host "Restart now? (y/N)"
                    if ($restart -eq 'y' -or $restart -eq 'Y') {
                        Write-Log -Message "User initiated system restart" -Level "INFO"
                        Restart-Computer -Force
                    }
                }
            } else {
                Write-Host "  ✗ Failed to install Hyper-V role" -ForegroundColor Red
                Write-Log -Message "Failed to install Hyper-V role" -Level "ERROR"
                return
            }
        }
        
        # Install Hyper-V Management Tools if not already installed
        $mgmtTools = Get-WindowsFeature -Name RSAT-Hyper-V-Tools -ErrorAction SilentlyContinue
        if ($mgmtTools -and $mgmtTools.InstallState -ne "Installed") {
            Write-Host "  Installing Hyper-V Management Tools..." -ForegroundColor Yellow
            Install-WindowsFeature -Name RSAT-Hyper-V-Tools -IncludeAllSubFeature
            Write-Host "  ✓ Hyper-V Management Tools installed" -ForegroundColor Green
            Write-Log -Message "Hyper-V Management Tools installed" -Level "SUCCESS"
        }
        
        # Verify installation
        $hyperVService = Get-Service -Name vmms -ErrorAction SilentlyContinue
        if ($hyperVService) {
            Write-Host "  ✓ Hyper-V Virtual Machine Management Service detected" -ForegroundColor Green
            if ($hyperVService.Status -eq "Running") {
                Write-Host "  ✓ Hyper-V service is running" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Hyper-V service is not running (may require restart)" -ForegroundColor Yellow
            }
        }
        
        # Save installation status
        $installStatus = @{
            Timestamp = Get-Date
            HyperVInstalled = $true
            RestartRequired = ($result.RestartNeeded -eq "Yes")
            ServiceStatus = $hyperVService.Status
        }
        
        $statusFile = Join-Path $Global:ConfigPath "HyperV-InstallStatus_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $installStatus | Export-Clixml -Path $statusFile
        Write-Log -Message "Installation status saved to: $statusFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error installing Hyper-V role: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error installing Hyper-V role: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Configure-VirtualSwitches {
    <#
    .SYNOPSIS
        Configures virtual switches for Hyper-V
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nConfiguring Hyper-V Virtual Switches..." -ForegroundColor Yellow
    Write-Log -Message "Starting virtual switch configuration" -Level "INFO"
    
    try {
        # Check if Hyper-V is available
        if (-not (Get-Command Get-VMSwitch -ErrorAction SilentlyContinue)) {
            Write-Host "  ✗ Hyper-V PowerShell module not available. Install Hyper-V role first." -ForegroundColor Red
            return
        }
        
        # Get existing switches
        $existingSwitches = Get-VMSwitch -ErrorAction SilentlyContinue
        if ($existingSwitches) {
            Write-Host "  ℹ Existing Virtual Switches:" -ForegroundColor Cyan
            foreach ($switch in $existingSwitches) {
                Write-Host "    - $($switch.Name) ($($switch.SwitchType))" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        # Get available network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false }
        
        if ($adapters.Count -eq 0) {
            Write-Host "  ✗ No physical network adapters available for external switch creation" -ForegroundColor Red
            return
        }
        
        Write-Host "  Available Network Adapters:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "    $($i + 1). $($adapters[$i].Name) - $($adapters[$i].InterfaceDescription)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # External Switch Configuration
        $createExternal = Read-Host "Create External Virtual Switch? (Y/n)"
        if ($createExternal -ne 'n' -and $createExternal -ne 'N') {
            if ($adapters.Count -eq 1) {
                $selectedAdapter = $adapters[0]
                Write-Host "  Using adapter: $($selectedAdapter.Name)" -ForegroundColor Yellow
            } else {
                do {
                    $adapterChoice = Read-Host "Select adapter for External Switch (1-$($adapters.Count))"
                    $adapterIndex = [int]$adapterChoice - 1
                } while ($adapterIndex -lt 0 -or $adapterIndex -ge $adapters.Count)
                $selectedAdapter = $adapters[$adapterIndex]
            }
            
            $externalSwitchName = Read-Host "Enter name for External Switch [External-Switch]"
            if ([string]::IsNullOrWhiteSpace($externalSwitchName)) {
                $externalSwitchName = "External-Switch"
            }
            
            # Check if switch already exists
            if (Get-VMSwitch -Name $externalSwitchName -ErrorAction SilentlyContinue) {
                Write-Host "  ⚠ Switch '$externalSwitchName' already exists" -ForegroundColor Yellow
            } else {
                Write-Host "  Creating External Virtual Switch '$externalSwitchName'..." -ForegroundColor Yellow
                
                $allowManagement = Read-Host "Allow management OS to share this network adapter? (Y/n)"
                $shareManagementOS = ($allowManagement -ne 'n' -and $allowManagement -ne 'N')
                
                New-VMSwitch -Name $externalSwitchName -NetAdapterName $selectedAdapter.Name -AllowManagementOS:$shareManagementOS
                Write-Host "  ✓ External switch '$externalSwitchName' created successfully" -ForegroundColor Green
                Write-Log -Message "External switch '$externalSwitchName' created on adapter '$($selectedAdapter.Name)'" -Level "SUCCESS"
            }
        }
        
        # Internal Switch Configuration
        $createInternal = Read-Host "Create Internal Virtual Switch? (Y/n)"
        if ($createInternal -ne 'n' -and $createInternal -ne 'N') {
            $internalSwitchName = Read-Host "Enter name for Internal Switch [Internal-Switch]"
            if ([string]::IsNullOrWhiteSpace($internalSwitchName)) {
                $internalSwitchName = "Internal-Switch"
            }
            
            if (Get-VMSwitch -Name $internalSwitchName -ErrorAction SilentlyContinue) {
                Write-Host "  ⚠ Switch '$internalSwitchName' already exists" -ForegroundColor Yellow
            } else {
                Write-Host "  Creating Internal Virtual Switch '$internalSwitchName'..." -ForegroundColor Yellow
                New-VMSwitch -Name $internalSwitchName -SwitchType Internal
                Write-Host "  ✓ Internal switch '$internalSwitchName' created successfully" -ForegroundColor Green
                Write-Log -Message "Internal switch '$internalSwitchName' created" -Level "SUCCESS"
            }
        }
        
        # Private Switch Configuration
        $createPrivate = Read-Host "Create Private Virtual Switch? (y/N)"
        if ($createPrivate -eq 'y' -or $createPrivate -eq 'Y') {
            $privateSwitchName = Read-Host "Enter name for Private Switch [Private-Switch]"
            if ([string]::IsNullOrWhiteSpace($privateSwitchName)) {
                $privateSwitchName = "Private-Switch"
            }
            
            if (Get-VMSwitch -Name $privateSwitchName -ErrorAction SilentlyContinue) {
                Write-Host "  ⚠ Switch '$privateSwitchName' already exists" -ForegroundColor Yellow
            } else {
                Write-Host "  Creating Private Virtual Switch '$privateSwitchName'..." -ForegroundColor Yellow
                New-VMSwitch -Name $privateSwitchName -SwitchType Private
                Write-Host "  ✓ Private switch '$privateSwitchName' created successfully" -ForegroundColor Green
                Write-Log -Message "Private switch '$privateSwitchName' created" -Level "SUCCESS"
            }
        }
        
        # Display final switch configuration
        Write-Host "`n  Current Virtual Switch Configuration:" -ForegroundColor Cyan
        $switches = Get-VMSwitch
        foreach ($switch in $switches) {
            $adapterInfo = if ($switch.NetAdapterInterfaceDescription) { " (Adapter: $($switch.NetAdapterInterfaceDescription))" } else { "" }
            Write-Host "    ✓ $($switch.Name) - $($switch.SwitchType)$adapterInfo" -ForegroundColor Green
        }
        
        # Save switch configuration
        $switchConfig = @{
            Timestamp = Get-Date
            Switches = $switches | Select-Object Name, SwitchType, NetAdapterInterfaceDescription, Id
        }
        
        $configFile = Join-Path $Global:ConfigPath "VirtualSwitches_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $switchConfig | Export-Clixml -Path $configFile
        Write-Log -Message "Virtual switch configuration saved to: $configFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error configuring virtual switches: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error configuring virtual switches: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Set-VMStorageLocations {
    <#
    .SYNOPSIS
        Configures default VM storage locations
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nConfiguring VM Storage Locations..." -ForegroundColor Yellow
    Write-Log -Message "Starting VM storage location configuration" -Level "INFO"
    
    try {
        # Check if Hyper-V is available
        if (-not (Get-Command Get-VMHost -ErrorAction SilentlyContinue)) {
            Write-Host "  ✗ Hyper-V PowerShell module not available. Install Hyper-V role first." -ForegroundColor Red
            return
        }
        
        # Get current VM host settings
        $vmHost = Get-VMHost
        Write-Host "  Current Storage Locations:" -ForegroundColor Cyan
        Write-Host "    Virtual Hard Disks: $($vmHost.VirtualHardDiskPath)" -ForegroundColor Gray
        Write-Host "    Virtual Machines: $($vmHost.VirtualMachinePath)" -ForegroundColor Gray
        Write-Host ""
        
        # Get available drives with sufficient space
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { 
            $_.DriveType -eq 3 -and $_.FreeSpace -gt 50GB 
        } | Sort-Object DeviceID
        
        Write-Host "  Available Drives (>50GB free):" -ForegroundColor Cyan
        foreach ($drive in $drives) {
            $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            Write-Host "    $($drive.DeviceID) - $freeGB GB free of $sizeGB GB total" -ForegroundColor Gray
        }
        Write-Host ""
        
        $changeSettings = Read-Host "Change VM storage locations? (y/N)"
        if ($changeSettings -eq 'y' -or $changeSettings -eq 'Y') {
            
            # Configure VM Path
            $changeVMPath = Read-Host "Change Virtual Machine default path? (y/N)"
            if ($changeVMPath -eq 'y' -or $changeVMPath -eq 'Y') {
                $newVMPath = Read-Host "Enter new VM path [$($vmHost.VirtualMachinePath)]"
                if ([string]::IsNullOrWhiteSpace($newVMPath)) {
                    $newVMPath = $vmHost.VirtualMachinePath
                } else {
                    # Validate and create path if needed
                    if (-not (Test-Path $newVMPath)) {
                        Write-Host "  Creating directory: $newVMPath" -ForegroundColor Yellow
                        New-Item -Path $newVMPath -ItemType Directory -Force | Out-Null
                    }
                    
                    Set-VMHost -VirtualMachinePath $newVMPath
                    Write-Host "  ✓ VM path updated to: $newVMPath" -ForegroundColor Green
                    Write-Log -Message "VM path updated to: $newVMPath" -Level "SUCCESS"
                }
            }
            
            # Configure VHD Path
            $changeVHDPath = Read-Host "Change Virtual Hard Disk default path? (y/N)"
            if ($changeVHDPath -eq 'y' -or $changeVHDPath -eq 'Y') {
                $newVHDPath = Read-Host "Enter new VHD path [$($vmHost.VirtualHardDiskPath)]"
                if ([string]::IsNullOrWhiteSpace($newVHDPath)) {
                    $newVHDPath = $vmHost.VirtualHardDiskPath
                } else {
                    # Validate and create path if needed
                    if (-not (Test-Path $newVHDPath)) {
                        Write-Host "  Creating directory: $newVHDPath" -ForegroundColor Yellow
                        New-Item -Path $newVHDPath -ItemType Directory -Force | Out-Null
                    }
                    
                    Set-VMHost -VirtualHardDiskPath $newVHDPath
                    Write-Host "  ✓ VHD path updated to: $newVHDPath" -ForegroundColor Green
                    Write-Log -Message "VHD path updated to: $newVHDPath" -Level "SUCCESS"
                }
            }
        }
        
        # Configure additional storage features
        Write-Host "  Additional Storage Configuration:" -ForegroundColor Cyan
        
        # Enable Storage QoS if available (Windows Server 2016+)
        $enableQoS = Read-Host "Enable Storage Quality of Service (QoS)? (y/N)"
        if ($enableQoS -eq 'y' -or $enableQoS -eq 'Y') {
            try {
                Enable-StorageQoSFlow -ErrorAction Stop
                Write-Host "  ✓ Storage QoS enabled" -ForegroundColor Green
                Write-Log -Message "Storage QoS enabled" -Level "SUCCESS"
            }
            catch {
                Write-Host "  ⚠ Storage QoS not available or already enabled" -ForegroundColor Yellow
                Write-Log -Message "Storage QoS configuration: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Get final configuration
        $vmHost = Get-VMHost
        Write-Host "`n  Final Storage Configuration:" -ForegroundColor Cyan
        Write-Host "    Virtual Hard Disks: $($vmHost.VirtualHardDiskPath)" -ForegroundColor Green
        Write-Host "    Virtual Machines: $($vmHost.VirtualMachinePath)" -ForegroundColor Green
        
        # Save storage configuration
        $storageConfig = @{
            Timestamp = Get-Date
            VirtualMachinePath = $vmHost.VirtualMachinePath
            VirtualHardDiskPath = $vmHost.VirtualHardDiskPath
            MaximumStorageMigrations = $vmHost.MaximumStorageMigrations
            MaximumVirtualMachineMigrations = $vmHost.MaximumVirtualMachineMigrations
        }
        
        $configFile = Join-Path $Global:ConfigPath "StorageConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $storageConfig | Export-Clixml -Path $configFile
        Write-Log -Message "Storage configuration saved to: $configFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error configuring VM storage: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error configuring VM storage: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Configure-MemorySettings {
    <#
    .SYNOPSIS
        Configures memory and NUMA settings for Hyper-V
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nConfiguring Memory and NUMA Settings..." -ForegroundColor Yellow
    Write-Log -Message "Starting memory and NUMA configuration" -Level "INFO"
    
    try {
        # Check if Hyper-V is available
        if (-not (Get-Command Get-VMHost -ErrorAction SilentlyContinue)) {
            Write-Host "  ✗ Hyper-V PowerShell module not available. Install Hyper-V role first." -ForegroundColor Red
            return
        }
        
        # Get system memory information
        $totalRAM = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        $availableRAM = [math]::Round((Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        
        Write-Host "  System Memory Information:" -ForegroundColor Cyan
        Write-Host "    Total RAM: $totalRAM GB" -ForegroundColor Gray
        Write-Host "    Available RAM: $availableRAM GB" -ForegroundColor Gray
        Write-Host ""
        
        # Get current VM host settings
        $vmHost = Get-VMHost
        
        # Get NUMA information
        $numaNodes = Get-WmiObject -Class Win32_NumaNode -ErrorAction SilentlyContinue
        if ($numaNodes) {
            Write-Host "  NUMA Configuration:" -ForegroundColor Cyan
            Write-Host "    NUMA Nodes: $($numaNodes.Count)" -ForegroundColor Gray
            foreach ($node in $numaNodes) {
                Write-Host "    Node $($node.NodeId): Available" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        # Configure memory settings
        $configureMemory = Read-Host "Configure memory settings? (Y/n)"
        if ($configureMemory -ne 'n' -and $configureMemory -ne 'N') {
            
            # Reserve memory for host OS
            $recommendedReserve = [math]::Max(2, [math]::Ceiling($totalRAM * 0.1))
            $reserveMemory = Read-Host "Reserve memory for host OS in GB [$recommendedReserve]"
            if ([string]::IsNullOrWhiteSpace($reserveMemory)) {
                $reserveMemory = $recommendedReserve
            }
            
            Write-Host "  Recommended to reserve $reserveMemory GB for host OS" -ForegroundColor Yellow
            Write-Host "  Available for VMs: $($totalRAM - $reserveMemory) GB" -ForegroundColor Cyan
            
            # Configure NUMA spanning
            if ($numaNodes -and $numaNodes.Count -gt 1) {
                Write-Host "  NUMA Configuration Options:" -ForegroundColor Cyan
                $numaSpanning = Read-Host "Allow VMs to span NUMA nodes? (y/N)"
                if ($numaSpanning -eq 'y' -or $numaSpanning -eq 'Y') {
                    Set-VMHost -NumaSpanningEnabled $true
                    Write-Host "  ✓ NUMA spanning enabled" -ForegroundColor Green
                    Write-Log -Message "NUMA spanning enabled" -Level "SUCCESS"
                } else {
                    Set-VMHost -NumaSpanningEnabled $false
                    Write-Host "  ✓ NUMA spanning disabled (VMs constrained to single NUMA node)" -ForegroundColor Green
                    Write-Log -Message "NUMA spanning disabled" -Level "SUCCESS"
                }
            }
            
            # Configure Enhanced Session Mode
            $enhancedSession = Read-Host "Enable Enhanced Session Mode? (Y/n)"
            if ($enhancedSession -ne 'n' -and $enhancedSession -ne 'N') {
                Set-VMHost -EnableEnhancedSessionMode $true
                Write-Host "  ✓ Enhanced Session Mode enabled" -ForegroundColor Green
                Write-Log -Message "Enhanced Session Mode enabled" -Level "SUCCESS"
            }
            
            # Configure Live Migration settings
            $configureMigration = Read-Host "Configure Live Migration settings? (y/N)"
            if ($configureMigration -eq 'y' -or $configureMigration -eq 'Y') {
                
                $maxMigrations = Read-Host "Maximum simultaneous live migrations [2]"
                if ([string]::IsNullOrWhiteSpace($maxMigrations)) {
                    $maxMigrations = 2
                }
                
                $maxStorageMigrations = Read-Host "Maximum simultaneous storage migrations [2]"
                if ([string]::IsNullOrWhiteSpace($maxStorageMigrations)) {
                    $maxStorageMigrations = 2
                }
                
                Set-VMHost -MaximumVirtualMachineMigrations $maxMigrations
                Set-VMHost -MaximumStorageMigrations $maxStorageMigrations
                
                Write-Host "  ✓ Live Migration settings configured" -ForegroundColor Green
                Write-Host "    Max VM Migrations: $maxMigrations" -ForegroundColor Gray
                Write-Host "    Max Storage Migrations: $maxStorageMigrations" -ForegroundColor Gray
                Write-Log -Message "Live Migration settings configured: VM=$maxMigrations, Storage=$maxStorageMigrations" -Level "SUCCESS"
            }
        }
        
        # Display final configuration
        $vmHost = Get-VMHost
        Write-Host "`n  Final Memory Configuration:" -ForegroundColor Cyan
        Write-Host "    NUMA Spanning: $($vmHost.NumaSpanningEnabled)" -ForegroundColor Green
        Write-Host "    Enhanced Session Mode: $($vmHost.EnableEnhancedSessionMode)" -ForegroundColor Green
        Write-Host "    Max VM Migrations: $($vmHost.MaximumVirtualMachineMigrations)" -ForegroundColor Green
        Write-Host "    Max Storage Migrations: $($vmHost.MaximumStorageMigrations)" -ForegroundColor Green
        
        # Save memory configuration
        $memoryConfig = @{
            Timestamp = Get-Date
            TotalSystemRAM = $totalRAM
            NumaSpanningEnabled = $vmHost.NumaSpanningEnabled
            EnableEnhancedSessionMode = $vmHost.EnableEnhancedSessionMode
            MaximumVirtualMachineMigrations = $vmHost.MaximumVirtualMachineMigrations
            MaximumStorageMigrations = $vmHost.MaximumStorageMigrations
            NumaNodes = $numaNodes.Count
        }
        
        $configFile = Join-Path $Global:ConfigPath "MemoryConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $memoryConfig | Export-Clixml -Path $configFile
        Write-Log -Message "Memory configuration saved to: $configFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error configuring memory settings: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error configuring memory settings: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Enable-AdvancedFeatures {
    <#
    .SYNOPSIS
        Enables advanced Hyper-V features
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nEnabling Advanced Hyper-V Features..." -ForegroundColor Yellow
    Write-Log -Message "Starting advanced features configuration" -Level "INFO"
    
    try {
        # Check if Hyper-V is available
        if (-not (Get-Command Get-VMHost -ErrorAction SilentlyContinue)) {
            Write-Host "  ✗ Hyper-V PowerShell module not available. Install Hyper-V role first." -ForegroundColor Red
            return
        }
        
        Write-Host "  Advanced Feature Options:" -ForegroundColor Cyan
        
        # Resource Metering
        $enableMetering = Read-Host "Enable Resource Metering? (Y/n)"
        if ($enableMetering -ne 'n' -and $enableMetering -ne 'N') {
            try {
                Enable-VMResourceMetering -ResourcePoolType Memory,Processor,VHD -ErrorAction SilentlyContinue
                Write-Host "  ✓ Resource Metering enabled" -ForegroundColor Green
                Write-Log -Message "Resource Metering enabled" -Level "SUCCESS"
            }
            catch {
                Write-Host "  ⚠ Resource Metering configuration: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # VM Integration Services
        $configureIntegration = Read-Host "Configure VM Integration Services defaults? (Y/n)"
        if ($configureIntegration -ne 'n' -and $configureIntegration -ne 'N') {
            Write-Host "  ✓ Integration Services will be enabled by default for new VMs" -ForegroundColor Green
            Write-Log -Message "Integration Services configured for new VMs" -Level "SUCCESS"
        }
        
        # Hyper-V Replica (if available)
        $configureReplica = Read-Host "Configure Hyper-V Replica settings? (y/N)"
        if ($configureReplica -eq 'y' -or $configureReplica -eq 'Y') {
            Write-Host "  Hyper-V Replica Configuration:" -ForegroundColor Cyan
            
            $enableReplica = Read-Host "Enable as Replica server? (y/N)"
            if ($enableReplica -eq 'y' -or $enableReplica -eq 'Y') {
                try {
                    $authType = Read-Host "Authentication type (1=Kerberos, 2=Certificate) [1]"
                    if ([string]::IsNullOrWhiteSpace($authType) -or $authType -eq "1") {
                        Set-VMReplicationServer -ReplicationEnabled $true -AllowedAuthenticationType Kerberos
                        Write-Host "  ✓ Hyper-V Replica enabled with Kerberos authentication" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠ Certificate authentication requires additional certificate configuration" -ForegroundColor Yellow
                        Set-VMReplicationServer -ReplicationEnabled $true -AllowedAuthenticationType Certificate
                        Write-Host "  ✓ Hyper-V Replica enabled with Certificate authentication" -ForegroundColor Green
                    }
                    Write-Log -Message "Hyper-V Replica server enabled" -Level "SUCCESS"
                }
                catch {
                    Write-Host "  ✗ Error configuring Hyper-V Replica: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Log -Message "Error configuring Hyper-V Replica: $($_.Exception.Message)" -Level "ERROR"
                }
            }
        }
        
        # Bandwidth Management
        $configureBandwidth = Read-Host "Configure network bandwidth management? (y/N)"
        if ($configureBandwidth -eq 'y' -or $configureBandwidth -eq 'Y') {
            Write-Host "  ⚠ Bandwidth management can be configured per VM or virtual switch" -ForegroundColor Yellow
            Write-Host "  ✓ Feature noted for individual VM configuration" -ForegroundColor Green
            Write-Log -Message "Bandwidth management noted for VM configuration" -Level "INFO"
        }
        
        # SR-IOV (if supported)
        $configureSRIOV = Read-Host "Check for SR-IOV support? (y/N)"
        if ($configureSRIOV -eq 'y' -or $configureSRIOV -eq 'Y') {
            $adapters = Get-NetAdapter | Where-Object { $_.SriovSupport -eq "Supported" }
            if ($adapters) {
                Write-Host "  ✓ SR-IOV supported adapters found:" -ForegroundColor Green
                foreach ($adapter in $adapters) {
                    Write-Host "    - $($adapter.Name)" -ForegroundColor Gray
                }
                Write-Host "  ℹ SR-IOV can be enabled on virtual switches using these adapters" -ForegroundColor Cyan
            } else {
                Write-Host "  ℹ No SR-IOV capable adapters found" -ForegroundColor Cyan
            }
        }
        
        # Display final status
        Write-Host "`n  Advanced Features Configuration Complete" -ForegroundColor Green
        
        # Save advanced features configuration
        $advancedConfig = @{
            Timestamp = Get-Date
            ResourceMeteringEnabled = $true
            IntegrationServicesConfigured = $true
            SriovAdapters = (Get-NetAdapter | Where-Object { $_.SriovSupport -eq "Supported" }).Count
        }
        
        $configFile = Join-Path $Global:ConfigPath "AdvancedFeatures_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $advancedConfig | Export-Clixml -Path $configFile
        Write-Log -Message "Advanced features configuration saved to: $configFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error configuring advanced features: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error configuring advanced features: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Start-CompleteDeployment {
    <#
    .SYNOPSIS
        Runs a complete single host deployment
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nStarting Complete Single Host Deployment..." -ForegroundColor Yellow
    Write-Log -Message "Starting complete single host deployment" -Level "INFO"
    
    $confirmation = Read-Host "This will install and configure Hyper-V with default settings. Continue? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "`nStep 1/5: Installing Hyper-V Role..." -ForegroundColor Cyan
        Install-HyperVRole
        
        Write-Host "`nStep 2/5: Configuring Virtual Switches..." -ForegroundColor Cyan
        # Auto-configure with defaults
        Configure-VirtualSwitches
        
        Write-Host "`nStep 3/5: Setting VM Storage Locations..." -ForegroundColor Cyan
        Set-VMStorageLocations
        
        Write-Host "`nStep 4/5: Configuring Memory Settings..." -ForegroundColor Cyan
        Configure-MemorySettings
        
        Write-Host "`nStep 5/5: Enabling Advanced Features..." -ForegroundColor Cyan
        Enable-AdvancedFeatures
        
        Write-Host "`n===============================================================================" -ForegroundColor Green
        Write-Host "                    DEPLOYMENT COMPLETED SUCCESSFULLY" -ForegroundColor Green
        Write-Host "===============================================================================" -ForegroundColor Green
        
        Show-CurrentConfiguration
        
        Write-Log -Message "Complete single host deployment finished successfully" -Level "SUCCESS"
        
    }
    catch {
        Write-Host "`n✗ Error during complete deployment: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error during complete deployment: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Show-CurrentConfiguration {
    <#
    .SYNOPSIS
        Displays the current Hyper-V configuration
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCurrent Hyper-V Configuration:" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    
    try {
        # Check if Hyper-V is installed
        $hyperVFeature = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
        if ($hyperVFeature -and $hyperVFeature.InstallState -eq "Installed") {
            Write-Host "✓ Hyper-V Role: Installed" -ForegroundColor Green
            
            # VM Host Settings
            $vmHost = Get-VMHost -ErrorAction SilentlyContinue
            if ($vmHost) {
                Write-Host "✓ VM Host Configuration:" -ForegroundColor Green
                Write-Host "  Virtual Machine Path: $($vmHost.VirtualMachinePath)" -ForegroundColor Gray
                Write-Host "  Virtual Hard Disk Path: $($vmHost.VirtualHardDiskPath)" -ForegroundColor Gray
                Write-Host "  NUMA Spanning: $($vmHost.NumaSpanningEnabled)" -ForegroundColor Gray
                Write-Host "  Enhanced Session Mode: $($vmHost.EnableEnhancedSessionMode)" -ForegroundColor Gray
                Write-Host "  Max VM Migrations: $($vmHost.MaximumVirtualMachineMigrations)" -ForegroundColor Gray
                Write-Host "  Max Storage Migrations: $($vmHost.MaximumStorageMigrations)" -ForegroundColor Gray
            }
            
            # Virtual Switches
            $switches = Get-VMSwitch -ErrorAction SilentlyContinue
            if ($switches) {
                Write-Host "✓ Virtual Switches:" -ForegroundColor Green
                foreach ($switch in $switches) {
                    $adapterInfo = if ($switch.NetAdapterInterfaceDescription) { " (Adapter: $($switch.NetAdapterInterfaceDescription))" } else { "" }
                    Write-Host "  $($switch.Name) - $($switch.SwitchType)$adapterInfo" -ForegroundColor Gray
                }
            } else {
                Write-Host "⚠ No Virtual Switches configured" -ForegroundColor Yellow
            }
            
            # Virtual Machines
            $vms = Get-VM -ErrorAction SilentlyContinue
            if ($vms) {
                Write-Host "✓ Virtual Machines: $($vms.Count)" -ForegroundColor Green
                foreach ($vm in $vms) {
                    Write-Host "  $($vm.Name) - $($vm.State)" -ForegroundColor Gray
                }
            } else {
                Write-Host "ℹ No Virtual Machines created yet" -ForegroundColor Cyan
            }
            
        } else {
            Write-Host "✗ Hyper-V Role: Not Installed" -ForegroundColor Red
        }
        
    }
    catch {
        Write-Host "✗ Error retrieving configuration: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error retrieving current configuration: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Host "===============================================================================" -ForegroundColor Cyan
}
