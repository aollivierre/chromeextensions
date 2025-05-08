option explicit

Dim Args
Set Args = WScript.Arguments

Dim Title
Dim Icon
Dim Target
Dim Arguments
Dim WorkingDir

Title = Args(0)
Icon = Args(1)
Target = Args(2)
Arguments = Args(3)
WorkingDir = Args(4)

Dim Shell
Dim FileSystem

Dim DesktopPath
Dim IconPath
Dim Shortcut

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")

DesktopPath = Shell.SpecialFolders("Desktop")
IconPath = Shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\AppData\Local\Microsoft\Windows"

FileSystem.CopyFile ".\" & Icon, IconPath & "\", true 

Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")
Shortcut.TargetPath = Target
Shortcut.Arguments = Arguments
Shortcut.WorkingDirectory = WorkingDir
Shortcut.IconLocation = IconPath & "\" & Icon & ", 0"
Shortcut.WindowStyle = 3
Shortcut.Save
