#
# SuperCheck-ChromePolicies.ps1
# Comprehensive Chrome policy diagnostic - checks ALL policies that can block extensions
#

# Create log file
$logFile = "$env:TEMP\ChromeSuperCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Policy Super-Check - $(Get-Date)"

# Extension ID to check
$ExtensionId = "idjmoolmcplbkjcldambblbojejkdpij"

# Registry paths
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$allowlistPath = "$chromePoliciesPath\ExtensionInstallAllowlist"
$blocklistPath = "$chromePoliciesPath\ExtensionInstallBlocklist"
$forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"

# Additional policy paths that can cause issues
$userChromePoliciesPath = "HKCU:\SOFTWARE\Policies\Google\Chrome"
$userAllowlistPath = "$userChromePoliciesPath\ExtensionInstallAllowlist"
$userBlocklistPath = "$userChromePoliciesPath\ExtensionInstallBlocklist"

Write-Host "`n========== CHECKING ALL EXTENSION BLOCKING POLICIES ==========" -ForegroundColor Cyan

# Check main Chrome policy settings
function CheckRegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$ExpectedValue = $null,
        [bool]$ExpectedExists = $true,
        [bool]$ExpectedDisabled = $false,
        [string]$Description
    )
    
    Write-Host "Checking: $Description..." -NoNewline
    
    # If path doesn't exist, report and return
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Path not found" -ForegroundColor Yellow
        return $null
    }
    
    try {
        # Try to get the property
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        
        if ($null -eq $value -or $null -eq $value.$Name) {
            if ($ExpectedExists) {
                Write-Host "Missing (Problem!)" -ForegroundColor Red
                return $null
            } else {
                Write-Host "Not set (Good)" -ForegroundColor Green
                return $null
            }
        }
        
        # Value exists, check if it should
        if (-not $ExpectedExists) {
            Write-Host "Set to '$($value.$Name)' (Problem!)" -ForegroundColor Red
            return $value.$Name
        }
        
        # If expecting a specific value
        if ($null -ne $ExpectedValue) {
            if ($value.$Name -eq $ExpectedValue) {
                Write-Host "Set to '$($value.$Name)' (Good)" -ForegroundColor Green
            } else {
                Write-Host "Set to '$($value.$Name)' (Expected: $ExpectedValue) (Problem!)" -ForegroundColor Red
            }
        } else {
            Write-Host "Set to '$($value.$Name)'" -ForegroundColor Cyan
        }
        
        return $value.$Name
    } catch {
        Write-Host "Error checking: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n### Critical Extension Blocking Policies ###" -ForegroundColor Yellow

# Check BlockExternalExtensions (blocks local CRX files)
$blockExternalExtensions = CheckRegistryValue -Path $chromePoliciesPath -Name "BlockExternalExtensions" -ExpectedValue 0 -Description "BlockExternalExtensions"

# Check ExtensionSettings policy (can disable all extensions)
$hasExtensionSettings = CheckRegistryValue -Path $chromePoliciesPath -Name "ExtensionSettings" -ExpectedExists $false -Description "ExtensionSettings (complex policy that can block extensions)"

# Check ExtensionsAllowedTypes (can restrict by type)
$hasExtensionAllowedTypes = CheckRegistryValue -Path $chromePoliciesPath -Name "ExtensionAllowedTypes" -ExpectedExists $false -Description "ExtensionAllowedTypes"

# Check AllowedInstallSites (restricts where extensions can be installed from)
$hasAllowedInstallSites = CheckRegistryValue -Path $chromePoliciesPath -Name "AllowedInstallSites" -ExpectedExists $false -Description "AllowedInstallSites"

# Check RequirePerUserExtensionInstall
$requirePerUserExtensionInstall = CheckRegistryValue -Path $chromePoliciesPath -Name "RequirePerUserExtensionInstall" -ExpectedExists $false -Description "RequirePerUserExtensionInstall"

# Check ExtensionInstallSources (restricts sources)
$hasExtensionInstallSources = CheckRegistryValue -Path $chromePoliciesPath -Name "ExtensionInstallSources" -ExpectedExists $false -Description "ExtensionInstallSources"

# Check developer mode
$developerModeAllowed = CheckRegistryValue -Path $chromePoliciesPath -Name "DeveloperToolsAvailability" -ExpectedValue 1 -Description "DeveloperToolsAvailability"
$extensionDeveloperMode = CheckRegistryValue -Path $chromePoliciesPath -Name "ExtensionDeveloperModeAllowed" -ExpectedValue 1 -Description "ExtensionDeveloperModeAllowed"

Write-Host "`n### Checking Blocklists and Allowlists ###" -ForegroundColor Yellow

# Check if the extension is in the force list
$extensionInForceList = $false
$forcePath = "file:///C:/Program Files/GenesysPOC/GenesysCloudDR.crx"
$forcelistEntries = @()

if (Test-Path -Path $forcelistPath) {
    $entries = Get-ItemProperty -Path $forcelistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            $value = $prop.Value
            $forcelistEntries += $value
            
            # Check if our extension is in the forcelist with correct path
            if ($value -match "^$ExtensionId;") {
                $extensionInForceList = $true
                $forcePath = $value -replace "^$ExtensionId;", ""
                Write-Host "Extension in forcelist with path: $forcePath" -ForegroundColor Green
            }
        }
    }
}

if (-not $extensionInForceList) {
    Write-Host "Extension NOT in forcelist (Problem!)" -ForegroundColor Red
}

# Check wildcard in blocklist (should be gone now)
$wildcardInBlocklist = $false
if (Test-Path -Path $blocklistPath) {
    $entries = Get-ItemProperty -Path $blocklistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $wildcardInBlocklist = $true
            Write-Host "Wildcard (*) still in blocklist at index $($prop.Name) (Problem!)" -ForegroundColor Red
            break
        }
    }
}

if (-not $wildcardInBlocklist) {
    Write-Host "No wildcard in blocklist (Good)" -ForegroundColor Green
}

# Check for user-level policies that might override machine policies
Write-Host "`n### Checking User-Level Policies ###" -ForegroundColor Yellow

$userPoliciesExist = Test-Path -Path $userChromePoliciesPath
if ($userPoliciesExist) {
    Write-Host "User-level Chrome policies exist (could override machine policies)" -ForegroundColor Yellow
    
    # Check user-level blocklist
    if (Test-Path -Path $userBlocklistPath) {
        $entries = Get-ItemProperty -Path $userBlocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $entries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$') {
                if ($prop.Value -eq "*" -or $prop.Value -eq $ExtensionId) {
                    Write-Host "User-level blocklist blocks the extension at index $($prop.Name): $($prop.Value) (Problem!)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "No user-level blocklist found (Good)" -ForegroundColor Green
    }
} else {
    Write-Host "No user-level Chrome policies found (Good)" -ForegroundColor Green
}

# Verify CRX file exists
Write-Host "`n### Checking CRX File ###" -ForegroundColor Yellow
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"
if (Test-Path -Path $crxPath) {
    $crxFile = Get-Item -Path $crxPath
    Write-Host ("CRX file exists at path " + $crxPath + " (Size: " + [math]::Round($crxFile.Length/1KB, 2) + " KB, Last Modified: " + $crxFile.LastWriteTime + ")") -ForegroundColor Green
} else {
    Write-Host ("CRX file NOT found at expected path " + $crxPath + " (Problem!)") -ForegroundColor Red
}

# Check actual registry values of problem policies
Write-Host "`n### Detailed Policy Inspection ###" -ForegroundColor Yellow

function ExportPolicyValues {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path -Path $Path) {
        Write-Host "Examining $Description" -ForegroundColor Cyan
        try {
            $values = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            foreach ($prop in $values.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS') {
                    Write-Host "  - $($prop.Name): $($prop.Value)"
                }
            }
        } catch {
            Write-Host "  Error reading values: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "$Description not found" -ForegroundColor Yellow
    }
}

# Export critical policies with actual values
ExportPolicyValues -Path $chromePoliciesPath -Description "Main Chrome Policies"
ExportPolicyValues -Path $blocklistPath -Description "Extension Blocklist"
ExportPolicyValues -Path $allowlistPath -Description "Extension Allowlist"
ExportPolicyValues -Path $forcelistPath -Description "Extension Forcelist"

# Check if Chrome is currently running
Write-Host "`n### Chrome Process Check ###" -ForegroundColor Yellow
$chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    Write-Host "Chrome is currently running with $($chromeProcesses.Count) processes" -ForegroundColor Yellow
    Write-Host "Chrome must be completely closed for policy changes to take effect" -ForegroundColor Yellow
} else {
    Write-Host "Chrome is not currently running (Good)" -ForegroundColor Green
}

# Recommendations
Write-Host "`n========== RECOMMENDATIONS ==========" -ForegroundColor Cyan

$problems = @()
if ($blockExternalExtensions -eq 1) { $problems += "BlockExternalExtensions is enabled - prevents local CRX files" }
if ($hasExtensionSettings) { $problems += "ExtensionSettings policy exists - could be blocking extensions" }
if ($hasExtensionAllowedTypes) { $problems += "ExtensionAllowedTypes policy exists - could be restricting by type" }
if ($hasAllowedInstallSites) { $problems += "AllowedInstallSites policy exists - could be restricting installation sources" }
if ($requirePerUserExtensionInstall) { $problems += "RequirePerUserExtensionInstall is enabled - requires per-user installation" }
if ($hasExtensionInstallSources) { $problems += "ExtensionInstallSources policy exists - could be restricting sources" }
if ($developerModeAllowed -ne 1) { $problems += "DeveloperToolsAvailability not enabled - may affect extensions" }
if ($extensionDeveloperMode -ne 1) { $problems += "ExtensionDeveloperModeAllowed not enabled - needed for local extensions" }
if (-not $extensionInForceList) { $problems += "Extension not in forcelist" }
if ($wildcardInBlocklist) { $problems += "Wildcard still in blocklist" }
if ($userPoliciesExist) { $problems += "User-level policies exist - could override machine policies" }
if (!(Test-Path -Path $crxPath)) { $problems += "CRX file not found" }

if ($problems.Count -gt 0) {
    Write-Host "Potential problems found:" -ForegroundColor Red
    foreach ($problem in $problems) {
        Write-Host "- $problem" -ForegroundColor Red
    }
    
    Write-Host "`nTry the following steps:" -ForegroundColor Yellow
    
    # BlockExternalExtensions specific fix
    if ($blockExternalExtensions -eq 1) {
        Write-Host "1. Set BlockExternalExtensions to 0:" -ForegroundColor Yellow
        Write-Host "   New-ItemProperty -Path '$chromePoliciesPath' -Name 'BlockExternalExtensions' -Value 0 -PropertyType DWORD -Force"
    }
    
    Write-Host "2. Close ALL Chrome instances (check Task Manager)" -ForegroundColor Yellow
    Write-Host "3. Run 'gpupdate /force' to refresh policies" -ForegroundColor Yellow
    Write-Host "4. Launch Chrome and check chrome://extensions" -ForegroundColor Yellow
    Write-Host "5. Check chrome://policy for any policy conflicts" -ForegroundColor Yellow
} else {
    Write-Host "No obvious problems found. Try these steps:" -ForegroundColor Green
    Write-Host "1. Close ALL Chrome instances (check Task Manager)" -ForegroundColor Yellow
    Write-Host "2. Run 'gpupdate /force' to refresh policies" -ForegroundColor Yellow
    Write-Host "3. Launch Chrome and check chrome://extensions" -ForegroundColor Yellow
}

Write-Host "`nFor advanced debugging, visit chrome://policy in Chrome to see all active policies"
Write-Host "Super-Check log saved to: $logFile"
Stop-Transcript 