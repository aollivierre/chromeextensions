#
# DeleteShortcut.ps1
# PowerShell replacement for DeleteShortcut.vbs used in SCCM uninstall
#
# Usage: .\DeleteShortcut.ps1 "Shortcut Title"
#
# Example: .\DeleteShortcut.ps1 "Genesys Cloud"
#

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Title
)

# Get desktop path
$desktopPath = [System.Environment]::GetFolderPath('Desktop')

# Delete the shortcut file
$shortcutPath = Join-Path $desktopPath "$Title.lnk"

if (Test-Path $shortcutPath) {
    try {
        Remove-Item -Path $shortcutPath -Force
        Write-Host "Shortcut '$Title' deleted successfully from the desktop."
    }
    catch {
        Write-Warning "Failed to delete shortcut '$Title': $_"
    }
}
else {
    Write-Warning "Shortcut '$Title' not found on the desktop."
} 