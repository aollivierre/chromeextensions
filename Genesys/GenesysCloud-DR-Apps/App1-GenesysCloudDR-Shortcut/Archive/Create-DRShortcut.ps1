#
# Create-DRShortcut.ps1
# Creates a desktop shortcut for Genesys Cloud DR with all required parameters
#

# Hardcoded values to avoid command-line parameter issues
$Title = "Genesys Cloud DR"
$IconFile = "GenesysCloud_DR_256.ico"
$Target = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$Arguments = '--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir="C:\Temp\GenesysPOC\ChromeUserData" --load-extension="C:\Program Files\GenesysPOC\ChromeExtension" --no-first-run'
$WorkingDir = "C:\Program Files\Google\Chrome\Application\"

# Get script directory for icon path
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$IconPath = Join-Path -Path $ScriptDir -ChildPath $IconFile

# Create required directories
if (-not (Test-Path -Path "C:\Temp\GenesysPOC\ChromeUserData")) {
    New-Item -Path "C:\Temp\GenesysPOC\ChromeUserData" -ItemType Directory -Force | Out-Null
}

# Prepare Windows folder for icon
$WindowsFolder = "$env:USERPROFILE\AppData\Local\Microsoft\Windows"
Copy-Item -Path $IconPath -Destination $WindowsFolder -Force

# Create the shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Desktop = [Environment]::GetFolderPath('Desktop')
$Shortcut = $WshShell.CreateShortcut("$Desktop\$Title.lnk")
$Shortcut.TargetPath = $Target
$Shortcut.Arguments = $Arguments
$Shortcut.WorkingDirectory = $WorkingDir
$Shortcut.IconLocation = "$WindowsFolder\$IconFile, 0"
$Shortcut.WindowStyle = 3
$Shortcut.Save()

# Verify the shortcut was created properly
try {
    $CreatedShortcut = $WshShell.CreateShortcut("$Desktop\$Title.lnk")
    Write-Host "Shortcut created with arguments:" -ForegroundColor Green
    Write-Host $CreatedShortcut.Arguments -ForegroundColor Cyan
    
    if ($CreatedShortcut.Arguments -notlike "*--no-first-run*") {
        Write-Host "Warning: --no-first-run parameter is missing!" -ForegroundColor Yellow
        
        # Try one more time with a different approach
        Write-Host "Attempting alternative method..." -ForegroundColor Yellow
        
        # Create a temporary script to create the shortcut
        $TempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
        
        @"
`$WshShell = New-Object -ComObject WScript.Shell
`$Desktop = [Environment]::GetFolderPath('Desktop')
`$Shortcut = `$WshShell.CreateShortcut("`$Desktop\$Title.lnk")
`$Shortcut.TargetPath = '$Target'
`$Shortcut.Arguments = '$Arguments'
`$Shortcut.WorkingDirectory = '$WorkingDir'
`$Shortcut.IconLocation = '$WindowsFolder\$IconFile, 0'
`$Shortcut.WindowStyle = 3
`$Shortcut.Save()
"@ | Out-File -FilePath $TempScript -Encoding UTF8
        
        # Run the temp script in a new PowerShell process
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$TempScript`"" -Wait -NoNewWindow
        
        # Clean up
        Remove-Item -Path $TempScript -Force
    }
} catch {
    Write-Host "Error verifying shortcut: $_" -ForegroundColor Red
}

Write-Host "Genesys Cloud DR shortcut creation completed." -ForegroundColor Green 