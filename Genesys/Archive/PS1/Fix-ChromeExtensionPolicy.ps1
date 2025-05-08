#
# Fix-ChromeExtensionPolicy.ps1
# Comprehensive diagnostic and fix for Chrome extension policy issues
#

param(
    [string]$ExtensionId = "idjmoolmcplbkjcldambblbojejkdpij",
    [switch]$Force = $false
)

# Create log file
$logFile = "$env:TEMP\ChromeExtensionPolicy_Fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Extension Policy Diagnostics - $(Get-Date)"

# Registry paths
$chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$allowlistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"
$blocklistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallBlocklist"
$forcelistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

Write-Host "`n========== POLICY DIAGNOSIS ==========" -ForegroundColor Cyan

# Function to check if a path exists, create if it doesn't
function Ensure-RegistryPath {
    param ([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "Creating registry path: $Path"
        New-Item -Path $Path -Force | Out-Null
        return $false
    }
    return $true
}

# Ensure all paths exist
Ensure-RegistryPath -Path $chromePolicyPath
Ensure-RegistryPath -Path $allowlistPath
Ensure-RegistryPath -Path $blocklistPath
Ensure-RegistryPath -Path $forcelistPath

# Check ExtensionInstallBlocklist policy (this is critical)
$blocklistEntries = @()
$extensionBlocked = $false
$wildcardBlocking = $false

if (Test-Path -Path $blocklistPath) {
    $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    foreach ($prop in $blocklistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            Write-Host "Blocklist entry at index $($prop.Name): $($prop.Value)"
            if ($prop.Value -eq "*") {
                $wildcardBlocking = $true
                Write-Host "CRITICAL ISSUE: Wildcard (*) blocking ALL extensions" -ForegroundColor Red
            }
            if ($prop.Value -eq $ExtensionId) {
                $extensionBlocked = $true
                Write-Host "CRITICAL ISSUE: Extension ID '$ExtensionId' explicitly blocked" -ForegroundColor Red
            }
        }
    }
}

# Check ExtensionInstallAllowlist policy
$allowlistEntries = @()
$extensionAllowed = $false

if (Test-Path -Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
            $extensionAllowed = $true
            Write-Host "Extension ID '$ExtensionId' found in allowlist at index: $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}
if (-not $extensionAllowed) {
    Write-Host "Extension ID '$ExtensionId' not found in allowlist" -ForegroundColor Yellow
}

# Check ExtensionInstallForcelist
$extensionForced = $false
if (Test-Path -Path $forcelistPath) {
    $forcelistEntries = Get-ItemProperty -Path $forcelistPath -ErrorAction SilentlyContinue
    foreach ($prop in $forcelistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -match "^$ExtensionId;") {
            $extensionForced = $true
            Write-Host "Extension found in force-install list at index: $($prop.Name)" -ForegroundColor Green
            Write-Host "Force-install entry: $($prop.Value)"
            break
        }
    }
}
if (-not $extensionForced) {
    Write-Host "Extension not found in force-install list" -ForegroundColor Yellow
}

# Check Developer Mode policy
$developerModeEnabled = $false
if (Test-Path -Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
    if ($chromePolicy.PSObject.Properties.Name -contains "ExtensionDeveloperModeAllowed" -and $chromePolicy.ExtensionDeveloperModeAllowed -eq 1) {
        $developerModeEnabled = $true
        Write-Host "Developer Mode is enabled" -ForegroundColor Green
    } else {
        Write-Host "Developer Mode is not enabled" -ForegroundColor Yellow
    }
}

# Summary of findings
Write-Host "`n========== DIAGNOSIS SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Extension ID: $ExtensionId"
Write-Host "Allowlist status: $(if ($extensionAllowed) { "Added ✓" } else { "Missing ✗" })"
Write-Host "Blocklist status: $(if ($extensionBlocked) { "Explicitly blocked ✗" } else { "Not explicitly blocked ✓" })"
Write-Host "Wildcard blocking: $(if ($wildcardBlocking) { "Enabled - blocks all unless allowed !" } else { "Disabled ✓" })"
Write-Host "Force-install status: $(if ($extensionForced) { "Configured ✓" } else { "Not configured ✗" })"
Write-Host "Developer Mode: $(if ($developerModeEnabled) { "Enabled ✓" } else { "Disabled ✗" })"

# Determine required fixes
$fixes = @()

if (-not $extensionAllowed) {
    $fixes += "Add extension to allowlist"
}

if ($wildcardBlocking -and -not $extensionAllowed) {
    $fixes += "Extension blocked by wildcard policy - must be explicitly allowed"
}

if ($extensionBlocked) {
    $fixes += "Remove extension from blocklist"
}

if (-not $developerModeEnabled) {
    $fixes += "Enable Developer Mode"
}

if (-not $extensionForced) {
    $fixes += "Add extension to force-install list (optional)"
}

# Show recommended fixes
Write-Host "`n========== RECOMMENDED FIXES ==========" -ForegroundColor Cyan
if ($fixes.Count -eq 0) {
    Write-Host "No fixes needed. All policies appear to be correctly configured." -ForegroundColor Green
    if (-not $Force) {
        Write-Host "If you're still experiencing issues, run with -Force parameter to apply fixes anyway."
        Stop-Transcript
        exit
    }
} else {
    Write-Host "The following fixes are recommended:" -ForegroundColor Yellow
    $fixes | ForEach-Object { Write-Host "- $_" }
}

# Ask for confirmation
if (-not $Force) {
    $confirmChanges = Read-Host "`nDo you want to apply these fixes? (Y/N)"
    if ($confirmChanges -ne 'Y' -and $confirmChanges -ne 'y') {
        Write-Host "Changes cancelled by user. Exiting script." -ForegroundColor Yellow
        Stop-Transcript
        exit
    }
}

Write-Host "`n========== APPLYING FIXES ==========" -ForegroundColor Cyan

# Ensure the extension is in allowlist
if (-not $extensionAllowed -or $Force) {
    Write-Host "Adding extension ID to allowlist..." -NoNewline
    try {
        # Get the next available index
        $indices = @()
        if (Test-Path $allowlistPath) {
            $indices = (Get-Item $allowlistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
        }
        $nextIndex = 1
        while ($indices -contains $nextIndex.ToString()) {
            $nextIndex++
        }

        # Add the extension ID
        New-ItemProperty -Path $allowlistPath -Name $nextIndex -Value $ExtensionId -PropertyType String -Force | Out-Null
        Write-Host "Success! Added at index $nextIndex" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Remove from blocklist if explicitly blocked
if ($extensionBlocked -or $Force) {
    Write-Host "Removing extension ID from blocklist..." -NoNewline
    try {
        $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $blocklistEntries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
                Remove-ItemProperty -Path $blocklistPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                Write-Host "Success! Removed from index $($prop.Name)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Enable Developer Mode if needed
if (-not $developerModeEnabled -or $Force) {
    Write-Host "Enabling ExtensionDeveloperModeAllowed policy..." -NoNewline
    try {
        New-ItemProperty -Path $chromePolicyPath -Name "ExtensionDeveloperModeAllowed" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Add BlockExternalExtensions policy if there's a wildcard blocking issue
if ($wildcardBlocking) {
    Write-Host "Setting BlockExternalExtensions to false..." -NoNewline
    try {
        New-ItemProperty -Path $chromePolicyPath -Name "BlockExternalExtensions" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Verify all changes
Write-Host "`n========== VERIFYING CHANGES ==========" -ForegroundColor Cyan
$allChangesSuccessful = $true

# Re-check extension in allowlist
$extensionInAllowlist = $false
if (Test-Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
            $extensionInAllowlist = $true
            Write-Host "Verified: Extension ID in allowlist at index: $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}
if (-not $extensionInAllowlist) {
    Write-Host "Error: Extension ID not found in allowlist after changes" -ForegroundColor Red
    $allChangesSuccessful = $false
}

# Re-check not in blocklist
$extensionBlocked = $false
if (Test-Path $blocklistPath) {
    $blocklistEntries = Get-ItemProperty -Path $blocklistPath
    foreach ($prop in $blocklistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
            $extensionBlocked = $true
            Write-Host "Error: Extension still found in blocklist at index: $($prop.Name)" -ForegroundColor Red
            break
        }
    }
}
if ($extensionBlocked) {
    $allChangesSuccessful = $false
}

# Re-check Developer Mode
$developerModeEnabled = $false
if (Test-Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath
    if ($chromePolicy.PSObject.Properties.Name -contains "ExtensionDeveloperModeAllowed" -and $chromePolicy.ExtensionDeveloperModeAllowed -eq 1) {
        $developerModeEnabled = $true
        Write-Host "Verified: Developer Mode is enabled" -ForegroundColor Green
    } else {
        Write-Host "Error: Developer Mode is not enabled after changes" -ForegroundColor Red
        $allChangesSuccessful = $false
    }
}

# Final summary
if ($allChangesSuccessful) {
    Write-Host "`nAll policy changes successfully applied and verified!" -ForegroundColor Green
    Write-Host "`nNext steps to get your extension working:"
    Write-Host "1. Close ALL Chrome instances (check Task Manager to make sure)"
    Write-Host "2. Run gpupdate /force to refresh policies"
    Write-Host "3. Restart Chrome and try installing the extension again"
    Write-Host "4. If still not working, try restarting your computer"
} else {
    Write-Host "`nSome policy changes could not be verified." -ForegroundColor Yellow
    Write-Host "You may need to manually configure Chrome policies or restart your computer."
}

# Additional troubleshooting tips
Write-Host "`n========== ADVANCED TROUBLESHOOTING ==========" -ForegroundColor Cyan
Write-Host "If the extension still won't install, try these steps:"
Write-Host "1. Open chrome://policy in Chrome to view all applied policies"
Write-Host "2. Check if any policy conflicts are reported"
Write-Host "3. Run chrome.exe --enable-logging --v=1 to generate detailed logs"
Write-Host "4. Consider using a different Chrome profile or user account"

# Stop transcript
Write-Host "`nDiagnostic log saved to: $logFile"
Stop-Transcript 