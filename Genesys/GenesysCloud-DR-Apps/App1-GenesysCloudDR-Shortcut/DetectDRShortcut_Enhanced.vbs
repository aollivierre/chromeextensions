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
    ' Not detected - shortcut doesn't exist, exit silently
    WScript.Quit
End If

' Try to load shortcut properties
On Error Resume Next
Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")
If Err.Number <> 0 Then
    ' Not detected - shortcut is corrupted, exit silently
    WScript.Quit
End If
On Error Goto 0

Dim TargetMatch, ArgumentMatch, IconMatch, TargetExists
TargetMatch = False
ArgumentMatch = False
IconMatch = False
TargetExists = False

' Check if target matches one of our expected paths
Dim i
For i = 0 to UBound(Targets)
    If StrComp(Targets(i), Shortcut.TargetPath, 1) = 0 Then
        TargetMatch = True
        ' Also verify the target file actually exists
        If FileSystem.FileExists(Shortcut.TargetPath) Then
            TargetExists = True
        End If
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

' Additional validation: Check if shortcut icon location is set correctly
Dim IconLocationMatch
IconLocationMatch = False
If InStr(1, Shortcut.IconLocation, Icon, 1) > 0 Then
    IconLocationMatch = True
End If

' Output "DETECTED" only if ALL conditions are met - SCCM standard
' 1. Target matches expected Chrome paths
' 2. Target file actually exists (Chrome is installed)
' 3. Arguments contain the expected URL pattern
' 4. Icon file exists in the expected location
' 5. Shortcut icon location points to our icon
If TargetMatch = True AND TargetExists = True AND ArgumentMatch = True AND IconMatch = True AND IconLocationMatch = True Then
    WScript.Echo "DETECTED"
End If

' If not detected, script exits silently (no output) - SCCM standard 