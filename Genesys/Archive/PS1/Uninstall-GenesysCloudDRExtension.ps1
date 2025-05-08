#
# Uninstall-GenesysCloudDRExtension.ps1
# Uninstalls the unpacked Genesys Cloud DR Chrome Extension files
# Note: This script only removes unpacked extension files, not Chrome policies
# Chrome policies should be managed separately
#

# Start logging
$logFile = "$env:TEMP\GenesysCloudDR_Uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Output "Starting Genesys Cloud DR Chrome Extension uninstallation at $(Get-Date)"

try {
    # Define the installation paths
    $extensionPath = "C:\Program Files\GenesysPOC\ChromeExtension"
    $parentDir = "C:\Program Files\GenesysPOC"
    
    # Check if the extension directory exists
    if (Test-Path -Path $extensionPath -PathType Container) {
        Write-Output "Removing extension directory at $extensionPath"
        Remove-Item -Path $extensionPath -Recurse -Force -ErrorAction SilentlyContinue
        
        # Verify removal
        if (-not (Test-Path -Path $extensionPath)) {
            Write-Output "Successfully removed extension directory"
        } else {
            Write-Warning "Failed to remove extension directory at $extensionPath"
        }
        
        # Check if parent directory is empty and remove if it is
        if (Test-Path -Path $parentDir -PathType Container) {
            $items = Get-ChildItem -Path $parentDir -Force -ErrorAction SilentlyContinue
            if ($null -eq $items -or $items.Count -eq 0) {
                Write-Output "Removing empty parent directory at $parentDir"
                Remove-Item -Path $parentDir -Force -ErrorAction SilentlyContinue
                
                # Verify removal
                if (-not (Test-Path -Path $parentDir)) {
                    Write-Output "Successfully removed parent directory"
                } else {
                    Write-Warning "Failed to remove parent directory at $parentDir"
                }
            } else {
                Write-Output "Parent directory not empty, skipping removal"
            }
        }
    } else {
        Write-Output "Extension directory not found at $extensionPath, nothing to remove"
    }
    
    Write-Output "Unpacked extension files uninstallation completed"
    Write-Output "Note: Chrome policies were not modified and should be managed separately if needed"

} catch {
    Write-Error "Error during uninstallation: $_"
    exit 1
} finally {
    Write-Output "Genesys Cloud DR Chrome Extension uninstallation finished at $(Get-Date)"
    Write-Output "Log file saved to $logFile"
    Stop-Transcript
}

exit 0 