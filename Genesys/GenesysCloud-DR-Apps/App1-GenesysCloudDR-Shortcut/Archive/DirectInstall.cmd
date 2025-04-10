@echo off
REM Direct Install script for Genesys Cloud DR Shortcut
REM Uses a completely direct approach with the exact working syntax

set TITLE=Genesys Cloud DR
set ICON=GenesysCloud_DR_256.ico

REM Ensure the user data directory exists
mkdir "C:\Temp\GenesysPOC\ChromeUserData" 2>nul

REM Copy icon to Windows folder
copy /Y "%ICON%" "%USERPROFILE%\AppData\Local\Microsoft\Windows\"

REM Create the shortcut directly with PowerShell to avoid any potential issues with VBScript
powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $shortcut = $ws.CreateShortcut($desktop + '\%TITLE%.lnk'); $shortcut.TargetPath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'; $shortcut.Arguments = '--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=\"C:\Temp\GenesysPOC\ChromeUserData\" --load-extension=\"C:\Program Files\GenesysPOC\ChromeExtension\"'; $shortcut.WorkingDirectory = 'C:\Program Files\Google\Chrome\Application\'; $shortcut.IconLocation = '$env:USERPROFILE\AppData\Local\Microsoft\Windows\%ICON%, 0'; $shortcut.WindowStyle = 3; $shortcut.Save()"

echo Genesys Cloud DR shortcut created successfully.
exit /b 0