# Advanced Chrome Extension Policy Diagnostic
# Performs a comprehensive check of all Chrome policies that could affect extension installation

# Create log file
$logFile = "$env:TEMP\AdvancedChromeDiagnostic_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Advanced Chrome Policy Diagnostic - $(Get-Date)"

# Extension ID to check
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"

# Registry paths - check both machine and user levels
$machinePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$userPoliciesPath = "HKCU:\SOFTWARE\Policies\Google\Chrome"

# Policy paths
$machineAllowlistPath = "$machinePoliciesPath\ExtensionInstallAllowlist"
$machineBlocklistPath = "$machinePoliciesPath\ExtensionInstallBlocklist"
$machineForcelistPath = "$machinePoliciesPath\ExtensionInstallForcelist"
$machineSourcesPath = "$machinePoliciesPath\ExtensionInstallSources"

$userAllowlistPath = "$userPoliciesPath\ExtensionInstallAllowlist"
$userBlocklistPath = "$userPoliciesPath\ExtensionInstallBlocklist" 
$userForcelistPath = "$userPoliciesPath\ExtensionInstallForcelist"
$userSourcesPath = "$userPoliciesPath\ExtensionInstallSources"

# Check for problematic policy values
$problemPolicies = @()
$warningPolicies = @()
$infoPolicies = @()

Write-Host "`n=== CHECKING ALL KNOWN BLOCKING POLICIES ===" -ForegroundColor Cyan

function CheckRegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Description,
        [object]$ExpectedValue = $null,
        [bool]$ExpectedToExist = $true,
        [bool]$IsCritical = $false
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            if ($ExpectedToExist) {
                Write-Host "Path not found: $Path" -ForegroundColor Yellow
                return @{Exists = $false; Value = $null; Problem = $false}
            } else {
                Write-Host "Path not found: $Path (This is good)" -ForegroundColor Green
                return @{Exists = $false; Value = $null; Problem = $false}
            }
        }

        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -eq $item -or $null -eq $item.$Name) {
            if ($ExpectedToExist) {
                Write-Host "$Description not found" -ForegroundColor Yellow
                return @{Exists = $false; Value = $null; Problem = $IsCritical}
            } else {
                Write-Host "$Description not found (This is good)" -ForegroundColor Green
                return @{Exists = $false; Value = $null; Problem = $false}
            }
        } else {
            $value = $item.$Name
            if ($null -ne $ExpectedValue) {
                if ($value -eq $ExpectedValue) {
                    Write-Host "$Description = $value (Correct)" -ForegroundColor Green
                    return @{Exists = $true; Value = $value; Problem = $false}
                } else {
                    Write-Host "$Description = $value (Should be $ExpectedValue)" -ForegroundColor Red
                    return @{Exists = $true; Value = $value; Problem = $true}
                }
            } else {
                Write-Host "$Description = $value" -ForegroundColor Cyan
                return @{Exists = $true; Value = $value; Problem = $false}
            }
        }
    } catch {
        Write-Host "Error checking $Description $_" -ForegroundColor Red
        return @{Exists = $false; Value = $null; Problem = $true; Error = $true}
    }
}

Write-Host "`n### Critical Policies (Machine Level) ###" -ForegroundColor Yellow

# ExtensionSettings - complex policy that can override others
$extSettings = CheckRegistryValue -Path $machinePoliciesPath -Name "ExtensionSettings" -Description "ExtensionSettings policy (can override other policies)" -ExpectedToExist $false
if ($extSettings.Exists) {
    $problemPolicies += "ExtensionSettings policy exists - this can override all other extension settings"
}

# BlockExternalExtensions - blocks drag & drop CRX files
$blockExt = CheckRegistryValue -Path $machinePoliciesPath -Name "BlockExternalExtensions" -Description "BlockExternalExtensions policy" -ExpectedValue 0
if ($blockExt.Exists -and $blockExt.Problem) {
    $problemPolicies += "BlockExternalExtensions = $($blockExt.Value) - This blocks drag & drop of CRX files"
}

# ExtensionInstallBlocklist - check for wildcard
$hasWildcardInMachineBlocklist = $false
if (Test-Path -Path $machineBlocklistPath) {
    $entries = Get-ItemProperty -Path $machineBlocklistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
            $hasWildcardInMachineBlocklist = $true
            Write-Host "ExtensionInstallBlocklist has wildcard (*) at index $($prop.Name) - This blocks ALL extensions" -ForegroundColor Red
            $problemPolicies += "ExtensionInstallBlocklist contains wildcard (*) - This blocks ALL extensions"
            break
        }
    }
    
    if (-not $hasWildcardInMachineBlocklist) {
        Write-Host "ExtensionInstallBlocklist has no wildcard (*) entry (Good)" -ForegroundColor Green
    }
}

# Check for additional blocking policies
$policies = @{
    "URLBlocklist" = @{Path = $machinePoliciesPath; ExpectedToExist = $false; Description = "URL blocklist (could block extension URLs)"}
    "ExtensionInstallSources" = @{Path = $machinePoliciesPath; ExpectedToExist = $false; Description = "Extension install sources restrictions"}
    "ExtensionAllowedTypes" = @{Path = $machinePoliciesPath; ExpectedToExist = $false; Description = "Extension allowed types restrictions"}
    "AllowedInstallSites" = @{Path = $machinePoliciesPath; ExpectedToExist = $false; Description = "Allowed install sites restrictions"}
    "DeveloperToolsAvailability" = @{Path = $machinePoliciesPath; ExpectedValue = 1; Description = "Developer tools availability"}
    "RequirePerUserExtensionInstall" = @{Path = $machinePoliciesPath; ExpectedToExist = $false; Description = "Per-user extension install requirement"}
}

foreach ($policy in $policies.GetEnumerator()) {
    $result = CheckRegistryValue -Path $policy.Value.Path -Name $policy.Key -Description $policy.Value.Description -ExpectedValue $policy.Value.ExpectedValue -ExpectedToExist ($null -ne $policy.Value.ExpectedValue)
    if ($result.Problem) {
        $problemPolicies += "$($policy.Value.Description) = $($result.Value)"
    } elseif ($result.Exists) {
        $infoPolicies += "$($policy.Value.Description) = $($result.Value)"
    }
}

# Check if our extension is properly allowlisted
Write-Host "`n### Extension Allowlist Check ###" -ForegroundColor Yellow
$extensionInAllowlist = $false
if (Test-Path -Path $machineAllowlistPath) {
    $entries = Get-ItemProperty -Path $machineAllowlistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -eq $extensionId) {
            $extensionInAllowlist = $true
            Write-Host "Extension is in allowlist at index $($prop.Name)" -ForegroundColor Green
            break
        }
    }
}

if (-not $extensionInAllowlist) {
    Write-Host "Extension NOT found in allowlist" -ForegroundColor Red
    $problemPolicies += "Extension is not in the allowlist"
}

# Check if our extension is properly in forcelist
Write-Host "`n### Extension Forcelist Check ###" -ForegroundColor Yellow
$extensionInForcelist = $false
$forceUrl = ""
if (Test-Path -Path $machineForcelistPath) {
    $entries = Get-ItemProperty -Path $machineForcelistPath -ErrorAction SilentlyContinue
    foreach ($prop in $entries.PSObject.Properties) {
        if ($prop.Name -match '^\d+$' -and $prop.Value -match "^$extensionId;") {
            $extensionInForcelist = $true
            $forceUrl = $prop.Value -replace "^$extensionId;", ""
            Write-Host "Extension is in forcelist at index $($prop.Name) with URL: $forceUrl" -ForegroundColor Green
            break
        }
    }
}

if (-not $extensionInForcelist) {
    Write-Host "Extension NOT found in forcelist" -ForegroundColor Red
    $warningPolicies += "Extension is not in the force-install list"
} elseif (-not $forceUrl.StartsWith("file:///")) {
    $warningPolicies += "Extension forcelist URL does not point to a local file: $forceUrl"
}

# Check for user-level policies that could override machine policies
Write-Host "`n### User-Level Policy Check ###" -ForegroundColor Yellow
$userPoliciesExist = Test-Path -Path $userPoliciesPath
if ($userPoliciesExist) {
    Write-Host "User-level Chrome policies exist (could override machine policies)" -ForegroundColor Yellow
    
    # Check for user blocklist with wildcard
    $hasWildcardInUserBlocklist = $false
    if (Test-Path -Path $userBlocklistPath) {
        $entries = Get-ItemProperty -Path $userBlocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $entries.PSObject.Properties) {
            if ($prop.Name -match '^\d+$' -and $prop.Value -eq "*") {
                $hasWildcardInUserBlocklist = $true
                Write-Host "User-level ExtensionInstallBlocklist has wildcard (*) at index $($prop.Name)" -ForegroundColor Red
                $problemPolicies += "User-level ExtensionInstallBlocklist contains wildcard (*) - This blocks ALL extensions"
                break
            }
        }
        
        if (-not $hasWildcardInUserBlocklist) {
            Write-Host "User-level ExtensionInstallBlocklist has no wildcard (*) entry" -ForegroundColor Green
        }
    } else {
        Write-Host "No user-level blocklist found" -ForegroundColor Green
    }
    
    # Check user BlockExternalExtensions
    $userBlockExt = CheckRegistryValue -Path $userPoliciesPath -Name "BlockExternalExtensions" -Description "User-level BlockExternalExtensions policy" -ExpectedToExist $false
    if ($userBlockExt.Exists -and $userBlockExt.Value -eq 1) {
        $problemPolicies += "User-level BlockExternalExtensions = 1 - This blocks drag & drop of CRX files"
    }
} else {
    Write-Host "No user-level Chrome policies found (Good)" -ForegroundColor Green
}

# Check for legacy policy names
Write-Host "`n### Legacy Policy Name Check ###" -ForegroundColor Yellow
$legacyPolicies = @(
    @{Path = $machinePoliciesPath; Name = "ExtensionInstallWhitelist"; Replacement = "ExtensionInstallAllowlist"}
    @{Path = $machinePoliciesPath; Name = "ExtensionInstallBlacklist"; Replacement = "ExtensionInstallBlocklist"}
)

foreach ($policy in $legacyPolicies) {
    $result = CheckRegistryValue -Path $policy.Path -Name $policy.Name -Description "Legacy policy $($policy.Name)" -ExpectedToExist $false
    if ($result.Exists) {
        $warningPolicies += "Legacy policy $($policy.Name) exists (should use $($policy.Replacement) instead)"
    }
}

# Check RegEdit to ensure Chrome policies are properly set
Write-Host "`n### Registry Consistency Check ###" -ForegroundColor Yellow
try {
    $lastWriteTime = (Get-Item -Path $machinePoliciesPath -ErrorAction SilentlyContinue).LastWriteTime
    if ($null -ne $lastWriteTime) {
        $timeSinceUpdate = (Get-Date) - $lastWriteTime
        Write-Host "Chrome policies were last updated $($timeSinceUpdate.TotalMinutes.ToString("0.0")) minutes ago" -ForegroundColor Cyan
        $infoPolicies += "Chrome policies last updated $($timeSinceUpdate.TotalMinutes.ToString("0.0")) minutes ago"
    }
} catch {
    Write-Host "Error checking registry last write time: $_" -ForegroundColor Red
}

# Dump all relevant Chrome policies for reference
Write-Host "`n=== CHROME POLICY DUMP ===" -ForegroundColor Cyan
try {
    if (Test-Path -Path $machinePoliciesPath) {
        Write-Host "`nMachine Chrome Policies:" -ForegroundColor Yellow
        $policies = Get-ItemProperty -Path $machinePoliciesPath -ErrorAction SilentlyContinue
        foreach ($prop in $policies.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                Write-Host "  $($prop.Name) = $($prop.Value)"
            }
        }
    }
    
    if (Test-Path -Path $machineAllowlistPath) {
        Write-Host "`nMachine Allowlist:" -ForegroundColor Yellow
        $policies = Get-ItemProperty -Path $machineAllowlistPath -ErrorAction SilentlyContinue
        foreach ($prop in $policies.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                Write-Host "  $($prop.Name) = $($prop.Value)"
            }
        }
    }
    
    if (Test-Path -Path $machineBlocklistPath) {
        Write-Host "`nMachine Blocklist:" -ForegroundColor Yellow
        $policies = Get-ItemProperty -Path $machineBlocklistPath -ErrorAction SilentlyContinue
        foreach ($prop in $policies.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                Write-Host "  $($prop.Name) = $($prop.Value)"
            }
        }
    }
    
    if (Test-Path -Path $machineForcelistPath) {
        Write-Host "`nMachine Forcelist:" -ForegroundColor Yellow
        $policies = Get-ItemProperty -Path $machineForcelistPath -ErrorAction SilentlyContinue
        foreach ($prop in $policies.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                Write-Host "  $($prop.Name) = $($prop.Value)"
            }
        }
    }
} catch {
    Write-Host "Error dumping policies: $_" -ForegroundColor Red
}

# Check for Enterprise OmahaTokens registry 
# This registry key has been known to influence Chrome policy behavior
Write-Host "`n### Checking Enterprise OmahaTokens ###" -ForegroundColor Yellow
$omahaTokensPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\OmahaTokens"
if (Test-Path -Path $omahaTokensPath) {
    try {
        $tokens = Get-ItemProperty -Path $omahaTokensPath -ErrorAction SilentlyContinue
        Write-Host "OmahaTokens policy exists - might affect Chrome update/policy behavior" -ForegroundColor Yellow
        foreach ($prop in $tokens.PSObject.Properties) {
            if ($prop.Name -notmatch '^PS') {
                Write-Host "  $($prop.Name) = $($prop.Value)"
                $infoPolicies += "OmahaToken: $($prop.Name) = $($prop.Value)"
            }
        }
    } catch {
        Write-Host "Error checking OmahaTokens: $_" -ForegroundColor Red
    }
} else {
    Write-Host "No OmahaTokens policy found (Normal)" -ForegroundColor Green
}

# Verify CRX file exists and is accessible
Write-Host "`n### CRX File Verification ###" -ForegroundColor Yellow
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"
if (Test-Path -Path $crxPath) {
    try {
        $crxFile = Get-Item -Path $crxPath
        Write-Host ("CRX file exists at " + $crxPath + " (Size: " + [math]::Round($crxFile.Length/1KB, 2) + " KB)") -ForegroundColor Green
        
        # Check file permissions
        $acl = Get-Acl -Path $crxPath -ErrorAction SilentlyContinue
        if ($null -ne $acl) {
            Write-Host "CRX file owner: $($acl.Owner)" -ForegroundColor Cyan
            $everyoneAccess = $acl.Access | Where-Object { $_.IdentityReference -match "Everyone" -or $_.IdentityReference -match "BUILTIN\\Users" }
            if ($null -ne $everyoneAccess) {
                Write-Host "File has proper read permissions" -ForegroundColor Green
            } else {
                Write-Host "File might have restricted permissions - could cause access issues" -ForegroundColor Yellow
                $warningPolicies += "CRX file may have restricted permissions"
            }
        }
    } catch {
        Write-Host "Error checking CRX file: $_" -ForegroundColor Red
        $problemPolicies += "Error accessing CRX file: $_"
    }
} else {
    Write-Host ("CRX file NOT found at expected path: " + $crxPath) -ForegroundColor Red
    $problemPolicies += "CRX file not found at expected path"
}

# Check for running Chrome processes
Write-Host "`n### Chrome Process Check ###" -ForegroundColor Yellow
$chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    Write-Host "Chrome is currently running with $($chromeProcesses.Count) processes" -ForegroundColor Yellow
    Write-Host "Chrome must be completely closed for policy changes to take effect" -ForegroundColor Yellow
    $warningPolicies += "Chrome is currently running with $($chromeProcesses.Count) processes"
} else {
    Write-Host "Chrome is not currently running (Good)" -ForegroundColor Green
}

# Summary
Write-Host "`n=== DIAGNOSTIC SUMMARY ===" -ForegroundColor Cyan

if ($problemPolicies.Count -gt 0) {
    Write-Host "`nPROBLEMS DETECTED (Need fixing):" -ForegroundColor Red
    foreach ($issue in $problemPolicies) {
        Write-Host "- $issue" -ForegroundColor Red
    }
}

if ($warningPolicies.Count -gt 0) {
    Write-Host "`nWARNINGS (Potential issues):" -ForegroundColor Yellow
    foreach ($issue in $warningPolicies) {
        Write-Host "- $issue" -ForegroundColor Yellow
    }
}

if ($infoPolicies.Count -gt 0) {
    Write-Host "`nINFORMATION:" -ForegroundColor Cyan
    foreach ($info in $infoPolicies) {
        Write-Host "- $info" -ForegroundColor Cyan
    }
}

if ($problemPolicies.Count -eq 0 -and $warningPolicies.Count -eq 0) {
    Write-Host "`nNo obvious problems detected with Chrome policies." -ForegroundColor Green
    Write-Host "If you're still having issues, try these steps:" -ForegroundColor Yellow
    Write-Host "1. Run 'gpupdate /force' to refresh policies" -ForegroundColor Yellow
    Write-Host "2. Completely close Chrome (check Task Manager)" -ForegroundColor Yellow
    Write-Host "3. Clear Chrome's cache folder: %LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" -ForegroundColor Yellow
    Write-Host "4. Check chrome://policy in Chrome for any conflicting policies" -ForegroundColor Yellow
    Write-Host "5. Try a different user account to see if the issue is user-specific" -ForegroundColor Yellow
} else {
    Write-Host "`nTry resolving the above issues to enable extension installation." -ForegroundColor Yellow
}

# Final recommendation - Try Cleanup + Load Extension approach
Write-Host "`n=== RECOMMENDED SOLUTION ===" -ForegroundColor Cyan
Write-Host "Based on diagnostics, try this 3-step approach:" -ForegroundColor Yellow
Write-Host "1. FIRST: Run Restore-ChromePolicies.ps1 to clean up all custom policies" -ForegroundColor Yellow
Write-Host "2. THEN: Run Enable-LocalExtensions.ps1 to set up minimal policies for --load-extension" -ForegroundColor Yellow
Write-Host "3. DO NOT run Install-CRX-NoBlocking.ps1 afterward (conflicts with above approach)" -ForegroundColor Yellow
Write-Host "This combination has proven most reliable for local extensions." -ForegroundColor Yellow

# Stop transcript
Write-Host "`nDiagnostic log saved to: $logFile"
Stop-Transcript 