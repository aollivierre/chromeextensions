#
# Set-LocalExtensionPolicies.ps1
# Sets only the essential policies needed for local extension loading with --load-extension
#

param(
    [string]$ExtensionPath = "C:\Program Files\GenesysPOC\ChromeExtension",
    [switch]$Force = $false
)

# Create log file
$logFile = "$env:TEMP\LocalExtensionPolicy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting Local Extension Policy Configuration - $(Get-Date)"

# Registry path
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Ensure Chrome Policies key exists
if (-not (Test-Path -Path $chromePoliciesPath)) {
    Write-Host "Creating Chrome Policies registry key..." -NoNewline
    try {
        New-Item -Path $chromePoliciesPath -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Check current policy settings
Write-Host "`n=== VALIDATING CURRENT POLICIES ===" -ForegroundColor Cyan

function CheckPolicy {
    param (
        [string]$PolicyName,
        [string]$ExpectedValue = $null
    )
    
    $currentValue = $null
    $exists = $false
    
    try {
        $item = Get-ItemProperty -Path $chromePoliciesPath -Name $PolicyName -ErrorAction SilentlyContinue
        if ($null -ne $item) {
            $currentValue = $item.$PolicyName
            $exists = $true
            
            if ($null -ne $ExpectedValue) {
                if ($currentValue -eq $ExpectedValue) {
                    Write-Host "$PolicyName = $currentValue (Already correct)" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "$PolicyName = $currentValue (Will be updated to: $ExpectedValue)" -ForegroundColor Yellow
                    return $false
                }
            } else {
                Write-Host "$PolicyName = $currentValue" -ForegroundColor Cyan
                return $true
            }
        } else {
            Write-Host "$PolicyName = Not set (Will be configured)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "$PolicyName = Error checking: $_" -ForegroundColor Red
        return $false
    }
}

# Validate current settings
$devModeCorrect = CheckPolicy -PolicyName "ExtensionDeveloperModeAllowed" -ExpectedValue 1
$pathsCorrect = CheckPolicy -PolicyName "AllowedLocalExtensionPaths" -ExpectedValue $ExtensionPath

# Apply necessary changes
Write-Host "`n=== APPLYING REQUIRED POLICIES ===" -ForegroundColor Cyan

if (-not $devModeCorrect) {
    Write-Host "Setting ExtensionDeveloperModeAllowed policy..." -NoNewline
    try {
        New-ItemProperty -Path $chromePoliciesPath -Name "ExtensionDeveloperModeAllowed" -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

if (-not $pathsCorrect) {
    Write-Host "Setting AllowedLocalExtensionPaths policy..." -NoNewline
    try {
        New-ItemProperty -Path $chromePoliciesPath -Name "AllowedLocalExtensionPaths" -Value $ExtensionPath -PropertyType String -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Make sure the extension directory exists
Write-Host "`n=== VERIFYING EXTENSION DIRECTORY ===" -ForegroundColor Cyan
if (-not (Test-Path -Path $ExtensionPath)) {
    Write-Host "Extension directory does not exist. Creating..." -NoNewline
    try {
        New-Item -Path $ExtensionPath -ItemType Directory -Force | Out-Null
        Write-Host "Success!" -ForegroundColor Green
    } catch {
        Write-Host "Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Extension directory exists at: $ExtensionPath" -ForegroundColor Green
}

# Re-validate settings to ensure they were applied correctly
Write-Host "`n=== VALIDATING APPLIED POLICIES ===" -ForegroundColor Cyan

# Check again to confirm changes
$devModeApplied = CheckPolicy -PolicyName "ExtensionDeveloperModeAllowed" -ExpectedValue 1
$pathsApplied = CheckPolicy -PolicyName "AllowedLocalExtensionPaths" -ExpectedValue $ExtensionPath

# Summarize results
Write-Host "`n=== CONFIGURATION SUMMARY ===" -ForegroundColor Cyan
$allCorrect = $devModeApplied -and $pathsApplied

if ($allCorrect) {
    Write-Host "All policies successfully configured!" -ForegroundColor Green
} else {
    Write-Host "Some policies were not applied correctly." -ForegroundColor Red
    if (-not $devModeApplied) { Write-Host "- ExtensionDeveloperModeAllowed not set correctly" -ForegroundColor Red }
    if (-not $pathsApplied) { Write-Host "- AllowedLocalExtensionPaths not set correctly" -ForegroundColor Red }
}

# Provide next steps
Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Close ALL Chrome instances completely"
Write-Host "3. Launch Chrome with the --load-extension parameter:"
Write-Host "   chrome.exe --load-extension=""$ExtensionPath"""

# Create a shortcut example command
$desktopPath = [Environment]::GetFolderPath('Desktop')
$shortcutCommand = @"
`$WshShell = New-Object -ComObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut('$desktopPath\GenesysChrome.lnk')
`$Shortcut.TargetPath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
`$Shortcut.Arguments = '--load-extension="$ExtensionPath"'
`$Shortcut.Save()
"@

Write-Host "`nTo create a desktop shortcut with the extension pre-loaded, run:"
Write-Host $shortcutCommand

# Stop transcript
Write-Host "`nConfiguration log saved to: $logFile"
Stop-Transcript 