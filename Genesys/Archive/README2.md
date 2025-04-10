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

To deploy this solution via Microsoft System Center Configuration Manager (SCCM):

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

- The extension is loaded via Chrome's command-line parameters (`--load-extension`)
- Because it's loaded this way and not installed from the Chrome Web Store, it may not appear in chrome://extensions/ but will still function
- The extension uses both CSS and JavaScript injection methods to ensure the banner appears
- If deploying to many machines, consider using Chrome's enterprise policies to:
  - Force-install the extension
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

Multiple policy-based approaches were attempted but were unsuccessful:

- **ExtensionSettings Policy**: Setting installation_mode to "force_installed" and specifying paths
- **ExtensionInstallForcelist Policy**: Using both with and without update URLs
- **ExternalExtensionPaths Policy**: Pointing directly to the extension folder
- **AllowedLocalExtensionPaths Policy**: Allowing loading from specific paths

Despite ensuring all policies were properly set in the registry, Chrome did not load the extension using these methods.

### 2. Manual "Load Unpacked" Extension (Worked, but Not Persistent)

Using Chrome's developer mode to "Load unpacked" extension worked, but this method:
- Requires developer mode to be enabled
- Must be done for each Chrome profile individually
- Does not persist if Chrome is reset or profiles are cleared

### 3. Command-Line Approach (SUCCESSFUL METHOD)

The successful approach uses Chrome's command-line parameter:

```
chrome.exe --load-extension="C:\path\to\extension"
```

This approach:
- Works consistently
- Doesn't require changing Chrome policies or registry
- Loads the extension each time Chrome is started with this parameter

## Recommended Solution

The `LaunchChromeWithExtension.ps1` script implements the successful command-line approach:

1. It locates the Chrome executable
2. Closes any running Chrome instances
3. Launches Chrome with the `--load-extension` parameter pointing to the extension folder
4. Optionally creates a startup shortcut to automate this on login

## Limitations

The command-line approach has some limitations:

1. The extension is only active for the Chrome session launched with the parameter
2. If a user closes Chrome and opens it normally (without the parameter), the extension won't be loaded
3. Creating a startup shortcut only helps for the initial login; subsequent Chrome launches won't include the extension

## Setup Instructions

1. Ensure the extension files are placed in the path defined in the script (`C:\temp\GenesysPOC\ChromeExtension` by default)
2. Run `LaunchChromeWithExtension.ps1` as the user
3. When prompted, choose whether to create a startup shortcut for automatic loading on login
4. Verify the extension is loaded by checking Chrome's extensions page

## Future Improvements

For a more permanent solution, consider:
1. Creating a proper .crx package with a signed extension
2. Using a Chrome Native Messaging Host to manage the extension installation
3. Working with Chrome Enterprise management tools for larger deployments

## Troubleshooting

If the extension doesn't load:
1. Verify the extension path exists and contains a valid manifest.json file
2. Check that the Chrome path is correctly detected in the script
3. Look for errors in Chrome's console or extensions page
4. Try manually enabling Developer Mode and using "Load unpacked" to test the extension 