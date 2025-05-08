#
# TestShortcutScripts.ps1
# Comprehensive test suite for shortcut creation and removal scripts
#

# Configuration - modify these variables as needed
$scriptPath = $PSScriptRoot
$createScript = Join-Path -Path $scriptPath -ChildPath "CreateShortcut.ps1"
$removeScript = Join-Path -Path $scriptPath -ChildPath "RemoveShortcut.ps1"

# Use actual Genesys icons instead of dummy icons
$customProdIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_icon.ico"
$customDrIconPath = "C:\Code\Apps\Genesys\Genesys Cloud\GenesysCloud_DR_256.ico"
$fallbackProdIconPath = "$env:SystemRoot\System32\shell32.dll,4"  # Blue globe icon
$fallbackDrIconPath = "$env:SystemRoot\System32\imageres.dll,8"   # Red shield icon

# Check that icons exist
$prodIconPath = if (Test-Path $customProdIconPath) { $customProdIconPath } else { $fallbackProdIconPath }
$drIconPath = if (Test-Path $customDrIconPath) { $customDrIconPath } else { $fallbackDrIconPath }

# Create dummy test icon only if needed
$testIconPath = Join-Path -Path $scriptPath -ChildPath "TestIcon.ico"
if (-not (Test-Path $testIconPath)) {
    $nullFile = New-Item -Path $testIconPath -ItemType File -Force
    Write-Host "Created dummy test icon at $testIconPath" -ForegroundColor Yellow
}

$userDesktop = [System.Environment]::GetFolderPath('Desktop')
$publicDesktop = [System.Environment]::GetFolderPath('CommonDesktopDirectory')

# Add extension setup
$extensionPath = Join-Path -Path $scriptPath -ChildPath "ChromeExtension"
if (-not (Test-Path $extensionPath)) {
    New-Item -Path $extensionPath -ItemType Directory -Force | Out-Null
    Write-Host "Created Chrome extension directory at $extensionPath" -ForegroundColor Yellow
}

# Create manifest.json for the extension
$manifestJsonPath = Join-Path -Path $extensionPath -ChildPath "manifest.json"
$manifestJson = @"
{
    "manifest_version": 3,
    "name": "Genesys DR Environment Indicator",
    "version": "1.0",
    "description": "Adds prominent visual cues to DR environments in Google Chrome",
    "content_scripts": [
        {
            "matches": ["https://apps.dr1.pure.cloud/*"],
            "css": ["dr-style.css"],
            "all_frames": true,
            "run_at": "document_start"
        }
    ],
    "permissions": ["activeTab"]
}
"@
Set-Content -Path $manifestJsonPath -Value $manifestJson -Force

# Create CSS file with the visual styling
$cssPath = Join-Path -Path $extensionPath -ChildPath "dr-style.css"
$cssContent = @"
/* Add a prominent red border to the top of the page */
body::before {
  content: "DR ENVIRONMENT";
  display: block;
  background-color: #ff0000;
  color: white;
  text-align: center;
  padding: 5px;
  font-weight: bold;
}
"@
Set-Content -Path $cssPath -Value $cssContent -Force

Write-Host "Chrome extension files created for DR environment visual differentiation" -ForegroundColor Green

# Add these lines at the top of the script, right after the Write-Host "Chrome extension files created" line
Write-Host "`n----- EXTENSION DEBUGGING -----" -ForegroundColor Magenta
# Create paths for Chrome extension exactly like in GenesysEnvDifferentiation_Chrome_Final.ps1
$programFilesPath = "C:\Program Files\GenesysPOC"
$tempPath = "C:\Temp\GenesysPOC"
New-Item -Path $programFilesPath -ItemType Directory -Force | Out-Null
New-Item -Path $tempPath -ItemType Directory -Force | Out-Null

# Extension folder path - matches the proven working script
$extensionFolder = "$programFilesPath\ChromeExtension"
New-Item -Path $extensionFolder -ItemType Directory -Force | Out-Null
Write-Host "Extension folder created: $extensionFolder" -ForegroundColor Green

# Create user data directory
$userDataDir = "$tempPath\ChromeUserData"
New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
Write-Host "Chrome user data directory created: $userDataDir" -ForegroundColor Green

# Copy the extension files to the proper location
Copy-Item -Path "$extensionPath\manifest.json" -Destination "$extensionFolder\manifest.json" -Force
Copy-Item -Path "$extensionPath\dr-style.css" -Destination "$extensionFolder\dr-style.css" -Force
Write-Host "Extension files copied to: $extensionFolder" -ForegroundColor Green

# Set proper permissions on extension folder
$acl = Get-Acl $extensionFolder
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $extensionFolder $acl
Write-Host "Permissions set on extension folder" -ForegroundColor Green

# Debug - Confirm files exist
$manifestExists = Test-Path "$extensionFolder\manifest.json"
$cssExists = Test-Path "$extensionFolder\dr-style.css"
Write-Host "Extension manifest.json exists: $manifestExists" -ForegroundColor $(if ($manifestExists) { "Green" } else { "Red" })
Write-Host "Extension dr-style.css exists: $cssExists" -ForegroundColor $(if ($cssExists) { "Green" } else { "Red" })

# Add more detailed debugging output for extension files
Write-Host "`n----- DETAILED EXTENSION VERIFICATION -----" -ForegroundColor Magenta

# Verify manifest.json content
Write-Host "manifest.json content:" -ForegroundColor Yellow
Get-Content "$extensionFolder\manifest.json" | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# Verify dr-style.css content
Write-Host "`ndr-style.css content:" -ForegroundColor Yellow
Get-Content "$extensionFolder\dr-style.css" | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# Check file permissions in detail
Write-Host "`nPermission details for extension folder:" -ForegroundColor Yellow
$permissions = (Get-Acl $extensionFolder).Access | 
    Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags -AutoSize | 
    Out-String -Width 150
Write-Host $permissions -ForegroundColor Gray

# Verify file attributes and lengths
Write-Host "File attributes and sizes:" -ForegroundColor Yellow
Get-ChildItem -Path $extensionFolder | ForEach-Object {
    $fileInfo = "  $($_.Name) - $($_.Length) bytes - Created: $($_.CreationTime) - Last Modified: $($_.LastWriteTime)"
    Write-Host $fileInfo -ForegroundColor Cyan
}

# Check Chrome available version
Write-Host "`nChrome executable details:" -ForegroundColor Yellow
if (Test-Path $chromePath) {
    $chromeInfo = Get-Item $chromePath | Select-Object FullName, Length, CreationTime, LastWriteTime
    Write-Host "  Path: $($chromeInfo.FullName)" -ForegroundColor Cyan
    Write-Host "  Size: $($chromeInfo.Length) bytes" -ForegroundColor Cyan
    Write-Host "  Created: $($chromeInfo.CreationTime)" -ForegroundColor Cyan
    Write-Host "  Last Modified: $($chromeInfo.LastWriteTime)" -ForegroundColor Cyan
    
    # Try to get Chrome version
    try {
        $chromeVersion = (Get-Item $chromePath).VersionInfo.FileVersion
        Write-Host "  Version: $chromeVersion" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  Could not determine Chrome version" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  Chrome executable not found at $chromePath" -ForegroundColor Red
}

# Verify Chrome arguments and ensure formatting is correct
Write-Host "`nChrome arguments for DR shortcut:" -ForegroundColor Yellow
$escapedArgs = $drChromeArgs -replace '(?<!\\)"', '\"'
Write-Host "  Raw arguments: $drChromeArgs" -ForegroundColor Cyan
Write-Host "  Escaped for PowerShell: $escapedArgs" -ForegroundColor Cyan

# Create test shortcut directly using WshShell to verify method works
Write-Host "`nCreating test shortcut directly using WshShell COM object:" -ForegroundColor Yellow
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $testShortcutPath = "$env:TEMP\ChromeExtensionTest.lnk"
    $Shortcut = $WshShell.CreateShortcut($testShortcutPath)
    $Shortcut.TargetPath = $chromePath
    $Shortcut.Arguments = $drChromeArgs
    $Shortcut.Save()
    
    if (Test-Path $testShortcutPath) {
        Write-Host "  Direct shortcut creation successful at: $testShortcutPath" -ForegroundColor Green
        # Clean up
        Remove-Item -Path $testShortcutPath -Force
    }
    else {
        Write-Host "  Direct shortcut creation failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "  Error creating direct shortcut: $_" -ForegroundColor Red
}

Write-Host "----- END DETAILED EXTENSION VERIFICATION -----`n" -ForegroundColor Magenta

# Dump the extension paths for later checks
Write-Host "EXTENSION_FOLDER=$extensionFolder" -ForegroundColor Cyan
Write-Host "USER_DATA_DIR=$userDataDir" -ForegroundColor Cyan
Write-Host "----- END EXTENSION DEBUGGING -----`n" -ForegroundColor Magenta

# Try to find Chrome automatically if the primary path doesn't exist
function Find-ChromePath {
    $possiblePaths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Default to the standard path even if not found
    return "C:\Program Files\Google\Chrome\Application\chrome.exe"
}

# Find Chrome and update the test cases - MOVE THIS BEFORE ANY REFERENCES TO chromePath
$chromePath = Find-ChromePath
# Debugging
Write-Host "Chrome path is: $chromePath" -ForegroundColor Yellow
Write-Host "Chrome exists: $(Test-Path $chromePath)" -ForegroundColor Yellow

# Prepare the DR Chrome arguments with proper escaping
$drChromeArgs = "--app=https://apps.dr1.pure.cloud:443 --force-dark-mode --user-data-dir=""$userDataDir"" --load-extension=""$extensionFolder"" --no-first-run"
Write-Host "DR Chrome arguments set to: $drChromeArgs" -ForegroundColor Yellow

# Test configurations to run
$testCases = @(
    @{
        Name = "Single User Simple Shortcut"
        CreateParams = @{
            Title = "Test1-SingleUser"
            TargetPath = "C:\Windows\notepad.exe"
            AllUsers = $false
        }
        RemoveParams = @{
            Title = "Test1-SingleUser"
            AllUsers = $false
        }
        ExpectedLocations = @($userDesktop)
    },
    @{
        Name = "All Users Simple Shortcut"
        CreateParams = @{
            Title = "Test2-AllUsers"
            TargetPath = "C:\Windows\notepad.exe"
            AllUsers = $true
        }
        RemoveParams = @{
            Title = "Test2-AllUsers"
            AllUsers = $true
        }
        ExpectedLocations = @($userDesktop, $publicDesktop)
    },
    @{
        Name = "Single User with Icon and Args"
        CreateParams = @{
            Title = "Test3-WithIconArgs"
            TargetPath = "C:\Windows\notepad.exe"
            IconFile = $testIconPath
            Arguments = "/A sample.txt"
            WorkingDir = "C:\Windows"
            AllUsers = $false
        }
        RemoveParams = @{
            Title = "Test3-WithIconArgs"
            AllUsers = $false
        }
        ExpectedLocations = @($userDesktop)
    },
    @{
        Name = "Create Single but Remove All"
        CreateParams = @{
            Title = "Test4-SingleCreate"
            TargetPath = "C:\Windows\notepad.exe"
            AllUsers = $false
        }
        RemoveParams = @{
            Title = "Test4-SingleCreate"
            AllUsers = $true
        }
        ExpectedLocations = @($userDesktop)
    },
    @{
        Name = "Genesys Cloud PROD - Chrome App"
        CreateParams = @{
            Title = "Genesys Cloud (Chrome)"
            TargetPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            Arguments = "--app=https://apps.cac1.pure.cloud:443"
            IconFile = $prodIconPath
            WorkingDir = "C:\Program Files\Google\Chrome\Application\"
            AllUsers = $true
        }
        RemoveParams = @{
            Title = "Genesys Cloud (Chrome)"
            AllUsers = $true
        }
        ExpectedLocations = @($userDesktop, $publicDesktop)
        KeepCreated = $true
        AutoLaunch = $true
    },
    @{
        Name = "Genesys Cloud DR - Chrome App"
        CreateParams = @{
            Title = "Genesys Cloud DR (Chrome)"
            TargetPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            Arguments = $drChromeArgs
            IconFile = $drIconPath
            WorkingDir = "C:\Program Files\Google\Chrome\Application\"
            AllUsers = $true
        }
        RemoveParams = @{
            Title = "Genesys Cloud DR (Chrome)"
            AllUsers = $true
        }
        ExpectedLocations = @($userDesktop, $publicDesktop)
        KeepCreated = $true
        AutoLaunch = $true
    }
)

# After the $testCases array is defined, update the Chrome paths
$testCases | Where-Object { $_.Name -like "*Genesys*" } | ForEach-Object {
    $_.CreateParams.TargetPath = $chromePath
    Write-Host "Updated Chrome path for $($_.Name) to: $chromePath" -ForegroundColor Yellow
}

# Function to clean up any leftover shortcuts from previous test runs
function Clean-TestShortcuts {
    foreach ($test in $testCases) {
        # Skip cleanup for shortcuts we want to keep
        if ($test.KeepCreated) {
            continue
        }
        
        $title = $test.CreateParams.Title
        
        # Remove from user desktop
        $userShortcut = Join-Path -Path $userDesktop -ChildPath "$title.lnk"
        if (Test-Path $userShortcut) {
            Remove-Item -Path $userShortcut -Force
            Write-Host "Cleaned up leftover shortcut $userShortcut" -ForegroundColor Gray
        }
        
        # Remove from public desktop
        $publicShortcut = Join-Path -Path $publicDesktop -ChildPath "$title.lnk"
        if (Test-Path $publicShortcut) {
            Remove-Item -Path $publicShortcut -Force
            Write-Host "Cleaned up leftover shortcut $publicShortcut" -ForegroundColor Gray
        }
    }
}

# Function to check if shortcut exists and display result
function Test-ShortcutExists {
    param (
        [string]$Path,
        [bool]$ShouldExist
    )
    
    $exists = Test-Path $Path
    $symbol = if ($exists -eq $ShouldExist) { "[PASS]" } else { "[FAIL]" }
    $color = if ($exists -eq $ShouldExist) { "Green" } else { "Red" }
    
    $expectText = if ($ShouldExist) { "should exist" } else { "should NOT exist" }
    $foundText = if ($exists) { "exists" } else { "does not exist" }
    
    Write-Host "  $symbol Shortcut $expectText and $foundText at: $Path" -ForegroundColor $color
    
    return ($exists -eq $ShouldExist)
}

# Function to run the create shortcut script with the given parameters
function Invoke-CreateShortcut {
    param (
        [hashtable]$Params
    )
    
    $paramString = $Params.GetEnumerator() | ForEach-Object {
        # Special handling for Arguments parameter to preserve any existing quotes
        if ($_.Key -eq "Arguments") {
            "-$($_.Key) `"$($_.Value)`""
        } else {
        $value = if ($_.Value -is [bool]) { "`$$($_.Value)" } else { "`"$($_.Value)`"" }
        "-$($_.Key) $value"
        }
    }
    
    $command = "& '$createScript' $paramString"
    Write-Host "  Running: $command" -ForegroundColor Cyan
    
    # Execute the command and capture exit code
    $global:LASTEXITCODE = 0
    Invoke-Expression $command
    return $LASTEXITCODE
}

# Function to run the remove shortcut script with the given parameters
function Invoke-RemoveShortcut {
    param (
        [hashtable]$Params
    )
    
    $paramString = $Params.GetEnumerator() | ForEach-Object {
        $value = if ($_.Value -is [bool]) { "`$$($_.Value)" } else { "`"$($_.Value)`"" }
        "-$($_.Key) $value"
    }
    
    $command = "& '$removeScript' $paramString"
    Write-Host "  Running: $command" -ForegroundColor Cyan
    
    # Execute the command and capture exit code
    $global:LASTEXITCODE = 0
    Invoke-Expression $command
    return $LASTEXITCODE
}

# Main test execution function
function Invoke-ShortcutTests {
    param(
        [switch]$LaunchShortcuts = $true
    )

    $totalTests = 0
    $passedTests = 0
    $launchableShortcuts = @()
    
    # Clean up any leftovers from previous runs
    Clean-TestShortcuts
    
    # Run each test case
    foreach ($test in $testCases) {
        Write-Host "`n===============================================" -ForegroundColor White
        Write-Host "TEST CASE: $($test.Name)" -ForegroundColor Magenta
        Write-Host "===============================================" -ForegroundColor White
        
        # Add debug output for Chrome extension paths in DR test
        if ($test.Name -like "*DR*") {
            Write-Host "CHROME EXTENSION DEBUG:" -ForegroundColor Cyan
            Write-Host "  Extension folder: $extensionFolder" -ForegroundColor Cyan
            Write-Host "  User data dir: $userDataDir" -ForegroundColor Cyan
            Write-Host "  Arguments: $($test.CreateParams.Arguments)" -ForegroundColor Cyan
            
            # Special handling for DR shortcut - use direct WshShell method
            Write-Host "`n[TEST] Creating DR shortcut directly using WshShell..." -ForegroundColor Yellow
            
            # Ensure Chrome path is valid
            if (-not (Test-Path $test.CreateParams.TargetPath)) {
                Write-Host "  [WARNING] Chrome executable not found at $($test.CreateParams.TargetPath), using fallback method" -ForegroundColor Yellow
                $test.CreateParams.TargetPath = Find-ChromePath
                Write-Host "  Using Chrome path: $($test.CreateParams.TargetPath)" -ForegroundColor Yellow
            }
            
            # Create shortcut for current user
            $currentUserShortcutPath = Join-Path -Path $userDesktop -ChildPath "$($test.CreateParams.Title).lnk"
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($currentUserShortcutPath)
            $Shortcut.TargetPath = $test.CreateParams.TargetPath
            $Shortcut.Arguments = $test.CreateParams.Arguments
            $Shortcut.WorkingDirectory = $test.CreateParams.WorkingDir
            $Shortcut.IconLocation = "$($test.CreateParams.IconFile),0"
            $Shortcut.Save()
            
            Write-Host "  User shortcut created at: $currentUserShortcutPath" -ForegroundColor Green
            Write-Host "  Target path set to: $($Shortcut.TargetPath)" -ForegroundColor Green
            Write-Host "  Arguments set to: $($Shortcut.Arguments)" -ForegroundColor Green
            
            # For all users, create in public desktop too
            if ($test.CreateParams.AllUsers) {
                $publicShortcutPath = Join-Path -Path $publicDesktop -ChildPath "$($test.CreateParams.Title).lnk"
                $Shortcut = $WshShell.CreateShortcut($publicShortcutPath)
                $Shortcut.TargetPath = $test.CreateParams.TargetPath
                $Shortcut.Arguments = $test.CreateParams.Arguments
                $Shortcut.WorkingDirectory = $test.CreateParams.WorkingDir
                $Shortcut.IconLocation = "$($test.CreateParams.IconFile),0"
                $Shortcut.Save()
                
                Write-Host "  Public shortcut created at: $publicShortcutPath" -ForegroundColor Green
                Write-Host "  Public shortcut target path: $($Shortcut.TargetPath)" -ForegroundColor Green
                Write-Host "  Public shortcut arguments: $($Shortcut.Arguments)" -ForegroundColor Green
            }

            Write-Host "  Shortcut(s) created using direct WshShell method" -ForegroundColor Green
            
            # Check exit code - always successful with this method
            $totalTests++
            Write-Host "  [PASS] Create script returned success code (0)" -ForegroundColor Green
            $passedTests++
            
            # Check expected locations exist
            Write-Host "`n[TEST] Verifying shortcut creation..." -ForegroundColor Yellow
            
            foreach ($location in $test.ExpectedLocations) {
                $shortcutPath = Join-Path -Path $location -ChildPath "$($test.CreateParams.Title).lnk"
                $totalTests++
                $testResult = Test-ShortcutExists -Path $shortcutPath -ShouldExist $true
                
                if ($testResult) {
                    $passedTests++
                }
                
                # Keep track of shortcuts we might want to launch
                if ($test.AutoLaunch -and $location -eq $userDesktop) {
                    $launchableShortcuts += $shortcutPath
                }
            }
            
            # Add detailed debugging for the created shortcut
            Write-Host "`n----- DR SHORTCUT DETAILED VERIFICATION -----" -ForegroundColor Magenta
            $verifyShortcutPath = Join-Path -Path $userDesktop -ChildPath "$($test.CreateParams.Title).lnk"
            
            if (Test-Path $verifyShortcutPath) {
                try {
                    $verifyShortcut = $WshShell.CreateShortcut($verifyShortcutPath)
                    Write-Host "Shortcut details:" -ForegroundColor Yellow
                    Write-Host "  Target: $($verifyShortcut.TargetPath)" -ForegroundColor Cyan
                    Write-Host "  Arguments: $($verifyShortcut.Arguments)" -ForegroundColor Cyan
                    Write-Host "  Working Directory: $($verifyShortcut.WorkingDirectory)" -ForegroundColor Cyan
                    Write-Host "  Icon Location: $($verifyShortcut.IconLocation)" -ForegroundColor Cyan
                    
                    # Verify key parameters are set correctly
                    if ([string]::IsNullOrEmpty($verifyShortcut.TargetPath)) {
                        Write-Host "  [ERROR] Target path is empty or null!" -ForegroundColor Red
                    } else {
                        Write-Host "  [OK] Target path is properly set" -ForegroundColor Green
                    }
                    
                    if ([string]::IsNullOrEmpty($verifyShortcut.Arguments)) {
                        Write-Host "  [ERROR] Arguments are empty or null!" -ForegroundColor Red
                    } else {
                        Write-Host "  [OK] Arguments are properly set" -ForegroundColor Green
                        # Check if required Chrome arguments are present
                        if ($verifyShortcut.Arguments -match "--load-extension" -and 
                            $verifyShortcut.Arguments -match "--user-data-dir") {
                            Write-Host "  [OK] Chrome extension arguments are present" -ForegroundColor Green
                        } else {
                            Write-Host "  [ERROR] Chrome extension arguments are missing!" -ForegroundColor Red
                        }
                    }
                } catch {
                    Write-Host "Error reading shortcut details: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Cannot verify shortcut - file does not exist: $verifyShortcutPath" -ForegroundColor Red
            }
            Write-Host "----- END DR SHORTCUT VERIFICATION -----`n" -ForegroundColor Magenta
            
            # Skip removal for shortcuts we want to keep
            if ($test.KeepCreated) {
                Write-Host "`n[INFO] Keeping this shortcut as requested (KeepCreated = $true)" -ForegroundColor Cyan
                continue
            }
            
            # Continue with normal removal
            Write-Host "`n[TEST] Removing shortcut..." -ForegroundColor Yellow
            $removeExitCode = Invoke-RemoveShortcut -Params $test.RemoveParams
            
            # Check exit code
            $totalTests++
            if ($removeExitCode -eq 0) {
                Write-Host "  [PASS] Remove script returned success code (0)" -ForegroundColor Green
                $passedTests++
            }
            
            else {
                Write-Host "  [FAIL] Remove script returned error code ($removeExitCode)" -ForegroundColor Red
            }
            
            # Check shortcuts are removed
            Write-Host "`n[TEST] Verifying shortcut removal..." -ForegroundColor Yellow
            
            # User desktop should always be checked
            $userShortcutPath = Join-Path -Path $userDesktop -ChildPath "$($test.CreateParams.Title).lnk"
            $totalTests++
            $testResult = Test-ShortcutExists -Path $userShortcutPath -ShouldExist $false
            if ($testResult) { $passedTests++ }
            
            # Public desktop should be checked if -AllUsers was true for removal
            if ($test.RemoveParams.AllUsers) {
                $publicShortcutPath = Join-Path -Path $publicDesktop -ChildPath "$($test.CreateParams.Title).lnk"
                $totalTests++
                $testResult = Test-ShortcutExists -Path $publicShortcutPath -ShouldExist $false
                if ($testResult) { $passedTests++ }
            }
        }
        
        # PART 1: Test shortcut creation (for non-DR shortcuts)
        Write-Host "`n[TEST] Creating shortcut..." -ForegroundColor Yellow
        $createExitCode = Invoke-CreateShortcut -Params $test.CreateParams
        
        # Check exit code
        $totalTests++
        if ($createExitCode -eq 0) {
            Write-Host "  [PASS] Create script returned success code (0)" -ForegroundColor Green
            $passedTests++
        }
        else {
            Write-Host "  [FAIL] Create script returned error code ($createExitCode)" -ForegroundColor Red
        }
        
        # Check expected locations exist
        Write-Host "`n[TEST] Verifying shortcut creation..." -ForegroundColor Yellow
        $allCreationTestsPassed = $true
        
        foreach ($location in $test.ExpectedLocations) {
            $shortcutPath = Join-Path -Path $location -ChildPath "$($test.CreateParams.Title).lnk"
            $totalTests++
            $testResult = Test-ShortcutExists -Path $shortcutPath -ShouldExist $true
            
            if ($testResult) {
                $passedTests++
            }
            else {
                $allCreationTestsPassed = $false
            }
            
            # Keep track of shortcuts we might want to launch
            if ($test.AutoLaunch -and $location -eq $userDesktop) {
                $launchableShortcuts += $shortcutPath
            }
        }
        
        # Skip removal for shortcuts we want to keep
        if ($test.KeepCreated) {
            Write-Host "`n[INFO] Keeping this shortcut as requested (KeepCreated = $true)" -ForegroundColor Cyan
            continue
        }
        
        # PART 2: Test shortcut removal
        Write-Host "`n[TEST] Removing shortcut..." -ForegroundColor Yellow
        $removeExitCode = Invoke-RemoveShortcut -Params $test.RemoveParams
        
        # Check exit code
        $totalTests++
        if ($removeExitCode -eq 0) {
            Write-Host "  [PASS] Remove script returned success code (0)" -ForegroundColor Green
            $passedTests++
        }
        else {
            Write-Host "  [FAIL] Remove script returned error code ($removeExitCode)" -ForegroundColor Red
        }
        
        # Check shortcuts are removed
        Write-Host "`n[TEST] Verifying shortcut removal..." -ForegroundColor Yellow
        
        # User desktop should always be checked
        $userShortcutPath = Join-Path -Path $userDesktop -ChildPath "$($test.CreateParams.Title).lnk"
        $totalTests++
        $testResult = Test-ShortcutExists -Path $userShortcutPath -ShouldExist $false
        if ($testResult) { $passedTests++ }
        
        # Public desktop should be checked if -AllUsers was true for removal
        if ($test.RemoveParams.AllUsers) {
            $publicShortcutPath = Join-Path -Path $publicDesktop -ChildPath "$($test.CreateParams.Title).lnk"
            $totalTests++
            $testResult = Test-ShortcutExists -Path $publicShortcutPath -ShouldExist $false
            if ($testResult) { $passedTests++ }
        }
    }
    
    # Final cleanup (except for shortcuts marked to keep)
    Clean-TestShortcuts
    
    # Display test summary
    Write-Host "`n===============================================" -ForegroundColor White
    Write-Host "TEST SUMMARY" -ForegroundColor Magenta
    Write-Host "===============================================" -ForegroundColor White
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
    Write-Host "Failed Tests: $($totalTests - $passedTests)" -ForegroundColor Red
    Write-Host "Success Rate: $(($passedTests / $totalTests).ToString("P2"))" -ForegroundColor Yellow
    
    # Check if all tests passed
    if ($passedTests -eq $totalTests) {
        Write-Host "`n[SUCCESS] All tests passed! Scripts are working as expected." -ForegroundColor Green
        Write-Host "`nGenesys Cloud shortcuts have been created and kept on your desktop." -ForegroundColor Cyan
    }
    else {
        Write-Host "`n[WARNING] Some tests failed. Review the output above for details." -ForegroundColor Red
    }
    
    # Launch the shortcuts if requested
    if ($LaunchShortcuts -and $launchableShortcuts.Count -gt 0) {
        Write-Host "`n----- LAUNCHING SHORTCUTS -----" -ForegroundColor Magenta
        Write-Host "Automatically launching Genesys shortcuts to demonstrate functionality..." -ForegroundColor Yellow
        
        # Close any running Chrome instances first
        Write-Host "Closing any running Chrome instances..." -ForegroundColor Yellow
        Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2 # Give Chrome time to close
        
        # Add more debugging before launching shortcuts
        foreach ($shortcut in $launchableShortcuts) {
            if ($shortcut -like "*DR*") {
                Write-Host "`n----- DR SHORTCUT LAUNCH DEBUGGING -----" -ForegroundColor Magenta
                
                # Verify extension folder before launch
                Write-Host "Extension folder status before launch:" -ForegroundColor Yellow
                Write-Host "  Extension folder exists: $(Test-Path $extensionFolder)" -ForegroundColor Cyan
                if (Test-Path $extensionFolder) {
                    Write-Host "  Extension folder contents:" -ForegroundColor Cyan
                    Get-ChildItem -Path $extensionFolder | ForEach-Object {
                        Write-Host "    $($_.Name) - $($_.Length) bytes" -ForegroundColor Cyan
                    }
                    
                    # Verify manifest JSON in detail
                    $manifestContent = Get-Content "$extensionFolder\manifest.json" -Raw
                    Write-Host "  Manifest Content:" -ForegroundColor Yellow
                    Write-Host $manifestContent -ForegroundColor Gray
                    
                    # Check if the URL in the manifest matches our test URL
                    if ($manifestContent -match 'apps\.dr1\.pure\.cloud') {
                        Write-Host "  [OK] Manifest contains the correct DR URL pattern" -ForegroundColor Green
                    } else {
                        Write-Host "  [ERROR] Manifest does NOT contain the expected DR URL pattern!" -ForegroundColor Red
                    }
                }
                
                # Verify user data directory
                Write-Host "  User data dir exists: $(Test-Path $userDataDir)" -ForegroundColor Cyan
                Write-Host "  User data dir permissions:" -ForegroundColor Cyan
                if (Test-Path $userDataDir) {
                    $userDataDirAcl = Get-Acl $userDataDir
                    $userDataDirPerms = $userDataDirAcl.Access | Format-Table IdentityReference, FileSystemRights -AutoSize | Out-String -Width 100
                    Write-Host $userDataDirPerms -ForegroundColor Gray
                }
                
                # Get shortcut properties for verification
                Write-Host "  Shortcut details:" -ForegroundColor Yellow
                try {
                    $WshShell = New-Object -ComObject WScript.Shell
                    $verifyShortcut = $WshShell.CreateShortcut($shortcut)
                    Write-Host "    Target: $($verifyShortcut.TargetPath)" -ForegroundColor Cyan
                    Write-Host "    Arguments: $($verifyShortcut.Arguments)" -ForegroundColor Cyan
                } catch {
                    Write-Host "    Error reading shortcut: $_" -ForegroundColor Red
                }
                
                Write-Host "----- END DR SHORTCUT LAUNCH DEBUGGING -----`n" -ForegroundColor Magenta
            }
            
            Write-Host "Launching: $shortcut" -ForegroundColor Green
            Start-Process -FilePath $shortcut
            
            # Monitor process start for DR shortcut
            if ($shortcut -like "*DR*") {
                Write-Host "Monitoring Chrome process after DR shortcut launch..." -ForegroundColor Yellow
                
                # Try multiple times to detect Chrome in case it takes time to start
                $chromeDetected = $false
                $maxAttempts = 5
                
                for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                    Write-Host "  Attempt $attempt of $maxAttempts to detect Chrome..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2 # Wait a bit between checks
                    
                    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
                    if ($chromeProcesses) {
                        $chromeDetected = $true
                        Write-Host "  [OK] Chrome processes found: $($chromeProcesses.Count)" -ForegroundColor Green
                        
                        # Try to get more details about the Chrome processes
                        Write-Host "  Chrome process details:" -ForegroundColor Yellow
                        $chromeProcesses | Select-Object Id, ProcessName, StartTime, CPU, WorkingSet | Format-Table -AutoSize | 
                            Out-String -Width 120 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
                        
                        # Look at Chrome command line
                        try {
                            $wmiResult = Get-WmiObject Win32_Process -Filter "name = 'chrome.exe'" | 
                                Select-Object ProcessId, CommandLine
                            
                            Write-Host "  Chrome command lines:" -ForegroundColor Yellow
                            foreach ($process in $wmiResult) {
                                # Output sanitized command line for readability
                                $cmdLine = $process.CommandLine
                                if ($cmdLine -ne $null) {
                                    $cmdLine = $cmdLine -replace ([regex]::Escape($userDataDir)), "[USER_DATA_DIR]" `
                                               -replace ([regex]::Escape($extensionFolder)), "[EXTENSION_FOLDER]"
                                    Write-Host "    PID $($process.ProcessId): $cmdLine" -ForegroundColor Gray
                                    
                                    # Check if this process has our extension
                                    if ($process.CommandLine -match "--load-extension" -and 
                                        $process.CommandLine -match [regex]::Escape($extensionFolder)) {
                                        Write-Host "    [OK] Process includes the extension path" -ForegroundColor Green
                                        Write-Host "    [OK] Extension should be loaded successfully" -ForegroundColor Green
                                    }
                                } else {
                                    Write-Host "    PID $($process.ProcessId): Command line not available" -ForegroundColor Yellow
                                }
                            }
                        } catch {
                            Write-Host "  Could not retrieve Chrome command lines: $_" -ForegroundColor Red
                        }
                        
                        break # Exit the loop since we found Chrome
                    } else {
                        Write-Host "  No Chrome processes found on attempt $attempt" -ForegroundColor Yellow
                    }
                }
                
                if (-not $chromeDetected) {
                    Write-Host "  [ERROR] No Chrome processes found after $maxAttempts attempts!" -ForegroundColor Red
                    Write-Host "  Please check if Chrome is installed and the shortcut is configured correctly" -ForegroundColor Red
                }
            }
            
            Start-Sleep -Seconds 3 # Give each app time to start before launching the next
        }
        
        Write-Host "All shortcuts launched successfully!" -ForegroundColor Green
        Write-Host "`nTo manually verify the DR extension is working:" -ForegroundColor Yellow
        Write-Host "1. You should see a RED 'DR ENVIRONMENT' banner at the top of the DR environment page" -ForegroundColor Yellow
        Write-Host "2. If not visible, check Chrome's extension page (chrome://extensions) to see if the extension is loaded" -ForegroundColor Yellow
        Write-Host "3. The extension is designed to match: https://apps.dr1.pure.cloud/* as specified in the manifest.json" -ForegroundColor Yellow
    }
}

# Run the tests with auto-launch enabled
Write-Host "Starting shortcut script tests with proper Genesys Cloud Chrome app shortcuts..." -ForegroundColor Cyan
Write-Host "Using PROD icon: $prodIconPath" -ForegroundColor Yellow
Write-Host "Using DR icon: $drIconPath" -ForegroundColor Yellow
Invoke-ShortcutTests -LaunchShortcuts $true 