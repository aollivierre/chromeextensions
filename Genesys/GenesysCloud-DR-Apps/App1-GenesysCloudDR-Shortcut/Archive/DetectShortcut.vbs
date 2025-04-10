option explicit

Dim Title, Targets, Arguments
Title = "Genesys Cloud DR"
Targets = Array("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
Arguments = Array("--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr")

Dim Shell
Dim DesktopPath
Dim Shortcut

Set Shell = CreateObject("WScript.Shell")
DesktopPath = Shell.SpecialFolders("Desktop")

' Check if shortcut exists
Dim FileSystem
Set FileSystem = CreateObject("Scripting.FileSystemObject")
If Not FileSystem.FileExists(DesktopPath & "\" & Title & ".lnk") Then
    WScript.Quit
End If

Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")

Dim TargetMatch, ArgumentMatch
TargetMatch = False
ArgumentMatch = False

Dim i
For i = 0 to UBound(Targets)
    If StrComp(Targets(i), Shortcut.TargetPath, 1) = 0 Then
        TargetMatch = True
    End If
Next

For i = 0 to UBound(Arguments)
    If InStr(1, Shortcut.Arguments, Arguments(i), 1) > 0 Then
        ArgumentMatch = True
    End If
Next

If TargetMatch = True AND ArgumentMatch = True Then
    WScript.Echo "DETECTED"
End If 