@echo off
REM Uninstall script for Genesys Cloud DR Shortcut

set TITLE=Genesys Cloud DR

REM Delete shortcut using VBScript
cscript //nologo DeleteShortcut.vbs "%TITLE%"

echo Genesys Cloud DR shortcut removed successfully.
exit /b 0 