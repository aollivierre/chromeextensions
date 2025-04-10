#
# ChromeExtensionTest.ps1
# A focused script to ensure the Chrome extension for DR environment is working correctly
#

Write-Host "Genesys DR Environment - Chrome Extension Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check for existing DR shortcut
$drShortcutPath = "C:\Users\Public\Desktop\Genesys Cloud DR (Chrome).lnk"
if (-not (Test-Path $drShortcutPath)) {
    Write-Host "[ERROR] DR shortcut not found at $drShortcutPath" -ForegroundColor Red
    Write-Host "Please run the GenesysEnvDifferentiation_Chrome_Final.ps1 script first" -ForegroundColor Yellow
    exit 1
}

# Constants - match these with what's in the main script
$programFilesPath = "C:\Program Files\GenesysPOC"
$tempPath = "C:\Temp\GenesysPOC"
$extensionFolder = "$programFilesPath\ChromeExtension"
$userDataDir = "$tempPath\ChromeUserData"

# Step 1: Ensure extension folder exists and has correct content
Write-Host "STEP 1: Verifying extension setup..." -ForegroundColor Green

# Create directories if they don't exist
if (-not (Test-Path $extensionFolder)) {
    Write-Host "Creating extension folder: $extensionFolder" -ForegroundColor Yellow
    New-Item -Path $extensionFolder -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $userDataDir)) {
    Write-Host "Creating Chrome user data directory: $userDataDir" -ForegroundColor Yellow
    New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
}

# Create/update the manifest.json file
$manifestPath = "$extensionFolder\manifest.json"
$manifestJson = @{
    "manifest_version" = 3
    "name" = "Genesys DR Environment Indicator"
    "version" = "1.0"
    "description" = "Adds prominent visual cues to DR environments in Google Chrome"
    "content_scripts" = @(
        @{
            "matches" = @(
                "https://login.mypurecloud.com/*",
                "https://*.mypurecloud.com/*"
            )
            "css" = @("dr-style.css")
            "js" = @("dr-script.js")
            "all_frames" = $true
            "run_at" = "document_start"
        }
    )
    "permissions" = @("activeTab")
    "host_permissions" = @(
        "https://login.mypurecloud.com/*",
        "https://*.mypurecloud.com/*"
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path $manifestPath -Value $manifestJson -Force
Write-Host "Extension manifest created/updated at: $manifestPath" -ForegroundColor Green

# Create/update the CSS file - Make it more aggressive but with just one banner
$cssPath = "$extensionFolder\dr-style.css"
$cssContent = @"
/* Add a prominent red border/banner to the page */
body::before {
  content: "DR ENVIRONMENT";
  display: block !important;
  background-color: #ff0000 !important;
  color: white !important;
  text-align: center !important;
  padding: 4px !important;
  font-weight: bold !important;
  font-size: 12px !important;
  z-index: 2147483647 !important; /* Maximum z-index */
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  width: 100% !important;
  pointer-events: none !important;
  box-shadow: 0 0 5px rgba(255,0,0,0.5) !important;
  text-shadow: 1px 1px 1px black !important;
}
"@
Set-Content -Path $cssPath -Value $cssContent -Force
Write-Host "Extension CSS created/updated at: $cssPath" -ForegroundColor Green

# Create a JavaScript file to further ensure the banner appears
$jsPath = "$extensionFolder\dr-script.js"
$jsContent = @"
// This script adds a DR environment banner through JavaScript
// This works as a backup to the CSS method
(function() {
    function addDRBanner() {
        console.log('DR Environment Extension: Adding DR banner...');
        
        // Add top banner if it doesn't exist
        if (!document.getElementById('dr-environment-top-banner')) {
            const topBanner = document.createElement('div');
            topBanner.id = 'dr-environment-top-banner';
            topBanner.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; ' +
                'background-color: #ff0000; color: white; text-align: center; ' +
                'padding: 4px; font-size: 12px; font-weight: bold; z-index: 9999999; ' +
                'box-shadow: 0 0 5px rgba(255,0,0,0.5);';
            topBanner.innerText = 'DR ENVIRONMENT';
            document.body.appendChild(topBanner);
            console.log('DR Environment Extension: Top banner added');
        }
    }

    // Run immediately and also after load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addDRBanner);
    } else {
        addDRBanner();
    }
    
    console.log('DR Environment Extension loaded');
})();
"@
Set-Content -Path $jsPath -Value $jsContent -Force
Write-Host "Extension JavaScript created/updated at: $jsPath" -ForegroundColor Green

# Set proper permissions on extension folder to ensure Chrome can access it
Write-Host "Setting permissions on extension folder..." -ForegroundColor Yellow
$acl = Get-Acl $extensionFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionFolder $acl
Write-Host "Permissions set on extension folder" -ForegroundColor Green

# Step 2: Verify shortcut configuration
Write-Host "`nSTEP 2: Verifying shortcut configuration..." -ForegroundColor Green

$WshShell = New-Object -ComObject WScript.Shell
$drShortcut = $WshShell.CreateShortcut($drShortcutPath)

Write-Host "Current shortcut configuration:" -ForegroundColor Yellow
Write-Host "  Target path: $($drShortcut.TargetPath)" -ForegroundColor White
Write-Host "  Arguments: $($drShortcut.Arguments)" -ForegroundColor White
Write-Host "  Working directory: $($drShortcut.WorkingDirectory)" -ForegroundColor White

# Check if shortcut has the correct extension path
$hasCorrectExtension = $drShortcut.Arguments -match [regex]::Escape($extensionFolder)
$hasCorrectUserData = $drShortcut.Arguments -match [regex]::Escape($userDataDir)

if (-not $hasCorrectExtension -or -not $hasCorrectUserData) {
    Write-Host "`n[WARNING] Shortcut arguments may not have correct extension or user data paths" -ForegroundColor Yellow
    Write-Host "Updating shortcut with correct paths..." -ForegroundColor Yellow
    
    # Build Chrome arguments including our extension folder
    $chromeArgs = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=""$userDataDir"" --load-extension=""$extensionFolder"" --no-first-run"
    
    # Update and save the shortcut
    $drShortcut.Arguments = $chromeArgs
    $drShortcut.Save()
    
    Write-Host "Shortcut updated with correct paths" -ForegroundColor Green
    Write-Host "  New arguments: $chromeArgs" -ForegroundColor White
} else {
    Write-Host "`nShortcut appears to have correct extension and user data paths" -ForegroundColor Green
}

# Step 3: Close existing Chrome instances
Write-Host "`nSTEP 3: Closing existing Chrome instances..." -ForegroundColor Green
Get-Process chrome -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Closing Chrome process with ID: $($_.Id)" -ForegroundColor Yellow
    $_.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 1
    if (-not $_.HasExited) {
        Write-Host "  Force closing Chrome process with ID: $($_.Id)" -ForegroundColor Yellow
        $_.Kill()
    }
}
Start-Sleep -Seconds 2
Write-Host "Chrome processes closed" -ForegroundColor Green

# Step 4: Launch the DR shortcut
Write-Host "`nSTEP 4: Launching the DR shortcut..." -ForegroundColor Green
Start-Process -FilePath $drShortcutPath

# Step 5: Verify Chrome started with extension
Write-Host "`nSTEP 5: Verifying Chrome launched with extension..." -ForegroundColor Green

# Give Chrome time to start
Start-Sleep -Seconds 5

# Check Chrome processes
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if (-not $chromeProcesses) {
    Write-Host "[ERROR] Chrome did not start. Please launch manually: $drShortcutPath" -ForegroundColor Red
    exit 1
}

Write-Host "Chrome has been launched successfully with $($chromeProcesses.Count) processes" -ForegroundColor Green

# Try to verify extension loading
try {
    $wmiResult = Get-WmiObject Win32_Process -Filter "name = 'chrome.exe'" | 
        Select-Object ProcessId, CommandLine
    
    $extensionLoaded = $false
    
    Write-Host "`nChrome command lines:" -ForegroundColor Yellow
    foreach ($process in $wmiResult) {
        $cmdLine = $process.CommandLine
        # Sanitize for readability
        if ($cmdLine -ne $null) {
            $sanitizedCmdLine = $cmdLine -replace ([regex]::Escape($userDataDir)), "[USER_DATA_DIR]" `
                                        -replace ([regex]::Escape($extensionFolder)), "[EXTENSION_FOLDER]"
            Write-Host "  PID $($process.ProcessId): $sanitizedCmdLine" -ForegroundColor White
            
            # Check if this process has our extension
            if ($cmdLine -match "--load-extension" -and $cmdLine -match [regex]::Escape($extensionFolder)) {
                $extensionLoaded = $true
                Write-Host "  [OK] Process with ID $($process.ProcessId) includes the extension path" -ForegroundColor Green
            }
        }
    }
    
    if ($extensionLoaded) {
        Write-Host "`n[SUCCESS] Extension should be loaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Could not confirm extension is loaded in any Chrome process" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not verify Chrome command lines: $_" -ForegroundColor Red
}

# Final instructions with improved debugging steps
Write-Host "`nFINAL VERIFICATION" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "1. You should now see the Genesys DR login page with a RED 'DR ENVIRONMENT' banner at the top" -ForegroundColor Yellow
Write-Host "2. If the banner is not visible, you can check the extension settings:" -ForegroundColor Yellow
Write-Host "   - Type 'chrome://extensions/' in the address bar" -ForegroundColor Yellow
Write-Host "   - Look for 'Genesys DR Environment Indicator' extension" -ForegroundColor Yellow
Write-Host "   - Ensure it is enabled" -ForegroundColor Yellow
Write-Host "   - Try reloading the page (press F5)" -ForegroundColor Yellow

Write-Host "`nThe DR environment is configured at: https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr" -ForegroundColor Green
Write-Host "Try visiting this URL directly in the Chrome window if the page doesn't load automatically" -ForegroundColor Yellow
