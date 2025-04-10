# PowerShell script to format screenshots for Chrome Web Store
# This script can format a single screenshot or process all images in a directory

param(
    [Parameter(Mandatory=$false)]
    [string]$InputPath = ".",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "chrome_screenshots",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("1280x800", "640x400")]
    [string]$Size = "1280x800",
    
    [Parameter(Mandatory=$false)]
    [switch]$SingleFile
)

$ErrorActionPreference = "Stop"

# Find Python executable
$PythonExe = $null
$PythonPaths = @(
    "python.exe",
    "py.exe",
    "python3.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
    "C:\Python*\python.exe",
    "$env:ProgramFiles\Python*\python.exe"
)

foreach ($Path in $PythonPaths) {
    $PythonLocations = @(Get-Command $Path -ErrorAction SilentlyContinue)
    if ($PythonLocations.Count -gt 0) {
        $PythonExe = $PythonLocations[0].Source
        break
    }
}

if (-not $PythonExe) {
    Write-Host "Python not found. Please install Python and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Using Python at $PythonExe" -ForegroundColor Green

# Ensure required packages are installed
Write-Host "Checking required Python packages..." -ForegroundColor Cyan
& $PythonExe -m pip install pillow>=10.0.0

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

if ($SingleFile) {
    # Format a single screenshot
    $ScriptPath = Join-Path $ScriptDir "format_screenshot.py"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Error: Script not found at $ScriptPath" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $InputPath)) {
        Write-Host "Error: Input file not found at $InputPath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Formatting single screenshot: $InputPath" -ForegroundColor Cyan
    Write-Host "Output: $OutputPath" -ForegroundColor Cyan
    Write-Host "Size: $Size" -ForegroundColor Cyan
    
    & $PythonExe $ScriptPath $InputPath $OutputPath $Size
} else {
    # Process all screenshots in a directory
    $ScriptPath = Join-Path $ScriptDir "format_all_screenshots.py"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Error: Script not found at $ScriptPath" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $InputPath)) {
        Write-Host "Error: Input directory not found at $InputPath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Processing all screenshots in: $InputPath" -ForegroundColor Cyan
    Write-Host "Output directory: $OutputPath" -ForegroundColor Cyan
    Write-Host "Size: $Size" -ForegroundColor Cyan
    
    & $PythonExe $ScriptPath $InputPath $OutputPath $Size
}

# Check if output exists and open folder
if (Test-Path $OutputPath) {
    if ((Get-Item $OutputPath) -is [System.IO.DirectoryInfo]) {
        # It's a directory
        $OutputFolder = $OutputPath
    } else {
        # It's a file
        $OutputFolder = Split-Path -Parent $OutputPath
    }
    
    Write-Host "Opening output folder: $OutputFolder" -ForegroundColor Green
    explorer.exe $OutputFolder
} else {
    Write-Host "Processing completed, but output not found. Check for errors." -ForegroundColor Yellow
} 