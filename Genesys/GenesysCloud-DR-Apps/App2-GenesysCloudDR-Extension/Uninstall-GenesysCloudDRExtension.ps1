#
# Uninstall-GenesysCloudDRExtension.ps1
# Removes the Genesys Cloud DR Chrome Extension
#

# Target installation folder
$programFilesPath = "C:\Program Files\GenesysPOC"
$extensionPath = "$programFilesPath\ChromeExtension"

# Remove extension directory if it exists
if (Test-Path -Path $extensionPath) {
    Remove-Item -Path $extensionPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Optionally remove the parent GenesysPOC folder if it's empty
if (Test-Path -Path $programFilesPath) {
    $items = Get-ChildItem -Path $programFilesPath -ErrorAction SilentlyContinue
    if (-not $items) {
        Remove-Item -Path $programFilesPath -Force -ErrorAction SilentlyContinue
    }
} 