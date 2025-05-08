# Genesys Cloud Environment Differentiation

This project provides visual differentiation between Genesys Cloud production and DR environments through custom shortcuts with Chrome extensions.

## Overview

The solution consists of several PowerShell scripts that create desktop shortcuts for Genesys Cloud environments with the following features:

1. **Visual differentiation** - Uses a red banner at the top of DR environment pages
2. **Custom icons** - Different icons for PROD vs DR environments
3. **Chrome extension** - Automatically loaded to display the DR environment banner

## Scripts

- **GenesysEnvDifferentiation_Chrome_Final.ps1** - Main deployment script that creates both PROD and DR shortcuts
- **ChromeExtensionTest.ps1** - Focused script for testing and troubleshooting the Chrome extension
- **TestShortcutScripts.ps1** - Comprehensive test suite for all shortcut features

## How It Works

1. The scripts create desktop shortcuts for both PROD and DR environments
2. The DR shortcut is configured to:
   - Load a custom Chrome extension that adds a red "DR ENVIRONMENT" banner
   - Use a dedicated Chrome user data directory to prevent extension conflicts
   - Apply a custom DR icon for easy visual identification

## Deploying via SCCM

**Important Note:** The method described below uses the `--load-extension` command-line parameter. This approach has significant limitations for enterprise deployment:
- It will **only work if Chrome's `ExtensionInstallBlocklist` policy does not contain a wildcard (`*`)** to block all extensions. Many enterprise environments implement this blocklist policy.
- The extension loaded via `--load-extension` is **only active in the specific Chrome instance launched by the custom shortcut**. It will not be active in other Chrome windows or profiles opened normally.
- This method relies on placing extension source files locally on each machine, which can be harder to manage and update than a centrally deployed extension.

**For a robust and manageable enterprise deployment (SCCM, Intune, etc.), the recommended and supported method is to publish the extension to the Chrome Web Store (can be 'Unlisted' for internal use) and deploy it using Chrome's enterprise policies (`ExtensionInstallForcelist`) referencing the Web Store ID.**

The following SCCM steps describe the `--load-extension` approach, keeping its limitations in mind:

1. **Create a Package**:
   - Create a new package in SCCM
   - Source folder should contain all the scripts and resources
   - Required files: 
     - GenesysEnvDifferentiation_Chrome_Final.ps1
     - Icons for PROD and DR
     - Extension files (manifest.json, dr-style.css, dr-script.js)

2. **Create a Program**:
   - Program type: Script
   - Command line: `powershell.exe -ExecutionPolicy Bypass -File "%~dp0GenesysEnvDifferentiation_Chrome_Final.ps1"`
   - Run mode: Run with administrative rights
   - Run whether or not user is logged on: Yes (to ensure proper installation for all users)

3. **Distribution Points**:
   - Distribute the package to your distribution points

4. **Deployment**:
   - Deploy to a collection of devices or users
   - Purpose: Required
   - Schedule: As soon as possible

## Extension Files Structure

The Chrome extension files are created in `C:\Program Files\GenesysPOC\ChromeExtension\` with the following structure:

```
ChromeExtension/
├── manifest.json    # Extension manifest defining permissions and properties
├── dr-style.css     # CSS styles for the DR environment banner
└── dr-script.js     # JavaScript backup for adding the banner
```

## Extension Notes

- The extension is loaded via Chrome's command-line parameters (`--load-extension`). **See important notes under "Deploying via SCCM" regarding the limitations of this method for enterprise use.**
- Because it's loaded this way (as an unpacked extension) and not installed from the Chrome Web Store, it may not appear in `chrome://extensions/` but will still function *in the specific browser instance launched with the parameter*.
- The extension uses both CSS and JavaScript injection methods to ensure the banner appears.
- **For Enterprise Deployment**: The suggestion below regarding force-installing via policy refers to deploying a **Chrome Web Store** version of the extension. Policies pointing to local paths or CRX files are generally not supported or reliable for enterprise deployment on Windows/macOS.
  - Force-install the extension (requires publishing to Chrome Web Store first)
  - Pin the shortcuts to taskbar or start menu

## Troubleshooting

If the banner doesn't appear:
1. Check if Chrome launched correctly with the extension loaded
2. Try manually visiting the DR URL: https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr
3. Run the ChromeExtensionTest.ps1 script to refresh the extension files
4. Verify the extension files exist in the correct location and have proper permissions

## Extension Permissions

The extension requires minimal permissions:
- "activeTab" - For accessing the current tab
- Host permissions for Genesys Cloud domains only

## Security Considerations

- The extension only runs on Genesys Cloud domains
- No data is collected or transmitted
- The extension is purely visual with no functional impact
- Chrome is configured to use a separate user data directory to prevent cross-contamination

# Genesys DR Environment Chrome Extension Installation

This repository contains scripts for deploying and installing the Genesys DR Environment indicator Chrome extension.

## What This Extension Does

The Genesys DR Environment extension adds a prominent red banner to DR (Disaster Recovery) environments, making it immediately clear to users when they are working in a DR environment rather than production.

## Installation Methods Attempted

We tried several approaches to permanently install this extension across all Chrome profiles:

### 1. Chrome Enterprise Policy-Based Installation (Did NOT Work)

Multiple policy-based approaches using local paths or attempting to install local CRX files were attempted but were **unsuccessful**. This confirms the general guidance that enterprise policies (`ExtensionInstallForcelist`, `ExtensionSettings` with `force_installed`, etc.) on Windows and macOS **require extensions to be hosted on the Chrome Web Store**. Policies pointing to local paths or CRX files are not reliably supported for forced installation.

- **ExtensionSettings Policy**: Setting installation_mode to "force_installed" and specifying local paths failed.
- **ExtensionInstallForcelist Policy**: Using local paths or CRX files (with or without update URLs) failed.
- **ExternalExtensionPaths Policy**: Pointing directly to the local extension folder failed.
- **AllowedLocalExtensionPaths Policy**: Allowing loading from specific paths does not force install.

Despite ensuring all policies were properly set in the registry, Chrome did not load the extension using these methods for forced installation.

### 2. Manual "Load Unpacked" Extension (Worked, but Not Persistent / Suitable for Testing Only)

Using Chrome's developer mode to "Load unpacked" extension worked for **local testing and development**. However, this method is **not suitable for deployment** because it:
- Requires developer mode to be enabled
- Must be done for each Chrome profile individually
- Does not persist if Chrome is reset or profiles are cleared

### 3. Command-Line Approach (--load-extension - Successful for Specific Use Cases, with Limitations)

The approach using Chrome's command-line parameter (`--load-extension`) works technically but has significant limitations for broad use:

```
chrome.exe --load-extension="C:\path\to\extension"
```

This approach:
- Loads the unpacked extension from a local path *each time Chrome is launched with this specific command*.
- Doesn't require changing Chrome policies directly, BUT **it will fail if policies block all extensions (`ExtensionInstallBlocklist` = `*`)**.
- **The extension is only active in the Chrome instance launched with this parameter.** It does not persist across normal Chrome launches.

## Recommended Solution (for Shortcut-Based Loading)

The `LaunchChromeWithExtension.ps1` script implements the command-line approach, creating a shortcut that launches Chrome with the necessary parameter. **This is suitable for scenarios where a specific shortcut is the *only* way users access the DR environment and enterprise policies allow it.**

1. It locates the Chrome executable
2. Closes any running Chrome instances
3. Launches Chrome with the `--load-extension` parameter pointing to the extension folder
4. Optionally creates a startup shortcut to automate this on login

## Limitations (of --load-extension Approach)

The command-line approach has critical limitations:

1. The extension is **only active** for the Chrome session launched with the parameter via the specific shortcut.
2. If a user closes Chrome and opens it normally (e.g., from the taskbar icon, Start Menu, or clicking a link in another app), the extension **will not be loaded**.
3. Creating a startup shortcut helps only for the initial login; subsequent Chrome launches initiated differently won't include the extension.
4. This method **may be blocked entirely** by enterprise policies (`ExtensionInstallBlocklist` = `*`).

## Setup Instructions (for --load-extension Approach)

1. Ensure the extension files are placed in the path defined in the script (`C:\temp\GenesysPOC\ChromeExtension` by default)
2. Run `LaunchChromeWithExtension.ps1` as the user
3. When prompted, choose whether to create a startup shortcut for automatic loading on login
4. Verify the extension is loaded by checking Chrome's extensions page

## Future Improvements / Enterprise Standard

For a **robust, persistent, and centrally managed enterprise solution**, the standard approach is:
1. Package the extension and publish it to the **Chrome Web Store** (visibility can be set to "Unlisted").
2. Use Chrome enterprise policies (**`ExtensionInstallForcelist`**) to deploy the extension using its **Web Store ID**. This ensures the extension is installed and active across all Chrome profiles and instances on the managed device, respecting enterprise policies.
3. Avoid reliance on local file paths or `--load-extension` for deployment. Using a Chrome Native Messaging Host is complex and generally unnecessary if using the Web Store.

## Troubleshooting (--load-extension issues)

If the extension doesn't load:
1. Verify the extension path exists and contains a valid manifest.json file
2. Check that the Chrome path is correctly detected in the script
3. Look for errors in Chrome's console or extensions page
4. Try manually enabling Developer Mode and using "Load unpacked" to test the extension 