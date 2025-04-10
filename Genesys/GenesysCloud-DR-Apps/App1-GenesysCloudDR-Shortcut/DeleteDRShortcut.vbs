option explicit
On Error Resume Next

' Hardcoded title to avoid command-line parameter issues
Dim Title
Title = "Genesys Cloud DR"

' Objects
Dim Shell, FileSystem, DesktopPath

Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")

DesktopPath = Shell.SpecialFolders("Desktop")

' Delete the shortcut
FileSystem.DeleteFile DesktopPath & "\" & Title & ".lnk"

' Success without popup
' Do not use WScript.Echo as it causes a popup 