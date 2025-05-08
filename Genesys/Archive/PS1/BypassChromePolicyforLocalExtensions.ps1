# Script to bypass Chrome policies for local extensions
# Enhanced with drift detection, user prompting, and detailed logging

# Add parameter for extension ID
param(
    [string]$CustomExtensionId = ""
)

# Start Transcript for logging
$logPath = "$env:TEMP\ChromePolicyModification_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logPath
Write-Host "Starting Chrome Policy modification script - $(Get-Date)"
Write-Host "Detailed log will be saved to: $logPath"

# Extension path configuration
$extensionPath = "C:\Program Files\GenesysPOC\ChromeExtension"
$manifestPath = Join-Path $extensionPath "manifest.json"
Write-Host "Checking extension at path: $extensionPath"

# Check if a custom extension ID was provided
if (-not [string]::IsNullOrEmpty($CustomExtensionId)) {
    $extensionId = $CustomExtensionId
    Write-Host "Using provided extension ID: $extensionId" -ForegroundColor Green
} else {
    # Verify extension path exists
    if (-not (Test-Path $extensionPath)) {
        Write-Host "WARNING: Extension path does not exist: $extensionPath" -ForegroundColor Yellow
        $createFolder = Read-Host "Do you want to create this folder? (Y/N)"
        if ($createFolder -eq 'Y' -or $createFolder -eq 'y') {
            New-Item -Path $extensionPath -ItemType Directory -Force
            Write-Host "Created extension directory: $extensionPath" -ForegroundColor Green
        } else {
            Write-Host "Extension path is required. Exiting script." -ForegroundColor Red
            Stop-Transcript
            exit
        }
    }

    # Check if manifest.json contains an ID, otherwise use folder name
    $extensionId = $null
    if (Test-Path $manifestPath) {
        Write-Host "Found manifest.json, checking for extension ID"
        try {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            if ($manifest.PSObject.Properties.Name -contains "id") {
                $extensionId = $manifest.id
                Write-Host "Using ID from manifest.json: $extensionId"
            } else {
                Write-Host "No ID found in manifest.json"
            }
        } catch {
            Write-Host "Error reading manifest.json: $_" -ForegroundColor Red
        }
    }

    # If no ID in manifest, use folder name
    if (-not $extensionId) {
        $extensionId = (Get-Item $extensionPath).Name
        Write-Host "Using folder name as ID: $extensionId"
    }
}

# Registry paths
$chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$allowlistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"

# Check if policy paths exist
Write-Host "`nChecking Chrome policy registry paths..."
$pathsExist = $true
if (-not (Test-Path $chromePolicyPath)) {
    Write-Host "Chrome policy path does not exist: $chromePolicyPath" -ForegroundColor Yellow
    $pathsExist = $false
}
if (-not (Test-Path $allowlistPath)) {
    Write-Host "Extension allowlist path does not exist: $allowlistPath" -ForegroundColor Yellow
    $pathsExist = $false
}

if (-not $pathsExist) {
    Write-Host "Required registry paths don't exist. This could indicate Chrome policies are not configured."
    $createPaths = Read-Host "Do you want to create these registry paths? (Y/N)"
    if ($createPaths -eq 'Y' -or $createPaths -eq 'y') {
        if (-not (Test-Path $chromePolicyPath)) {
            New-Item -Path $chromePolicyPath -Force | Out-Null
            Write-Host "Created Chrome policy path: $chromePolicyPath" -ForegroundColor Green
        }
        if (-not (Test-Path $allowlistPath)) {
            New-Item -Path $allowlistPath -Force | Out-Null
            Write-Host "Created Extension allowlist path: $allowlistPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Cannot proceed without required registry paths. Exiting script." -ForegroundColor Red
        Stop-Transcript
        exit
    }
}

# Check current policy states - Drift Detection
Write-Host "`n========== CURRENT POLICY STATE ==========" -ForegroundColor Cyan

# Check if extension is already in allowlist
$extensionInAllowlist = $false
$allowlistEntries = @()
if (Test-Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $extensionId) {
            $extensionInAllowlist = $true
            Write-Host "Extension ID already in allowlist at index: $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}
if (-not $extensionInAllowlist) {
    Write-Host "Extension ID not found in allowlist" -ForegroundColor Yellow
}

# Check Developer Mode policy
$developerModeEnabled = $false
if (Test-Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
    if ($chromePolicy.PSObject.Properties.Name -contains "ExtensionDeveloperModeAllowed" -and $chromePolicy.ExtensionDeveloperModeAllowed -eq 1) {
        $developerModeEnabled = $true
        Write-Host "Developer Mode is already enabled" -ForegroundColor Green
    } else {
        Write-Host "Developer Mode is not enabled" -ForegroundColor Yellow
    }
} else {
    Write-Host "Chrome policy path not found, Developer Mode status unknown" -ForegroundColor Yellow
}

# Check AllowedLocalExtensionPaths policy
$extensionPathAllowed = $false
if (Test-Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
    if ($chromePolicy.PSObject.Properties.Name -contains "AllowedLocalExtensionPaths") {
        $allowedPaths = $chromePolicy.AllowedLocalExtensionPaths
        if ($allowedPaths -is [array] -and $allowedPaths -contains $extensionPath) {
            $extensionPathAllowed = $true
            Write-Host "Extension path is already allowed" -ForegroundColor Green
        } else {
            Write-Host "Extension path is not in allowed paths list" -ForegroundColor Yellow
        }
    } else {
        Write-Host "AllowedLocalExtensionPaths policy not configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "Chrome policy path not found, allowed paths status unknown" -ForegroundColor Yellow
}

# Display proposed changes
Write-Host "`n========== PROPOSED CHANGES ==========" -ForegroundColor Cyan
$changesNeeded = @()

if (-not $extensionInAllowlist) {
    $changesNeeded += "Add extension ID '$extensionId' to the allowlist"
}
if (-not $developerModeEnabled) {
    $changesNeeded += "Enable Developer Mode for extensions"
}
if (-not $extensionPathAllowed) {
    $changesNeeded += "Add '$extensionPath' to AllowedLocalExtensionPaths"
}

if ($changesNeeded.Count -eq 0) {
    Write-Host "No changes needed. All policies are already configured correctly." -ForegroundColor Green
    Write-Host "`nScript complete. No changes made." -ForegroundColor Green
    Stop-Transcript
    exit
} else {
    Write-Host "The following changes will be made:" -ForegroundColor Yellow
    $changesNeeded | ForEach-Object { Write-Host "- $_" }
}

# Prompt for confirmation
$confirmChanges = Read-Host "`nDo you want to proceed with these changes? (Y/N)"
if ($confirmChanges -ne 'Y' -and $confirmChanges -ne 'y') {
    Write-Host "Changes cancelled by user. Exiting script." -ForegroundColor Yellow
    Stop-Transcript
    exit
}

Write-Host "`n========== APPLYING CHANGES ==========" -ForegroundColor Cyan

# Add extension to allowlist if needed
if (-not $extensionInAllowlist) {
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
        New-ItemProperty -Path $allowlistPath -Name $nextIndex -Value $extensionId -PropertyType String -Force | Out-Null
        Write-Host "Success! Added at index $nextIndex" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Enable Developer Mode if needed
if (-not $developerModeEnabled) {
    Write-Host "Enabling ExtensionDeveloperModeAllowed policy..." -NoNewline
    try {
        New-ItemProperty -Path $chromePolicyPath -Name "ExtensionDeveloperModeAllowed" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Add to AllowedLocalExtensionPaths if needed
if (-not $extensionPathAllowed) {
    Write-Host "Adding extension path to AllowedLocalExtensionPaths policy..." -NoNewline
    try {
        # Handle existing paths if any
        $existingPaths = @()
        if (Test-Path $chromePolicyPath) {
            $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
            if ($chromePolicy.PSObject.Properties.Name -contains "AllowedLocalExtensionPaths" -and $chromePolicy.AllowedLocalExtensionPaths) {
                $existingPaths = $chromePolicy.AllowedLocalExtensionPaths
                if ($existingPaths -isnot [array]) {
                    $existingPaths = @($existingPaths)
                }
            }
        }
        
        # Add the new path if not already in the list
        if ($existingPaths -notcontains $extensionPath) {
            $newPaths = $existingPaths + $extensionPath
            New-ItemProperty -Path $chromePolicyPath -Name "AllowedLocalExtensionPaths" -Value $newPaths -PropertyType MultiString -Force | Out-Null
        }
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Verify changes
Write-Host "`n========== VERIFYING CHANGES ==========" -ForegroundColor Cyan
$allChangesSuccessful = $true

# Verify extension in allowlist
$extensionInAllowlist = $false
if (Test-Path $allowlistPath) {
    $allowlistEntries = Get-ItemProperty -Path $allowlistPath
    foreach ($prop in $allowlistEntries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $extensionId) {
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

# Verify Developer Mode policy
$developerModeEnabled = $false
if (Test-Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
    if ($chromePolicy.PSObject.Properties.Name -contains "ExtensionDeveloperModeAllowed" -and $chromePolicy.ExtensionDeveloperModeAllowed -eq 1) {
        $developerModeEnabled = $true
        Write-Host "Verified: Developer Mode is enabled" -ForegroundColor Green
    } else {
        Write-Host "Error: Developer Mode is not enabled after changes" -ForegroundColor Red
        $allChangesSuccessful = $false
    }
}

# Verify AllowedLocalExtensionPaths policy
$extensionPathAllowed = $false
if (Test-Path $chromePolicyPath) {
    $chromePolicy = Get-ItemProperty -Path $chromePolicyPath -ErrorAction SilentlyContinue
    if ($chromePolicy.PSObject.Properties.Name -contains "AllowedLocalExtensionPaths") {
        $allowedPaths = $chromePolicy.AllowedLocalExtensionPaths
        if ($allowedPaths -is [array] -and $allowedPaths -contains $extensionPath) {
            $extensionPathAllowed = $true
            Write-Host "Verified: Extension path is in allowed paths list" -ForegroundColor Green
        } else {
            Write-Host "Error: Extension path not found in allowed paths after changes" -ForegroundColor Red
            $allChangesSuccessful = $false
        }
    } else {
        Write-Host "Error: AllowedLocalExtensionPaths policy not found after changes" -ForegroundColor Red
        $allChangesSuccessful = $false
    }
}

# Final status
if ($allChangesSuccessful) {
    Write-Host "`nAll policy changes successfully applied and verified!" -ForegroundColor Green
    Write-Host "`nPlease restart Chrome completely (close all instances) to apply the new policies."
    Write-Host "Then try loading your extension with the --load-extension parameter."
} else {
    Write-Host "`nWarning: Some policy changes could not be verified." -ForegroundColor Yellow
    Write-Host "Chrome may still block your extension. Check the log file for details."
}

# Stop transcript
Write-Host "`nLog file saved to: $logPath"
Stop-Transcript