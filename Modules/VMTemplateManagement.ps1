# VM Template Management Module for Hyper-V
# Contains functions for creating and managing standardized VM templates

function Start-TemplateConfiguration {
    <#
    .SYNOPSIS
        Manages VM templates and standards for Hyper-V deployment
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting VM template configuration workflow..." -Level "INFO"
    
    # Check if Hyper-V is available
    if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
        Write-Host "`nWARNING: Hyper-V PowerShell module not available." -ForegroundColor Yellow
        Write-Host "Install Hyper-V role first (Option 2)." -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return
    }
    
    try {
        Show-TemplateMenu
        
    }
    catch {
        Write-Log -Message "Error in VM template configuration: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "An error occurred during template configuration. Check the log file for details." -ForegroundColor Red
    }
}

function Show-TemplateMenu {
    <#
    .SYNOPSIS
        Displays the VM template management menu options
    #>
    do {
        Clear-Host
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host "                    VM TEMPLATE MANAGEMENT" -ForegroundColor Cyan
        Write-Host "===============================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "TEMPLATE OPTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Create Domain Controller Template" -ForegroundColor White
        Write-Host "  2. Create Application Server Template" -ForegroundColor White
        Write-Host "  3. Create Database Server Template" -ForegroundColor White
        Write-Host "  4. Create Web Server Template" -ForegroundColor White
        Write-Host "  5. Create VDI Desktop Template" -ForegroundColor White
        Write-Host "  6. Create Custom Template" -ForegroundColor White
        Write-Host "  7. View Existing Templates" -ForegroundColor Cyan
        Write-Host "  8. Export/Import Templates" -ForegroundColor Yellow
        Write-Host "  9. Deploy VM from Template" -ForegroundColor Green
        Write-Host "  0. Return to Main Menu" -ForegroundColor Red
        Write-Host ""
        Write-Host "===============================================================================" -ForegroundColor Cyan
        
        $selection = Read-Host "Please select an option (0-9)"
        
        switch ($selection) {
            1 { New-DomainControllerTemplate }
            2 { New-ApplicationServerTemplate }
            3 { New-DatabaseServerTemplate }
            4 { New-WebServerTemplate }
            5 { New-VDITemplate }
            6 { New-CustomTemplate }
            7 { Show-ExistingTemplates }
            8 { Manage-TemplateImportExport }
            9 { Deploy-VMFromTemplate }
            0 { 
                Write-Log -Message "Returning to main menu from template configuration" -Level "INFO"
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

function New-DomainControllerTemplate {
    <#
    .SYNOPSIS
        Creates a standardized Domain Controller VM template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating Domain Controller Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting Domain Controller template creation" -Level "INFO"
    
    try {
        # Get template configuration
        $templateConfig = Get-TemplateConfiguration -TemplateType "DomainController"
        
        # Display recommended specifications
        Write-Host "  Recommended Domain Controller Specifications:" -ForegroundColor Cyan
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host ""
        
        # Allow customization
        $customize = Read-Host "Customize specifications? (y/N)"
        if ($customize -eq 'y' -or $customize -eq 'Y') {
            $templateConfig = Get-CustomTemplateSpecs -BaseConfig $templateConfig -TemplateType "Domain Controller"
        }
        
        # Create the template
        $templateName = Read-Host "Enter template name [DC-Template]"
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            $templateName = "DC-Template"
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "DomainController"
        
        if ($template) {
            Write-Host "  ✓ Domain Controller template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "Domain Controller template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating Domain Controller template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating Domain Controller template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function New-ApplicationServerTemplate {
    <#
    .SYNOPSIS
        Creates a standardized Application Server VM template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating Application Server Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting Application Server template creation" -Level "INFO"
    
    try {
        # Get template configuration
        $templateConfig = Get-TemplateConfiguration -TemplateType "ApplicationServer"
        
        # Display recommended specifications
        Write-Host "  Recommended Application Server Specifications:" -ForegroundColor Cyan
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host ""
        
        # Allow customization
        $customize = Read-Host "Customize specifications? (y/N)"
        if ($customize -eq 'y' -or $customize -eq 'Y') {
            $templateConfig = Get-CustomTemplateSpecs -BaseConfig $templateConfig -TemplateType "Application Server"
        }
        
        # Create the template
        $templateName = Read-Host "Enter template name [AppServer-Template]"
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            $templateName = "AppServer-Template"
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "ApplicationServer"
        
        if ($template) {
            Write-Host "  ✓ Application Server template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "Application Server template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating Application Server template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating Application Server template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function New-DatabaseServerTemplate {
    <#
    .SYNOPSIS
        Creates a standardized Database Server VM template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating Database Server Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting Database Server template creation" -Level "INFO"
    
    try {
        # Get template configuration
        $templateConfig = Get-TemplateConfiguration -TemplateType "DatabaseServer"
        
        # Display recommended specifications
        Write-Host "  Recommended Database Server Specifications:" -ForegroundColor Cyan
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    OS Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Data Storage: $($templateConfig.DataStorage) GB" -ForegroundColor Gray
        Write-Host "    Log Storage: $($templateConfig.LogStorage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host ""
        
        # Allow customization
        $customize = Read-Host "Customize specifications? (y/N)"
        if ($customize -eq 'y' -or $customize -eq 'Y') {
            $templateConfig = Get-CustomTemplateSpecs -BaseConfig $templateConfig -TemplateType "Database Server"
        }
        
        # Create the template
        $templateName = Read-Host "Enter template name [DBServer-Template]"
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            $templateName = "DBServer-Template"
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "DatabaseServer"
        
        if ($template) {
            Write-Host "  ✓ Database Server template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "Database Server template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating Database Server template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating Database Server template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function New-WebServerTemplate {
    <#
    .SYNOPSIS
        Creates a standardized Web Server VM template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating Web Server Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting Web Server template creation" -Level "INFO"
    
    try {
        # Get template configuration
        $templateConfig = Get-TemplateConfiguration -TemplateType "WebServer"
        
        # Display recommended specifications
        Write-Host "  Recommended Web Server Specifications:" -ForegroundColor Cyan
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host ""
        
        # Allow customization
        $customize = Read-Host "Customize specifications? (y/N)"
        if ($customize -eq 'y' -or $customize -eq 'Y') {
            $templateConfig = Get-CustomTemplateSpecs -BaseConfig $templateConfig -TemplateType "Web Server"
        }
        
        # Create the template
        $templateName = Read-Host "Enter template name [WebServer-Template]"
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            $templateName = "WebServer-Template"
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "WebServer"
        
        if ($template) {
            Write-Host "  ✓ Web Server template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "Web Server template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating Web Server template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating Web Server template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function New-VDITemplate {
    <#
    .SYNOPSIS
        Creates a standardized VDI Desktop VM template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating VDI Desktop Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting VDI Desktop template creation" -Level "INFO"
    
    try {
        # Get template configuration
        $templateConfig = Get-TemplateConfiguration -TemplateType "VDI"
        
        # Display recommended specifications
        Write-Host "  Recommended VDI Desktop Specifications:" -ForegroundColor Cyan
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host "    Enhanced Session Mode: Enabled" -ForegroundColor Gray
        Write-Host ""
        
        # Allow customization
        $customize = Read-Host "Customize specifications? (y/N)"
        if ($customize -eq 'y' -or $customize -eq 'Y') {
            $templateConfig = Get-CustomTemplateSpecs -BaseConfig $templateConfig -TemplateType "VDI Desktop"
        }
        
        # Create the template
        $templateName = Read-Host "Enter template name [VDI-Template]"
        if ([string]::IsNullOrWhiteSpace($templateName)) {
            $templateName = "VDI-Template"
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "VDI"
        
        if ($template) {
            Write-Host "  ✓ VDI Desktop template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "VDI Desktop template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating VDI Desktop template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating VDI Desktop template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function New-CustomTemplate {
    <#
    .SYNOPSIS
        Creates a custom VM template with user-defined specifications
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nCreating Custom Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting custom template creation" -Level "INFO"
    
    try {
        Write-Host "  Enter specifications for your custom template:" -ForegroundColor Cyan
        
        # Get custom specifications
        $templateName = Read-Host "Template name"
        while ([string]::IsNullOrWhiteSpace($templateName)) {
            Write-Host "  Template name is required." -ForegroundColor Red
            $templateName = Read-Host "Template name"
        }
        
        $cpuCores = Read-Host "CPU cores [2]"
        if ([string]::IsNullOrWhiteSpace($cpuCores)) { $cpuCores = 2 }
        
        $memory = Read-Host "Memory in MB [4096]"
        if ([string]::IsNullOrWhiteSpace($memory)) { $memory = 4096 }
        
        $storage = Read-Host "Storage in GB [80]"
        if ([string]::IsNullOrWhiteSpace($storage)) { $storage = 80 }
        
        $networkAdapters = Read-Host "Number of network adapters [1]"
        if ([string]::IsNullOrWhiteSpace($networkAdapters)) { $networkAdapters = 1 }
        
        $dynamicMemory = Read-Host "Enable Dynamic Memory? (Y/n)"
        $enableDynamicMemory = ($dynamicMemory -ne 'n' -and $dynamicMemory -ne 'N')
        
        $secureboot = Read-Host "Enable Secure Boot? (Y/n)"
        $enableSecureBoot = ($secureboot -ne 'n' -and $secureboot -ne 'N')
        
        # Create custom configuration
        $templateConfig = @{
            CPU = [int]$cpuCores
            Memory = [int]$memory
            Storage = [int]$storage
            NetworkAdapters = [int]$networkAdapters
            DynamicMemory = $enableDynamicMemory
            SecureBoot = $enableSecureBoot
            Generation = 2
            TemplateType = "Custom"
        }
        
        Write-Host "`n  Custom Template Summary:" -ForegroundColor Cyan
        Write-Host "    Name: $templateName" -ForegroundColor Gray
        Write-Host "    CPU Cores: $($templateConfig.CPU)" -ForegroundColor Gray
        Write-Host "    Memory: $($templateConfig.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($templateConfig.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network Adapters: $($templateConfig.NetworkAdapters)" -ForegroundColor Gray
        Write-Host "    Dynamic Memory: $($templateConfig.DynamicMemory)" -ForegroundColor Gray
        Write-Host "    Secure Boot: $($templateConfig.SecureBoot)" -ForegroundColor Gray
        Write-Host ""
        
        $confirm = Read-Host "Create this template? (Y/n)"
        if ($confirm -eq 'n' -or $confirm -eq 'N') {
            Write-Host "  Template creation cancelled." -ForegroundColor Yellow
            return
        }
        
        $template = New-VMTemplate -TemplateConfig $templateConfig -TemplateName $templateName -TemplateType "Custom"
        
        if ($template) {
            Write-Host "  ✓ Custom template '$templateName' created successfully" -ForegroundColor Green
            Write-Log -Message "Custom template '$templateName' created" -Level "SUCCESS"
            
            # Save template to file system
            Save-VMTemplate -Template $template -TemplateName $templateName
        }
        
    }
    catch {
        Write-Host "  ✗ Error creating custom template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error creating custom template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Get-TemplateConfiguration {
    <#
    .SYNOPSIS
        Returns standard template configurations for different VM types
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateType
    )
    
    switch ($TemplateType) {
        "DomainController" {
            return @{
                CPU = 2
                Memory = 4096
                Storage = 80
                NetworkAdapters = 1
                DynamicMemory = $true
                SecureBoot = $true
                Generation = 2
                TemplateType = "DomainController"
            }
        }
        "ApplicationServer" {
            return @{
                CPU = 4
                Memory = 8192
                Storage = 120
                NetworkAdapters = 2
                DynamicMemory = $true
                SecureBoot = $true
                Generation = 2
                TemplateType = "ApplicationServer"
            }
        }
        "DatabaseServer" {
            return @{
                CPU = 8
                Memory = 16384
                Storage = 120
                DataStorage = 200
                LogStorage = 100
                NetworkAdapters = 2
                DynamicMemory = $false
                SecureBoot = $true
                Generation = 2
                TemplateType = "DatabaseServer"
            }
        }
        "WebServer" {
            return @{
                CPU = 2
                Memory = 4096
                Storage = 100
                NetworkAdapters = 2
                DynamicMemory = $true
                SecureBoot = $true
                Generation = 2
                TemplateType = "WebServer"
            }
        }
        "VDI" {
            return @{
                CPU = 2
                Memory = 4096
                Storage = 60
                NetworkAdapters = 1
                DynamicMemory = $true
                SecureBoot = $true
                Generation = 2
                EnhancedSessionMode = $true
                TemplateType = "VDI"
            }
        }
    }
}

function Get-CustomTemplateSpecs {
    <#
    .SYNOPSIS
        Allows user to customize template specifications
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BaseConfig,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateType
    )
    
    Write-Host "  Customize $TemplateType specifications:" -ForegroundColor Cyan
    
    $cpu = Read-Host "CPU cores [$($BaseConfig.CPU)]"
    if (-not [string]::IsNullOrWhiteSpace($cpu)) { $BaseConfig.CPU = [int]$cpu }
    
    $memory = Read-Host "Memory in MB [$($BaseConfig.Memory)]"
    if (-not [string]::IsNullOrWhiteSpace($memory)) { $BaseConfig.Memory = [int]$memory }
    
    $storage = Read-Host "OS Storage in GB [$($BaseConfig.Storage)]"
    if (-not [string]::IsNullOrWhiteSpace($storage)) { $BaseConfig.Storage = [int]$storage }
    
    if ($BaseConfig.ContainsKey("DataStorage")) {
        $dataStorage = Read-Host "Data Storage in GB [$($BaseConfig.DataStorage)]"
        if (-not [string]::IsNullOrWhiteSpace($dataStorage)) { $BaseConfig.DataStorage = [int]$dataStorage }
        
        $logStorage = Read-Host "Log Storage in GB [$($BaseConfig.LogStorage)]"
        if (-not [string]::IsNullOrWhiteSpace($logStorage)) { $BaseConfig.LogStorage = [int]$logStorage }
    }
    
    $networkAdapters = Read-Host "Network adapters [$($BaseConfig.NetworkAdapters)]"
    if (-not [string]::IsNullOrWhiteSpace($networkAdapters)) { $BaseConfig.NetworkAdapters = [int]$networkAdapters }
    
    return $BaseConfig
}

function New-VMTemplate {
    <#
    .SYNOPSIS
        Creates a VM template configuration object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TemplateConfig,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateType
    )
    
    # Create template object
    $template = @{
        Name = $TemplateName
        Type = $TemplateType
        Created = Get-Date
        Configuration = $TemplateConfig
        Version = $Global:ScriptVersion
    }
    
    Write-Log -Message "VM template '$TemplateName' of type '$TemplateType' created" -Level "SUCCESS"
    
    return $template
}

function Save-VMTemplate {
    <#
    .SYNOPSIS
        Saves a VM template to the file system
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Template,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateName
    )
    
    try {
        $templateFile = Join-Path $Global:TemplatePath "VMTemplate_$($TemplateName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $Template | Export-Clixml -Path $templateFile
        
        Write-Host "  ✓ Template saved to: $templateFile" -ForegroundColor Green
        Write-Log -Message "VM template saved to: $templateFile" -Level "INFO"
        
    }
    catch {
        Write-Host "  ✗ Error saving template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error saving template: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Show-ExistingTemplates {
    <#
    .SYNOPSIS
        Displays all existing VM templates
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nExisting VM Templates:" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    
    try {
        $templateFiles = Get-ChildItem -Path $Global:TemplatePath -Filter "VMTemplate_*.xml" -ErrorAction SilentlyContinue
        
        if ($templateFiles.Count -eq 0) {
            Write-Host "  No VM templates found." -ForegroundColor Yellow
            Write-Host "  Create templates using options 1-6." -ForegroundColor Yellow
            return
        }
        
        foreach ($file in $templateFiles) {
            try {
                $template = Import-Clixml -Path $file.FullName
                
                Write-Host "✓ Template: $($template.Name)" -ForegroundColor Green
                Write-Host "  Type: $($template.Type)" -ForegroundColor Gray
                Write-Host "  Created: $($template.Created)" -ForegroundColor Gray
                Write-Host "  CPU: $($template.Configuration.CPU) cores" -ForegroundColor Gray
                Write-Host "  Memory: $($template.Configuration.Memory) MB" -ForegroundColor Gray
                Write-Host "  Storage: $($template.Configuration.Storage) GB" -ForegroundColor Gray
                if ($template.Configuration.DataStorage) {
                    Write-Host "  Data Storage: $($template.Configuration.DataStorage) GB" -ForegroundColor Gray
                    Write-Host "  Log Storage: $($template.Configuration.LogStorage) GB" -ForegroundColor Gray
                }
                Write-Host "  Network Adapters: $($template.Configuration.NetworkAdapters)" -ForegroundColor Gray
                Write-Host "  File: $($file.Name)" -ForegroundColor Gray
                Write-Host ""
            }
            catch {
                Write-Host "✗ Error reading template file: $($file.Name)" -ForegroundColor Red
                Write-Log -Message "Error reading template file '$($file.Name)': $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
    }
    catch {
        Write-Host "✗ Error accessing template directory: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error accessing template directory: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Host "===============================================================================" -ForegroundColor Cyan
}

function Manage-TemplateImportExport {
    <#
    .SYNOPSIS
        Manages template import and export operations
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nTemplate Import/Export Management:" -ForegroundColor Cyan
    Write-Host "  1. Export Templates to Archive" -ForegroundColor White
    Write-Host "  2. Import Templates from Archive" -ForegroundColor White
    Write-Host "  3. Export Single Template" -ForegroundColor White
    Write-Host "  4. Return to Template Menu" -ForegroundColor Red
    
    $choice = Read-Host "Select option (1-4)"
    
    switch ($choice) {
        1 { Export-AllTemplates }
        2 { Import-TemplateArchive }
        3 { Export-SingleTemplate }
        4 { return }
        default { 
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
}

function Export-AllTemplates {
    <#
    .SYNOPSIS
        Exports all templates to a compressed archive
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nExporting All Templates..." -ForegroundColor Yellow
    
    try {
        $templateFiles = Get-ChildItem -Path $Global:TemplatePath -Filter "VMTemplate_*.xml"
        
        if ($templateFiles.Count -eq 0) {
            Write-Host "  No templates to export." -ForegroundColor Yellow
            return
        }
        
        $exportPath = Join-Path $Global:ConfigPath "VMTemplates_Export_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        
        # Create zip file
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($Global:TemplatePath, $exportPath)
        
        Write-Host "  ✓ Templates exported to: $exportPath" -ForegroundColor Green
        Write-Log -Message "All templates exported to: $exportPath" -Level "SUCCESS"
        
    }
    catch {
        Write-Host "  ✗ Error exporting templates: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error exporting templates: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Deploy-VMFromTemplate {
    <#
    .SYNOPSIS
        Deploys a new VM from an existing template
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`nDeploy VM from Template..." -ForegroundColor Yellow
    Write-Log -Message "Starting VM deployment from template" -Level "INFO"
    
    try {
        # Get available templates
        $templateFiles = Get-ChildItem -Path $Global:TemplatePath -Filter "VMTemplate_*.xml" -ErrorAction SilentlyContinue
        
        if ($templateFiles.Count -eq 0) {
            Write-Host "  No templates available for deployment." -ForegroundColor Yellow
            Write-Host "  Create templates first using options 1-6." -ForegroundColor Yellow
            return
        }
        
        Write-Host "  Available Templates:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $templateFiles.Count; $i++) {
            try {
                $template = Import-Clixml -Path $templateFiles[$i].FullName
                Write-Host "    $($i + 1). $($template.Name) ($($template.Type))" -ForegroundColor Gray
            }
            catch {
                Write-Host "    $($i + 1). $($templateFiles[$i].BaseName) (Error reading template)" -ForegroundColor Red
            }
        }
        
        # Select template
        do {
            $selection = Read-Host "Select template (1-$($templateFiles.Count))"
            $templateIndex = [int]$selection - 1
        } while ($templateIndex -lt 0 -or $templateIndex -ge $templateFiles.Count)
        
        $selectedTemplate = Import-Clixml -Path $templateFiles[$templateIndex].FullName
        
        Write-Host "`n  Selected Template: $($selectedTemplate.Name)" -ForegroundColor Cyan
        
        # Get VM deployment details
        $vmName = Read-Host "Enter VM name"
        while ([string]::IsNullOrWhiteSpace($vmName)) {
            Write-Host "  VM name is required." -ForegroundColor Red
            $vmName = Read-Host "Enter VM name"
        }
        
        # Check if VM already exists
        if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
            Write-Host "  ✗ VM '$vmName' already exists" -ForegroundColor Red
            return
        }
        
        # Get virtual switch
        $switches = Get-VMSwitch
        if ($switches.Count -eq 0) {
            Write-Host "  ✗ No virtual switches available. Create virtual switches first." -ForegroundColor Red
            return
        }
        
        Write-Host "  Available Virtual Switches:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $switches.Count; $i++) {
            Write-Host "    $($i + 1). $($switches[$i].Name) ($($switches[$i].SwitchType))" -ForegroundColor Gray
        }
        
        do {
            $switchSelection = Read-Host "Select virtual switch (1-$($switches.Count))"
            $switchIndex = [int]$switchSelection - 1
        } while ($switchIndex -lt 0 -or $switchIndex -ge $switches.Count)
        
        $selectedSwitch = $switches[$switchIndex]
        
        # Deploy VM
        Write-Host "`n  Deploying VM '$vmName'..." -ForegroundColor Yellow
        
        $vmParams = @{
            Name = $vmName
            Generation = $selectedTemplate.Configuration.Generation
            MemoryStartupBytes = $selectedTemplate.Configuration.Memory * 1MB
            SwitchName = $selectedSwitch.Name
        }
        
        # Create VM
        $vm = New-VM @vmParams
        
        # Configure CPU
        Set-VM -VM $vm -ProcessorCount $selectedTemplate.Configuration.CPU
        
        # Configure Dynamic Memory
        if ($selectedTemplate.Configuration.DynamicMemory) {
            $minMemory = [math]::Max(512MB, $selectedTemplate.Configuration.Memory * 1MB * 0.5)
            $maxMemory = $selectedTemplate.Configuration.Memory * 1MB * 2
            Set-VM -VM $vm -DynamicMemory -MemoryMinimumBytes $minMemory -MemoryMaximumBytes $maxMemory
        }
        
        # Configure Secure Boot
        if ($selectedTemplate.Configuration.SecureBoot -and $selectedTemplate.Configuration.Generation -eq 2) {
            Set-VMFirmware -VM $vm -EnableSecureBoot On
        }
        
        # Create and attach VHD
        $vhdPath = Join-Path (Get-VMHost).VirtualHardDiskPath "$vmName.vhdx"
        $vhd = New-VHD -Path $vhdPath -SizeBytes ($selectedTemplate.Configuration.Storage * 1GB) -Dynamic
        Add-VMHardDiskDrive -VM $vm -Path $vhd.Path
        
        # Add additional storage for database servers
        if ($selectedTemplate.Configuration.ContainsKey("DataStorage")) {
            $dataVhdPath = Join-Path (Get-VMHost).VirtualHardDiskPath "$vmName-Data.vhdx"
            $dataVhd = New-VHD -Path $dataVhdPath -SizeBytes ($selectedTemplate.Configuration.DataStorage * 1GB) -Dynamic
            Add-VMHardDiskDrive -VM $vm -Path $dataVhd.Path
            
            $logVhdPath = Join-Path (Get-VMHost).VirtualHardDiskPath "$vmName-Log.vhdx"
            $logVhd = New-VHD -Path $logVhdPath -SizeBytes ($selectedTemplate.Configuration.LogStorage * 1GB) -Dynamic
            Add-VMHardDiskDrive -VM $vm -Path $logVhd.Path
        }
        
        # Add additional network adapters
        for ($i = 1; $i -lt $selectedTemplate.Configuration.NetworkAdapters; $i++) {
            Add-VMNetworkAdapter -VM $vm -SwitchName $selectedSwitch.Name
        }
        
        # Enable Enhanced Session Mode for VDI
        if ($selectedTemplate.Configuration.ContainsKey("EnhancedSessionMode")) {
            Enable-VMIntegrationService -VM $vm -Name "Guest Service Interface"
        }
        
        Write-Host "  ✓ VM '$vmName' deployed successfully from template '$($selectedTemplate.Name)'" -ForegroundColor Green
        Write-Host "  VM Configuration:" -ForegroundColor Cyan
        Write-Host "    CPU: $($selectedTemplate.Configuration.CPU) cores" -ForegroundColor Gray
        Write-Host "    Memory: $($selectedTemplate.Configuration.Memory) MB" -ForegroundColor Gray
        Write-Host "    Storage: $($selectedTemplate.Configuration.Storage) GB" -ForegroundColor Gray
        Write-Host "    Network: $($selectedSwitch.Name)" -ForegroundColor Gray
        Write-Host "    VHD Path: $vhdPath" -ForegroundColor Gray
        
        Write-Log -Message "VM '$vmName' deployed from template '$($selectedTemplate.Name)'" -Level "SUCCESS"
        
        # Save deployment record
        $deploymentRecord = @{
            VMName = $vmName
            TemplateName = $selectedTemplate.Name
            TemplateType = $selectedTemplate.Type
            DeploymentDate = Get-Date
            Configuration = $selectedTemplate.Configuration
        }
        
        $recordFile = Join-Path $Global:ConfigPath "VMDeployment_$($vmName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
        $deploymentRecord | Export-Clixml -Path $recordFile
        
        $startVM = Read-Host "Start the VM now? (Y/n)"
        if ($startVM -ne 'n' -and $startVM -ne 'N') {
            Start-VM -VM $vm
            Write-Host "  ✓ VM '$vmName' started" -ForegroundColor Green
        }
        
    }
    catch {
        Write-Host "  ✗ Error deploying VM from template: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Error deploying VM from template: $($_.Exception.Message)" -Level "ERROR"
    }
}
