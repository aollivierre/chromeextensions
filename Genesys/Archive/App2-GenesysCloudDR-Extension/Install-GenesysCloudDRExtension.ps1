#
# Install-GenesysCloudDRExtension.ps1
# Installs the Genesys Cloud DR Chrome Extension as an unpacked extension for use with --load-extension
#

# Get the script directory to find the extension files
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$extensionSourcePath = Join-Path -Path $scriptPath -ChildPath "Extension"

# Target installation folder
$programFilesPath = "C:\Program Files\GenesysPOC"
$extensionTargetPath = "$programFilesPath\ChromeExtension"

# Create log file
$logFile = "$env:TEMP\GenesysCloudDR_Install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Genesys Cloud DR Extension installation - $(Get-Date)"

# Step 1: Create destination directory if it doesn't exist
Write-Host "Setting up installation directory..."
if (-not (Test-Path -Path $programFilesPath)) {
    New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
}

# Create or clean the extension directory
if (Test-Path -Path $extensionTargetPath) {
    # Clean existing files
    Write-Host "Cleaning existing extension files..."
    Remove-Item -Path "$extensionTargetPath\*" -Force -Recurse
} else {
    # Create the directory if it doesn't exist
    Write-Host "Creating extension directory..."
    New-Item -Path $extensionTargetPath -ItemType Directory -Force | Out-Null
}

# Step 2: Copy extension files
Write-Host "Copying extension files to $extensionTargetPath..."
Copy-Item -Path "$extensionSourcePath\*" -Destination $extensionTargetPath -Recurse -Force

# Step 3: Set appropriate permissions so Chrome can access the extension
Write-Host "Setting appropriate permissions..."
$acl = Get-Acl $extensionTargetPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionTargetPath $acl

# Step 4: Validate the installation
Write-Host "`nValidating installation..." -ForegroundColor Cyan

$validationSuccess = $true
$validationMessages = @()

# Check if critical extension files exist
# Define required files to check
$requiredFiles = @(
    "manifest.json",
    "dr-script.js",
    "dr-style.css"
)

foreach ($file in $requiredFiles) {
    $filePath = Join-Path -Path $extensionTargetPath -ChildPath $file
    if (Test-Path -Path $filePath) {
        Write-Host "Found $file" -ForegroundColor Green
    } else {
        $validationSuccess = $false
        $validationMessages += "$file is missing in the extension directory."
    }
}

# Display validation results
if ($validationSuccess) {
    Write-Host "Validation successful! Extension files are properly installed." -ForegroundColor Green
} else {
    Write-Host "Validation failed with the following issues:" -ForegroundColor Yellow
    foreach ($message in $validationMessages) {
        Write-Host "- $message" -ForegroundColor Yellow
    }
}

# Summary and completion message
Write-Host "`nGenesys Cloud DR Extension installation completed!" -ForegroundColor Green
Write-Host "`nTo use the extension, launch Chrome with the following parameter:" -ForegroundColor Cyan
Write-Host "--load-extension=`"$extensionTargetPath`"" -ForegroundColor Yellow

# Save log
Write-Host "`nInstallation log saved to: $logFile"
Stop-Transcript 