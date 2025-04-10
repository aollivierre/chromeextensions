#
# Detect-GenesysCloudDRExtension.ps1
# Detects if the Genesys Cloud DR Chrome Extension is installed
#

# Target installation folder
$programFilesPath = "C:\Program Files\GenesysPOC"
$extensionPath = "$programFilesPath\ChromeExtension"
$manifestPath = "$extensionPath\manifest.json"
$cssPath = "$extensionPath\dr-style.css"
$jsPath = "$extensionPath\dr-script.js"

# Check if extension files exist and are valid
$extensionInstalled = $false

if (Test-Path -Path $manifestPath -PathType Leaf) {
    if (Test-Path -Path $cssPath -PathType Leaf) {
        if (Test-Path -Path $jsPath -PathType Leaf) {
            # Verify manifest content (simple check)
            $manifestContent = Get-Content -Path $manifestPath -Raw
            if ($manifestContent -match '"name"\s*:\s*"Genesys DR Environment Indicator"') {
                $extensionInstalled = $true
            }
        }
    }
}

# Output detection result - output "Installed" when extension is found
if ($extensionInstalled) {
    Write-Host "Installed"
}
# No output when action is needed 