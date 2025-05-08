#
# Genesys Environment Differentiation POC Implementation
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments
# with visual differentiation to help users clearly identify which environment they're using.
#

# Part 1: Create Desktop Shortcuts with Custom Icons

# 1. Create working directory
Write-Host "Creating working directory..."
New-Item -Path "C:\Temp\GenesysPOC" -ItemType Directory -Force

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

# Create local copies of custom icons in program directory if using custom icons
$localIconDir = "C:\Temp\GenesysPOC"
if (-not (Test-Path $localIconDir)) {
    New-Item -Path $localIconDir -ItemType Directory -Force | Out-Null
}

# Don't create local copies - use the original icons directly
$prodIconPath = $customProdIconPath
$drIconPath = $customDrIconPath

Write-Host "Using PROD icon directly from source: $prodIconPath" -ForegroundColor Green
Write-Host "Using DR icon directly from source: $drIconPath" -ForegroundColor Green

# Find the primary Edge executable
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    # Try to find Edge automatically if the primary path doesn't exist
    $possiblePaths = @(
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $edgePath = $path
            break
        }
    }
    
    # If still not found, warn user
    if (-not (Test-Path $edgePath)) {
        Write-Host "WARNING: Microsoft Edge executable not found at expected locations." -ForegroundColor Yellow
        Write-Host "Using 'msedge.exe' and relying on PATH environment. This may not work correctly." -ForegroundColor Yellow
        $edgePath = "msedge.exe"
    }
}

Write-Host "Using Microsoft Edge from $edgePath" -ForegroundColor Green

# Delete existing shortcuts if they exist to prevent caching issues
$prodShortcutPath = "$env:USERPROFILE\Desktop\Genesys PROD (Edge).lnk"
$drShortcutPath = "$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk"

if (Test-Path $prodShortcutPath) {
    Write-Host "Removing existing PROD shortcut..." -ForegroundColor Yellow
    Remove-Item -Path $prodShortcutPath -Force
}

if (Test-Path $drShortcutPath) {
    Write-Host "Removing existing DR shortcut..." -ForegroundColor Yellow
    Remove-Item -Path $drShortcutPath -Force
}

# 3. Create the PROD shortcut
Write-Host "Creating PROD shortcut on desktop..."
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($prodShortcutPath)
$Shortcut.TargetPath = $edgePath
$Shortcut.Arguments = "--app=https://winnipeg.ca"
$Shortcut.IconLocation = "$prodIconPath,0"
$Shortcut.Save()

# 4. Create the DR shortcut with visual differentiation parameter
Write-Host "Creating DR shortcut on desktop..."
$Shortcut = $WshShell.CreateShortcut($drShortcutPath)
$Shortcut.TargetPath = $edgePath
$Shortcut.Arguments = "--app=https://www.toronto.ca --edge-theme=dark"
$Shortcut.IconLocation = "$drIconPath,0"
$Shortcut.Save()

Write-Host "Basic shortcuts created successfully!" -ForegroundColor Green

# Launch the shortcuts to demonstrate
Write-Host "Launching shortcuts for demonstration..." -ForegroundColor Yellow
$prodShortcutPath = "$env:USERPROFILE\Desktop\Genesys PROD (Edge).lnk"
$drShortcutPath = "$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk"

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
Write-Host "1. Edge Profiles (creates a separate browser profile for DR)"
Write-Host "2. Edge Workspace Approach (uses Edge workspace feature)"
Write-Host "3. Browser Extension Approach (creates a simple extension for visual cues)"
Write-Host "4. Chrome Isolated App Approach (creates an isolated browser instance)"
Write-Host "5. Simulate SCCM Extension Deployment (applies extension to all profiles)"
Write-Host "0. Skip additional differentiation (keep basic shortcuts only)`n"

$selection = Read-Host "Enter your selection (0-5)"

# Option 1: Edge Profiles
if ($selection -eq "1" -or $selection -eq "4") {
    Write-Host "`nImplementing Edge Profiles approach..." -ForegroundColor Yellow
    
    # Create a custom Edge profile for DR
    $drProfilePath = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\DR Profile"
    New-Item -Path $drProfilePath -ItemType Directory -Force
    
    # Update the DR shortcut to use the profile
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk")
    $Shortcut.TargetPath = $edgePath
    $Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=`"DR Profile`""
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching updated DR shortcut with profile differentiation..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk"
    
    # Configure the DR profile with different theme (This is a placeholder - actual preferences would need to be set after first profile use)
    $prefsFile = "$drProfilePath\Preferences"
    $prefs = @{
        "browser" = @{
            "custom_chrome_frame" = $true
        }
        "extensions" = @{
            "theme" = @{
                "use_system" = $false
            }
        }
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $prefsFile -Value $prefs -Force
    Write-Host "Edge Profile approach implemented. DR environment will use a separate browser profile." -ForegroundColor Green
}

# Option 2: Edge Workspace Approach
if ($selection -eq "2" -or $selection -eq "4") {
    Write-Host "`nImplementing Edge Workspace approach..." -ForegroundColor Yellow
    
    # Create workspace configuration
    $workspaceConfig = @{
        "name" = "Genesys DR Environment"
        "theme" = "red"
        "showWorkspaceSwitcher" = $true
    } | ConvertTo-Json
    
    Set-Content -Path "C:\Temp\GenesysPOC\dr-workspace.json" -Value $workspaceConfig
    
    # Update the DR shortcut to use workspace
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk")
    $Shortcut.TargetPath = $edgePath
    $Shortcut.Arguments = "--app=https://www.toronto.ca --workspace-file=`"C:\Temp\GenesysPOC\dr-workspace.json`""
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching updated DR shortcut with workspace differentiation..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk"
    
    Write-Host "Edge Workspace approach implemented. DR environment will use a workspace with red theme." -ForegroundColor Green
}

# Option 3: Browser Extension Approach
if ($selection -eq "3" -or $selection -eq "4") {
    Write-Host "`nImplementing Browser Extension approach..." -ForegroundColor Yellow
    
    # Create extension directory
    New-Item -Path "C:\Temp\GenesysPOC\EdgeExtension" -ItemType Directory -Force
    
    # Create manifest.json for the extension
    $manifestJson = @{
        "manifest_version" = 3
        "name" = "Genesys Environment Indicator for Edge"
        "version" = "1.0"
        "description" = "Adds visual cues to Genesys environments in Microsoft Edge"
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
    Set-Content -Path "C:\Temp\GenesysPOC\EdgeExtension\manifest.json" -Value $manifestJson
    Set-Content -Path "C:\Temp\GenesysPOC\EdgeExtension\dr-style.css" -Value $cssContent
    
    # Notify user to install extension and then relaunch
    Write-Host "After installing the extension, re-launch the DR shortcut to see the visual indicators." -ForegroundColor Cyan
    
    Write-Host "Edge Browser Extension approach implemented." -ForegroundColor Green
    Write-Host "To install the extension:" -ForegroundColor Cyan
    Write-Host "1. Open Edge and navigate to edge://extensions"
    Write-Host "2. Enable Developer Mode (toggle in bottom-left)"
    Write-Host "3. Click 'Load unpacked' and select C:\Temp\GenesysPOC\EdgeExtension"
    
    # Add enterprise deployment option
    Write-Host "`nWould you like to prepare the extension for enterprise deployment? (Y/N)" -ForegroundColor Cyan
    $deployExtension = Read-Host

    if ($deployExtension -eq "Y" -or $deployExtension -eq "y") {
        Write-Host "`nPreparing extension for enterprise deployment..." -ForegroundColor Yellow
        
        # Create folder for enterprise deployment
        $deploymentPath = "C:\Temp\GenesysPOC\EdgeDeployment"
        New-Item -Path $deploymentPath -ItemType Directory -Force
        
        # Create extension package
        Compress-Archive -Path "C:\Temp\GenesysPOC\EdgeExtension\*" -DestinationPath "$deploymentPath\GenesysDRIndicator_Edge.zip" -Force
        Copy-Item "$deploymentPath\GenesysDRIndicator_Edge.zip" "$deploymentPath\GenesysDRIndicator_Edge.crx" -Force
        
        # Generate a consistent extension ID (for demo purposes)
        $extensionId = "genesysdrextension_edge" # In production: actual Edge Add-ons Store ID
        
        # Create registry script for machine-wide installation
        $registryScript = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist]
"1"="$extensionId;file://C:\\Program Files\\GenesysPOC\\GenesysDRIndicator_Edge.crx"
"@
        
        Set-Content -Path "$deploymentPath\InstallExtension.reg" -Value $registryScript
        
        # Create SCCM deployment script
        $deploymentScript = @"
# Genesys DR Edge Extension SCCM Deployment Script
# Run with administrator privileges

# Create target directory
New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force

# Copy extension file
Copy-Item "$deploymentPath\GenesysDRIndicator_Edge.crx" "C:\Program Files\GenesysPOC\GenesysDRIndicator_Edge.crx" -Force

# Import registry settings
reg import "$deploymentPath\InstallExtension.reg"

Write-Host "Genesys DR Edge Extension deployed successfully" -ForegroundColor Green
"@
        
        Set-Content -Path "$deploymentPath\Deploy-Extension.ps1" -Value $deploymentScript
        
        # Create deployment instructions
        $deploymentInstructions = @"
# Genesys DR Edge Extension Deployment

## Recommended Approach: SCCM Application Deployment

SCCM Applications are recommended over Packages for this extension because they provide:
- Detailed detection methods to prevent redundant installations
- Requirements to ensure Edge is installed first
- Better reporting and compliance tracking
- Improved user experience through Software Center
- Easier updates with supersedence when new versions are released

### Steps for SCCM Application Deployment:

1. **Prepare source files**:
   - Create a network share folder (e.g., `\\server\share\GenesysDREdgeExtension`)
   - Copy all files (GenesysDRIndicator_Edge.crx, InstallExtension.reg, Deploy-Extension.ps1) to this folder

2. **Create the Application**:
   - In SCCM Console: **Software Library** > **Application Management** > **Applications**
   - Right-click **Applications** and select **Create Application**
   - Select **Manually specify the application information** > **Next**
   - Enter details:
     - **Name**: "Genesys DR Environment Extension for Edge"
     - **Publisher**: "YourCompany"
     - **Version**: "1.0"
   - **Source folder**: `\\server\share\GenesysDREdgeExtension`
   - Click **Next** > **Next**

3. **Create Deployment Type**:
   - Click **Add** to create a deployment type
   - Select **Script Installer** > **Next**
   - Enter name: "Edge Extension Installer"
   - **Content location**: `\\server\share\GenesysDREdgeExtension`
   - **Installation program**: `PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Extension.ps1"`
   - **Uninstall program**: Leave blank or add an uninstall script if needed
   - Click **Next**

4. **Add Detection Method**:
   - Click **Add Clause**
   - **Setting Type**: **Registry**
   - **Hive**: **HKEY_LOCAL_MACHINE**
   - **Key**: `SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`
   - **Value**: `1`
   - **Data Type**: **String**
   - **Value**: (contains) `genesysdrextension_edge`
   - Click **OK** > **Next**

5. **Configure User Experience**:
   - **Installation behavior**: **Install for system**
   - **Logon requirement**: **Whether or not a user is logged on**
   - **Installation program visibility**: **Hidden**
   - Click **Next**

6. **Add Requirements** (recommended):
   - Click **Add**
   - Select **File System** condition
   - **Path**: `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` (or other verified Edge path)
   - **File or folder exists**: Checked
   - Click **OK** > **Next** > **Next** > **Close** > **Next** > **Close**

7. **Deploy the Application**:
   - Right-click the application and select **Deploy**
   - Select your target collection
   - Configure as **Required** deployment
   - Complete the wizard

## Alternative: SCCM Package Deployment

If you must use a Package (for legacy systems or specific requirements):

1. Create a package with these files:
   - GenesysDRIndicator_Edge.crx
   - InstallExtension.reg
   - Deploy-Extension.ps1

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
        
        # Copy the Enterprise-Setup.ps1 file for Edge to the deployment folder
        $enterpriseSetupPath = "$deploymentPath\Enterprise-Setup-Edge.ps1"
        
        # Create Edge enterprise setup script
        $enterpriseSetupScript = @"
#
# Genesys Environment Enterprise Setup Script for Microsoft Edge
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments
# with visual differentiation and installs the DR indicator extension for Edge.
#

# Create working directory
New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force

# Create desktop shortcuts
$WshShell = New-Object -ComObject WScript.Shell

# PROD shortcut
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys PROD (Edge).lnk")
$Shortcut.TargetPath = "$edgePath"
$Shortcut.Arguments = "--app=https://winnipeg.ca"
$Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_prod_edge.ico,0"
$Shortcut.Save()

# DR shortcut
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Genesys DR (Edge).lnk")
$Shortcut.TargetPath = "$edgePath"
$Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=```"DR Profile```" --edge-theme=dark"
$Shortcut.IconLocation = "C:\Program Files\GenesysPOC\genesys_dr_edge.ico,0"
$Shortcut.Save()

# Copy icon files
Copy-Item "$prodIconPath" "C:\Program Files\GenesysPOC\genesys_prod_edge.ico" -Force
Copy-Item "$drIconPath" "C:\Program Files\GenesysPOC\genesys_dr_edge.ico" -Force

# Import registry for extension force-install
reg import "C:\Program Files\GenesysPOC\InstallExtension.reg"

Write-Host "Genesys Environment Differentiation setup complete for Microsoft Edge" -ForegroundColor Green
"@
        
        Set-Content -Path "$enterpriseSetupPath" -Value $enterpriseSetupScript
        
        Write-Host "Enterprise deployment files created at: $deploymentPath" -ForegroundColor Green
        Write-Host "Follow the instructions in DeploymentInstructions.md for SCCM deployment" -ForegroundColor Cyan
        Write-Host "The Enterprise-Setup-Edge.ps1 script can be used for complete deployment including shortcuts" -ForegroundColor Cyan
    }
}

# Option 4: Chrome Isolated App Approach
if ($selection -eq "4") {
    Write-Host "`nImplementing Chrome Isolated App approach..." -ForegroundColor Yellow
    
    # Create a new Edge profile for DR
    $drProfilePath = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\DR Profile"
    New-Item -Path $drProfilePath -ItemType Directory -Force
    
    # Update the DR shortcut to use the new profile
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk")
    $Shortcut.TargetPath = $edgePath
    $Shortcut.Arguments = "--app=https://www.toronto.ca --profile-directory=`"DR Profile`""
    $Shortcut.Save()
    
    # Re-launch the DR shortcut to show the changes
    Write-Host "Launching updated DR shortcut with isolated app differentiation..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:USERPROFILE\Desktop\Genesys DR (Edge).lnk"
    
    Write-Host "Chrome Isolated App approach implemented. DR environment will use a separate isolated app." -ForegroundColor Green
}

# Option 5: Simulate SCCM Edge Extension Deployment
if ($selection -eq "5") {
    Write-Host "`nSimulating SCCM Enterprise Deployment of Edge Extension..." -ForegroundColor Yellow
    
    # Create extension directory
    $extensionFolder = "C:\Program Files\GenesysPOC\EdgeExtension"
    New-Item -Path $extensionFolder -ItemType Directory -Force
    
    # Create manifest.json for the extension
    $manifestJson = @{
        "manifest_version" = 3
        "name" = "Genesys DR Environment Indicator"
        "version" = "1.0"
        "description" = "Adds prominent visual cues to DR environments in Microsoft Edge"
        "content_scripts" = @(
            @{
                "matches" = @("https://www.toronto.ca/*")  # Would be DR environment URL in production
                "css" = @("dr-style.css")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Create CSS file for visual styling - more prominent banner for easy testing
    $cssContent = @"
/* Add a prominent red banner to the top of the page */
body::before {
  content: "DR ENVIRONMENT - SCCM DEPLOYED EXTENSION";
  display: block;
  background-color: #ff0000;
  color: white;
  text-align: center;
  padding: 10px;
  font-weight: bold;
  font-size: 16px;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 999999;
}

/* Add space at the top of the body to prevent content from being hidden */
body {
  margin-top: 40px !important;
}
"@
    
    # Write extension files
    Set-Content -Path "$extensionFolder\manifest.json" -Value $manifestJson
    Set-Content -Path "$extensionFolder\dr-style.css" -Value $cssContent
    
    # Create the extension package (crx file)
    $crxPath = "C:\Program Files\GenesysPOC\GenesysDR_Edge.crx"
    Write-Host "Creating extension package at $crxPath..." -ForegroundColor Yellow
    
    # For simulation, we can just copy the files (in a real scenario, you'd properly package as crx)
    Compress-Archive -Path "$extensionFolder\*" -DestinationPath "$crxPath.zip" -Force
    Copy-Item "$crxPath.zip" -Destination $crxPath -Force
    
    # Create a random but consistent extension ID (for simulation purposes)
    $extensionId = "genesysdrenv_" + [Guid]::NewGuid().ToString().Substring(0, 8)
    
    # Create registry key to force-install the extension (this is what SCCM would do)
    $registryPath = "HKCU:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    
    # Create the registry path if it doesn't exist
    if (-not (Test-Path $registryPath)) {
        Write-Host "Creating registry key structure for Edge extension policy..." -ForegroundColor Yellow
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Add extension to force-install list (1 is just an index, can be any number not already used)
    $extensionValue = "1:$extensionId;file:///$crxPath"
    Write-Host "Setting registry value to force-install extension..." -ForegroundColor Yellow
    New-ItemProperty -Path $registryPath -Name "1" -Value $extensionValue -PropertyType String -Force | Out-Null
    
    Write-Host "`nSCCM Enterprise Deployment simulation complete!" -ForegroundColor Green
    Write-Host "The Edge extension has been 'force-installed' via registry policy." -ForegroundColor Green
    Write-Host "This simulates what happens when SCCM deploys the extension." -ForegroundColor Green
    Write-Host "`nWhen you open Edge and navigate to the DR site (toronto.ca), you should" -ForegroundColor Cyan 
    Write-Host "see the extension automatically apply a red banner to the page." -ForegroundColor Cyan
    Write-Host "`nNote: You may need to restart Edge completely for the extension to activate." -ForegroundColor Yellow
    
    # Launch the DR shortcut to show the result
    Write-Host "`nLaunching the DR shortcut to demonstrate the extension..." -ForegroundColor Yellow
    Start-Process -FilePath $drShortcutPath
}

if ($selection -eq "0") {
    Write-Host "`nSkipping additional differentiation. Basic shortcuts are already created." -ForegroundColor Yellow
}

# Testing Instructions
Write-Host "`n----- TESTING INSTRUCTIONS -----" -ForegroundColor Magenta
Write-Host "1. Test the PROD shortcut:" -ForegroundColor White
Write-Host "   - Double-click the 'Genesys PROD (Edge)' shortcut on your desktop"
Write-Host "   - Verify it opens Edge in app mode with the correct URL"
Write-Host "`n2. Test the DR shortcut:" -ForegroundColor White
Write-Host "   - Double-click the 'Genesys DR (Edge)' shortcut on your desktop"
Write-Host "   - Verify it opens with visual differences (icon, theme, etc.)"
Write-Host "`n3. Compare both environments side by side to ensure clear visual differentiation" -ForegroundColor White

Write-Host "`nPOC implementation complete!" -ForegroundColor Green 