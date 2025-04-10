#
# Enable-LocalExtensions.ps1
# Menu-based solution for enabling local Chrome extensions with --load-extension
#

param(
    [string]$ExtensionPath = "C:\Program Files\GenesysPOC\ChromeExtension"
)

# Create log file
$logFile = "$env:TEMP\EnableLocalExtensions_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Local Extension Configuration - $(Get-Date)"

# Registry paths
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$blocklistPath = "$chromePoliciesPath\ExtensionInstallBlocklist"

function Remove-WildcardFromBlocklist {
    Write-Host "`n=== REMOVING WILDCARD FROM BLOCKLIST ===" -ForegroundColor Cyan
    Write-Host "This step removes the wildcard (*) from Chrome's extension blocklist."
    Write-Host "The wildcard blocks ALL extensions, including local ones."
    
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
        # Create policies key if it doesn't exist
        if (-not (Test-Path -Path $chromePoliciesPath)) {
            New-Item -Path $chromePoliciesPath -Force | Out-Null
            Write-Host "Created Chrome Policies registry key." -ForegroundColor Green
        }
    
        New-ItemProperty -Path $chromePoliciesPath -Name $PolicyName -Value $Value -PropertyType $PropertyType -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Enable-DeveloperMode {
    Write-Host "`n=== ENABLING CHROME EXTENSION DEVELOPER MODE ===" -ForegroundColor Cyan
    Write-Host "This policy allows Chrome to load unpacked extensions"
    Write-Host "Required Policy: ExtensionDeveloperModeAllowed = 1"
    
    SetPolicy -PolicyName "ExtensionDeveloperModeAllowed" -Value 1 -PropertyType "DWORD"
}

function Set-AllowedExtensionPaths {
    Write-Host "`n=== SETTING ALLOWED EXTENSION PATHS ===" -ForegroundColor Cyan
    Write-Host "This policy tells Chrome which paths are allowed for loading local extensions"
    Write-Host "Required Policy: AllowedLocalExtensionPaths = $ExtensionPath"
    
    SetPolicy -PolicyName "AllowedLocalExtensionPaths" -Value $ExtensionPath -PropertyType "String"
}

function Disable-ExternalExtensionBlocking {
    Write-Host "`n=== ALLOWING EXTERNAL EXTENSIONS ===" -ForegroundColor Cyan
    Write-Host "This policy disables Chrome's external extension blocking feature"
    Write-Host "Required Policy: BlockExternalExtensions = 0"
    
    SetPolicy -PolicyName "BlockExternalExtensions" -Value 0 -PropertyType "DWORD"
}

function Add-ExtensionToAllowlist {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExtensionId = "extension_id_placeholder"
    )
    
    Write-Host "`n=== ADDING EXTENSION TO ALLOWLIST ===" -ForegroundColor Cyan
    Write-Host "This adds your extension to the allowlist, permitting it to run even with wildcard blocklist"
    Write-Host "Policy: ExtensionInstallAllowlist"
    Write-Host "NOTE: This works best for Chrome Web Store extensions and packaged CRX files." -ForegroundColor Yellow
    Write-Host "      For local unpacked extensions, this may or may not work depending on how Chrome" -ForegroundColor Yellow
    Write-Host "      processes the extension ID for unpacked extensions." -ForegroundColor Yellow
    
    $allowlistPath = "$chromePoliciesPath\ExtensionInstallAllowlist"
    
    # Create allowlist key if it doesn't exist
    if (-not (Test-Path -Path $allowlistPath)) {
        Write-Host "Creating allowlist registry key..." -NoNewline
        try {
            New-Item -Path $allowlistPath -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Find the next available index
    $nextIndex = 1
    if (Test-Path -Path $allowlistPath) {
        $allowlistEntries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
        foreach ($prop in $allowlistEntries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$') {
                $index = [int]$prop.Name
                if ($index -ge $nextIndex) {
                    $nextIndex = $index + 1
                }
                
                # Check if extension ID is already in the allowlist
                if ($prop.Value -eq $ExtensionId) {
                    Write-Host "Extension ID $ExtensionId is already in the allowlist at index $($prop.Name)" -ForegroundColor Green
                    return $true
                }
            }
        }
    }
    
    # Add extension ID to allowlist
    Write-Host "Adding extension ID $ExtensionId to allowlist at index $nextIndex..." -NoNewline
    try {
        New-ItemProperty -Path $allowlistPath -Name $nextIndex -Value $ExtensionId -PropertyType "String" -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "Your extension should now be allowed even with the wildcard blocklist" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Set-MixedBlockAllowApproach {
    Write-Host "`n=== CONFIGURING MIXED BLOCK/ALLOW APPROACH ===" -ForegroundColor Cyan
    Write-Host "This uses a combination of policies to try allowing local extensions while keeping the wildcard block"
    Write-Host "This is an experimental approach that may work in some environments"
    
    # 1. First ensure developer mode is allowed
    Write-Host "`nStep 1: Enable developer mode"
    Enable-DeveloperMode
    
    # 2. Set specific allowed local extension paths
    Write-Host "`nStep 2: Set allowed local extension paths"
    Set-AllowedExtensionPaths
    
    # 3. Disable external extension blocking
    Write-Host "`nStep 3: Disable external extension blocking"
    Disable-ExternalExtensionBlocking
    
    # 4. Try setting ExtensionSettings policy (Chrome 78+)
    # This is a more granular approach that might allow local extensions to override the blocklist
    Write-Host "`nStep 4: Configuring ExtensionSettings policy..." -NoNewline
    
    try {
        # Create ExtensionSettings key if it doesn't exist
        $extensionSettingsPath = "$chromePoliciesPath\ExtensionSettings"
        if (-not (Test-Path -Path $extensionSettingsPath)) {
            New-Item -Path $extensionSettingsPath -Force | Out-Null
        }
        
        # Create '*' key for default settings
        $wildcardPath = "$extensionSettingsPath\*"
        if (-not (Test-Path -Path $wildcardPath)) {
            New-Item -Path $wildcardPath -Force | Out-Null
        }
        
        # Set the installation_mode to blocked by default (like blocklist)
        New-ItemProperty -Path $wildcardPath -Name "installation_mode" -Value "blocked" -PropertyType "String" -Force | Out-Null
        
        # Create key for allowed local extension path pattern
        $localExtensionsKey = "$extensionSettingsPath\$ExtensionPath"
        if (-not (Test-Path -Path $localExtensionsKey -ErrorAction SilentlyContinue)) {
            New-Item -Path $localExtensionsKey -Force -ErrorAction SilentlyContinue | Out-Null
        }
        
        # Set the installation_mode to allowed for local extensions
        New-ItemProperty -Path $localExtensionsKey -Name "installation_mode" -Value "allowed" -PropertyType "String" -Force -ErrorAction SilentlyContinue | Out-Null
        
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "ExtensionSettings policy configured (more granular than blocklist/allowlist)" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "This policy may not be supported in your Chrome version" -ForegroundColor Yellow
    }
    
    Write-Host "`nMixed approach configuration complete. This creates a more granular policy structure"
    Write-Host "that might allow local extensions while maintaining the wildcard block."
    Write-Host "Note: This is experimental and may not work in all environments." -ForegroundColor Yellow
}

function Create-ExtensionDirectory {
    Write-Host "`n=== CREATING EXTENSION DIRECTORY ===" -ForegroundColor Cyan
    Write-Host "Creating directory for local extensions at: $ExtensionPath"
    
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

function Verify-AllPolicies {
    Write-Host "`n=== VERIFYING ALL POLICIES ===" -ForegroundColor Cyan
    Write-Host "Checking all required Chrome policies are correctly set"
    
    # Check policy values
    $policiesVerified = $true
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "ExtensionDeveloperModeAllowed" -ExpectedValue 1)
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "AllowedLocalExtensionPaths" -ExpectedValue $ExtensionPath)
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "BlockExternalExtensions" -ExpectedValue 0)
    
    if ($policiesVerified) {
        Write-Host "All policies are correctly set!" -ForegroundColor Green
    } else {
        Write-Host "Some policies are not set correctly. Please review the warnings above." -ForegroundColor Red
    }
}

function Verify-BlocklistWildcard {
    Write-Host "`n=== CHECKING BLOCKLIST FOR WILDCARD ===" -ForegroundColor Cyan
    Write-Host "Verifying the blocklist doesn't contain a wildcard (*) that would block ALL extensions"
    
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
}

function Show-NextSteps {
    Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
    Write-Host "After configuring policies, follow these steps:" -ForegroundColor Yellow
    Write-Host "1. Run 'gpupdate /force' to refresh policies" -ForegroundColor Yellow
    Write-Host "2. Close ALL Chrome instances completely (check Task Manager to be sure)" -ForegroundColor Yellow
    Write-Host "3. Launch Chrome with the --load-extension parameter:" -ForegroundColor Yellow
    Write-Host "   chrome.exe --load-extension=""$ExtensionPath""" -ForegroundColor Yellow
}

function Run-AllSteps {
    Write-Host "`n=== RUNNING ALL CONFIGURATION STEPS ===" -ForegroundColor Cyan
    Write-Host "This will perform all necessary steps to enable local extensions"
    
    # 1. Remove wildcard from blocklist
    Remove-WildcardFromBlocklist
    
    # 2. Set all required policies
    Enable-DeveloperMode
    Set-AllowedExtensionPaths
    Disable-ExternalExtensionBlocking
    
    # 3. Create extension directory
    Create-ExtensionDirectory
    
    # 4. Verify configuration
    Verify-BlocklistWildcard
    Verify-AllPolicies
    
    # 5. Show next steps
    Show-NextSteps
    
    Write-Host "`n=== ALL STEPS COMPLETED ===" -ForegroundColor Green
}

function Restore-WorkingState {
    Write-Host "`n=== EMERGENCY RESTORE - REVERTING EXPERIMENTAL CHANGES ===" -ForegroundColor Red
    Write-Host "This will remove ExtensionSettings policy and restore the previous working configuration"
    
    # 1. First remove ExtensionSettings key and all subkeys (cleanup from experimental approach)
    $extensionSettingsPath = "$chromePoliciesPath\ExtensionSettings"
    if (Test-Path -Path $extensionSettingsPath) {
        Write-Host "`nRemoving ExtensionSettings policy..." -NoNewline
        try {
            Remove-Item -Path $extensionSettingsPath -Recurse -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "ExtensionSettings policy not found. No action needed." -ForegroundColor Green
    }
    
    # 2. Make sure the wildcard is removed from blocklist (restore to working state)
    Write-Host "`nChecking blocklist for wildcard..."
    Remove-WildcardFromBlocklist
    
    # 3. Ensure base policies are set correctly
    Write-Host "`nRestoring essential policies..."
    Enable-DeveloperMode
    Set-AllowedExtensionPaths
    Disable-ExternalExtensionBlocking
    
    Write-Host "`n=== RESTORE COMPLETE ===" -ForegroundColor Green
    Write-Host "Your configuration should now be back to a working state." -ForegroundColor Green
    Write-Host "Please try option 1 again, which was working previously." -ForegroundColor Yellow
}

function Show-Menu {
    Clear-Host
    Write-Host "======= CHROME LOCAL EXTENSION CONFIGURATION MENU =======" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " REGISTRY BLOCKLIST OPERATIONS:" -ForegroundColor Yellow
    Write-Host " 1: Remove wildcard (*) from extension blocklist" -ForegroundColor White
    Write-Host " 2: Verify blocklist doesn't contain wildcard" -ForegroundColor White
    Write-Host ""
    Write-Host " INDIVIDUAL CHROME POLICIES:" -ForegroundColor Yellow
    Write-Host " 3: Enable Chrome extension developer mode" -ForegroundColor White
    Write-Host " 4: Set allowed local extension paths" -ForegroundColor White 
    Write-Host " 5: Disable external extension blocking" -ForegroundColor White
    Write-Host " 6: Verify all Chrome policies" -ForegroundColor White
    Write-Host ""
    Write-Host " EMERGENCY OPTION:" -ForegroundColor Red
    Write-Host " R: RESTORE - Revert experimental changes (use if option 8 broke things)" -ForegroundColor Red
    Write-Host ""
    Write-Host " EXPERIMENTAL OPTIONS:" -ForegroundColor Yellow
    Write-Host " 7: Add extension to allowlist (best for Web Store extensions)" -ForegroundColor White
    Write-Host " 8: Try mixed block/allow approach (for local extensions)" -ForegroundColor White
    Write-Host ""  
    Write-Host " OTHER OPERATIONS:" -ForegroundColor Yellow
    Write-Host " 9: Create extension directory" -ForegroundColor White
    Write-Host " 0: Show next steps" -ForegroundColor White
    Write-Host ""
    Write-Host " A: Run ALL steps (complete configuration)" -ForegroundColor Green
    Write-Host " Q: Quit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
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
                Verify-BlocklistWildcard
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '3' {
                Enable-DeveloperMode
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '4' {
                Set-AllowedExtensionPaths
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '5' {
                Disable-ExternalExtensionBlocking
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '6' {
                Verify-AllPolicies
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '7' {
                $extensionId = Read-Host "Enter your extension ID (or press Enter to use placeholder)"
                if ([string]::IsNullOrWhiteSpace($extensionId)) {
                    Add-ExtensionToAllowlist
                } else {
                    Add-ExtensionToAllowlist -ExtensionId $extensionId
                }
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '8' {
                Set-MixedBlockAllowApproach
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '9' {
                Create-ExtensionDirectory
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            '0' {
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
            'R' {
                Restore-WorkingState
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
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