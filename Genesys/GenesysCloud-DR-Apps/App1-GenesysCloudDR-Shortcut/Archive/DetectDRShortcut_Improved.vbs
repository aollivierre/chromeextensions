option explicit

' Hardcoded values to avoid command-line parameter issues
Dim Title, Icon, Targets, ArgumentPattern
Title = "Genesys Cloud DR"
Icon = "GenesysCloud_DR_256.ico"
Targets = Array("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
ArgumentPattern = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr"

' Objects
Dim Shell, FileSystem, DesktopPath, IconPath, Shortcut

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")
DesktopPath = Shell.SpecialFolders("Desktop")
IconPath = Shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\AppData\Local\Microsoft\Windows"

' Check if shortcut exists first
If Not FileSystem.FileExists(DesktopPath & "\" & Title & ".lnk") Then
    WScript.Quit 0
End If

Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")

Dim TargetMatch, ArgumentMatch, IconMatch
TargetMatch = False
ArgumentMatch = False
IconMatch = False

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

' Check if the icon file exists (critical for OneDrive sync issue)
If FileSystem.FileExists(IconPath & "\" & Icon) Then
    IconMatch = True
End If

' Output "DETECTED" only if target, arguments, AND icon all match
' This prevents false positives from OneDrive-synced shortcuts without icons
If TargetMatch = True AND ArgumentMatch = True AND IconMatch = True Then
    WScript.Echo "DETECTED"
End If 