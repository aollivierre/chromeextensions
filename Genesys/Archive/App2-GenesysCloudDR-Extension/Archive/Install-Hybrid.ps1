# Hybrid approach for installing Chrome extensions
# Uses Chrome update URL format while working with local extensions

# Configuration
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"

# Use Chrome Web Store URL format - this is more reliable than file:///
# Chrome sees this as coming from the Web Store even though it points to our local file
$extensionUrl = "https://clients2.google.com/service/update2/crx"
$extensionData = "$extensionId;$extensionUrl"

# Create log file
$logFile = "$env:TEMP\ChromeExtensionInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Extension Installation - $(Get-Date)"

# Setup required registry paths
Write-Host "Setting up Chrome policies..." -ForegroundColor Cyan
if (-not (Test-Path $chromePoliciesPath)) {
    New-Item -Path $chromePoliciesPath -Force | Out-Null
}
if (-not (Test-Path $forcelistPath)) {
    New-Item -Path $forcelistPath -Force | Out-Null
}

# Find next available index
Write-Host "Finding next available index in forcelist..." -ForegroundColor Cyan
$nextIndex = 1
$properties = (Get-Item -Path $forcelistPath -ErrorAction SilentlyContinue).Property
if ($properties) {
    foreach ($prop in $properties) {
        if ($prop -match "^\d+$" -and [int]$prop -ge $nextIndex) {
            $nextIndex = [int]$prop + 1
        }
    }
}

# Add to force-install list
Write-Host "Adding extension $extensionId to force-install list at index $nextIndex..." -ForegroundColor Cyan
New-ItemProperty -Path $forcelistPath -Name $nextIndex -Value $extensionData -PropertyType String -Force | Out-Null

# Check if extension is already in the forcelist to avoid duplicates
$isDuplicate = $false
if ($properties) {
    foreach ($prop in $properties) {
        if ($prop -match "^\d+$") {
            $value = (Get-ItemProperty -Path $forcelistPath -Name $prop -ErrorAction SilentlyContinue).$prop
            if ($value -match "^$extensionId;") {
                if ($prop -ne $nextIndex.ToString()) {
                    Write-Host "Extension already exists at index $prop - removing duplicate" -ForegroundColor Yellow
                    Remove-ItemProperty -Path $forcelistPath -Name $prop -Force -ErrorAction SilentlyContinue
                } else {
                    $isDuplicate = $true
                }
            }
        }
    }
}

if ($isDuplicate) {
    Write-Host "Extension was already in the forcelist - value updated" -ForegroundColor Green
} else {
    Write-Host "Extension added to forcelist successfully" -ForegroundColor Green
}

# Verify the extension installation
Write-Host "`nVerifying configuration..." -ForegroundColor Cyan
$success = $true

try {
    $installedValue = (Get-ItemProperty -Path $forcelistPath -Name $nextIndex -ErrorAction Stop).$nextIndex
    if ($installedValue -eq $extensionData) {
        Write-Host "Verified: Extension correctly added to forcelist at index $nextIndex" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Extension data mismatch in forcelist at index $nextIndex" -ForegroundColor Red
        Write-Host "  Expected: $extensionData" -ForegroundColor Red
        Write-Host "  Found: $installedValue" -ForegroundColor Red
        $success = $false
    }
} catch {
    Write-Host "ERROR: Failed to verify extension in forcelist: $_" -ForegroundColor Red
    $success = $false
}

# Final summary
if ($success) {
    Write-Host "`nExtension installation configured successfully!" -ForegroundColor Green
} else {
    Write-Host "`nExtension installation had issues - check errors above" -ForegroundColor Red
}

Write-Host "`nTo complete installation:"
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Restart Chrome to apply changes"
Write-Host "3. Verify extension is installed at chrome://extensions"

Write-Host "`nInstallation log saved to: $logFile"
Stop-Transcript 