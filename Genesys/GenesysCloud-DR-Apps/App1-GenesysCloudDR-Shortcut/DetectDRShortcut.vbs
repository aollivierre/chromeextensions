option explicit

' Hardcoded values to avoid command-line parameter issues
Dim Title, Targets, ArgumentPattern
Title = "Genesys Cloud DR"
Targets = Array("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
ArgumentPattern = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr"

' Objects
Dim Shell, FileSystem, DesktopPath, Shortcut

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")
DesktopPath = Shell.SpecialFolders("Desktop")

' Check if shortcut exists
If Not FileSystem.FileExists(DesktopPath & "\" & Title & ".lnk") Then
    WScript.Quit 0
End If

Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")

Dim TargetMatch, ArgumentMatch
TargetMatch = False
ArgumentMatch = False

' Check if target matches one of our expected paths
Dim i
For i = 0 to UBound(Targets)
    If StrComp(Targets(i), Shortcut.TargetPath, 1) = 0 Then
        TargetMatch = True
        Exit For
    End If
Next

' Check if arguments contain the expected pattern
If InStr(1, Shortcut.Arguments, ArgumentPattern, 1) > 0 Then
    ArgumentMatch = True
End If

' Output "DETECTED" if both target and arguments match (for SCCM)
If TargetMatch = True AND ArgumentMatch = True Then
    WScript.Echo "DETECTED"
End If 