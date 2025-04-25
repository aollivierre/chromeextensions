# Genesys Cloud DR Applications for SCCM

This project contains two SCCM applications designed to provide a differentiated experience for the Genesys Cloud Disaster Recovery (DR) environment using a specific shortcut-based approach.

**Important Note on Deployment Method:** The approach implemented here relies on App2 installing extension source files locally and App1 creating a shortcut that launches Chrome using the `--load-extension` command-line parameter pointing to those local files. This method has significant limitations for enterprise environments:
*   It will **only work if Chrome's `ExtensionInstallBlocklist` policy does not contain a wildcard (`*`)** to block all extensions.
*   The extension is **only active in the specific Chrome instance launched by the custom shortcut (App1)**. It will not be active in other Chrome windows or profiles opened normally.
*   Managing updates requires redeploying the files via App2 and potentially updating the shortcut via App1 if paths change.

**Recommended Enterprise Standard:** For robust, reliable, and centrally managed enterprise deployment (SCCM, Intune), the standard and supported method is to:
1.  Publish the extension to the **Chrome Web Store** (can be set to 'Unlisted' visibility for internal use).
2.  Deploy the extension using the **`ExtensionInstallForcelist`** enterprise policy, referencing the extension's **Web Store ID**. This ensures the extension is properly installed and active across all Chrome instances and profiles on managed devices, independent of specific shortcuts.

The applications below describe the `--load-extension` implementation.

## Applications

### App2-GenesysCloudDR-Extension

This application installs the custom Chrome extension *source files* to a local directory (`C:\\Program Files\\GenesysPOC\\ChromeExtension\\`). It does **not** install the extension into Chrome itself. Its primary purpose is to make the extension files available for App1's shortcut.

*   Deployment Type: System deployment
*   Dependencies: None
*   This application must be installed before App1 *if using the `--load-extension` method*. (Note: This app might be unnecessary if deploying via Chrome Web Store policy).

### App1-GenesysCloudDR-Shortcut

This application creates a desktop shortcut that launches Chrome in application mode, pointing to the Genesys Cloud DR environment. The shortcut is configured to **load the unpacked extension from the local path** (installed by App2) using the `--load-extension` parameter and uses a distinctive icon.

*   Deployment Type: User deployment
*   Dependencies: App2-GenesysCloudDR-Extension (to ensure local extension files exist for the shortcut parameter)

## Deployment Order (for --load-extension method)

1.  Deploy App2-GenesysCloudDR-Extension (installs the extension *files* to Program Files)
2.  Deploy App1-GenesysCloudDR-Shortcut (creates the desktop shortcut referencing the local files via `--load-extension`)

## Technology Used

*   App1 uses VBScript for installation, detection, and uninstallation of the shortcut
*   App2 uses PowerShell for installation, detection, and uninstallation of the extension *files*
*   The Chrome extension is implemented using manifest v3 with CSS styling

## Key Files / Parameters (for --load-extension method)

*   App1 shortcut parameters: `--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --load-extension="C:\\Program Files\\GenesysPOC\\ChromeExtension" --no-first-run`
*   Extension source file location (deployed by App2): `C:\\Program Files\\GenesysPOC\\ChromeExtension\\`
*   Custom icons are used for visual differentiation 