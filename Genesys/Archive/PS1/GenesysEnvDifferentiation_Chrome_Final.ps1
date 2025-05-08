#
# Genesys Environment Differentiation for Chrome - Final Version
# 
# This script creates desktop shortcuts for Genesys PROD and DR environments using Chrome
# with visual differentiation via custom icons and a Chrome extension that adds visual indicators.
#

Write-Host "Starting Genesys Environment Differentiation setup..." -ForegroundColor Green

# Create working directories
Write-Host "Creating working directories..."
$programFilesPath = "C:\Program Files\GenesysPOC"
$tempPath = "C:\Temp\GenesysPOC"
New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
New-Item -Path $tempPath -ItemType Directory -Force | Out-Null

# Set up custom icons with proper validation
Write-Host "Setting up custom icons for shortcuts..." -ForegroundColor Yellow

# Define icon paths - both custom and fallback
$customProdIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_icon.ico"
$customDrIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_DR_256.ico"
$fallbackProdIconPath = "$env:SystemRoot\System32\shell32.dll,4"  # Blue globe icon
$fallbackDrIconPath = "$env:SystemRoot\System32\imageres.dll,8"   # Red shield icon

# Final icon paths 
$prodIconPath = $fallbackProdIconPath
$drIconPath = $fallbackDrIconPath

# Function to validate if an ICO file is valid
function Test-IconFile {
    param (
        [string]$IconPath
    )
    
    # Check if file exists and has .ico extension
    if (-not (Test-Path $IconPath)) {
        Write-Host "Icon file not found $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    if (-not $IconPath.ToLower().EndsWith(".ico")) {
        Write-Host "File is not an ICO file $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    # Check if file size is too small (likely invalid)
    $fileInfo = Get-Item $IconPath
    if ($fileInfo.Length -lt 100) {
        Write-Host "Icon file appears to be invalid (too small) $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

# Determine which icons to use with validation
if (Test-IconFile $customProdIconPath) {
    $prodIconPath = $customProdIconPath
    Write-Host "Using custom PROD icon $prodIconPath" -ForegroundColor Green
} else {
    Write-Host "Using fallback PROD icon $prodIconPath" -ForegroundColor Yellow
}

if (Test-IconFile $customDrIconPath) {
    $drIconPath = $customDrIconPath
    Write-Host "Using custom DR icon $drIconPath" -ForegroundColor Green
} else {
    Write-Host "Using fallback DR icon $drIconPath" -ForegroundColor Yellow
}

# Copy icons to program files location for permanent storage
$prodIconDestPath = "$programFilesPath\genesys_prod_chrome.ico"
$drIconDestPath = "$programFilesPath\genesys_dr_chrome.ico"

# Only copy if using custom icons and they're not in the system directory
if ($prodIconPath -ne $fallbackProdIconPath) {
    Copy-Item -Path $prodIconPath -Destination $prodIconDestPath -Force
    $prodIconPath = $prodIconDestPath
}

if ($drIconPath -ne $fallbackDrIconPath) {
    Copy-Item -Path $drIconPath -Destination $drIconDestPath -Force
    $drIconPath = $drIconDestPath
}

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

# Create Chrome Extension for visual differentiation
Write-Host "Creating Chrome extension for DR environment visual indicators..." -ForegroundColor Yellow

# Create extension directory
$extensionFolder = "$programFilesPath\ChromeExtension"
New-Item -Path $extensionFolder -ItemType Directory -Force | Out-Null

# Create manifest.json for the extension
$manifestJson = @{
    "manifest_version" = 3
    "name" = "Genesys DR Environment Indicator"
    "version" = "1.0"
    "description" = "Adds prominent visual cues to DR environments in Google Chrome"
    "content_scripts" = @(
        @{
            "matches" = @("https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr*")  # Correct DR environment URL
            "css" = @("dr-style.css")
            "all_frames" = $true
            "run_at" = "document_start"
        }
    )
    "permissions" = @("activeTab")
} | ConvertTo-Json -Depth 10

# Create CSS file with the known working style
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
Set-Content -Path "$extensionFolder\manifest.json" -Value $manifestJson
Set-Content -Path "$extensionFolder\dr-style.css" -Value $cssContent

# Apply proper permissions to extension folder to ensure Chrome can access it
Write-Host "Setting permissions on extension folder..." -ForegroundColor Yellow
$acl = Get-Acl $extensionFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionFolder $acl

# Create a user data directory for Chrome to ensure extension persistence
$userDataDir = "$tempPath\ChromeUserData"
New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
Write-Host "Created custom Chrome user data directory $userDataDir" -ForegroundColor Green

# Create desktop shortcuts
Write-Host "Creating desktop shortcuts..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell

# For all users if we have admin rights, otherwise just current user
$createAllUsersShortcuts = $false
try {
    # Test by trying to create a folder in Program Files
    $testPath = "$env:ProgramFiles\GenesysTest"
    New-Item -Path $testPath -ItemType Directory -Force | Out-Null
    Remove-Item -Path $testPath -Force | Out-Null
    $createAllUsersShortcuts = $true
} catch {
    $createAllUsersShortcuts = $false
}

# Determine desktop paths
$currentUserDesktop = "$env:USERPROFILE\Desktop"
$allUsersDesktop = "$env:PUBLIC\Desktop"
$desktopPath = if ($createAllUsersShortcuts) { $allUsersDesktop } else { $currentUserDesktop }

# Create PROD shortcut - using actual Genesys Cloud production URL
$Shortcut = $WshShell.CreateShortcut("$desktopPath\Genesys Cloud (Chrome).lnk")
$Shortcut.TargetPath = $chromePath
$Shortcut.Arguments = "--app=https://apps.cac1.pure.cloud:443"
$Shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application\"
$Shortcut.IconLocation = "$prodIconPath,0"
$Shortcut.Save()

# Create DR shortcut with visual differentiation and direct extension loading
$Shortcut = $WshShell.CreateShortcut("$desktopPath\Genesys Cloud DR (Chrome).lnk")
$Shortcut.TargetPath = $chromePath
# Use custom user data directory and load-extension flag to ensure consistent extension loading
$Shortcut.Arguments = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=""$userDataDir"" --load-extension=""$extensionFolder"" --no-first-run"
$Shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application\"
$Shortcut.IconLocation = "$drIconPath,0"
$Shortcut.Save()

Write-Host "Desktop shortcuts created successfully!" -ForegroundColor Green

# STEP 1: Close any running Chrome instances
Write-Host "`n----- STEP 1: Closing Chrome -----" -ForegroundColor Magenta
Write-Host "Automatically closing all Chrome processes..." -ForegroundColor Yellow
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "All Chrome processes closed." -ForegroundColor Green

# Wait a moment to ensure Chrome is fully closed
Write-Host "Waiting for Chrome to fully close..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# STEP 2: Verify extension configuration
Write-Host "`n----- STEP 2: Extension Configuration -----" -ForegroundColor Magenta
Write-Host "Extension will be loaded automatically using Chrome's command-line parameters." -ForegroundColor Green
Write-Host "Extension folder is configured at $extensionFolder" -ForegroundColor Green
Write-Host "Chrome will use a dedicated user data directory at $userDataDir" -ForegroundColor Green

# STEP 3: Launch the environments
Write-Host "`n----- STEP 3: Launching Environments -----" -ForegroundColor Magenta
Write-Host "Now launching both PROD and DR environments to demonstrate the difference..." -ForegroundColor Green

# Define shortcut paths
$prodShortcutPath = "$desktopPath\Genesys Cloud (Chrome).lnk"
$drShortcutPath = "$desktopPath\Genesys Cloud DR (Chrome).lnk"

# Launch PROD shortcut
Start-Process -FilePath $prodShortcutPath
Write-Host "PROD environment launched." -ForegroundColor Green

# Short delay before launching DR
Start-Sleep -Seconds 2

# Launch DR shortcut
Start-Process -FilePath $drShortcutPath
Write-Host "DR environment launched." -ForegroundColor Green

Write-Host "`nGenesys Environment Differentiation setup complete!" -ForegroundColor Green
Write-Host "You should now see the red DR banner at the top of the DR environment page." -ForegroundColor Green
Write-Host "If you don't see the banner, Chrome may need to be restarted or may require additional permissions." -ForegroundColor Yellow 