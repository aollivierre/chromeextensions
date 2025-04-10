#
# Detect-GenesysCloudDRExtension.ps1
# Detects whether the unpacked Genesys Cloud DR Chrome Extension is installed
# Note: This script only checks for the unpacked extension files, not Chrome policies
#

# Define the installation path
$extensionPath = "C:\Program Files\GenesysPOC\ChromeExtension"

# Define required files to check
$requiredFiles = @(
    "manifest.json",
    "dr-script.js",
    "dr-style.css"
)

# First check if the directory exists
if (-not (Test-Path -Path $extensionPath -PathType Container)) {
    Write-Output "Extension directory not found at $extensionPath"
    exit 1
}

# Check if required files exist
$missingFiles = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path -Path $extensionPath -ChildPath $file
    if (-not (Test-Path -Path $filePath -PathType Leaf)) {
        $missingFiles += $file
    }
}

# If any required files are missing, report failure
if ($missingFiles.Count -gt 0) {
    Write-Output "Missing required extension files: $($missingFiles -join ', ')"
    exit 1
}

# If we got here, all checks passed
Write-Output "Genesys Cloud DR Chrome Extension files detected successfully"
exit 0 