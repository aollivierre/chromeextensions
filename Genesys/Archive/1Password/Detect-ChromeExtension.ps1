﻿$ExtensionID = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"

$Compliant = $False

if (Test-Path HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist) {
    $(Get-Item HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist).GetValueNames() | Where-Object {$_ -ne ""} | ForEach-Object {
        if ($(Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist -Name $_).Trim() -like "$($ExtensionID);*") {
            $Compliant = $True
        }
    }
}

if ($Compliant) {
    Write-Host "DETECTED"
}

# SIG # Begin signature block
# MIIPkAYJKoZIhvcNAQcCoIIPgTCCD30CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuUaEDLKzuZGYxO8Wy5hbX6x5
# s/2ggg18MIIGijCCBHKgAwIBAgITRQACH1d/naH/S4uqGwABAAIfVzANBgkqhkiG
# 9w0BAQsFADBHMRMwEQYKCZImiZPyLGQBGRYDaW5zMRQwEgYKCZImiZPyLGQBGRYE
# d21pYzEaMBgGA1UEAxMRV01JQyBJc3N1aW5nIENBMDEwHhcNMjQxMTA0MTUyNTQz
# WhcNMjcxMTA0MTUyNTQzWjAhMR8wHQYDVQQDExZDb25maWdNZ3IgQ29kZSBTaWdu
# aW5nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3VDNydJ15ZvgmCQsS406H
# wn15rryd2y1lZDkofCjLZqVGkBlwOMGE1Mmdh/rNROu26NCpSGvDqX/SIIiLWDY3
# djmNhSakpLx2sYDCK+Ev0hNazoyBy0je70pim1yY9T2HwJs7uq71A8N/FmBRidVw
# mGGCSm8HrkFWcIFGMiOMCQIDAQABo4IDFzCCAxMwPAYJKwYBBAGCNxUHBC8wLQYl
# KwYBBAGCNxUIhcjOCYKl1k2G5Y8qh7PAeofoxhpYjYMmg83tGgIBZAIBBTATBgNV
# HSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGCNxUKBA4wDDAK
# BggrBgEFBQcDAzAdBgNVHQ4EFgQU/2A0VkE2FjZFduXnv7/xBfP3uIwwHwYDVR0j
# BBgwFoAUUTG4xiNJ8Pl5dfIMgxYYeeC1AlowggFeBgNVHR8EggFVMIIBUTCCAU2g
# ggFJoIIBRYaBvGxkYXA6Ly8vQ049V01JQyUyMElzc3VpbmclMjBDQTAxLENOPVdQ
# RzFQSUNBMDEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNl
# cnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9d21pYyxEQz1pbnM/Y2VydGlmaWNh
# dGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlv
# blBvaW50hj9odHRwOi8vV1BHMVBJQ0EwMS53bWljLmlucy9DZXJ0RW5yb2xsL1dN
# SUMlMjBJc3N1aW5nJTIwQ0EwMS5jcmyGQ2h0dHA6Ly9jcmwtd21pYy5tc2FwcHBy
# b3h5Lm5ldC9DZXJ0RW5yb2xsL1dNSUMlMjBJc3N1aW5nJTIwQ0EwMS5jcmwwgfEG
# CCsGAQUFBwEBBIHkMIHhMIGxBggrBgEFBQcwAoaBpGxkYXA6Ly8vQ049V01JQyUy
# MElzc3VpbmclMjBDQTAxLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXdtaWMsREM9aW5zP2NB
# Q2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9y
# aXR5MCsGCCsGAQUFBzABhh9odHRwOi8vd3BnMXBpY2EwMS53bWljLmlucy9vY3Nw
# MA0GCSqGSIb3DQEBCwUAA4ICAQCWPYMuS+HT1YHGqKPP1nv63to5tzrWtqUOqs39
# ms4eTE510kpRCgemNvtzxsYrH7Np9RIdpcc+xIf9ekfOVPCn3gqUzaCilBRYksMV
# US/Qvg4FdxI0fJQ3qur37rnlOHRVeI+QXOWzDw8QXoxCf6FeB8ro4Iv/UDTzrhKn
# 8igsrStRkKbXJQVfZoG1eosXklNXL8g02FCSjkcV79A98xC5/EvcmATy2sF7jibn
# DvaMAmAxQJ+sT2GjNSN6puL4GcYN3hjbq0uxfK75ZbGyD3TEc/rF73K4/zb3EKvD
# KQLCVmO+42c1MDFQel5QUW789ZaW1qPwILtL9o5rabZTUERT+JgvZejZsi86C/+0
# Rl0uMIpOl9AbzGRy6XKJuWNzLF4cuVakhE+eri+odWmh+7jqTYZeQ40Wv0SCenv3
# 5m/TZBUUXRoaD11nPD6G/m61sj9YXkUIV39NGwBNw1ByQLiEeqK/LGoSoRw8d+JM
# +wfgfC4h1hbX+YNYdhugdmFP9NBZO01xs/7ch9xOwHTu3euLQJ2sHD4El3qUDPIG
# nOH6MUHBp8klyb4xzFzg0eQSFC0y0Wwc4KPqzBtYOlendkJnshRJXOfXgtMCvDos
# haTmU3lD3T48NkfeQRGsArhKY/y+EphOIuvUWkKULGde140a6BNSZu7SZ6fsJf77
# lkuZBTCCBuowggTSoAMCAQICE30AAAAJAKbIko6QQuEAAAAAAAkwDQYJKoZIhvcN
# AQELBQAwGjEYMBYGA1UEAxMPV01JQyBSb290IENBIDAxMB4XDTI0MDIxMjE2MjQy
# NVoXDTM0MDIxMjE2MzQyNVowRzETMBEGCgmSJomT8ixkARkWA2luczEUMBIGCgmS
# JomT8ixkARkWBHdtaWMxGjAYBgNVBAMTEVdNSUMgSXNzdWluZyBDQTAxMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwrPArtoeoEFc6/NZjqfPsegetEUe
# zL3FOC1a/kLFR7mUAFX1KEBmZpSCisF+yimREqNiySvi93vGTEEhwJDHxzWulEvD
# Yyxy+/tGNf7ArXkKaAgr0CT7wm0795tBDm+dynnrkt9IA0mXOz4BlbIkzrCPFPCh
# oWHr7VvXHjxwN/xF2LLWOQtS9/UNNuN7GnGgr0jZGg4e3dWuGM+Kvp6D2hvVIxMc
# GdCyCrdd1UzmBg4Z5YTqDvcOYdQR2+c51bd6USoSGsDrYvw4kNB1DO3MLJxosOIH
# 3Zs7TEKYGf30UVxTfCl33QC9IuVHa0AJasmON2yCSRgRStYzIWLGqy8A3axdPiJm
# SxjZsQh912ktCzkuxcqD6tWBxejtJkyYfj5vHqRdj6YEqseNItnMkQ6qHBMjw0s4
# eiR/sYxFbqt784+s7xrxkVwgWVL/mdmAxZz9XyQO7El29AzPgJqBNHx8zYrVZbKY
# 3SICXgUgHCwFuWRBSpJOjdXknl+FpiBxGCErbohxSUP7jxvRcGAftca6HSVli1S2
# o4wwk4B86vnJDtn9pPn/QCLQ3Jo3o+q/OlwDcRx2XQ+UimKCfHiRCCsP/YolGTT6
# 2sg/bnVyqaliBTgKFtYc0wt5uIYNzRMkp50rvKiOiFIoBb0vSL1z+HsSlXd8zlcz
# k1X19z40DiTmiEsCAwEAAaOCAfowggH2MBAGCSsGAQQBgjcVAQQDAgEBMCMGCSsG
# AQQBgjcVAgQWBBQPtiw4DpaiSoUoPvHpoh3GMjmCcjAdBgNVHQ4EFgQUUTG4xiNJ
# 8Pl5dfIMgxYYeeC1AlowGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0P
# BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUAi/hzyjrt1Yz26ga
# Bpiw81v6wkgwgYkGA1UdHwSBgTB/MH2ge6B5hjhmaWxlOi8vLy9XUEcxUFJDQTAx
# L0NlcnRFbnJvbGwvV01JQyUyMFJvb3QlMjBDQSUyMDAxLmNybIY9aHR0cDovL1dQ
# RzFQSUNBMDEud21pYy5pbnMvQ2VydERhdGEvV01JQyUyMFJvb3QlMjBDQSUyMDAx
# LmNybDCBtwYIKwYBBQUHAQEEgaowgacwTwYIKwYBBQUHMAKGQ2ZpbGU6Ly8vL1dQ
# RzFQUkNBMDEvQ2VydEVucm9sbC9XUEcxUFJDQTAxX1dNSUMlMjBSb290JTIwQ0El
# MjAwMS5jcnQwVAYIKwYBBQUHMAKGSGh0dHA6Ly9XUEcxUElDQTAxLndtaWMuaW5z
# L0NlcnREYXRhL1dQRzFQUkNBMDFfV01JQyUyMFJvb3QlMjBDQSUyMDAxLmNydDAN
# BgkqhkiG9w0BAQsFAAOCAgEAmttT+K3/bsVz7f00qdPkSaYPU5Mosht8sS+F3JQG
# vZHBL4knQBXS+/THLTEnSNqmymEAhe8015tz+5rP5e6+tjhr40k+Q3PbTm77UyS2
# eUEQ5tA5cWFfhfpBQmdwitEij6A2YtezsDfH+Zsbq5sO2NNMVqbuuIZHAMQgVj+2
# Djkjp+c/JmUowEskwt8dahlj6Y31kAvZFs0nxe1eev8Hnou7/y7RN1+6LRXMviXS
# 0fbIkv8TJGrgGDV+YQBY3NlJ7Cclhjf6GoEn7wcMeg+iz1MCImpqyhwk9VoOobT5
# Gpr55sVXyD4c152PVitvVrwUrCObZxa5yHDUPc6KYkotzjfHtJkoU4BQsPZ+CEBQ
# 7gmQZ0e2wEJyjK5x9p0Z9STMDcub/oGiuMG3cU7f1zt8NyTW7TWmiyjo/W/iF83K
# xMViAYhLXX4GWM1Nt6bezMUgsNEkusddiVRd/zJvviBZqNGCECGbuln/t6VB/77a
# zXOXlN/78lahxcoxx7FYmHVXLYDOl2s5cS1Mn8s52iZBVLMK2lbGu6sHeI3OuU0t
# h1t87KppyaHtuFEr2J0Iz1jai5TTaJQ2x1V/XW+Lbu+8QgAYLClQKKe0CLgmJ7gQ
# S5JKxZ3phqsr5fT8yTaiY/J/jMekSzrEUN2lgG43P8Z9U2UMcAa8ENTmgEF6/zmK
# JfUxggF+MIIBegIBATBeMEcxEzARBgoJkiaJk/IsZAEZFgNpbnMxFDASBgoJkiaJ
# k/IsZAEZFgR3bWljMRowGAYDVQQDExFXTUlDIElzc3VpbmcgQ0EwMQITRQACH1d/
# naH/S4uqGwABAAIfVzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUWdt+BqiyNUsi11d3+Oy4xQyF
# +1UwDQYJKoZIhvcNAQEBBQAEgYBwo9MWX2Xf8ULxgXe36s9q1l+asv/FWX37wcwA
# Kv+OnjCf/wMo2+Ct+Kl+SS8ka5+xfGwgEsZrM17ERnK5IiqexrR6KkvgzZ9dWXQr
# GLwRRRkTO3rAUhq6Xs2pnC3VCSa0bbzszhcyu7y9ruS0dchn+/5snkbWRwlh4qMk
# U28U6g==
# SIG # End signature block
