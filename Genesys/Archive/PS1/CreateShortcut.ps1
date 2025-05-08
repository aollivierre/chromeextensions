#
# CreateShortcut.ps1
# PowerShell script for creating desktop shortcuts, designed for SCCM deployment
#
# Example usage: 
# .\CreateShortcut.ps1 -Title "Genesys Cloud" -IconFile "C:\Program Files\GenesysCloud\icon.ico" -TargetPath "C:\Program Files\GenesysCloud\GenesysCloud.exe" -Arguments "/silent" -WorkingDir "C:\Program Files\GenesysCloud"
# .\CreateShortcut.ps1 -Title "Genesys Cloud" -IconFile "C:\Program Files\GenesysCloud\icon.ico" -TargetPath "C:\Program Files\GenesysCloud\GenesysCloud.exe" -Arguments "/silent" -WorkingDir "C:\Program Files\GenesysCloud" -AllUsers $true
#

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    
    [Parameter(Mandatory=$false)]
    [string]$IconFile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Arguments = "",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkingDir = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$AllUsers = $false
)

# Function to create a shortcut
function New-Shortcut {
    param (
        [string]$DesktopPath,
        [string]$ShortcutTitle,
        [string]$TargetPath,
        [string]$IconFile,
        [string]$Arguments,
        [string]$WorkingDir
    )
    
    # Full path to the shortcut file
    $shortcutPath = Join-Path -Path $DesktopPath -ChildPath "$ShortcutTitle.lnk"
    
    try {
        # Create a WScript.Shell object to create the shortcut
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        
        # Set shortcut properties
        $Shortcut.TargetPath = $TargetPath
        
        if ($Arguments -ne "") {
            $Shortcut.Arguments = $Arguments
        }
        
        if ($WorkingDir -ne "") {
            $Shortcut.WorkingDirectory = $WorkingDir
        }
        
        if ($IconFile -ne "") {
            $Shortcut.IconLocation = $IconFile
        }
        
        # Save the shortcut
        $Shortcut.Save()
        
        Write-Host "Shortcut created successfully at $shortcutPath"
        return $true
    }
    catch {
        Write-Error "Error creating shortcut at $shortcutPath`r`n$_"
        return $false
    }
}

# Check if icon file exists and if it's a relative path, convert to absolute
if ($IconFile -ne "") {
    if (-not [System.IO.Path]::IsPathRooted($IconFile)) {
        # Convert relative path to absolute
        $IconFile = Join-Path $PSScriptRoot $IconFile
    }
    
    # Verify icon file exists
    if (-not (Test-Path $IconFile)) {
        Write-Warning "Icon file not found at $IconFile. Shortcut will use default icon."
        $IconFile = ""
    }
}

# If no working directory specified, use the target path's directory
if ($WorkingDir -eq "") {
    $WorkingDir = Split-Path -Parent $TargetPath
}

# Get current user's desktop path
$userDesktopPath = [System.Environment]::GetFolderPath('Desktop')

# Create shortcut on current user's desktop
$userResult = New-Shortcut -DesktopPath $userDesktopPath -ShortcutTitle $Title -TargetPath $TargetPath -IconFile $IconFile -Arguments $Arguments -WorkingDir $WorkingDir

# If AllUsers is specified, also create on Public desktop
if ($AllUsers) {
    $publicDesktopPath = [System.Environment]::GetFolderPath('CommonDesktopDirectory')
    $publicResult = New-Shortcut -DesktopPath $publicDesktopPath -ShortcutTitle $Title -TargetPath $TargetPath -IconFile $IconFile -Arguments $Arguments -WorkingDir $WorkingDir
    
    # Exit with success only if both operations succeeded
    if ($userResult -and $publicResult) {
        exit 0
    } else {
        exit 1
    }
} else {
    # Exit based on the result of creating user desktop shortcut
    if ($userResult) {
        exit 0
    } else {
        exit 1
    }
} 