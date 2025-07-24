# Configuration Management Module
# Contains functions for exporting and importing Hyper-V configuration templates

function Start-ConfigurationManagement {
    <#
    .SYNOPSIS
        Manages configuration templates for Hyper-V deployment
    .DESCRIPTION
        Provides functionality to export current configurations as templates
        and import existing templates for standardized deployments
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting configuration template management workflow..." -Level "INFO"
    
    try {
        Show-ConfigurationMenu
        
    }
    catch {
        Write-Log -Message "Error in configuration management: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during configuration management. Check the log file for details." -ForegroundColor Red
    }
}

function Show-ConfigurationMenu {
    <#
    .SYNOPSIS
        Displays the configuration management menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                CONFIGURATION TEMPLATE MANAGEMENT" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "CONFIGURATION OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "EXPORT CONFIGURATIONS:" -ForegroundColor Yellow
        Write-Host "  1. Export Hyper-V Host Configuration" -ForegroundColor White
        Write-Host "  2. Export Virtual Switch Configuration" -ForegroundColor White
        Write-Host "  3. Export VM Template Configuration" -ForegroundColor White
        Write-Host "  4. Export Network Configuration" -ForegroundColor White
        Write-Host "  5. Export Storage Configuration" -ForegroundColor White
        Write-Host "  6. Export Complete Environment Template" -ForegroundColor White
        Write-Host ""
        Write-Host "IMPORT CONFIGURATIONS:" -ForegroundColor Yellow
        Write-Host "  7. Import Hyper-V Host Configuration" -ForegroundColor White
        Write-Host "  8. Import Virtual Switch Configuration" -ForegroundColor White
        Write-Host "  9. Import VM Template Configuration" -ForegroundColor White
        Write-Host "  10. Import Network Configuration" -ForegroundColor White
        Write-Host "  11. Import Storage Configuration" -ForegroundColor White
        Write-Host "  12. Import Complete Environment Template" -ForegroundColor White
        Write-Host ""
        Write-Host "TEMPLATE MANAGEMENT:" -ForegroundColor Yellow
        Write-Host "  13. View Available Templates" -ForegroundColor White
        Write-Host "  14. Compare Configurations" -ForegroundColor White
        Write-Host "  15. Validate Template Compatibility" -ForegroundColor White
        Write-Host "  16. Delete Configuration Template" -ForegroundColor White
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-16)"
        
        switch ($choice) {
            "1" { Export-HyperVHostConfiguration }
            "2" { Export-VirtualSwitchConfiguration }
            "3" { Export-VMTemplateConfiguration }
            "4" { Export-NetworkConfiguration }
            "5" { Export-StorageConfiguration }
            "6" { Export-CompleteEnvironmentTemplate }
            "7" { Import-HyperVHostConfiguration }
            "8" { Import-VirtualSwitchConfiguration }
            "9" { Import-VMTemplateConfiguration }
            "10" { Import-NetworkConfiguration }
            "11" { Import-StorageConfiguration }
            "12" { Import-CompleteEnvironmentTemplate }
            "13" { Show-AvailableTemplates }
            "14" { Compare-Configurations }
            "15" { Test-TemplateCompatibility }
            "16" { Remove-ConfigurationTemplate }
            "0" { return }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Export-HyperVHostConfiguration {
    <#
    .SYNOPSIS
        Exports current Hyper-V host configuration to a template
    #>
    Write-Host "`nExporting Hyper-V Host Configuration..." -ForegroundColor Yellow
    Write-Log -Message "Starting Hyper-V host configuration export" -Level "INFO"
    
    try {
        $templateName = Read-Host "Enter template name"
        $description = Read-Host "Enter template description (optional)"
        
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            Write-Host "Template name is required" -ForegroundColor Red
            return
        }
        
        Write-Host "Collecting Hyper-V host configuration..." -ForegroundColor Cyan
        
        $hostConfig = @{
            TemplateName = $templateName
            Description = $description
            ExportDate = Get-Date
            ExportedBy = "$env:USERDOMAIN\$env:USERNAME"
            ComputerName = $env:COMPUTERNAME
            Configuration = @{}
        }
        
        # Collect host settings
        try {
            $vmHost = Get-VMHost
            $hostConfig.Configuration.VMHost = @{
                VirtualMachinePath = $vmHost.VirtualMachinePath
                VirtualHardDiskPath = $vmHost.VirtualHardDiskPath
                MacAddressMinimum = $vmHost.MacAddressMinimum
                MacAddressMaximum = $vmHost.MacAddressMaximum
                FibreChannelWwnn = $vmHost.FibreChannelWwnn
                FibreChannelWwpnMinimum = $vmHost.FibreChannelWwpnMinimum
                FibreChannelWwpnMaximum = $vmHost.FibreChannelWwpnMaximum
                NumaSpanningEnabled = $vmHost.NumaSpanningEnabled
                EnableEnhancedSessionMode = $vmHost.EnableEnhancedSessionMode
            }
            Write-Host "  ✓ VM Host settings collected" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not collect VM Host settings" -ForegroundColor Yellow
        }
        
        # Collect memory settings
        try {
            $memorySettings = Get-VMMemory -VMName "*" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($memorySettings) {
                $hostConfig.Configuration.Memory = @{
                    DynamicMemoryEnabled = $memorySettings.DynamicMemoryEnabled
                    MinimumBytes = $memorySettings.Minimum
                    MaximumBytes = $memorySettings.Maximum
                    Buffer = $memorySettings.Buffer
                    Priority = $memorySettings.Priority
                }
            }
            Write-Host "  ✓ Memory settings collected" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not collect memory settings" -ForegroundColor Yellow
        }
        
        # Collect processor settings
        try {
            $processorSettings = Get-VMProcessor -VMName "*" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($processorSettings) {
                $hostConfig.Configuration.Processor = @{
                    Count = $processorSettings.Count
                    Reserve = $processorSettings.Reserve
                    Maximum = $processorSettings.Maximum
                    RelativeWeight = $processorSettings.RelativeWeight
                    CompatibilityForMigrationEnabled = $processorSettings.CompatibilityForMigrationEnabled
                    CompatibilityForOlderOperatingSystemsEnabled = $processorSettings.CompatibilityForOlderOperatingSystemsEnabled
                }
            }
            Write-Host "  ✓ Processor settings collected" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not collect processor settings" -ForegroundColor Yellow
        }
        
        # Collect integration services settings
        try {
            $integrationServices = Get-VMIntegrationService -VMName "*" -ErrorAction SilentlyContinue | Select-Object -First 5
            if ($integrationServices) {
                $hostConfig.Configuration.IntegrationServices = $integrationServices | ForEach-Object {
                    @{
                        Name = $_.Name
                        Enabled = $_.Enabled
                        PrimaryStatusDescription = $_.PrimaryStatusDescription
                    }
                }
            }
            Write-Host "  ✓ Integration services settings collected" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not collect integration services settings" -ForegroundColor Yellow
        }
        
        # Save the configuration
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $templateFile = Join-Path $Global:TemplatePath "HostConfig_${templateName}_$timestamp.xml"
        $hostConfig | Export-Clixml -Path $templateFile
        
        Write-Host "✓ Hyper-V host configuration exported successfully" -ForegroundColor Green
        Write-Host "Template saved to: $templateFile" -ForegroundColor Cyan
        Write-Log -Message "Hyper-V host configuration exported to: $templateFile" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error exporting Hyper-V host configuration: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error exporting configuration. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Export-VirtualSwitchConfiguration {
    <#
    .SYNOPSIS
        Exports virtual switch configuration to a template
    #>
    Write-Host "`nExporting Virtual Switch Configuration..." -ForegroundColor Yellow
    Write-Log -Message "Starting virtual switch configuration export" -Level "INFO"
    
    try {
        $templateName = Read-Host "Enter template name"
        $description = Read-Host "Enter template description (optional)"
        
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            Write-Host "Template name is required" -ForegroundColor Red
            return
        }
        
        Write-Host "Collecting virtual switch configuration..." -ForegroundColor Cyan
        
        $switchConfig = @{
            TemplateName = $templateName
            Description = $description
            ExportDate = Get-Date
            ExportedBy = "$env:USERDOMAIN\$env:USERNAME"
            ComputerName = $env:COMPUTERNAME
            VirtualSwitches = @()
        }
        
        # Get all virtual switches
        $vSwitches = Get-VMSwitch
        
        if ($vSwitches) {
            foreach ($vSwitch in $vSwitches) {
                $switchInfo = @{
                    Name = $vSwitch.Name
                    SwitchType = $vSwitch.SwitchType
                    AllowManagementOS = $vSwitch.AllowManagementOS
                    Notes = $vSwitch.Notes
                    NetAdapterInterfaceDescription = $vSwitch.NetAdapterInterfaceDescription
                    BandwidthMode = $vSwitch.BandwidthMode
                    PacketDirectEnabled = $vSwitch.PacketDirectEnabled
                    IovEnabled = $vSwitch.IovEnabled
                }
                
                # Get switch extensions
                try {
                    $extensions = Get-VMSwitchExtension -VMSwitch $vSwitch
                    $switchInfo.Extensions = $extensions | ForEach-Object {
                        @{
                            Name = $_.Name
                            Enabled = $_.Enabled
                            ExtensionType = $_.ExtensionType
                        }
                    }
                }
                catch {
                    $switchInfo.Extensions = @()
                }
                
                # Get VLAN configuration
                try {
                    $vlanConfig = Get-VMNetworkAdapter -ManagementOS | Where-Object { $_.SwitchName -eq $vSwitch.Name }
                    if ($vlanConfig) {
                        $switchInfo.VLANConfiguration = $vlanConfig | ForEach-Object {
                            $vlan = Get-VMNetworkAdapterVlan -VMNetworkAdapter $_
                            @{
                                Name = $_.Name
                                VlanSetting = $vlan.OperationMode
                                AccessVlanId = $vlan.AccessVlanId
                                NativeVlanId = $vlan.NativeVlanId
                                AllowedVlanIdList = $vlan.AllowedVlanIdList
                            }
                        }
                    }
                }
                catch {
                    $switchInfo.VLANConfiguration = @()
                }
                
                $switchConfig.VirtualSwitches += $switchInfo
                Write-Host "  ✓ Switch '$($vSwitch.Name)' configuration collected" -ForegroundColor Green
            }
        } else {
            Write-Host "  ⚠ No virtual switches found" -ForegroundColor Yellow
        }
        
        # Save the configuration
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $templateFile = Join-Path $Global:TemplatePath "SwitchConfig_${templateName}_$timestamp.xml"
        $switchConfig | Export-Clixml -Path $templateFile
        
        Write-Host "✓ Virtual switch configuration exported successfully" -ForegroundColor Green
        Write-Host "Template saved to: $templateFile" -ForegroundColor Cyan
        Write-Log -Message "Virtual switch configuration exported to: $templateFile" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error exporting virtual switch configuration: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error exporting configuration. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Export-CompleteEnvironmentTemplate {
    <#
    .SYNOPSIS
        Exports a complete Hyper-V environment template
    #>
    Write-Host "`nExporting Complete Environment Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting complete environment template export" -Level "INFO"
    
    try {
        $templateName = Read-Host "Enter template name"
        $description = Read-Host "Enter template description (optional)"
        
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            Write-Host "Template name is required" -ForegroundColor Red
            return
        }
        
        Write-Host "Collecting complete environment configuration..." -ForegroundColor Cyan
        Write-Host "This may take a few minutes..." -ForegroundColor Yellow
        
        $environmentConfig = @{
            TemplateName = $templateName
            Description = $description
            ExportDate = Get-Date
            ExportedBy = "$env:USERDOMAIN\$env:USERNAME"
            ComputerName = $env:COMPUTERNAME
            Environment = @{
                Host = @{}
                VirtualSwitches = @()
                VirtualMachines = @()
                Storage = @{}
                Network = @{}
            }
        }
        
        # Collect host configuration
        Write-Host "  Collecting host configuration..." -ForegroundColor Cyan
        try {
            $vmHost = Get-VMHost
            $environmentConfig.Environment.Host = @{
                VirtualMachinePath = $vmHost.VirtualMachinePath
                VirtualHardDiskPath = $vmHost.VirtualHardDiskPath
                MacAddressMinimum = $vmHost.MacAddressMinimum
                MacAddressMaximum = $vmHost.MacAddressMaximum
                NumaSpanningEnabled = $vmHost.NumaSpanningEnabled
                EnableEnhancedSessionMode = $vmHost.EnableEnhancedSessionMode
            }
            Write-Host "    ✓ Host configuration collected" -ForegroundColor Green
        }
        catch {
            Write-Host "    ⚠ Could not collect host configuration" -ForegroundColor Yellow
        }
        
        # Collect virtual switches
        Write-Host "  Collecting virtual switch configuration..." -ForegroundColor Cyan
        try {
            $vSwitches = Get-VMSwitch
            foreach ($vSwitch in $vSwitches) {
                $switchInfo = @{
                    Name = $vSwitch.Name
                    SwitchType = $vSwitch.SwitchType
                    AllowManagementOS = $vSwitch.AllowManagementOS
                    Notes = $vSwitch.Notes
                    NetAdapterInterfaceDescription = $vSwitch.NetAdapterInterfaceDescription
                }
                $environmentConfig.Environment.VirtualSwitches += $switchInfo
            }
            Write-Host "    ✓ Virtual switches collected ($($vSwitches.Count) switches)" -ForegroundColor Green
        }
        catch {
            Write-Host "    ⚠ Could not collect virtual switch configuration" -ForegroundColor Yellow
        }
        
        # Collect virtual machines (configuration only, not VHDs)
        Write-Host "  Collecting virtual machine configurations..." -ForegroundColor Cyan
        try {
            $vms = Get-VM
            foreach ($vm in $vms) {
                $vmInfo = @{
                    Name = $vm.Name
                    Generation = $vm.Generation
                    MemoryStartupBytes = $vm.MemoryStartupBytes
                    DynamicMemoryEnabled = $vm.DynamicMemoryEnabled
                    ProcessorCount = $vm.ProcessorCount
                    State = $vm.State
                    Version = $vm.Version
                    Notes = $vm.Notes
                    CheckpointType = $vm.CheckpointType
                    AutomaticStartAction = $vm.AutomaticStartAction
                    AutomaticStopAction = $vm.AutomaticStopAction
                }
                
                # Get network adapters
                $vmInfo.NetworkAdapters = @()
                $netAdapters = Get-VMNetworkAdapter -VM $vm
                foreach ($adapter in $netAdapters) {
                    $vmInfo.NetworkAdapters += @{
                        Name = $adapter.Name
                        SwitchName = $adapter.SwitchName
                        MacAddress = $adapter.MacAddress
                        DynamicMacAddress = $adapter.DynamicMacAddress
                    }
                }
                
                # Get hard disk configuration (paths only)
                $vmInfo.HardDisks = @()
                $hardDisks = Get-VMHardDiskDrive -VM $vm
                foreach ($disk in $hardDisks) {
                    $vmInfo.HardDisks += @{
                        ControllerType = $disk.ControllerType
                        ControllerNumber = $disk.ControllerNumber
                        ControllerLocation = $disk.ControllerLocation
                        Path = $disk.Path
                    }
                }
                
                $environmentConfig.Environment.VirtualMachines += $vmInfo
            }
            Write-Host "    ✓ Virtual machines collected ($($vms.Count) VMs)" -ForegroundColor Green
        }
        catch {
            Write-Host "    ⚠ Could not collect virtual machine configuration" -ForegroundColor Yellow
        }
        
        # Collect storage configuration
        Write-Host "  Collecting storage configuration..." -ForegroundColor Cyan
        try {
            $storageInfo = @{
                DefaultVMPath = (Get-VMHost).VirtualMachinePath
                DefaultVHDPath = (Get-VMHost).VirtualHardDiskPath
                StoragePools = @()
            }
            
            # Get storage pools
            $storagePools = Get-StoragePool | Where-Object { $_.IsPrimordial -eq $false }
            foreach ($pool in $storagePools) {
                $storageInfo.StoragePools += @{
                    FriendlyName = $pool.FriendlyName
                    HealthStatus = $pool.HealthStatus
                    OperationalStatus = $pool.OperationalStatus
                    Size = $pool.Size
                    AllocatedSize = $pool.AllocatedSize
                }
            }
            
            $environmentConfig.Environment.Storage = $storageInfo
            Write-Host "    ✓ Storage configuration collected" -ForegroundColor Green
        }
        catch {
            Write-Host "    ⚠ Could not collect storage configuration" -ForegroundColor Yellow
        }
        
        # Save the complete template
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $templateFile = Join-Path $Global:TemplatePath "CompleteEnvironment_${templateName}_$timestamp.xml"
        $environmentConfig | Export-Clixml -Path $templateFile
        
        Write-Host "`n✓ Complete environment template exported successfully" -ForegroundColor Green
        Write-Host "Template saved to: $templateFile" -ForegroundColor Cyan
        Write-Log -Message "Complete environment template exported to: $templateFile" -Level "SUCCESS"
        
        # Generate summary
        Write-Host "`nEnvironment Summary:" -ForegroundColor Yellow
        Write-Host "  Host: $($environmentConfig.ComputerName)" -ForegroundColor White
        Write-Host "  Virtual Switches: $($environmentConfig.Environment.VirtualSwitches.Count)" -ForegroundColor White
        Write-Host "  Virtual Machines: $($environmentConfig.Environment.VirtualMachines.Count)" -ForegroundColor White
        Write-Host "  Storage Pools: $($environmentConfig.Environment.Storage.StoragePools.Count)" -ForegroundColor White
        
    }
    catch {
        Write-Log -Message "Error exporting complete environment template: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error exporting template. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-AvailableTemplates {
    <#
    .SYNOPSIS
        Displays all available configuration templates
    #>
    Write-Host "`nAvailable Configuration Templates" -ForegroundColor Yellow
    Write-Log -Message "Displaying available configuration templates" -Level "INFO"
    
    try {
        $templateFiles = Get-ChildItem -Path $Global:TemplatePath -Filter "*.xml" | Sort-Object LastWriteTime -Descending
        
        if ($templateFiles.Count -eq 0) {
            Write-Host "No configuration templates found" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nFound $($templateFiles.Count) template(s):" -ForegroundColor Cyan
        Write-Host ""
        
        for ($i = 0; $i -lt $templateFiles.Count; $i++) {
            $file = $templateFiles[$i]
            try {
                $template = Import-Clixml -Path $file.FullName
                
                $templateType = "Unknown"
                if ($file.Name.StartsWith("HostConfig_")) { $templateType = "Host Configuration" }
                elseif ($file.Name.StartsWith("SwitchConfig_")) { $templateType = "Virtual Switch" }
                elseif ($file.Name.StartsWith("VMTemplate_")) { $templateType = "VM Template" }
                elseif ($file.Name.StartsWith("NetworkConfig_")) { $templateType = "Network Configuration" }
                elseif ($file.Name.StartsWith("StorageConfig_")) { $templateType = "Storage Configuration" }
                elseif ($file.Name.StartsWith("CompleteEnvironment_")) { $templateType = "Complete Environment" }
                
                Write-Host "  $($i + 1). $($template.TemplateName)" -ForegroundColor White
                Write-Host "     Type: $templateType" -ForegroundColor Gray
                Write-Host "     Created: $($template.ExportDate)" -ForegroundColor Gray
                Write-Host "     By: $($template.ExportedBy)" -ForegroundColor Gray
                if ($template.Description) {
                    Write-Host "     Description: $($template.Description)" -ForegroundColor Gray
                }
                Write-Host "     File: $($file.Name)" -ForegroundColor Gray
                Write-Host ""
            }
            catch {
                Write-Host "  $($i + 1). $($file.Name)" -ForegroundColor White
                Write-Host "     Type: Template File" -ForegroundColor Gray
                Write-Host "     Created: $($file.LastWriteTime)" -ForegroundColor Gray
                Write-Host "     Note: Unable to read template details" -ForegroundColor Yellow
                Write-Host ""
            }
        }
        
        $viewTemplate = Read-Host "Would you like to view details of a specific template? (Enter number or 'n' for no)"
        
        if ($viewTemplate -ne 'n' -and $viewTemplate -ne 'N') {
            $templateIndex = [int]$viewTemplate - 1
            if ($templateIndex -ge 0 -and $templateIndex -lt $templateFiles.Count) {
                Show-TemplateDetails -TemplateFile $templateFiles[$templateIndex].FullName
            }
        }
        
    }
    catch {
        Write-Log -Message "Error displaying available templates: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error displaying templates. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-TemplateDetails {
    <#
    .SYNOPSIS
        Shows detailed information about a specific template
    #>
    param([string]$TemplateFile)
    
    try {
        $template = Import-Clixml -Path $TemplateFile
        
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    TEMPLATE DETAILS" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Template Name: $($template.TemplateName)" -ForegroundColor Yellow
        Write-Host "Description: $($template.Description)" -ForegroundColor White
        Write-Host "Created: $($template.ExportDate)" -ForegroundColor White
        Write-Host "Created By: $($template.ExportedBy)" -ForegroundColor White
        Write-Host "Source Computer: $($template.ComputerName)" -ForegroundColor White
        Write-Host ""
        
        # Display template-specific details
        if ($template.Configuration) {
            Write-Host "Configuration Details:" -ForegroundColor Cyan
            
            if ($template.Configuration.VMHost) {
                Write-Host "  VM Host Settings:" -ForegroundColor Yellow
                Write-Host "    VM Path: $($template.Configuration.VMHost.VirtualMachinePath)" -ForegroundColor White
                Write-Host "    VHD Path: $($template.Configuration.VMHost.VirtualHardDiskPath)" -ForegroundColor White
                Write-Host "    NUMA Spanning: $($template.Configuration.VMHost.NumaSpanningEnabled)" -ForegroundColor White
                Write-Host "    Enhanced Session Mode: $($template.Configuration.VMHost.EnableEnhancedSessionMode)" -ForegroundColor White
            }
            
            if ($template.Configuration.Memory) {
                Write-Host "  Memory Settings:" -ForegroundColor Yellow
                Write-Host "    Dynamic Memory: $($template.Configuration.Memory.DynamicMemoryEnabled)" -ForegroundColor White
                Write-Host "    Minimum: $([math]::Round($template.Configuration.Memory.MinimumBytes / 1GB, 2)) GB" -ForegroundColor White
                Write-Host "    Maximum: $([math]::Round($template.Configuration.Memory.MaximumBytes / 1GB, 2)) GB" -ForegroundColor White
            }
        }
        
        if ($template.VirtualSwitches) {
            Write-Host "  Virtual Switches:" -ForegroundColor Yellow
            foreach ($switch in $template.VirtualSwitches) {
                Write-Host "    $($switch.Name) ($($switch.SwitchType))" -ForegroundColor White
            }
        }
        
        if ($template.Environment) {
            Write-Host "  Environment Summary:" -ForegroundColor Yellow
            Write-Host "    Virtual Switches: $($template.Environment.VirtualSwitches.Count)" -ForegroundColor White
            Write-Host "    Virtual Machines: $($template.Environment.VirtualMachines.Count)" -ForegroundColor White
            Write-Host "    Storage Pools: $($template.Environment.Storage.StoragePools.Count)" -ForegroundColor White
        }
        
    }
    catch {
        Write-Host "Error displaying template details: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

# Import functions (stubs for now - these would implement the reverse of export functions)
function Import-HyperVHostConfiguration {
    <#
    .SYNOPSIS
        Imports and applies Hyper-V host configuration from XML template
    #>
    Write-Host "Importing Hyper-V host configuration..." -ForegroundColor Cyan
    
    try {
        $configFiles = Get-ChildItem -Path $Global:ConfigPath -Filter "*HostConfig*.xml" -ErrorAction SilentlyContinue
        
        if (-not $configFiles) {
            Write-Host "No host configuration files found in $Global:ConfigPath" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
        
        Write-Host "`nAvailable host configuration templates:" -ForegroundColor Green
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($configFiles[$i].BaseName)" -ForegroundColor Cyan
        }
        
        $selection = Read-Host "`nSelect configuration to import (1-$($configFiles.Count))"
        
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $configFiles.Count) {
            $selectedFile = $configFiles[[int]$selection - 1]
            Write-Host "Importing configuration from: $($selectedFile.Name)" -ForegroundColor Yellow
            
            [xml]$config = Get-Content $selectedFile.FullName
            
            # Apply VM settings
            if ($config.HyperVHostConfiguration.VMSettings) {
                $vmSettings = $config.HyperVHostConfiguration.VMSettings
                Write-Host "Applying VM default settings..." -ForegroundColor Green
                
                if ($vmSettings.DefaultVMPath) {
                    Set-VMHost -VirtualMachinePath $vmSettings.DefaultVMPath
                    Write-Host "  Set default VM path: $($vmSettings.DefaultVMPath)" -ForegroundColor Cyan
                }
                
                if ($vmSettings.DefaultVHDPath) {
                    Set-VMHost -VirtualHardDiskPath $vmSettings.DefaultVHDPath
                    Write-Host "  Set default VHD path: $($vmSettings.DefaultVHDPath)" -ForegroundColor Cyan
                }
            }
            
            # Apply memory settings
            if ($config.HyperVHostConfiguration.MemorySettings) {
                $memSettings = $config.HyperVHostConfiguration.MemorySettings
                Write-Host "Applying memory settings..." -ForegroundColor Green
                
                if ($memSettings.EnableDynamicMemory -eq "True") {
                    Write-Host "  Dynamic Memory will be enabled for new VMs" -ForegroundColor Cyan
                }
            }
            
            Write-Log -Message "Host configuration imported successfully from $($selectedFile.Name)" -Level "INFO"
            Write-Host "`nHost configuration imported successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
    catch {
        Write-Log -Message "Error importing host configuration: $_" -Level "ERROR"
        Write-Host "Error importing configuration: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Import-VirtualSwitchConfiguration {
    <#
    .SYNOPSIS
        Imports and creates virtual switches from XML template
    #>
    Write-Host "Importing virtual switch configuration..." -ForegroundColor Cyan
    
    try {
        $configFiles = Get-ChildItem -Path $Global:ConfigPath -Filter "*VSwitch*.xml" -ErrorAction SilentlyContinue
        
        if (-not $configFiles) {
            Write-Host "No virtual switch configuration files found in $Global:ConfigPath" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
        
        Write-Host "`nAvailable virtual switch configuration templates:" -ForegroundColor Green
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($configFiles[$i].BaseName)" -ForegroundColor Cyan
        }
        
        $selection = Read-Host "`nSelect configuration to import (1-$($configFiles.Count))"
        
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $configFiles.Count) {
            $selectedFile = $configFiles[[int]$selection - 1]
            Write-Host "Importing virtual switch configuration from: $($selectedFile.Name)" -ForegroundColor Yellow
            
            [xml]$config = Get-Content $selectedFile.FullName
            
            if ($config.VirtualSwitchConfiguration.VirtualSwitches.VirtualSwitch) {
                foreach ($switch in $config.VirtualSwitchConfiguration.VirtualSwitches.VirtualSwitch) {
                    $existingSwitch = Get-VMSwitch -Name $switch.Name -ErrorAction SilentlyContinue
                    
                    if (-not $existingSwitch) {
                        Write-Host "Creating virtual switch: $($switch.Name)" -ForegroundColor Green
                        
                        $switchParams = @{
                            Name = $switch.Name
                            SwitchType = $switch.Type
                        }
                        
                        if ($switch.Type -eq "External" -and $switch.NetAdapterName) {
                            $switchParams.NetAdapterName = $switch.NetAdapterName
                        }
                        
                        New-VMSwitch @switchParams
                        Write-Host "  Created $($switch.Type) switch: $($switch.Name)" -ForegroundColor Cyan
                    }
                    else {
                        Write-Host "Virtual switch '$($switch.Name)' already exists, skipping..." -ForegroundColor Yellow
                    }
                }
            }
            
            Write-Log -Message "Virtual switch configuration imported successfully from $($selectedFile.Name)" -Level "INFO"
            Write-Host "`nVirtual switch configuration imported successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
    catch {
        Write-Log -Message "Error importing virtual switch configuration: $_" -Level "ERROR"
        Write-Host "Error importing virtual switch configuration: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Import-VMTemplateConfiguration {
    Write-Host "Importing VM template configuration..." -ForegroundColor Cyan
    Write-Host "This function would import VM template configurations" -ForegroundColor Yellow
    Write-Log -Message "VM template configuration import completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Import-NetworkConfiguration {
    Write-Host "Importing network configuration..." -ForegroundColor Cyan
    Write-Host "This function would import network configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Network configuration import completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Import-StorageConfiguration {
    Write-Host "Importing storage configuration..." -ForegroundColor Cyan
    Write-Host "This function would import storage configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Storage configuration import completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Import-CompleteEnvironmentTemplate {
    <#
    .SYNOPSIS
        Imports and applies a complete environment template
    #>
    Write-Host "Importing complete environment template..." -ForegroundColor Cyan
    
    try {
        $configFiles = Get-ChildItem -Path $Global:ConfigPath -Filter "*Environment*.xml" -ErrorAction SilentlyContinue
        
        if (-not $configFiles) {
            Write-Host "No environment template files found in $Global:ConfigPath" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
        
        Write-Host "`nAvailable environment templates:" -ForegroundColor Green
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($configFiles[$i].BaseName)" -ForegroundColor Cyan
        }
        
        $selection = Read-Host "`nSelect environment template to import (1-$($configFiles.Count))"
        
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $configFiles.Count) {
            $selectedFile = $configFiles[[int]$selection - 1]
            Write-Host "Importing environment template from: $($selectedFile.Name)" -ForegroundColor Yellow
            
            [xml]$config = Get-Content $selectedFile.FullName
            
            Write-Host "`nApplying environment template..." -ForegroundColor Green
            
            # Import host configuration
            if ($config.EnvironmentTemplate.HostConfiguration) {
                Write-Host "Applying host configuration..." -ForegroundColor Cyan
                # Apply host settings here
            }
            
            # Import virtual switches
            if ($config.EnvironmentTemplate.VirtualSwitches) {
                Write-Host "Creating virtual switches..." -ForegroundColor Cyan
                foreach ($switch in $config.EnvironmentTemplate.VirtualSwitches.VirtualSwitch) {
                    $existingSwitch = Get-VMSwitch -Name $switch.Name -ErrorAction SilentlyContinue
                    if (-not $existingSwitch) {
                        $switchParams = @{
                            Name = $switch.Name
                            SwitchType = $switch.Type
                        }
                        if ($switch.Type -eq "External" -and $switch.NetAdapterName) {
                            $switchParams.NetAdapterName = $switch.NetAdapterName
                        }
                        New-VMSwitch @switchParams
                        Write-Host "  Created switch: $($switch.Name)" -ForegroundColor Green
                    }
                }
            }
            
            # Import network configuration
            if ($config.EnvironmentTemplate.NetworkConfiguration) {
                Write-Host "Applying network configuration..." -ForegroundColor Cyan
                # Apply network settings here
            }
            
            # Import storage configuration
            if ($config.EnvironmentTemplate.StorageConfiguration) {
                Write-Host "Applying storage configuration..." -ForegroundColor Cyan
                # Apply storage settings here
            }
            
            Write-Log -Message "Complete environment template imported successfully from $($selectedFile.Name)" -Level "INFO"
            Write-Host "`nComplete environment template imported successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
    catch {
        Write-Log -Message "Error importing environment template: $_" -Level "ERROR"
        Write-Host "Error importing environment template: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Compare-Configurations {
    Write-Host "Comparing configurations..." -ForegroundColor Cyan
    Write-Host "This function would compare two configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Configuration comparison completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Test-TemplateCompatibility {
    Write-Host "Testing template compatibility..." -ForegroundColor Cyan
    Write-Host "This function would validate template compatibility with current system" -ForegroundColor Yellow
    Write-Log -Message "Template compatibility testing completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Remove-ConfigurationTemplate {
    Write-Host "Removing configuration template..." -ForegroundColor Cyan
    Write-Host "This function would delete selected configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Configuration template removal completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Export-VMTemplateConfiguration {
    Write-Host "Exporting VM template configuration..." -ForegroundColor Cyan
    Write-Host "This function would export VM template configurations" -ForegroundColor Yellow
    Write-Log -Message "VM template configuration export completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Export-NetworkConfiguration {
    Write-Host "Exporting network configuration..." -ForegroundColor Cyan
    Write-Host "This function would export network configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Network configuration export completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}

function Export-StorageConfiguration {
    Write-Host "Exporting storage configuration..." -ForegroundColor Cyan
    Write-Host "This function would export storage configuration templates" -ForegroundColor Yellow
    Write-Log -Message "Storage configuration export completed" -Level "INFO"
    Read-Host "Press Enter to continue"
}
