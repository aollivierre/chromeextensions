$ExtensionData = "pkggbpdkbnahidijamikngnlpfgepabn;https://edge.microsoft.com/extensionwebstorebase/v1/crx"

function Test-RegistryValue {
    param (
     [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path,
     [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Value
    )

    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    } catch { 
        return $false
    }
}

if (-not $(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist)) {
    New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Edge -Name "ExtensionInstallForcelist"
}

$Extensions = $($(Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist).GetValueNames() | Where-Object {$_ -ne ""}).Length
$Index = 0
for ($i = 1; $i -le $Extensions; $i++) {
    if (-not $(Test-RegistryValue -Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -Value "$i")) {
        $Index = $i
        $i = $Extensions
    }
}
if ($Index -eq 0) {
    $Index = $Extensions + 1
}

New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -Name "$Index" -Value $ExtensionData -Force