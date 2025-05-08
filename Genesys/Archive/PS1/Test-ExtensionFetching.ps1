<#
.SYNOPSIS
    Tests different methods for efficiently fetching Chrome extension information.

.DESCRIPTION
    This script compares three different approaches to retrieve extension names and descriptions:
    1. Using Invoke-WebRequest (baseline/slow method)
    2. Using System.Net.WebClient (faster method)
    3. Using parallel processing with runspaces (fastest method)

.EXAMPLE
    .\Test-ExtensionFetching.ps1 -ExtensionId "pjkljhegncpnkpknbcohdijeoejaedia"
    Tests all three methods on a single extension ID (in this case, Google Gmail)

.EXAMPLE
    .\Test-ExtensionFetching.ps1 -ExtensionIds @("pjkljhegncpnkpknbcohdijeoejaedia", "aohghmighlieiainnegkcijnfilokake")
    Tests all three methods on multiple extension IDs
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$ExtensionId = "pjkljhegncpnkpknbcohdijeoejaedia", # Gmail as default example

    [Parameter(Mandatory=$false)]
    [string[]]$ExtensionIds = @()
)

# Add the single extension ID to the array if not already in bulk mode
if ($ExtensionIds.Count -eq 0 -and $ExtensionId) {
    $ExtensionIds = @($ExtensionId)
}

# Common settings
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"

#region Method 1: Standard Invoke-WebRequest (slow)
function Get-ExtensionInfo_InvokeWebRequest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ExtensionId
    )

    $startTime = Get-Date
    Write-Host "Method 1 (Invoke-WebRequest): Fetching info for $ExtensionId..." -NoNewline

    try {
        $url = "https://chromewebstore.google.com/detail/$ExtensionId"
        $response = Invoke-WebRequest -Uri $url -UserAgent $userAgent -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        
        $name = "Unknown"
        $description = "No description available"
        
        if ($response.StatusCode -eq 200) {
            # Extract title (extension name)
            if ($response.Content -match '<title>(.*?)</title>') {
                $title = $matches[1]
                # Clean up the title (remove "- Chrome Web Store" part)
                if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
                    $name = $matches[1].Trim()
                }
            }
            
            # Try to extract description
            if ($response.Content -match '<meta\s+name="description"\s+content="([^"]*)"') {
                $description = $matches[1]
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "Done (${duration}ms)" -ForegroundColor Green
        
        return [PSCustomObject]@{
            ExtensionId = $ExtensionId
            Name = $name
            Description = $description.Substring(0, [Math]::Min(100, $description.Length)) + $(if($description.Length -gt 100){"..."} else {""})
            Duration = $duration
            Method = "Invoke-WebRequest"
        }
    }
    catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        Write-Host "Failed (${duration}ms)" -ForegroundColor Red
        return [PSCustomObject]@{
            ExtensionId = $ExtensionId
            Name = "Error"
            Description = $_.Exception.Message
            Duration = $duration
            Method = "Invoke-WebRequest"
        }
    }
}

#region Method 2: Using System.Net.WebClient (faster)
function Get-ExtensionInfo_WebClient {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ExtensionId
    )

    $startTime = Get-Date
    Write-Host "Method 2 (WebClient): Fetching info for $ExtensionId..." -NoNewline

    try {
        $url = "https://chromewebstore.google.com/detail/$ExtensionId"
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", $userAgent)
        $content = $webClient.DownloadString($url)
        
        $name = "Unknown"
        $description = "No description available"
        
        # Extract title (extension name)
        if ($content -match '<title>(.*?)</title>') {
            $title = $matches[1]
            # Clean up the title (remove "- Chrome Web Store" part)
            if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
                $name = $matches[1].Trim()
            }
        }
        
        # Try to extract description
        if ($content -match '<meta\s+name="description"\s+content="([^"]*)"') {
            $description = $matches[1]
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "Done (${duration}ms)" -ForegroundColor Green
        
        return [PSCustomObject]@{
            ExtensionId = $ExtensionId
            Name = $name
            Description = $description.Substring(0, [Math]::Min(100, $description.Length)) + $(if($description.Length -gt 100){"..."} else {""})
            Duration = $duration
            Method = "WebClient"
        }
    }
    catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        Write-Host "Failed (${duration}ms)" -ForegroundColor Red
        return [PSCustomObject]@{
            ExtensionId = $ExtensionId
            Name = "Error"
            Description = $_.Exception.Message
            Duration = $duration
            Method = "WebClient"
        }
    }
}

#region Method 3: Parallel Processing with Runspaces (fastest for bulk)
function Get-ExtensionInfo_Parallel {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ExtensionIds,
        [int]$MaxThreads = 10
    )
    
    $startTime = Get-Date
    Write-Host "Method 3 (Parallel): Fetching info for ${ExtensionIds.Count} extensions..." -NoNewline
    
    # Initialize runspace pool
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
    $runspacePool.Open()
    
    $scriptBlock = {
        param($extensionId, $userAgent)
        
        try {
            $url = "https://chromewebstore.google.com/detail/$extensionId"
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", $userAgent)
            $content = $webClient.DownloadString($url)
            
            $name = "Unknown"
            $description = "No description available"
            
            # Extract title (extension name)
            if ($content -match '<title>(.*?)</title>') {
                $title = $matches[1]
                # Clean up the title (remove "- Chrome Web Store" part)
                if ($title -match '(.*?)(?:\s*-\s*Chrome Web Store)?$') {
                    $name = $matches[1].Trim()
                }
            }
            
            # Try to extract description
            if ($content -match '<meta\s+name="description"\s+content="([^"]*)"') {
                $description = $matches[1]
            }
            
            return [PSCustomObject]@{
                ExtensionId = $extensionId
                Name = $name
                Description = $description.Substring(0, [Math]::Min(100, $description.Length)) + $(if($description.Length -gt 100){"..."} else {""})
                Success = $true
            }
        }
        catch {
            return [PSCustomObject]@{
                ExtensionId = $extensionId
                Name = "Error"
                Description = $_.Exception.Message
                Success = $false
            }
        }
    }
    
    # Create runspaces for each extension
    $runspaces = @()
    foreach ($extensionId in $ExtensionIds) {
        $powerShell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
            extensionId = $extensionId
            userAgent = $userAgent
        })
        $powerShell.RunspacePool = $runspacePool
        
        $runspaces += [PSCustomObject]@{
            PowerShell = $powerShell
            Runspace = $powerShell.BeginInvoke()
            ExtensionId = $extensionId
        }
    }
    
    # Collect results
    $results = @()
    foreach ($runspace in $runspaces) {
        $results += $runspace.PowerShell.EndInvoke($runspace.Runspace)
        $runspace.PowerShell.Dispose()
    }
    
    # Close the runspace pool
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalMilliseconds
    $averageDuration = if ($results.Count -gt 0) { $totalDuration / $results.Count } else { 0 }
    
    Write-Host "Done (Total: ${totalDuration}ms, Avg: ${averageDuration}ms per extension)" -ForegroundColor Green
    
    return $results | ForEach-Object {
        [PSCustomObject]@{
            ExtensionId = $_.ExtensionId
            Name = $_.Name
            Description = $_.Description
            Success = $_.Success
            Method = "Parallel"
        }
    }
}

# Run all tests
Write-Host "====== CHROME EXTENSION INFO FETCHING PERFORMANCE TEST ======" -ForegroundColor Cyan
Write-Host "Testing with ${$ExtensionIds.Count} extension(s)`n" -ForegroundColor Yellow

# Test Method 1 (individual requests)
$method1Results = @()
foreach ($id in $ExtensionIds) {
    $method1Results += Get-ExtensionInfo_InvokeWebRequest -ExtensionId $id
}

# Test Method 2 (individual requests)
$method2Results = @()
foreach ($id in $ExtensionIds) {
    $method2Results += Get-ExtensionInfo_WebClient -ExtensionId $id
}

# Test Method 3 (parallel)
$method3Results = Get-ExtensionInfo_Parallel -ExtensionIds $ExtensionIds

# Display summary
Write-Host "`n====== RESULTS SUMMARY ======" -ForegroundColor Cyan

# Method 1 summary
$method1TotalDuration = ($method1Results | Measure-Object -Property Duration -Sum).Sum
$method1AvgDuration = if ($method1Results.Count -gt 0) { $method1TotalDuration / $method1Results.Count } else { 0 }
Write-Host "Method 1 (Invoke-WebRequest):" -ForegroundColor Yellow
Write-Host "  - Total Duration: $method1TotalDuration ms"
Write-Host "  - Average Duration: $method1AvgDuration ms per extension"

# Method 2 summary
$method2TotalDuration = ($method2Results | Measure-Object -Property Duration -Sum).Sum
$method2AvgDuration = if ($method2Results.Count -gt 0) { $method2TotalDuration / $method2Results.Count } else { 0 }
Write-Host "Method 2 (WebClient):" -ForegroundColor Yellow
Write-Host "  - Total Duration: $method2TotalDuration ms"
Write-Host "  - Average Duration: $method2AvgDuration ms per extension"

# Method 3 summary (parallel)
Write-Host "Method 3 (Parallel):" -ForegroundColor Yellow
Write-Host "  - Total Duration: $totalDuration ms"
Write-Host "  - Average Duration: $averageDuration ms per extension"

# Compare the actual data
Write-Host "`n====== EXTENSION DETAILS ======" -ForegroundColor Cyan
foreach ($id in $ExtensionIds) {
    $m1 = $method1Results | Where-Object { $_.ExtensionId -eq $id }
    $m2 = $method2Results | Where-Object { $_.ExtensionId -eq $id }
    $m3 = $method3Results | Where-Object { $_.ExtensionId -eq $id }
    
    Write-Host "Extension ID: $id" -ForegroundColor Green
    Write-Host "  Method 1: $($m1.Name) - $($m1.Duration)ms"
    Write-Host "  Method 2: $($m2.Name) - $($m2.Duration)ms"
    Write-Host "  Method 3: $($m3.Name)"
    Write-Host "  Description: $($m2.Description)" -ForegroundColor Gray
    Write-Host ""
}

# Recommendation
Write-Host "`n====== RECOMMENDATIONS ======" -ForegroundColor Cyan
Write-Host "Based on performance testing:" -ForegroundColor Yellow

if ($method1AvgDuration -gt $method2AvgDuration) {
    if ($ExtensionIds.Count -gt 5) {
        Write-Host "For bulk processing (${$ExtensionIds.Count} extensions), Method 3 (Parallel) is recommended" -ForegroundColor Green
        Write-Host "  - Approximately $(($method1TotalDuration/$totalDuration).ToString("N1"))x faster than Method 1"
        Write-Host "  - Approximately $(($method2TotalDuration/$totalDuration).ToString("N1"))x faster than Method 2"
    } else {
        Write-Host "For individual or small batches, Method 2 (WebClient) is recommended" -ForegroundColor Green
        Write-Host "  - Approximately $(($method1AvgDuration/$method2AvgDuration).ToString("N1"))x faster than Method 1"
    }
} else {
    Write-Host "Method 1 (Invoke-WebRequest) performed well in this test." -ForegroundColor Green
}

# Example of how to implement in a production script
Write-Host "`n====== IMPLEMENTATION EXAMPLE ======" -ForegroundColor Cyan

# Using single quotes to prevent variable interpolation
Write-Host '
# Copy this function into your script to use the most efficient method:

function Get-ExtensionFriendlyNames {
    param (
        [string[]]$ExtensionIds,
        [switch]$IncludeDescription,
        [int]$MaxThreads = 10
    )
    
    # For a single ID or small batch, use WebClient
    if ($ExtensionIds.Count -le 5) {
        $results = @()
        foreach ($id in $ExtensionIds) {
            try {
                $url = "https://chromewebstore.google.com/detail/$id"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/135.0.0.0")
                $content = $webClient.DownloadString($url)
                
                $name = "Extension $id"
                
                if ($content -match "<title>(.*?)</title>") {
                    $title = $matches[1]
                    if ($title -match "(.*?)(?:\s*-\s*Chrome Web Store)?$") {
                        $name = $matches[1].Trim()
                    }
                }
                
                $obj = [PSCustomObject]@{
                    ExtensionId = $id
                    Name = $name
                }
                
                if ($IncludeDescription) {
                    $description = "No description available"
                    if ($content -match "<meta\s+name=\"description\"\s+content=\"([^\"]*)\") {
                        $description = $matches[1]
                    }
                    $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $description
                }
                
                $results += $obj
            }
            catch {
                $results += [PSCustomObject]@{
                    ExtensionId = $id
                    Name = "Extension $id"
                    Description = if ($IncludeDescription) { "Error: $_" } else { $null }
                }
            }
        }
        return $results
    }
    # For larger batches, use parallel processing
    else {
        # Parallel processing implementation
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $runspacePool.Open()
        
        $scriptBlock = {
            param($extensionId, $includeDescription)
            
            try {
                $url = "https://chromewebstore.google.com/detail/$extensionId"
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/135.0.0.0")
                $content = $webClient.DownloadString($url)
                
                $name = "Extension $extensionId"
                
                if ($content -match "<title>(.*?)</title>") {
                    $title = $matches[1]
                    if ($title -match "(.*?)(?:\s*-\s*Chrome Web Store)?$") {
                        $name = $matches[1].Trim()
                    }
                }
                
                $resultObj = [PSCustomObject]@{
                    ExtensionId = $extensionId
                    Name = $name
                    Success = $true
                }
                
                if ($includeDescription) {
                    $description = "No description available"
                    if ($content -match "<meta\s+name=\"description\"\s+content=\"([^\"]*)\") {
                        $description = $matches[1]
                    }
                    $resultObj | Add-Member -MemberType NoteProperty -Name "Description" -Value $description
                }
                
                return $resultObj
            }
            catch {
                $resultObj = [PSCustomObject]@{
                    ExtensionId = $extensionId
                    Name = "Extension $extensionId"
                    Success = $false
                }
                
                if ($includeDescription) {
                    $resultObj | Add-Member -MemberType NoteProperty -Name "Description" -Value "Error: $_"
                }
                
                return $resultObj
            }
        }
        
        # Create runspaces
        $runspaces = @()
        foreach ($id in $ExtensionIds) {
            $powerShell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                extensionId = $id
                includeDescription = $IncludeDescription
            })
            $powerShell.RunspacePool = $runspacePool
            
            $runspaces += [PSCustomObject]@{
                PowerShell = $powerShell
                Runspace = $powerShell.BeginInvoke()
                ExtensionId = $id
            }
        }
        
        # Collect results
        $results = @()
        foreach ($runspace in $runspaces) {
            try {
                $results += $runspace.PowerShell.EndInvoke($runspace.Runspace)
            }
            catch {
                # Handle any errors in results collection
                $results += [PSCustomObject]@{
                    ExtensionId = $runspace.ExtensionId
                    Name = "Error collecting result"
                    Success = $false
                }
                if ($IncludeDescription) {
                    $results[-1] | Add-Member -MemberType NoteProperty -Name "Description" -Value "Error: $_"
                }
            }
            finally {
                $runspace.PowerShell.Dispose()
            }
        }
        
        # Close the runspace pool
        $runspacePool.Close()
        $runspacePool.Dispose()
        
        return $results
    }
}
'

# Usage examples
Write-Host "`nExample usage:" -ForegroundColor Yellow
Write-Host '  $extensions = Get-ExtensionFriendlyNames -ExtensionIds @("pjkljhegncpnkpknbcohdijeoejaedia")'
Write-Host '  $extensions | ForEach-Object { Write-Host "$($_.Name) - $($_.ExtensionId)" }' 