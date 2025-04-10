# Genesys Cloud DR Chrome Extension (App2)

This SCCM application installs the custom Chrome extension that provides visual differentiation for the Genesys Cloud DR environment. This application is a dependency for the Genesys Cloud DR Shortcut (App1).

## Files

- `Install-GenesysCloudDRExtension.ps1`: PowerShell script that copies the Chrome extension to Program Files
- `Detect-GenesysCloudDRExtension.ps1`: PowerShell script that detects if the extension is installed
- `Uninstall-GenesysCloudDRExtension.ps1`: PowerShell script that removes the extension
- `Extension/`: Directory containing the Chrome extension files:
  - `manifest.json`: Extension manifest file
  - `dr-style.css`: CSS styling for visual differentiation

## SCCM Configuration

- **Installation Program**: `powershell.exe -ExecutionPolicy Bypass -File Install-GenesysCloudDRExtension.ps1`
- **Uninstallation Program**: `powershell.exe -ExecutionPolicy Bypass -File Uninstall-GenesysCloudDRExtension.ps1`
- **Detection Method**: Use a script with `powershell.exe -ExecutionPolicy Bypass -File Detect-GenesysCloudDRExtension.ps1`
- **Dependencies**: None (this application is a dependency for App1)
- **User Experience**: Install for system
- **Target**: System-targeted application

## Extension Details

The Chrome extension adds a red banner at the top of the Genesys Cloud DR environment with the text "DR ENVIRONMENT" to visually differentiate it from the production environment. The extension matches the URL pattern for the DR environment: `https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr*`

## Installation Location

The extension is installed to:
```
C:\Program Files\GenesysPOC\ChromeExtension\
```

This allows Chrome to load it with the `--load-extension` parameter when launching the DR shortcut. 