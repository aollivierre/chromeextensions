#
# RemoveShortcut.ps1
# PowerShell script for removing desktop shortcuts, designed for SCCM deployment
#
# Example usage: 
# .\RemoveShortcut.ps1 -Title "Genesys Cloud"
# .\RemoveShortcut.ps1 -Title "Genesys Cloud" -AllUsers $true
#

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,
    
    [Parameter(Mandatory=$false)]
    [bool]$AllUsers = $false
)

# Function to remove a shortcut if it exists
function Remove-ShortcutFile {
    param (
        [string]$Path,
        [string]$ShortcutName
    )
    
    $fullPath = Join-Path -Path $Path -ChildPath "$ShortcutName.lnk"
    
    if (Test-Path $fullPath) {
        try {
            # Remove the shortcut
            Remove-Item -Path $fullPath -Force
            
            # Verify the shortcut was removed
            if (-not (Test-Path $fullPath)) {
                Write-Host "Shortcut '$ShortcutName' was successfully removed from $Path"
                return $true
            } else {
                Write-Warning "Failed to remove shortcut '$ShortcutName' from $Path"
                return $false
            }
        }
        catch {
            Write-Error "Error removing shortcut '$ShortcutName' from $Path`r`n$_"
            return $false
        }
    } else {
        Write-Host "Shortcut '$ShortcutName' was not found in $Path. No action taken."
        return $true
    }
}

# Get current user's desktop path
$userDesktopPath = [System.Environment]::GetFolderPath('Desktop')

# Remove from current user's desktop
$userResult = Remove-ShortcutFile -Path $userDesktopPath -ShortcutName $Title

# If AllUsers is specified, also remove from Public desktop
if ($AllUsers) {
    $publicDesktopPath = [System.Environment]::GetFolderPath('CommonDesktopDirectory')
    $publicResult = Remove-ShortcutFile -Path $publicDesktopPath -ShortcutName $Title
    
    # Exit with success only if both operations succeeded
    if ($userResult -and $publicResult) {
        exit 0
    } else {
        exit 1
    }
} else {
    # Exit based on the result of removing from user desktop
    if ($userResult) {
        exit 0
    } else {
        exit 1
    }
} 