﻿$ExtensionID = "bekjclbbemboommhkppfcdpeaddfajnm"

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
# MIIltwYJKoZIhvcNAQcCoIIlqDCCJaQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBrjTre+rDP7X9thuQ3QGL1tB
# BWeggiB/MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0B
# AQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz
# 7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS
# 5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7
# bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfI
# SKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jH
# trHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14
# Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2
# h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt
# 6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPR
# iQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ER
# ElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4K
# Jpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRV
# HSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyh
# hyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO
# 0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo
# 8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++h
# UD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5x
# aiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGijCCBHKg
# AwIBAgITRQACH1d/naH/S4uqGwABAAIfVzANBgkqhkiG9w0BAQsFADBHMRMwEQYK
# CZImiZPyLGQBGRYDaW5zMRQwEgYKCZImiZPyLGQBGRYEd21pYzEaMBgGA1UEAxMR
# V01JQyBJc3N1aW5nIENBMDEwHhcNMjQxMTA0MTUyNTQzWhcNMjcxMTA0MTUyNTQz
# WjAhMR8wHQYDVQQDExZDb25maWdNZ3IgQ29kZSBTaWduaW5nMIGfMA0GCSqGSIb3
# DQEBAQUAA4GNADCBiQKBgQC3VDNydJ15ZvgmCQsS406Hwn15rryd2y1lZDkofCjL
# ZqVGkBlwOMGE1Mmdh/rNROu26NCpSGvDqX/SIIiLWDY3djmNhSakpLx2sYDCK+Ev
# 0hNazoyBy0je70pim1yY9T2HwJs7uq71A8N/FmBRidVwmGGCSm8HrkFWcIFGMiOM
# CQIDAQABo4IDFzCCAxMwPAYJKwYBBAGCNxUHBC8wLQYlKwYBBAGCNxUIhcjOCYKl
# 1k2G5Y8qh7PAeofoxhpYjYMmg83tGgIBZAIBBTATBgNVHSUEDDAKBggrBgEFBQcD
# AzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAdBgNV
# HQ4EFgQU/2A0VkE2FjZFduXnv7/xBfP3uIwwHwYDVR0jBBgwFoAUUTG4xiNJ8Pl5
# dfIMgxYYeeC1AlowggFeBgNVHR8EggFVMIIBUTCCAU2gggFJoIIBRYaBvGxkYXA6
# Ly8vQ049V01JQyUyMElzc3VpbmclMjBDQTAxLENOPVdQRzFQSUNBMDEsQ049Q0RQ
# LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
# Z3VyYXRpb24sREM9d21pYyxEQz1pbnM/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlz
# dD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hj9odHRwOi8v
# V1BHMVBJQ0EwMS53bWljLmlucy9DZXJ0RW5yb2xsL1dNSUMlMjBJc3N1aW5nJTIw
# Q0EwMS5jcmyGQ2h0dHA6Ly9jcmwtd21pYy5tc2FwcHByb3h5Lm5ldC9DZXJ0RW5y
# b2xsL1dNSUMlMjBJc3N1aW5nJTIwQ0EwMS5jcmwwgfEGCCsGAQUFBwEBBIHkMIHh
# MIGxBggrBgEFBQcwAoaBpGxkYXA6Ly8vQ049V01JQyUyMElzc3VpbmclMjBDQTAx
# LENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxD
# Tj1Db25maWd1cmF0aW9uLERDPXdtaWMsREM9aW5zP2NBQ2VydGlmaWNhdGU/YmFz
# ZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MCsGCCsGAQUFBzAB
# hh9odHRwOi8vd3BnMXBpY2EwMS53bWljLmlucy9vY3NwMA0GCSqGSIb3DQEBCwUA
# A4ICAQCWPYMuS+HT1YHGqKPP1nv63to5tzrWtqUOqs39ms4eTE510kpRCgemNvtz
# xsYrH7Np9RIdpcc+xIf9ekfOVPCn3gqUzaCilBRYksMVUS/Qvg4FdxI0fJQ3qur3
# 7rnlOHRVeI+QXOWzDw8QXoxCf6FeB8ro4Iv/UDTzrhKn8igsrStRkKbXJQVfZoG1
# eosXklNXL8g02FCSjkcV79A98xC5/EvcmATy2sF7jibnDvaMAmAxQJ+sT2GjNSN6
# puL4GcYN3hjbq0uxfK75ZbGyD3TEc/rF73K4/zb3EKvDKQLCVmO+42c1MDFQel5Q
# UW789ZaW1qPwILtL9o5rabZTUERT+JgvZejZsi86C/+0Rl0uMIpOl9AbzGRy6XKJ
# uWNzLF4cuVakhE+eri+odWmh+7jqTYZeQ40Wv0SCenv35m/TZBUUXRoaD11nPD6G
# /m61sj9YXkUIV39NGwBNw1ByQLiEeqK/LGoSoRw8d+JM+wfgfC4h1hbX+YNYdhug
# dmFP9NBZO01xs/7ch9xOwHTu3euLQJ2sHD4El3qUDPIGnOH6MUHBp8klyb4xzFzg
# 0eQSFC0y0Wwc4KPqzBtYOlendkJnshRJXOfXgtMCvDoshaTmU3lD3T48NkfeQRGs
# ArhKY/y+EphOIuvUWkKULGde140a6BNSZu7SZ6fsJf77lkuZBTCCBq4wggSWoAMC
# AQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMy
# MzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJT
# QTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQAD
# ggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD
# +Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz
# 7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp
# 39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0Cs
# X7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OT
# rCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4
# EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEc
# azjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUo
# JEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfp
# mEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSy
# Px4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMB
# AAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUv
# cyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAO
# BgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEE
# azBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYB
# BQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYG
# Z4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ip
# RCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL
# 5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU
# 1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa
# 96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZgaNW
# hqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlL
# AlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14
# OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjT
# x/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7
# YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLf
# BInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r
# 5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwgga8MIIEpKADAgECAhALrma8Wrp/lYfG
# +ekE4zMEMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0
# MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUx
# MTI1MjM1OTU5WjBCMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxIDAe
# BgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDI0MIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAvmpzn/aVIauWMLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/Qow
# IEMSvgjEdEZ3v4vrrTHleW1JWGErrjOL0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7
# yijvoQ7ujm0u6yXF2v1CrzZopykD07/9fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHj
# es4fduksTHulntq9WelRWY++TFPxzZrbILRYynyEy7rS1lHQKFpXvo2GePfsMRhN
# f1F41nyEg5h7iOXv+vjX0K8RhUisfqw3TTLHj1uhS66YX2LZPxS4oaf33rp9Hlfq
# SBePejlYeEdU740GKQM7SaVSH3TbBL8R6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPx
# RNUNK6lYk2y1WSKour4hJN0SMkoaNV8hyyADiX1xuTxKaXN12HgR+8WulU2d6zhz
# XomJ2PleI9V2yfmfXSPGYanGgxzqI+ShoOGLomMd3mJt92nm7Mheng/TBeSA2z4I
# 78JpwGpTRHiT7yHqBiV2ngUIyCtd0pZ8zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ3
# 3c1HG93Vp6lJ415ERcC7bFQMRbxqrMVANiav1k425zYyFMyLNyE1QulQSgDpW9rt
# vVcIH7WvG9sqYup9j8z9J1XqbBZPJ5XLln8mS8wWmdDLnBHXgYly/p1DhoQo5fkC
# AwEAAaOCAYswggGHMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG
# /WwHATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQU
# n1csA3cOKBWQZqVjXu5Pkh92oFswWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRp
# bWVTdGFtcGluZ0NBLmNybDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1
# NlRpbWVTdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4
# hBJH2UOR9hHbm04IHdEoT8/T3HuBSyZeq3jSi5GXeWP7xCKhVireKCnCs+8GZl2u
# VYFvQe+pPTScVJeCZSsMo1JCoZN2mMew/L4tpqVNbSpWO9QGFwfMEy60HofN6V51
# sMLMXNTLfhVqs+e8haupWiArSozyAmGH/6oMQAh078qRh6wvJNU6gnh5OruCP1QU
# AvVSu4kqVOcJVozZR5RRb/zPd++PGE3qF1P3xWvYViUJLsxtvge/mzA75oBfFZSb
# dakHJe2BVDGIGVNVjOp8sNt70+kEoMF+T6tptMUNlehSR7vM+C13v9+9ZOUKzfRU
# AYSyyEmYtsnpltD/GWX8eM70ls1V6QG/ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CW
# T/xrW7twipXTJ5/i5pkU5E16RSBAdOp12aw8IQhhA/vEbFkEiF2abhuFixUDobZa
# A0VhqAsMHOmaT3XThZDNi5U2zHKhUs5uHHdG6BoQau75KiNbh0c+hatSF+02kULk
# ftARjsyEpHKsF7u5zKRbt5oK5YGwFvgc4pEVUNytmB3BpIiowOIIuDgP5M9WArHY
# SAR16gc0dP2XdkMEP5eBsX7bf/MGN4K3HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzL
# P8lx4Q1zZKDyHcp4VQJLu2kWTsKsOqQwggbqMIIE0qADAgECAhN9AAAACQCmyJKO
# kELhAAAAAAAJMA0GCSqGSIb3DQEBCwUAMBoxGDAWBgNVBAMTD1dNSUMgUm9vdCBD
# QSAwMTAeFw0yNDAyMTIxNjI0MjVaFw0zNDAyMTIxNjM0MjVaMEcxEzARBgoJkiaJ
# k/IsZAEZFgNpbnMxFDASBgoJkiaJk/IsZAEZFgR3bWljMRowGAYDVQQDExFXTUlD
# IElzc3VpbmcgQ0EwMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMKz
# wK7aHqBBXOvzWY6nz7HoHrRFHsy9xTgtWv5CxUe5lABV9ShAZmaUgorBfsopkRKj
# Yskr4vd7xkxBIcCQx8c1rpRLw2Mscvv7RjX+wK15CmgIK9Ak+8JtO/ebQQ5vncp5
# 65LfSANJlzs+AZWyJM6wjxTwoaFh6+1b1x48cDf8Rdiy1jkLUvf1DTbjexpxoK9I
# 2RoOHt3VrhjPir6eg9ob1SMTHBnQsgq3XdVM5gYOGeWE6g73DmHUEdvnOdW3elEq
# EhrA62L8OJDQdQztzCycaLDiB92bO0xCmBn99FFcU3wpd90AvSLlR2tACWrJjjds
# gkkYEUrWMyFixqsvAN2sXT4iZksY2bEIfddpLQs5LsXKg+rVgcXo7SZMmH4+bx6k
# XY+mBKrHjSLZzJEOqhwTI8NLOHokf7GMRW6re/OPrO8a8ZFcIFlS/5nZgMWc/V8k
# DuxJdvQMz4CagTR8fM2K1WWymN0iAl4FIBwsBblkQUqSTo3V5J5fhaYgcRghK26I
# cUlD+48b0XBgH7XGuh0lZYtUtqOMMJOAfOr5yQ7Z/aT5/0Ai0NyaN6PqvzpcA3Ec
# dl0PlIpignx4kQgrD/2KJRk0+trIP251cqmpYgU4ChbWHNMLebiGDc0TJKedK7yo
# johSKAW9L0i9c/h7EpV3fM5XM5NV9fc+NA4k5ohLAgMBAAGjggH6MIIB9jAQBgkr
# BgEEAYI3FQEEAwIBATAjBgkrBgEEAYI3FQIEFgQUD7YsOA6WokqFKD7x6aIdxjI5
# gnIwHQYDVR0OBBYEFFExuMYjSfD5eXXyDIMWGHngtQJaMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFAIv4c8o67dWM9uoGgaYsPNb+sJIMIGJBgNVHR8EgYEwfzB9oHugeYY4
# ZmlsZTovLy8vV1BHMVBSQ0EwMS9DZXJ0RW5yb2xsL1dNSUMlMjBSb290JTIwQ0El
# MjAwMS5jcmyGPWh0dHA6Ly9XUEcxUElDQTAxLndtaWMuaW5zL0NlcnREYXRhL1dN
# SUMlMjBSb290JTIwQ0ElMjAwMS5jcmwwgbcGCCsGAQUFBwEBBIGqMIGnME8GCCsG
# AQUFBzAChkNmaWxlOi8vLy9XUEcxUFJDQTAxL0NlcnRFbnJvbGwvV1BHMVBSQ0Ew
# MV9XTUlDJTIwUm9vdCUyMENBJTIwMDEuY3J0MFQGCCsGAQUFBzAChkhodHRwOi8v
# V1BHMVBJQ0EwMS53bWljLmlucy9DZXJ0RGF0YS9XUEcxUFJDQTAxX1dNSUMlMjBS
# b290JTIwQ0ElMjAwMS5jcnQwDQYJKoZIhvcNAQELBQADggIBAJrbU/it/27Fc+39
# NKnT5EmmD1OTKLIbfLEvhdyUBr2RwS+JJ0AV0vv0xy0xJ0japsphAIXvNNebc/ua
# z+XuvrY4a+NJPkNz205u+1MktnlBEObQOXFhX4X6QUJncIrRIo+gNmLXs7A3x/mb
# G6ubDtjTTFam7riGRwDEIFY/tg45I6fnPyZlKMBLJMLfHWoZY+mN9ZAL2RbNJ8Xt
# Xnr/B56Lu/8u0Tdfui0VzL4l0tH2yJL/EyRq4Bg1fmEAWNzZSewnJYY3+hqBJ+8H
# DHoPos9TAiJqasocJPVaDqG0+Rqa+ebFV8g+HNedj1Yrb1a8FKwjm2cWuchw1D3O
# imJKLc43x7SZKFOAULD2fghAUO4JkGdHtsBCcoyucfadGfUkzA3Lm/6BorjBt3FO
# 39c7fDck1u01poso6P1v4hfNysTFYgGIS11+BljNTbem3szFILDRJLrHXYlUXf8y
# b74gWajRghAhm7pZ/7elQf++2s1zl5Tf+/JWocXKMcexWJh1Vy2AzpdrOXEtTJ/L
# OdomQVSzCtpWxrurB3iNzrlNLYdbfOyqacmh7bhRK9idCM9Y2ouU02iUNsdVf11v
# i27vvEIAGCwpUCintAi4Jie4EEuSSsWd6YarK+X0/Mk2omPyf4zHpEs6xFDdpYBu
# Nz/GfVNlDHAGvBDU5oBBev85iiX1MYIEojCCBJ4CAQEwXjBHMRMwEQYKCZImiZPy
# LGQBGRYDaW5zMRQwEgYKCZImiZPyLGQBGRYEd21pYzEaMBgGA1UEAxMRV01JQyBJ
# c3N1aW5nIENBMDECE0UAAh9Xf52h/0uLqhsAAQACH1cwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FKTSsHSg/A+xvoHPg7vgdj8S3BxnMA0GCSqGSIb3DQEBAQUABIGALzJjf4bzxvxq
# VDernX61E1bwGF+f5oJlHCcEe1t+uaPO2YPgAD2Lu+1OEYCaPoPFOAGnC71cvAYB
# ODvWu0o9jFVAgNoCdyLU5E0OYX5hy1cCJhFj+NunjoajEv4ATigddLo4ra+qaa/F
# +fCihtYWHfTwid3lKde/qFmYkrh7tg6hggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCC
# AwkCAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGlt
# ZVN0YW1waW5nIENBAhALrma8Wrp/lYfG+ekE4zMEMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjUwNDE0
# MTMyODUwWjAvBgkqhkiG9w0BCQQxIgQgaY0FYT/zecN8p+0zDOayFxPBfRbAP+iN
# OwO2fIt7m7cwDQYJKoZIhvcNAQEBBQAEggIAc8jrGLeA0ocH48acXB6/lomU4XVI
# 9ietbsUk9jgb50TpuUXR2peVHbwGUVnSRaFF6zrFdh8I9612yTDk4wzY7+jbIDpP
# TOU4tY2Z4zqzDD5WGfVvr4umLsL6DdPkZqhKwgzCB5eRKs0ApRR/Q4xD/Ru4v1uX
# 8OPcgWKDMb9kG7DcVgpALJ1X0E/txQmvgonmT4ZvxdBbL6FIzNJAjKmUZVIHLNho
# OngUEX+rA/MsYS9jvxrKOYc8Na0UMBrVnW4HAsHN4TzFZpO4HCaP7KAxnF/zbZWW
# vcIV1LnYBZkBmIooeV5a05b+qYEonr0FoKTamd6TYdvLg+wfLuy4ihLrsglULF4G
# TittV8v1QLvU0Up8Gfgf2hedGWBltFozIzKZPmyzPNY2h3sMkvg0xEqDXqDX4W+j
# FbzxcjKsFxuPl7mhNnbMzSjVyAjbowaxQC7lvETBSZcVyaGBqW3GbfR1gK1CdtYf
# k5n1RWhpL1Vd+E3h30TQLYBFm2yX8w3eHTpRjkS1fDTztoYTTK8Ffj6Qut7l2oxd
# DPJ28RX63HFGzeuL1qel6ec+373szj1R3FGQ3qmHQSGm6laJAwmqkELhuGCiDU0l
# zVTSCUOxdoq2qs4vJ2pY8EtFECB/r6LMHkv6oOk/4VVniJCVt0sC7SMK5w6WuCJc
# SaUBzZxp4o8/5FM=
# SIG # End signature block
