# Detect-GenesysCloudPROD.ps1
# SCCM Detection script for Genesys Cloud PROD shortcut
# 
# IMPORTANT: This script follows SCCM detection methodology:
# - Outputs a message with Write-Host when NO remediation is needed
# - Outputs nothing when remediation IS needed
# - Does NOT use exit codes or return statements (critical for SCCM compatibility)

# Configuration
$shortcutTitle = "Genesys Cloud (Chrome)"
$expectedTargets = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)
$expectedArguments = "--app=https://apps.cac1.pure.cloud:443"

# Get both desktop paths
$publicDesktopPath = [System.Environment]::GetFolderPath('CommonDesktopDirectory')
$userDesktopPath = [System.Environment]::GetFolderPath('Desktop')

# Define shortcut paths for both locations
$publicShortcutPath = Join-Path -Path $publicDesktopPath -ChildPath "$shortcutTitle.lnk"
$userShortcutPath = Join-Path -Path $userDesktopPath -ChildPath "$shortcutTitle.lnk"

# Detailed information for logging
$detectionDetails = @()

# Flag to track if remediation is needed
$remediationNeeded = $true  # Default to needed, will set to false if either shortcut is valid

# Check public desktop shortcut
$publicShortcutValid = $false
try {
    if (Test-Path $publicShortcutPath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($publicShortcutPath)
        
        # Check target path
        $targetMatch = $false
        foreach ($target in $expectedTargets) {
            if ($shortcut.TargetPath -eq $target) {
                $targetMatch = $true
                break
            }
        }
        
        # Check if both target and arguments match
        if ($targetMatch -and $shortcut.Arguments -eq $expectedArguments) {
            $publicShortcutValid = $true
            $detectionDetails += "Public desktop shortcut is valid at: $publicShortcutPath"
        }
        else {
            $detectionDetails += "Public desktop shortcut exists but has incorrect properties at: $publicShortcutPath"
        }
        
        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
    else {
        $detectionDetails += "Public desktop shortcut does not exist at: $publicShortcutPath"
    }
}
catch {
    $detectionDetails += "Error checking public desktop shortcut: $($_.Exception.Message)"
}

# Check user desktop shortcut
$userShortcutValid = $false
try {
    if (Test-Path $userShortcutPath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($userShortcutPath)
        
        # Check target path
        $targetMatch = $false
        foreach ($target in $expectedTargets) {
            if ($shortcut.TargetPath -eq $target) {
                $targetMatch = $true
                break
            }
        }
        
        # Check if both target and arguments match
        if ($targetMatch -and $shortcut.Arguments -eq $expectedArguments) {
            $userShortcutValid = $true
            $detectionDetails += "User desktop shortcut is valid at: $userShortcutPath"
        }
        else {
            $detectionDetails += "User desktop shortcut exists but has incorrect properties at: $userShortcutPath"
        }
        
        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
    else {
        $detectionDetails += "User desktop shortcut does not exist at: $userShortcutPath"
    }
}
catch {
    $detectionDetails += "Error checking user desktop shortcut: $($_.Exception.Message)"
}

# Determine if remediation is needed
# We require BOTH shortcuts to be missing or invalid to trigger remediation
if ($publicShortcutValid -or $userShortcutValid) {
    $remediationNeeded = $false
    $detectionDetails += "At least one shortcut is valid, no remediation needed"
}
else {
    $detectionDetails += "Both shortcuts are missing or invalid, remediation needed"
}

# Output decision based on the flag
if (-not $remediationNeeded) {
    # Only write output when NO remediation is needed
    Write-Host "Genesys Cloud PROD shortcut is properly configured. No remediation needed."
}

# For troubleshooting purposes, you can uncomment this line to write detailed detection info to a log file
# $logFolder = "C:\ProgramData\GenesysCloud\"
# if (-not (Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory -Force | Out-Null }
# $detectionDetails | Out-File -FilePath "$logFolder\detection_log_prod.txt" -Append 