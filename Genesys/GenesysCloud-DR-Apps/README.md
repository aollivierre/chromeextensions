# Genesys Cloud DR Applications for SCCM

This project contains SCCM applications designed to provide a differentiated experience for the Genesys Cloud Disaster Recovery (DR) environment by deploying a custom browser extension.

**Recommended Enterprise Standard:** For robust, reliable, and centrally managed enterprise deployment (SCCM, Intune), the standard and supported method is to:
1.  Publish the extension to the respective browser's web store (e.g., Chrome Web Store, Microsoft Edge Add-ons). For internal use, visibility can often be set to 'Unlisted' or 'Private'.
2.  Deploy the extension using enterprise policies such as `ExtensionInstallForcelist` (for Chrome) or its equivalent for Edge, referencing the extension's Web Store ID. This ensures the extension is properly installed and active across all browser instances and profiles on managed devices.

The applications below describe this policy-based deployment. The older `--load-extension` method (which involved local file installations) is no longer the primary approach and has significant limitations in enterprise environments.

## Applications

### App1-GenesysCloudDR-Shortcut
This application creates a desktop shortcut that launches Chrome in application mode, pointing to the Genesys Cloud DR environment. The shortcut uses a distinctive icon for easy identification.
*   Deployment Type: User deployment
*   Dependencies: App2-GenesysCloudDR-Extension and App3-GenesysCloudDR-EdgeExtension (to ensure both Chrome and Edge extensions are configured for installation, so users receiving the shortcut will have the extension available in both browsers).

### App2-GenesysCloudDR-Extension
This application configures Google Chrome to automatically install and enable the custom Genesys Cloud DR extension from the Chrome Web Store. It achieves this by adding an entry to the `ExtensionInstallForcelist` registry policy, pointing to the extension's ID and update URL.
*   Deployment Type: System deployment
*   Dependencies: None
*   This application ensures the Chrome extension is managed via enterprise policy.

### App3-GenesysCloudDR-EdgeExtension
This application is similar to App2 but targets Microsoft Edge. It configures Edge to automatically install and enable the custom Genesys Cloud DR extension from the Microsoft Edge Add-ons store. It achieves this by adding an entry to the `ExtensionInstallForcelist` registry policy at `HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`, pointing to the extension's ID and update URL (`bekjclbbemboommhkppfcdpeaddfajnm;https://edge.microsoft.com/extensionwebstorebase/v1/crx`).
*   Deployment Type: System deployment
*   Dependencies: None
*   This application ensures the Edge extension is managed via enterprise policy.

## Deployment Order

1.  Deploy App2-GenesysCloudDR-Extension (configures Chrome to install the extension from the Web Store).
2.  Deploy App3-GenesysCloudDR-EdgeExtension (configures Edge to install the extension from its Web Store).
3.  Deploy App1-GenesysCloudDR-Shortcut (creates the desktop shortcut. Due to SCCM dependencies, installing App1 will ensure App2 and App3 are also processed if not already present).

## Technology Used

*   App1 uses VBScript for installation, detection, and uninstallation of the shortcut.
*   App2 uses PowerShell to configure Chrome's `ExtensionInstallForcelist` policy for the extension.
*   App3 uses PowerShell to configure Microsoft Edge's `ExtensionInstallForcelist` policy.
*   The Chrome and Edge extensions are implemented using manifest v3 with CSS styling.

## Key Policy Details

*   App2 (Chrome): Configures `HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist` with the extension ID (`bekjclbbemboommhkppfcdpeaddfajnm`) and update URL (`https://clients2.google.com/service/update2/crx`).
*   App3 (Edge): Configures `HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist` with the extension ID (`pkggbpdkbnahidijamikngnlpfgepabn`) and update URL (`https://edge.microsoft.com/extensionwebstorebase/v1/crx`).
*   Custom icons are used for visual differentiation of the shortcut created by App1. 