#
# GenesysCloudDR.ps1
# Creates a Genesys Cloud DR shortcut with visual differentiation via Chrome extension
#
# Usage examples:
# 1. Default usage: .\GenesysCloudDR.ps1
# 2. Custom title/URLs: .\GenesysCloudDR.ps1 -ProdTitle "Genesys Prod" -DrTitle "Genesys DR" -ProdUrl "https://apps.cac1.pure.cloud" -DrUrl "https://apps.dr1.pure.cloud"
#

param(
    [string]$ProdTitle = "Genesys Cloud",
    [string]$DrTitle = "Genesys Cloud DR",
    [string]$ProdUrl = "https://apps.cac1.pure.cloud:443",
    [string]$DrUrl = "https://apps.dr1.pure.cloud:443",
    [string]$ProdIconPath = $null,
    [string]$DrIconPath = $null,
    [switch]$Silent = $false
)

# Function for logging
function Write-Log {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

Write-Log "Starting Genesys Cloud environment setup..." -ForegroundColor Green

# Create working directories
$programFilesPath = "C:\Program Files\GenesysPOC"
$tempPath = "C:\Temp\GenesysPOC"
New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
New-Item -Path $tempPath -ItemType Directory -Force | Out-Null

# Set up custom icons with proper validation
Write-Log "Setting up custom icons for shortcuts..." -ForegroundColor Yellow

# Define icon paths - both custom and fallback
if (-not $ProdIconPath) {
    $customProdIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_icon.ico"
} else {
    $customProdIconPath = $ProdIconPath
}

if (-not $DrIconPath) {
    $customDrIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_DR_256.ico"
} else {
    $customDrIconPath = $DrIconPath
}

$fallbackProdIconPath = "$env:SystemRoot\System32\shell32.dll,4"  # Blue globe icon
$fallbackDrIconPath = "$env:SystemRoot\System32\imageres.dll,8"   # Red shield icon

# Final icon paths 
$prodIconPath = $fallbackProdIconPath
$drIconPath = $fallbackDrIconPath

# Function to validate if an ICO file is valid
function Test-IconFile {
    param(
        [string]$IconPath
    )
    
    # Check if file exists and has .ico extension
    if (-not (Test-Path $IconPath)) {
        Write-Log "Icon file not found $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    if (-not $IconPath.ToLower().EndsWith(".ico")) {
        Write-Log "File is not an ICO file $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    # Check if file size is too small (likely invalid)
    $fileInfo = Get-Item $IconPath
    if ($fileInfo.Length -lt 100) {
        Write-Log "Icon file appears to be invalid (too small) $IconPath" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

# Determine which icons to use with validation
if (Test-IconFile $customProdIconPath) {
    $prodIconPath = $customProdIconPath
    Write-Log "Using custom PROD icon $prodIconPath" -ForegroundColor Green
} else {
    Write-Log "Using fallback PROD icon $prodIconPath" -ForegroundColor Yellow
}

if (Test-IconFile $customDrIconPath) {
    $drIconPath = $customDrIconPath
    Write-Log "Using custom DR icon $drIconPath" -ForegroundColor Green
} else {
    Write-Log "Using fallback DR icon $drIconPath" -ForegroundColor Yellow
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
        Write-Log "WARNING: Google Chrome executable not found at expected locations." -ForegroundColor Yellow
        Write-Log "Using 'chrome.exe' and relying on PATH environment. This may not work correctly." -ForegroundColor Yellow
        $chromePath = "chrome.exe"
    }
}

Write-Log "Using Google Chrome from $chromePath" -ForegroundColor Green

# Create Chrome Extension for visual differentiation
Write-Log "Creating Chrome extension for DR environment visual indicators..." -ForegroundColor Yellow

# Create extension directory
$extensionFolder = "$programFilesPath\ChromeExtension"
New-Item -Path $extensionFolder -ItemType Directory -Force | Out-Null

# Extract domain from DR URL for the extension matching pattern
$drDomain = [System.Uri]$DrUrl
$matchPattern = "$($drDomain.Scheme)://$($drDomain.Authority)/*"

# Create manifest.json for the extension
$manifestJson = @{
    "manifest_version" = 3
    "name" = "Genesys DR Environment Indicator"
    "version" = "1.0"
    "description" = "Adds prominent visual cues to DR environments in Google Chrome"
    "content_scripts" = @(
        @{
            "matches" = @($matchPattern)  # Dynamic pattern based on DR URL
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
Write-Log "Setting permissions on extension folder..." -ForegroundColor Yellow
$acl = Get-Acl $extensionFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionFolder $acl

# Create a user data directory for Chrome to ensure extension persistence
$userDataDir = "$tempPath\ChromeUserData"
New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
Write-Log "Created custom Chrome user data directory $userDataDir" -ForegroundColor Green

# Create desktop shortcuts
Write-Log "Creating desktop shortcuts..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell

# Get desktop path
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Create PROD shortcut - using actual Genesys Cloud production URL
$Shortcut = $WshShell.CreateShortcut("$desktopPath\$ProdTitle.lnk")
$Shortcut.TargetPath = $chromePath
$Shortcut.Arguments = "--app=$ProdUrl"
$Shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application\"
$Shortcut.IconLocation = "$prodIconPath,0"
$Shortcut.Save()

# Create DR shortcut with visual differentiation and direct extension loading
$Shortcut = $WshShell.CreateShortcut("$desktopPath\$DrTitle.lnk")
$Shortcut.TargetPath = $chromePath
# Use custom user data directory and load-extension flag to ensure consistent extension loading
$Shortcut.Arguments = "--app=$DrUrl --force-dark-mode --user-data-dir=""$userDataDir"" --load-extension=""$extensionFolder"" --no-first-run"
$Shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application\"
$Shortcut.IconLocation = "$drIconPath,0"
$Shortcut.Save()

Write-Log "Desktop shortcuts created successfully!" -ForegroundColor Green
Write-Log "Setup complete." -ForegroundColor Green

# Return success code for SCCM
exit 0 