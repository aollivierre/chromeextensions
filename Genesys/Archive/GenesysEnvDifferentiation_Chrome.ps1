#
# Genesys Environment Differentiation POC Implementation - Chrome Version
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments using Chrome
# with visual differentiation to help users clearly identify which environment they're using.
#

# Part 1: Create Desktop Shortcuts with Custom Icons

# 1. Create working directory
Write-Host "Creating working directory..."
New-Item -Path "C:\Temp\GenesysPOC" -ItemType Directory -Force

# 2. Create sample icons if they don't exist
$prodIconPath = "C:\Temp\GenesysPOC\genesys_prod.ico"
$drIconPath = "C:\Temp\GenesysPOC\genesys_dr.ico"

# Generate simple colored icon files if they don't exist
if (-not (Test-Path $prodIconPath)) {
    Write-Host "Creating sample PROD icon..."
    # For demo purposes, we'll use a placeholder file
    Copy-Item -Path "$env:SystemRoot\System32\shell32.dll" -Destination $prodIconPath -ErrorAction SilentlyContinue
}

if (-not (Test-Path $drIconPath)) {
    Write-Host "Creating sample DR icon..."
    # For demo purposes, we'll use a placeholder file
    Copy-Item -Path "$env:SystemRoot\System32\imageres.dll" -Destination $drIconPath -ErrorAction SilentlyContinue
}

# 2. Handle custom icons with proper validation
Write-Host "Setting up custom icons for shortcuts..." -ForegroundColor Yellow

# Define icon paths - both custom and fallback
$customProdIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_icon.ico"
$customDrIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_DR_256.ico"
$fallbackProdIconPath = "$env:SystemRoot\System32\shell32.dll,4"  # Blue globe icon
$fallbackDrIconPath = "$env:SystemRoot\System32\imageres.dll,8"   # Red shield icon

# Function to validate if an ICO file is valid
function Test-IconFile {
    param (
        [string]$IconPath
    )
    
    # Check if file exists and has .ico extension
    if (-not (Test-Path $IconPath)) {
        Write-Host "Icon file not found: $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    if (-not $IconPath.ToLower().EndsWith(".ico")) {
        Write-Host "File is not an ICO file: $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    # Check if file size is too small (likely invalid)
    $fileInfo = Get-Item $IconPath
    if ($fileInfo.Length -lt 100) {
        Write-Host "Icon file appears to be invalid (too small): $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

# Determine which icons to use with validation
if (Test-IconFile $customProdIconPath) {
    $prodIconPath = $customProdIconPath
    Write-Host "Using custom PROD icon: $prodIconPath" -ForegroundColor Green
} else {
    $prodIconPath = $fallbackProdIconPath
    Write-Host "Using fallback PROD icon: $prodIconPath" -ForegroundColor Yellow
}

if (Test-IconFile $customDrIconPath) {
    $drIconPath = $customDrIconPath
    Write-Host "Using custom DR icon: $drIconPath" -ForegroundColor Green
} else {
    $drIconPath = $fallbackDrIconPath
    Write-Host "Using fallback DR icon: $drIconPath" -ForegroundColor Yellow
}

# Don't create local copies - use the original icons directly
Write-Host "Using PROD icon directly from source: $prodIconPath" -ForegroundColor Green
Write-Host "Using DR icon directly from source: $drIconPath" -ForegroundColor Green

# Find the primary Chrome executable
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    # Try to find Chrome automatically if the primary path doesn't exist
    $possiblePaths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $chromePath = $path
            break
        }
    }
    
    # If still not found, warn user
    if (-not (Test-Path $chromePath)) {
        Write-Host "WARNING: Google Chrome executable not found at expected locations." -ForegroundColor Yellow
        Write-Host "Using 'chrome.exe' and relying on PATH environment. This may not work correctly." -ForegroundColor Yellow
        $chromePath = "chrome.exe"
    }
}

Write-Host "Using Google Chrome from $chromePath" -ForegroundColor Green

# 3. Create the PROD shortcut
Write-Host "Creating PROD shortcut on desktop..."
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys PROD (Chrome).lnk")
$Shortcut.TargetPath = $chromePath
$Shortcut.Arguments = "--app=https://winnipeg.ca"
$Shortcut.IconLocation = "$prodIconPath,0"
$Shortcut.Save()

# 4. Create the DR shortcut with visual differentiation parameter
Write-Host "Creating DR shortcut on desktop..."
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk")
$Shortcut.TargetPath = $chromePath
# Chrome doesn't have --edge-theme option, but we can use --force-dark-mode instead
$Shortcut.Arguments = "--app=https://www.toronto.ca --force-dark-mode"
$Shortcut.IconLocation = "$drIconPath,0"
$Shortcut.Save()

Write-Host "Basic shortcuts created successfully!" -ForegroundColor Green

# Launch the shortcuts to demonstrate
Write-Host "Launching shortcuts for demonstration..." -ForegroundColor Yellow
$prodShortcutPath = "$env:USERPROFILE\Desktop\Genesys PROD (Chrome).lnk"
$drShortcutPath = "$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk"

# Launch the PROD shortcut
Start-Process -FilePath $prodShortcutPath
Write-Host "PROD shortcut launched." -ForegroundColor Green

# Short delay before launching DR
Start-Sleep -Seconds 3

# Launch the DR shortcut
Start-Process -FilePath $drShortcutPath
Write-Host "DR shortcut launched." -ForegroundColor Green

# Part 2: Browser Visual Differentiation Options

# Let user select which approach to implement
Write-Host "`nSelect a visual differentiation approach to implement:`n" -ForegroundColor Cyan
Write-Host "1. Chrome Profiles (creates a separate browser profile for DR)"
Write-Host "2. Chrome Theme Color Approach (uses window frame coloring)"
Write-Host "3. Browser Extension Approach (creates a simple extension for visual cues)"
Write-Host "4. Chrome Isolated App Approach (creates an isolated browser instance)"
Write-Host "5. Simulate SCCM Extension Deployment (applies extension to all profiles)"
Write-Host "0. Skip additional differentiation (keep basic shortcuts only)`n"

$selection = Read-Host "Enter your selection (0-5)"

# Option 1: Chrome Profiles
if ($selection -eq "1" -or $selection -eq "5") {
    Write-Host "`nImplementing Chrome Profiles approach..." -ForegroundColor Yellow
    
    # Create a custom Chrome profile name for DR
    $drProfileName = "Genesys_DR"
    
    # Update the DR shortcut to use the profile
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk")
    $Shortcut.TargetPath = $chromePath
    $Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=`"$drProfileName`" --force-dark-mode"
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching updated DR shortcut with profile differentiation..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk"
    
    Write-Host "Chrome Profile approach implemented. DR environment will use a separate browser profile." -ForegroundColor Green
    Write-Host "Note: The first time you use this shortcut, Chrome will create a new profile." -ForegroundColor Cyan
}

# Option 2: Chrome Theme Color Approach
if ($selection -eq "2" -or $selection -eq "5") {
    Write-Host "`nImplementing Chrome Theme Color approach..." -ForegroundColor Yellow
    
    # Update the DR shortcut to use theme color
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk")
    $Shortcut.TargetPath = $chromePath
    # Use Chrome's window frame color option with a red frame
    $Shortcut.Arguments = "--app=https://www.toronto.ca --force-dark-mode --window-color=#FF0000"
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching updated DR shortcut with theme color differentiation..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR (Chrome).lnk"
    
    Write-Host "Chrome Theme Color approach implemented. DR environment will use a red window frame." -ForegroundColor Green
}

# Option 3: Browser Extension Approach
if ($selection -eq "3" -or $selection -eq "5") {
    Write-Host "`nImplementing Browser Extension approach..." -ForegroundColor Yellow
    
    # Create extension directory
    New-Item -Path "C:\Temp\GenesysPOC\ChromeExtension" -ItemType Directory -Force
    
    # Create manifest.json for the extension
    $manifestJson = @{
        "manifest_version" = 3
        "name" = "Genesys Environment Indicator"
        "version" = "1.0"
        "description" = "Adds visual cues to Genesys environments"
        "content_scripts" = @(
            @{
                "matches" = @("https://www.toronto.ca/*")
                "css" = @("dr-style.css")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Create CSS file for visual styling
    $cssContent = @"
/* Add a prominent red border to the top of the page */
body::before {
  content: "DR ENVIRONMENT";
  display: block;
  background-color: #ff0000;
  color: white;
  text-align: center;
  padding: 5px;
  font-weight: bold;
}
"@
    
    # Write extension files
    Set-Content -Path "C:\Temp\GenesysPOC\ChromeExtension\manifest.json" -Value $manifestJson
    Set-Content -Path "C:\Temp\GenesysPOC\ChromeExtension\dr-style.css" -Value $cssContent
    
    # Notify user to install extension and then relaunch
    Write-Host "After installing the extension, re-launch the DR shortcut to see the visual indicators." -ForegroundColor Cyan
    
    Write-Host "Browser Extension approach implemented." -ForegroundColor Green
    Write-Host "To install the extension:" -ForegroundColor Cyan
    Write-Host "1. Open Chrome and navigate to chrome://extensions"
    Write-Host "2. Enable Developer Mode (toggle in top-right)"
    Write-Host "3. Click 'Load unpacked' and select C:\Temp\GenesysPOC\ChromeExtension"

    # Add enterprise deployment option
    Write-Host "`nWould you like to prepare the extension for enterprise deployment? (Y/N)" -ForegroundColor Cyan
    $deployExtension = Read-Host

    if ($deployExtension -eq "Y" -or $deployExtension -eq "y") {
        Write-Host "`nPreparing extension for enterprise deployment..." -ForegroundColor Yellow
        
        # Create folder for enterprise deployment
        $deploymentPath = "C:\Temp\GenesysPOC\Deployment"
        New-Item -Path $deploymentPath -ItemType Directory -Force
        
        # Create extension package
        Compress-Archive -Path "C:\Temp\GenesysPOC\ChromeExtension\*" -DestinationPath "$deploymentPath\GenesysDRIndicator.zip" -Force
        Copy-Item "$deploymentPath\GenesysDRIndicator.zip" "$deploymentPath\GenesysDRIndicator.crx" -Force
        
        # Generate a consistent extension ID (for demo purposes)
        $extensionId = "genesysdrextension" # In production: actual Chrome Web Store ID
        
        # Create registry script for machine-wide installation
        $registryScript = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist]
"1"="$extensionId;file://C:\\Program Files\\GenesysPOC\\GenesysDRIndicator.crx"
"@
        
        Set-Content -Path "$deploymentPath\InstallExtension.reg" -Value $registryScript
        
        # Create SCCM deployment script
        $deploymentScript = @"
# Genesys DR Extension SCCM Deployment Script
# Run with administrator privileges

# Create target directory
New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force

# Copy extension file
Copy-Item "$deploymentPath\GenesysDRIndicator.crx" "C:\Program Files\GenesysPOC\GenesysDRIndicator.crx" -Force

# Import registry settings
reg import "$deploymentPath\InstallExtension.reg"

Write-Host "Genesys DR Extension deployed successfully" -ForegroundColor Green
"@
        
        Set-Content -Path "$deploymentPath\Deploy-Extension.ps1" -Value $deploymentScript
        
        # Create deployment instructions
        $deploymentInstructions = @"
# Genesys DR Extension Deployment

## For SCCM Deployment:
1. Create a package with these files:
   - GenesysDRIndicator.crx
   - InstallExtension.reg
   - Deploy-Extension.ps1
   - Enterprise-Setup.ps1

2. Deploy the package to target machines using SCCM with the following settings:
   - Program: PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Extension.ps1"
   - Run with administrative rights: Yes
   - Run mode: Hidden
   
3. Target the appropriate collection of machines

## For GPO Deployment:
1. Use Group Policy to create the registry keys in InstallExtension.reg
2. Deploy the CRX file to a network share or each machine
"@
        
        Set-Content -Path "$deploymentPath\DeploymentInstructions.md" -Value $deploymentInstructions

        # Copy the Enterprise-Setup.ps1 file to the deployment folder
        $enterpriseSetupPath = "$deploymentPath\Enterprise-Setup.ps1"
        Copy-Item "GenesysPOC\Deployment\Enterprise-Setup.ps1" $enterpriseSetupPath -Force

        # If the file doesn't exist, create a simple reference script
        if (-not (Test-Path "$enterpriseSetupPath")) {
            Write-Host "Creating Enterprise-Setup.ps1 script..." -ForegroundColor Yellow
            
            # Create the enterprise setup script with Chrome-specific settings
            $enterpriseSetupScript = @"
#
# Genesys Environment Enterprise Setup Script for Google Chrome
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments
# with visual differentiation and installs the DR indicator extension.
#

# Create working directory
New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force

# Create desktop shortcuts
$`WshShell = New-Object -ComObject WScript.Shell

# PROD shortcut
$`Shortcut = $`WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys PROD (Chrome).lnk")
$`Shortcut.TargetPath = "$chromePath"
$`Shortcut.Arguments = "--app=https://winnipeg.ca"
$`Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_prod_chrome.ico,0"
$`Shortcut.Save()

# DR shortcut
$`Shortcut = $`WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys DR (Chrome).lnk")
$`Shortcut.TargetPath = "$chromePath"
$`Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=```"Genesys_DR```" --force-dark-mode"
$`Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_dr_chrome.ico,0"
$`Shortcut.Save()

# Copy icon files
Copy-Item "$customProdIconPath" "C:\Program Files\GenesysPOC\genesys_prod_chrome.ico" -Force
Copy-Item "$customDrIconPath" "C:\Program Files\GenesysPOC\genesys_dr_chrome.ico" -Force

# Import registry for extension force-install
reg import "C:\Program Files\GenesysPOC\InstallExtension.reg"

Write-Host "Genesys Environment Differentiation setup complete for Google Chrome" -ForegroundColor Green
"@
            
            Set-Content -Path "$enterpriseSetupPath" -Value $enterpriseSetupScript -Force
        }

        Write-Host "Enterprise deployment files created at: $deploymentPath" -ForegroundColor Green
        Write-Host "Follow the instructions in DeploymentInstructions.md for SCCM deployment" -ForegroundColor Cyan
        Write-Host "The Enterprise-Setup.ps1 script included in the deployment package will set up shortcuts" -ForegroundColor Cyan
    }

    # Create an additional shortcut combining profile and extension approach if option 5 was selected
    if ($selection -eq "5") {
        Write-Host "`nCreating complete differentiation shortcut (profile + extension)..." -ForegroundColor Yellow
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR Complete (Chrome).lnk")
        $Shortcut.TargetPath = $chromePath
        $Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=`"Genesys_DR`" --force-dark-mode"
        $Shortcut.IconLocation = "$drIconPath,0"
        $Shortcut.Save()
        
        Write-Host "Complete differentiation shortcut created. After installing the extension," -ForegroundColor Green
        Write-Host "use this shortcut for the most distinct visual experience." -ForegroundColor Green
    }
}

if ($selection -eq "0") {
    Write-Host "`nSkipping additional differentiation. Basic shortcuts are already created." -ForegroundColor Yellow
}

# Option 4: Chrome's Isolated App Approach 
# Demonstrating another Chrome-specific approach available in newer versions
if ($selection -eq "4" -or $selection -eq "5") {
    Write-Host "`nImplementing Chrome Isolated App approach..." -ForegroundColor Yellow
    
    # Create a desktop shortcut that opens Chrome in isolation mode for DR
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR Isolated (Chrome).lnk")
    $Shortcut.TargetPath = $chromePath
    # Newer Chrome versions support "site isolation" with --isolate-origins
    $Shortcut.Arguments = "--app=https://www.toronto.ca --isolate-origins=https://www.toronto.ca --force-dark-mode"
    $Shortcut.IconLocation = "$drIconPath,0"
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching Isolated App shortcut for DR environment..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR Isolated (Chrome).lnk"
    
    Write-Host "Chrome Isolated App approach implemented for DR environment." -ForegroundColor Green
}

# Option 5: Simulate SCCM Chrome Extension Deployment
if ($selection -eq "5") {
    Write-Host "`nSimulating SCCM Enterprise Deployment of Chrome Extension..." -ForegroundColor Yellow
    
    # Create extension directory
    $extensionFolder = "C:\Program Files\GenesysPOC\ChromeExtension"
    New-Item -Path $extensionFolder -ItemType Directory -Force
    
    # Create manifest.json for the extension
    $manifestJson = @{
        "manifest_version" = 3
        "name" = "Genesys DR Environment Indicator"
        "version" = "1.0"
        "description" = "Adds prominent visual cues to DR environments in Google Chrome"
        "content_scripts" = @(
            @{
                "matches" = @("https://www.toronto.ca/*")  # Would be DR environment URL in production
                "css" = @("dr-style.css")
                "all_frames" = $true
                "run_at" = "document_start"
            }
        )
        "permissions" = @("activeTab")
    } | ConvertTo-Json -Depth 10
    
    # Create CSS file with stronger visual styling - more prominent banner
    $cssContent = @"
/* Add a prominent red banner to the top of the page */
body::before {
  content: "DR ENVIRONMENT - SCCM DEPLOYED EXTENSION";
  display: block !important;
  background-color: #ff0000 !important;
  color: white !important;
  text-align: center !important;
  padding: 10px !important;
  font-weight: bold !important;
  font-size: 16px !important;
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  width: 100% !important;
  z-index: 2147483647 !important;
}

/* Add space at the top of the body to prevent content from being hidden */
body {
  margin-top: 40px !important;
  padding-top: 40px !important;
}
"@
    
    # Write extension files
    Set-Content -Path "$extensionFolder\manifest.json" -Value $manifestJson
    Set-Content -Path "$extensionFolder\dr-style.css" -Value $cssContent
    
    # Create the extension package (crx file)
    $crxPath = "C:\Program Files\GenesysPOC\GenesysDR_Chrome.crx"
    Write-Host "Creating extension package at $crxPath..." -ForegroundColor Yellow
    
    # For simulation, we can just copy the files (in a real scenario, you'd properly package as crx)
    Compress-Archive -Path "$extensionFolder\*" -DestinationPath "$crxPath.zip" -Force
    Copy-Item "$crxPath.zip" -Destination $crxPath -Force
    
    # Create a random but consistent extension ID (for simulation purposes)
    $extensionId = "genesysdrenv_" + [Guid]::NewGuid().ToString().Replace("-", "").Substring(0, 16)
    
    # Create registry key to force-install the extension (this is what SCCM would do)
    # Chrome uses a different registry path than Edge
    $registryPath = "HKCU:\Software\Policies\Google\Chrome\ExtensionInstallForcelist"
    
    # Create the registry path if it doesn't exist
    if (-not (Test-Path $registryPath)) {
        Write-Host "Creating registry key structure for Chrome extension policy..." -ForegroundColor Yellow
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Add extension to force-install list (1 is just an index, can be any number not already used)
    $extensionValue = "1:$extensionId;file:///$crxPath"
    Write-Host "Setting registry value to force-install extension..." -ForegroundColor Yellow
    New-ItemProperty -Path $registryPath -Name "1" -Value $extensionValue -PropertyType String -Force | Out-Null
    
    # Create enterprise setup script directly instead of trying to copy a non-existent file
    $enterpriseSetupPath = "$deploymentPath\Enterprise-Setup.ps1"
    
    # Create the enterprise setup script
    $enterpriseSetupScript = @"
#
# Genesys Environment Enterprise Setup Script for Google Chrome
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments
# with visual differentiation and installs the DR indicator extension.
#

# Create working directory
New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force

# Create desktop shortcuts
$`WshShell = New-Object -ComObject WScript.Shell

# PROD shortcut
$`Shortcut = $`WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys PROD (Chrome).lnk")
$`Shortcut.TargetPath = "$chromePath"
$`Shortcut.Arguments = "--app=https://winnipeg.ca"
$`Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_prod_chrome.ico,0"
$`Shortcut.Save()

# DR shortcut
$`Shortcut = $`WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys DR (Chrome).lnk")
$`Shortcut.TargetPath = "$chromePath"
$`Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=```"Genesys_DR```" --force-dark-mode"
$`Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_dr_chrome.ico,0"
$`Shortcut.Save()

# Copy icon files
Copy-Item "$customProdIconPath" "C:\Program Files\GenesysPOC\genesys_prod_chrome.ico" -Force
Copy-Item "$customDrIconPath" "C:\Program Files\GenesysPOC\genesys_dr_chrome.ico" -Force

# Import registry for extension force-install
reg import "C:\Program Files\GenesysPOC\InstallExtension.reg"

Write-Host "Genesys Environment Differentiation setup complete for Google Chrome" -ForegroundColor Green
"@
    
    Set-Content -Path $enterpriseSetupPath -Value $enterpriseSetupScript -Force
    
    # Notify user that they need to close and reopen Chrome
    Write-Host "`nSCCM Enterprise Deployment simulation complete!" -ForegroundColor Green
    Write-Host "The Chrome extension has been 'force-installed' via registry policy." -ForegroundColor Green
    Write-Host "This simulates what happens when SCCM deploys the extension." -ForegroundColor Green
    Write-Host "`nIMPORTANT: You MUST COMPLETELY exit Chrome and restart it for the extension to activate." -ForegroundColor Yellow 
    Write-Host "All Chrome windows and background processes must be closed for the policy to take effect." -ForegroundColor Yellow
    Write-Host "`nTo verify Chrome is completely closed, check Task Manager and end any chrome.exe processes." -ForegroundColor Cyan
    Write-Host "After restarting Chrome, navigate to the DR site (toronto.ca) to see the extension in action." -ForegroundColor Cyan
    
    # Ask if user wants to kill all Chrome processes
    Write-Host "`nWould you like to automatically close all Chrome processes now? (Y/N)" -ForegroundColor Yellow
    $killChrome = Read-Host
    
    if ($killChrome -eq "Y" -or $killChrome -eq "y") {
        Write-Host "Closing all Chrome processes..." -ForegroundColor Yellow
        Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "All Chrome processes closed. Wait a moment, then restart Chrome manually." -ForegroundColor Green
    } else {
        # Launch the DR shortcut to show the result
        Write-Host "`nLaunching the DR shortcut to demonstrate the extension..." -ForegroundColor Yellow
        Write-Host "Note: You may need to manually close Chrome completely first for the extension to work." -ForegroundColor Yellow
        Start-Process -FilePath $drShortcutPath
    }
}

# Testing Instructions
Write-Host "`n----- TESTING INSTRUCTIONS -----" -ForegroundColor Magenta
Write-Host "1. Test the PROD shortcut:" -ForegroundColor White
Write-Host "   - Double-click the 'Genesys PROD (Chrome)' shortcut on your desktop"
Write-Host "   - Verify it opens Chrome in app mode with the correct URL"
Write-Host "`n2. Test the DR shortcut:" -ForegroundColor White
Write-Host "   - Double-click the 'Genesys DR (Chrome)' shortcut on your desktop"
Write-Host "   - Verify it opens with visual differences (icon, theme, etc.)"
Write-Host "`n3. Compare both environments side by side to ensure clear visual differentiation" -ForegroundColor White

Write-Host "`nPOC implementation complete!" -ForegroundColor Green 