option explicit
On Error Resume Next

Dim Args
Set Args = WScript.Arguments

Dim Title

Title = Args(0)

Dim Shell
Dim FileSystem
Dim DesktopPath

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")

DesktopPath = Shell.SpecialFolders("Desktop")
FileSystem.DeleteFile DesktopPath & "\" & Title & ".lnk"
