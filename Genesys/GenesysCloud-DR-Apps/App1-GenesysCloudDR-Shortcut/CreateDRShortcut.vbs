option explicit

' Hardcoded values to avoid command-line parameter issues
Dim Title, Icon, Target, Arguments, WorkingDir

Title = "Genesys Cloud DR"
Icon = "GenesysCloud_DR_256.ico"
Target = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Arguments = "--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=""C:\Temp\GenesysPOC\ChromeUserData"" --load-extension=""C:\Program Files\GenesysPOC\ChromeExtension"" --no-first-run"
WorkingDir = "C:\Program Files\Google\Chrome\Application\"

' Objects
Dim Shell, FileSystem, DesktopPath, IconPath, Shortcut

' Create user data directory if it doesn't exist
Set Shell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")

' Create user data dir if it doesn't exist, create parent folders first
On Error Resume Next
If Not FileSystem.FolderExists("C:\Temp") Then
    FileSystem.CreateFolder("C:\Temp")
End If
If Not FileSystem.FolderExists("C:\Temp\GenesysPOC") Then
    FileSystem.CreateFolder("C:\Temp\GenesysPOC")
End If
If Not FileSystem.FolderExists("C:\Temp\GenesysPOC\ChromeUserData") Then
    FileSystem.CreateFolder("C:\Temp\GenesysPOC\ChromeUserData")
End If
On Error Goto 0

' Set up paths
DesktopPath = Shell.SpecialFolders("Desktop")
IconPath = Shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\AppData\Local\Microsoft\Windows"

' Copy icon to Windows folder
On Error Resume Next
FileSystem.CopyFile Icon, IconPath & "\", True
On Error Goto 0

' Create the shortcut
Set Shortcut = Shell.CreateShortcut(DesktopPath & "\" & Title & ".lnk")
Shortcut.TargetPath = Target
Shortcut.Arguments = Arguments
Shortcut.WorkingDirectory = WorkingDir
Shortcut.IconLocation = IconPath & "\" & Icon & ", 0"
Shortcut.WindowStyle = 3
Shortcut.Save

' Report success
WScript.Echo "Genesys Cloud DR shortcut created successfully." 