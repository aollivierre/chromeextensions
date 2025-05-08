# Genesys Cloud DR Chrome Extension Files (App2)

This SCCM application installs the custom Chrome extension **source files** to a local directory. It serves as a prerequisite for App1 (Genesys Cloud DR Shortcut) **when using the `--load-extension` method**, ensuring the files are present at the expected path for the shortcut to reference.

**Important Considerations:**
*   This application **does not install the extension into Chrome**. It only copies the files (`manifest.json`, `.css`, `.js`).
*   The effectiveness of this approach relies entirely on App1 successfully launching Chrome with the `--load-extension` parameter.
*   The `--load-extension` method has limitations:
    *   It fails if enterprise policies block extensions (`ExtensionInstallBlocklist` = `*`).
    *   The extension is only active in the specific Chrome instance launched by the App1 shortcut.

**Recommended Enterprise Deployment:** For reliable, persistent, and centrally managed deployment, publishing the extension to the **Chrome Web Store** (can be 'Unlisted') and deploying via the **`ExtensionInstallForcelist`** policy using the Web Store ID is the standard and supported method. In that scenario, this App2 package (for copying source files) would likely be unnecessary.

## Files

*   `Install-GenesysCloudDRExtension.ps1`: PowerShell script that copies the Chrome extension *source files* to Program Files.
*   `Detect-GenesysCloudDRExtension.ps1`: PowerShell script that detects if the extension *files* are present in the target directory.
*   `Uninstall-GenesysCloudDRExtension.ps1`: PowerShell script that removes the extension *files*.
*   `Extension/`: Directory containing the Chrome extension source files:
    *   `manifest.json`: Extension manifest file
    *   `dr-style.css`: CSS styling for visual differentiation
    *   `dr-script.js`: (Optional) JavaScript logic

## SCCM Configuration (for --load-extension file deployment)

*   **Installation Program**: `powershell.exe -ExecutionPolicy Bypass -File Install-GenesysCloudDRExtension.ps1`
*   **Uninstallation Program**: `powershell.exe -ExecutionPolicy Bypass -File Uninstall-GenesysCloudDRExtension.ps1`
*   **Detection Method**: Use a script checking for the presence of key files (e.g., `manifest.json`) in the installation location: `powershell.exe -ExecutionPolicy Bypass -File Detect-GenesysCloudDRExtension.ps1`
*   **Dependencies**: None (this application is a dependency for App1 *when using the `--load-extension` method*)
*   **User Experience**: Install for system
*   **Target**: System-targeted application

## Extension Details (Functionality)

The Chrome extension itself adds a red banner at the top of the Genesys Cloud DR environment with the text "DR ENVIRONMENT" to visually differentiate it from the production environment. The extension matches the URL pattern for the DR environment: `https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr*`

## Installation Location (of Files)

The extension *source files* are installed by this application to:
```
C:\Program Files\GenesysPOC\ChromeExtension\
```

This allows the App1 shortcut's Chrome instance to load it with the `--load-extension="C:\Program Files\GenesysPOC\ChromeExtension"` parameter. 