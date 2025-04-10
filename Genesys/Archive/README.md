# Genesys Environment Differentiation POC

This proof of concept demonstrates methods to create visually distinct desktop shortcuts and browser experiences for different Genesys environments (Production vs. DR), helping users avoid confusion and potential errors.

## Overview

This POC implements three different approaches to create visual differentiation between Genesys environments:

1. **Basic Approach**: Desktop shortcuts with different icons and names
2. **Edge Profiles**: Separate browser profiles for each environment
3. **Edge Workspace**: Using Edge workspace features with different themes
4. **Browser Extension**: A simple extension that adds visual cues to the DR environment

## Implementation

The POC is implemented in a PowerShell script (`GenesysEnvDifferentiation.ps1`) that:
- Creates desktop shortcuts for PROD and DR environments
- Offers a menu to select which differentiation approach to implement
- Provides testing instructions

## Requirements

- Windows 10/11
- Microsoft Edge browser
- PowerShell 5.1 or later
- Administrative rights (for creating shortcuts)

## How to Use

1. Run the PowerShell script:
   ```powershell
   .\GenesysEnvDifferentiation.ps1
   ```

2. Follow the on-screen instructions to select which differentiation approach to implement

3. Test the created shortcuts following the provided instructions

## Approaches Implemented

### Basic Approach
- Different shortcut names and icons
- PROD uses standard Edge
- DR uses Edge with dark theme

### Edge Profiles Approach
- Creates a separate Edge user profile for DR environment
- Allows for different browser settings, extensions, and appearance

### Edge Workspace Approach
- Uses Edge's workspace feature
- Provides a distinctive red theme for the DR environment

### Browser Extension Approach
- Creates a simple browser extension
- Adds a prominent red banner to the DR environment

## Notes

- For a production implementation, you would need to create proper icon files rather than using system DLLs
- The Edge workspace approach requires Edge 88 or later
- The browser extension needs to be loaded manually in developer mode

## File Structure

```
C:\Temp\GenesysPOC\
├── genesys_prod.ico        # Icon for PROD shortcut
├── genesys_dr.ico          # Icon for DR shortcut
├── dr-workspace.json       # Edge workspace configuration
└── Extension\              # Browser extension files
    ├── manifest.json       # Extension manifest
    └── dr-style.css        # CSS styling for visual cues
``` 