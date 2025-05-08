#
# Clean-ChromePolicies.ps1
# Cleans up Chrome policies that are causing extension installation failures
#

param(
    [string]$ExtensionId = "idjmoolmcplbkjcldambblbojejkdpij",
    [switch]$Force = $false
)

# Create log file
$logFile = "$env:TEMP\ChromePolicyCleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Policy Cleanup - $(Get-Date)"

# Registry paths
$allowlistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"
$blocklistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallBlocklist"

# Fix the allowlist issues
Write-Host "`n========== FIXING ALLOWLIST ==========" -ForegroundColor Cyan
if (Test-Path -Path $allowlistPath) {
    Write-Host "Checking allowlist for invalid entries..."
    $invalidEntries = @()
    $validEntries = @()
    
    # Get all allowlist entries
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            $value = $prop.Value
            # Check if the entry is a valid extension ID (32 character alphanumeric)
            if ($value -match '^[a-z0-9]{32}$') {
                Write-Host "Valid entry at index $($prop.Name): $value" -ForegroundColor Green
                $validEntries += @{
                    Index = $prop.Name
                    Value = $value
                }
            } else {
                Write-Host "Invalid entry at index $($prop.Name): $value" -ForegroundColor Red
                $invalidEntries += @{
                    Index = $prop.Name
                    Value = $value
                }
            }
        }
    }
    
    # Remove invalid entries
    if ($invalidEntries.Count -gt 0) {
        Write-Host "`nRemoving invalid entries from allowlist..."
        foreach ($entry in $invalidEntries) {
            Write-Host "Removing $($entry.Value) at index $($entry.Index)..." -NoNewline
            try {
                Remove-ItemProperty -Path $allowlistPath -Name $entry.Index -Force -ErrorAction SilentlyContinue
                Write-Host "Success!" -ForegroundColor Green
            } catch {
                Write-Host "Failed!" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }
    }
    
    # Make sure our extension is in the allowlist
    $extensionInAllowlist = $false
    foreach ($entry in $validEntries) {
        if ($entry.Value -eq $ExtensionId) {
            $extensionInAllowlist = $true
            break
        }
    }
    
    if (-not $extensionInAllowlist) {
        Write-Host "`nAdding $ExtensionId to allowlist..." -NoNewline
        try {
            # Get the next available index
            $indices = @()
            $indices = (Get-Item $allowlistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
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
} else {
    Write-Host "Allowlist registry path not found. Creating it..." -ForegroundColor Yellow
    New-Item -Path $allowlistPath -Force | Out-Null
}

# Handle the blocklist with wildcard
Write-Host "`n========== HANDLING BLOCKLIST ==========" -ForegroundColor Cyan
if (Test-Path -Path $blocklistPath) {
    $wildcardFound = $false
    $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    
    # Check for wildcard in blocklist
    foreach ($prop in $blocklistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $wildcardIndex = $prop.Name
            $wildcardFound = $true
            Write-Host "Found wildcard (*) at index $wildcardIndex - this blocks ALL extensions" -ForegroundColor Red
            break
        }
    }
    
    if ($wildcardFound) {
        # We have two options:
        # 1. Remove the wildcard (allows all extensions)
        # 2. Replace the wildcard with a specific list (more secure)
        
        Write-Host "`nWildcard blocking ALL extensions found. Choose an action:" -ForegroundColor Yellow
        Write-Host "1) Remove wildcard (allows all extensions unless specifically blocked)"
        Write-Host "2) Keep wildcard (requires allowlist for each extension)"
        
        if (-not $Force) {
            $choice = Read-Host "Enter choice (1 or 2)"
        } else {
            $choice = "1"
            Write-Host "Force mode enabled. Automatically choosing option 1."
        }
        
        if ($choice -eq "1") {
            Write-Host "Removing wildcard blocklist entry..." -NoNewline
            try {
                Remove-ItemProperty -Path $blocklistPath -Name $wildcardIndex -Force -ErrorAction SilentlyContinue
                Write-Host "Success!" -ForegroundColor Green
            } catch {
                Write-Host "Failed!" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Keeping wildcard blocklist entry. Make sure your extension is properly allowlisted." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No wildcard blocking found in blocklist. This is good!" -ForegroundColor Green
    }
} else {
    Write-Host "Blocklist registry path not found. This is good - no extensions are blocked." -ForegroundColor Green
}

# Verify changes
Write-Host "`n========== VERIFYING CHANGES ==========" -ForegroundColor Cyan

# Verify extension in allowlist
$extensionInAllowlist = $false
$invalidEntriesRemaining = $false

if (Test-Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            if ($prop.Value -eq $ExtensionId) {
                $extensionInAllowlist = $true
                Write-Host "Verified: Extension ID in allowlist at index: $($prop.Name)" -ForegroundColor Green
            }
            
            if (-not ($prop.Value -match '^[a-z0-9]{32}$')) {
                $invalidEntriesRemaining = $true
                Write-Host "Warning: Invalid entry still in allowlist at index $($prop.Name): $($prop.Value)" -ForegroundColor Yellow
            }
        }
    }
}

if (-not $extensionInAllowlist) {
    Write-Host "Error: Extension not found in allowlist after changes" -ForegroundColor Red
}

# Verify wildcard not in blocklist
$wildcardStillBlocking = $false
if (Test-Path $blocklistPath) {
    $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    foreach ($prop in $blocklistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $wildcardStillBlocking = $true
            Write-Host "Warning: Wildcard still in blocklist at index $($prop.Name)" -ForegroundColor Yellow
            break
        }
    }
}

if (-not $wildcardStillBlocking) {
    Write-Host "Verified: No wildcard blocking in blocklist" -ForegroundColor Green
}

# Final instructions
Write-Host "`n========== NEXT STEPS ==========" -ForegroundColor Cyan
Write-Host "To apply these changes:"
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Close ALL Chrome instances completely"
Write-Host "3. Try installing the extension again"

if ($invalidEntriesRemaining) {
    Write-Host "`nWarning: Some invalid entries remain in the allowlist. If problems persist, run this script again with -Force" -ForegroundColor Yellow
}

if ($wildcardStillBlocking) {
    Write-Host "`nWarning: Wildcard blocking remains active. Your extension will only load if it's properly allowlisted." -ForegroundColor Yellow
}

# Stop transcript
Write-Host "`nCleanup log saved to: $logFile"
Stop-Transcript 