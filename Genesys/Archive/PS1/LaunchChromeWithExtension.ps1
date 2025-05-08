#
# LaunchChromeWithExtension.ps1
# Launches Chrome with the Genesys DR Environment extension loaded directly
#

# Extension path from the successful manual load
$extensionPath = "C:\temp\GenesysPOC\ChromeExtension"

# Find Chrome executable in standard locations
$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
)

$chromePath = $null
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $chromePath = $path
        break
    }
}

# If Chrome wasn't found in the standard locations, try using chrome.exe from PATH
if (-not $chromePath) {
    try {
        $chromePath = (Get-Command chrome.exe -ErrorAction SilentlyContinue).Source
    } catch {
        Write-Host "ERROR: Could not find Chrome executable." -ForegroundColor Red
        Write-Host "Please specify the full path to chrome.exe in this script." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Launching Chrome with extension from: $extensionPath" -ForegroundColor Cyan

# Close any existing Chrome instances to ensure a clean start
Get-Process -Name chrome -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Closing Chrome process (PID: $($_.Id))..." -ForegroundColor Yellow
    $_.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 1
    if (-not $_.HasExited) {
        $_ | Stop-Process -Force
    }
}

# Wait a moment to ensure Chrome is fully closed
Start-Sleep -Seconds 2

# Launch Chrome with the extension loaded
# We'll also navigate to a URL that the extension affects
$chromeArgs = @(
    "--load-extension=""$extensionPath""",
    "https://www.google.com"
)

Write-Host "Starting Chrome with command: $chromePath $($chromeArgs -join ' ')" -ForegroundColor Green
Start-Process -FilePath $chromePath -ArgumentList $chromeArgs

# Create a shortcut in the Startup folder to auto-launch Chrome with this extension on login
Write-Host "`nWould you like to add this to your Windows startup to load automatically on login? (Y/N)" -ForegroundColor Yellow
$createStartup = Read-Host
if ($createStartup -eq "Y" -or $createStartup -eq "y") {
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $shortcutPath = "$startupFolder\ChromeWithDRExtension.lnk"
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $chromePath
    $shortcut.Arguments = "--load-extension=""$extensionPath"" https://www.google.com"
    $shortcut.Description = "Launch Chrome with Genesys DR Environment Extension"
    $shortcut.WorkingDirectory = Split-Path $chromePath -Parent
    $shortcut.Save()
    
    Write-Host "Startup shortcut created at: $shortcutPath" -ForegroundColor Green
    Write-Host "Chrome will now launch with this extension automatically on login." -ForegroundColor Green
}

Write-Host "`nDone! Chrome has been launched with the extension loaded." -ForegroundColor Cyan
Write-Host "Note: This extension will only be active in this Chrome session." -ForegroundColor Yellow
Write-Host "To make it permanent, either:" -ForegroundColor Yellow
Write-Host "1. Add the startup shortcut as offered above" -ForegroundColor Yellow
Write-Host "2. Manually enable Developer Mode in chrome://extensions and use 'Load unpacked'" -ForegroundColor Yellow

# Open Chrome's extensions page to verify the extension is loaded
Start-Sleep -Seconds 5
Start-Process -FilePath $chromePath -ArgumentList "--new-window chrome://extensions/" 