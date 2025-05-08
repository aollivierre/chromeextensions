# PowerShell script to create a Chrome extension icon with a DR indicator
# This script automatically finds Python and runs the create_chrome_extension_icon.py script

$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define input and output paths
$InputIcon = Join-Path $ScriptDir "GenesysCloud_icon.ico"
$OutputIcon = Join-Path $ScriptDir "GenesysCloud_DR_128.png"
$PythonScript = Join-Path $ScriptDir "create_chrome_extension_icon.py"

Write-Host "Creating Chrome extension icon..." -ForegroundColor Cyan

# Check if input icon exists
if (-not (Test-Path $InputIcon)) {
    Write-Host "Error: Input icon not found at $InputIcon" -ForegroundColor Red
    Write-Host "Please place the GenesysCloud_icon.ico file in the same directory as this script." -ForegroundColor Yellow
    exit 1
}

# Check if Python script exists
if (-not (Test-Path $PythonScript)) {
    Write-Host "Error: Python script not found at $PythonScript" -ForegroundColor Red
    Write-Host "Please place the create_chrome_extension_icon.py file in the same directory as this script." -ForegroundColor Yellow
    exit 1
}

# Find Python executable
$PythonExe = $null

# Try to find Python in standard locations
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

# Navigate to script directory to ensure relative paths work
Push-Location $ScriptDir

try {
    # Ensure required packages are installed
    Write-Host "Checking required Python packages..." -ForegroundColor Cyan
    
    # Check if requirements.txt exists
    $RequirementsFile = Join-Path $ScriptDir "requirements.txt"
    if (Test-Path $RequirementsFile) {
        # Use -m pip to avoid issues with pip not being in PATH
        & $PythonExe -m pip install -r $RequirementsFile
    } else {
        # Fall back to direct install if requirements.txt is missing
        & $PythonExe -m pip install pillow>=10.0.0
    }
    
    # Run the Python script with our parameters
    Write-Host "Running icon creation script..." -ForegroundColor Cyan
    Write-Host "Input icon: $InputIcon" -ForegroundColor Cyan
    Write-Host "Output icon: $OutputIcon" -ForegroundColor Cyan
    
    & $PythonExe $PythonScript $InputIcon $OutputIcon
    
    # Check if icon was created successfully
    if (Test-Path $OutputIcon) {
        Write-Host "Successfully created Chrome extension icon: $OutputIcon" -ForegroundColor Green
        
        # Get the full path for display
        $FullPath = (Get-Item $OutputIcon).FullName
        Write-Host "Full path $FullPath" -ForegroundColor Green
        
        # Show icon in explorer
        Write-Host "Opening containing folder..." -ForegroundColor Cyan
        explorer.exe /select,"$FullPath"
    } else {
        Write-Host "Failed to create icon. Check the Python script output for errors." -ForegroundColor Red
    }
} finally {
    # Restore original location
    Pop-Location
} 