#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive Hyper-V Deployment and Configuration Script
    
.DESCRIPTION
    Enterprise-ready PowerShell script for deploying and configuring Hyper-V 
    on Windows Server physical hosts with menu-driven interface.
    
.AUTHOR
    Created: June 11, 2025
    
.NOTES
    Requires Administrator privileges and PowerShell 5.1 or higher
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$Silent,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Global Variables
$Global:ScriptVersion = "1.0.0"
$Global:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Global:LogPath = Join-Path $ScriptPath "Logs"
$Global:ConfigPath = Join-Path $ScriptPath "Configs"
$Global:TemplatePath = Join-Path $ScriptPath "Templates"
$Global:ReportPath = Join-Path $ScriptPath "Reports"
$Global:ModulePath = Join-Path $ScriptPath "Modules"
$Global:LogFile = ""

# Import required modules
. (Join-Path $Global:ModulePath "SystemValidation.ps1")
. (Join-Path $Global:ModulePath "SingleHostDeployment.ps1")
. (Join-Path $Global:ModulePath "VMTemplateManagement.ps1")
. (Join-Path $Global:ModulePath "MultiHostDeployment.ps1")
. (Join-Path $Global:ModulePath "NetworkStorageConfig.ps1")
. (Join-Path $Global:ModulePath "PostDeploymentValidation.ps1")
. (Join-Path $Global:ModulePath "ConfigurationManagement.ps1")
. (Join-Path $Global:ModulePath "LogViewer.ps1")
. (Join-Path $Global:ModulePath "HTMLReportGenerator.ps1")
. (Join-Path $Global:ModulePath "HyperVInventory_New.ps1")

# Initialize script environment
function Initialize-Environment {
    [CmdletBinding()]
    param()
    
    Write-Host "Initializing Hyper-V Deployment Script Environment..." -ForegroundColor Green
      # Create required directories
    $directories = @($LogPath, $ConfigPath, $TemplatePath, $ReportPath, $ModulePath)
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $dir" -ForegroundColor Yellow
        }
    }
    
    # Initialize logging
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Global:LogFile = Join-Path $LogPath "HyperV-Deployment_$timestamp.log"
    
    Write-Log -Message "=== Hyper-V Deployment Script Started ===" -Level "INFO"
    Write-Log -Message "Script Version: $Global:ScriptVersion" -Level "INFO"
    Write-Log -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Level "INFO"
    Write-Log -Message "Operating System: $((Get-WmiObject Win32_OperatingSystem).Caption)" -Level "INFO"
}

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    if ($Global:LogFile) {
        Add-Content -Path $Global:LogFile -Value $logEntry
    }
    
    # Write to console with color coding
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

# Display script header
function Show-Header {
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "               ENTERPRISE HYPER-V DEPLOYMENT TOOL v$Global:ScriptVersion" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "Current Host: $($env:COMPUTERNAME)" -ForegroundColor Yellow
    Write-Host "Current User: $($env:USERDOMAIN)\$($env:USERNAME)" -ForegroundColor Yellow
    Write-Host "Script Path:  $Global:ScriptPath" -ForegroundColor Yellow
    Write-Host "Log File:     $Global:LogFile" -ForegroundColor Yellow
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Main menu display
function Show-MainMenu {
    Write-Host "MAIN MENU OPTIONS:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. Prerequisites and System Validation" -ForegroundColor White
    Write-Host "  2. Single Host Hyper-V Deployment" -ForegroundColor White
    Write-Host "  3. Multi-Host Hyper-V Deployment" -ForegroundColor White
    Write-Host "  4. Configure VM Templates and Standards" -ForegroundColor White
    Write-Host "  5. Network and Storage Configuration" -ForegroundColor White
    Write-Host "  6. Post-Deployment Validation and Testing" -ForegroundColor White
    Write-Host "  7. Export/Import Configuration Templates" -ForegroundColor White
    Write-Host "  8. Hyper-V Inventory and Reporting (RVTools-like)" -ForegroundColor White
    Write-Host "  9. View Deployment Logs and Status" -ForegroundColor White
    Write-Host " 10. Generate HTML Report" -ForegroundColor White
    Write-Host "  0. Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
}

# Get user menu selection
function Get-MenuSelection {
    do {
        $selection = Read-Host "Please select an option (0-10)"
        if ($selection -match '^([0-9]|10)$') {
            return [int]$selection
        }
        Write-Host "Invalid selection. Please enter a number between 0 and 10." -ForegroundColor Red
    } while ($true)
}

# Placeholder functions for menu options
function Invoke-SystemValidation {
    Write-Log -Message "Starting system prerequisites and validation..." -Level "INFO"
    
    try {
        $validationResult = Test-HyperVPrerequisites
        
        if ($validationResult.Status) {
            Write-Log -Message "System validation completed successfully - Ready for deployment" -Level "SUCCESS"
        } else {
            Write-Log -Message "System validation found issues that need to be resolved" -Level "WARNING"
        }
        
        # Save validation results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $validationFile = Join-Path $Global:ConfigPath "ValidationResults_$timestamp.xml"
        $validationResult | Export-Clixml -Path $validationFile
        Write-Log -Message "Validation results saved to: $validationFile" -Level "INFO"
        
    }
    catch {
        Write-Log -Message "Error during system validation: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during validation. Check the log file for details." -ForegroundColor Red
    }
    
    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
    Read-Host
}

function Invoke-SingleHostDeployment {
    Write-Log -Message "Starting single host Hyper-V deployment..." -Level "INFO"
    Start-SingleHostDeployment
}

function Invoke-MultiHostDeployment {
    Write-Log -Message "Starting multi-host Hyper-V deployment..." -Level "INFO"
    Start-MultiHostDeployment
}

function Invoke-TemplateConfiguration {
    Write-Log -Message "Starting VM template configuration..." -Level "INFO"
    Start-TemplateConfiguration
}

function Invoke-NetworkStorageConfig {
    Write-Log -Message "Starting network and storage configuration..." -Level "INFO"
    Start-NetworkStorageConfig
}

function Invoke-PostDeploymentValidation {
    Write-Log -Message "Starting post-deployment validation..." -Level "INFO"
    Start-PostDeploymentValidation
}

function Invoke-ConfigurationManagement {
    Write-Log -Message "Starting configuration template management..." -Level "INFO"
    Start-ConfigurationManagement
}

function Show-DeploymentLogs {
    Write-Log -Message "Displaying deployment logs and status..." -Level "INFO"
    Start-LogViewer
}

function Start-HTMLReportGeneration {
    Write-Log -Message "Starting HTML deployment report generation..." -Level "INFO"
    New-HTMLReport
}

function Invoke-HyperVInventory {
    Write-Log -Message "Starting Hyper-V inventory and reporting..." -Level "INFO"
    Start-HyperVInventory
}

# Main script execution
function Start-HyperVDeployment {
    try {
        Initialize-Environment
        
        do {
            Show-Header
            Show-MainMenu
            
            $selection = Get-MenuSelection
            
            switch ($selection) {
                1 { Invoke-SystemValidation }
                2 { Invoke-SingleHostDeployment }
                3 { Invoke-MultiHostDeployment }
                4 { Invoke-TemplateConfiguration }
                5 { Invoke-NetworkStorageConfig }                6 { Invoke-PostDeploymentValidation }
                7 { Invoke-ConfigurationManagement }
                8 { Invoke-HyperVInventory }
                9 { Show-DeploymentLogs }
                10 { Start-HTMLReportGeneration }
                0 { 
                    Write-Log -Message "User selected exit. Terminating script." -Level "INFO"
                    Write-Host "Thank you for using the Hyper-V Deployment Tool!" -ForegroundColor Green
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
        Write-Log -Message "Critical error in main execution: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "A critical error occurred. Check the log file for details." -ForegroundColor Red
        Read-Host "Press Enter to exit"
    }
    finally {
        Write-Log -Message "=== Hyper-V Deployment Script Ended ===" -Level "INFO"
    }
}

# Script entry point
if ($MyInvocation.InvocationName -ne '.') {
    Start-HyperVDeployment
}
