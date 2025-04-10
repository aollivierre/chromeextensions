#
# SCCM_Deploy_GenesysEnvDifferentiation.ps1
# Script for deploying Genesys Environment Differentiation via SCCM
#

param (
    [switch]$Uninstall = $false
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = "$env:TEMP\GenesysEnvDifferentiation_Deploy.log"

# Create paths for Chrome extension
$programFilesPath = "C:\Program Files\GenesysPOC"
$tempPath = "C:\Temp\GenesysPOC"
$extensionFolder = "$programFilesPath\ChromeExtension"
$userDataDir = "$tempPath\ChromeUserData"

# Define desktop paths
$currentUserDesktop = [Environment]::GetFolderPath('Desktop')
$publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')

# Define shortcut paths
$prodShortcutName = "Genesys Cloud (Chrome)"
$drShortcutName = "Genesys Cloud DR (Chrome)"
$prodShortcutPath = "$publicDesktop\$prodShortcutName.lnk"
$drShortcutPath = "$publicDesktop\$drShortcutName.lnk"

# Extension content source paths
$sourceFolder = $ScriptPath
$sourceExtensionFolder = "$sourceFolder\ChromeExtension"
$sourceProdIconPath = "$sourceFolder\Genesys Cloud\GenesysCloud_icon.ico"
$sourceDrIconPath = "$sourceFolder\Genesys Cloud\GenesysCloud_DR_256.ico"

# Initialize log file
function Write-Log {
    param ([string]$Message)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

# Function to find Chrome
function Find-ChromePath {
    $possiblePaths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

# Function to create a shortcut
function Create-Shortcut {
    param (
        [string]$Path,
        [string]$TargetPath,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$IconLocation
    )
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.Arguments = $Arguments
        $Shortcut.WorkingDirectory = $WorkingDirectory
        $Shortcut.IconLocation = "$IconLocation,0"
        $Shortcut.Save()
        
        Write-Log "Shortcut created successfully at $Path"
        return $true
    }
    catch {
        Write-Log "ERROR: Failed to create shortcut at $Path. Error: $_"
        return $false
    }
}

# Function to install the extension
function Install-ChromeExtension {
    Write-Log "Creating Chrome extension directories..."
    
    # Create necessary directories
    New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
    New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    New-Item -Path $extensionFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
    
    # Check if source extension files exist
    if (-not (Test-Path $sourceExtensionFolder)) {
        Write-Log "ERROR: Source extension folder not found at $sourceExtensionFolder"
        return $false
    }
    
    # Copy extension files
    try {
        Copy-Item -Path "$sourceExtensionFolder\*" -Destination $extensionFolder -Recurse -Force
        Write-Log "Extension files copied to $extensionFolder"
    }
    catch {
        Write-Log "ERROR: Failed to copy extension files. Error: $_"
        return $false
    }
    
    # Set permissions on extension folder
    try {
        $acl = Get-Acl $extensionFolder
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl $extensionFolder $acl
        Write-Log "Permissions set on extension folder"
    }
    catch {
        Write-Log "ERROR: Failed to set permissions on extension folder. Error: $_"
        return $false
    }
    
    return $true
}

# Function to verify extension installation
function Verify-ExtensionInstallation {
    if (-not (Test-Path $extensionFolder)) {
        Write-Log "ERROR: Extension folder not found at $extensionFolder"
        return $false
    }
    
    $requiredFiles = @("manifest.json", "dr-style.css", "dr-script.js")
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path "$extensionFolder\$file")) {
            Write-Log "ERROR: Required extension file $file not found"
            return $false
        }
    }
    
    Write-Log "Extension installation verified successfully"
    return $true
}

# Function to create shortcuts
function Create-Shortcuts {
    $chromePath = Find-ChromePath
    if (-not $chromePath) {
        Write-Log "ERROR: Chrome not found. Cannot create shortcuts."
        return $false
    }
    
    Write-Log "Using Chrome at $chromePath"
    
    # Create PROD shortcut
    $prodIconPath = if (Test-Path $sourceProdIconPath) { $sourceProdIconPath } else { "$extensionFolder\genesys_prod.ico" }
    $prodSuccess = Create-Shortcut -Path $prodShortcutPath -TargetPath $chromePath `
        -Arguments "--app=https://apps.cac1.pure.cloud:443" `
        -WorkingDirectory (Split-Path $chromePath) `
        -IconLocation $prodIconPath
    
    # Create DR shortcut
    $drIconPath = if (Test-Path $sourceDrIconPath) { $sourceDrIconPath } else { "$extensionFolder\genesys_dr.ico" }
    $drArguments = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode " + 
                   "--user-data-dir=""$userDataDir"" --load-extension=""$extensionFolder"" --no-first-run"
    
    $drSuccess = Create-Shortcut -Path $drShortcutPath -TargetPath $chromePath `
        -Arguments $drArguments `
        -WorkingDirectory (Split-Path $chromePath) `
        -IconLocation $drIconPath
    
    return ($prodSuccess -and $drSuccess)
}

# Function to uninstall everything
function Uninstall-GenesysEnv {
    Write-Log "Starting uninstallation..."
    
    # Remove shortcuts
    if (Test-Path $prodShortcutPath) {
        Remove-Item -Path $prodShortcutPath -Force
        Write-Log "Removed PROD shortcut"
    }
    
    if (Test-Path $drShortcutPath) {
        Remove-Item -Path $drShortcutPath -Force
        Write-Log "Removed DR shortcut"
    }
    
    # Close any Chrome instances using our extension
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match [regex]::Escape($extensionFolder) }
    
    if ($chromeProcesses) {
        Write-Log "Closing Chrome instances using our extension..."
        $chromeProcesses | ForEach-Object {
            Try {
                $_.CloseMainWindow() | Out-Null
                Start-Sleep -Seconds 1
                if (-not $_.HasExited) {
                    $_.Kill()
                }
            } Catch {
                Write-Log "Error closing Chrome process: $_"
            }
        }
    }
    
    # Remove extension folder
    if (Test-Path $extensionFolder) {
        try {
            Remove-Item -Path $extensionFolder -Recurse -Force
            Write-Log "Removed extension folder"
        } catch {
            Write-Log "ERROR: Failed to remove extension folder. Error: $_"
        }
    }
    
    # Remove user data directory
    if (Test-Path $userDataDir) {
        try {
            Remove-Item -Path $userDataDir -Recurse -Force
            Write-Log "Removed Chrome user data directory"
        } catch {
            Write-Log "ERROR: Failed to remove user data directory. Error: $_"
        }
    }
    
    # Remove parent folders if empty
    if ((Test-Path $programFilesPath) -and -not (Get-ChildItem $programFilesPath)) {
        try {
            Remove-Item -Path $programFilesPath -Force
            Write-Log "Removed empty program files folder"
        } catch {
            Write-Log "Failed to remove program files folder: $_"
        }
    }
    
    if ((Test-Path $tempPath) -and -not (Get-ChildItem $tempPath)) {
        try {
            Remove-Item -Path $tempPath -Force
            Write-Log "Removed empty temp folder"
        } catch {
            Write-Log "Failed to remove temp folder: $_"
        }
    }
    
    Write-Log "Uninstallation completed"
    return $true
}

# Main execution
Write-Log "==== Starting Genesys Environment Differentiation Deployment ===="
Write-Log "Script path: $ScriptPath"

if ($Uninstall) {
    Write-Log "Running in uninstall mode"
    $result = Uninstall-GenesysEnv
    
    if ($result) {
        Write-Log "Uninstallation completed successfully"
        exit 0
    } else {
        Write-Log "Uninstallation failed"
        exit 1
    }
}

# Install mode
Write-Log "Running in install mode"

# Step 1: Install Chrome extension
Write-Log "Step 1: Installing Chrome extension..."
$extensionResult = Install-ChromeExtension
if (-not $extensionResult) {
    Write-Log "Failed to install Chrome extension. Exiting."
    exit 1
}

# Step 2: Verify extension installation
Write-Log "Step 2: Verifying extension installation..."
$verifyResult = Verify-ExtensionInstallation
if (-not $verifyResult) {
    Write-Log "Extension verification failed. Exiting."
    exit 1
}

# Step 3: Create shortcuts
Write-Log "Step 3: Creating shortcuts..."
$shortcutsResult = Create-Shortcuts
if (-not $shortcutsResult) {
    Write-Log "Failed to create shortcuts. Exiting."
    exit 1
}

Write-Log "Installation completed successfully"
exit 0 