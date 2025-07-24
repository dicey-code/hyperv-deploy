# Hyper-V Inventory and Reporting Module - RVTools-like functionality
# Comprehensive inventory collection and analysis for Hyper-V environments

# Define the base directory for the project dynamically
$Global:BaseDirectory = (Get-Item -Path "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\..\").FullName
$Global:ReportPath = Join-Path -Path $Global:BaseDirectory -ChildPath "Reports"

# Ensure the Reports folder exists
if (-not (Test-Path -Path $Global:ReportPath)) {
    New-Item -Path $Global:ReportPath -ItemType Directory -Force | Out-Null
}

function Start-HyperVInventory {
    <#
    .SYNOPSIS
        Main entry point for Hyper-V Inventory and Reporting
    .DESCRIPTION
        Provides comprehensive inventory collection and reporting capabilities
        for Hyper-V environments with Excel and HTML export options similar to RVTools
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting Hyper-V Inventory and Reporting workflow..." -Level "INFO"
    
    try {
        Show-HyperVInventoryMenu
    }
    catch {
        Write-Log -Message "Error in Hyper-V Inventory workflow: $_" -Level "ERROR"
        Write-Host "Error in inventory workflow: $_" -ForegroundColor Red
    }
}

function Show-HyperVInventoryMenu {
    <#
    .SYNOPSIS
        Display the Hyper-V Inventory menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    HYPER-V INVENTORY AND REPORTING TOOL" -ForegroundColor Cyan
        Write-Host "                        (RVTools-like for Hyper-V)" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "INVENTORY COLLECTION OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Quick Environment Scan" -ForegroundColor White
        Write-Host "  2. Complete Inventory Collection" -ForegroundColor White
        Write-Host "  3. Host Details Report" -ForegroundColor White
        Write-Host "  4. VM Comprehensive Analysis" -ForegroundColor White
        Write-Host "  5. Storage and VHD Analysis" -ForegroundColor White
        Write-Host "  6. Network Configuration Report" -ForegroundColor White
        Write-Host "  7. Performance Metrics Collection" -ForegroundColor White
        Write-Host " 8. Security and Compliance Audit" -ForegroundColor White
        Write-Host ""
        Write-Host "EXPORT AND REPORTING:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  9. Export to Excel (RVTools Format)" -ForegroundColor White
        Write-Host " 10. Export to CSV Files" -ForegroundColor White
        Write-Host " 11. Generate HTML Report" -ForegroundColor White
        Write-Host " 12. Create Executive Summary" -ForegroundColor White
        Write-Host ""
        Write-Host "ANALYSIS TOOLS:" -ForegroundColor Magenta
        Write-Host ""
        Write-Host " 13. Compare Previous Inventories" -ForegroundColor White
        Write-Host " 14. Capacity Planning Report" -ForegroundColor White
        Write-Host " 15. Environment Health Check" -ForegroundColor White
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-15)"
        
        switch ($choice) {
            1 { Invoke-QuickEnvironmentScan }
            2 { Invoke-CompleteInventoryCollection }
            3 { Invoke-HostDetailsReport }
            4 { Invoke-VMComprehensiveAnalysis }
            5 { Invoke-StorageVHDAnalysis }
            6 { Invoke-NetworkConfigurationReport }
            7 { Invoke-PerformanceMetricsCollection }
            8 { Invoke-SecurityComplianceAudit }
            9 { Export-ToRVToolsExcel }
            10 { Export-ToCSVFiles }
            11 { New-HTMLReport }
            12 { New-ExecutiveSummary }
            13 { Compare-PreviousInventories }
            14 { New-CapacityPlanningReport }
            15 { Invoke-EnvironmentHealthCheck }
            0 { return }
            default {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($choice -ne 0)
}

function Invoke-CompleteInventoryCollection {
    <#
    .SYNOPSIS
        Performs comprehensive inventory collection similar to RVTools
    #>
    Write-Host "Starting Complete Inventory Collection..." -ForegroundColor Cyan
    Write-Log -Message "Starting complete inventory collection" -Level "INFO"
    
    try {
        $inventory = @{}
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        Write-Host "`nCollecting comprehensive inventory data..." -ForegroundColor Yellow
        Write-Host "This may take several minutes depending on environment size." -ForegroundColor Yellow
        
        # Collect all data
        Write-Host "`n[1/7] Collecting Host Information..." -ForegroundColor Cyan
        $inventory.Hosts = Get-HyperVHostDetails
        
        Write-Host "[2/7] Collecting Virtual Machine Details..." -ForegroundColor Cyan
        $inventory.VMs = Get-HyperVVMDetails
        
        Write-Host "[3/7] Collecting Virtual Switch Information..." -ForegroundColor Cyan
        $inventory.VirtualSwitches = Get-HyperVVirtualSwitchDetails
        
        Write-Host "[4/7] Collecting Storage and VHD Details..." -ForegroundColor Cyan
        $inventory.Storage = Get-HyperVStorageDetails
        
        Write-Host "[5/7] Collecting Network Adapter Information..." -ForegroundColor Cyan
        $inventory.Networks = Get-HyperVNetworkDetails
        
        Write-Host "[6/7] Collecting Performance Metrics..." -ForegroundColor Cyan
        $inventory.Performance = Get-HyperVPerformanceDetails
        
        Write-Host "[7/7] Collecting Security Configuration..." -ForegroundColor Cyan
        $inventory.Security = Get-HyperVSecurityDetails
        
        # Save inventory data
        $inventoryFile = Join-Path $Global:ReportPath "CompleteInventory_$timestamp.json"
        $inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $inventoryFile -Encoding UTF8
        
        # Display summary
        Show-InventorySummary -Inventory $inventory
        
        Write-Host "`nComplete inventory collection finished!" -ForegroundColor Green
        Write-Host "Data saved to: $inventoryFile" -ForegroundColor Cyan
        Write-Log -Message "Complete inventory collection completed: $inventoryFile" -Level "SUCCESS"
        
        # Offer export options
        $exportChoice = Read-Host "`nWould you like to export this data now? (E)xcel/(H)TML/(N)o"
        switch ($exportChoice.ToUpper()) {
            "E" { Export-ToRVToolsExcel -InventoryData $inventory }
            "H" { New-HTMLReport -InventoryData $inventory }
        }
        
    }
    catch {
        Write-Log -Message "Error during complete inventory collection: $_" -Level "ERROR"
        Write-Host "Error during inventory collection: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Export-ToRVToolsExcel {
    <#
    .SYNOPSIS
        Exports inventory data to Excel format similar to RVTools
    #>
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$InventoryData
    )
    
    Write-Host "Exporting to RVTools-style Excel format..." -ForegroundColor Cyan
    Write-Log -Message "Starting RVTools-style Excel export" -Level "INFO"
    
    try {
        # Check if we have inventory data or need to collect it
        if (-not $InventoryData) {
            Write-Host "No inventory data provided. Using latest collected data..." -ForegroundColor Yellow
            
            # Get latest inventory file
            $inventoryFiles = Get-ChildItem -Path $Global:ReportPath -Filter "CompleteInventory_*.json" | Sort-Object LastWriteTime -Descending
            
            if (-not $inventoryFiles) {
                Write-Host "No inventory data found. Please run inventory collection first." -ForegroundColor Red
                return
            }
            
            $latestFile = $inventoryFiles[0]
            Write-Host "Using inventory data from: $($latestFile.Name)" -ForegroundColor Yellow
            $InventoryData = Get-Content $latestFile.FullName | ConvertFrom-Json -AsHashtable
        }
        
        # Check if ImportExcel module is available
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Host "ImportExcel module not found. Installing..." -ForegroundColor Yellow
            Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
        }
        
        Import-Module ImportExcel -Force
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $excelFile = Join-Path $Global:ReportPath "HyperV_RVTools_Export_$timestamp.xlsx"
        
        Write-Host "`nCreating RVTools-style Excel workbook..." -ForegroundColor Yellow
        
        # Export Hosts (similar to RVTools vHost tab)
        if ($InventoryData.Hosts -and $InventoryData.Hosts.Count -gt 0) {
            Write-Host "  Adding vHost worksheet..." -ForegroundColor Cyan
            $InventoryData.Hosts | Export-Excel -Path $excelFile -WorksheetName "vHost" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export VMs (similar to RVTools vInfo tab)
        if ($InventoryData.VMs -and $InventoryData.VMs.Count -gt 0) {
            Write-Host "  Adding vInfo worksheet..." -ForegroundColor Cyan
            $InventoryData.VMs | Export-Excel -Path $excelFile -WorksheetName "vInfo" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export Virtual Switches (similar to RVTools vNetwork tab)
        if ($InventoryData.VirtualSwitches -and $InventoryData.VirtualSwitches.Count -gt 0) {
            Write-Host "  Adding vNetwork worksheet..." -ForegroundColor Cyan
            $InventoryData.VirtualSwitches | Export-Excel -Path $excelFile -WorksheetName "vNetwork" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export Storage (similar to RVTools vDisk tab)
        if ($InventoryData.Storage -and $InventoryData.Storage.Count -gt 0) {
            Write-Host "  Adding vDisk worksheet..." -ForegroundColor Cyan
            $InventoryData.Storage | Export-Excel -Path $excelFile -WorksheetName "vDisk" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export Network Adapters (similar to RVTools vNIC tab)
        if ($InventoryData.Networks -and $InventoryData.Networks.Count -gt 0) {
            Write-Host "  Adding vNIC worksheet..." -ForegroundColor Cyan
            $InventoryData.Networks | Export-Excel -Path $excelFile -WorksheetName "vNIC" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export Performance data
        if ($InventoryData.Performance -and $InventoryData.Performance.Count -gt 0) {
            Write-Host "  Adding vPerformance worksheet..." -ForegroundColor Cyan
            $InventoryData.Performance | Export-Excel -Path $excelFile -WorksheetName "vPerformance" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Export Security data
        if ($InventoryData.Security -and $InventoryData.Security.Count -gt 0) {
            Write-Host "  Adding vSecurity worksheet..." -ForegroundColor Cyan
            $InventoryData.Security | Export-Excel -Path $excelFile -WorksheetName "vSecurity" -AutoSize -TableStyle Medium2 -FreezeTopRow -BoldTopRow
        }
        
        # Create Summary worksheet
        Write-Host "  Adding Summary worksheet..." -ForegroundColor Cyan
        $summary = New-InventorySummary -InventoryData $InventoryData
        $summary | Export-Excel -Path $excelFile -WorksheetName "Summary" -AutoSize -TableStyle Medium6 -FreezeTopRow -BoldTopRow
        
        Write-Host "`nRVTools-style Excel file created successfully!" -ForegroundColor Green
        Write-Host "Location: $excelFile" -ForegroundColor Cyan
        Write-Host "Worksheets created: vHost, vInfo, vNetwork, vDisk, vNIC, vPerformance, vSecurity, Summary" -ForegroundColor White
        Write-Log -Message "RVTools-style Excel export completed: $excelFile" -Level "SUCCESS"
        
        # Offer to open the file
        $openFile = Read-Host "`nWould you like to open the Excel file? (Y/N)"
        if ($openFile -match "^[Yy]") {
            Start-Process $excelFile
        }
        
    }
    catch {
        Write-Log -Message "Error during RVTools-style Excel export: $_" -Level "ERROR"
        Write-Host "Error during Excel export: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Get-HyperVHostDetails {
    <#
    .SYNOPSIS
        Collects comprehensive Hyper-V host details for RVTools-style reporting
    #>
    try {
        $hosts = @()
        
        # Get cluster nodes if in cluster environment
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting data for host: $hostName" -ForegroundColor Cyan
                
                # Get basic system info
                $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $hostName
                $operatingSystem = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $hostName
                $processor = Get-WmiObject -Class Win32_Processor -ComputerName $hostName | Select-Object -First 1
                $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $hostName
                
                # Get Hyper-V specific info
                $vmHost = Get-VMHost -ComputerName $hostName -ErrorAction SilentlyContinue
                $vmCount = (Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue | Measure-Object).Count
                $runningVMCount = (Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue | Where-Object {$_.State -eq "Running"} | Measure-Object).Count
                
                # Get memory info
                $totalRAM = [Math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
                $availableRAM = [Math]::Round((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $hostName).FreePhysicalMemory / 1MB, 2)
                
                $hostInfo = [PSCustomObject]@{
                    HostName = $hostName
                    Domain = $computerSystem.Domain
                    Manufacturer = $computerSystem.Manufacturer
                    Model = $computerSystem.Model
                    SerialNumber = $bios.SerialNumber
                    BIOSVersion = $bios.SMBIOSBIOSVersion
                    OperatingSystem = $operatingSystem.Caption
                    OSVersion = $operatingSystem.Version
                    OSBuildNumber = $operatingSystem.BuildNumber
                    ServicePack = $operatingSystem.ServicePackMajorVersion
                    InstallDate = $operatingSystem.ConvertToDateTime($operatingSystem.InstallDate)
                    LastBootTime = $operatingSystem.ConvertToDateTime($operatingSystem.LastBootUpTime)
                    ProcessorName = $processor.Name
                    ProcessorCores = $processor.NumberOfCores
                    ProcessorLogicalProcessors = $processor.NumberOfLogicalProcessors
                    ProcessorSpeedMHz = $processor.MaxClockSpeed
                    TotalRAMGB = $totalRAM
                    AvailableRAMGB = $availableRAM
                    HyperVVersion = if ($vmHost) { $vmHost.HyperVVersion } else { "Not Installed" }
                    VirtualMachinePath = if ($vmHost) { $vmHost.VirtualMachinePath } else { "" }
                    VirtualHardDiskPath = if ($vmHost) { $vmHost.VirtualHardDiskPath } else { "" }
                    TotalVMs = $vmCount
                    RunningVMs = $runningVMCount
                    StoppedVMs = $vmCount - $runningVMCount
                    NumaSpanningEnabled = if ($vmHost) { $vmHost.NumaSpanningEnabled } else { $false }
                    MacAddressMinimum = if ($vmHost) { $vmHost.MacAddressMinimum } else { "" }
                    MacAddressMaximum = if ($vmHost) { $vmHost.MacAddressMaximum } else { "" }
                    MaxVMMigrations = if ($vmHost) { $vmHost.MaximumVirtualMachineMigrations } else { 0 }
                    MaxStorageMigrations = if ($vmHost) { $vmHost.MaximumStorageMigrations } else { 0 }
                }
                
                $hosts += $hostInfo
            }
            catch {
                Write-Log -Message "Error collecting data for host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $hosts
    }
    catch {
        Write-Log -Message "Error in Get-HyperVHostDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVVMDetails {
    <#
    .SYNOPSIS
        Collects comprehensive VM details for RVTools-style reporting
    #>
    try {
        $allVMs = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting VM data from host: $hostName" -ForegroundColor Cyan
                
                $vms = Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue
                
                foreach ($vm in $vms) {
                    try {
                        # Get VM details
                        $vmInfo = [PSCustomObject]@{
                            VMName = $vm.Name
                            HostName = $hostName
                            State = $vm.State
                            Generation = $vm.Generation
                            Version = $vm.Version
                            CreationTime = $vm.CreationTime
                            Path = $vm.Path
                            ConfigurationLocation = $vm.ConfigurationLocation
                            MemoryStartupMB = [Math]::Round($vm.MemoryStartup / 1MB, 0)
                            MemoryMinimumMB = [Math]::Round($vm.MemoryMinimum / 1MB, 0)
                            MemoryMaximumMB = [Math]::Round($vm.MemoryMaximum / 1MB, 0)
                            MemoryAssignedMB = [Math]::Round($vm.MemoryAssigned / 1MB, 0)
                            MemoryDemandMB = [Math]::Round($vm.MemoryDemand / 1MB, 0)
                            DynamicMemoryEnabled = $vm.DynamicMemoryEnabled
                            ProcessorCount = $vm.ProcessorCount
                            IntegrationServicesState = $vm.IntegrationServicesState
                            IntegrationServicesVersion = $vm.IntegrationServicesVersion
                            Uptime = $vm.Uptime
                            Status = $vm.Status
                            ReplicationMode = $vm.ReplicationMode
                            ReplicationState = $vm.ReplicationState
                            CPUUsage = $vm.CPUUsage
                            MemoryStatus = $vm.MemoryStatus
                            Heartbeat = $vm.Heartbeat
                            VMId = $vm.VMId
                            ParentCheckpointId = $vm.ParentCheckpointId
                            ParentCheckpointName = $vm.ParentCheckpointName
                        }
                        
                        # Get network adapter count
                        $networkAdapters = Get-VMNetworkAdapter -VM $vm -ErrorAction SilentlyContinue
                        $vmInfo | Add-Member -NotePropertyName "NetworkAdapterCount" -NotePropertyValue ($networkAdapters | Measure-Object).Count
                        
                        # Get hard drive count and total size
                        $hardDrives = Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue
                        $totalDiskGB = 0
                        foreach ($drive in $hardDrives) {
                            try {
                                $vhd = Get-VHD -Path $drive.Path -ErrorAction SilentlyContinue
                                if ($vhd) {
                                    $totalDiskGB += [Math]::Round($vhd.Size / 1GB, 2)
                                }
                            }
                            catch {
                                # VHD file might be inaccessible
                            }
                        }
                        $vmInfo | Add-Member -NotePropertyName "HardDriveCount" -NotePropertyValue ($hardDrives | Measure-Object).Count
                        $vmInfo | Add-Member -NotePropertyName "TotalDiskSizeGB" -NotePropertyValue $totalDiskGB
                        
                        # Get checkpoint count
                        $checkpoints = Get-VMCheckpoint -VM $vm -ErrorAction SilentlyContinue
                        $vmInfo | Add-Member -NotePropertyName "CheckpointCount" -NotePropertyValue ($checkpoints | Measure-Object).Count
                        
                        $allVMs += $vmInfo
                    }
                    catch {
                        Write-Log -Message "Error collecting data for VM $($vm.Name): $_" -Level "WARNING"
                    }
                }
            }
            catch {
                Write-Log -Message "Error collecting VMs from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allVMs
    }
    catch {
        Write-Log -Message "Error in Get-HyperVVMDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVVirtualSwitchDetails {
    <#
    .SYNOPSIS
        Collects comprehensive virtual switch details
    #>
    try {
        $allSwitches = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting virtual switch data from host: $hostName" -ForegroundColor Cyan
                
                $switches = Get-VMSwitch -ComputerName $hostName -ErrorAction SilentlyContinue
                
                foreach ($switch in $switches) {
                    # Get connected VMs
                    $connectedVMs = Get-VMNetworkAdapter -ComputerName $hostName -ErrorAction SilentlyContinue | 
                                   Where-Object { $_.SwitchName -eq $switch.Name } | 
                                   ForEach-Object { $_.VMName }
                    
                    $switchInfo = [PSCustomObject]@{
                        HostName = $hostName
                        SwitchName = $switch.Name
                        SwitchType = $switch.SwitchType
                        SwitchId = $switch.Id
                        NetAdapterInterfaceDescription = $switch.NetAdapterInterfaceDescription
                        AllowManagementOS = $switch.AllowManagementOS
                        DefaultFlowMinimumBandwidthAbsolute = $switch.DefaultFlowMinimumBandwidthAbsolute
                        DefaultFlowMinimumBandwidthWeight = $switch.DefaultFlowMinimumBandwidthWeight
                        Notes = $switch.Notes
                        ConnectedVMs = $connectedVMs -join ", "
                        ConnectedVMCount = ($connectedVMs | Measure-Object).Count
                        BandwidthReservationMode = $switch.BandwidthReservationMode
                        PacketDirectEnabled = $switch.PacketDirectEnabled
                        IovEnabled = $switch.IovEnabled
                    }
                    
                    $allSwitches += $switchInfo
                }
            }
            catch {
                Write-Log -Message "Error collecting virtual switches from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allSwitches
    }
    catch {
        Write-Log -Message "Error in Get-HyperVVirtualSwitchDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVStorageDetails {
    <#
    .SYNOPSIS
        Collects comprehensive storage and VHD details
    #>
    try {
        $allStorage = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting storage data from host: $hostName" -ForegroundColor Cyan
                
                # Get all VMs and their VHD files
                $vms = Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue
                
                foreach ($vm in $vms) {
                    $hardDrives = Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue
                    
                    foreach ($drive in $hardDrives) {
                        try {
                            $vhd = Get-VHD -Path $drive.Path -ErrorAction SilentlyContinue
                            
                            if ($vhd) {
                                $storageInfo = [PSCustomObject]@{
                                    HostName = $hostName
                                    VMName = $vm.Name
                                    VHDPath = $vhd.Path
                                    VHDType = $vhd.VhdType
                                    VHDFormat = $vhd.VhdFormat
                                    SizeGB = [Math]::Round($vhd.Size / 1GB, 2)
                                    FileSizeGB = [Math]::Round($vhd.FileSize / 1GB, 2)
                                    MinimumSizeGB = [Math]::Round($vhd.MinimumSize / 1GB, 2)
                                    FragmentationPercentage = $vhd.FragmentationPercentage
                                    Alignment = $vhd.Alignment
                                    Attached = $vhd.Attached
                                    DiskNumber = $vhd.DiskNumber
                                    LogicalSectorSize = $vhd.LogicalSectorSize
                                    PhysicalSectorSize = $vhd.PhysicalSectorSize
                                    ParentPath = $vhd.ParentPath
                                    ControllerType = $drive.ControllerType
                                    ControllerNumber = $drive.ControllerNumber
                                    ControllerLocation = $drive.ControllerLocation
                                }
                                
                                $allStorage += $storageInfo
                            }
                        }
                        catch {
                            # VHD file might be inaccessible, add basic info
                            $storageInfo = [PSCustomObject]@{
                                HostName = $hostName
                                VMName = $vm.Name
                                VHDPath = $drive.Path
                                VHDType = "Unknown"
                                VHDFormat = "Unknown"
                                SizeGB = 0
                                FileSizeGB = 0
                                MinimumSizeGB = 0
                                FragmentationPercentage = 0
                                Alignment = 0
                                Attached = "Unknown"
                                DiskNumber = 0
                                LogicalSectorSize = 0
                                PhysicalSectorSize = 0
                                ParentPath = ""
                                ControllerType = $drive.ControllerType
                                ControllerNumber = $drive.ControllerNumber
                                ControllerLocation = $drive.ControllerLocation
                            }
                            
                            $allStorage += $storageInfo
                        }
                    }
                }
            }
            catch {
                Write-Log -Message "Error collecting storage from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allStorage
    }
    catch {
        Write-Log -Message "Error in Get-HyperVStorageDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVNetworkDetails {
    <#
    .SYNOPSIS
        Collects comprehensive network adapter details for all VMs
    #>
    try {
        $allNetworkAdapters = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting network data from host: $hostName" -ForegroundColor Cyan
                
                $vms = Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue
                
                foreach ($vm in $vms) {
                    $networkAdapters = Get-VMNetworkAdapter -VM $vm -ErrorAction SilentlyContinue
                    
                    foreach ($adapter in $networkAdapters) {
                        $networkInfo = [PSCustomObject]@{
                            HostName = $hostName
                            VMName = $vm.Name
                            AdapterName = $adapter.Name
                            SwitchName = $adapter.SwitchName
                            MacAddress = $adapter.MacAddress
                            DynamicMacAddressEnabled = $adapter.DynamicMacAddressEnabled
                            IPAddresses = $adapter.IPAddresses -join "; "
                            Connected = $adapter.Connected
                            VlanId = if ($adapter.VlanSetting) { $adapter.VlanSetting.AccessVlanId } else { 0 }
                            VlanMode = if ($adapter.VlanSetting) { $adapter.VlanSetting.OperationMode } else { "Untagged" }
                            Status = $adapter.Status
                            StatusDescription = $adapter.StatusDescription
                            IsManagementOs = $adapter.IsManagementOs
                            ClusterMonitored = $adapter.ClusterMonitored
                            Id = $adapter.Id
                        }
                        
                        $allNetworkAdapters += $networkInfo
                    }
                }
            }
            catch {
                Write-Log -Message "Error collecting network adapters from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allNetworkAdapters
    }
    catch {
        Write-Log -Message "Error in Get-HyperVNetworkDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVPerformanceDetails {
    <#
    .SYNOPSIS
        Collects performance metrics for hosts and VMs
    #>
    try {
        $allPerformance = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting performance data from host: $hostName" -ForegroundColor Cyan
                
                # VM performance
                $vms = Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue
                foreach ($vm in $vms) {
                    $vmPerf = [PSCustomObject]@{
                        HostName = $hostName
                        Type = "VM"
                        Name = $vm.Name
                        CPUUsagePercent = $vm.CPUUsage
                        MemoryUsedGB = [Math]::Round($vm.MemoryAssigned / 1GB, 2)
                        MemoryDemandGB = [Math]::Round($vm.MemoryDemand / 1GB, 2)
                        MemoryStatus = $vm.MemoryStatus
                        Heartbeat = $vm.Heartbeat
                        IntegrationServicesState = $vm.IntegrationServicesState
                        CollectionTime = Get-Date
                        State = $vm.State
                        UptimeHours = if ($vm.Uptime) { [Math]::Round($vm.Uptime.TotalHours, 2) } else { 0 }
                    }
                    
                    $allPerformance += $vmPerf
                }
            }
            catch {
                Write-Log -Message "Error collecting performance data from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allPerformance
    }
    catch {
        Write-Log -Message "Error in Get-HyperVPerformanceDetails: $_" -Level "ERROR"
        return @()
    }
}

function Get-HyperVSecurityDetails {
    <#
    .SYNOPSIS
        Collects security and compliance information
    #>
    try {
        $allSecurity = @()
        
        # Get all Hyper-V hosts
        try {
            $clusterNodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($clusterNodes) {
                $hostNames = $clusterNodes.Name
            } else {
                $hostNames = @($env:COMPUTERNAME)
            }
        }
        catch {
            $hostNames = @($env:COMPUTERNAME)
        }
        
        foreach ($hostName in $hostNames) {
            try {
                Write-Host "    Collecting security data from host: $hostName" -ForegroundColor Cyan
                
                $vms = Get-VM -ComputerName $hostName -ErrorAction SilentlyContinue
                
                foreach ($vm in $vms) {
                    $vmSecurity = Get-VMSecurity -VM $vm -ErrorAction SilentlyContinue
                    $vmFirmware = Get-VMFirmware -VM $vm -ErrorAction SilentlyContinue
                    
                    $securityInfo = [PSCustomObject]@{
                        HostName = $hostName
                        VMName = $vm.Name
                        Generation = $vm.Generation
                        SecureBootEnabled = if ($vmFirmware) { $vmFirmware.SecureBoot } else { "N/A" }
                        SecureBootTemplate = if ($vmFirmware) { $vmFirmware.SecureBootTemplate } else { "N/A" }
                        TpmEnabled = if ($vmSecurity) { $vmSecurity.TpmEnabled } else { $false }
                        IntegrationServicesVersion = $vm.IntegrationServicesVersion
                        IntegrationServicesState = $vm.IntegrationServicesState
                        ReplicationMode = $vm.ReplicationMode
                        ReplicationState = $vm.ReplicationState
                        CheckpointType = $vm.CheckpointType
                        AutomaticCheckpointsEnabled = $vm.AutomaticCheckpointsEnabled
                    }
                    
                    $allSecurity += $securityInfo
                }
            }
            catch {
                Write-Log -Message "Error collecting security data from host $hostName`: $_" -Level "ERROR"
            }
        }
        
        return $allSecurity
    }
    catch {
        Write-Log -Message "Error in Get-HyperVSecurityDetails: $_" -Level "ERROR"
        return @()
    }
}

function New-InventorySummary {
    <#
    .SYNOPSIS
        Creates a summary of the inventory data for the Summary worksheet
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$InventoryData
    )
    
    $summary = @()
    
    # Host summary
    if ($InventoryData.Hosts) {
        $totalHosts = $InventoryData.Hosts.Count
        $totalRAM = ($InventoryData.Hosts | Measure-Object -Property TotalRAMGB -Sum).Sum
        $totalCores = ($InventoryData.Hosts | Measure-Object -Property ProcessorCores -Sum).Sum
        
        $summary += [PSCustomObject]@{
            Category = "Hosts"
            Metric = "Total Hosts"
            Value = $totalHosts
            Unit = "hosts"
        }
        
        $summary += [PSCustomObject]@{
            Category = "Hosts"
            Metric = "Total RAM"
            Value = [Math]::Round($totalRAM, 2)
            Unit = "GB"
        }
        
        $summary += [PSCustomObject]@{
            Category = "Hosts"
            Metric = "Total CPU Cores"
            Value = $totalCores
            Unit = "cores"
        }
    }
    
    # VM summary
    if ($InventoryData.VMs) {
        $totalVMs = $InventoryData.VMs.Count
        $runningVMs = ($InventoryData.VMs | Where-Object { $_.State -eq "Running" }).Count
        $totalVMMemory = ($InventoryData.VMs | Measure-Object -Property MemoryAssignedMB -Sum).Sum
        $totalVMStorage = ($InventoryData.VMs | Measure-Object -Property TotalDiskSizeGB -Sum).Sum
        
        $summary += [PSCustomObject]@{
            Category = "Virtual Machines"
            Metric = "Total VMs"
            Value = $totalVMs
            Unit = "VMs"
        }
        
        $summary += [PSCustomObject]@{
            Category = "Virtual Machines"
            Metric = "Running VMs"
            Value = $runningVMs
            Unit = "VMs"
        }
        
        $summary += [PSCustomObject]@{
            Category = "Virtual Machines"
            Metric = "Total VM Memory"
            Value = [Math]::Round($totalVMMemory / 1024, 2)
            Unit = "GB"
        }
        
        $summary += [PSCustomObject]@{
            Category = "Virtual Machines"
            Metric = "Total VM Storage"
            Value = [Math]::Round($totalVMStorage, 2)
            Unit = "GB"
        }
    }
    
    # Additional summaries for other categories...
    if ($InventoryData.VirtualSwitches) {
        $summary += [PSCustomObject]@{
            Category = "Network"
            Metric = "Virtual Switches"
            Value = $InventoryData.VirtualSwitches.Count
            Unit = "switches"
        }
    }
    
    if ($InventoryData.Storage) {
        $summary += [PSCustomObject]@{
            Category = "Storage"
            Metric = "VHD Files"
            Value = $InventoryData.Storage.Count
            Unit = "files"
        }
    }
    
    return $summary
}

# ============================================================================
# MISSING MENU FUNCTIONS - IMPLEMENTATION
# ============================================================================

function Invoke-QuickEnvironmentScan {
    <#
    .SYNOPSIS
        Performs a quick scan of the Hyper-V environment
    #>
    Write-Host "Starting Quick Environment Scan..." -ForegroundColor Cyan
    Write-Log -Message "Starting quick environment scan" -Level "INFO"
    
    try {
        Write-Host "`nScanning Hyper-V environment..." -ForegroundColor Yellow
        
        # Quick host check
        Write-Host "[1/4] Scanning Hyper-V hosts..." -ForegroundColor Cyan
        $hostCount = (Get-VMHost -ErrorAction SilentlyContinue | Measure-Object).Count
        
        # Quick VM check
        Write-Host "[2/4] Scanning virtual machines..." -ForegroundColor Cyan
        $vms = Get-VM -ErrorAction SilentlyContinue
        $vmCount = ($vms | Measure-Object).Count
        $runningVMs = ($vms | Where-Object { $_.State -eq "Running" } | Measure-Object).Count
        
        # Quick switch check
        Write-Host "[3/4] Scanning virtual switches..." -ForegroundColor Cyan
        $switchCount = (Get-VMSwitch -ErrorAction SilentlyContinue | Measure-Object).Count
        
        # Quick storage check
        Write-Host "[4/4] Scanning storage configuration..." -ForegroundColor Cyan
        $vhdCount = (Get-VHD -Path (Join-Path $Global:BaseDirectory "*") -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        
        # Display results
        Write-Host "`n📊 Environment Summary:" -ForegroundColor Green
        Write-Host "  🏢 Hyper-V Hosts: $hostCount" -ForegroundColor White
        Write-Host "  💻 Total VMs: $vmCount ($runningVMs running)" -ForegroundColor White
        Write-Host "  🌐 Virtual Switches: $switchCount" -ForegroundColor White
        Write-Host "  💽 VHD Files Found: $vhdCount" -ForegroundColor White
        
        Write-Host "`n✓ Quick environment scan completed!" -ForegroundColor Green
        Write-Log -Message "Quick environment scan completed successfully" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error during quick environment scan: $_" -Level "ERROR"
        Write-Host "Error during scan: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-HostDetailsReport {
    <#
    .SYNOPSIS
        Generates detailed host information report
    #>
    Write-Host "Generating Host Details Report..." -ForegroundColor Cyan
    Write-Log -Message "Starting host details report generation" -Level "INFO"
    
    try {
        $hostDetails = Get-HyperVHostDetails
        
        if ($hostDetails -and $hostDetails.Count -gt 0) {
            Write-Host "`n📋 Host Details Report:" -ForegroundColor Green
            foreach ($host in $hostDetails) {
                Write-Host "`n🏢 Host: $($host.HostName)" -ForegroundColor Yellow
                Write-Host "  OS: $($host.OperatingSystem)" -ForegroundColor White
                Write-Host "  Version: $($host.HyperVVersion)" -ForegroundColor White
                Write-Host "  CPU: $($host.ProcessorCores) cores" -ForegroundColor White
                Write-Host "  RAM: $($host.TotalRAMGB) GB" -ForegroundColor White
                Write-Host "  Virtual Machines: $($host.VMCount)" -ForegroundColor White
            }
            
            # Offer to export
            $export = Read-Host "`nWould you like to export this report? (Y/N)"
            if ($export -match "^[Yy]") {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $reportFile = Join-Path $Global:ReportPath "HostDetails_$timestamp.json"
                $hostDetails | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFile -Encoding UTF8
                Write-Host "Report exported to: $reportFile" -ForegroundColor Cyan
            }
        } else {
            Write-Host "No host information available" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error generating host details report: $_" -Level "ERROR"
        Write-Host "Error generating report: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-VMComprehensiveAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive VM analysis
    #>
    Write-Host "Starting VM Comprehensive Analysis..." -ForegroundColor Cyan
    Write-Log -Message "Starting comprehensive VM analysis" -Level "INFO"
    
    try {
        $vmDetails = Get-HyperVVMDetails
        
        if ($vmDetails -and $vmDetails.Count -gt 0) {
            Write-Host "`n📊 VM Analysis Results:" -ForegroundColor Green
            
            # VM State Analysis
            $stateAnalysis = $vmDetails | Group-Object -Property State | Select-Object Name, Count
            Write-Host "`n🔍 VM State Distribution:" -ForegroundColor Yellow
            foreach ($state in $stateAnalysis) {
                Write-Host "  $($state.Name): $($state.Count) VMs" -ForegroundColor White
            }
            
            # Resource Analysis
            $totalMemory = ($vmDetails | Measure-Object -Property MemoryAssignedMB -Sum).Sum
            $totalStorage = ($vmDetails | Measure-Object -Property TotalDiskSizeGB -Sum).Sum
            
            Write-Host "`n💾 Resource Allocation:" -ForegroundColor Yellow
            Write-Host "  Total Memory Allocated: $([Math]::Round($totalMemory / 1024, 2)) GB" -ForegroundColor White
            Write-Host "  Total Storage Allocated: $([Math]::Round($totalStorage, 2)) GB" -ForegroundColor White
            
            # Top resource consumers
            Write-Host "`n🏆 Top Memory Consumers:" -ForegroundColor Yellow
            $vmDetails | Sort-Object MemoryAssignedMB -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.VMName): $([Math]::Round($_.MemoryAssignedMB / 1024, 2)) GB" -ForegroundColor White
            }
            
            Write-Host "`n🏆 Top Storage Consumers:" -ForegroundColor Yellow
            $vmDetails | Sort-Object TotalDiskSizeGB -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.VMName): $([Math]::Round($_.TotalDiskSizeGB, 2)) GB" -ForegroundColor White
            }
        } else {
            Write-Host "No VM information available for analysis" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error during VM comprehensive analysis: $_" -Level "ERROR"
        Write-Host "Error during analysis: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-StorageVHDAnalysis {
    <#
    .SYNOPSIS
        Performs storage and VHD analysis
    #>
    Write-Host "Starting Storage and VHD Analysis..." -ForegroundColor Cyan
    Write-Log -Message "Starting storage and VHD analysis" -Level "INFO"
    
    try {
        $storageDetails = Get-HyperVStorageDetails
        
        if ($storageDetails -and $storageDetails.Count -gt 0) {
            Write-Host "`n💽 Storage Analysis Results:" -ForegroundColor Green
            
            # VHD Type Analysis
            $typeAnalysis = $storageDetails | Group-Object -Property VHDType | Select-Object Name, Count
            Write-Host "`n📁 VHD Type Distribution:" -ForegroundColor Yellow
            foreach ($type in $typeAnalysis) {
                Write-Host "  $($type.Name): $($type.Count) files" -ForegroundColor White
            }
            
            # Size Analysis
            $totalSize = ($storageDetails | Measure-Object -Property SizeGB -Sum).Sum
            $avgSize = ($storageDetails | Measure-Object -Property SizeGB -Average).Average
            
            Write-Host "`n📊 Storage Statistics:" -ForegroundColor Yellow
            Write-Host "  Total Storage: $([Math]::Round($totalSize, 2)) GB" -ForegroundColor White
            Write-Host "  Average VHD Size: $([Math]::Round($avgSize, 2)) GB" -ForegroundColor White
            Write-Host "  Total VHD Files: $($storageDetails.Count)" -ForegroundColor White
            
            # Largest VHDs
            Write-Host "`n🏆 Largest VHD Files:" -ForegroundColor Yellow
            $storageDetails | Sort-Object SizeGB -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.Path): $([Math]::Round($_.SizeGB, 2)) GB" -ForegroundColor White
            }        } else {
            Write-Host "No storage information available for analysis" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error during storage and VHD analysis: $_" -Level "ERROR"
        Write-Host "Error during analysis: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-NetworkConfigurationReport {
    <#
    .SYNOPSIS
        Generates network configuration report
    #>
    Write-Host "Generating Network Configuration Report..." -ForegroundColor Cyan
    Write-Log -Message "Starting network configuration report generation" -Level "INFO"
    
    try {
        $networkDetails = Get-HyperVNetworkDetails
        $switchDetails = Get-HyperVVirtualSwitchDetails
        
        Write-Host "`n🌐 Network Configuration Report:" -ForegroundColor Green
        
        # Virtual Switch Summary
        if ($switchDetails -and $switchDetails.Count -gt 0) {
            Write-Host "`n📡 Virtual Switches:" -ForegroundColor Yellow
            foreach ($switch in $switchDetails) {
                Write-Host "  $($switch.SwitchName) ($($switch.SwitchType))" -ForegroundColor White
                Write-Host "    Connected VMs: $($switch.ConnectedVMs)" -ForegroundColor Gray
            }
        }
        
        # Network Adapter Summary
        if ($networkDetails -and $networkDetails.Count -gt 0) {
            Write-Host "`n🔌 Network Adapters Summary:" -ForegroundColor Yellow
            $adapterTypes = $networkDetails | Group-Object -Property AdapterType | Select-Object Name, Count
            foreach ($type in $adapterTypes) {
                Write-Host "  $($type.Name): $($type.Count) adapters" -ForegroundColor White
            }
        }
        
    }
    catch {
        Write-Log -Message "Error generating network configuration report: $_" -Level "ERROR"
        Write-Host "Error generating report: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-PerformanceMetricsCollection {
    <#
    .SYNOPSIS
        Collects performance metrics from Hyper-V environment
    #>
    Write-Host "Collecting Performance Metrics..." -ForegroundColor Cyan
    Write-Log -Message "Starting performance metrics collection" -Level "INFO"
    
    try {
        Write-Host "`nGathering performance data..." -ForegroundColor Yellow
        Write-Host "This may take a few moments..." -ForegroundColor Yellow
        
        $performanceData = Get-HyperVPerformanceDetails
        
        if ($performanceData -and $performanceData.Count -gt 0) {
            Write-Host "`n📈 Performance Metrics Summary:" -ForegroundColor Green
            
            # CPU Performance
            $avgCpuUsage = ($performanceData | Measure-Object -Property CPUUsagePercent -Average).Average
            Write-Host "`n🔧 CPU Performance:" -ForegroundColor Yellow
            Write-Host "  Average CPU Usage: $([Math]::Round($avgCpuUsage, 2))%" -ForegroundColor White
            
            # Memory Performance
            $avgMemUsage = ($performanceData | Measure-Object -Property MemoryUsagePercent -Average).Average
            Write-Host "`n💾 Memory Performance:" -ForegroundColor Yellow
            Write-Host "  Average Memory Usage: $([Math]::Round($avgMemUsage, 2))%" -ForegroundColor White
            
            # Top performers
            Write-Host "`n🏆 Highest CPU Usage VMs:" -ForegroundColor Yellow
            $performanceData | Sort-Object CPUUsagePercent -Descending | Select-Object -First 3 | ForEach-Object {
                Write-Host "  $($_.VMName): $($_.CPUUsagePercent)%" -ForegroundColor White
            }
        } else {
            Write-Host "No performance data available" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error collecting performance metrics: $_" -Level "ERROR"
        Write-Host "Error collecting metrics: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-SecurityComplianceAudit {
    <#
    .SYNOPSIS
        Performs security and compliance audit
    #>
    Write-Host "Starting Security and Compliance Audit..." -ForegroundColor Cyan
    Write-Log -Message "Starting security and compliance audit" -Level "INFO"
    
    try {
        Write-Host "`nPerforming security audit..." -ForegroundColor Yellow
        
        $securityData = Get-HyperVSecurityDetails
        
        if ($securityData -and $securityData.Count -gt 0) {
            Write-Host "`n🔒 Security Audit Results:" -ForegroundColor Green
            
            # Security features summary
            $secureBootEnabled = ($securityData | Where-Object { $_.SecureBootEnabled -eq $true }).Count
            $tpmEnabled = ($securityData | Where-Object { $_.TPMEnabled -eq $true }).Count
            $encryptionEnabled = ($securityData | Where-Object { $_.EncryptionEnabled -eq $true }).Count
            
            Write-Host "`n🛡️ Security Features Status:" -ForegroundColor Yellow
            Write-Host "  Secure Boot Enabled: $secureBootEnabled VMs" -ForegroundColor White
            Write-Host "  TPM Enabled: $tpmEnabled VMs" -ForegroundColor White
            Write-Host "  Encryption Enabled: $encryptionEnabled VMs" -ForegroundColor White
            
            # Compliance assessment
            $totalVMs = $securityData.Count
            $compliantVMs = ($securityData | Where-Object { 
                $_.SecureBootEnabled -eq $true -and $_.TPMEnabled -eq $true 
            }).Count
            
            $compliancePercent = if ($totalVMs -gt 0) { [Math]::Round(($compliantVMs / $totalVMs) * 100, 2) } else { 0 }
            
            Write-Host "`n📊 Compliance Summary:" -ForegroundColor Yellow
            Write-Host "  Compliance Rate: $compliancePercent% ($compliantVMs of $totalVMs VMs)" -ForegroundColor White
            
            if ($compliancePercent -lt 80) {
                Write-Host "  ⚠️  Compliance below recommended threshold (80%)" -ForegroundColor Red
            } else {
                Write-Host "  ✅ Good compliance rate" -ForegroundColor Green
            }
        } else {
            Write-Host "No security data available for audit" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error during security compliance audit: $_" -Level "ERROR"
        Write-Host "Error during audit: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Export-ToCSVFiles {
    <#
    .SYNOPSIS
        Exports inventory data to CSV files
    #>
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$InventoryData
    )
    
    Write-Host "Exporting to CSV files..." -ForegroundColor Cyan
    Write-Log -Message "Starting CSV export" -Level "INFO"
    
    try {
        # Get inventory data if not provided
        if (-not $InventoryData) {
            Write-Host "Collecting current inventory data..." -ForegroundColor Yellow
            $InventoryData = @{
                Hosts = Get-HyperVHostDetails
                VMs = Get-HyperVVMDetails
                VirtualSwitches = Get-HyperVVirtualSwitchDetails
                Storage = Get-HyperVStorageDetails
                Networks = Get-HyperVNetworkDetails
                Performance = Get-HyperVPerformanceDetails
                Security = Get-HyperVSecurityDetails
            }
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportFolder = Join-Path $Global:ReportPath "CSV_Export_$timestamp"
        New-Item -Path $exportFolder -ItemType Directory -Force | Out-Null
        
        Write-Host "`nExporting CSV files to: $exportFolder" -ForegroundColor Yellow
        
        # Export each dataset to CSV
        if ($InventoryData.Hosts) {
            $csvFile = Join-Path $exportFolder "Hosts.csv"
            $InventoryData.Hosts | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ Hosts.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.VMs) {
            $csvFile = Join-Path $exportFolder "VirtualMachines.csv"
            $InventoryData.VMs | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ VirtualMachines.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.VirtualSwitches) {
            $csvFile = Join-Path $exportFolder "VirtualSwitches.csv"
            $InventoryData.VirtualSwitches | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ VirtualSwitches.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.Storage) {
            $csvFile = Join-Path $exportFolder "Storage.csv"
            $InventoryData.Storage | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ Storage.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.Networks) {
            $csvFile = Join-Path $exportFolder "NetworkAdapters.csv"
            $InventoryData.Networks | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ NetworkAdapters.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.Performance) {
            $csvFile = Join-Path $exportFolder "Performance.csv"
            $InventoryData.Performance | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ Performance.csv" -ForegroundColor Green
        }
        
        if ($InventoryData.Security) {
            $csvFile = Join-Path $exportFolder "Security.csv"
            $InventoryData.Security | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
            Write-Host "  ✓ Security.csv" -ForegroundColor Green
        }
        
        Write-Host "`n✅ CSV export completed successfully!" -ForegroundColor Green
        Write-Log -Message "CSV export completed: $exportFolder" -Level "SUCCESS"
        
        # Offer to open folder
        $openFolder = Read-Host "`nWould you like to open the export folder? (Y/N)"
        if ($openFolder -match "^[Yy]") {
            Start-Process $exportFolder
        }
        
    }
    catch {
        Write-Log -Message "Error during CSV export: $_" -Level "ERROR"
        Write-Host "Error during CSV export: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function New-HTMLReport {
    <#
    .SYNOPSIS
        Generates HTML report from inventory data
    #>
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$InventoryData
    )
    
    Write-Host "Generating HTML Report..." -ForegroundColor Cyan
    Write-Log -Message "Starting HTML report generation" -Level "INFO"
    
    try {
        # Get inventory data if not provided
        if (-not $InventoryData) {
            Write-Host "Collecting current inventory data..." -ForegroundColor Yellow
            $InventoryData = @{
                Hosts = Get-HyperVHostDetails
                VMs = Get-HyperVVMDetails
                VirtualSwitches = Get-HyperVVirtualSwitchDetails
                Storage = Get-HyperVStorageDetails
                Networks = Get-HyperVNetworkDetails
                Performance = Get-HyperVPerformanceDetails
                Security = Get-HyperVSecurityDetails
            }
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $Global:ReportPath "HyperV_Inventory_Report_$timestamp.html"
        
        # Generate simple HTML content using string building
        $html = "<!DOCTYPE html>`n"
        $html += "<html lang='en'>`n"
        $html += "<head>`n"
        $html += "<meta charset='UTF-8'>`n"
        $html += "<title>Hyper-V Inventory Report</title>`n"
        $html += "<style>`n"
        $html += "body { font-family: Arial, sans-serif; margin: 20px; }`n"
        $html += ".header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }`n"
        $html += ".section { margin-bottom: 30px; }`n"
        $html += "table { width: 100%; border-collapse: collapse; }`n"
        $html += "th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }`n"
        $html += "th { background-color: #f2f2f2; }`n"
        $html += ".running { color: green; font-weight: bold; }`n"
        $html += ".stopped { color: red; font-weight: bold; }`n"
        $html += "</style>`n"
        $html += "</head>`n"
        $html += "<body>`n"
        
        # Header
        $html += "<div class='header'>`n"
        $html += "<h1>Hyper-V Infrastructure Inventory Report</h1>`n"
        $html += "<p>Generated on $(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')</p>`n"
        $html += "</div>`n"
        
        # Executive Summary
        $html += "<div class='section'>`n"
        $html += "<h2>Executive Summary</h2>`n"
        $html += "<p>Hyper-V Hosts: $($InventoryData.Hosts.Count)</p>`n"
        $html += "<p>Virtual Machines: $($InventoryData.VMs.Count)</p>`n"
        $html += "<p>Virtual Switches: $($InventoryData.VirtualSwitches.Count)</p>`n"
        $html += "<p>VHD Files: $($InventoryData.Storage.Count)</p>`n"
        $html += "</div>`n"
        
        # VM Table
        if ($InventoryData.VMs -and $InventoryData.VMs.Count -gt 0) {
            $html += "<div class='section'>`n"
            $html += "<h2>Virtual Machines</h2>`n"
            $html += "<table>`n"
            $html += "<tr><th>VM Name</th><th>State</th><th>Memory (GB)</th><th>CPU Cores</th></tr>`n"
            
            foreach ($vm in $InventoryData.VMs | Sort-Object VMName) {
                $stateClass = if ($vm.State -eq "Running") { "running" } else { "stopped" }
                $memoryGB = [Math]::Round($vm.MemoryAssignedMB / 1024, 2)
                $html += "<tr>`n"
                $html += "<td>$($vm.VMName)</td>`n"
                $html += "<td class='$stateClass'>$($vm.State)</td>`n"
                $html += "<td>$memoryGB</td>`n"
                $html += "<td>$($vm.ProcessorCount)</td>`n"
                $html += "</tr>`n"
            }
            $html += "</table>`n"
            $html += "</div>`n"
        }
        
        # Close HTML
        $html += "</body>`n"
        $html += "</html>`n"
        
        # Save the HTML file
        $html | Out-File -FilePath $reportFile -Encoding UTF8
        
        Write-Host "`n📄 HTML Report Generated Successfully!" -ForegroundColor Green
        Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
        Write-Log -Message "HTML report generated: $reportFile" -Level "SUCCESS"
        
        # Try to open the report
        try {
            Start-Process $reportFile
            Write-Host "Opening report in default browser..." -ForegroundColor Cyan
        }
        catch {
            Write-Host "Report saved but couldn't open automatically." -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error generating HTML report: $_" -Level "ERROR"
        Write-Host "Error generating HTML report: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function New-ExecutiveSummary {
    <#
    .SYNOPSIS
        Creates an executive summary report
    #>
    Write-Host "Creating Executive Summary..." -ForegroundColor Cyan
    Write-Log -Message "Starting executive summary creation" -Level "INFO"
    
    try {
        Write-Host "`nGenerating executive summary..." -ForegroundColor Yellow
        
        # Collect summary data
        $hostCount = (Get-VMHost -ErrorAction SilentlyContinue | Measure-Object).Count
        $vms = Get-VM -ErrorAction SilentlyContinue
        $vmCount = ($vms | Measure-Object).Count
        $runningVMs = ($vms | Where-Object { $_.State -eq "Running" } | Measure-Object).Count
        $switchCount = (Get-VMSwitch -ErrorAction SilentlyContinue | Measure-Object).Count
        
        # Calculate resource allocation
        $totalMemoryGB = ($vms | Measure-Object -Property MemoryAssigned -Sum).Sum / 1GB
        $utilizationRate = if ($vmCount -gt 0) { [Math]::Round(($runningVMs / $vmCount) * 100, 1) } else { 0 }
        
        Write-Host "`n📋 EXECUTIVE SUMMARY" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "🏢 INFRASTRUCTURE OVERVIEW:" -ForegroundColor Yellow
        Write-Host "  • Hyper-V Hosts: $hostCount" -ForegroundColor White
        Write-Host "  • Total Virtual Machines: $vmCount" -ForegroundColor White
        Write-Host "  • Running VMs: $runningVMs ($utilizationRate`% utilization)" -ForegroundColor White
        Write-Host "  • Virtual Switches: $switchCount" -ForegroundColor White
        Write-Host ""
        Write-Host "💾 RESOURCE ALLOCATION:" -ForegroundColor Yellow
        Write-Host "  • Total Allocated Memory: $([Math]::Round($totalMemoryGB, 2)) GB" -ForegroundColor White
        Write-Host "  • Average Memory per VM: $([Math]::Round($totalMemoryGB / $vmCount, 2)) GB" -ForegroundColor White
        Write-Host ""
        Write-Host "📊 KEY METRICS:" -ForegroundColor Yellow
        if ($utilizationRate -gt 80) {
            Write-Host "  • VM Utilization: HIGH ($utilizationRate`%)" -ForegroundColor Red
            Write-Host "    Recommendation: Monitor resource consumption" -ForegroundColor Yellow
        } elseif ($utilizationRate -gt 60) {
            Write-Host "  • VM Utilization: OPTIMAL ($utilizationRate`%)" -ForegroundColor Green
        } else {
            Write-Host "  • VM Utilization: LOW ($utilizationRate`%)" -ForegroundColor Yellow
            Write-Host "    Recommendation: Consider consolidation opportunities" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "📅 Report Generated: $(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')" -ForegroundColor Gray
        Write-Host "===========================================" -ForegroundColor Green
        
        # Save summary to file
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $summaryFile = Join-Path $Global:ReportPath "ExecutiveSummary_$timestamp.txt"
          $summaryContent = @"
HYPER-V INFRASTRUCTURE EXECUTIVE SUMMARY
Generated: $(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')

INFRASTRUCTURE OVERVIEW:
• Hyper-V Hosts: $hostCount
• Total Virtual Machines: $vmCount
• Running VMs: $runningVMs ($utilizationRate`% utilization)
• Virtual Switches: $switchCount

RESOURCE ALLOCATION:
• Total Allocated Memory: $([Math]::Round($totalMemoryGB, 2)) GB
• Average Memory per VM: $([Math]::Round($totalMemoryGB / $vmCount, 2)) GB

KEY RECOMMENDATIONS:
$(if ($utilizationRate -gt 80) { "• Monitor high resource utilization ($utilizationRate`%)" } 
elseif ($utilizationRate -lt 60) { "• Consider consolidation opportunities (utilization: $utilizationRate`%)" } 
else { "• Current utilization is optimal ($utilizationRate`%)" })

Report generated by Hyper-V Enterprise Deployment Tool v$Global:ScriptVersion
"@
        
        $summaryContent | Out-File -FilePath $summaryFile -Encoding UTF8
        Write-Host "`nExecutive summary saved to: $summaryFile" -ForegroundColor Cyan
        Write-Log -Message "Executive summary created: $summaryFile" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error creating executive summary: $_" -Level "ERROR"
        Write-Host "Error creating summary: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Compare-PreviousInventories {
    <#
    .SYNOPSIS
        Compares current inventory with previous inventories
    #>
    Write-Host "Comparing Previous Inventories..." -ForegroundColor Cyan
    Write-Log -Message "Starting inventory comparison" -Level "INFO"
    
    try {
        # Find previous inventory files
        $inventoryFiles = Get-ChildItem -Path $Global:ReportPath -Filter "CompleteInventory_*.json" | Sort-Object LastWriteTime -Descending
        
        if ($inventoryFiles.Count -lt 2) {
            Write-Host "`n⚠️  Not enough inventory files found for comparison" -ForegroundColor Yellow
            Write-Host "At least 2 previous inventory files are required." -ForegroundColor Yellow
            Write-Host "Current inventory files found: $($inventoryFiles.Count)" -ForegroundColor White
            return
        }
        
        Write-Host "`nAvailable inventory files for comparison:" -ForegroundColor Green
        for ($i = 0; $i -lt [Math]::Min($inventoryFiles.Count, 5); $i++) {
            $file = $inventoryFiles[$i]
            Write-Host "  $($i + 1). $($file.BaseName) ($($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Cyan
        }
        
        $selection1 = Read-Host "`nSelect first inventory file (1-$([Math]::Min($inventoryFiles.Count, 5)))"
        $selection2 = Read-Host "Select second inventory file for comparison (1-$([Math]::Min($inventoryFiles.Count, 5)))"
        
        if ($selection1 -match '^\d+$' -and $selection2 -match '^\d+$' -and 
            [int]$selection1 -ge 1 -and [int]$selection1 -le $inventoryFiles.Count -and
            [int]$selection2 -ge 1 -and [int]$selection2 -le $inventoryFiles.Count -and
            $selection1 -ne $selection2) {
            
            $file1 = $inventoryFiles[[int]$selection1 - 1]
            $file2 = $inventoryFiles[[int]$selection2 - 1]
            
            Write-Host "`nComparing inventories..." -ForegroundColor Yellow
            Write-Host "File 1: $($file1.BaseName)" -ForegroundColor Cyan
            Write-Host "File 2: $($file2.BaseName)" -ForegroundColor Cyan
            
            # Load inventory data
            $inventory1 = Get-Content $file1.FullName | ConvertFrom-Json
            $inventory2 = Get-Content $file2.FullName | ConvertFrom-Json
            
            # Compare VM counts
            $vm1Count = if ($inventory1.VMs) { $inventory1.VMs.Count } else { 0 }
            $vm2Count = if ($inventory2.VMs) { $inventory2.VMs.Count } else { 0 }
            $vmDiff = $vm1Count - $vm2Count
            
            # Compare host counts
            $host1Count = if ($inventory1.Hosts) { $inventory1.Hosts.Count } else { 0 }
            $host2Count = if ($inventory2.Hosts) { $inventory2.Hosts.Count } else { 0 }
            $hostDiff = $host1Count - $host2Count
            
            Write-Host "`n📊 Comparison Results:" -ForegroundColor Green
            Write-Host "Virtual Machines: $vm1Count vs $vm2Count ($(if($vmDiff -gt 0){"+"})$vmDiff)" -ForegroundColor White
            Write-Host "Hyper-V Hosts: $host1Count vs $host2Count ($(if($hostDiff -gt 0){"+"})$hostDiff)" -ForegroundColor White
            
            if ($vmDiff -ne 0 -or $hostDiff -ne 0) {
                Write-Host "`n📋 Changes Detected:" -ForegroundColor Yellow
                if ($vmDiff -gt 0) {
                    Write-Host "  • $vmDiff new virtual machine(s) added" -ForegroundColor Green
               
                } elseif ($vmDiff -lt 0) {
                    Write-Host "  • $([Math]::Abs($vmDiff)) virtual machine(s) removed" -ForegroundColor Red
                }
                
                if ($hostDiff -gt 0) {
                    Write-Host "  • $hostDiff new Hyper-V host(s) added" -ForegroundColor Green
                } elseif ($hostDiff -lt 0) {
                    Write-Host "  • $([Math]::Abs($hostDiff)) Hyper-V host(s) removed" -ForegroundColor Red
                }
            } else {
                Write-Host "`n✅ No significant changes detected between inventories" -ForegroundColor Green
            }
            
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
        
    }
    catch {
        Write-Log -Message "Error comparing inventories: $_" -Level "ERROR"
        Write-Host "Error during comparison: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function New-CapacityPlanningReport {
    <#
    .SYNOPSIS
        Generates capacity planning report
    #>
    Write-Host "Generating Capacity Planning Report..." -ForegroundColor Cyan
    Write-Log -Message "Starting capacity planning report generation" -Level "INFO"
    
    try {
        Write-Host "`nAnalyzing current capacity..." -ForegroundColor Yellow
        
        # Collect current data
        $hosts = Get-VMHost -ErrorAction SilentlyContinue
        $vms = Get-VM -ErrorAction SilentlyContinue
        
        if ($hosts -and $vms) {
                       # Calculate current utilization
            $totalHostMemory = ($hosts | Measure-Object -Property MemoryCapacity -Sum).Sum / 1GB
            $totalVMMemory = ($vms | Measure-Object -Property MemoryAssigned -Sum).Sum / 1GB
            $memoryUtilization = if ($totalHostMemory -gt 0) { [Math]::Round(($totalVMMemory / $totalHostMemory) * 100, 2) } else { 0 }
            
            $totalHostCores = ($hosts | Measure-Object -Property LogicalProcessorCount -Sum).Sum
            $totalVMCores = ($vms | Measure-Object -Property ProcessorCount -Sum).Sum
            $cpuUtilization = if ($totalHostCores -gt 0) { [Math]::Round(($totalVMCores / $totalHostCores) * 100, 2) } else { 0 }
            
            Write-Host "`n📊 CAPACITY PLANNING REPORT" -ForegroundColor Green
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "🔧 CURRENT RESOURCE UTILIZATION:" -ForegroundColor Yellow
            Write-Host "  Memory Utilization: $memoryUtilization%" -ForegroundColor White
            Write-Host "  CPU Utilization: $cpuUtilization%" -ForegroundColor White
            Write-Host ""
            Write-Host "📈 CAPACITY ANALYSIS:" -ForegroundColor Yellow
            
            # Memory analysis
            if ($memoryUtilization -gt 85) {
                Write-Host "  • Memory: CRITICAL - Consider adding memory or hosts" -ForegroundColor Red
            } elseif ($memoryUtilization -gt 70) {
                Write-Host "  • Memory: WARNING - Monitor closely" -ForegroundColor Yellow
            } else {
                Write-Host "  • Memory: GOOD - Adequate capacity available" -ForegroundColor Green
            }
            
            # CPU analysis
            if ($cpuUtilization -gt 85) {
                Write-Host "  • CPU: CRITICAL - Consider adding CPU cores or hosts" -ForegroundColor Red
            } elseif ($cpuUtilization -gt 70) {
                Write-Host "  • CPU: WARNING - Monitor closely" -ForegroundColor Yellow
            } else {
                Write-Host "  • CPU: GOOD - Adequate capacity available" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "🎯 RECOMMENDATIONS:" -ForegroundColor Yellow
            
            # Calculate growth projections
            $avgVMMemory = if ($vms.Count -gt 0) { $totalVMMemory / $vms.Count } else { 0 }
            $avgVMCores = if ($vms.Count -gt 0) { $totalVMCores / $vms.Count } else { 0 }
            
            # 20% growth scenario
            $projectedVMs = [Math]::Ceiling($vms.Count * 1.2)
            $additionalVMs = $projectedVMs - $vms.Count
            $projectedMemoryNeeded = $additionalVMs * $avgVMMemory
            $projectedCoresNeeded = $additionalVMs * $avgVMCores
            
            Write-Host "  • For 20% growth ($additionalVMs additional VMs):" -ForegroundColor Cyan
            Write-Host "    - Additional memory needed: $([Math]::Round($projectedMemoryNeeded, 2)) GB" -ForegroundColor White
            Write-Host "    - Additional CPU cores needed: $([Math]::Round($projectedCoresNeeded, 0))" -ForegroundColor White
            
            # Check if current capacity can handle growth
            $futureMemoryUtil = (($totalVMMemory + $projectedMemoryNeeded) / $totalHostMemory) * 100
            $futureCpuUtil = (($totalVMCores + $projectedCoresNeeded) / $totalHostCores) * 100
            
            if ($futureMemoryUtil -gt 85 -or $futureCpuUtil -gt 85) {
                Write-Host "  • RECOMMENDATION: Infrastructure expansion required for projected growth" -ForegroundColor Red
            } else {
                Write-Host "  • RECOMMENDATION: Current infrastructure can support projected growth" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "📅 Report Generated: $(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')" -ForegroundColor Gray
            Write-Host "===========================================" -ForegroundColor Green
            
            # Save capacity planning report
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $reportFile = Join-Path $Global:ReportPath "CapacityPlanning_$timestamp.txt"
            
            $reportContent = @"
HYPER-V CAPACITY PLANNING REPORT
Generated: $(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')

CURRENT RESOURCE UTILIZATION:
• Memory Utilization: $memoryUtilization%
• CPU Utilization: $cpuUtilization%

CAPACITY ANALYSIS:
• Total Host Memory: $([Math]::Round($totalHostMemory, 2)) GB
• Total VM Memory: $([Math]::Round($totalVMMemory, 2)) GB
• Total Host CPU Cores: $totalHostCores
• Total VM CPU Cores: $totalVMCores

GROWTH PROJECTIONS (20% increase):
• Additional VMs needed: $additionalVMs
• Additional memory required: $([Math]::Round($projectedMemoryNeeded, 2)) GB
• Additional CPU cores required: $([Math]::Round($projectedCoresNeeded, 0))
• Projected memory utilization: $([Math]::Round($futureMemoryUtil, 2))%
• Projected CPU utilization: $([Math]::Round($futureCpuUtil, 2))%

RECOMMENDATIONS:
$(if ($futureMemoryUtil -gt 85 -or $futureCpuUtil -gt 85) {
"• Infrastructure expansion required for projected growth
• Consider adding additional Hyper-V hosts
• Plan for memory and CPU upgrades"
} else {
"• Current infrastructure can support projected growth
• Continue monitoring resource utilization
• Plan for future expansion beyond 20% growth"
})

Report generated by Hyper-V Enterprise Deployment Tool v$Global:ScriptVersion
"@
            
            $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
            Write-Host "`nCapacity planning report saved to: $reportFile" -ForegroundColor Cyan
            Write-Log -Message "Capacity planning report generated: $reportFile" -Level "SUCCESS"
            
        } else {
            Write-Host "Unable to collect capacity data. Ensure Hyper-V is properly configured." -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Log -Message "Error generating capacity planning report: $_" -Level "ERROR"
        Write-Host "Error generating report: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-EnvironmentHealthCheck {
    <#
    .SYNOPSIS
        Performs comprehensive environment health check
    #>
    Write-Host "Starting Environment Health Check..." -ForegroundColor Cyan
    Write-Log -Message "Starting environment health check" -Level "INFO"
    
    try {
        Write-Host "`nPerforming comprehensive health assessment..." -ForegroundColor Yellow
        
        $healthReport = @{
            OverallStatus = $true
            Checks = @()
            Timestamp = Get-Date
        }
        
        # Check 1: Hyper-V Service Status
        Write-Host "[1/7] Checking Hyper-V services..." -ForegroundColor Cyan
        $hyperVServices = @("vmms", "nvspwmi", "vmcompute")
        $serviceCheck = @{
            Name = "Hyper-V Services"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        foreach ($serviceName in $hyperVServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {                if ($service.Status -eq "Running") {
                    $serviceCheck.Details += "$serviceName`: Running"
                } else {
                    $serviceCheck.Status = $false
                    $serviceCheck.Issues += "$serviceName service is not running"
                    $healthReport.OverallStatus = $false
                }
            } else {
                $serviceCheck.Status = $false
                $serviceCheck.Issues += "$serviceName service not found"
                $healthReport.OverallStatus = $false
            }
        }
        $healthReport.Checks += $serviceCheck
        
        # Check 2: VM Health
        Write-Host "[2/7] Checking VM health..." -ForegroundColor Cyan
        $vms = Get-VM -ErrorAction SilentlyContinue
        $vmCheck = @{
            Name = "Virtual Machine Health"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        if ($vms) {
            $runningVMs = ($vms | Where-Object { $_.State -eq "Running" }).Count
            $totalVMs = $vms.Count
            $vmCheck.Details += "Total VMs: $totalVMs"
            $vmCheck.Details += "Running VMs: $runningVMs"
            
            # Check for VMs with issues
            $vmIssues = $vms | Where-Object { $_.State -eq "Critical" -or $_.Status -eq "Operating normally" -eq $false }
            if ($vmIssues) {
                $vmCheck.Status = $false
                $vmCheck.Issues += "$($vmIssues.Count) VMs have health issues"
                $healthReport.OverallStatus = $false
            }
        } else {
            $vmCheck.Details += "No VMs found"
        }
        $healthReport.Checks += $vmCheck
        
        # Check 3: Host Resource Health
        Write-Host "[3/7] Checking host resources..." -ForegroundColor Cyan
        $resourceCheck = @{
            Name = "Host Resource Health"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        try {
            $computerInfo = Get-ComputerInfo
            $memoryUsage = [Math]::Round((($computerInfo.TotalPhysicalMemory - $computerInfo.AvailablePhysicalMemory) / $computerInfo.TotalPhysicalMemory) * 100, 2)
            $resourceCheck.Details += "Memory usage: $memoryUsage%"
            
            if ($memoryUsage -gt 90) {
                $resourceCheck.Status = $false
                $resourceCheck.Issues += "High memory usage detected ($memoryUsage%)"
                $healthReport.OverallStatus = $false
            } elseif ($memoryUsage -gt 80) {
                $resourceCheck.Issues += "Warning: Memory usage is high ($memoryUsage%)"
            }
        }
        catch {
            $resourceCheck.Issues += "Unable to collect resource information"
        }
        $healthReport.Checks += $resourceCheck
        
        # Check 4: Virtual Switch Health
        Write-Host "[4/7] Checking virtual switches..." -ForegroundColor Cyan
        $switchCheck = @{
            Name = "Virtual Switch Health"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        $switches = Get-VMSwitch -ErrorAction SilentlyContinue
        if ($switches) {
            $switchCheck.Details += "Virtual switches found: $($switches.Count)"
            foreach ($switch in $switches) {
                if ($switch.SwitchType -eq "External" -and -not $switch.NetAdapterInterfaceDescription) {
                    $switchCheck.Status = $false
                    $switchCheck.Issues += "External switch '$($switch.Name)' has no network adapter"
                    $healthReport.OverallStatus = $false
                }
            }
        } else {
            $switchCheck.Issues += "No virtual switches found"
        }
        $healthReport.Checks += $switchCheck
        
        # Check 5: Storage Health
        Write-Host "[5/7] Checking storage health..." -ForegroundColor Cyan
        $storageCheck = @{
            Name = "Storage Health"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($drive in $drives) {
            $freePercent = [Math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)
            $storageCheck.Details += "Drive $($drive.DeviceID) free space: $freePercent%"
            
            if ($freePercent -lt 10) {
                $storageCheck.Status = $false
                $storageCheck.Issues += "Critical: Drive $($drive.DeviceID) has only $freePercent% free space"
                $healthReport.OverallStatus = $false
            } elseif ($freePercent -lt 20) {
                $storageCheck.Issues += "Warning: Drive $($drive.DeviceID) has only $freePercent% free space"
            }
        }
        $healthReport.Checks += $storageCheck
        
        # Check 6: Network Connectivity
        Write-Host "[6/7] Checking network connectivity..." -ForegroundColor Cyan
        $networkCheck = @{
            Name = "Network Connectivity"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false }
        $networkCheck.Details += "Active physical adapters: $($adapters.Count)"
        
        if ($adapters.Count -eq 0) {
            $networkCheck.Status = $false
            $networkCheck.Issues += "No active physical network adapters found"
            $healthReport.OverallStatus = $false
        }
        $healthReport.Checks += $networkCheck
        
        # Check 7: Event Log Analysis
        Write-Host "[7/7] Analyzing event logs..." -ForegroundColor Cyan
        $eventCheck = @{
            Name = "Event Log Analysis"
            Status = $true
            Details = @()
            Issues = @()
        }
        
        try {
            $recentErrors = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Hyper-V-VMMS/Admin'; Level=2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($recentErrors) {
                $eventCheck.Issues += "$($recentErrors.Count) Hyper-V errors in the last 24 hours"
                if ($recentErrors.Count -gt 5) {
                    $eventCheck.Status = $false
                    $healthReport.OverallStatus = $false
                }
            }
            $eventCheck.Details += "Recent Hyper-V errors: $($recentErrors.Count)"
        }
        catch {
            $eventCheck.Details += "Unable to analyze event logs"
        }
        $healthReport.Checks += $eventCheck
        
        # Display results
        Write-Host "`n🏥 ENVIRONMENT HEALTH CHECK RESULTS" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Overall Status: $(if ($healthReport.OverallStatus) { "✅ HEALTHY" } else { "❌ ISSUES FOUND" })" -ForegroundColor $(if ($healthReport.OverallStatus) { "Green" } else { "Red" })
        Write-Host ""
        
        foreach ($check in $healthReport.Checks) {
            $statusSymbol = if ($check.Status) { "✅" } else { "❌" }
            Write-Host "$statusSymbol $($check.Name)" -ForegroundColor $(if ($check.Status) { "Green" } else { "Red" })
            
            foreach ($detail in $check.Details) {
                Write-Host "   • $detail" -ForegroundColor White
            }
            
            if ($check.Issues.Count -gt 0) {
                foreach ($issue in $check.Issues) {
                    Write-Host "   ⚠️  $issue" -ForegroundColor Yellow
                }
            }
            Write-Host ""
        }
        
        # Save health report
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $Global:ReportPath "HealthCheck_$timestamp.json"
        $healthReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
        
        Write-Host "Health check report saved to: $reportFile" -ForegroundColor Cyan
        Write-Log -Message "Environment health check completed: $reportFile" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error during environment health check: $_" -Level "ERROR"
        Write-Host "Error during health check: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}
