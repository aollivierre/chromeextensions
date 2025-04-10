#
# Create-DRShortcut-Direct.ps1
# Creates a shortcut using an alternative approach to ensure all parameters are included
#

# Ensure required folders exist
$ChromeUserDataDir = "C:\Temp\GenesysPOC\ChromeUserData"
if (-not (Test-Path -Path $ChromeUserDataDir)) {
    New-Item -Path $ChromeUserDataDir -ItemType Directory -Force | Out-Null
}

# Get script directory for the icon file
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$IconFile = Join-Path -Path $ScriptDir -ChildPath "GenesysCloud_DR_256.ico" 

# Store icon in Windows folder
$WindowsFolder = "$env:USERPROFILE\AppData\Local\Microsoft\Windows"
Copy-Item -Path $IconFile -Destination $WindowsFolder -Force

# Define the shortcut components
$ShortcutTitle = "Genesys Cloud DR"
$Desktop = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = "$Desktop\$ShortcutTitle.lnk"

# Try multiple approaches to ensure the shortcut gets created with all parameters
Write-Host "Attempting shortcut creation with multiple methods..."

# Approach 1: Split the arguments and construct them carefully
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$ChromeWorkingDir = "C:\Program Files\Google\Chrome\Application\"
$ExtensionPath = "C:\Program Files\GenesysPOC\ChromeExtension"

# Create shortcut using the shell extension method
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $ChromePath

# Try with the --no-first-run at the beginning
$Shortcut.Arguments = "--no-first-run --app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=`"$ChromeUserDataDir`" --load-extension=`"$ExtensionPath`""

$Shortcut.WorkingDirectory = $ChromeWorkingDir
$Shortcut.IconLocation = "$WindowsFolder\$(Split-Path -Leaf $IconFile), 0"
$Shortcut.WindowStyle = 3  # Maximized
$Shortcut.Save()

# Check if the shortcut was created properly
try {
    $CreatedShortcut = New-Object -ComObject WScript.Shell
    $ShortcutVerify = $CreatedShortcut.CreateShortcut($ShortcutPath)
    
    Write-Host "`nShortcut created with the following properties:" -ForegroundColor Green
    Write-Host "Target: $($ShortcutVerify.TargetPath)" -ForegroundColor Cyan
    Write-Host "Arguments: $($ShortcutVerify.Arguments)" -ForegroundColor Cyan
    Write-Host "Working Directory: $($ShortcutVerify.WorkingDirectory)" -ForegroundColor Cyan
    
    # Check for the --no-first-run parameter
    if ($ShortcutVerify.Arguments -notlike "*--no-first-run*") {
        Write-Host "`nWarning: --no-first-run parameter is not in the shortcut arguments" -ForegroundColor Yellow
        
        # Approach 2: Try creating a batch file wrapper as a last resort
        Write-Host "Attempting to create a batch file wrapper as an alternative solution..." -ForegroundColor Yellow
        
        $BatFile = "$env:USERPROFILE\AppData\Local\Temp\GenesysDR.bat"
        
        # Create a batch file with the full command
        @"
@echo off
start "" "$ChromePath" --no-first-run --app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir="$ChromeUserDataDir" --load-extension="$ExtensionPath"
"@ | Out-File -FilePath $BatFile -Encoding ASCII
        
        # Create a shortcut to the batch file instead
        $BatShortcut = $WshShell.CreateShortcut($ShortcutPath)
        $BatShortcut.TargetPath = $BatFile
        $BatShortcut.WorkingDirectory = $ChromeWorkingDir
        $BatShortcut.IconLocation = "$WindowsFolder\$(Split-Path -Leaf $IconFile), 0"
        $BatShortcut.WindowStyle = 7  # Minimized (to hide the CMD window)
        $BatShortcut.Save()
        
        Write-Host "Created a batch file wrapper shortcut as an alternative approach." -ForegroundColor Yellow
    }
    else {
        Write-Host "`nSuccess! All parameters were included in the shortcut." -ForegroundColor Green
    }
} 
catch {
    Write-Host "Error verifying shortcut: $_" -ForegroundColor Red
}

Write-Host "`nShortcut creation process completed." -ForegroundColor Green 