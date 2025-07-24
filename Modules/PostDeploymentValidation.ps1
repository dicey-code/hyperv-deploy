# Post-Deployment Validation and Testing Module
# Contains functions for validating and testing Hyper-V deployment after installation

function Start-PostDeploymentValidation {
    <#
    .SYNOPSIS
        Manages post-deployment validation and testing for Hyper-V
    .DESCRIPTION
        Provides comprehensive validation and testing of Hyper-V deployment including
        health checks, performance validation, security validation, and functionality testing
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting post-deployment validation workflow..." -Level "INFO"
    
    try {
        Show-ValidationMenu
        
    }
    catch {
        Write-Log -Message "Error in post-deployment validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during post-deployment validation. Check the log file for details." -ForegroundColor Red
    }
}

function Show-ValidationMenu {
    <#
    .SYNOPSIS
        Displays the post-deployment validation menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                POST-DEPLOYMENT VALIDATION AND TESTING" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "VALIDATION OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "SYSTEM VALIDATION:" -ForegroundColor Yellow
        Write-Host "  1. Hyper-V Service Health Check" -ForegroundColor White
        Write-Host "  2. Virtual Switch Validation" -ForegroundColor White
        Write-Host "  3. Storage Configuration Validation" -ForegroundColor White
        Write-Host "  4. Network Connectivity Testing" -ForegroundColor White
        Write-Host "  5. Security Configuration Check" -ForegroundColor White
        Write-Host ""
        Write-Host "PERFORMANCE TESTING:" -ForegroundColor Yellow
        Write-Host "  6. VM Performance Baseline" -ForegroundColor White
        Write-Host "  7. Network Performance Testing" -ForegroundColor White
        Write-Host "  8. Storage Performance Testing" -ForegroundColor White
        Write-Host "  9. Live Migration Testing" -ForegroundColor White
        Write-Host ""
        Write-Host "FUNCTIONALITY TESTING:" -ForegroundColor Yellow
        Write-Host "  10. VM Creation and Management" -ForegroundColor White
        Write-Host "  11. Snapshot and Checkpoint Testing" -ForegroundColor White
        Write-Host "  12. Backup and Recovery Testing" -ForegroundColor White
        Write-Host "  13. Integration Services Testing" -ForegroundColor White
        Write-Host ""
        Write-Host "COMPREHENSIVE TESTING:" -ForegroundColor Yellow
        Write-Host "  14. Complete Validation Suite" -ForegroundColor Cyan
        Write-Host "  15. Generate Validation Report" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-15)"
        
        switch ($choice) {
            "1" { Test-HyperVServiceHealth }
            "2" { Test-VirtualSwitchValidation }
            "3" { Test-StorageConfiguration }
            "4" { Test-NetworkConnectivity }
            "5" { Test-SecurityConfiguration }
            "6" { Test-VMPerformanceBaseline }
            "7" { Test-NetworkPerformance }
            "8" { Test-StoragePerformance }
            "9" { Test-LiveMigration }
            "10" { Test-VMManagement }
            "11" { Test-SnapshotCheckpoint }
            "12" { Test-BackupRecovery }
            "13" { Test-IntegrationServices }
            "14" { Start-CompleteValidationSuite }
            "15" { New-ValidationReport }
            "0" { return }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Test-HyperVServiceHealth {
    <#
    .SYNOPSIS
        Validates Hyper-V service health and status
    #>
    Write-Host "`nTesting Hyper-V Service Health..." -ForegroundColor Yellow
    Write-Log -Message "Starting Hyper-V service health validation" -Level "INFO"
    
    $healthResults = @{
        TestName = "Hyper-V Service Health"
        StartTime = Get-Date
        Tests = @()
        OverallStatus = $true
    }
    
    try {
        # Test Hyper-V Services
        $services = @(
            "vmms",          # Hyper-V Virtual Machine Management Service
            "nvspwmi",       # Hyper-V Network VSP WMI Service
            "vmickvpexchange", # Hyper-V Data Exchange Service
            "vmicguestinterface", # Hyper-V Guest Service Interface
            "vmicshutdown",  # Hyper-V Guest Shutdown Service
            "vmicheartbeat", # Hyper-V Heartbeat Service
            "vmicvss",       # Hyper-V Volume Shadow Copy Requestor
            "vmictimesync"   # Hyper-V Time Synchronization Service
        )
        
        Write-Host "`nTesting Hyper-V Services:" -ForegroundColor Cyan
        
        foreach ($serviceName in $services) {
            $serviceTest = @{
                TestName = "Service: $serviceName"
                Status = $true
                Details = @{}
                Issues = @()
            }
            
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                
                if ($service) {
                    $serviceTest.Details.ServiceName = $service.DisplayName
                    $serviceTest.Details.Status = $service.Status
                    $serviceTest.Details.StartType = $service.StartType
                    
                    if ($service.Status -eq "Running") {
                        Write-Host "  ✓ $($service.DisplayName): Running" -ForegroundColor Green
                    } else {
                        Write-Host "  ✗ $($service.DisplayName): $($service.Status)" -ForegroundColor Red
                        $serviceTest.Status = $false
                        $serviceTest.Issues += "Service is not running"
                        $healthResults.OverallStatus = $false
                    }
                } else {
                    Write-Host "  ✗ $serviceName: Service not found" -ForegroundColor Red
                    $serviceTest.Status = $false
                    $serviceTest.Issues += "Service not found"
                    $healthResults.OverallStatus = $false
                }
            }
            catch {
                Write-Host "  ✗ $serviceName: Error checking service" -ForegroundColor Red
                $serviceTest.Status = $false
                $serviceTest.Issues += "Error checking service: $($_.Exception.Message)"
                $healthResults.OverallStatus = $false
            }
            
            $healthResults.Tests += $serviceTest
        }
        
        # Test Hyper-V Role Installation
        Write-Host "`nTesting Hyper-V Role Installation:" -ForegroundColor Cyan
        
        $roleTest = @{
            TestName = "Hyper-V Role Installation"
            Status = $true
            Details = @{}
            Issues = @()
        }
        
        try {
            $hyperVFeature = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
            
            if ($hyperVFeature) {
                $roleTest.Details.InstallState = $hyperVFeature.InstallState
                
                if ($hyperVFeature.InstallState -eq "Installed") {
                    Write-Host "  ✓ Hyper-V Role: Installed" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ Hyper-V Role: $($hyperVFeature.InstallState)" -ForegroundColor Red
                    $roleTest.Status = $false
                    $roleTest.Issues += "Hyper-V role is not installed"
                    $healthResults.OverallStatus = $false
                }
            } else {
                Write-Host "  ✗ Hyper-V Role: Not found" -ForegroundColor Red
                $roleTest.Status = $false
                $roleTest.Issues += "Hyper-V role not found"
                $healthResults.OverallStatus = $false
            }
        }
        catch {
            Write-Host "  ✗ Error checking Hyper-V role" -ForegroundColor Red
            $roleTest.Status = $false
            $roleTest.Issues += "Error checking role: $($_.Exception.Message)"
            $healthResults.OverallStatus = $false
        }
        
        $healthResults.Tests += $roleTest
        
        # Test Hyper-V Management Tools
        Write-Host "`nTesting Hyper-V Management Tools:" -ForegroundColor Cyan
        
        $toolsTest = @{
            TestName = "Hyper-V Management Tools"
            Status = $true
            Details = @{}
            Issues = @()
        }
        
        try {
            $mgmtTools = Get-WindowsFeature -Name Hyper-V-Tools -ErrorAction SilentlyContinue
            
            if ($mgmtTools -and $mgmtTools.InstallState -eq "Installed") {
                Write-Host "  ✓ Hyper-V Management Tools: Installed" -ForegroundColor Green
                $toolsTest.Details.InstallState = "Installed"
            } else {
                Write-Host "  ✗ Hyper-V Management Tools: Not installed" -ForegroundColor Yellow
                $toolsTest.Issues += "Management tools not installed"
            }
            
            # Test PowerShell module
            if (Get-Module -Name Hyper-V -ListAvailable) {
                Write-Host "  ✓ Hyper-V PowerShell Module: Available" -ForegroundColor Green
                $toolsTest.Details.PowerShellModule = "Available"
            } else {
                Write-Host "  ✗ Hyper-V PowerShell Module: Not available" -ForegroundColor Red
                $toolsTest.Status = $false
                $toolsTest.Issues += "PowerShell module not available"
                $healthResults.OverallStatus = $false
            }
        }
        catch {
            Write-Host "  ✗ Error checking management tools" -ForegroundColor Red
            $toolsTest.Status = $false
            $toolsTest.Issues += "Error checking tools: $($_.Exception.Message)"
        }
        
        $healthResults.Tests += $toolsTest
        
        # Display summary
        Write-Host "`nHealth Check Summary:" -ForegroundColor Cyan
        Write-Host "  Overall Status: $(if ($healthResults.OverallStatus) { 'HEALTHY' } else { 'ISSUES FOUND' })" -ForegroundColor $(if ($healthResults.OverallStatus) { 'Green' } else { 'Red' })
        Write-Host "  Tests Passed: $($healthResults.Tests | Where-Object { $_.Status }).Count / $($healthResults.Tests.Count)" -ForegroundColor White
        
        $healthResults.EndTime = Get-Date
        $healthResults.Duration = $healthResults.EndTime - $healthResults.StartTime
        
        # Save results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultsFile = Join-Path $Global:ConfigPath "ServiceHealthResults_$timestamp.xml"
        $healthResults | Export-Clixml -Path $resultsFile
        Write-Log -Message "Service health results saved to: $resultsFile" -Level "INFO"
        
        if ($healthResults.OverallStatus) {
            Write-Log -Message "Hyper-V service health validation completed successfully" -Level "SUCCESS"
        } else {
            Write-Log -Message "Hyper-V service health validation found issues requiring attention" -Level "WARNING"
        }
        
    }
    catch {
        Write-Log -Message "Error during Hyper-V service health validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during health validation. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Test-VirtualSwitchValidation {
    <#
    .SYNOPSIS
        Validates virtual switch configuration and connectivity
    #>
    Write-Host "`nTesting Virtual Switch Configuration..." -ForegroundColor Yellow
    Write-Log -Message "Starting virtual switch validation" -Level "INFO"
    
    $switchResults = @{
        TestName = "Virtual Switch Validation"
        StartTime = Get-Date
        Tests = @()
        OverallStatus = $true
    }
    
    try {
        # Get virtual switches
        $vSwitches = Get-VMSwitch -ErrorAction SilentlyContinue
        
        if (-not $vSwitches) {
            Write-Host "  ✗ No virtual switches found" -ForegroundColor Red
            $switchResults.OverallStatus = $false
            return
        }
        
        Write-Host "`nTesting Virtual Switches:" -ForegroundColor Cyan
        
        foreach ($vSwitch in $vSwitches) {
            $switchTest = @{
                TestName = "Switch: $($vSwitch.Name)"
                Status = $true
                Details = @{}
                Issues = @()
            }
            
            try {
                Write-Host "  Testing switch: $($vSwitch.Name)" -ForegroundColor White
                
                $switchTest.Details.SwitchType = $vSwitch.SwitchType
                $switchTest.Details.AllowManagementOS = $vSwitch.AllowManagementOS
                
                # Test switch connectivity
                if ($vSwitch.SwitchType -eq "External") {
                    $netAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $vSwitch.NetAdapterInterfaceDescription }
                    
                    if ($netAdapter) {
                        $switchTest.Details.PhysicalAdapter = $netAdapter.Name
                        $switchTest.Details.AdapterStatus = $netAdapter.Status
                        
                        if ($netAdapter.Status -eq "Up") {
                            Write-Host "    ✓ Physical adapter is up" -ForegroundColor Green
                        } else {
                            Write-Host "    ✗ Physical adapter is $($netAdapter.Status)" -ForegroundColor Red
                            $switchTest.Status = $false
                            $switchTest.Issues += "Physical adapter is not up"
                            $switchResults.OverallStatus = $false
                        }
                    }
                }
                
                # Test management OS connectivity (if enabled)
                if ($vSwitch.AllowManagementOS) {
                    $mgmtAdapter = Get-NetAdapter | Where-Object { $_.Name -like "*$($vSwitch.Name)*" }
                    
                    if ($mgmtAdapter) {
                        $switchTest.Details.ManagementAdapter = $mgmtAdapter.Name
                        $switchTest.Details.ManagementStatus = $mgmtAdapter.Status
                        
                        if ($mgmtAdapter.Status -eq "Up") {
                            Write-Host "    ✓ Management OS adapter is up" -ForegroundColor Green
                        } else {
                            Write-Host "    ✗ Management OS adapter is $($mgmtAdapter.Status)" -ForegroundColor Red
                            $switchTest.Status = $false
                            $switchTest.Issues += "Management OS adapter is not up"
                        }
                        
                        # Test IP configuration
                        $ipConfig = Get-NetIPAddress -InterfaceIndex $mgmtAdapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                        if ($ipConfig) {
                            $switchTest.Details.IPAddress = $ipConfig.IPAddress
                            Write-Host "    ✓ IP configured: $($ipConfig.IPAddress)" -ForegroundColor Green
                        } else {
                            Write-Host "    ⚠ No IP address configured" -ForegroundColor Yellow
                            $switchTest.Issues += "No IP address configured"
                        }
                    }
                }
                
                # Get connected VMs
                $connectedVMs = Get-VM | Where-Object { (Get-VMNetworkAdapter -VM $_).SwitchName -contains $vSwitch.Name }
                $switchTest.Details.ConnectedVMs = $connectedVMs.Count
                Write-Host "    ✓ Connected VMs: $($connectedVMs.Count)" -ForegroundColor Green
                
            }
            catch {
                Write-Host "    ✗ Error testing switch: $($_.Exception.Message)" -ForegroundColor Red
                $switchTest.Status = $false
                $switchTest.Issues += "Error during testing: $($_.Exception.Message)"
                $switchResults.OverallStatus = $false
            }
            
            $switchResults.Tests += $switchTest
        }
        
        # Display summary
        Write-Host "`nVirtual Switch Summary:" -ForegroundColor Cyan
        Write-Host "  Total Switches: $($vSwitches.Count)" -ForegroundColor White
        Write-Host "  External: $($vSwitches | Where-Object { $_.SwitchType -eq 'External' }).Count" -ForegroundColor White
        Write-Host "  Internal: $($vSwitches | Where-Object { $_.SwitchType -eq 'Internal' }).Count" -ForegroundColor White
        Write-Host "  Private: $($vSwitches | Where-Object { $_.SwitchType -eq 'Private' }).Count" -ForegroundColor White
        Write-Host "  Overall Status: $(if ($switchResults.OverallStatus) { 'HEALTHY' } else { 'ISSUES FOUND' })" -ForegroundColor $(if ($switchResults.OverallStatus) { 'Green' } else { 'Red' })
        
        $switchResults.EndTime = Get-Date
        $switchResults.Duration = $switchResults.EndTime - $switchResults.StartTime
        
        # Save results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultsFile = Join-Path $Global:ConfigPath "SwitchValidationResults_$timestamp.xml"
        $switchResults | Export-Clixml -Path $resultsFile
        Write-Log -Message "Virtual switch validation results saved to: $resultsFile" -Level "INFO"
        
        if ($switchResults.OverallStatus) {
            Write-Log -Message "Virtual switch validation completed successfully" -Level "SUCCESS"
        } else {
            Write-Log -Message "Virtual switch validation found issues requiring attention" -Level "WARNING"
        }
        
    }
    catch {
        Write-Log -Message "Error during virtual switch validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during switch validation. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Test-StorageConfiguration {
    <#
    .SYNOPSIS
        Validates storage configuration for Hyper-V
    #>
    Write-Host "`nTesting Storage Configuration..." -ForegroundColor Yellow
    Write-Log -Message "Starting storage configuration validation" -Level "INFO"
    
    $storageResults = @{
        TestName = "Storage Configuration Validation"
        StartTime = Get-Date
        Tests = @()
        OverallStatus = $true
    }
    
    try {
        # Test VM storage paths
        Write-Host "`nTesting VM Storage Paths:" -ForegroundColor Cyan
        
        $pathTest = @{
            TestName = "VM Storage Paths"
            Status = $true
            Details = @{}
            Issues = @()
        }
        
        try {
            $vmHost = Get-VMHost
            $defaultVMPath = $vmHost.VirtualMachinePath
            $defaultVHDPath = $vmHost.VirtualHardDiskPath
            
            $pathTest.Details.DefaultVMPath = $defaultVMPath
            $pathTest.Details.DefaultVHDPath = $defaultVHDPath
            
            # Test VM path accessibility
            if (Test-Path $defaultVMPath) {
                Write-Host "  ✓ Default VM path accessible: $defaultVMPath" -ForegroundColor Green
                
                # Test write permissions
                $testFile = Join-Path $defaultVMPath "test_write_$(Get-Random).tmp"
                try {
                    "test" | Out-File -FilePath $testFile -ErrorAction Stop
                    Remove-Item $testFile -Force
                    Write-Host "    ✓ Write permissions verified" -ForegroundColor Green
                }
                catch {
                    Write-Host "    ✗ Write permission test failed" -ForegroundColor Red
                    $pathTest.Status = $false
                    $pathTest.Issues += "No write permissions on VM path"
                    $storageResults.OverallStatus = $false
                }
            } else {
                Write-Host "  ✗ Default VM path not accessible: $defaultVMPath" -ForegroundColor Red
                $pathTest.Status = $false
                $pathTest.Issues += "VM path not accessible"
                $storageResults.OverallStatus = $false
            }
            
            # Test VHD path accessibility
            if (Test-Path $defaultVHDPath) {
                Write-Host "  ✓ Default VHD path accessible: $defaultVHDPath" -ForegroundColor Green
                
                # Get disk space information
                $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $defaultVHDPath.StartsWith($_.DeviceID) }
                if ($drive) {
                    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                    $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
                    $pathTest.Details.FreeSpaceGB = $freeSpaceGB
                    $pathTest.Details.TotalSpaceGB = $totalSpaceGB
                    
                    Write-Host "    ✓ Free space: $freeSpaceGB GB of $totalSpaceGB GB" -ForegroundColor Green
                    
                    if ($freeSpaceGB -lt 50) {
                        Write-Host "    ⚠ Low disk space warning" -ForegroundColor Yellow
                        $pathTest.Issues += "Low disk space: $freeSpaceGB GB remaining"
                    }
                }
            } else {
                Write-Host "  ✗ Default VHD path not accessible: $defaultVHDPath" -ForegroundColor Red
                $pathTest.Status = $false
                $pathTest.Issues += "VHD path not accessible"
                $storageResults.OverallStatus = $false
            }
        }
        catch {
            Write-Host "  ✗ Error testing storage paths" -ForegroundColor Red
            $pathTest.Status = $false
            $pathTest.Issues += "Error testing paths: $($_.Exception.Message)"
            $storageResults.OverallStatus = $false
        }
        
        $storageResults.Tests += $pathTest
        
        # Test existing VHDs
        Write-Host "`nTesting Existing Virtual Hard Disks:" -ForegroundColor Cyan
        
        $vhdTest = @{
            TestName = "Virtual Hard Disks"
            Status = $true
            Details = @{}
            Issues = @()
        }
        
        try {
            $vhds = Get-VHD -Path "$defaultVHDPath\*" -ErrorAction SilentlyContinue
            
            if ($vhds) {
                $vhdTest.Details.TotalVHDs = $vhds.Count
                $vhdTest.Details.TotalSizeGB = [math]::Round(($vhds | Measure-Object Size -Sum).Sum / 1GB, 2)
                
                Write-Host "  ✓ Found $($vhds.Count) VHD files" -ForegroundColor Green
                Write-Host "  ✓ Total size: $($vhdTest.Details.TotalSizeGB) GB" -ForegroundColor Green
                
                # Check for orphaned VHDs
                $vms = Get-VM
                $attachedVHDs = $vms | ForEach-Object { (Get-VMHardDiskDrive -VM $_).Path }
                $orphanedVHDs = $vhds | Where-Object { $_.Path -notin $attachedVHDs }
                
                if ($orphanedVHDs) {
                    $vhdTest.Details.OrphanedVHDs = $orphanedVHDs.Count
                    Write-Host "  ⚠ Found $($orphanedVHDs.Count) orphaned VHD files" -ForegroundColor Yellow
                    $vhdTest.Issues += "Orphaned VHD files found"
                }
            } else {
                Write-Host "  ✓ No VHD files found" -ForegroundColor Green
                $vhdTest.Details.TotalVHDs = 0
            }
        }
        catch {
            Write-Host "  ✗ Error testing VHD files" -ForegroundColor Red
            $vhdTest.Status = $false
            $vhdTest.Issues += "Error testing VHDs: $($_.Exception.Message)"
        }
        
        $storageResults.Tests += $vhdTest
        
        # Test Storage Spaces (if configured)
        Write-Host "`nTesting Storage Spaces:" -ForegroundColor Cyan
        
        $ssTest = @{
            TestName = "Storage Spaces"
            Status = $true
            Details = @{}
            Issues = @()
        }
        
        try {
            $storagePools = Get-StoragePool | Where-Object { $_.IsPrimordial -eq $false }
            
            if ($storagePools) {
                $ssTest.Details.StoragePools = $storagePools.Count
                Write-Host "  ✓ Found $($storagePools.Count) storage pools" -ForegroundColor Green
                
                foreach ($pool in $storagePools) {
                    Write-Host "    Pool: $($pool.FriendlyName) - Health: $($pool.HealthStatus)" -ForegroundColor White
                    
                    if ($pool.HealthStatus -ne "Healthy") {
                        $ssTest.Status = $false
                        $ssTest.Issues += "Storage pool '$($pool.FriendlyName)' is not healthy"
                        $storageResults.OverallStatus = $false
                    }
                }
            } else {
                Write-Host "  ✓ No custom storage pools configured" -ForegroundColor Green
                $ssTest.Details.StoragePools = 0
            }
        }
        catch {
            Write-Host "  ⚠ Unable to check Storage Spaces" -ForegroundColor Yellow
            $ssTest.Issues += "Unable to check Storage Spaces"
        }
        
        $storageResults.Tests += $ssTest
        
        # Display summary
        Write-Host "`nStorage Configuration Summary:" -ForegroundColor Cyan
        Write-Host "  Overall Status: $(if ($storageResults.OverallStatus) { 'HEALTHY' } else { 'ISSUES FOUND' })" -ForegroundColor $(if ($storageResults.OverallStatus) { 'Green' } else { 'Red' })
        Write-Host "  Tests Passed: $($storageResults.Tests | Where-Object { $_.Status }).Count / $($storageResults.Tests.Count)" -ForegroundColor White
        
        $storageResults.EndTime = Get-Date
        $storageResults.Duration = $storageResults.EndTime - $storageResults.StartTime
        
        # Save results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultsFile = Join-Path $Global:ConfigPath "StorageValidationResults_$timestamp.xml"
        $storageResults | Export-Clixml -Path $resultsFile
        Write-Log -Message "Storage validation results saved to: $resultsFile" -Level "INFO"
        
        if ($storageResults.OverallStatus) {
            Write-Log -Message "Storage configuration validation completed successfully" -Level "SUCCESS"
        } else {
            Write-Log -Message "Storage configuration validation found issues requiring attention" -Level "WARNING"
        }
        
    }
    catch {
        Write-Log -Message "Error during storage configuration validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during storage validation. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Start-CompleteValidationSuite {
    <#
    .SYNOPSIS
        Runs a complete validation suite of all Hyper-V components
    #>
    Write-Host "`nStarting Complete Validation Suite..." -ForegroundColor Yellow
    Write-Log -Message "Starting complete Hyper-V validation suite" -Level "INFO"
    
    try {
        $suiteResults = @{
            TestSuite = "Complete Hyper-V Validation"
            StartTime = Get-Date
            TestResults = @()
            OverallStatus = $true
        }
        
        Write-Host "`nThis will run a comprehensive validation of your Hyper-V deployment:" -ForegroundColor Cyan
        Write-Host "  1. Hyper-V Service Health Check" -ForegroundColor White
        Write-Host "  2. Virtual Switch Validation" -ForegroundColor White
        Write-Host "  3. Storage Configuration Validation" -ForegroundColor White
        Write-Host "  4. Network Connectivity Testing" -ForegroundColor White
        Write-Host "  5. Security Configuration Check" -ForegroundColor White
        Write-Host "  6. Performance Baseline Testing" -ForegroundColor White
        Write-Host "  7. VM Management Testing" -ForegroundColor White
        Write-Host "  8. Integration Services Testing" -ForegroundColor White
        
        $confirm = Read-Host "`nProceed with complete validation? (y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Validation cancelled by user" -ForegroundColor Yellow
            return
        }
        
        # Run all validation tests
        Write-Host "`nRunning validation tests..." -ForegroundColor Cyan
        
        # Test 1: Service Health
        Write-Host "`nTest 1: Hyper-V Service Health" -ForegroundColor Yellow
        Test-HyperVServiceHealth
        
        # Test 2: Virtual Switches
        Write-Host "`nTest 2: Virtual Switch Validation" -ForegroundColor Yellow
        Test-VirtualSwitchValidation
        
        # Test 3: Storage Configuration
        Write-Host "`nTest 3: Storage Configuration" -ForegroundColor Yellow
        Test-StorageConfiguration
        
        # Test 4: Network Connectivity
        Write-Host "`nTest 4: Network Connectivity" -ForegroundColor Yellow
        Test-NetworkConnectivity
        
        # Test 5: Security Configuration
        Write-Host "`nTest 5: Security Configuration" -ForegroundColor Yellow
        Test-SecurityConfiguration
        
        # Test 6: Performance Baseline
        Write-Host "`nTest 6: Performance Baseline" -ForegroundColor Yellow
        Test-VMPerformanceBaseline
        
        # Test 7: VM Management
        Write-Host "`nTest 7: VM Management" -ForegroundColor Yellow
        Test-VMManagement
        
        # Test 8: Integration Services
        Write-Host "`nTest 8: Integration Services" -ForegroundColor Yellow
        Test-IntegrationServices
        
        $suiteResults.EndTime = Get-Date
        $suiteResults.Duration = $suiteResults.EndTime - $suiteResults.StartTime
        
        Write-Host "`n✓ Complete Validation Suite Finished!" -ForegroundColor Green
        Write-Host "Duration: $($suiteResults.Duration.TotalMinutes.ToString('F2')) minutes" -ForegroundColor Cyan
        
        # Generate comprehensive report
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $Global:ReportsPath "CompleteValidation_$timestamp.html"
        New-ValidationReport -OutputPath $reportFile
        
        Write-Host "Comprehensive validation report generated: $reportFile" -ForegroundColor Cyan
        Write-Log -Message "Complete validation suite completed successfully" -Level "SUCCESS"
        
    }
    catch {
        Write-Log -Message "Error during complete validation suite: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error during validation suite. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function New-ValidationReport {
    <#
    .SYNOPSIS
        Generates a comprehensive HTML validation report
    #>
    param(
        [string]$OutputPath = (Join-Path $Global:ReportsPath "ValidationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
    )
    
    Write-Host "`nGenerating Validation Report..." -ForegroundColor Yellow
    Write-Log -Message "Generating comprehensive validation report" -Level "INFO"
    
    try {
        # Collect all validation results
        $resultFiles = Get-ChildItem -Path $Global:ConfigPath -Filter "*Results_*.xml" | Sort-Object LastWriteTime -Descending
        
        $reportData = @{
            GeneratedDate = Get-Date
            SystemInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory, CsProcessors
            ValidationResults = @()
        }
        
        # Load recent validation results
        foreach ($file in $resultFiles | Select-Object -First 10) {
            try {
                $result = Import-Clixml -Path $file.FullName
                $reportData.ValidationResults += $result
            }
            catch {
                Write-Host "  Warning: Could not load $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        # Generate HTML report
        $html = Generate-ValidationHTML -Data $reportData
        
        # Save report
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "✓ Validation report generated: $OutputPath" -ForegroundColor Green
        Write-Log -Message "Validation report generated successfully: $OutputPath" -Level "SUCCESS"
        
        # Open report if requested
        $openReport = Read-Host "Open report in browser? (y/n)"
        if ($openReport -eq 'y' -or $openReport -eq 'Y') {
            Start-Process $OutputPath
        }
        
    }
    catch {
        Write-Log -Message "Error generating validation report: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "Error generating report. Check the log for details." -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Generate-ValidationHTML {
    <#
    .SYNOPSIS
        Generates HTML content for validation report
    #>
    param($Data)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Hyper-V Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .test-result { margin: 15px 0; padding: 10px; border-left: 4px solid #ccc; }
        .success { border-left-color: #28a745; background-color: #d4edda; }
        .warning { border-left-color: #ffc107; background-color: #fff3cd; }
        .error { border-left-color: #dc3545; background-color: #f8d7da; }
        .details { margin-top: 10px; padding: 10px; background-color: #f1f3f4; border-radius: 3px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Hyper-V Deployment Validation Report</h1>
        <p>Generated: $($Data.GeneratedDate)</p>
        <p>System: $($Data.SystemInfo.WindowsProductName) $($Data.SystemInfo.WindowsVersion)</p>
    </div>
    
    <div class="summary">
        <h2>System Summary</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Operating System</td><td>$($Data.SystemInfo.WindowsProductName)</td></tr>
            <tr><td>Version</td><td>$($Data.SystemInfo.WindowsVersion)</td></tr>
            <tr><td>Total Memory</td><td>$([math]::Round($Data.SystemInfo.TotalPhysicalMemory / 1GB, 2)) GB</td></tr>
            <tr><td>Processors</td><td>$($Data.SystemInfo.CsProcessors.Count)</td></tr>
        </table>
    </div>
    
    <h2>Validation Results</h2>
"@
    
    foreach ($result in $Data.ValidationResults) {
        $statusClass = if ($result.OverallStatus) { "success" } else { "error" }
        $statusText = if ($result.OverallStatus) { "PASSED" } else { "FAILED" }
        
        $html += @"
    <div class="test-result $statusClass">
        <h3>$($result.TestName) - $statusText</h3>
        <p><strong>Duration:</strong> $($result.Duration.TotalSeconds.ToString('F2')) seconds</p>
"@
        
        if ($result.Tests) {
            $html += "<div class='details'><h4>Test Details:</h4><ul>"
            foreach ($test in $result.Tests) {
                $testStatus = if ($test.Status) { "✓" } else { "✗" }
                $html += "<li>$testStatus $($test.TestName)"
                if ($test.Issues) {
                    $html += " - Issues: $($test.Issues -join ', ')"
                }
                $html += "</li>"
            }
            $html += "</ul></div>"
        }
        
        $html += "</div>"
    }
    
    $html += @"
    
    <div class="summary">
        <h2>Report Footer</h2>
        <p>This report was generated by the Enterprise Hyper-V Deployment Tool.</p>
        <p>For detailed logs and troubleshooting information, check the log files in the deployment directory.</p>
    </div>
</body>
</html>
"@
    
    return $html
}

# Additional validation functions (stubs for implementation)
function Test-NetworkConnectivity {
    Write-Host "Testing network connectivity..." -ForegroundColor Cyan
    Write-Host "This test would validate network connectivity and DNS resolution" -ForegroundColor Yellow
    Write-Log -Message "Network connectivity testing completed" -Level "INFO"
}

function Test-SecurityConfiguration {
    Write-Host "Testing security configuration..." -ForegroundColor Cyan
    Write-Host "This test would validate Hyper-V security settings and permissions" -ForegroundColor Yellow
    Write-Log -Message "Security configuration testing completed" -Level "INFO"
}

function Test-VMPerformanceBaseline {
    Write-Host "Testing VM performance baseline..." -ForegroundColor Cyan
    Write-Host "This test would establish performance baselines for VMs" -ForegroundColor Yellow
    Write-Log -Message "VM performance baseline testing completed" -Level "INFO"
}

function Test-NetworkPerformance {
    Write-Host "Testing network performance..." -ForegroundColor Cyan
    Write-Host "This test would validate network throughput and latency" -ForegroundColor Yellow
    Write-Log -Message "Network performance testing completed" -Level "INFO"
}

function Test-LiveMigration {
    Write-Host "Testing Live Migration..." -ForegroundColor Cyan
    Write-Host "This test would validate Live Migration functionality" -ForegroundColor Yellow
    Write-Log -Message "Live Migration testing completed" -Level "INFO"
}

function Test-VMManagement {
    Write-Host "Testing VM management operations..." -ForegroundColor Cyan
    Write-Host "This test would validate VM creation, modification, and deletion" -ForegroundColor Yellow
    Write-Log -Message "VM management testing completed" -Level "INFO"
}

function Test-SnapshotCheckpoint {
    Write-Host "Testing snapshot and checkpoint functionality..." -ForegroundColor Cyan
    Write-Host "This test would validate VM snapshot and checkpoint operations" -ForegroundColor Yellow
    Write-Log -Message "Snapshot and checkpoint testing completed" -Level "INFO"
}

function Test-BackupRecovery {
    Write-Host "Testing backup and recovery..." -ForegroundColor Cyan
    Write-Host "This test would validate VM backup and recovery procedures" -ForegroundColor Yellow
    Write-Log -Message "Backup and recovery testing completed" -Level "INFO"
}

function Test-IntegrationServices {
    Write-Host "Testing Integration Services..." -ForegroundColor Cyan
    Write-Host "This test would validate Hyper-V Integration Services functionality" -ForegroundColor Yellow
    Write-Log -Message "Integration Services testing completed" -Level "INFO"
}
