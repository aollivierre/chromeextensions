#
# Fix-DeveloperTools.ps1
# Adds the missing DeveloperToolsAvailability policy needed for extensions
#

# Create log file
$logFile = "$env:TEMP\ChromeDeveloperFix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Chrome Developer Tools Policy Fix - $(Get-Date)"

# Registry path
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Add the missing DeveloperToolsAvailability policy
Write-Host "Adding DeveloperToolsAvailability policy..." -NoNewline
try {
    New-ItemProperty -Path $chromePoliciesPath -Name "DeveloperToolsAvailability" -Value 1 -PropertyType DWORD -Force | Out-Null
    Write-Host "Success!" -ForegroundColor Green
} catch {
    Write-Host "Failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# Verify all relevant developer policies are set
Write-Host "`nVerifying developer policies..."

$developerPolicies = @{
    "DeveloperToolsAvailability" = 1
    "ExtensionDeveloperModeAllowed" = 1
    "BlockExternalExtensions" = 0
}

foreach ($policy in $developerPolicies.GetEnumerator()) {
    $value = $null
    try {
        $value = (Get-ItemProperty -Path $chromePoliciesPath -Name $policy.Key -ErrorAction SilentlyContinue).$($policy.Key)
    } catch { }
    
    if ($value -eq $policy.Value) {
        Write-Host "$($policy.Key) = $value (Correct)" -ForegroundColor Green
    } else {
        Write-Host "$($policy.Key) = $value (Should be $($policy.Value))" -ForegroundColor Red
    }
}

# Final instructions
Write-Host "`nTo apply these changes:"
Write-Host "1. Close ALL Chrome instances (check Task Manager)"
Write-Host "2. Run 'gpupdate /force' to refresh policies"
Write-Host "3. Launch Chrome and check chrome://extensions"

# Stop transcript
Write-Host "`nFix log saved to: $logFile"
Stop-Transcript 