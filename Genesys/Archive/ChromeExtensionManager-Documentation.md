# Chrome Extension Manager - Documentation

## Overview

The Chrome Extension Manager script (`Enable-LocalExtensions.ps1`) is a PowerShell utility for managing Chrome extensions in enterprise environments. This tool helps IT administrators:

- Configure Chrome policies for extension management
- View and manage the extension allowlist and forcelist
- Add new extensions to the allowlist or forcelist
- Create necessary registry keys and directories
- Remove wildcard blocks that prevent extension installation
- Configure local extension loading

## Key Features

- **Registry Management**: Creates and configures necessary registry keys for Chrome extension policies
- **Blocklist Management**: Removes wildcard blockers that prevent extension installation
- **Extension Allowlist**: Add and view extensions that are allowed to be installed
- **Extension Forcelist**: Add and view extensions that are force-installed for all users
- **Policy Verification**: Verifies that all required policies are correctly set
- **Extension Name Resolution**: Efficiently fetches extension names from the Chrome Web Store
- **Caching**: Stores extension names locally for fast retrieval in subsequent runs

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

#### Chrome Web Store Extensions
- **Add extension to allowlist**: Users can install these extensions if they want
- **View and manage allowlist extensions**: Shows and manages extensions in the allowlist
- **Add extension to forcelist**: Auto-installs for all users
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

- **Windows/Mac Requirements**: Extensions must be from the Chrome Web Store for Windows and Mac OS
- **Caching**: Extension names are cached in the registry for performance
- **Enterprise Deployment**: Compatible with SCCM and other enterprise deployment tools
- **Policy Application**: Changes take effect after policy refresh or browser restart 