$ExtensionID = "bekjclbbemboommhkppfcdpeaddfajnm"

$(Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist).GetValueNames() | Where-Object {$_ -ne ""} | ForEach-Object {
    if ($(Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -Name $_).Trim() -like "$($ExtensionID);*") {
        Remove-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist -Name $_ -Force
    }
}