@echo off
REM Install script for Genesys Cloud DR Shortcut
REM Direct approach without complex escaping

set TITLE=Genesys Cloud DR
set ICON=GenesysCloud_DR_256.ico

REM Create required directories
mkdir "C:\Temp\GenesysPOC\ChromeUserData" 2>nul

REM Copy the icon to Windows directory
copy /Y "%ICON%" "%USERPROFILE%\AppData\Local\Microsoft\Windows\" >nul

REM Create shortcut directly with PowerShell (bypassing VBS completely)
powershell -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $desktop = [Environment]::GetFolderPath('Desktop'); ^
   $shortcut = $ws.CreateShortcut($desktop + '\%TITLE%.lnk'); ^
   $shortcut.TargetPath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'; ^
   $shortcut.Arguments = '--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir=\"C:\Temp\GenesysPOC\ChromeUserData\" --load-extension=\"C:\Program Files\GenesysPOC\ChromeExtension\" --no-first-run'; ^
   $shortcut.WorkingDirectory = 'C:\Program Files\Google\Chrome\Application\'; ^
   $shortcut.IconLocation = '$env:USERPROFILE\AppData\Local\Microsoft\Windows\%ICON%, 0'; ^
   $shortcut.WindowStyle = 3; ^
   $shortcut.Save()"

echo Genesys Cloud DR shortcut created successfully.
exit /b 0 