# Script to programmatically install CRX extension
# Place CRX file in a network share or local folder that's accessible to all machines

# Configuration
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"
$crxPath = "C:\Program Files\GenesysPOC\GenesysDR.crx"  # Update with your CRX location
$forcelistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

# Ensure path exists
if (-not (Test-Path $forcelistPath)) {
    New-Item -Path $forcelistPath -Force | Out-Null
}

# Find next available index
$indices = @()
if (Test-Path $forcelistPath) {
    $indices = (Get-Item $forcelistPath | Select-Object -ExpandProperty Property) -match '^\d+$'
}
$nextIndex = 1
while ($indices -contains $nextIndex.ToString()) {
    $nextIndex++
}

# Convert path to file:// URL format with forward slashes
$crxPathUrl = $crxPath.Replace("\", "/")
$crxPathUrl = "file:///$crxPathUrl"

# Add to force-install list
Write-Host "Adding extension to force-install list..."
New-ItemProperty -Path $forcelistPath -Name $nextIndex -Value "$extensionId;$crxPathUrl" -PropertyType String -Force

Write-Host "Extension added to force-install list. Restart Chrome to apply."