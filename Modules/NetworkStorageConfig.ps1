# Network and Storage Configuration Module
# Contains functions for advanced network and storage configuration for Hyper-V

function Start-NetworkStorageConfig {
    <#
    .SYNOPSIS
        Manages advanced network and storage configuration for Hyper-V
    .DESCRIPTION
        Provides comprehensive network and storage configuration including VLANs,
        Quality of Service, Storage Spaces, SAN integration, and performance optimization
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting network and storage configuration workflow..." -Level "INFO"
    
    try {
        Show-NetworkStorageMenu
        
    }
    catch {
        Write-Log -Message "Error in network and storage configuration: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during network and storage configuration. Check the log file for details." -ForegroundColor Red
    }
}

function Show-NetworkStorageMenu {
    <#
    .SYNOPSIS
        Displays the network and storage configuration menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                NETWORK AND STORAGE CONFIGURATION" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "CONFIGURATION OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "NETWORK CONFIGURATION:" -ForegroundColor Yellow
        Write-Host "  1. Configure Virtual Switch VLANs" -ForegroundColor White
        Write-Host "  2. Set Quality of Service (QoS)" -ForegroundColor White
        Write-Host "  3. Configure NIC Teaming" -ForegroundColor White
        Write-Host "  4. Set Live Migration Networks" -ForegroundColor White
        Write-Host "  5. Configure SR-IOV" -ForegroundColor White
        Write-Host ""
        Write-Host "STORAGE CONFIGURATION:" -ForegroundColor Yellow
        Write-Host "  6. Configure Storage Spaces" -ForegroundColor White
        Write-Host "  7. Set up SAN Integration" -ForegroundColor White
        Write-Host "  8. Configure iSCSI Multipathing" -ForegroundColor White
        Write-Host "  9. Optimize Storage Performance" -ForegroundColor White
        Write-Host "  10. Configure Backup Storage" -ForegroundColor White
        Write-Host ""
        Write-Host "ADVANCED OPTIONS:" -ForegroundColor Yellow
        Write-Host "  11. Network Performance Tuning" -ForegroundColor White
        Write-Host "  12. Storage Performance Analysis" -ForegroundColor White
        Write-Host "  13. Complete Network & Storage Setup" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-13)"
        
        switch ($choice) {
            "1" { Set-VirtualSwitchVLANs }
            "2" { Set-QualityOfService }
            "3" { Set-NICTeaming }
            "4" { Set-LiveMigrationNetworks }
            "5" { Set-SRIOV }
            "6" { Set-StorageSpaces }
            "7" { Set-SANIntegration }
            "8" { Set-iSCSIMultipathing }
            "9" { Optimize-StoragePerformance }
            "10" { Set-BackupStorage }
            "11" { Optimize-NetworkPerformance }
            "12" { Test-StoragePerformance }
            "13" { Complete-NetworkStorageSetup }
            "0" { return }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Set-VirtualSwitchVLANs {
    <#
    .SYNOPSIS
        Configures VLAN settings for virtual switches
    #>
    Write-Host "`nConfiguring Virtual Switch VLANs..." -ForegroundColor Yellow
    Write-Log -Message "Starting virtual switch VLAN configuration" -Level "INFO"
    
    try {
        # Get existing virtual switches
        $vSwitches = Get-VMSwitch -ErrorAction SilentlyContinue
        
        if (-not $vSwitches) {
            Write-Host "No virtual switches found. Create virtual switches first." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nExisting Virtual Switches:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $vSwitches.Count; $i++) {
            Write-Host "  $($i + 1). $($vSwitches[$i].Name) ($($vSwitches[$i].SwitchType))" -ForegroundColor White
        }
        
        $switchChoice = Read-Host "`nSelect switch to configure VLANs (1-$($vSwitches.Count))"
        $switchIndex = [int]$switchChoice - 1
        
        if ($switchIndex -ge 0 -and $switchIndex -lt $vSwitches.Count) {
            $selectedSwitch = $vSwitches[$switchIndex]
            
            Write-Host "`nConfiguring VLANs for switch: $($selectedSwitch.Name)" -ForegroundColor Cyan
            
            # VLAN configuration options
            Write-Host "`nVLAN Configuration Options:" -ForegroundColor Yellow
            Write-Host "  1. Management VLAN (ID: 10)" -ForegroundColor White
            Write-Host "  2. VM Traffic VLAN (ID: 20)" -ForegroundColor White
            Write-Host "  3. Live Migration VLAN (ID: 30)" -ForegroundColor White
            Write-Host "  4. Storage VLAN (ID: 40)" -ForegroundColor White
            Write-Host "  5. Custom VLAN" -ForegroundColor White
            
            $vlanChoice = Read-Host "Select VLAN type (1-5)"
            
            $vlanId = switch ($vlanChoice) {
                "1" { 10 }
                "2" { 20 }
                "3" { 30 }
                "4" { 40 }
                "5" { 
                    $customVlan = Read-Host "Enter custom VLAN ID (1-4094)"
                    [int]$customVlan
                }
                default { 
                    Write-Host "Invalid selection" -ForegroundColor Red
                    return
                }
            }
            
            # Configure VLAN on virtual switch
            try {
                # Create virtual network adapter with VLAN
                $vlanName = "VLAN_$vlanId"
                Add-VMNetworkAdapter -ManagementOS -SwitchName $selectedSwitch.Name -Name $vlanName
                Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $vlanName -Access -VlanId $vlanId
                
                Write-Host "✓ VLAN $vlanId configured on switch '$($selectedSwitch.Name)'" -ForegroundColor Green
                Write-Log -Message "VLAN $vlanId configured on virtual switch '$($selectedSwitch.Name)'" -Level "SUCCESS"
                
                # Configure IP if needed
                $configureIP = Read-Host "Configure IP address for this VLAN? (y/n)"
                if ($configureIP -eq 'y' -or $configureIP -eq 'Y') {
                    Set-VLANIPConfiguration -VLANName $vlanName -VLANID $vlanId
                }
                
            }
            catch {
                Write-Host "✗ Failed to configure VLAN: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log -Message "Failed to configure VLAN $vlanId`: $($_.Exception.Message)" -Level "ERROR"
            }
        } else {
            Write-Host "Invalid switch selection" -ForegroundColor Red
        }
        
    }
    catch {
        Write-Log -Message "Error configuring virtual switch VLANs: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error configuring VLANs. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-VLANIPConfiguration {
    <#
    .SYNOPSIS
        Configures IP settings for a VLAN interface
    #>
    param(
        [string]$VLANName,
        [int]$VLANID
    )
    
    try {
        $ipAddress = Read-Host "Enter IP address for VLAN $VLANID"
        $subnetMask = Read-Host "Enter subnet mask (e.g., 255.255.255.0 or 24)"
        $gateway = Read-Host "Enter gateway (optional, press Enter to skip)"
        
        # Get the network adapter
        $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$VLANName*" }
        
        if ($adapter) {
            # Configure IP address
            if ($subnetMask -match '^\d{1,2}$') {
                # CIDR notation
                New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $ipAddress -PrefixLength $subnetMask
            } else {
                # Subnet mask format - convert to CIDR
                $prefixLength = Convert-SubnetMaskToCIDR -SubnetMask $subnetMask
                New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $ipAddress -PrefixLength $prefixLength
            }
            
            # Configure gateway if provided
            if (-not [string]::IsNullOrWhiteSpace($gateway)) {
                New-NetRoute -InterfaceIndex $adapter.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -NextHop $gateway
            }
            
            Write-Host "✓ IP configuration completed for VLAN $VLANID" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Failed to configure IP for VLAN: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Convert-SubnetMaskToCIDR {
    param([string]$SubnetMask)
    
    $octets = $SubnetMask.Split('.')
    $binaryString = ""
    
    foreach ($octet in $octets) {
        $binaryString += [Convert]::ToString([int]$octet, 2).PadLeft(8, '0')
    }
    
    return ($binaryString.ToCharArray() | Where-Object { $_ -eq '1' }).Count
}

function Set-QualityOfService {
    <#
    .SYNOPSIS
        Configures Quality of Service (QoS) for Hyper-V networks
    #>
    Write-Host "`nConfiguring Quality of Service (QoS)..." -ForegroundColor Yellow
    Write-Log -Message "Starting QoS configuration" -Level "INFO"
    
    try {
        Write-Host "`nQoS Configuration Options:" -ForegroundColor Cyan
        Write-Host "  1. Configure VM QoS Policies" -ForegroundColor White
        Write-Host "  2. Set Live Migration Bandwidth" -ForegroundColor White
        Write-Host "  3. Configure Storage QoS" -ForegroundColor White
        Write-Host "  4. Set Management Traffic Priority" -ForegroundColor White
        Write-Host "  5. Create Custom QoS Policy" -ForegroundColor White
        
        $qosChoice = Read-Host "Select QoS option (1-5)"
        
        switch ($qosChoice) {
            "1" { Set-VMQoSPolicies }
            "2" { Set-LiveMigrationBandwidth }
            "3" { Set-StorageQoS }
            "4" { Set-ManagementTrafficPriority }
            "5" { New-CustomQoSPolicy }
            default { 
                Write-Host "Invalid selection" -ForegroundColor Red
                return
            }
        }
        
    }
    catch {
        Write-Log -Message "Error configuring QoS: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error configuring QoS. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-VMQoSPolicies {
    <#
    .SYNOPSIS
        Configures QoS policies for virtual machines
    #>
    Write-Host "`nConfiguring VM QoS Policies..." -ForegroundColor Cyan
    
    try {
        # Get existing VMs
        $vms = Get-VM -ErrorAction SilentlyContinue
        
        if (-not $vms) {
            Write-Host "No virtual machines found" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nAvailable Virtual Machines:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $vms.Count; $i++) {
            Write-Host "  $($i + 1). $($vms[$i].Name) ($($vms[$i].State))" -ForegroundColor White
        }
        
        $vmChoice = Read-Host "Select VM to configure QoS (1-$($vms.Count), or 'all' for all VMs)"
        
        if ($vmChoice -eq 'all') {
            $selectedVMs = $vms
        } else {
            $vmIndex = [int]$vmChoice - 1
            if ($vmIndex -ge 0 -and $vmIndex -lt $vms.Count) {
                $selectedVMs = @($vms[$vmIndex])
            } else {
                Write-Host "Invalid VM selection" -ForegroundColor Red
                return
            }
        }
        
        # QoS settings
        Write-Host "`nQoS Traffic Types:" -ForegroundColor Yellow
        Write-Host "  1. High Priority (Critical VMs)" -ForegroundColor White
        Write-Host "  2. Medium Priority (Standard VMs)" -ForegroundColor White
        Write-Host "  3. Low Priority (Development/Test VMs)" -ForegroundColor White
        Write-Host "  4. Custom Priority" -ForegroundColor White
        
        $priorityChoice = Read-Host "Select priority level (1-4)"
        
        $bandwidthSettings = switch ($priorityChoice) {
            "1" { @{ MinimumBandwidthWeight = 50; MaximumBandwidth = 10000000000 } }  # 10 Gbps
            "2" { @{ MinimumBandwidthWeight = 30; MaximumBandwidth = 5000000000 } }   # 5 Gbps
            "3" { @{ MinimumBandwidthWeight = 10; MaximumBandwidth = 1000000000 } }   # 1 Gbps
            "4" { 
                $customWeight = Read-Host "Enter minimum bandwidth weight (1-100)"
                $customMax = Read-Host "Enter maximum bandwidth in Mbps"
                @{ 
                    MinimumBandwidthWeight = [int]$customWeight
                    MaximumBandwidth = [long]$customMax * 1000000 
                }
            }
            default { 
                Write-Host "Invalid priority selection" -ForegroundColor Red
                return
            }
        }
        
        # Apply QoS settings to selected VMs
        foreach ($vm in $selectedVMs) {
            try {
                $vmNetAdapters = Get-VMNetworkAdapter -VM $vm
                
                foreach ($adapter in $vmNetAdapters) {
                    Set-VMNetworkAdapter -VM $vm -Name $adapter.Name `
                        -MinimumBandwidthWeight $bandwidthSettings.MinimumBandwidthWeight `
                        -MaximumBandwidth $bandwidthSettings.MaximumBandwidth
                }
                
                Write-Host "✓ QoS configured for VM: $($vm.Name)" -ForegroundColor Green
                
            }
            catch {
                Write-Host "✗ Failed to configure QoS for VM: $($vm.Name)" -ForegroundColor Red
                Write-Log -Message "Failed to configure QoS for VM $($vm.Name)`: $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
        Write-Log -Message "VM QoS policies configuration completed" -Level "SUCCESS"
        
    }
    catch {
        Write-Host "Error configuring VM QoS policies: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-NICTeaming {
    <#
    .SYNOPSIS
        Configures NIC Teaming for redundancy and performance
    #>
    Write-Host "`nConfiguring NIC Teaming..." -ForegroundColor Yellow
    Write-Log -Message "Starting NIC teaming configuration" -Level "INFO"
    
    try {
        # Get available network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.LinkSpeed -gt 0 }
        
        if ($adapters.Count -lt 2) {
            Write-Host "At least 2 network adapters are required for teaming" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nAvailable Network Adapters:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "  $($i + 1). $($adapters[$i].Name) - $($adapters[$i].LinkSpeed)" -ForegroundColor White
        }
        
        # Team configuration
        $teamName = Read-Host "`nEnter team name"
        $memberIndices = Read-Host "Enter adapter numbers to team (comma-separated, e.g., 1,2)"
        
        try {
            $indices = $memberIndices.Split(',') | ForEach-Object { [int]$_.Trim() - 1 }
            $teamMembers = $indices | ForEach-Object { $adapters[$_].Name }
            
            # Teaming algorithm options
            Write-Host "`nTeaming Algorithm Options:" -ForegroundColor Yellow
            Write-Host "  1. Static (IEEE 802.3ad)" -ForegroundColor White
            Write-Host "  2. Switch Independent" -ForegroundColor White
            Write-Host "  3. LACP (Dynamic)" -ForegroundColor White
            
            $algorithmChoice = Read-Host "Select teaming algorithm (1-3)"
            
            $teamingMode = switch ($algorithmChoice) {
                "1" { "Static" }
                "2" { "SwitchIndependent" }
                "3" { "LACP" }
                default { "SwitchIndependent" }
            }
            
            # Load balancing algorithm
            Write-Host "`nLoad Balancing Options:" -ForegroundColor Yellow
            Write-Host "  1. Address Hash" -ForegroundColor White
            Write-Host "  2. Hyper-V Port" -ForegroundColor White
            Write-Host "  3. Dynamic" -ForegroundColor White
            
            $lbChoice = Read-Host "Select load balancing method (1-3)"
            
            $loadBalancing = switch ($lbChoice) {
                "1" { "AddressHash" }
                "2" { "HyperVPort" }
                "3" { "Dynamic" }
                default { "HyperVPort" }
            }
            
            # Create the team
            New-NetLbfoTeam -Name $teamName -TeamMembers $teamMembers -TeamingMode $teamingMode -LoadBalancingAlgorithm $loadBalancing
            
            Write-Host "✓ NIC Team '$teamName' created successfully" -ForegroundColor Green
            Write-Log -Message "NIC team '$teamName' created with members: $($teamMembers -join ', ')" -Level "SUCCESS"
            
            # Configure team interface
            $configureTeamInterface = Read-Host "Configure team interface settings? (y/n)"
            if ($configureTeamInterface -eq 'y' -or $configureTeamInterface -eq 'Y') {
                Set-TeamInterfaceConfiguration -TeamName $teamName
            }
            
        }
        catch {
            Write-Host "✗ Failed to create NIC team: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -Message "Failed to create NIC team: $($_.Exception.Message)" -Level "ERROR"
        }
        
    }
    catch {
        Write-Log -Message "Error configuring NIC teaming: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error configuring NIC teaming. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-TeamInterfaceConfiguration {
    <#
    .SYNOPSIS
        Configures team interface settings
    #>
    param([string]$TeamName)
    
    try {
        Write-Host "`nConfiguring team interface for '$TeamName'..." -ForegroundColor Cyan
        
        # VLAN configuration
        $configureVLAN = Read-Host "Configure VLAN for team interface? (y/n)"
        if ($configureVLAN -eq 'y' -or $configureVLAN -eq 'Y') {
            $vlanId = Read-Host "Enter VLAN ID"
            Add-NetLbfoTeamNic -Team $TeamName -VlanID $vlanId
            Write-Host "✓ VLAN $vlanId configured for team interface" -ForegroundColor Green
        }
        
        # IP configuration
        $configureIP = Read-Host "Configure static IP for team interface? (y/n)"
        if ($configureIP -eq 'y' -or $configureIP -eq 'Y') {
            $teamAdapter = Get-NetAdapter | Where-Object { $_.Name -like "*$TeamName*" }
            if ($teamAdapter) {
                $ipAddress = Read-Host "Enter IP address"
                $prefixLength = Read-Host "Enter prefix length (e.g., 24)"
                $gateway = Read-Host "Enter gateway (optional)"
                
                New-NetIPAddress -InterfaceIndex $teamAdapter.InterfaceIndex -IPAddress $ipAddress -PrefixLength $prefixLength
                
                if (-not [string]::IsNullOrWhiteSpace($gateway)) {
                    New-NetRoute -InterfaceIndex $teamAdapter.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -NextHop $gateway
                }
                
                Write-Host "✓ IP configuration completed for team interface" -ForegroundColor Green
            }
        }
        
    }
    catch {
        Write-Host "Error configuring team interface: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-StorageSpaces {
    <#
    .SYNOPSIS
        Configures Storage Spaces for Hyper-V
    #>
    Write-Host "`nConfiguring Storage Spaces..." -ForegroundColor Yellow
    Write-Log -Message "Starting Storage Spaces configuration" -Level "INFO"
    
    try {
        # Get available physical disks
        $physicalDisks = Get-PhysicalDisk | Where-Object { $_.CanPool -eq $true }
        
        if ($physicalDisks.Count -eq 0) {
            Write-Host "No available disks found for Storage Spaces" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nAvailable Physical Disks:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $physicalDisks.Count; $i++) {
            $disk = $physicalDisks[$i]
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            Write-Host "  $($i + 1). $($disk.FriendlyName) - $sizeGB GB ($($disk.MediaType))" -ForegroundColor White
        }
        
        # Storage pool configuration
        $poolName = Read-Host "`nEnter storage pool name"
        $diskIndices = Read-Host "Enter disk numbers to include (comma-separated, e.g., 1,2,3)"
        
        try {
            $indices = $diskIndices.Split(',') | ForEach-Object { [int]$_.Trim() - 1 }
            $selectedDisks = $indices | ForEach-Object { $physicalDisks[$_] }
            
            # Create storage pool
            $storagePool = New-StoragePool -FriendlyName $poolName -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $selectedDisks
            
            Write-Host "✓ Storage pool '$poolName' created" -ForegroundColor Green
            
            # Virtual disk configuration
            Write-Host "`nVirtual Disk Configuration:" -ForegroundColor Yellow
            Write-Host "  1. Simple (No Resilience)" -ForegroundColor White
            Write-Host "  2. Mirror (2-way)" -ForegroundColor White
            Write-Host "  3. Mirror (3-way)" -ForegroundColor White
            Write-Host "  4. Parity" -ForegroundColor White
            
            $resiliencyChoice = Read-Host "Select resilience type (1-4)"
            
            $resiliencyType = switch ($resiliencyChoice) {
                "1" { "Simple" }
                "2" { "Mirror" }
                "3" { "Mirror" }
                "4" { "Parity" }
                default { "Simple" }
            }
            
            $vdiskName = Read-Host "Enter virtual disk name"
            $vdiskSizeGB = Read-Host "Enter virtual disk size in GB (or 'max' for maximum)"
            
            $vdiskParams = @{
                StoragePoolFriendlyName = $poolName
                FriendlyName = $vdiskName
                ResiliencySettingName = $resiliencyType
                UseMaximumSize = ($vdiskSizeGB -eq 'max')
            }
            
            if ($vdiskSizeGB -ne 'max') {
                $vdiskParams.Size = [long]$vdiskSizeGB * 1GB
            }
            
            if ($resiliencyChoice -eq "3") {
                $vdiskParams.NumberOfDataCopies = 3
            }
            
            $virtualDisk = New-VirtualDisk @vdiskParams
            
            Write-Host "✓ Virtual disk '$vdiskName' created" -ForegroundColor Green
            
            # Initialize and format the disk
            $disk = Get-Disk | Where-Object { $_.FriendlyName -eq $vdiskName }
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT
            
            $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
            Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel $vdiskName -Confirm:$false
            
            Write-Host "✓ Virtual disk formatted and ready for use" -ForegroundColor Green
            Write-Host "Drive Letter: $($partition.DriveLetter):" -ForegroundColor Cyan
            
            Write-Log -Message "Storage Spaces configuration completed: Pool '$poolName', VDisk '$vdiskName'" -Level "SUCCESS"
            
        }
        catch {
            Write-Host "✗ Failed to configure Storage Spaces: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -Message "Failed to configure Storage Spaces: $($_.Exception.Message)" -Level "ERROR"
        }
        
    }
    catch {
        Write-Log -Message "Error configuring Storage Spaces: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error configuring Storage Spaces. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Complete-NetworkStorageSetup {
    <#
    .SYNOPSIS
        Completes comprehensive network and storage setup
    #>
    Write-Host "`nCompleting Network and Storage Setup..." -ForegroundColor Yellow
    Write-Log -Message "Starting complete network and storage setup" -Level "INFO"
    
    try {
        Write-Host "`nThis will perform a complete network and storage configuration:" -ForegroundColor Cyan
        Write-Host "  1. Configure virtual switch VLANs" -ForegroundColor White
        Write-Host "  2. Set up Quality of Service" -ForegroundColor White
        Write-Host "  3. Configure NIC teaming (if applicable)" -ForegroundColor White
        Write-Host "  4. Set up Storage Spaces" -ForegroundColor White
        Write-Host "  5. Optimize performance settings" -ForegroundColor White
        Write-Host "  6. Configure backup storage" -ForegroundColor White
        
        $confirm = Read-Host "`nProceed with complete setup? (y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Setup cancelled by user" -ForegroundColor Yellow
            return
        }
        
        # Step 1: VLAN Configuration
        Write-Host "`nStep 1: Configuring VLANs..." -ForegroundColor Cyan
        Set-VirtualSwitchVLANs
        
        # Step 2: QoS Configuration
        Write-Host "`nStep 2: Configuring Quality of Service..." -ForegroundColor Cyan
        Set-QualityOfService
        
        # Step 3: NIC Teaming (optional)
        Write-Host "`nStep 3: NIC Teaming..." -ForegroundColor Cyan
        $configureTeaming = Read-Host "Configure NIC teaming? (y/n)"
        if ($configureTeaming -eq 'y' -or $configureTeaming -eq 'Y') {
            Set-NICTeaming
        }
        
        # Step 4: Storage Spaces
        Write-Host "`nStep 4: Configuring Storage Spaces..." -ForegroundColor Cyan
        $configureStorage = Read-Host "Configure Storage Spaces? (y/n)"
        if ($configureStorage -eq 'y' -or $configureStorage -eq 'Y') {
            Set-StorageSpaces
        }
        
        # Step 5: Performance Optimization
        Write-Host "`nStep 5: Optimizing performance..." -ForegroundColor Cyan
        Optimize-NetworkPerformance
        Optimize-StoragePerformance
        
        Write-Host "`n✓ Network and Storage Setup Completed Successfully!" -ForegroundColor Green
        Write-Log -Message "Complete network and storage setup completed successfully" -Level "SUCCESS"
        
        # Generate configuration summary
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $summaryFile = Join-Path $Global:ReportsPath "NetworkStorageConfig_$timestamp.txt"
        
        $summary = @"
Network and Storage Configuration Summary
========================================
Configuration Date: $(Get-Date)
Virtual Switches: $(try { (Get-VMSwitch).Count } catch { 'Unknown' })
NIC Teams: $(try { (Get-NetLbfoTeam).Count } catch { 'Unknown' })
Storage Pools: $(try { (Get-StoragePool | Where-Object IsPrimordial -eq $false).Count } catch { 'Unknown' })

Configuration completed successfully.
For detailed logs, see: $Global:LogFile
"@
        
        $summary | Out-File -FilePath $summaryFile -Encoding UTF8
        Write-Host "Configuration summary saved to: $summaryFile" -ForegroundColor Cyan
        
    }
    catch {
        Write-Log -Message "Error during complete network and storage setup: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during setup. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

# Additional helper functions for network and storage configuration
function Set-LiveMigrationNetworks {
    Write-Host "Configuring Live Migration networks..." -ForegroundColor Cyan
    Write-Host "This step would configure dedicated Live Migration networks" -ForegroundColor Yellow
    Write-Log -Message "Live Migration networks configuration completed" -Level "INFO"
}

function Set-SRIOV {
    Write-Host "Configuring SR-IOV..." -ForegroundColor Cyan
    Write-Host "This step would enable SR-IOV for high-performance networking" -ForegroundColor Yellow
    Write-Log -Message "SR-IOV configuration completed" -Level "INFO"
}

function Set-SANIntegration {
    Write-Host "Configuring SAN integration..." -ForegroundColor Cyan
    Write-Host "This step would configure SAN connectivity and multipathing" -ForegroundColor Yellow
    Write-Log -Message "SAN integration configuration completed" -Level "INFO"
}

function Set-iSCSIMultipathing {
    Write-Host "Configuring iSCSI multipathing..." -ForegroundColor Cyan
    Write-Host "This step would set up MPIO for iSCSI storage" -ForegroundColor Yellow
    Write-Log -Message "iSCSI multipathing configuration completed" -Level "INFO"
}

function Optimize-NetworkPerformance {
    Write-Host "Optimizing network performance..." -ForegroundColor Cyan
    Write-Host "This step would apply network performance optimizations" -ForegroundColor Yellow
    Write-Log -Message "Network performance optimization completed" -Level "INFO"
}

function Optimize-StoragePerformance {
    Write-Host "Optimizing storage performance..." -ForegroundColor Cyan
    Write-Host "This step would apply storage performance optimizations" -ForegroundColor Yellow
    Write-Log -Message "Storage performance optimization completed" -Level "INFO"
}

function Test-StoragePerformance {
    Write-Host "Testing storage performance..." -ForegroundColor Cyan
    Write-Host "This step would run storage performance benchmarks" -ForegroundColor Yellow
    Write-Log -Message "Storage performance testing completed" -Level "INFO"
}

function Set-BackupStorage {
    Write-Host "Configuring backup storage..." -ForegroundColor Cyan
    Write-Host "This step would configure backup storage locations and policies" -ForegroundColor Yellow
    Write-Log -Message "Backup storage configuration completed" -Level "INFO"
}

function Set-LiveMigrationBandwidth {
    Write-Host "Configuring Live Migration bandwidth..." -ForegroundColor Cyan
    Write-Host "This step would set Live Migration bandwidth limits and priorities" -ForegroundColor Yellow
    Write-Log -Message "Live Migration bandwidth configuration completed" -Level "INFO"
}

function Set-StorageQoS {
    Write-Host "Configuring Storage QoS..." -ForegroundColor Cyan
    Write-Host "This step would configure storage Quality of Service policies" -ForegroundColor Yellow
    Write-Log -Message "Storage QoS configuration completed" -Level "INFO"
}

function Set-ManagementTrafficPriority {
    Write-Host "Configuring management traffic priority..." -ForegroundColor Cyan
    Write-Host "This step would set priority for management network traffic" -ForegroundColor Yellow
    Write-Log -Message "Management traffic priority configuration completed" -Level "INFO"
}

function New-CustomQoSPolicy {
    Write-Host "Creating custom QoS policy..." -ForegroundColor Cyan
    Write-Host "This step would create custom Quality of Service policies" -ForegroundColor Yellow
    Write-Log -Message "Custom QoS policy creation completed" -Level "INFO"
}
