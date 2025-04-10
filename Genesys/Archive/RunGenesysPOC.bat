@echo off
REM Genesys Environment Differentiation POC Launcher
echo Starting Genesys Environment Differentiation POC...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& { Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "".\GenesysEnvDifferentiation.ps1""' -Verb RunAs }"
echo If a UAC prompt appears, please click Yes to allow administrative access.
pause 