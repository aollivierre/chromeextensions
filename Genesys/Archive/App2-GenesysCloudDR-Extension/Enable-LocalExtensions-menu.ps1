#
# Enable-LocalExtensions.ps1
# Complete solution for enabling local Chrome extensions with --load-extension
#

param(
    [string]$ExtensionPath = "C:\Program Files\GenesysPOC\ChromeExtension",
    [switch]$Force = $true
)

# Create log file
$logFile = "$env:TEMP\EnableLocalExtensions_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Local Extension Configuration - $(Get-Date)"

# Registry paths
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$blocklistPath = "$chromePoliciesPath\ExtensionInstallBlocklist"

function Remove-WildcardFromBlocklist {
    Write-Host "`n=== CHECKING BLOCKLIST ===" -ForegroundColor Cyan
    if (Test-Path -Path $blocklistPath) {
        $wildcardFound = $false
        $wildcardIndex = $null
        
        # Check for wildcard in blocklist
        $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $blocklistEntries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
                $wildcardIndex = $prop.Name
                $wildcardFound = $true
                Write-Host "Found wildcard (*) at index $wildcardIndex - this blocks ALL extensions" -ForegroundColor Red
                break
            }
        }
        
        if ($wildcardFound) {
            Write-Host "Removing wildcard blocklist entry..." -NoNewline
            try {
                Remove-ItemProperty -Path $blocklistPath -Name $wildcardIndex -Force -ErrorAction SilentlyContinue
                Write-Host "Success!" -ForegroundColor Green
            } catch {
                Write-Host "Failed!" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
                Write-Host "Extension loading will likely fail without this change" -ForegroundColor Red
            }
        } else {
            Write-Host "No wildcard blocking found in blocklist. This is good!" -ForegroundColor Green
        }
    } else {
        Write-Host "Blocklist path not found. This is good - no extensions are blocked." -ForegroundColor Green
    }
}

function SetPolicy {
    param (
        [string]$PolicyName,
        [object]$Value,
        [string]$PropertyType
    )
    
    Write-Host "Setting $PolicyName..." -NoNewline
    try {
        New-ItemProperty -Path $chromePoliciesPath -Name $PolicyName -Value $Value -PropertyType $PropertyType -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Configure-RequiredPolicies {
    Write-Host "`n=== CONFIGURING REQUIRED POLICIES ===" -ForegroundColor Cyan

    # Create policies key if it doesn't exist
    if (-not (Test-Path -Path $chromePoliciesPath)) {
        Write-Host "Creating Chrome Policies registry key..." -NoNewline
        try {
            New-Item -Path $chromePoliciesPath -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    # Set critical policies
    $success = $true
    $success = $success -and (SetPolicy -PolicyName "ExtensionDeveloperModeAllowed" -Value 1 -PropertyType "DWORD")
    $success = $success -and (SetPolicy -PolicyName "AllowedLocalExtensionPaths" -Value $ExtensionPath -PropertyType "String")
    $success = $success -and (SetPolicy -PolicyName "BlockExternalExtensions" -Value 0 -PropertyType "DWORD")
    
    return $success
}

function CheckPolicy {
    param (
        [string]$PolicyName,
        [object]$ExpectedValue
    )
    
    try {
        $item = Get-ItemProperty -Path $chromePoliciesPath -Name $PolicyName -ErrorAction SilentlyContinue
        if ($null -ne $item -and $null -ne $item.$PolicyName) {
            if ($item.$PolicyName -eq $ExpectedValue) {
                Write-Host "Verified: $PolicyName = $($item.$PolicyName)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "WARNING: $PolicyName = $($item.$PolicyName) (Expected: $ExpectedValue)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "WARNING: $PolicyName not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error checking $PolicyName $_" -ForegroundColor Red
        return $false
    }
}

function Verify-Configuration {
    Write-Host "`n=== VERIFYING CONFIGURATION ===" -ForegroundColor Cyan

    # Check if wildcard was removed
    $wildcardStillBlocking = $false
    if (Test-Path $blocklistPath) {
        $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $blocklistEntries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
                $wildcardStillBlocking = $true
                Write-Host "WARNING: Wildcard still in blocklist at index $($prop.Name)" -ForegroundColor Red
                break
            }
        }
    }

    if (-not $wildcardStillBlocking) {
        Write-Host "Verified: No wildcard blocking in blocklist" -ForegroundColor Green
    }

    # Check policy values
    $policiesVerified = $true
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "ExtensionDeveloperModeAllowed" -ExpectedValue 1)
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "AllowedLocalExtensionPaths" -ExpectedValue $ExtensionPath)
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "BlockExternalExtensions" -ExpectedValue 0)
    
    return @{
        WildcardStillBlocking = $wildcardStillBlocking
        PoliciesVerified = $policiesVerified
    }
}

function Create-ExtensionDirectory {
    Write-Host "`n=== CHECKING EXTENSION DIRECTORY ===" -ForegroundColor Cyan
    if (-not (Test-Path -Path $ExtensionPath)) {
        Write-Host "Extension directory does not exist. Creating it..." -NoNewline
        try {
            New-Item -Path $ExtensionPath -ItemType Directory -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Extension directory exists at: $ExtensionPath" -ForegroundColor Green
        return $true
    }
}

function Create-DesktopShortcut {
    Write-Host "`n=== CREATING DESKTOP SHORTCUT ===" -ForegroundColor Cyan
    try {
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$desktopPath\GenesysChrome.lnk")
        $Shortcut.TargetPath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
        $Shortcut.Arguments = "--load-extension=""$ExtensionPath"""
        $Shortcut.Save()
        Write-Host "Created desktop shortcut: $desktopPath\GenesysChrome.lnk" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to create shortcut: $_" -ForegroundColor Red
        
        # Provide manual command as fallback
        Write-Host "`nTo create a shortcut manually, run this PowerShell command:" -ForegroundColor Yellow
        Write-Host @"
`$WshShell = New-Object -ComObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut("$desktopPath\GenesysChrome.lnk")
`$Shortcut.TargetPath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
`$Shortcut.Arguments = "--load-extension=""$ExtensionPath"""
`$Shortcut.Save()
"@ -ForegroundColor Yellow
        return $false
    }
}

function Show-NextSteps {
    Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
    Write-Host "1. Run 'gpupdate /force' to refresh policies" -ForegroundColor Yellow
    Write-Host "2. Close ALL Chrome instances completely (check Task Manager to be sure)" -ForegroundColor Yellow
    Write-Host "3. Launch Chrome with the --load-extension parameter:" -ForegroundColor Yellow
    Write-Host "   chrome.exe --load-extension=""$ExtensionPath""" -ForegroundColor Yellow
}

function Show-Summary {
    param (
        [bool]$Success,
        [bool]$PoliciesVerified,
        [bool]$WildcardStillBlocking
    )
    
    Write-Host "`n=== CONFIGURATION SUMMARY ===" -ForegroundColor Cyan
    if ($Success -and $PoliciesVerified -and (-not $WildcardStillBlocking)) {
        Write-Host "All configurations complete! Local extensions should work now." -ForegroundColor Green
    } else {
        Write-Host "Some configurations were not applied correctly." -ForegroundColor Red
        
        if ($WildcardStillBlocking) {
            Write-Host "- Wildcard still blocking all extensions" -ForegroundColor Red
        }
        
        if (-not $Success) {
            Write-Host "- Not all policies were set successfully" -ForegroundColor Red
        }
        
        if (-not $PoliciesVerified) {
            Write-Host "- Policy verification failed" -ForegroundColor Red
        }
    }
}

function Run-AllSteps {
    # 1. Remove wildcard from blocklist
    Remove-WildcardFromBlocklist
    
    # 2. Configure required policies
    $success = Configure-RequiredPolicies
    
    # 3. Verify configuration
    $verificationResult = Verify-Configuration
    $wildcardStillBlocking = $verificationResult.WildcardStillBlocking
    $policiesVerified = $verificationResult.PoliciesVerified
    
    # 4. Create extension directory
    Create-ExtensionDirectory
    
    # 5. Show summary
    Show-Summary -Success $success -PoliciesVerified $policiesVerified -WildcardStillBlocking $wildcardStillBlocking
    
    # 6. Create shortcut if forced
    if ($Force) {
        Create-DesktopShortcut
    }
    
    # 7. Show next steps
    Show-NextSteps
}

function Show-Menu {
    Clear-Host
    Write-Host "=== CHROME LOCAL EXTENSION CONFIGURATION MENU ===" -ForegroundColor Cyan
    Write-Host "1: Remove wildcard from blocklist (most important step)" -ForegroundColor White
    Write-Host "2: Configure required Chrome policies" -ForegroundColor White
    Write-Host "3: Verify configuration" -ForegroundColor White
    Write-Host "4: Create extension directory ($ExtensionPath)" -ForegroundColor White
    Write-Host "5: Create Chrome desktop shortcut" -ForegroundColor White
    Write-Host "6: Show next steps" -ForegroundColor White
    Write-Host "A: Run ALL steps (original script behavior)" -ForegroundColor Green
    Write-Host "Q: Quit" -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor Cyan
}

# Main menu loop
function Start-Menu {
    $menuRunning = $true
    
    while ($menuRunning) {
        Show-Menu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice.ToUpper()) {
            '1' {
                Remove-WildcardFromBlocklist
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '2' {
                Configure-RequiredPolicies
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '3' {
                Verify-Configuration
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '4' {
                Create-ExtensionDirectory
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '5' {
                Create-DesktopShortcut
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '6' {
                Show-NextSteps
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            'A' {
                Run-AllSteps
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            'Q' {
                $menuRunning = $false
                Write-Host "Exiting menu..." -ForegroundColor Yellow
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Start the menu
Start-Menu

Write-Host "`nConfiguration log saved to: $logFile"
Stop-Transcript 