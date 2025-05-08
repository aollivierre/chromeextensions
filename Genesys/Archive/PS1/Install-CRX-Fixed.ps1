# Fixed Script to programmatically install CRX extension
# Includes all required policy settings for reliable installation

# Configuration
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"  # Corrected name
$chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"

# Ensure directories exist
Write-Host "Setting up directories and CRX file..." -ForegroundColor Cyan
if (-not (Test-Path "C:\Program Files\GenesysPOC")) {
    New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force | Out-Null
}

# Copy CRX file from source if needed (uncomment and adjust source path)
#$sourceCrx = "SOURCE_PATH\GenesysCloudDR.crx"
#if (Test-Path $sourceCrx) {
#    Copy-Item -Path $sourceCrx -Destination $crxPath -Force
#    Write-Host "CRX file copied from $sourceCrx" -ForegroundColor Green
#}

# Ensure registry paths exist
Write-Host "Setting up Chrome policies..." -ForegroundColor Cyan
if (-not (Test-Path $chromePoliciesPath)) {
    New-Item -Path $chromePoliciesPath -Force | Out-Null
}
if (-not (Test-Path $forcelistPath)) {
    New-Item -Path $forcelistPath -Force | Out-Null
}

# CRITICAL: Set BlockExternalExtensions to 0
Write-Host "Setting BlockExternalExtensions=0..." -ForegroundColor Cyan
New-ItemProperty -Path $chromePoliciesPath -Name "BlockExternalExtensions" -Value 0 -PropertyType DWORD -Force | Out-Null

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
Write-Host "Adding extension to force-install list at index $nextIndex..." -ForegroundColor Cyan
New-ItemProperty -Path $forcelistPath -Name $nextIndex -Value "$extensionId;$crxPathUrl" -PropertyType String -Force | Out-Null

# Verify CRX file exists and is accessible
if (Test-Path $crxPath) {
    $crxFile = Get-Item -Path $crxPath
    Write-Host "CRX file exists: $crxPath (Size: $([math]::Round($crxFile.Length/1KB, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "WARNING: CRX file not found at $crxPath" -ForegroundColor Red
    Write-Host "You need to place the CRX file at this location before Chrome can install it" -ForegroundColor Red
}

# Final instructions
Write-Host "`nExtension installation configured successfully!" -ForegroundColor Green
Write-Host "To complete installation:"
Write-Host "1. Run 'gpupdate /force' to refresh policies"
Write-Host "2. Restart Chrome to apply changes" 