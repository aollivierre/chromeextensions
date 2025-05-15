#
# Enable-LocalExtensions-Edge.ps1
# Menu-based solution for enabling local Microsoft Edge extensions with --load-extension
#

param(
    [string]$ExtensionPath = "C:\\Program Files\\GenesysPOC\\EdgeExtension" # Default path for Edge extensions
)

# Create log file
$logFile = "$env:TEMP\\EnableLocalExtensionsEdge_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Local Edge Extension Configuration - $(Get-Date)"

# Registry paths for Microsoft Edge
$edgePoliciesPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge"
$blocklistPath = "$edgePoliciesPath\\ExtensionInstallBlocklist"

function Remove-WildcardFromBlocklist {
    Write-Host "`n=== REMOVING WILDCARD FROM EDGE EXTENSION BLOCKLIST ===" -ForegroundColor Cyan
    Write-Host "This step removes the wildcard (*) from Edge's extension blocklist."
    Write-Host "The wildcard blocks ALL extensions, including local ones."
    
    if (Test-Path -Path $blocklistPath) {
        $wildcardFound = $false
        $wildcardIndex = $null
        
        # Check for wildcard in blocklist
        $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
        if ($null -ne $blocklistEntries) {
            foreach ($prop in $blocklistEntries.PSObject.Properties) {
                if ($prop.Name -match '^\\d+$' -and $prop.Value -eq "*") {
                    $wildcardIndex = $prop.Name
                    $wildcardFound = $true
                    Write-Host "Found wildcard (*) at index $wildcardIndex - this blocks ALL extensions" -ForegroundColor Red
                    break
                }
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
    
    Write-Host "Setting Edge Policy: $PolicyName..." -NoNewline
    try {
        # Create policies key if it doesn't exist
        if (-not (Test-Path -Path $edgePoliciesPath)) {
            New-Item -Path $edgePoliciesPath -Force | Out-Null
            Write-Host "Created Edge Policies registry key." -ForegroundColor Green
        }
    
        New-ItemProperty -Path $edgePoliciesPath -Name $PolicyName -Value $Value -PropertyType $PropertyType -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Enable-DeveloperMode {
    Write-Host "`n=== ENABLING EDGE EXTENSION DEVELOPER MODE ===" -ForegroundColor Cyan
    Write-Host "This policy allows Edge to load unpacked extensions."
    # For Edge, DeveloperToolsAvailability = 1 allows developer tools and unpacked extensions.
    # A value of 2 disallows developer tools and unpacked extensions.
    Write-Host "Required Policy: DeveloperToolsAvailability = 1"
    
    SetPolicy -PolicyName "DeveloperToolsAvailability" -Value 1 -PropertyType "DWORD"
}

function Set-AllowedExtensionPaths {
    Write-Host "`n=== SETTING ALLOWED EDGE EXTENSION SOURCES ===" -ForegroundColor Cyan
    Write-Host "This policy tells Edge which paths are allowed for loading local extensions."
    # Edge uses ExtensionInstallSources and expects file URLs like file:///C:/path/*
    # It also expects a REG_MULTI_SZ (StringArray)
    $formattedPath = "file:///$($ExtensionPath.Replace('\\', '/'))/*"
    Write-Host "Required Policy: ExtensionInstallSources = $formattedPath"
    
    SetPolicy -PolicyName "ExtensionInstallSources" -Value $formattedPath -PropertyType "String" # Will be treated as StringArray if one item
}

function Add-ExtensionToAllowlist {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExtensionId = "extension_id_placeholder" # Placeholder for Edge extension ID
    )
    
    Write-Host "`n=== ADDING EXTENSION TO EDGE ALLOWLIST ===" -ForegroundColor Cyan
    Write-Host "This adds your extension to the allowlist, permitting it to run even with wildcard blocklist"
    Write-Host "Policy: ExtensionInstallAllowlist (for Edge)"
    Write-Host "NOTE: This works best for Edge Add-ons store extensions and packaged CRX files." -ForegroundColor Yellow
    Write-Host "      For local unpacked extensions, this may or may not work depending on how Edge" -ForegroundColor Yellow
    Write-Host "      processes the extension ID for unpacked extensions." -ForegroundColor Yellow
    
    $allowlistPath = "$edgePoliciesPath\\ExtensionInstallAllowlist"
    
    # Create allowlist key if it doesn't exist
    if (-not (Test-Path -Path $allowlistPath)) {
        Write-Host "Creating allowlist registry key for Edge..." -NoNewline
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
        if ($null -ne $allowlistEntries) {
            foreach ($prop in $allowlistEntries.PSObject.Properties) {
                if ($prop.Name -match '^\\d+$') {
                    $index = [int]$prop.Name
                    if ($index -ge $nextIndex) {
                        $nextIndex = $index + 1
                    }
                    
                    # Check if extension ID is already in the allowlist
                    if ($prop.Value -eq $ExtensionId) {
                        Write-Host "Extension ID $ExtensionId is already in the Edge allowlist at index $($prop.Name)" -ForegroundColor Green
                        return $true
                    }
                }
            }
        }
    }
    
    # Add extension ID to allowlist
    Write-Host "Adding extension ID $ExtensionId to Edge allowlist at index $nextIndex..." -NoNewline
    try {
        New-ItemProperty -Path $allowlistPath -Name $nextIndex -Value $ExtensionId -PropertyType "String" -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "Your extension should now be allowed in Edge even with the wildcard blocklist" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Set-MixedBlockAllowApproach {
    Write-Host "`n=== CONFIGURING MIXED BLOCK/ALLOW APPROACH FOR EDGE ===" -ForegroundColor Cyan
    Write-Host "This uses a combination of policies to try allowing local extensions while keeping the wildcard block"
    Write-Host "This is an experimental approach that may work in some environments for Edge"
    
    # 1. First ensure developer mode is allowed
    Write-Host "`nStep 1: Enable developer mode for Edge"
    Enable-DeveloperMode
    
    # 2. Set specific allowed local extension paths
    Write-Host "`nStep 2: Set allowed local extension sources for Edge"
    Set-AllowedExtensionPaths # This already sets ExtensionInstallSources
        
    # 3. Try setting ExtensionSettings policy (Edge also supports this)
    # This is a more granular approach that might allow local extensions to override the blocklist
    Write-Host "`nStep 3: Configuring ExtensionSettings policy for Edge..." -NoNewline
    
    try {
        # Create ExtensionSettings key if it doesn't exist
        $extensionSettingsPath = "$edgePoliciesPath\\ExtensionSettings"
        if (-not (Test-Path -Path $extensionSettingsPath)) {
            New-Item -Path $extensionSettingsPath -Force | Out-Null
        }
        
        # Create '*' key for default settings
        $wildcardPathKey = "$extensionSettingsPath\\*" # Registry keys cannot contain '*' directly in the path, use a placeholder or encoded value if needed
                                                     # For simplicity, we'll assume '*' is a valid subkey name for policy processing by Edge.
                                                     # If this fails, a specific ID or a general policy might be needed.
        if (-not (Test-Path -Path $wildcardPathKey)) {
            New-Item -Path $wildcardPathKey -Force | Out-Null
        }
        
        # Set the installation_mode to blocked by default (like blocklist)
        New-ItemProperty -Path $wildcardPathKey -Name "installation_mode" -Value "blocked" -PropertyType "String" -Force | Out-Null
        
        # Create key for allowed local extension path pattern
        # For Edge, this would typically be the extension ID or an update URL pattern from ExtensionInstallSources
        # Using the direct path here for ExtensionSettings might not work as expected for unpacked extensions.
        # It's usually <extension_id_or_update_url_pattern>
        # Let's use the ExtensionPath for consistency, but note its limitations for unpacked extensions in ExtensionSettings
        $localExtensionsKeyName = $ExtensionPath.Replace('\', '_').Replace(':', '') # Sanitize path for key name
        $localExtensionsPolicyPath = "$extensionSettingsPath\\$localExtensionsKeyName"

        if (-not (Test-Path -Path $localExtensionsPolicyPath -ErrorAction SilentlyContinue)) {
            New-Item -Path $localExtensionsPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        
        # Set the installation_mode to allowed for local extensions
        New-ItemProperty -Path $localExtensionsPolicyPath -Name "installation_mode" -Value "allowed" -PropertyType "String" -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $localExtensionsPolicyPath -Name "update_url" -Value "file:///$($ExtensionPath.Replace('\\','/'))/*" -PropertyType "String" -Force -ErrorAction SilentlyContinue | Out-Null


        Write-Host "Success!" -ForegroundColor Green
        Write-Host "ExtensionSettings policy configured for Edge (more granular than blocklist/allowlist)" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "This policy may not be supported or configured correctly for Edge" -ForegroundColor Yellow
    }
    
    Write-Host "`nMixed approach configuration complete for Edge. This creates a more granular policy structure"
    Write-Host "that might allow local extensions while maintaining the wildcard block."
    Write-Host "Note: This is experimental and may not work in all environments for Edge." -ForegroundColor Yellow
}

function Create-ExtensionDirectory {
    Write-Host "`n=== CREATING EDGE EXTENSION DIRECTORY ===" -ForegroundColor Cyan
    Write-Host "Creating directory for local Edge extensions at: $ExtensionPath"
    
    if (-not (Test-Path -Path $ExtensionPath)) {
        Write-Host "Edge extension directory does not exist. Creating it..." -NoNewline
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
        Write-Host "Edge extension directory exists at: $ExtensionPath" -ForegroundColor Green
        return $true
    }
}

function CheckPolicy {
    param (
        [string]$PolicyName,
        [object]$ExpectedValue,
        [string]$RegistryPath = $edgePoliciesPath # Default to Edge policies path
    )
    
    try {
        $item = Get-ItemProperty -Path $RegistryPath -Name $PolicyName -ErrorAction SilentlyContinue
        if ($null -ne $item -and $null -ne $item.$PolicyName) {
            $currentValue = $item.$PolicyName
            # Handle StringArray (REG_MULTI_SZ) for ExtensionInstallSources
            if ($PolicyName -eq "ExtensionInstallSources" -and $currentValue -is [array]) {
                # If expected is a single string, check if it's in the array
                if ($ExpectedValue -is [string] -and $currentValue -contains $ExpectedValue) {
                    Write-Host "Verified: $PolicyName contains $($ExpectedValue)" -ForegroundColor Green
                    return $true
                } elseif ($ExpectedValue -is [array]) {
                    # If expected is an array, check for exact match (order doesn't matter for this check)
                    $match = $true
                    if ($currentValue.Count -ne $ExpectedValue.Count) {
                        $match = $false
                    } else {
                        foreach ($val in $ExpectedValue) {
                            if ($currentValue -notcontains $val) {
                                $match = $false
                                break
                            }
                        }
                    }
                    if ($match) {
                        Write-Host "Verified: $PolicyName = $($currentValue -join ', ')" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "WARNING: $PolicyName = $($currentValue -join ', ') (Expected: $($ExpectedValue -join ', '))" -ForegroundColor Red
                        return $false
                    }
                }
            } elseif ($currentValue -eq $ExpectedValue) {
                Write-Host "Verified: $PolicyName = $currentValue" -ForegroundColor Green
                return $true
            } else {
                Write-Host "WARNING: $PolicyName = $currentValue (Expected: $ExpectedValue)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "WARNING: Edge Policy $PolicyName not found at $RegistryPath" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error checking Edge Policy $PolicyName $_" -ForegroundColor Red
        return $false
    }
    return $false # Fallback if not verified
}

function Verify-AllPolicies {
    Write-Host "`n=== VERIFYING ALL EDGE POLICIES ===" -ForegroundColor Cyan
    Write-Host "Checking all required Edge policies are correctly set"
    
    # Check policy values
    $policiesVerified = $true
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "DeveloperToolsAvailability" -ExpectedValue 1)
    
    # For ExtensionInstallSources, format the expected value as it was set
    $formattedPath = "file:///$($ExtensionPath.Replace('\\', '/'))/*"
    $policiesVerified = $policiesVerified -and (CheckPolicy -PolicyName "ExtensionInstallSources" -ExpectedValue $formattedPath) # Expects a string, CheckPolicy handles array if needed
    
    # BlockExternalExtensions is not a direct equivalent in Edge, relies on allow/block lists and sources.
    # So we don't verify it directly here.
    
    if ($policiesVerified) {
        Write-Host "All essential Edge policies appear to be correctly set!" -ForegroundColor Green
    } else {
        Write-Host "Some Edge policies are not set correctly or are missing. Please review the warnings above." -ForegroundColor Red
    }
}

function Verify-BlocklistWildcard {
    Write-Host "`n=== CHECKING EDGE BLOCKLIST FOR WILDCARD ===" -ForegroundColor Cyan
    Write-Host "Verifying the Edge extension blocklist doesn't contain a wildcard (*) that would block ALL extensions"
    
    # Check if wildcard was removed
    $wildcardStillBlocking = $false
    if (Test-Path $blocklistPath) {
        $blocklistEntries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
        if ($null -ne $blocklistEntries) {
            foreach ($prop in $blocklistEntries.PSObject.Properties) {
                if ($prop.Name -match '^\\d+$' -and $prop.Value -eq "*") {
                    $wildcardStillBlocking = $true
                    Write-Host "WARNING: Wildcard still in Edge blocklist at index $($prop.Name)" -ForegroundColor Red
                    break
                }
            }
        }
    }

    if (-not $wildcardStillBlocking) {
        Write-Host "Verified: No wildcard blocking in Edge blocklist" -ForegroundColor Green
    }
}

function Show-NextSteps {
    Write-Host "`n=== NEXT STEPS (FOR EDGE) ===" -ForegroundColor Cyan
    Write-Host "After configuring policies, follow these steps:" -ForegroundColor Yellow
    Write-Host "1. Run 'gpupdate /force' to refresh policies (if domain joined, or restart PC for local policies)" -ForegroundColor Yellow
    Write-Host "2. Close ALL Microsoft Edge instances completely (check Task Manager to be sure: msedge.exe)" -ForegroundColor Yellow
    Write-Host "3. Launch Microsoft Edge with the --load-extension parameter:" -ForegroundColor Yellow
    Write-Host "   msedge.exe --load-extension=""$ExtensionPath""" -ForegroundColor Yellow
    Write-Host "   (Ensure msedge.exe is in your PATH or provide the full path to it)"
}

function Run-AllSteps {
    Write-Host "`n=== RUNNING ALL EDGE CONFIGURATION STEPS ===" -ForegroundColor Cyan
    Write-Host "This will perform all necessary steps to enable local Edge extensions"
    
    # 1. Remove wildcard from blocklist
    Remove-WildcardFromBlocklist
    
    # 2. Set all required policies
    Enable-DeveloperMode
    Set-AllowedExtensionPaths
    # Disable-ExternalExtensionBlocking - This function is removed as it's not directly applicable to Edge in the same way.
    
    # 3. Create extension directory
    Create-ExtensionDirectory
    
    # 4. Verify configuration
    Verify-BlocklistWildcard
    Verify-AllPolicies
    
    # 5. Show next steps
    Show-NextSteps
    
    Write-Host "`n=== ALL EDGE STEPS COMPLETED ===" -ForegroundColor Green
}

function Restore-WorkingState {
    Write-Host "`n=== EMERGENCY RESTORE - REVERTING EXPERIMENTAL EDGE CHANGES ===" -ForegroundColor Red
    Write-Host "This will remove Edge ExtensionSettings policy and restore the previous working configuration"
    
    # 1. First remove ExtensionSettings key and all subkeys (cleanup from experimental approach)
    $extensionSettingsPath = "$edgePoliciesPath\\ExtensionSettings"
    if (Test-Path -Path $extensionSettingsPath) {
        Write-Host "`nRemoving Edge ExtensionSettings policy..." -NoNewline
        try {
            Remove-Item -Path $extensionSettingsPath -Recurse -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Edge ExtensionSettings policy not found. No action needed." -ForegroundColor Green
    }
    
    # 2. Make sure the wildcard is removed from blocklist (restore to working state)
    Write-Host "`nChecking Edge blocklist for wildcard..."
    Remove-WildcardFromBlocklist
    
    # 3. Ensure base policies are set correctly
    Write-Host "`nRestoring essential Edge policies..."
    Enable-DeveloperMode
    Set-AllowedExtensionPaths
    # Disable-ExternalExtensionBlocking - Removed
    
    Write-Host "`n=== EDGE RESTORE COMPLETE ===" -ForegroundColor Green
    Write-Host "Your Edge configuration should now be back to a working state." -ForegroundColor Green
    Write-Host "Please try option 1 (Remove Wildcard) and the policy options again if needed." -ForegroundColor Yellow
}

function Add-ExtensionToForcelist {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExtensionId = "extension_id_placeholder" # Placeholder for Edge Extension ID
    )
    
    # Edge Forcelist typically includes the extension ID and an update URL (optional but good practice)
    # Using a generic Edge update service URL as an example. Replace if a specific one is known.
    $ExtensionData = "$ExtensionId;https://edge.microsoft.com/extensionwebstorebase/v1/crx" 
    
    Write-Host "`n=== ADDING EXTENSION TO EDGE FORCELIST ===" -ForegroundColor Cyan
    Write-Host "This force-installs your extension for all users on Edge, and they cannot disable or remove it"
    Write-Host "Policy: ExtensionInstallForcelist (for Edge)"
    Write-Host "Format being used: $ExtensionData" -ForegroundColor Yellow
    
    $forcelistPath = "$edgePoliciesPath\\ExtensionInstallForcelist"
    
    # Create forcelist key if it doesn't exist
    if (-not (Test-Path -Path $forcelistPath)) {
        Write-Host "Creating Edge forcelist registry key..." -NoNewline
        try {
            New-Item -Path $forcelistPath -Force | Out-Null
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Find next available index
    $existingProperties = @()
    if (Test-Path $forcelistPath) {
        $item = Get-Item -Path $forcelistPath -ErrorAction SilentlyContinue
        if ($null -ne $item) {
            $existingProperties = $item.Property
        }
    }
    
    $IDOnly = $ExtensionId.Split(';')[0]  # Extract just the ID part
    
    # Check if extension is already in the forcelist
    foreach ($property in $existingProperties) {
        # Property names are the indices, values are the extension data string
        $currentEntry = Get-ItemProperty -Path $forcelistPath -Name $property -ErrorAction SilentlyContinue
        if ($null -ne $currentEntry -and ($currentEntry.$property -like "$IDOnly*")) {
            Write-Host "Extension ID $IDOnly is already in the Edge forcelist at index $property" -ForegroundColor Green
            return $true
        }
    }
    
    # Find next available index (numeric property name)
    $Index = 1
    if ($existingProperties.Count -gt 0) {
        $usedIndices = $existingProperties | Where-Object { $_ -match '^\\d+$' } | ForEach-Object { [int]$_ }
        if ($usedIndices.Count -gt 0) {
            $Index = ($usedIndices | Measure-Object -Maximum).Maximum + 1
        }
    }
    
    # Add extension to forcelist
    Write-Host "Adding extension to Edge forcelist at index $Index..." -NoNewline
    try {
        New-ItemProperty -Path $forcelistPath -Name $Index.ToString() -Value $ExtensionData -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "Your extension will be force-installed in Edge for all users and they cannot remove it" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

function Get-ExtensionFriendlyName {
    param (
        [string]$ExtensionId,
        [bool]$UseCachedNames = $true
    )
    
    # Fallback for known extension IDs (Update these if they are different for Edge)
    if ($ExtensionId -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or 
        $ExtensionId -eq "mblicpebpihkjnkhjaplnbhehjoclneg") { # These are Chrome IDs, likely different for Edge
        return "Genesys DR Environment Indicator (ID: $ExtensionId - Verify Edge ID)" # Placeholder
    }
    
    # Return just the ID without web lookup to avoid slowness if not using cache or web fetch fails
    if (-not $UseCachedNames) {
        return "Edge Extension $ExtensionId"
    }
    
    # Check for cached name in registry (use an Edge specific path)
    $cachePath = "HKCU:\\Software\\GenesysDR\\EdgeExtensionCache"
    if (Test-Path "$cachePath\\$ExtensionId") {
        try {
            $cachedValue = Get-ItemProperty -Path "$cachePath\\$ExtensionId" -Name "Name" -ErrorAction SilentlyContinue
            if ($null -ne $cachedValue -and $cachedValue.Name) {
                return $cachedValue.Name
            }
        } catch {
            # Continue if cache read fails
        }
    }

    # If we get here, no cached value exists, so fetch it from web using WebClient
    try {
        $url = "https://microsoftedge.microsoft.com/addons/detail/$ExtensionId" # Edge Add-ons store URL
        $webClient = New-Object System.Net.WebClient
        # Some sites require a User-Agent
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36 Edg/90.0.818.51")
        $content = $webClient.DownloadString($url)
        
        $name = "Edge Extension $ExtensionId" # Default if parsing fails
        
        # Title parsing logic for Edge Add-ons store (this may need adjustment)
        # Example: <title>Extension Name - Microsoft Edge Addons</title>
        if ($content -match '<title>(.*?)</title>') {
            $title = $matches[1]
            # Try to clean up " - Microsoft Edge Addons" suffix
            if ($title -match '(.*?)(?:\s*-\s*Microsoft Edge Addons)?$') {
                $name = $matches[1].Trim()
                
                # Save to cache for future use
                if (-not (Test-Path "HKCU:\\Software\\GenesysDR")) {
                    New-Item -Path "HKCU:\\Software\\GenesysDR" -Force | Out-Null
                }
                if (-not (Test-Path $cachePath)) {
                    New-Item -Path $cachePath -Force | Out-Null
                }
                if (-not (Test-Path "$cachePath\\$ExtensionId")) {
                    New-Item -Path "$cachePath\\$ExtensionId" -Force | Out-Null
                }
                New-ItemProperty -Path "$cachePath\\$ExtensionId" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                
                return $name
            }
        }
    } catch {
        # Write-Warning "Failed to fetch extension name for $ExtensionId from Edge Add-ons store: $_"
    }
    
    # Return ID as fallback
    return "Edge Extension $ExtensionId (Not Found/Cached)"
}

function Update-ExtensionNameCache {
    param (
        [string[]]$ExtensionIds
    )
    
    if ($ExtensionIds.Count -eq 0) {
        Write-Host "No Edge extension IDs provided to update cache" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== UPDATING EDGE EXTENSION NAME CACHE ===" -ForegroundColor Cyan
    Write-Host "This will fetch extension names from Microsoft Edge Add-ons Store" -ForegroundColor Yellow
    Write-Host "This may take a moment depending on the number of extensions" -ForegroundColor Yellow
    
    # Create cache directory if it doesn't exist
    $cachePath = "HKCU:\\Software\\GenesysDR\\EdgeExtensionCache"
    if (-not (Test-Path "HKCU:\\Software\\GenesysDR")) {
        New-Item -Path "HKCU:\\Software\\GenesysDR" -Force | Out-Null
    }
    if (-not (Test-Path $cachePath)) {
        New-Item -Path $cachePath -Force | Out-Null
    }
    
    $totalExtensions = $ExtensionIds.Count
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36 Edg/90.0.818.51" # Edge User Agent
    
    # Use parallel processing for 10+ extensions, otherwise use WebClient sequentially
    if ($ExtensionIds.Count -ge 10) {
        Write-Host "Using parallel processing for $totalExtensions Edge extensions..." -ForegroundColor Cyan
        
        $maxThreads = [Math]::Min(10, $totalExtensions)
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads, $sessionState, $Host)
        $runspacePool.Open()
        
        $scriptBlock = {
            param($extensionId, $userAgent)
            
            try {
                # Handle known extensions without web request (Update IDs for Edge if known)
                if ($extensionId -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or $extensionId -eq "mblicpebpihkjnkhjaplnbhehjoclneg") { # CHROME IDs
                    return [PSCustomObject]@{
                        ExtensionId = $extensionId
                        Name = "Genesys DR Environment Indicator (ID: $extensionId - Verify Edge ID)"
                        Success = $true
                    }
                }
                
                $url = "https://microsoftedge.microsoft.com/addons/detail/$extensionId"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", $userAgent)
                $content = $webClient.DownloadString($url)
                
                $name = "Edge Extension $extensionId"
                if ($content -match '<title>(.*?)</title>') {
                    $title = $matches[1]
                    if ($title -match '(.*?)(?:\s*-\s*Microsoft Edge Addons)?$') {
                        $name = $matches[1].Trim()
                    }
                }
                
                return [PSCustomObject]@{
                    ExtensionId = $extensionId
                    Name = $name
                    Success = $true
                }
            }
            catch {
                return [PSCustomObject]@{
                    ExtensionId = $extensionId
                    Name = "Edge Extension $extensionId (Fetch Failed)"
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        $runspaces = @()
        foreach ($idToProcess in $ExtensionIds) { # Renamed variable to avoid conflict
            $powerShell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                extensionId = $idToProcess 
                userAgent = $userAgent
            })
            $powerShell.RunspacePool = $runspacePool
            
            $runspaces += [PSCustomObject]@{
                PowerShell = $powerShell
                Runspace = $powerShell.BeginInvoke()
                ExtensionId = $idToProcess
            }
        }
        
        $completed = 0
        foreach ($runspace in $runspaces) {
            try {
                $result = $runspace.PowerShell.EndInvoke($runspace.Runspace)
                if ($result.Success) {
                    if (-not (Test-Path "$cachePath\\$($result.ExtensionId)")) {
                        New-Item -Path "$cachePath\\$($result.ExtensionId)" -Force | Out-Null
                    }
                    New-ItemProperty -Path "$cachePath\\$($result.ExtensionId)" -Name "Name" -Value $result.Name -PropertyType String -Force | Out-Null
                } else {
                     Write-Warning "Failed to fetch name for $($result.ExtensionId): $($result.Error)"
                }
            }
            catch {
                 Write-Warning "Error processing result for $($runspace.ExtensionId): $_"
            }
            finally {
                $runspace.PowerShell.Dispose()
                $completed++
                $percentage = [math]::Round(($completed / $totalExtensions) * 100)
                Write-Progress -Activity "Fetching Edge extension names" -Status "Processed $completed of $totalExtensions" -PercentComplete $percentage
            }
        }
        
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    else {
        $counter = 0
        foreach ($idToProcess in $ExtensionIds) { # Renamed variable
            $counter++
            $percentage = [math]::Round(($counter / $totalExtensions) * 100)
            Write-Progress -Activity "Fetching Edge extension names" -Status "Processing $counter of $totalExtensions" -PercentComplete $percentage
            
            try {
                if ($idToProcess -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or $idToProcess -eq "mblicpebpihkjnkhjaplnbhehjoclneg") { # CHROME IDs
                    $name = "Genesys DR Environment Indicator (ID: $idToProcess - Verify Edge ID)"
                    if (-not (Test-Path "$cachePath\\$idToProcess")) { New-Item -Path "$cachePath\\$idToProcess" -Force | Out-Null }
                    New-ItemProperty -Path "$cachePath\\$idToProcess" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                    continue
                }
                
                $url = "https://microsoftedge.microsoft.com/addons/detail/$idToProcess"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", $userAgent)
                $content = $webClient.DownloadString($url)
                
                $name = "Edge Extension $idToProcess"
                if ($content -match '<title>(.*?)</title>') {
                    $title = $matches[1]
                    if ($title -match '(.*?)(?:\s*-\s*Microsoft Edge Addons)?$') {
                        $name = $matches[1].Trim()
                    } else {
                        $name = $title.Trim() # Fallback if specific suffix not found
                    }
                    
                    if (-not (Test-Path "$cachePath\\$idToProcess")) { New-Item -Path "$cachePath\\$idToProcess" -Force | Out-Null }
                    New-ItemProperty -Path "$cachePath\\$idToProcess" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                }
            } catch {
                Write-Warning "Failed to fetch/cache name for $idToProcess sequentially: $_"
                continue
            }
            Start-Sleep -Milliseconds 100 # Increased delay slightly
        }
    }
    
    Write-Progress -Activity "Fetching Edge extension names" -Completed
    Write-Host "Edge extension name cache updated successfully" -ForegroundColor Green
}

function Show-ExtensionAllowList {
    param (
        [switch]$UpdateNames
    )
    
    Write-Host "`n=== EDGE EXTENSIONS IN ALLOWLIST ===" -ForegroundColor Cyan
    Write-Host "These extensions can be installed by users in Edge despite the wildcard blocklist"
    Write-Host "Registry: [$edgePoliciesPath\\ExtensionInstallAllowlist]" -ForegroundColor DarkGray
    
    $allowlistRegPath = "$edgePoliciesPath\\ExtensionInstallAllowlist" # Use specific var
    
    if (-not (Test-Path -Path $allowlistRegPath)) {
        Write-Host "Edge Allowlist does not exist. No extensions are specifically allowed." -ForegroundColor Yellow
        return
    }
    
    # More robust way to read registry values, especially if names are numeric
    $regKeyItem = Get-Item -Path $allowlistRegPath -ErrorAction SilentlyContinue
    if ($null -eq $regKeyItem) {
        Write-Host "Edge Allowlist key found, but could not be read or is empty." -ForegroundColor Yellow
        return
    }

    $valueNames = $regKeyItem.GetValueNames()
    if ($null -eq $valueNames -or $valueNames.Count -eq 0) {
        Write-Host "No extensions found in the Edge allowlist (key exists but has no values)." -ForegroundColor Yellow
        return
    }
    
    $hasEntries = $false
    $sortedEntries = @()
    $extensionIdsToUpdate = @() 

    foreach ($valueName in $valueNames) {
        # Filter for names that are purely numeric, as per policy structure (e.g., "1", "2")
        if ($valueName -match '^\d+$') {
            $hasEntries = $true
            $extensionId = $regKeyItem.GetValue($valueName)
            $extensionIdsToUpdate += $extensionId
            $friendlyName = Get-ExtensionFriendlyName -ExtensionId $extensionId -UseCachedNames $true
            $sortedEntries += [PSCustomObject]@{
                Index = [int]$valueName # The numeric name is the index
                ExtensionId = $extensionId
                FriendlyName = $friendlyName
            }
        }
    }
    
    if (-not $hasEntries) {
        Write-Host "No validly numbered extension entries found in the Edge allowlist." -ForegroundColor Yellow
        return
    }

    if ($UpdateNames -and $extensionIdsToUpdate.Count -gt 0) {
        Update-ExtensionNameCache -ExtensionIds $extensionIdsToUpdate
        foreach ($entry in $sortedEntries) {
            $entry.FriendlyName = Get-ExtensionFriendlyName -ExtensionId $entry.ExtensionId -UseCachedNames $true # Refresh from cache
        }
    }
    
    $sortedEntries = $sortedEntries | Sort-Object -Property Index
    
    foreach ($entry in $sortedEntries) {
        Write-Host "`nIndex: $($entry.Index)" -ForegroundColor White
        Write-Host "  Name: $($entry.FriendlyName)" -ForegroundColor Magenta
        Write-Host "  Extension ID: $($entry.ExtensionId)" -ForegroundColor Green
        Write-Host "  Edge Add-ons Store: https://microsoftedge.microsoft.com/addons/detail/$($entry.ExtensionId)" -ForegroundColor DarkGray
    }
    
    # (Rest of the function remains the same for user interaction - R, U, X options)
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "R: Remove an extension from Edge Allowlist" -ForegroundColor White
    Write-Host "U: Update Edge extension names (slow, requires internet)" -ForegroundColor White
    Write-Host "X: Return to main menu" -ForegroundColor White
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        'R' {
            $indexToRemove = Read-Host "Enter the index number of the Edge extension to remove from allowlist"
            # We need to ensure $indexToRemove is a string that matches one of $valueNames used previously
            if ($indexToRemove -match '^\d+$' -and ($valueNames -contains $indexToRemove)) {
                $extensionToRemoveId = $regKeyItem.GetValue($indexToRemove)
                $friendlyNameToRemove = Get-ExtensionFriendlyName -ExtensionId $extensionToRemoveId -UseCachedNames $true
                try {
                    Remove-ItemProperty -Path $allowlistRegPath -Name $indexToRemove -Force
                    Write-Host "Successfully removed Edge extension '$friendlyNameToRemove' ($extensionToRemoveId) from allowlist" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove Edge extension: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid index number for Edge allowlist or extension not found with that index." -ForegroundColor Red
            }
        }
        'U' {
            Show-ExtensionAllowList -UpdateNames # Recursive call
        }
        'X' { # Return to menu
        }
        default {
            Write-Host "Invalid option for Edge allowlist" -ForegroundColor Red
        }
    }
}

function Show-ExtensionForceList {
    param (
        [switch]$UpdateNames
    )
    
    Write-Host "`n=== EDGE EXTENSIONS IN FORCELIST ===" -ForegroundColor Cyan
    Write-Host "These extensions are automatically installed in Edge for all users and cannot be disabled"
    Write-Host "Registry: [$edgePoliciesPath\\ExtensionInstallForcelist]" -ForegroundColor DarkGray
    
    $forcelistRegPath = "$edgePoliciesPath\\ExtensionInstallForcelist" 
    
    if (-not (Test-Path -Path $forcelistRegPath)) {
        Write-Host "Edge Forcelist does not exist. No extensions are being force-installed." -ForegroundColor Yellow
        return
    }
    
    # More robust way to read registry values, especially if names are numeric
    $regKeyItem = Get-Item -Path $forcelistRegPath -ErrorAction SilentlyContinue
    if ($null -eq $regKeyItem) {
        Write-Host "Edge Forcelist key found, but could not be read or is empty." -ForegroundColor Yellow
        return
    }

    $valueNames = $regKeyItem.GetValueNames()
    if ($null -eq $valueNames -or $valueNames.Count -eq 0) {
        Write-Host "No extensions found in the Edge forcelist (key exists but has no values)." -ForegroundColor Yellow
        return
    }
    
    $hasEntries = $false
    $sortedEntries = @()
    $extensionIdsToUpdateForce = @() 

    foreach ($valueName in $valueNames) {
        # Filter for names that are purely numeric, as per policy structure (e.g., "1", "2")
        if ($valueName -match '^\d+$') {
            $hasEntries = $true
            $extensionData = $regKeyItem.GetValue($valueName)
            $extensionIdOnly = $extensionData -replace ';.*', '' # Extract ID part
            $updateUrlInfo = if ($extensionData -match ';(.+)$') { $matches[1] } else { "No update URL specified" }
            
            $extensionIdsToUpdateForce += $extensionIdOnly
            $friendlyName = Get-ExtensionFriendlyName -ExtensionId $extensionIdOnly -UseCachedNames $true
            
            $sortedEntries += [PSCustomObject]@{
                Index = [int]$valueName # The numeric name is the index
                ExtensionId = $extensionIdOnly
                UpdateUrl = $updateUrlInfo
                FriendlyName = $friendlyName
            }
        }
    }
    
    if (-not $hasEntries) {
        Write-Host "No validly numbered extension entries found in the Edge forcelist." -ForegroundColor Yellow
        return
    }

    if ($UpdateNames -and $extensionIdsToUpdateForce.Count -gt 0) {
        Update-ExtensionNameCache -ExtensionIds $extensionIdsToUpdateForce
        foreach ($entry in $sortedEntries) {
            $entry.FriendlyName = Get-ExtensionFriendlyName -ExtensionId $entry.ExtensionId -UseCachedNames $true # Refresh from cache
        }
    }
    
    $sortedEntries = $sortedEntries | Sort-Object -Property Index
    
    foreach ($entry in $sortedEntries) {
        Write-Host "`nIndex: $($entry.Index)" -ForegroundColor White
        Write-Host "  Name: $($entry.FriendlyName)" -ForegroundColor Magenta
        Write-Host "  Extension ID: $($entry.ExtensionId)" -ForegroundColor Green
        Write-Host "  Update URL: $($entry.UpdateUrl)" -ForegroundColor Gray
        Write-Host "  Edge Add-ons Store: https://microsoftedge.microsoft.com/addons/detail/$($entry.ExtensionId)" -ForegroundColor DarkGray
    }
    
    # (Rest of the function remains the same for user interaction - R, U, X options)
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "R: Remove an extension from Edge Forcelist" -ForegroundColor White
    Write-Host "U: Update Edge extension names (slow, requires internet)" -ForegroundColor White
    Write-Host "X: Return to main menu" -ForegroundColor White
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        'R' {
            $indexToRemove = Read-Host "Enter the index number of the Edge extension to remove from forcelist"
            # We need to ensure $indexToRemove is a string that matches one of $valueNames used previously
            if ($indexToRemove -match '^\d+$' -and ($valueNames -contains $indexToRemove)) {
                $extensionDataToRemove = $regKeyItem.GetValue($indexToRemove)
                # $extensionIdOnlyToRemove = $extensionDataToRemove -replace ';.*', '' # Not needed for removal message directly
                $friendlyNameToRemove = Get-ExtensionFriendlyName -ExtensionId ($extensionDataToRemove -replace ';.*', '') -UseCachedNames $true
                try {
                    Remove-ItemProperty -Path $forcelistRegPath -Name $indexToRemove -Force
                    Write-Host "Successfully removed Edge extension '$friendlyNameToRemove' (Index: $indexToRemove) from forcelist" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove Edge extension: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid index number for Edge forcelist or extension not found with that index." -ForegroundColor Red
            }
        }
        'U' {
            Show-ExtensionForceList -UpdateNames # Recursive call
        }
        'X' { # Return to menu
        }
        default {
            Write-Host "Invalid option for Edge forcelist" -ForegroundColor Red
        }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "======= MICROSOFT EDGE LOCAL EXTENSION CONFIGURATION MENU =======" -ForegroundColor Cyan
    Write-Host "Script Log: $logFile" -ForegroundColor DarkGray
    Write-Host "Extension Path: $ExtensionPath" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " REGISTRY BLOCKLIST OPERATIONS (EDGE):" -ForegroundColor Yellow
    Write-Host " 1: Remove wildcard (*) from Edge extension blocklist" -ForegroundColor White
    Write-Host "    [$edgePoliciesPath\\ExtensionInstallBlocklist]" -ForegroundColor DarkGray
    Write-Host " 2: Verify Edge blocklist doesn't contain wildcard" -ForegroundColor White
    Write-Host "    [$edgePoliciesPath\\ExtensionInstallBlocklist]" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " INDIVIDUAL EDGE POLICIES:" -ForegroundColor Yellow
    Write-Host " 3: Enable Edge extension developer mode (DeveloperToolsAvailability = 1)" -ForegroundColor White
    Write-Host "    [$edgePoliciesPath\\DeveloperToolsAvailability]" -ForegroundColor DarkGray
    Write-Host " 4: Set allowed local Edge extension sources (ExtensionInstallSources)" -ForegroundColor White 
    Write-Host "    [$edgePoliciesPath\\ExtensionInstallSources]" -ForegroundColor DarkGray
    # Option 5 (BlockExternalExtensions) removed as it's not a direct Edge equivalent this way.
    Write-Host " 5: Verify all essential Edge policies" -ForegroundColor White # Renumbered
    Write-Host ""
    Write-Host " EMERGENCY OPTION (EDGE):" -ForegroundColor Red
    Write-Host " R: RESTORE - Revert experimental Edge changes (use if option 7 broke things)" -ForegroundColor Red # Renumbered
    Write-Host ""
    Write-Host " EDGE ADD-ONS STORE EXTENSIONS:" -ForegroundColor Yellow
    Write-Host " 6: Add extension to Edge allowlist (users can install)" -ForegroundColor White # Renumbered
    Write-Host "    [$edgePoliciesPath\\ExtensionInstallAllowlist]" -ForegroundColor DarkGray
    Write-Host " L: View and manage Edge allowlist extensions" -ForegroundColor White
    Write-Host " F: Add extension to Edge forcelist (auto-installs for all users)" -ForegroundColor White
    Write-Host "    [$edgePoliciesPath\\ExtensionInstallForcelist]" -ForegroundColor DarkGray
    Write-Host " M: View and manage Edge forcelist extensions" -ForegroundColor White
    Write-Host ""
    Write-Host " EXPERIMENTAL OPTIONS (EDGE):" -ForegroundColor Yellow
    Write-Host " 7: Try mixed block/allow approach for local Edge extensions" -ForegroundColor White # Renumbered
    Write-Host "    [$edgePoliciesPath\\ExtensionSettings]" -ForegroundColor DarkGray
    Write-Host ""  
    Write-Host " OTHER OPERATIONS (EDGE):" -ForegroundColor Yellow
    Write-Host " 8: Create Edge extension directory" -ForegroundColor White # Renumbered
    Write-Host " 9: Show next steps for Edge" -ForegroundColor White # Renumbered
    Write-Host ""
    Write-Host " A: Run ALL Edge steps (complete configuration)" -ForegroundColor Green
    Write-Host " Q: Quit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
}

# Main menu loop
function Start-Menu {
    $menuRunning = $true
    
    while ($menuRunning) {
        Show-Menu
        $choice = Read-Host "Enter your choice for Edge configuration"
        
        switch ($choice.ToUpper()) {
            '1' {
                Remove-WildcardFromBlocklist
            }
            '2' {
                Verify-BlocklistWildcard
            }
            '3' {
                Enable-DeveloperMode
            }
            '4' {
                Set-AllowedExtensionPaths
            }
            '5' { # Was 6
                Verify-AllPolicies
            }
            '6' { # Was 7
                $extensionIdInput = Read-Host "Enter your Edge extension ID (or press Enter to use placeholder '$($Global:ExtensionIdPlaceholder)')"
                if ([string]::IsNullOrWhiteSpace($extensionIdInput)) {
                    Add-ExtensionToAllowlist # Uses default placeholder
                } else {
                    Add-ExtensionToAllowlist -ExtensionId $extensionIdInput
                }
            }
            '7' { # Was 8
                Set-MixedBlockAllowApproach
            }
            '8' { # Was 9
                Create-ExtensionDirectory
            }
            '9' { # Was 0
                Show-NextSteps
            }
            'A' {
                Run-AllSteps
            }
            'Q' {
                $menuRunning = $false
                Write-Host "Exiting Edge Local Extension Configuration menu..." -ForegroundColor Yellow
            }
            'R' { # Was R (Emergency Restore)
                Restore-WorkingState
            }
            'F' { # Add to Forcelist
                $extensionIdInput = Read-Host "Enter your Edge extension ID to add to Forcelist (or press Enter for '$($Global:ExtensionIdPlaceholder)')"
                 if ([string]::IsNullOrWhiteSpace($extensionIdInput)) {
                    Add-ExtensionToForcelist # Uses default placeholder
                } else {
                    Add-ExtensionToForcelist -ExtensionId $extensionIdInput
                }
            }
            'L' { # View Allowlist
                Show-ExtensionAllowList
            }
            'M' { # View Forcelist
                Show-ExtensionForceList
            }
            default {
                Write-Host "Invalid option for Edge. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        # Common pause unless quitting
        if ($choice.ToUpper() -ne 'Q') {
            Write-Host "`nPress any key to return to the Edge menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    }
}

# Global placeholder for readability if user presses enter
$Global:ExtensionIdPlaceholder = "extension_id_placeholder"

# Start the menu
Start-Menu

Write-Host "`nEdge configuration log saved to: $logFile"
Stop-Transcript 