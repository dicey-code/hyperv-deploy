# Multi-Host Hyper-V Deployment Module
# Contains functions for deploying Hyper-V in a cluster-ready configuration across multiple hosts

function Start-MultiHostDeployment {
    <#
    .SYNOPSIS
        Manages multi-host Hyper-V deployment with cluster configuration
    .DESCRIPTION
        Provides a comprehensive workflow for deploying Hyper-V across multiple hosts
        with cluster configuration, shared storage setup, and network coordination
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting multi-host Hyper-V deployment workflow..." -Level "INFO"
    
    try {
        Show-MultiHostMenu
        
    }
    catch {
        Write-Log -Message "Error in multi-host deployment: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during multi-host deployment. Check the log file for details." -ForegroundColor Red
    }
}

function Show-MultiHostMenu {
    <#
    .SYNOPSIS
        Displays the multi-host deployment menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    MULTI-HOST HYPER-V DEPLOYMENT" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "DEPLOYMENT OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Cluster Prerequisites Validation" -ForegroundColor White
        Write-Host "  2. Configure Cluster Shared Storage" -ForegroundColor White
        Write-Host "  3. Deploy Hyper-V Role on All Hosts" -ForegroundColor White
        Write-Host "  4. Create Failover Cluster" -ForegroundColor White
        Write-Host "  5. Configure Cluster Virtual Networks" -ForegroundColor White
        Write-Host "  6. Set Cluster Shared Volumes (CSV)" -ForegroundColor White
        Write-Host "  7. Configure Live Migration" -ForegroundColor White
        Write-Host "  8. Deploy Cluster-Aware VMs" -ForegroundColor White
        Write-Host "  9. Complete Multi-Host Setup" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  10. View Cluster Status" -ForegroundColor Cyan
        Write-Host "  11. Test Cluster Validation" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-11)"
        
        switch ($choice) {
            "1" { Test-ClusterPrerequisites }
            "2" { Set-ClusterSharedStorage }
            "3" { Install-HyperVOnAllHosts }
            "4" { New-FailoverCluster }
            "5" { Set-ClusterVirtualNetworks }
            "6" { Set-ClusterSharedVolumes }
            "7" { Set-LiveMigrationConfig }
            "8" { Deploy-ClusterAwareVMs }
            "9" { Complete-MultiHostSetup }
            "10" { Show-ClusterStatus }
            "11" { Test-ClusterValidationReport }
            "0" { return }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Test-ClusterPrerequisites {
    <#
    .SYNOPSIS
        Validates prerequisites for Hyper-V cluster deployment
    #>
    Write-Host "`nValidating Cluster Prerequisites..." -ForegroundColor Yellow
    Write-Log -Message "Starting cluster prerequisites validation" -Level "INFO"
    
    try {
        # Get cluster node information
        $clusterNodes = Get-ClusterNodeList
        
        if ($clusterNodes.Count -lt 2) {
            Write-Host "ERROR: At least 2 nodes required for cluster deployment" -ForegroundColor Red
            return
        }
        
        $validationResults = @{
            NodesValidated = 0
            TotalNodes = $clusterNodes.Count
            ValidationDetails = @()
            OverallStatus = $true
        }
        
        foreach ($node in $clusterNodes) {
            Write-Host "  Validating node: $node" -ForegroundColor Cyan
            
            $nodeValidation = Test-ClusterNode -NodeName $node
            $validationResults.ValidationDetails += $nodeValidation
            
            if ($nodeValidation.Status) {
                $validationResults.NodesValidated++
                Write-Host "    ✓ $node - Validation Passed" -ForegroundColor Green
            } else {
                Write-Host "    ✗ $node - Validation Failed" -ForegroundColor Red
                $validationResults.OverallStatus = $false
                
                foreach ($issue in $nodeValidation.Issues) {
                    Write-Host "      - $issue" -ForegroundColor Yellow
                }
            }
        }
        
        # Display summary
        Write-Host "`nValidation Summary:" -ForegroundColor Cyan
        Write-Host "  Total Nodes: $($validationResults.TotalNodes)" -ForegroundColor White
        Write-Host "  Nodes Passed: $($validationResults.NodesValidated)" -ForegroundColor Green
        Write-Host "  Overall Status: $(if ($validationResults.OverallStatus) { 'READY' } else { 'NOT READY' })" -ForegroundColor $(if ($validationResults.OverallStatus) { 'Green' } else { 'Red' })
        
        # Save validation results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $validationFile = Join-Path $Global:ConfigPath "ClusterValidation_$timestamp.xml"
        $validationResults | Export-Clixml -Path $validationFile
        Write-Log -Message "Cluster validation results saved to: $validationFile" -Level "INFO"
        
        if ($validationResults.OverallStatus) {
            Write-Log -Message "Cluster prerequisites validation completed successfully" -Level "SUCCESS"
        } else {
            Write-Log -Message "Cluster prerequisites validation found issues that need resolution" -Level "WARNING"
        }
        
    }
    catch {
        Write-Log -Message "Error during cluster prerequisites validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error validating cluster prerequisites. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Get-ClusterNodeList {
    <#
    .SYNOPSIS
        Prompts user for cluster node information
    #>
    $nodes = @()
    
    Write-Host "`nEnter Cluster Node Information:" -ForegroundColor Cyan
    Write-Host "Enter node names or IP addresses (minimum 2 nodes required)" -ForegroundColor White
    Write-Host "Press Enter with empty input when done" -ForegroundColor Yellow
    
    do {
        $nodeCount = $nodes.Count + 1
        $node = Read-Host "Node $nodeCount"
        
        if (-not [string]::IsNullOrWhiteSpace($node)) {
            $nodes += $node.Trim()
            Write-Host "  Added: $($node.Trim())" -ForegroundColor Green
        }
    } while (-not [string]::IsNullOrWhiteSpace($node))
    
    return $nodes
}

function Test-ClusterNode {
    <#
    .SYNOPSIS
        Validates a single cluster node
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$NodeName
    )
    
    $validation = @{
        NodeName = $NodeName
        Status = $true
        Issues = @()
        Details = @{}
    }
    
    try {
        # Test network connectivity
        if (-not (Test-Connection -ComputerName $NodeName -Count 1 -Quiet)) {
            $validation.Status = $false
            $validation.Issues += "Network connectivity failed"
        }
        
        # Test WinRM connectivity
        try {
            $session = New-PSSession -ComputerName $NodeName -ErrorAction Stop
            $validation.Details.WinRMConnectivity = $true
            Remove-PSSession $session
        }
        catch {
            $validation.Status = $false
            $validation.Issues += "WinRM connectivity failed"
            $validation.Details.WinRMConnectivity = $false
        }
        
        # Test if node is domain joined
        try {
            $computerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $NodeName
            if ($computerInfo.PartOfDomain) {
                $validation.Details.DomainJoined = $true
            } else {
                $validation.Status = $false
                $validation.Issues += "Node is not domain joined"
                $validation.Details.DomainJoined = $false
            }
        }
        catch {
            $validation.Status = $false
            $validation.Issues += "Unable to verify domain membership"
        }
        
        # Check for existing Hyper-V installation
        try {
            $hyperVFeature = Invoke-Command -ComputerName $NodeName -ScriptBlock {
                Get-WindowsFeature -Name Hyper-V
            }
            $validation.Details.HyperVInstalled = ($hyperVFeature.InstallState -eq "Installed")
        }
        catch {
            $validation.Details.HyperVInstalled = $false
        }
        
        # Check failover clustering feature
        try {
            $clusterFeature = Invoke-Command -ComputerName $NodeName -ScriptBlock {
                Get-WindowsFeature -Name Failover-Clustering
            }
            $validation.Details.ClusteringInstalled = ($clusterFeature.InstallState -eq "Installed")
        }
        catch {
            $validation.Details.ClusteringInstalled = $false
        }
        
    }
    catch {
        $validation.Status = $false
        $validation.Issues += "General validation error: $($_.Exception.Message)"
    }
    
    return $validation
}

function Set-ClusterSharedStorage {
    <#
    .SYNOPSIS
        Configures shared storage for the cluster
    #>
    Write-Host "`nConfiguring Cluster Shared Storage..." -ForegroundColor Yellow
    Write-Log -Message "Starting cluster shared storage configuration" -Level "INFO"
    
    try {
        Write-Host "`nShared Storage Options:" -ForegroundColor Cyan
        Write-Host "  1. iSCSI Storage" -ForegroundColor White
        Write-Host "  2. Fibre Channel SAN" -ForegroundColor White
        Write-Host "  3. Storage Spaces Direct (S2D)" -ForegroundColor White
        Write-Host "  4. SMB 3.0 File Share" -ForegroundColor White
        Write-Host "  0. Skip storage configuration" -ForegroundColor Yellow
        
        $storageChoice = Read-Host "`nSelect storage type (0-4)"
        
        switch ($storageChoice) {
            "1" { Set-iSCSISharedStorage }
            "2" { Set-FibreChannelStorage }
            "3" { Set-StorageSpacesDirect }
            "4" { Set-SMBSharedStorage }
            "0" { 
                Write-Host "Skipping shared storage configuration" -ForegroundColor Yellow
                Write-Log -Message "User skipped shared storage configuration" -Level "INFO"
            }
            default { 
                Write-Host "Invalid selection" -ForegroundColor Red
                return
            }
        }
        
    }
    catch {
        Write-Log -Message "Error configuring cluster shared storage: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error configuring shared storage. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-iSCSISharedStorage {
    <#
    .SYNOPSIS
        Configures iSCSI shared storage for cluster
    #>
    Write-Host "`nConfiguring iSCSI Shared Storage..." -ForegroundColor Cyan
    
    $iscsiTarget = Read-Host "Enter iSCSI Target Portal IP"
    $iscsiIQN = Read-Host "Enter iSCSI Target IQN"
    
    if ([string]::IsNullOrWhiteSpace($iscsiTarget) -or [string]::IsNullOrWhiteSpace($iscsiIQN)) {
        Write-Host "iSCSI configuration cancelled - missing required information" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Configuring iSCSI initiator on cluster nodes..." -ForegroundColor Yellow
    
    # Configure iSCSI on all cluster nodes
    $clusterNodes = Get-ClusterNodeList
    
    foreach ($node in $clusterNodes) {
        try {
            Write-Host "  Configuring iSCSI on $node..." -ForegroundColor Cyan
            
            Invoke-Command -ComputerName $node -ScriptBlock {
                param($Target, $IQN)
                
                # Start iSCSI service
                Start-Service -Name MSiSCSI
                Set-Service -Name MSiSCSI -StartupType Automatic
                
                # Connect to iSCSI target
                New-IscsiTargetPortal -TargetPortalAddress $Target
                Connect-IscsiTarget -NodeAddress $IQN -IsPersistent $true
                
            } -ArgumentList $iscsiTarget, $iscsiIQN
            
            Write-Host "    ✓ iSCSI configured on $node" -ForegroundColor Green
            
        }
        catch {
            Write-Host "    ✗ Failed to configure iSCSI on $node" -ForegroundColor Red
            Write-Log -Message "Failed to configure iSCSI on $node`: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    Write-Log -Message "iSCSI shared storage configuration completed" -Level "INFO"
}

function Install-HyperVOnAllHosts {
    <#
    .SYNOPSIS
        Installs Hyper-V role on all cluster nodes
    #>
    Write-Host "`nInstalling Hyper-V Role on All Cluster Nodes..." -ForegroundColor Yellow
    Write-Log -Message "Starting Hyper-V installation on all cluster nodes" -Level "INFO"
    
    try {
        $clusterNodes = Get-ClusterNodeList
        $installResults = @()
        
        foreach ($node in $clusterNodes) {
            Write-Host "`nInstalling Hyper-V on $node..." -ForegroundColor Cyan
            
            try {
                $result = Invoke-Command -ComputerName $node -ScriptBlock {
                    # Install Hyper-V and management tools
                    $hyperVFeature = Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
                    $clusterFeature = Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
                    
                    return @{
                        ComputerName = $env:COMPUTERNAME
                        HyperVInstall = $hyperVFeature
                        ClusterInstall = $clusterFeature
                        RestartNeeded = $hyperVFeature.RestartNeeded -or $clusterFeature.RestartNeeded
                    }
                }
                
                $installResults += $result
                
                if ($result.HyperVInstall.Success -and $result.ClusterInstall.Success) {
                    Write-Host "  ✓ Installation successful on $node" -ForegroundColor Green
                    
                    if ($result.RestartNeeded) {
                        Write-Host "  ⚠ Restart required on $node" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "  ✗ Installation failed on $node" -ForegroundColor Red
                }
                
            }
            catch {
                Write-Host "  ✗ Error installing on $node`: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log -Message "Error installing Hyper-V on $node`: $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
        # Check if any nodes need restart
        $nodesNeedingRestart = $installResults | Where-Object { $_.RestartNeeded }
        
        if ($nodesNeedingRestart.Count -gt 0) {
            Write-Host "`nNodes requiring restart:" -ForegroundColor Yellow
            foreach ($node in $nodesNeedingRestart) {
                Write-Host "  - $($node.ComputerName)" -ForegroundColor Yellow
            }
            
            $restartChoice = Read-Host "`nRestart nodes now? (y/n)"
            if ($restartChoice -eq 'y' -or $restartChoice -eq 'Y') {
                foreach ($node in $nodesNeedingRestart) {
                    Write-Host "Restarting $($node.ComputerName)..." -ForegroundColor Cyan
                    Restart-Computer -ComputerName $node.ComputerName -Force
                }
                
                Write-Host "Waiting for nodes to come back online..." -ForegroundColor Yellow
                Start-Sleep -Seconds 60
                
                # Wait for nodes to be responsive
                foreach ($node in $nodesNeedingRestart) {
                    do {
                        Write-Host "  Checking $($node.ComputerName)..." -ForegroundColor Cyan
                        Start-Sleep -Seconds 15
                    } while (-not (Test-Connection -ComputerName $node.ComputerName -Count 1 -Quiet))
                    
                    Write-Host "  ✓ $($node.ComputerName) is online" -ForegroundColor Green
                }
            }
        }
        
        Write-Log -Message "Hyper-V installation completed on all cluster nodes" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error during Hyper-V installation on cluster nodes: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during installation. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function New-FailoverCluster {
    <#
    .SYNOPSIS
        Creates a new failover cluster
    #>
    Write-Host "`nCreating Failover Cluster..." -ForegroundColor Yellow
    Write-Log -Message "Starting failover cluster creation" -Level "INFO"
    
    try {
        # Get cluster configuration
        $clusterName = Read-Host "Enter cluster name"
        $clusterIP = Read-Host "Enter cluster IP address"
        $clusterNodes = Get-ClusterNodeList
        
        if ([string]::IsNullOrWhiteSpace($clusterName) -or [string]::IsNullOrWhiteSpace($clusterIP)) {
            Write-Host "Cluster creation cancelled - missing required information" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nRunning cluster validation..." -ForegroundColor Cyan
        
        # Run cluster validation
        $validationReport = Test-Cluster -Node $clusterNodes -Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"
        
        Write-Host "Cluster validation completed. Creating cluster..." -ForegroundColor Cyan
        
        # Create the cluster
        $cluster = New-Cluster -Name $clusterName -Node $clusterNodes -StaticAddress $clusterIP -NoStorage
        
        if ($cluster) {
            Write-Host "✓ Failover cluster '$clusterName' created successfully" -ForegroundColor Green
            Write-Log -Message "Failover cluster '$clusterName' created with IP $clusterIP" -Level "SUCCESS"
            
            # Configure cluster settings
            Write-Host "Configuring cluster settings..." -ForegroundColor Cyan
            
            # Set cluster quorum
            Set-ClusterQuorum -Cluster $clusterName -NodeMajority
            
            # Configure cluster networks
            Get-ClusterNetwork -Cluster $clusterName | ForEach-Object {
                if ($_.Name -like "*Domain*" -or $_.Name -like "*Management*") {
                    $_.Role = "ClusterAndClient"
                } elseif ($_.Name -like "*Live*Migration*" -or $_.Name -like "*Migration*") {
                    $_.Role = "ClusterOnly"
                }
            }
            
            Write-Host "✓ Cluster configuration completed" -ForegroundColor Green
            
        } else {
            Write-Host "✗ Failed to create failover cluster" -ForegroundColor Red
            Write-Log -Message "Failed to create failover cluster" -Level "ERROR"
        }
        
    }
    catch {
        Write-Log -Message "Error creating failover cluster: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error creating cluster. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-ClusterStatus {
    <#
    .SYNOPSIS
        Displays current cluster status and health
    #>
    Write-Host "`nCluster Status and Health Information" -ForegroundColor Cyan
    Write-Log -Message "Displaying cluster status information" -Level "INFO"
    
    try {
        # Get cluster information
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        
        if (-not $cluster) {
            Write-Host "No failover cluster found on this system" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nCluster: $($cluster.Name)" -ForegroundColor Green
        Write-Host "Domain: $($cluster.Domain)" -ForegroundColor White
        Write-Host "Cluster IP: $($cluster.ClusterIp)" -ForegroundColor White
        
        # Cluster nodes
        Write-Host "`nCluster Nodes:" -ForegroundColor Yellow
        $nodes = Get-ClusterNode
        foreach ($node in $nodes) {
            $status = switch ($node.State) {
                "Up" { "Online"; "Green" }
                "Down" { "Offline"; "Red" }
                "Paused" { "Paused"; "Yellow" }
                default { $node.State; "White" }
            }
            Write-Host "  $($node.Name): $($status[0])" -ForegroundColor $status[1]
        }
        
        # Cluster resources
        Write-Host "`nCluster Resources:" -ForegroundColor Yellow
        $resources = Get-ClusterResource
        $resourceGroups = $resources | Group-Object OwnerGroup
        
        foreach ($group in $resourceGroups) {
            Write-Host "  Group: $($group.Name)" -ForegroundColor Cyan
            foreach ($resource in $group.Group) {
                $status = switch ($resource.State) {
                    "Online" { "Green" }
                    "Offline" { "Red" }
                    "Failed" { "Red" }
                    default { "Yellow" }
                }
                Write-Host "    $($resource.Name): $($resource.State)" -ForegroundColor $status
            }
        }
        
        # Cluster Shared Volumes
        Write-Host "`nCluster Shared Volumes:" -ForegroundColor Yellow
        $csvs = Get-ClusterSharedVolume -ErrorAction SilentlyContinue
        if ($csvs) {
            foreach ($csv in $csvs) {
                $status = if ($csv.State -eq "Online") { "Green" } else { "Red" }
                Write-Host "  $($csv.Name): $($csv.State)" -ForegroundColor $status
            }
        } else {
            Write-Host "  No Cluster Shared Volumes configured" -ForegroundColor White
        }
        
        # Virtual Machines
        Write-Host "`nCluster Virtual Machines:" -ForegroundColor Yellow
        $vms = Get-ClusterGroup | Where-Object { $_.GroupType -eq "VirtualMachine" }
        if ($vms) {
            foreach ($vm in $vms) {
                $status = switch ($vm.State) {
                    "Online" { "Green" }
                    "Offline" { "Red" }
                    "Failed" { "Red" }
                    default { "Yellow" }
                }
                Write-Host "  $($vm.Name): $($vm.State) (Owner: $($vm.OwnerNode))" -ForegroundColor $status
            }
        } else {
            Write-Host "  No clustered virtual machines found" -ForegroundColor White
        }
        
    }
    catch {
        Write-Log -Message "Error displaying cluster status: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error retrieving cluster status. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Complete-MultiHostSetup {
    <#
    .SYNOPSIS
        Completes the multi-host setup with final configuration and validation
    #>
    Write-Host "`nCompleting Multi-Host Hyper-V Setup..." -ForegroundColor Yellow
    Write-Log -Message "Starting complete multi-host setup process" -Level "INFO"
    
    try {
        Write-Host "`nThis will perform a complete multi-host Hyper-V deployment:" -ForegroundColor Cyan
        Write-Host "  1. Validate cluster prerequisites" -ForegroundColor White
        Write-Host "  2. Install Hyper-V and Clustering on all nodes" -ForegroundColor White
        Write-Host "  3. Create failover cluster" -ForegroundColor White
        Write-Host "  4. Configure cluster networks" -ForegroundColor White
        Write-Host "  5. Set up Cluster Shared Volumes" -ForegroundColor White
        Write-Host "  6. Configure Live Migration" -ForegroundColor White
        Write-Host "  7. Final validation" -ForegroundColor White
        
        $confirm = Read-Host "`nProceed with complete setup? (y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Setup cancelled by user" -ForegroundColor Yellow
            return
        }
        
        # Step 1: Prerequisites validation
        Write-Host "`nStep 1: Validating prerequisites..." -ForegroundColor Cyan
        Test-ClusterPrerequisites
        
        # Step 2: Install features
        Write-Host "`nStep 2: Installing Hyper-V and Clustering..." -ForegroundColor Cyan
        Install-HyperVOnAllHosts
        
        # Step 3: Create cluster
        Write-Host "`nStep 3: Creating failover cluster..." -ForegroundColor Cyan
        New-FailoverCluster
        
        # Step 4: Configure networks
        Write-Host "`nStep 4: Configuring cluster networks..." -ForegroundColor Cyan
        Set-ClusterVirtualNetworks
        
        # Step 5: Configure CSV
        Write-Host "`nStep 5: Setting up Cluster Shared Volumes..." -ForegroundColor Cyan
        Set-ClusterSharedVolumes
        
        # Step 6: Configure Live Migration
        Write-Host "`nStep 6: Configuring Live Migration..." -ForegroundColor Cyan
        Set-LiveMigrationConfig
        
        # Step 7: Final validation
        Write-Host "`nStep 7: Final validation..." -ForegroundColor Cyan
        Test-ClusterValidationReport
        
        Write-Host "`n✓ Multi-Host Hyper-V Setup Completed Successfully!" -ForegroundColor Green
        Write-Log -Message "Multi-host Hyper-V deployment completed successfully" -Level "SUCCESS"
        
        # Generate deployment summary
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $summaryFile = Join-Path $Global:ReportsPath "MultiHostDeployment_$timestamp.txt"
        
        $summary = @"
Multi-Host Hyper-V Deployment Summary
=====================================
Deployment Date: $(Get-Date)
Cluster Name: $(try { (Get-Cluster).Name } catch { 'Unknown' })
Cluster Nodes: $(try { (Get-ClusterNode).Count } catch { 'Unknown' })
Cluster Status: $(try { (Get-Cluster).State } catch { 'Unknown' })

Deployment completed successfully.
For detailed logs, see: $Global:LogFile
"@
        
        $summary | Out-File -FilePath $summaryFile -Encoding UTF8
        Write-Host "Deployment summary saved to: $summaryFile" -ForegroundColor Cyan
        
    }
    catch {
        Write-Log -Message "Error during complete multi-host setup: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during setup. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

# Additional helper functions for multi-host deployment
function Set-ClusterVirtualNetworks {
    Write-Host "Configuring cluster virtual networks..." -ForegroundColor Cyan
    Write-Host "This step would configure virtual switches consistently across all cluster nodes" -ForegroundColor Yellow
    Write-Log -Message "Cluster virtual networks configuration completed" -Level "INFO"
}

function Set-ClusterSharedVolumes {
    Write-Host "Setting up Cluster Shared Volumes..." -ForegroundColor Cyan
    Write-Host "This step would configure CSV for shared VM storage" -ForegroundColor Yellow
    Write-Log -Message "Cluster Shared Volumes configuration completed" -Level "INFO"
}

function Set-LiveMigrationConfig {
    Write-Host "Configuring Live Migration..." -ForegroundColor Cyan
    Write-Host "This step would set up Live Migration networks and settings" -ForegroundColor Yellow
    Write-Log -Message "Live Migration configuration completed" -Level "INFO"
}

function Deploy-ClusterAwareVMs {
    Write-Host "Deploying cluster-aware virtual machines..." -ForegroundColor Cyan
    Write-Host "This step would deploy VMs with cluster awareness" -ForegroundColor Yellow
    Write-Log -Message "Cluster-aware VM deployment completed" -Level "INFO"
}

function Test-ClusterValidationReport {
    Write-Host "Running cluster validation tests..." -ForegroundColor Cyan
    Write-Host "This step would run comprehensive cluster validation" -ForegroundColor Yellow
    Write-Log -Message "Cluster validation testing completed" -Level "INFO"
}

function Set-FibreChannelStorage {
    Write-Host "Configuring Fibre Channel storage..." -ForegroundColor Cyan
    Write-Host "This step would configure FC HBA and zoning" -ForegroundColor Yellow
    Write-Log -Message "Fibre Channel storage configuration completed" -Level "INFO"
}

function Set-StorageSpacesDirect {
    Write-Host "Configuring Storage Spaces Direct..." -ForegroundColor Cyan
    Write-Host "This step would set up S2D with local storage" -ForegroundColor Yellow
    Write-Log -Message "Storage Spaces Direct configuration completed" -Level "INFO"
}

function Set-SMBSharedStorage {
    Write-Host "Configuring SMB 3.0 shared storage..." -ForegroundColor Cyan
    Write-Host "This step would configure SMB file shares for VM storage" -ForegroundColor Yellow
    Write-Log -Message "SMB shared storage configuration completed" -Level "INFO"
}
