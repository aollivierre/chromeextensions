# Chrome Extension Manager - Documentation

**IMPORTANT NOTE: Development/Testing Use Only**

> This script (`Enable-LocalExtensions.ps1`) and the techniques it employs (modifying local Chrome policies to allow unpacked extensions, using `--load-extension`, enabling developer mode) are intended **strictly for local development and testing purposes**. These methods are **NOT suitable or supported for enterprise-wide deployment** of extensions using management tools like SCCM or Intune.
>
> **Enterprise deployment requires publishing extensions to the Chrome Web Store** (even as 'Unlisted') and deploying them via policies (`ExtensionInstallAllowlist`, `ExtensionInstallForcelist`) that reference the Web Store ID. Policies pointing to local paths or relying on developer mode settings are unreliable and unsupported for managed environments.

## Overview

The Chrome Extension Manager script (`Enable-LocalExtensions.ps1`) is a PowerShell utility primarily designed to **assist developers in setting up their local environment** for testing unpacked Chrome extensions. It helps administrators or developers to temporarily adjust local Chrome policies that might otherwise block the loading of unpacked extensions during development.

It can help IT administrators or developers:

- Configure Chrome policies for extension management
- View and manage the extension allowlist and forcelist
- Add new extensions to the allowlist or forcelist
- Create necessary registry keys and directories
- Remove wildcard blocks that prevent extension installation
- Configure local extension loading **(for testing/development)**

## Key Features

- **Registry Management**: Creates and configures necessary registry keys for Chrome extension policies
- **Blocklist Management**: Removes wildcard blockers that prevent extension installation
- **Extension Allowlist**: Add and view extensions that are allowed to be installed
- **Extension Forcelist**: Add and view extensions that are force-installed for all users
- **Policy Verification**: Verifies that all required policies are correctly set
- **Extension Name Resolution**: Efficiently fetches extension names from the Chrome Web Store
- **Caching**: Stores extension names locally for fast retrieval in subsequent runs
- **Set allowed local extension paths**: Sets `AllowedLocalExtensionPaths` **(primarily for development)**.
- **Disable external extension blocking**: Sets `BlockExternalExtensions` to 0 **(use with caution, generally not recommended for production environments)**.

## Usage

### Running the Script

```powershell
.\Enable-LocalExtensions.ps1 [-ExtensionPath "C:\Path\To\Extensions"]
```

### Menu Options

The script presents a comprehensive menu with various options:

#### Registry Blocklist Operations
- **Remove wildcard from extension blocklist**: Removes the wildcard (*) that blocks all extensions
- **Verify blocklist doesn't contain wildcard**: Checks if the blocklist contains a wildcard entry

#### Individual Chrome Policies
- **Enable Chrome extension developer mode**: Sets ExtensionDeveloperModeAllowed to 1
- **Set allowed local extension paths**: Sets AllowedLocalExtensionPaths
- **Disable external extension blocking**: Sets BlockExternalExtensions to 0
- **Verify all Chrome policies**: Checks if all policies are set correctly

#### Chrome Web Store Extensions (Policy Management)

**Note:** While this script provides functions to manage Allowlist/Forcelist registry keys, remember that for these policies to work correctly in an enterprise context, they **must** reference extensions published on the Chrome Web Store using their Web Store IDs. Adding local paths or non-Web Store IDs here will not result in reliable enterprise deployment.

- **Add extension to allowlist**: Users can install these extensions if they want (Requires Web Store ID for enterprise use).
- **View and manage allowlist extensions**: Shows and manages extensions in the allowlist
- **Add extension to forcelist**: Auto-installs for all users (Requires Web Store ID and update URL for enterprise use).
- **View and manage forcelist extensions**: Shows and manages force-installed extensions

#### Other Operations
- **Create extension directory**: Creates a directory for local extensions
- **Run ALL steps**: Performs all necessary configuration steps
- **Restore working state**: Emergency option to revert experimental changes

## Extension Name Caching

The script efficiently fetches extension names using three methods:

1. **Registry Cache**: Checks for previously cached extension names
2. **WebClient Fetch**: Uses System.Net.WebClient to efficiently fetch extension names
3. **Parallel Processing**: For bulk operations, uses PowerShell runspaces to fetch multiple extension details simultaneously

Performance improvements:
- WebClient method is ~13-14x faster than Invoke-WebRequest
- Parallel processing dramatically improves performance for bulk operations
- Registry caching provides instant name lookups on subsequent runs

## Registry Structure

The script manages the following registry locations:

- `HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallBlocklist`
- `HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist`
- `HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist`
- `HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings`
- `HKCU:\Software\GenesysDR\ExtensionCache` (for name caching)

## Technical Notes

- **Windows/Mac Requirements**: For **enterprise policy deployment** (Allowlist/Forcelist), extensions **must** be from the Chrome Web Store for Windows and Mac OS. Local loading methods manipulated by this script are for development/testing only.
- **Caching**: Extension names are cached in the registry for performance
- **Enterprise Deployment**: Compatible with SCCM and other enterprise deployment tools
- **Policy Application**: Changes take effect after policy refresh or browser restart 