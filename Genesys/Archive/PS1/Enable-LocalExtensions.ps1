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

function Add-ExtensionToForcelist {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExtensionId = "extension_id_placeholder"
    )
    
    # Always include the Chrome Web Store update URL
    $ExtensionData = "$ExtensionId;https://clients2.google.com/service/update2/crx"
    
    Write-Host "`n=== ADDING EXTENSION TO FORCELIST ===" -ForegroundColor Cyan
    Write-Host "This force-installs your extension for all users, and they cannot disable or remove it"
    Write-Host "Policy: ExtensionInstallForcelist"
    Write-Host "Format being used: $ExtensionData" -ForegroundColor Yellow
    
    $forcelistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    
    # Create forcelist key if it doesn't exist
    if (-not (Test-Path -Path $forcelistPath)) {
        Write-Host "Creating forcelist registry key..." -NoNewline
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
    $Extensions = @(Get-Item -Path $forcelistPath).Property
    $IDOnly = $ExtensionId.Split(';')[0]  # Extract just the ID part
    
    # Check if extension is already in the forcelist
    foreach ($property in $Extensions) {
        $existingValue = (Get-ItemProperty -Path $forcelistPath -Name $property).$property
        if ($existingValue -like "$IDOnly*") {
            Write-Host "Extension ID $IDOnly is already in the forcelist at index $property" -ForegroundColor Green
            return $true
        }
    }
    
    # Find next available index
    $Index = 1
    if ($Extensions.Count -gt 0) {
        $usedIndices = $Extensions | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        if ($usedIndices.Count -gt 0) {
            $Index = ($usedIndices | Measure-Object -Maximum).Maximum + 1
        }
    }
    
    # Add extension to forcelist
    Write-Host "Adding extension to forcelist at index $Index..." -NoNewline
    try {
        New-ItemProperty -Path $forcelistPath -Name $Index -Value $ExtensionData -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "Your extension will be force-installed for all users and they cannot remove it" -ForegroundColor Green
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
    
    # Fallback for known extension IDs
    if ($ExtensionId -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or 
        $ExtensionId -eq "mblicpebpihkjnkhjaplnbhehjoclneg") {
        return "Genesys DR Environment Indicator"
    }
    
    # Return just the ID without web lookup to avoid slowness
    if (-not $UseCachedNames) {
        return "Extension $ExtensionId"
    }
    
    # Check for cached name in registry
    $cachePath = "HKCU:\Software\GenesysDR\ExtensionCache"
    if (Test-Path "$cachePath\$ExtensionId") {
        try {
            $cachedValue = Get-ItemProperty -Path "$cachePath\$ExtensionId" -Name "Name" -ErrorAction SilentlyContinue
            if ($cachedValue -and $cachedValue.Name) {
                return $cachedValue.Name
            }
        } catch {
            # Continue if cache read fails
        }
    }

    # If we get here, no cached value exists, so fetch it from web using the faster WebClient method
    try {
        $url = "https://chromewebstore.google.com/detail/$ExtensionId"
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/135.0.0.0 Safari/537.36")
        $content = $webClient.DownloadString($url)
        
        $name = "Extension $ExtensionId"
        
        if ($content -match '<title>(.*?)</title>') {
            $title = $matches[1]
            if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
                $name = $matches[1].Trim()
                
                # Save to cache for future use
                if (-not (Test-Path "HKCU:\Software\GenesysDR")) {
                    New-Item -Path "HKCU:\Software\GenesysDR" -Force | Out-Null
                }
                if (-not (Test-Path $cachePath)) {
                    New-Item -Path $cachePath -Force | Out-Null
                }
                if (-not (Test-Path "$cachePath\$ExtensionId")) {
                    New-Item -Path "$cachePath\$ExtensionId" -Force | Out-Null
                }
                New-ItemProperty -Path "$cachePath\$ExtensionId" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                
                return $name
            }
        }
    } catch {
        # Continue if web fetch fails
    }
    
    # Return ID as fallback
    return "Extension $ExtensionId"
}

function Update-ExtensionNameCache {
    param (
        [string[]]$ExtensionIds
    )
    
    if ($ExtensionIds.Count -eq 0) {
        Write-Host "No extension IDs provided to update cache" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== UPDATING EXTENSION NAME CACHE ===" -ForegroundColor Cyan
    Write-Host "This will fetch extension names from Chrome Web Store" -ForegroundColor Yellow
    Write-Host "This may take a moment depending on the number of extensions" -ForegroundColor Yellow
    
    # Create cache directory if it doesn't exist
    $cachePath = "HKCU:\Software\GenesysDR\ExtensionCache"
    if (-not (Test-Path "HKCU:\Software\GenesysDR")) {
        New-Item -Path "HKCU:\Software\GenesysDR" -Force | Out-Null
    }
    if (-not (Test-Path $cachePath)) {
        New-Item -Path $cachePath -Force | Out-Null
    }
    
    $totalExtensions = $ExtensionIds.Count
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    
    # Use parallel processing for 10+ extensions, otherwise use WebClient sequentially
    if ($ExtensionIds.Count -ge 10) {
        Write-Host "Using parallel processing for $totalExtensions extensions..." -ForegroundColor Cyan
        
        # Initialize runspace pool with max 10 threads
        $maxThreads = [Math]::Min(10, $totalExtensions)
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads, $sessionState, $Host)
        $runspacePool.Open()
        
        $scriptBlock = {
            param($extensionId, $userAgent)
            
            try {
                # Handle known extensions without web request
                if ($extensionId -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or 
                    $extensionId -eq "mblicpebpihkjnkhjaplnbhehjoclneg") {
                    return [PSCustomObject]@{
                        ExtensionId = $extensionId
                        Name = "Genesys DR Environment Indicator"
                        Success = $true
                    }
                }
                
                # Make web request using WebClient (faster than Invoke-WebRequest)
                $url = "https://chromewebstore.google.com/detail/$extensionId"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", $userAgent)
                $content = $webClient.DownloadString($url)
                
                $name = "Extension $extensionId"
                
                if ($content -match '<title>(.*?)</title>') {
                    $title = $matches[1]
                    if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
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
                    Name = "Extension $extensionId"
                    Success = $false
                    Error = $_
                }
            }
        }
        
        # Create runspaces for each extension
        $runspaces = @()
        foreach ($extensionId in $ExtensionIds) {
            $powerShell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                extensionId = $extensionId
                userAgent = $userAgent
            })
            $powerShell.RunspacePool = $runspacePool
            
            $runspaces += [PSCustomObject]@{
                PowerShell = $powerShell
                Runspace = $powerShell.BeginInvoke()
                ExtensionId = $extensionId
            }
        }
        
        # Collect results and update cache
        $completed = 0
        foreach ($runspace in $runspaces) {
            try {
                $result = $runspace.PowerShell.EndInvoke($runspace.Runspace)
                if ($result.Success) {
                    # Create extension cache key
                    if (-not (Test-Path "$cachePath\$($result.ExtensionId)")) {
                        New-Item -Path "$cachePath\$($result.ExtensionId)" -Force | Out-Null
                    }
                    New-ItemProperty -Path "$cachePath\$($result.ExtensionId)" -Name "Name" -Value $result.Name -PropertyType String -Force | Out-Null
                }
            }
            catch {
                # Skip if there's an error
                continue
            }
            finally {
                $runspace.PowerShell.Dispose()
                $completed++
                $percentage = [math]::Round(($completed / $totalExtensions) * 100)
                Write-Progress -Activity "Fetching extension names" -Status "Processed $completed of $totalExtensions" -PercentComplete $percentage
            }
        }
        
        # Close the runspace pool
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    else {
        # For smaller batches, use sequential WebClient (still faster than Invoke-WebRequest)
        $counter = 0
        foreach ($extensionId in $ExtensionIds) {
            $counter++
            $percentage = [math]::Round(($counter / $totalExtensions) * 100)
            Write-Progress -Activity "Fetching extension names" -Status "Processing $counter of $totalExtensions" -PercentComplete $percentage
            
            try {
                # Handle known extensions without web request
                if ($extensionId -eq "bekjclbbemboommhkppfcdpeaddfajnm" -or 
                    $extensionId -eq "mblicpebpihkjnkhjaplnbhehjoclneg") {
                    $name = "Genesys DR Environment Indicator"
                    # Create extension cache key
                    if (-not (Test-Path "$cachePath\$extensionId")) {
                        New-Item -Path "$cachePath\$extensionId" -Force | Out-Null
                    }
                    New-ItemProperty -Path "$cachePath\$extensionId" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                    continue
                }
                
                # Make web request using WebClient (faster than Invoke-WebRequest)
                $url = "https://chromewebstore.google.com/detail/$extensionId"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", $userAgent)
                $content = $webClient.DownloadString($url)
                
                if ($content -match '<title>(.*?)</title>') {
                    $title = $matches[1]
                    # Clean up the title (remove "- Chrome Web Store" part)
                    if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
                        $name = $matches[1].Trim()
                    } else {
                        $name = $title.Trim()
                    }
                    
                    # Create extension cache key
                    if (-not (Test-Path "$cachePath\$extensionId")) {
                        New-Item -Path "$cachePath\$extensionId" -Force | Out-Null
                    }
                    New-ItemProperty -Path "$cachePath\$extensionId" -Name "Name" -Value $name -PropertyType String -Force | Out-Null
                }
            } catch {
                # Skip if web request fails
                continue
            }
            
            # Small delay to avoid rate limiting
            Start-Sleep -Milliseconds 50
        }
    }
    
    Write-Progress -Activity "Fetching extension names" -Completed
    Write-Host "Extension name cache updated successfully" -ForegroundColor Green
}

function Show-ExtensionAllowList {
    param (
        [switch]$UpdateNames
    )
    
    Write-Host "`n=== EXTENSIONS IN ALLOWLIST ===" -ForegroundColor Cyan
    Write-Host "These extensions can be installed by users despite the wildcard blocklist"
    Write-Host "[HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist]" -ForegroundColor DarkGray
    
    $allowlistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"
    
    if (-not (Test-Path -Path $allowlistPath)) {
        Write-Host "Allowlist does not exist. No extensions are specifically allowed." -ForegroundColor Yellow
        return
    }
    
    $allowlistItems = Get-ItemProperty -Path $allowlistPath
    $hasEntries = $false
    $sortedEntries = @()
    $extensionIds = @()
    
    # Collect and prepare entries for sorting
    foreach ($prop in $allowlistItems.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            $hasEntries = $true
            $extensionIds += $prop.Value
            # Use cached names by default for fast display
            $friendlyName = Get-ExtensionFriendlyName -ExtensionId $prop.Value -UseCachedNames $true
            $sortedEntries += [PSCustomObject]@{
                Index = [int]$prop.Name
                ExtensionId = $prop.Value
                FriendlyName = $friendlyName
            }
        }
    }
    
    # Update names if requested (this is slow but optional)
    if ($UpdateNames -and $extensionIds.Count -gt 0) {
        Update-ExtensionNameCache -ExtensionIds $extensionIds
        
        # Refresh names from cache
        foreach ($entry in $sortedEntries) {
            $entry.FriendlyName = Get-ExtensionFriendlyName -ExtensionId $entry.ExtensionId -UseCachedNames $true
        }
    }
    
    # Sort entries by index
    $sortedEntries = $sortedEntries | Sort-Object -Property Index
    
    # Display sorted entries with friendly names
    foreach ($entry in $sortedEntries) {
        Write-Host "`nIndex: $($entry.Index)" -ForegroundColor White
        Write-Host "  Name: $($entry.FriendlyName)" -ForegroundColor Magenta
        Write-Host "  Extension ID: $($entry.ExtensionId)" -ForegroundColor Green
        Write-Host "  Chrome Web Store: https://chromewebstore.google.com/detail/$($entry.ExtensionId)" -ForegroundColor DarkGray
    }
    
    if (-not $hasEntries) {
        Write-Host "No extensions found in the allowlist." -ForegroundColor Yellow
        return
    }
    
    # Show options
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "R: Remove an extension" -ForegroundColor White
    Write-Host "U: Update extension names (slow)" -ForegroundColor White
    Write-Host "X: Return to main menu" -ForegroundColor White
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        'R' {
            $indexToRemove = Read-Host "Enter the index number of the extension to remove"
            if ($indexToRemove -match '^\d+$' -and $allowlistItems.$indexToRemove) {
                $extensionToRemove = $allowlistItems.$indexToRemove
                $friendlyName = Get-ExtensionFriendlyName -ExtensionId $extensionToRemove -UseCachedNames $true
                try {
                    Remove-ItemProperty -Path $allowlistPath -Name $indexToRemove -Force
                    Write-Host "Successfully removed extension '$friendlyName' ($extensionToRemove) from allowlist" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove extension: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid index number" -ForegroundColor Red
            }
        }
        'U' {
            # Recursively call with update flag
            Show-ExtensionAllowList -UpdateNames
        }
        'X' {
            # Do nothing, return to main menu
        }
        default {
            Write-Host "Invalid option" -ForegroundColor Red
        }
    }
}

function Show-ExtensionForceList {
    param (
        [switch]$UpdateNames
    )
    
    Write-Host "`n=== EXTENSIONS IN FORCELIST ===" -ForegroundColor Cyan
    Write-Host "These extensions are automatically installed for all users and cannot be disabled"
    Write-Host "[HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist]" -ForegroundColor DarkGray
    
    $forcelistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    
    if (-not (Test-Path -Path $forcelistPath)) {
        Write-Host "Forcelist does not exist. No extensions are being force-installed." -ForegroundColor Yellow
        return
    }
    
    $forcelistItems = Get-ItemProperty -Path $forcelistPath
    $hasEntries = $false
    $sortedEntries = @()
    $extensionIds = @()
    
    # Collect and prepare entries for sorting
    foreach ($prop in $forcelistItems.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            $hasEntries = $true
            
            # Extract extension ID from the value (which may include an update URL)
            $extensionData = $prop.Value
            $extensionId = $extensionData -replace ';.*', ''
            $updateUrl = if ($extensionData -match ';(.+)$') { $matches[1] } else { "No update URL specified" }
            
            $extensionIds += $extensionId
            $friendlyName = Get-ExtensionFriendlyName -ExtensionId $extensionId -UseCachedNames $true
            
            $sortedEntries += [PSCustomObject]@{
                Index = [int]$prop.Name
                ExtensionId = $extensionId
                UpdateUrl = $updateUrl
                FriendlyName = $friendlyName
            }
        }
    }
    
    # Update names if requested (this is slow but optional)
    if ($UpdateNames -and $extensionIds.Count -gt 0) {
        Update-ExtensionNameCache -ExtensionIds $extensionIds
        
        # Refresh names from cache
        foreach ($entry in $sortedEntries) {
            $entry.FriendlyName = Get-ExtensionFriendlyName -ExtensionId $entry.ExtensionId -UseCachedNames $true
        }
    }
    
    # Sort entries by index
    $sortedEntries = $sortedEntries | Sort-Object -Property Index
    
    # Display sorted entries with friendly names
    foreach ($entry in $sortedEntries) {
        Write-Host "`nIndex: $($entry.Index)" -ForegroundColor White
        Write-Host "  Name: $($entry.FriendlyName)" -ForegroundColor Magenta
        Write-Host "  Extension ID: $($entry.ExtensionId)" -ForegroundColor Green
        Write-Host "  Update URL: $($entry.UpdateUrl)" -ForegroundColor Gray
        Write-Host "  Chrome Web Store: https://chromewebstore.google.com/detail/$($entry.ExtensionId)" -ForegroundColor DarkGray
    }
    
    if (-not $hasEntries) {
        Write-Host "No extensions found in the forcelist." -ForegroundColor Yellow
        return
    }
    
    # Show options
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "R: Remove an extension" -ForegroundColor White
    Write-Host "U: Update extension names (slow)" -ForegroundColor White
    Write-Host "X: Return to main menu" -ForegroundColor White
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        'R' {
            $indexToRemove = Read-Host "Enter the index number of the extension to remove"
            if ($indexToRemove -match '^\d+$' -and $forcelistItems.$indexToRemove) {
                $extensionToRemove = $forcelistItems.$indexToRemove
                $extensionId = $extensionToRemove -replace ';.*', ''
                $friendlyName = Get-ExtensionFriendlyName -ExtensionId $extensionId -UseCachedNames $true
                try {
                    Remove-ItemProperty -Path $forcelistPath -Name $indexToRemove -Force
                    Write-Host "Successfully removed extension '$friendlyName' ($extensionId) from forcelist" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove extension: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid index number" -ForegroundColor Red
            }
        }
        'U' {
            # Recursively call with update flag
            Show-ExtensionForceList -UpdateNames
        }
        'X' {
            # Do nothing, return to main menu
        }
        default {
            Write-Host "Invalid option" -ForegroundColor Red
        }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "======= CHROME LOCAL EXTENSION CONFIGURATION MENU =======" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " REGISTRY BLOCKLIST OPERATIONS:" -ForegroundColor Yellow
    Write-Host " 1: Remove wildcard (*) from extension blocklist" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallBlocklist]" -ForegroundColor DarkGray
    Write-Host " 2: Verify blocklist doesn't contain wildcard" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallBlocklist]" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " INDIVIDUAL CHROME POLICIES:" -ForegroundColor Yellow
    Write-Host " 3: Enable Chrome extension developer mode" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionDeveloperModeAllowed = 1]" -ForegroundColor DarkGray
    Write-Host " 4: Set allowed local extension paths" -ForegroundColor White 
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\AllowedLocalExtensionPaths]" -ForegroundColor DarkGray
    Write-Host " 5: Disable external extension blocking" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\BlockExternalExtensions = 0]" -ForegroundColor DarkGray
    Write-Host " 6: Verify all Chrome policies" -ForegroundColor White
    Write-Host ""
    Write-Host " EMERGENCY OPTION:" -ForegroundColor Red
    Write-Host " R: RESTORE - Revert experimental changes (use if option 8 broke things)" -ForegroundColor Red
    Write-Host ""
    Write-Host " CHROME WEB STORE EXTENSIONS:" -ForegroundColor Yellow
    Write-Host " 7: Add extension to allowlist (users can install if they want)" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist]" -ForegroundColor DarkGray
    Write-Host " L: View and manage allowlist extensions" -ForegroundColor White
    Write-Host " F: Add extension to forcelist (auto-installs for all users)" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist]" -ForegroundColor DarkGray
    Write-Host " M: View and manage forcelist extensions" -ForegroundColor White
    Write-Host ""
    Write-Host " EXPERIMENTAL OPTIONS:" -ForegroundColor Yellow
    Write-Host " 8: Try mixed block/allow approach (for local extensions)" -ForegroundColor White
    Write-Host "    [HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings]" -ForegroundColor DarkGray
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
            'F' {
                $extensionId = Read-Host "Enter your extension ID (or press Enter to use placeholder)"
                Add-ExtensionToForcelist -ExtensionId $extensionId
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            'L' {
                Show-ExtensionAllowList
                Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            'M' {
                Show-ExtensionForceList
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