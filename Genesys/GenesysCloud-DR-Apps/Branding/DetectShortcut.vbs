option explicit

Dim Title, Targets, Arguments
Title = "Genesys Cloud"
Targets = Array("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
Arguments = Array("--app=https://apps.cac1.pure.cloud:443")

Dim Shell
Dim DesktopPath
Dim Shortcut

Set Shell = CreateObject("WScript.Shell")
DesktopPath = Shell.SpecialFolders("Desktop")
Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")

Dim TargetMatch, ArgumentMatch
TargetMatch = false
ArgumentMatch = false

Dim i
For i = 0 to UBound(Targets)
	If StrComp(Targets(i), Shortcut.TargetPath, 1) = 0 Then
		TargetMatch = true
	End If
Next

For i = 0 to UBound(Arguments)
	If StrComp(Arguments(i), Shortcut.Arguments, 1) = 0 Then
		ArgumentMatch = true
	End If
Next

If TargetMatch = true AND ArgumentMatch = true Then
	WScript.Echo "DETECTED"
End If