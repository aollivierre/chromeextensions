#
# Install-GenesysCloudDRExtension.ps1
# Installs the Genesys Cloud DR Chrome Extension by copying it to Program Files
#

# Get the script directory to find the extension files
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$extensionSourcePath = Join-Path -Path $scriptPath -ChildPath "Extension"

# Target installation folder
$programFilesPath = "C:\Program Files\GenesysPOC"
$extensionTargetPath = "$programFilesPath\ChromeExtension"

# Create destination directory if it doesn't exist
if (-not (Test-Path -Path $programFilesPath)) {
    New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
}

# Create or clean the extension directory
if (Test-Path -Path $extensionTargetPath) {
    # Clean existing files
    Remove-Item -Path "$extensionTargetPath\*" -Force -Recurse
} else {
    # Create the directory if it doesn't exist
    New-Item -Path $extensionTargetPath -ItemType Directory -Force | Out-Null
}

# Copy extension files
Copy-Item -Path "$extensionSourcePath\*" -Destination $extensionTargetPath -Recurse -Force

# Set appropriate permissions so Chrome can access the extension
$acl = Get-Acl $extensionTargetPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionTargetPath $acl 