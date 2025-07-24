# Log Viewer Module
# Contains functions for viewing and analyzing Hyper-V deployment logs

function Start-LogViewer {
    <#
    .SYNOPSIS
        Manages log viewing and analysis for Hyper-V deployment
    .DESCRIPTION
        Provides functionality to view, filter, search, and analyze deployment logs
        with real-time monitoring capabilities
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting log viewer workflow..." -Level "INFO"
    
    try {
        Show-LogViewerMenu
        
    }
    catch {
        Write-Log -Message "Error in log viewer: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred in log viewer. Check the log file for details." -ForegroundColor Red
    }
}

function Show-LogViewerMenu {
    <#
    .SYNOPSIS
        Displays the log viewer menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    DEPLOYMENT LOGS AND STATUS VIEWER" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "LOG VIEWER OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "VIEW LOGS:" -ForegroundColor Yellow
        Write-Host "  1. View Current Session Log" -ForegroundColor White
        Write-Host "  2. View All Log Files" -ForegroundColor White
        Write-Host "  3. View Specific Log File" -ForegroundColor White
        Write-Host "  4. View Recent Errors Only" -ForegroundColor White
        Write-Host "  5. View Recent Warnings Only" -ForegroundColor White
        Write-Host "  6. Real-time Log Monitoring" -ForegroundColor White
        Write-Host ""
        Write-Host "SEARCH AND FILTER:" -ForegroundColor Yellow
        Write-Host "  7. Search Logs by Keyword" -ForegroundColor White
        Write-Host "  8. Filter by Date Range" -ForegroundColor White
        Write-Host "  9. Filter by Log Level" -ForegroundColor White
        Write-Host "  10. Filter by Module/Component" -ForegroundColor White
        Write-Host ""
        Write-Host "ANALYSIS:" -ForegroundColor Yellow
        Write-Host "  11. Generate Log Summary" -ForegroundColor White
        Write-Host "  12. Deployment Status Overview" -ForegroundColor White
        Write-Host "  13. Error Analysis Report" -ForegroundColor White
        Write-Host "  14. Performance Metrics" -ForegroundColor White
        Write-Host ""
        Write-Host "MAINTENANCE:" -ForegroundColor Yellow
        Write-Host "  15. Clean Old Log Files" -ForegroundColor White
        Write-Host "  16. Export Logs to Archive" -ForegroundColor White
        Write-Host ""
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Please select an option (0-16)"
        
        switch ($choice) {
            "1" { Show-CurrentSessionLog }
            "2" { Show-AllLogFiles }
            "3" { Show-SpecificLogFile }
            "4" { Show-RecentErrors }
            "5" { Show-RecentWarnings }
            "6" { Start-RealTimeLogMonitoring }
            "7" { Search-LogsByKeyword }
            "8" { Show-LogsByDateRange }
            "9" { Show-LogsByLevel }
            "10" { Show-LogsByModule }
            "11" { New-LogSummary }
            "12" { Show-DeploymentStatusOverview }
            "13" { New-ErrorAnalysisReport }
            "14" { Show-PerformanceMetrics }
            "15" { Remove-OldLogFiles }
            "16" { Export-LogsToArchive }
            "0" { return }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Show-CurrentSessionLog {
    <#
    .SYNOPSIS
        Displays the current session log file
    #>
    Write-Host "`nDisplaying Current Session Log" -ForegroundColor Yellow
    Write-Log -Message "Displaying current session log" -Level "INFO"
    
    try {
        if (-not (Test-Path $Global:LogFile)) {
            Write-Host "Current session log file not found: $Global:LogFile" -ForegroundColor Red
            return
        }
        
        $logContent = Get-Content -Path $Global:LogFile
        
        if ($logContent.Count -eq 0) {
            Write-Host "Log file is empty" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nCurrent Session Log: $Global:LogFile" -ForegroundColor Cyan
        Write-Host "Total Lines: $($logContent.Count)" -ForegroundColor White
        Write-Host "Log File Size: $([math]::Round((Get-Item $Global:LogFile).Length / 1KB, 2)) KB" -ForegroundColor White
        Write-Host ""
        Write-Host "Recent entries (last 50 lines):" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $recentLines = $logContent | Select-Object -Last 50
        
        foreach ($line in $recentLines) {
            $color = "White"
            
            if ($line -match "\[ERROR\]") { $color = "Red" }
            elseif ($line -match "\[WARNING\]") { $color = "Yellow" }
            elseif ($line -match "\[SUCCESS\]") { $color = "Green" }
            elseif ($line -match "\[INFO\]") { $color = "Cyan" }
            
            Write-Host $line -ForegroundColor $color
        }
        
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $showAll = Read-Host "`nShow complete log file? (y/n)"
        if ($showAll -eq 'y' -or $showAll -eq 'Y') {
            $logContent | Out-Host -Paging
        }
        
    }
    catch {
        Write-Host "Error displaying current session log: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error displaying current session log: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-AllLogFiles {
    <#
    .SYNOPSIS
        Displays information about all log files
    #>
    Write-Host "`nAll Log Files Overview" -ForegroundColor Yellow
    Write-Log -Message "Displaying all log files overview" -Level "INFO"
    
    try {
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending
        
        if ($logFiles.Count -eq 0) {
            Write-Host "No log files found in: $Global:LogPath" -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nFound $($logFiles.Count) log file(s):" -ForegroundColor Cyan
        Write-Host ""
        
        $totalSize = 0
        for ($i = 0; $i -lt $logFiles.Count; $i++) {
            $file = $logFiles[$i]
            $sizeKB = [math]::Round($file.Length / 1KB, 2)
            $totalSize += $file.Length
            
            $ageColor = "White"
            $age = (Get-Date) - $file.LastWriteTime
            if ($age.Days -gt 7) { $ageColor = "Gray" }
            elseif ($age.Days -gt 1) { $ageColor = "Yellow" }
            else { $ageColor = "Green" }
            
            Write-Host "  $($i + 1). $($file.Name)" -ForegroundColor White
            Write-Host "     Size: $sizeKB KB" -ForegroundColor Gray
            Write-Host "     Modified: $($file.LastWriteTime)" -ForegroundColor $ageColor
            Write-Host "     Age: $($age.Days) days, $($age.Hours) hours" -ForegroundColor $ageColor
            
            # Quick log analysis
            try {
                $content = Get-Content -Path $file.FullName
                $errorCount = ($content | Where-Object { $_ -match "\[ERROR\]" }).Count
                $warningCount = ($content | Where-Object { $_ -match "\[WARNING\]" }).Count
                $successCount = ($content | Where-Object { $_ -match "\[SUCCESS\]" }).Count
                
                Write-Host "     Entries: $($content.Count) total" -ForegroundColor Gray
                if ($errorCount -gt 0) { Write-Host "     Errors: $errorCount" -ForegroundColor Red }
                if ($warningCount -gt 0) { Write-Host "     Warnings: $warningCount" -ForegroundColor Yellow }
                if ($successCount -gt 0) { Write-Host "     Success: $successCount" -ForegroundColor Green }
            }
            catch {
                Write-Host "     Status: Unable to analyze content" -ForegroundColor Yellow
            }
            
            Write-Host ""
        }
        
        Write-Host "Total log storage: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
        
        $viewSpecific = Read-Host "Would you like to view a specific log file? (Enter number or 'n' for no)"
        
        if ($viewSpecific -ne 'n' -and $viewSpecific -ne 'N') {
            $fileIndex = [int]$viewSpecific - 1
            if ($fileIndex -ge 0 -and $fileIndex -lt $logFiles.Count) {
                Show-LogFileContent -LogFile $logFiles[$fileIndex].FullName
            }
        }
        
    }
    catch {
        Write-Host "Error displaying log files: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error displaying log files: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-LogFileContent {
    <#
    .SYNOPSIS
        Displays the content of a specific log file
    #>
    param([string]$LogFile)
    
    try {
        $content = Get-Content -Path $LogFile
        
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    LOG FILE VIEWER" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "File: $LogFile" -ForegroundColor Yellow
        Write-Host "Lines: $($content.Count)" -ForegroundColor White
        Write-Host "Size: $([math]::Round((Get-Item $LogFile).Length / 1KB, 2)) KB" -ForegroundColor White
        Write-Host "Modified: $((Get-Item $LogFile).LastWriteTime)" -ForegroundColor White
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Display with color coding
        foreach ($line in $content) {
            $color = "White"
            
            if ($line -match "\[ERROR\]") { $color = "Red" }
            elseif ($line -match "\[WARNING\]") { $color = "Yellow" }
            elseif ($line -match "\[SUCCESS\]") { $color = "Green" }
            elseif ($line -match "\[INFO\]") { $color = "Cyan" }
            
            Write-Host $line -ForegroundColor $color
        }
        
    }
    catch {
        Write-Host "Error displaying log file content: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-RecentErrors {
    <#
    .SYNOPSIS
        Displays recent error entries from all log files
    #>
    Write-Host "`nRecent Error Entries" -ForegroundColor Yellow
    Write-Log -Message "Displaying recent error entries" -Level "INFO"
    
    try {
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending
        $allErrors = @()
        
        foreach ($file in $logFiles) {
            try {
                $content = Get-Content -Path $file.FullName
                $errors = $content | Where-Object { $_ -match "\[ERROR\]" }
                
                foreach ($error in $errors) {
                    # Parse timestamp if available
                    if ($error -match '^\[([^\]]+)\]') {
                        try {
                            $timestamp = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                        }
                        catch {
                            $timestamp = $file.LastWriteTime
                        }
                    } else {
                        $timestamp = $file.LastWriteTime
                    }
                    
                    $allErrors += [PSCustomObject]@{
                        Timestamp = $timestamp
                        LogFile = $file.Name
                        Message = $error
                    }
                }
            }
            catch {
                Write-Host "Warning: Could not read $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        $recentErrors = $allErrors | Sort-Object Timestamp -Descending | Select-Object -First 25
        
        if ($recentErrors.Count -eq 0) {
            Write-Host "No error entries found in log files" -ForegroundColor Green
            return
        }
        
        Write-Host "`nFound $($allErrors.Count) total error(s), showing most recent 25:" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($error in $recentErrors) {
            Write-Host "[$($error.Timestamp)] [$($error.LogFile)]" -ForegroundColor Gray
            Write-Host "$($error.Message)" -ForegroundColor Red
            Write-Host ""
        }
        
        if ($allErrors.Count -gt 25) {
            $showAll = Read-Host "Show all $($allErrors.Count) errors? (y/n)"
            if ($showAll -eq 'y' -or $showAll -eq 'Y') {
                $allErrors | Sort-Object Timestamp -Descending | ForEach-Object {
                    Write-Host "[$($_.Timestamp)] [$($_.LogFile)]" -ForegroundColor Gray
                    Write-Host "$($_.Message)" -ForegroundColor Red
                    Write-Host ""
                }
            }
        }
        
    }
    catch {
        Write-Host "Error displaying recent errors: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error displaying recent errors: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-RecentWarnings {
    <#
    .SYNOPSIS
        Displays recent warning entries from all log files
    #>
    Write-Host "`nRecent Warning Entries" -ForegroundColor Yellow
    Write-Log -Message "Displaying recent warning entries" -Level "INFO"
    
    try {
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending
        $allWarnings = @()
        
        foreach ($file in $logFiles) {
            try {
                $content = Get-Content -Path $file.FullName
                $warnings = $content | Where-Object { $_ -match "\[WARNING\]" }
                
                foreach ($warning in $warnings) {
                    # Parse timestamp if available
                    if ($warning -match '^\[([^\]]+)\]') {
                        try {
                            $timestamp = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                        }
                        catch {
                            $timestamp = $file.LastWriteTime
                        }
                    } else {
                        $timestamp = $file.LastWriteTime
                    }
                    
                    $allWarnings += [PSCustomObject]@{
                        Timestamp = $timestamp
                        LogFile = $file.Name
                        Message = $warning
                    }
                }
            }
            catch {
                Write-Host "Warning: Could not read $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        $recentWarnings = $allWarnings | Sort-Object Timestamp -Descending | Select-Object -First 25
        
        if ($recentWarnings.Count -eq 0) {
            Write-Host "No warning entries found in log files" -ForegroundColor Green
            return
        }
        
        Write-Host "`nFound $($allWarnings.Count) total warning(s), showing most recent 25:" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($warning in $recentWarnings) {
            Write-Host "[$($warning.Timestamp)] [$($warning.LogFile)]" -ForegroundColor Gray
            Write-Host "$($warning.Message)" -ForegroundColor Yellow
            Write-Host ""
        }
        
        if ($allWarnings.Count -gt 25) {
            $showAll = Read-Host "Show all $($allWarnings.Count) warnings? (y/n)"
            if ($showAll -eq 'y' -or $showAll -eq 'Y') {
                $allWarnings | Sort-Object Timestamp -Descending | ForEach-Object {
                    Write-Host "[$($_.Timestamp)] [$($_.LogFile)]" -ForegroundColor Gray
                    Write-Host "$($_.Message)" -ForegroundColor Yellow
                    Write-Host ""
                }
            }
        }
        
    }
    catch {
        Write-Host "Error displaying recent warnings: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error displaying recent warnings: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Start-RealTimeLogMonitoring {
    <#
    .SYNOPSIS
        Starts real-time monitoring of the current log file
    #>
    Write-Host "`nStarting Real-Time Log Monitoring" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Cyan
    Write-Log -Message "Starting real-time log monitoring" -Level "INFO"
    
    try {
        if (-not (Test-Path $Global:LogFile)) {
            Write-Host "Current log file not found: $Global:LogFile" -ForegroundColor Red
            return
        }
        
        Write-Host "`nMonitoring: $Global:LogFile" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Gray
        
        # Get current file position
        $initialContent = Get-Content -Path $Global:LogFile
        $lastLineCount = $initialContent.Count
        
        # Monitor for new content
        while ($true) {
            Start-Sleep -Seconds 2
            
            try {
                $currentContent = Get-Content -Path $Global:LogFile
                $currentLineCount = $currentContent.Count
                
                if ($currentLineCount -gt $lastLineCount) {
                    $newLines = $currentContent | Select-Object -Skip $lastLineCount
                    
                    foreach ($line in $newLines) {
                        $color = "White"
                        
                        if ($line -match "\[ERROR\]") { $color = "Red" }
                        elseif ($line -match "\[WARNING\]") { $color = "Yellow" }
                        elseif ($line -match "\[SUCCESS\]") { $color = "Green" }
                        elseif ($line -match "\[INFO\]") { $color = "Cyan" }
                        
                        Write-Host $line -ForegroundColor $color
                    }
                    
                    $lastLineCount = $currentLineCount
                }
            }
            catch {
                Write-Host "Error reading log file: $($_.Exception.Message)" -ForegroundColor Red
                break
            }
        }
        
    }
    catch {
        Write-Host "Error in real-time log monitoring: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error in real-time log monitoring: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Host "`nReal-time monitoring stopped" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function New-LogSummary {
    <#
    .SYNOPSIS
        Generates a comprehensive log summary report
    #>
    Write-Host "`nGenerating Log Summary Report" -ForegroundColor Yellow
    Write-Log -Message "Generating log summary report" -Level "INFO"
    
    try {
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending
        
        if ($logFiles.Count -eq 0) {
            Write-Host "No log files found for analysis" -ForegroundColor Yellow
            return
        }
        
        $summary = @{
            GeneratedDate = Get-Date
            TotalLogFiles = $logFiles.Count
            TotalSizeKB = [math]::Round(($logFiles | Measure-Object Length -Sum).Sum / 1KB, 2)
            DateRange = @{
                Oldest = ($logFiles | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime
                Newest = ($logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
            }
            Statistics = @{
                TotalEntries = 0
                InfoEntries = 0
                WarningEntries = 0
                ErrorEntries = 0
                SuccessEntries = 0
            }
            FileDetails = @()
        }
        
        Write-Host "Analyzing log files..." -ForegroundColor Cyan
        
        foreach ($file in $logFiles) {
            Write-Host "  Processing: $($file.Name)..." -ForegroundColor White
            
            try {
                $content = Get-Content -Path $file.FullName
                
                $fileDetail = @{
                    FileName = $file.Name
                    LastModified = $file.LastWriteTime
                    SizeKB = [math]::Round($file.Length / 1KB, 2)
                    TotalLines = $content.Count
                    InfoCount = ($content | Where-Object { $_ -match "\[INFO\]" }).Count
                    WarningCount = ($content | Where-Object { $_ -match "\[WARNING\]" }).Count
                    ErrorCount = ($content | Where-Object { $_ -match "\[ERROR\]" }).Count
                    SuccessCount = ($content | Where-Object { $_ -match "\[SUCCESS\]" }).Count
                }
                
                $summary.Statistics.TotalEntries += $fileDetail.TotalLines
                $summary.Statistics.InfoEntries += $fileDetail.InfoCount
                $summary.Statistics.WarningEntries += $fileDetail.WarningCount
                $summary.Statistics.ErrorEntries += $fileDetail.ErrorCount
                $summary.Statistics.SuccessEntries += $fileDetail.SuccessCount
                
                $summary.FileDetails += $fileDetail
                
            }
            catch {
                Write-Host "    Warning: Could not analyze $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        # Display summary
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    LOG SUMMARY REPORT" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "Generated: $($summary.GeneratedDate)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "OVERVIEW:" -ForegroundColor Yellow
        Write-Host "  Total Log Files: $($summary.TotalLogFiles)" -ForegroundColor White
        Write-Host "  Total Storage: $($summary.TotalSizeKB) KB" -ForegroundColor White
        Write-Host "  Date Range: $($summary.DateRange.Oldest) to $($summary.DateRange.Newest)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "STATISTICS:" -ForegroundColor Yellow
        Write-Host "  Total Entries: $($summary.Statistics.TotalEntries)" -ForegroundColor White
        Write-Host "  Info Entries: $($summary.Statistics.InfoEntries)" -ForegroundColor Cyan
        Write-Host "  Success Entries: $($summary.Statistics.SuccessEntries)" -ForegroundColor Green
        Write-Host "  Warning Entries: $($summary.Statistics.WarningEntries)" -ForegroundColor Yellow
        Write-Host "  Error Entries: $($summary.Statistics.ErrorEntries)" -ForegroundColor Red
        Write-Host ""
        
        Write-Host "FILE DETAILS:" -ForegroundColor Yellow
        foreach ($detail in $summary.FileDetails) {
            Write-Host "  $($detail.FileName)" -ForegroundColor White
            Write-Host "    Size: $($detail.SizeKB) KB, Lines: $($detail.TotalLines)" -ForegroundColor Gray
            Write-Host "    Info: $($detail.InfoCount), Success: $($detail.SuccessCount), Warnings: $($detail.WarningCount), Errors: $($detail.ErrorCount)" -ForegroundColor Gray
            Write-Host "    Modified: $($detail.LastModified)" -ForegroundColor Gray
            Write-Host ""
        }
        
        # Save summary report
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $Global:ReportsPath "LogSummary_$timestamp.xml"
        $summary | Export-Clixml -Path $reportFile
        
        Write-Host "Log summary saved to: $reportFile" -ForegroundColor Cyan
        Write-Log -Message "Log summary report generated: $reportFile" -Level "SUCCESS"
        
    }
    catch {
        Write-Host "Error generating log summary: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error generating log summary: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-DeploymentStatusOverview {
    <#
    .SYNOPSIS
        Shows overall deployment status based on log analysis
    #>
    Write-Host "`nDeployment Status Overview" -ForegroundColor Yellow
    Write-Log -Message "Displaying deployment status overview" -Level "INFO"
    
    try {
        # Analyze recent deployment activities
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        $deploymentStatus = @{
            OverallHealth = "Unknown"
            LastDeployment = $null
            RecentErrors = 0
            RecentWarnings = 0
            RecentSuccess = 0
            ComponentStatus = @{}
        }
        
        Write-Host "Analyzing recent deployment activities..." -ForegroundColor Cyan
        
        foreach ($file in $logFiles) {
            try {
                $content = Get-Content -Path $file.FullName
                
                # Look for deployment-specific entries
                $systemValidation = $content | Where-Object { $_ -match "System validation" }
                $hyperVDeployment = $content | Where-Object { $_ -match "Hyper-V.*deployment" }
                $templateConfig = $content | Where-Object { $_ -match "template.*config" }
                $networkConfig = $content | Where-Object { $_ -match "network.*config" }
                
                # Count recent issues
                $deploymentStatus.RecentErrors += ($content | Where-Object { $_ -match "\[ERROR\]" }).Count
                $deploymentStatus.RecentWarnings += ($content | Where-Object { $_ -match "\[WARNING\]" }).Count
                $deploymentStatus.RecentSuccess += ($content | Where-Object { $_ -match "\[SUCCESS\]" }).Count
                
                # Determine component status
                if ($systemValidation) {
                    $lastValidation = $systemValidation | Select-Object -Last 1
                    if ($lastValidation -match "completed successfully") {
                        $deploymentStatus.ComponentStatus.SystemValidation = "Healthy"
                    } elseif ($lastValidation -match "ERROR") {
                        $deploymentStatus.ComponentStatus.SystemValidation = "Error"
                    } else {
                        $deploymentStatus.ComponentStatus.SystemValidation = "Warning"
                    }
                }
                
                if ($hyperVDeployment) {
                    $lastDeployment = $hyperVDeployment | Select-Object -Last 1
                    if ($lastDeployment -match "completed successfully") {
                        $deploymentStatus.ComponentStatus.HyperVDeployment = "Healthy"
                        $deploymentStatus.LastDeployment = $file.LastWriteTime
                    } elseif ($lastDeployment -match "ERROR") {
                        $deploymentStatus.ComponentStatus.HyperVDeployment = "Error"
                    } else {
                        $deploymentStatus.ComponentStatus.HyperVDeployment = "Warning"
                    }
                }
                
            }
            catch {
                Write-Host "Warning: Could not analyze $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        # Determine overall health
        if ($deploymentStatus.RecentErrors -eq 0 -and $deploymentStatus.RecentWarnings -eq 0) {
            $deploymentStatus.OverallHealth = "Healthy"
        } elseif ($deploymentStatus.RecentErrors -eq 0) {
            $deploymentStatus.OverallHealth = "Warning"
        } else {
            $deploymentStatus.OverallHealth = "Error"
        }
        
        # Display status
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    DEPLOYMENT STATUS OVERVIEW" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $healthColor = switch ($deploymentStatus.OverallHealth) {
            "Healthy" { "Green" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "White" }
        }
        
        Write-Host "OVERALL STATUS: $($deploymentStatus.OverallHealth.ToUpper())" -ForegroundColor $healthColor
        Write-Host ""
        
        if ($deploymentStatus.LastDeployment) {
            Write-Host "LAST DEPLOYMENT: $($deploymentStatus.LastDeployment)" -ForegroundColor White
        } else {
            Write-Host "LAST DEPLOYMENT: No recent deployments found" -ForegroundColor Yellow
        }
        Write-Host ""
        
        Write-Host "RECENT ACTIVITY SUMMARY:" -ForegroundColor Yellow
        Write-Host "  Success Operations: $($deploymentStatus.RecentSuccess)" -ForegroundColor Green
        Write-Host "  Warnings: $($deploymentStatus.RecentWarnings)" -ForegroundColor Yellow
        Write-Host "  Errors: $($deploymentStatus.RecentErrors)" -ForegroundColor Red
        Write-Host ""
        
        if ($deploymentStatus.ComponentStatus.Count -gt 0) {
            Write-Host "COMPONENT STATUS:" -ForegroundColor Yellow
            foreach ($component in $deploymentStatus.ComponentStatus.GetEnumerator()) {
                $componentColor = switch ($component.Value) {
                    "Healthy" { "Green" }
                    "Warning" { "Yellow" }
                    "Error" { "Red" }
                    default { "White" }
                }
                Write-Host "  $($component.Key): $($component.Value)" -ForegroundColor $componentColor
            }
        } else {
            Write-Host "COMPONENT STATUS: No component information available" -ForegroundColor Gray
        }
        
    }
    catch {
        Write-Host "Error displaying deployment status: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error displaying deployment status: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Read-Host "`nPress Enter to continue"
}

# Additional helper functions (stubs for implementation)
function Show-SpecificLogFile {
    Write-Host "Viewing specific log file..." -ForegroundColor Cyan
    Write-Host "This function would allow selection and viewing of a specific log file" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Search-LogsByKeyword {
    Write-Host "Searching logs by keyword..." -ForegroundColor Cyan
    Write-Host "This function would search all logs for specified keywords" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Show-LogsByDateRange {
    Write-Host "Filtering logs by date range..." -ForegroundColor Cyan
    Write-Host "This function would filter logs within a specified date range" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Show-LogsByLevel {
    Write-Host "Filtering logs by level..." -ForegroundColor Cyan
    Write-Host "This function would filter logs by specific levels (INFO, WARNING, ERROR, SUCCESS)" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Show-LogsByModule {
    Write-Host "Filtering logs by module..." -ForegroundColor Cyan
    Write-Host "This function would filter logs by specific modules or components" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function New-ErrorAnalysisReport {
    Write-Host "Generating error analysis report..." -ForegroundColor Cyan
    Write-Host "This function would analyze error patterns and generate a detailed report" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Show-PerformanceMetrics {
    Write-Host "Displaying performance metrics..." -ForegroundColor Cyan
    Write-Host "This function would show deployment performance metrics and timing" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Remove-OldLogFiles {
    Write-Host "Cleaning old log files..." -ForegroundColor Cyan
    Write-Host "This function would remove log files older than specified retention period" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Export-LogsToArchive {
    Write-Host "Exporting logs to archive..." -ForegroundColor Cyan
    Write-Host "This function would compress and archive old log files" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}
