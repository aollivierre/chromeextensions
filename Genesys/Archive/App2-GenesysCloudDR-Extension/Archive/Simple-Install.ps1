# Simplified CRX installation with error handling
# Run as Administrator

# Create log file for diagnostics
$logFile = "$env:TEMP\ChromeExtensionInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting simplified Chrome extension installation - $(Get-Date)"

# Configuration
$extensionId = "idjmoolmcplbkjcldambblbojejkdpij"
$crxPath = "C:\Program Files\GenesysPOC\GenesysCloudDR.crx"

try {
    # Step 1: Ensure directory exists with proper error handling
    Write-Host "Step 1: Creating directory..." -ForegroundColor Cyan
    if (-not (Test-Path "C:\Program Files\GenesysPOC")) {
        try {
            New-Item -Path "C:\Program Files\GenesysPOC" -ItemType Directory -Force | Out-Null
            Write-Host "Directory created successfully" -ForegroundColor Green
        } catch {
            Write-Host "ERROR creating directory: $_" -ForegroundColor Red
            Write-Host "Make sure you're running as Administrator" -ForegroundColor Yellow
            throw "Failed to create directory"
        }
    } else {
        Write-Host "Directory already exists" -ForegroundColor Green
    }

    # Step 2: Verify Chrome policies registry path
    Write-Host "`nStep 2: Checking Chrome policies registry path..." -ForegroundColor Cyan
    $chromePoliciesPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    $forcelistPath = "$chromePoliciesPath\ExtensionInstallForcelist"
    
    try {
        if (-not (Test-Path $chromePoliciesPath)) {
            New-Item -Path $chromePoliciesPath -Force | Out-Null
            Write-Host "Created Chrome policies registry path" -ForegroundColor Green
        } else {
            Write-Host "Chrome policies registry path exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "ERROR accessing registry: $_" -ForegroundColor Red
        Write-Host "Make sure you're running as Administrator" -ForegroundColor Yellow
        throw "Failed to access registry"
    }

    # Step 3: Create ExtensionInstallForcelist key if needed
    Write-Host "`nStep 3: Setting up forcelist registry key..." -ForegroundColor Cyan
    try {
        if (-not (Test-Path $forcelistPath)) {
            New-Item -Path $forcelistPath -Force | Out-Null
            Write-Host "Created forcelist registry key" -ForegroundColor Green
        } else {
            Write-Host "Forcelist registry key exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "ERROR creating forcelist registry key: $_" -ForegroundColor Red
        Write-Host "Make sure you're running as Administrator" -ForegroundColor Yellow
        throw "Failed to create forcelist registry key"
    }

    # Step 4: Set BlockExternalExtensions policy
    Write-Host "`nStep 4: Setting BlockExternalExtensions policy..." -ForegroundColor Cyan
    try {
        New-ItemProperty -Path $chromePoliciesPath -Name "BlockExternalExtensions" -Value 0 -PropertyType DWORD -Force | Out-Null
        Write-Host "BlockExternalExtensions policy set to 0" -ForegroundColor Green
    } catch {
        Write-Host "ERROR setting BlockExternalExtensions policy: $_" -ForegroundColor Red
        Write-Host "Make sure you're running as Administrator" -ForegroundColor Yellow
        throw "Failed to set BlockExternalExtensions policy"
    }

    # Step 5: Find next available index for forcelist
    Write-Host "`nStep 5: Finding next available index..." -ForegroundColor Cyan
    try {
        $nextIndex = 1
        $properties = (Get-Item -Path $forcelistPath -ErrorAction SilentlyContinue).Property
        
        if ($properties) {
            foreach ($prop in $properties) {
                if ($prop -match "^\d+$" -and [int]$prop -ge $nextIndex) {
                    $nextIndex = [int]$prop + 1
                }
            }
        }
        Write-Host "Next available index: $nextIndex" -ForegroundColor Green
    } catch {
        Write-Host "ERROR finding next index: $_" -ForegroundColor Red
        Write-Host "Using default index 1" -ForegroundColor Yellow
        $nextIndex = 1
    }

    # Step 6: Add extension to forcelist
    Write-Host "`nStep 6: Adding extension to forcelist..." -ForegroundColor Cyan
    try {
        # Convert path to file:// URL format
        $crxPathUrl = $crxPath.Replace("\", "/")
        $crxPathUrl = "file:///$crxPathUrl"
        
        New-ItemProperty -Path $forcelistPath -Name $nextIndex -Value "$extensionId;$crxPathUrl" -PropertyType String -Force | Out-Null
        Write-Host "Extension added to forcelist at index $nextIndex" -ForegroundColor Green
    } catch {
        Write-Host "ERROR adding extension to forcelist: $_" -ForegroundColor Red
        throw "Failed to add extension to forcelist"
    }

    # Step 7: Verify CRX file
    Write-Host "`nStep 7: Verifying CRX file..." -ForegroundColor Cyan
    if (Test-Path $crxPath) {
        $crxFile = Get-Item -Path $crxPath
        Write-Host "CRX file exists: $crxPath" -ForegroundColor Green
        Write-Host "File size: $([math]::Round($crxFile.Length/1KB, 2)) KB" -ForegroundColor Green
    } else {
        Write-Host "WARNING: CRX file not found!" -ForegroundColor Yellow
        Write-Host "You need to manually copy the CRX file to: $crxPath" -ForegroundColor Yellow
    }

    # Success!
    Write-Host "`nExtension installation configured successfully!" -ForegroundColor Green
    Write-Host "To complete installation:"
    Write-Host "1. Run 'gpupdate /force'"
    Write-Host "2. Restart Chrome"
    
} catch {
    Write-Host "`nInstallation failed: $_" -ForegroundColor Red
    Write-Host "Check log file for details: $logFile" -ForegroundColor Red
}

Stop-Transcript 