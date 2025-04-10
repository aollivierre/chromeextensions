@echo off
REM Alternative Install script for Genesys Cloud DR Shortcut
REM Uses a different approach to handle paths with spaces

set TITLE=Genesys Cloud DR
set ICON=GenesysCloud_DR_256.ico
set TARGET=C:\Program Files\Google\Chrome\Application\chrome.exe
set EXTENSIONPATH=C:\Program Files\GenesysPOC\ChromeExtension
set USERDATAPATH=C:\Temp\GenesysPOC\ChromeUserData

REM First ensure directories exist
mkdir "%USERDATAPATH%" 2>nul
mkdir "%EXTENSIONPATH%" 2>nul

REM Construct arguments with proper quoting
set ARGS=--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir="%USERDATAPATH%" --load-extension="%EXTENSIONPATH%" --no-first-run
set WORKDIR=C:\Program Files\Google\Chrome\Application\

REM Create shortcut using WScript.Shell directly (more reliable than VBS for preserving quotes)
powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $shortcut = $ws.CreateShortcut($desktop + '\%TITLE%.lnk'); $shortcut.TargetPath = '%TARGET%'; $shortcut.Arguments = '%ARGS%'; $shortcut.WorkingDirectory = '%WORKDIR%'; $shortcut.IconLocation = '$env:USERPROFILE\AppData\Local\Microsoft\Windows\%ICON%, 0'; $shortcut.Save()"

echo Genesys Cloud DR shortcut created successfully.
exit /b 0 