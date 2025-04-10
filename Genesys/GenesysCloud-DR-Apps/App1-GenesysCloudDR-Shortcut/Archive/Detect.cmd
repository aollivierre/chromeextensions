@echo off
REM Detection script for Genesys Cloud DR Shortcut

REM Run detection VBScript and capture output
FOR /F "tokens=*" %%a IN ('cscript //nologo DetectShortcut.vbs') DO SET DETECTED=%%a

REM Check if shortcut was detected
IF "%DETECTED%"=="DETECTED" (
    REM Exit silently if shortcut is detected (installed)
    exit /b 0
) ELSE (
    REM Output message if shortcut is not detected (needs to be installed)
    echo Action is needed
    exit /b 0
) 