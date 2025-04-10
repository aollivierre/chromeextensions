# Genesys Cloud DR Applications for SCCM

This project contains two SCCM applications that work together to provide a differentiated experience for the Genesys Cloud Disaster Recovery (DR) environment.

## Applications

### App2-GenesysCloudDR-Extension

This application installs a custom Chrome extension that adds visual differentiation to the Genesys Cloud DR environment. The extension shows a red banner on the DR site to help users identify they are in the DR environment.

- Deployment Type: System deployment
- Dependencies: None
- This application must be installed before App1

### App1-GenesysCloudDR-Shortcut

This application creates a desktop shortcut that launches Chrome in application mode, pointing to the Genesys Cloud DR environment. The shortcut is configured to load the custom extension and uses a distinctive icon.

- Deployment Type: User deployment
- Dependencies: App2-GenesysCloudDR-Extension

## Deployment Order

1. Deploy App2-GenesysCloudDR-Extension (installs the extension to Program Files)
2. Deploy App1-GenesysCloudDR-Shortcut (creates the desktop shortcut with the custom icon)

## Technology Used

- App1 uses VBScript for installation, detection, and uninstallation
- App2 uses PowerShell for installation, detection, and uninstallation
- The Chrome extension is implemented using manifest v3 with CSS styling

## Key Files

- App1 shortcut parameters: `--app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --load-extension="C:\Program Files\GenesysPOC\ChromeExtension" --no-first-run`
- Extension location: `C:\Program Files\GenesysPOC\ChromeExtension\`
- Custom icons are used for visual differentiation 