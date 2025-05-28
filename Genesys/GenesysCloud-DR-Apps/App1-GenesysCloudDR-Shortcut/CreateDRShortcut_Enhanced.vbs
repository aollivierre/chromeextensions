option explicit

' Get script directory for icon path
Dim ScriptPath
ScriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

' Hardcoded values to avoid command-line parameter issues
Dim Title, Icon, Target, Arguments, WorkingDir

Title = "Genesys Cloud DR"
Icon = ScriptPath & "GenesysCloud_DR_256.ico"
Target = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Arguments = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --no-first-run"
WorkingDir = "C:\Program Files\Google\Chrome\Application\"

' Objects
Dim Shell, FileSystem, DesktopPath, IconPath, Shortcut

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")

' Validate Chrome installation first
If Not FileSystem.FileExists(Target) Then
    ' Try alternative Chrome path
    Target = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    WorkingDir = "C:\Program Files (x86)\Google\Chrome\Application\"
    If Not FileSystem.FileExists(Target) Then
        ' Chrome not found, exit with error
        WScript.Quit 1
    End If
End If

' Validate icon file exists before proceeding
If Not FileSystem.FileExists(Icon) Then
    WScript.Quit 2
End If

' Set up paths
DesktopPath = Shell.SpecialFolders("Desktop")
IconPath = Shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\AppData\Local\Microsoft\Windows"

' Ensure icon destination directory exists
On Error Resume Next
If Not FileSystem.FolderExists(IconPath) Then
    FileSystem.CreateFolder(IconPath)
    If Err.Number <> 0 Then WScript.Quit 6
End If
On Error Goto 0

' Copy icon to Windows folder
On Error Resume Next
FileSystem.CopyFile Icon, IconPath & "\", True
If Err.Number <> 0 Then WScript.Quit 7
On Error Goto 0

' Create the shortcut
On Error Resume Next
Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")
If Err.Number <> 0 Then WScript.Quit 8

Shortcut.TargetPath = Target
Shortcut.Arguments = Arguments
Shortcut.WorkingDirectory = WorkingDir
Shortcut.IconLocation = IconPath & "\GenesysCloud_DR_256.ico, 0"
Shortcut.WindowStyle = 3
Shortcut.Save
If Err.Number <> 0 Then WScript.Quit 9
On Error Goto 0

' Verify shortcut was created successfully
If Not FileSystem.FileExists(DesktopPath & "\" & Title & ".lnk") Then
    WScript.Quit 10
End If

' Success - exit code 0
WScript.Quit 0 