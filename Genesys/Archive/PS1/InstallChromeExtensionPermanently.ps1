#
# InstallChromeExtensionPermanently.ps1
# Permanently installs the Genesys DR Environment extension using Chrome Enterprise Policy
#

# Ensure script runs as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator to modify registry policies" -ForegroundColor Red
    Write-Host "Please restart the script with administrative privileges" -ForegroundColor Yellow
    exit 1
}

# Configuration - Use the actual extension ID we observed working with manual loading
$extensionId = "ogdgiomifhjoenfhbmheapmjcpicdlg" # The ID Chrome generated when loaded manually
$extensionName = "Genesys DR Environment Indicator"
$extensionVersion = "1.0"

# Paths - Use the path that worked with manual loading
$extensionPath = "C:\temp\GenesysPOC\ChromeExtension"
$chromePolicyKey = "HKLM:\SOFTWARE\Policies\Google\Chrome"

Write-Host "Genesys DR Environment - Chrome Extension Permanent Installation" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Print diagnostic information
Write-Host "DIAGNOSTIC INFORMATION:" -ForegroundColor Magenta
Write-Host "  Using Extension ID: $extensionId" -ForegroundColor Magenta
Write-Host "  Using Extension Path: $extensionPath" -ForegroundColor Magenta
Write-Host "  Checking if path exists: $(Test-Path $extensionPath)" -ForegroundColor Magenta
Write-Host "  Chrome Policy Registry Key: $chromePolicyKey" -ForegroundColor Magenta
Write-Host ""

# Step 1: Create registry keys for Chrome policies
Write-Host "STEP 1: Creating Chrome policy registry keys..." -ForegroundColor Green

# Create main Chrome policy key
if (-not (Test-Path $chromePolicyKey)) {
    Write-Host "  Creating Chrome policy registry key..." -ForegroundColor Yellow
    New-Item -Path $chromePolicyKey -Force | Out-Null
    Write-Host "  Created Chrome policy key" -ForegroundColor Green
}

# Now set up both approaches for extension installation

# APPROACH 1: ExtensionSettings
# Create ExtensionSettings key
$extensionSettingsKey = "$chromePolicyKey\ExtensionSettings"
if (-not (Test-Path $extensionSettingsKey)) {
    Write-Host "  Creating ExtensionSettings key..." -ForegroundColor Yellow
    New-Item -Path $extensionSettingsKey -Force | Out-Null
    Write-Host "  Created ExtensionSettings key" -ForegroundColor Green
}

# Create key for our specific extension
$extensionKey = "$extensionSettingsKey\$extensionId"
if (-not (Test-Path $extensionKey)) {
    Write-Host "  Creating key for extension $extensionId..." -ForegroundColor Yellow
    New-Item -Path $extensionKey -Force | Out-Null
    Write-Host "  Created extension key" -ForegroundColor Green
}

# APPROACH 2: ExtensionInstallForcelist
# Create ExtensionInstallForcelist registry key
$forcelistPath = "$chromePolicyKey\ExtensionInstallForcelist"
if (-not (Test-Path $forcelistPath)) {
    Write-Host "  Creating ExtensionInstallForcelist registry key..." -ForegroundColor Yellow
    New-Item -Path $forcelistPath -Force | Out-Null
    Write-Host "  Created ExtensionInstallForcelist key" -ForegroundColor Green
}

# Step 2: Set policies to force install the extension (using multiple approaches)
Write-Host "`nSTEP 2: Setting policies to force-install the extension..." -ForegroundColor Green

# APPROACH 1: Using ExtensionSettings
# Set installation_mode to force_installed
New-ItemProperty -Path $extensionKey -Name "installation_mode" -Value "force_installed" -PropertyType String -Force | Out-Null
Write-Host "  Set installation_mode to force_installed" -ForegroundColor Green

# APPROACH 2: Using ExtensionInstallForcelist with a URL
# Format the URL for local extension
$extUrl = "file:///$($extensionPath.Replace('\', '/'))"
$policyValue = "$extensionId;$extUrl"
New-ItemProperty -Path $forcelistPath -Name "1" -Value $policyValue -PropertyType String -Force | Out-Null
Write-Host "  Added to ExtensionInstallForcelist with value: $policyValue" -ForegroundColor Green

# Common settings for both approaches
# Allow the extension to be loaded from local path
$allowedLocalExtensionsKey = "$chromePolicyKey\ExtensionInstallSources"
if (-not (Test-Path $allowedLocalExtensionsKey)) {
    New-Item -Path $allowedLocalExtensionsKey -Force | Out-Null
}
New-ItemProperty -Path $allowedLocalExtensionsKey -Name "1" -Value "file:///*" -PropertyType String -Force | Out-Null
Write-Host "  Allowed loading extensions from local paths" -ForegroundColor Green

# Create external extension paths key
$externalExtensionPathsKey = "$chromePolicyKey\ExternalExtensionPaths"
if (-not (Test-Path $externalExtensionPathsKey)) {
    New-Item -Path $externalExtensionPathsKey -Force | Out-Null
}

# Set the extension path - use double backslashes for registry
$escapedPath = $extensionPath.Replace('\', '\\')
New-ItemProperty -Path $externalExtensionPathsKey -Name $extensionId -Value $escapedPath -PropertyType String -Force | Out-Null
Write-Host "  Set extension path to $escapedPath" -ForegroundColor Green

# Disable extension blocklist
New-ItemProperty -Path $chromePolicyKey -Name "ExtensionInstallBlocklist" -Value "1" -PropertyType String -Force | Out-Null
Write-Host "  Disabled extension installation blocklist" -ForegroundColor Green

# Additional required policies
# ExtensionAllowedTypes - allow all types
New-ItemProperty -Path $chromePolicyKey -Name "ExtensionAllowedTypes" -Value "*" -PropertyType String -Force | Out-Null
Write-Host "  Set ExtensionAllowedTypes to allow all types" -ForegroundColor Green

# Developer mode
New-ItemProperty -Path $chromePolicyKey -Name "DeveloperToolsAvailability" -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "  Enabled developer tools" -ForegroundColor Green

# AllowFileSelectionDialogs
New-ItemProperty -Path $chromePolicyKey -Name "AllowFileSelectionDialogs" -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "  Enabled file selection dialogs" -ForegroundColor Green

# Step 3: Restart Chrome to apply the policy
Write-Host "`nSTEP 3: Closing Chrome to apply policy changes..." -ForegroundColor Green

# Close any running Chrome instances
Get-Process -Name chrome -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Closing Chrome process (PID: $($_.Id))..." -ForegroundColor Yellow
    $_.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 1
    if (-not $_.HasExited) {
        $_ | Stop-Process -Force
    }
}

# Display registry values for verification
Write-Host "`nVERIFYING REGISTRY ENTRIES:" -ForegroundColor Cyan
try {
    Write-Host "  ExtensionSettings value:" -ForegroundColor Yellow
    Get-ItemProperty -Path $extensionKey -ErrorAction SilentlyContinue | Format-List
    
    Write-Host "  ExtensionInstallForcelist value:" -ForegroundColor Yellow
    Get-ItemProperty -Path $forcelistPath -ErrorAction SilentlyContinue | Format-List
    
    Write-Host "  ExternalExtensionPaths value:" -ForegroundColor Yellow
    Get-ItemProperty -Path $externalExtensionPathsKey -ErrorAction SilentlyContinue | Format-List
} catch {
    Write-Host "  Error reading registry values: $_" -ForegroundColor Red
}

Write-Host "`nINSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "To verify the installation:" -ForegroundColor White
Write-Host "1. Start Chrome" -ForegroundColor White
Write-Host "2. Go to chrome://extensions/ - the extension should be listed" -ForegroundColor White
Write-Host "3. Go to chrome://policy/ - verify the extension policies are applied" -ForegroundColor White
Write-Host "`nIf the extension is not visible:" -ForegroundColor Yellow
Write-Host "1. Completely exit Chrome (check Task Manager to make sure all processes are gone)" -ForegroundColor Yellow
Write-Host "2. Restart Chrome" -ForegroundColor Yellow
Write-Host "3. Try restarting your computer - policies sometimes require a full restart" -ForegroundColor Yellow
Write-Host "4. Check chrome://policy to see if policies are properly applied" -ForegroundColor Yellow
Write-Host "5. Check chrome://extensions-internals/ for detailed extension loading logs" -ForegroundColor Yellow

Write-Host "`nALTERNATIVE APPROACH:" -ForegroundColor Magenta
Write-Host "If policy-based installation continues to fail, consider these alternatives:" -ForegroundColor White
Write-Host "1. Create a Windows Startup shortcut that loads the extension in Developer Mode" -ForegroundColor White
Write-Host "2. Package the extension as a .crx file and deploy it via Group Policy" -ForegroundColor White
Write-Host "3. Create a startup script that uses --load-extension=path Chrome command line parameter" -ForegroundColor White 