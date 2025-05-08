#
# Restore-ChromePolicies.ps1
# Restores Chrome policies to corporate defaults by removing custom modifications
#

# Create log file
$logFile = "$env:TEMP\ChromePolicyRestore_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Policy Restoration - $(Get-Date)"

# Extension ID to remove from policies
$ExtensionId = "idjmoolmcplbkjcldambblbojejkdpij"

# Registry paths
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$allowlistPath = "$chromePoliciesPath\ExtensionInstallAllowlist"
$blocklistPath = "$chromePoliciesPath\ExtensionInstallBlocklist"
$forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"

# 1. Remove our extension from allowlist
Write-Host "`n=== Removing Extension from Allowlist ===" -ForegroundColor Cyan
if (Test-Path -Path $allowlistPath) {
    $entriesToRemove = @()
    $entries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
            Write-Host "Found extension in allowlist at index $($prop.Name)"
            $entriesToRemove += $prop.Name
        }
    }
    
    foreach ($index in $entriesToRemove) {
        Write-Host "Removing extension from allowlist at index $index..." -NoNewline
        try {
            Remove-ItemProperty -Path $allowlistPath -Name $index -Force -ErrorAction SilentlyContinue
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
    
    if ($entriesToRemove.Count -eq 0) {
        Write-Host "Extension not found in allowlist" -ForegroundColor Yellow
    }
} else {
    Write-Host "Allowlist path not found" -ForegroundColor Yellow
}

# 2. Remove extension from forcelist
Write-Host "`n=== Removing Extension from Forcelist ===" -ForegroundColor Cyan
if (Test-Path -Path $forcelistPath) {
    $entriesToRemove = @()
    $entries = Get-ItemProperty -Path $forcelistPath -ErrorAction SilentlyContinue
    
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -match "^$ExtensionId;") {
            Write-Host "Found extension in forcelist at index $($prop.Name)"
            $entriesToRemove += $prop.Name
        }
    }
    
    foreach ($index in $entriesToRemove) {
        Write-Host "Removing extension from forcelist at index $index..." -NoNewline
        try {
            Remove-ItemProperty -Path $forcelistPath -Name $index -Force -ErrorAction SilentlyContinue
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
    
    if ($entriesToRemove.Count -eq 0) {
        Write-Host "Extension not found in forcelist" -ForegroundColor Yellow
    }
} else {
    Write-Host "Forcelist path not found" -ForegroundColor Yellow
}

# 3. Restore the wildcard blocklist entry (corporate policy standard)
Write-Host "`n=== Restoring Wildcard Blocklist ===" -ForegroundColor Cyan
if (Test-Path -Path $blocklistPath) {
    # Check if wildcard already exists
    $wildcardExists = $false
    $entries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $wildcardExists = $true
            Write-Host "Wildcard already exists in blocklist at index $($prop.Name)" -ForegroundColor Yellow
            break
        }
    }
    
    if (-not $wildcardExists) {
        # Get next available index
        $indices = @()
        $indices = (Get-Item $blocklistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
        $nextIndex = 1
        while ($indices -contains $nextIndex.ToString()) {
            $nextIndex++
        }
        
        Write-Host "Restoring wildcard entry to blocklist at index $nextIndex..." -NoNewline
        try {
            New-ItemProperty -Path $blocklistPath -Name $nextIndex -Value "*" -PropertyType String -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Creating blocklist path..." -NoNewline
    try {
        New-Item -Path $blocklistPath -Force | Out-Null
        New-ItemProperty -Path $blocklistPath -Name "1" -Value "*" -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed: $_" -ForegroundColor Red
    }
}

# 4. Clean up custom policies we may have added
Write-Host "`n=== Cleaning Up Custom Policies ===" -ForegroundColor Cyan

# Check for AllowedLocalExtensionPaths policy
if (Test-Path -Path $chromePoliciesPath) {
    try {
        $hasLocalPaths = Get-ItemProperty -Path $chromePoliciesPath -Name "AllowedLocalExtensionPaths" -ErrorAction SilentlyContinue
        if ($null -ne $hasLocalPaths) {
            Write-Host "Removing AllowedLocalExtensionPaths policy..." -NoNewline
            Remove-ItemProperty -Path $chromePoliciesPath -Name "AllowedLocalExtensionPaths" -Force -ErrorAction SilentlyContinue
            Write-Host "Success!" -ForegroundColor Green
        } else {
            Write-Host "AllowedLocalExtensionPaths not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error checking AllowedLocalExtensionPaths: $_" -ForegroundColor Red
    }
}

# 5. Remove the CRX file
Write-Host "`n=== Cleaning Up Extension Files ===" -ForegroundColor Cyan
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"
if (Test-Path -Path $crxPath) {
    Write-Host "Removing CRX file..." -NoNewline
    try {
        Remove-Item -Path $crxPath -Force -ErrorAction SilentlyContinue
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed: $_" -ForegroundColor Red
    }
}

# Check if directory is empty and remove it
$dirPath = "C:\Program Files\GenesysPOC"
if (Test-Path -Path $dirPath) {
    $items = Get-ChildItem -Path $dirPath -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        Write-Host "Removing empty directory..." -NoNewline
        try {
            Remove-Item -Path $dirPath -Force -ErrorAction SilentlyContinue
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Directory not empty, keeping it" -ForegroundColor Yellow
    }
}

# Verify changes
Write-Host "`n=== Verifying Changes ===" -ForegroundColor Cyan

# Verify extension removed from allowlist
$extensionInAllowlist = $false
if (Test-Path -Path $allowlistPath) {
    $entries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $ExtensionId) {
            $extensionInAllowlist = $true
            Write-Host "Extension still found in allowlist at index $($prop.Name)" -ForegroundColor Red
        }
    }
}

if (-not $extensionInAllowlist) {
    Write-Host "Extension successfully removed from allowlist" -ForegroundColor Green
}

# Verify wildcard in blocklist
$wildcardInBlocklist = $false
if (Test-Path -Path $blocklistPath) {
    $entries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $wildcardInBlocklist = $true
            Write-Host "Wildcard successfully restored to blocklist at index $($prop.Name)" -ForegroundColor Green
        }
    }
}

if (-not $wildcardInBlocklist) {
    Write-Host "Warning: Wildcard not found in blocklist" -ForegroundColor Red
}

# Final instructions
Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Close ALL Chrome instances completely"
Write-Host "3. Restart Chrome to apply corporate policies"

Write-Host "`nPolicy restoration log saved to: $logFile"
Stop-Transcript 