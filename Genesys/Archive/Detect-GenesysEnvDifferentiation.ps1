#
# Detect-GenesysEnvDifferentiation.ps1
# SCCM detection script for Genesys Environment Differentiation
#
# This script follows SCCM detection script best practices:
# - Exit code 0 means component is installed (detected)
# - Any other exit code means component is not installed (not detected)
#

# Required paths to check
$programFilesPath = "C:\Program Files\GenesysPOC"
$extensionFolder = "$programFilesPath\ChromeExtension"
$publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
$prodShortcutPath = "$publicDesktop\Genesys Cloud (Chrome).lnk"
$drShortcutPath = "$publicDesktop\Genesys Cloud DR (Chrome).lnk"

# Define required extension files
$requiredExtensionFiles = @(
    "$extensionFolder\manifest.json",
    "$extensionFolder\dr-style.css",
    "$extensionFolder\dr-script.js"
)

# Check if required folders exist
$foldersExist = (Test-Path $programFilesPath) -and (Test-Path $extensionFolder)
if (-not $foldersExist) {
    # Uncomment for troubleshooting:
    # Write-Host "Required folders not found"
    exit 1
}

# Check if required extension files exist
foreach ($file in $requiredExtensionFiles) {
    if (-not (Test-Path $file)) {
        # Uncomment for troubleshooting:
        # Write-Host "Required file not found: $file"
        exit 1
    }
}

# Check if manifest.json has the correct content
$manifestContent = Get-Content "$extensionFolder\manifest.json" -Raw -ErrorAction SilentlyContinue
if (-not $manifestContent -or -not ($manifestContent -match "login\.mypurecloud\.com")) {
    # Uncomment for troubleshooting:
    # Write-Host "Manifest file is missing or doesn't contain required URL patterns"
    exit 1
}

# Check if at least one shortcut exists
$shortcutExists = (Test-Path $prodShortcutPath) -or (Test-Path $drShortcutPath)
if (-not $shortcutExists) {
    # Uncomment for troubleshooting:
    # Write-Host "No shortcuts found"
    exit 1
}

# If the DR shortcut exists, verify it has the correct extension path
if (Test-Path $drShortcutPath) {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $drShortcut = $WshShell.CreateShortcut($drShortcutPath)
        
        # Check if the shortcut arguments contain our extension path
        $hasExtensionPath = $drShortcut.Arguments -match [regex]::Escape($extensionFolder)
        
        if (-not $hasExtensionPath) {
            # Uncomment for troubleshooting:
            # Write-Host "DR shortcut doesn't include the extension path"
            exit 1
        }
    }
    catch {
        # Uncomment for troubleshooting:
        # Write-Host "Error reading DR shortcut: $_"
        exit 1
    }
}

# All checks passed, return 0 to indicate the component is installed
exit 0 