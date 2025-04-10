# Improved CRX Installation Script
# Installs CRX extension while ensuring no blocking policies are enabled

# Configuration
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"  # Update with your CRX location
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"
$blocklistPath = "$chromePoliciesPath\ExtensionInstallBlocklist"
$allowlistPath = "$chromePoliciesPath\ExtensionInstallAllowlist"

Write-Host "Starting CRX installation process..." -ForegroundColor Cyan

# 1. First, remove wildcard from blocklist (MOST IMPORTANT STEP)
Write-Host "`n=== CHECKING BLOCKLIST ===" -ForegroundColor Cyan
if (Test-Path -Path $blocklistPath) {
    $wildcardRemoved = $false
    $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    
    foreach ($prop in $blocklistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            Write-Host "Found wildcard (*) at index $($prop.Name) - removing..." -NoNewline
            try {
                Remove-ItemProperty -Path $blocklistPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                Write-Host "Success!" -ForegroundColor Green
                $wildcardRemoved = $true
            } catch {
                Write-Host "Failed! Error: $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $wildcardRemoved) {
        Write-Host "No wildcard blocklist entry found. Good!" -ForegroundColor Green
    }
} else {
    Write-Host "Blocklist not found. This is good!" -ForegroundColor Green
}

# 2. Make sure extension is in allowlist
Write-Host "`n=== ADDING TO ALLOWLIST ===" -ForegroundColor Cyan
# Ensure path exists
if (-not (Test-Path $allowlistPath)) {
    Write-Host "Creating allowlist path..." -NoNewline
    try {
        New-Item -Path $allowlistPath -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed! Error: $_" -ForegroundColor Red
    }
}

# Check if already in allowlist
$extensionInAllowlist = $false
if (Test-Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $extensionId) {
            $extensionInAllowlist = $true
            Write-Host "Extension already in allowlist at index $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}

# Add to allowlist if not already there
if (-not $extensionInAllowlist) {
    # Find next available index
    $indices = @()
    if (Test-Path $allowlistPath) {
        $indices = (Get-Item $allowlistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
    }
    $nextIndex = 1
    while ($indices -contains $nextIndex.ToString()) {
        $nextIndex++
    }
    
    Write-Host "Adding extension to allowlist at index $nextIndex..." -NoNewline
    try {
        New-ItemProperty -Path $allowlistPath -Name $nextIndex -Value $extensionId -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed! Error: $_" -ForegroundColor Red
    }
}

# 3. Make sure BlockExternalExtensions is disabled
Write-Host "`n=== CONFIGURING REQUIRED POLICIES ===" -ForegroundColor Cyan
Write-Host "Setting BlockExternalExtensions=0..." -NoNewline
try {
    New-ItemProperty -Path $chromePoliciesPath -Name "BlockExternalExtensions" -Value 0 -PropertyType DWORD -Force | Out-Null
    Write-Host "Success!" -ForegroundColor Green
} catch {
    Write-Host "Failed! Error: $_" -ForegroundColor Red
}

# 4. Add to force-install list
Write-Host "`n=== ADDING TO FORCE-INSTALL LIST ===" -ForegroundColor Cyan
# Ensure path exists
if (-not (Test-Path $forcelistPath)) {
    Write-Host "Creating force-install list path..." -NoNewline
    try {
        New-Item -Path $forcelistPath -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed! Error: $_" -ForegroundColor Red
    }
}

# Check if already in force-install list
$extensionInForcelist = $false
if (Test-Path $forcelistPath) {
    $forcelistEntries = Get-ItemProperty -Path $forcelistPath -ErrorAction SilentlyContinue
    foreach ($prop in $forcelistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -match "^$extensionId;") {
            $extensionInForcelist = $true
            Write-Host "Extension already in force-install list at index $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}

# Add to force-install list if not already there
if (-not $extensionInForcelist) {
    # Find next available index
    $indices = @()
    if (Test-Path $forcelistPath) {
        $indices = (Get-Item $forcelistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
    }
    $nextIndex = 1
    while ($indices -contains $nextIndex.ToString()) {
        $nextIndex++
    }
    
    # Convert path to file:// URL format with forward slashes
    $crxPathUrl = $crxPath.Replace("\", "/")
    $crxPathUrl = "file:///$crxPathUrl"
    
    Write-Host "Adding extension to force-install list at index $nextIndex..." -NoNewline
    try {
        New-ItemProperty -Path $forcelistPath -Name $nextIndex -Value "$extensionId;$crxPathUrl" -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed! Error: $_" -ForegroundColor Red
    }
}

# Verify CRX file exists
Write-Host "`n=== VERIFYING CRX FILE ===" -ForegroundColor Cyan
if (Test-Path $crxPath) {
    $crxFile = Get-Item -Path $crxPath
    Write-Host ("CRX file exists at " + $crxPath + " (Size: " + [math]::Round($crxFile.Length/1KB, 2) + " KB)") -ForegroundColor Green
} else {
    Write-Host ("WARNING: CRX file not found at " + $crxPath) -ForegroundColor Red
    Write-Host "Installation will likely fail without the CRX file" -ForegroundColor Red
}

# Final message
Write-Host "`n=== INSTALLATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "CRX extension has been configured for installation"
Write-Host "Follow these steps to complete the process:"
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Close ALL Chrome instances completely"
Write-Host "3. Restart Chrome - the extension should auto-install"
Write-Host "4. If not auto-installed, you can manually drag and drop the CRX file into Chrome" 