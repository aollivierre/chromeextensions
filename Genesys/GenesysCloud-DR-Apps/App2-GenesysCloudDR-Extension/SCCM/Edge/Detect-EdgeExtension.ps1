$ExtensionID = "pkggbpdkbnahidijamikngnlpfgepabn"

$Compliant = $False

if (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist) {
    $(Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist).GetValueNames() | Where-Object {$_ -ne ""} | ForEach-Object {
        if ($(Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -Name $_).Trim() -like "$($ExtensionID);*") {
            $Compliant = $True
        }
    }
}

if ($Compliant) {
    Write-Host "DETECTED"
}