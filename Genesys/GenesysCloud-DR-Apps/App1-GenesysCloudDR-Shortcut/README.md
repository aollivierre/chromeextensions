# Genesys Cloud DR Shortcut (App1)

This SCCM application creates a desktop shortcut for the Genesys Cloud Disaster Recovery (DR) environment using VBScript.

## Dependencies

- App2-GenesysCloudDR-Extension (required first to install the Chrome extension)
- Google Chrome must be installed on the target system

## Files

### Production Scripts
- `CreateDRShortcut_Enhanced.vbs`: Creates the shortcut with full validation and error handling
- `DetectDRShortcut_Enhanced.vbs`: Detects installation with OneDrive sync protection
- `DeleteDRShortcut.vbs`: Removes the shortcut from the user's desktop
- `GenesysCloud_DR_256.ico`: Custom icon for the shortcut
- `Shortcut-Truncation-Note.md`: Documentation about Windows shortcut properties display limitation

## SCCM Configuration

### Application Settings
- **Installation Program**: `wscript.exe //B "CreateDRShortcut_Enhanced.vbs"`
- **Uninstallation Program**: `wscript.exe //B "DeleteDRShortcut.vbs"`
- **Detection Method**: Script (VBScript) - Paste content of `DetectDRShortcut_Enhanced.vbs`
- **Dependencies**: Add App2-GenesysCloudDR-Extension as a dependency
- **User Experience**: Install for user
- **Target**: User-targeted application

**Key Points:**
- The `//B` flag runs scripts in background mode, completely suppressing all UI elements and popups

## Critical Issue: OneDrive Sync Detection Problem

### The Problem
OneDrive sync can create shortcuts before SCCM deployment completes, leading to false positive detections:

1. **OneDrive syncs shortcuts** from other devices to new laptops
2. **Shortcuts appear WITHOUT icons** (OneDrive doesn't sync the icon files)
3. **Basic detection would return "DETECTED"** even though the application isn't properly installed
4. **SCCM would skip installation** thinking the app is already there

### The Solution
The detection script includes **icon file validation** to prevent false positives:

```vbs
' Check if the icon file exists (critical for OneDrive sync issue)
If FileSystem.FileExists(IconPath & "\" & Icon) Then
    IconMatch = True
End If
```

**Detection Validates:**
1. Shortcut exists
2. Target path matches expected Chrome executable
3. Arguments contain correct URL pattern  
4. **Icon file exists in user's Windows folder** ⭐ **KEY PROTECTION**
5. Shortcut icon location points to our icon
6. Chrome executable actually exists

## SCCM Detection Methods

### How SCCM Reads Detection
✅ **Text Output Based**: 
- **Detected**: Script outputs "DETECTED" 
- **Not Detected**: Script outputs nothing and exits silently
- **How SCCM reads it**: Uses `cscript.exe` internally to capture stdout

❌ **Exit Codes**: Not used for detection in SCCM Applications

## VBScript Execution Modes

### `wscript.exe` (GUI Mode)
- **WScript.Echo behavior**: Shows popup dialogs
- **With //B flag**: Suppresses error dialogs but WScript.Echo still shows popups
- **SCCM compatibility**: ❌ SCCM can't read popup dialogs
- **Use for**: Silent installation (`wscript.exe //B`)

### `cscript.exe` (Console Mode)
- **WScript.Echo behavior**: Writes to console (stdout)
- **SCCM compatibility**: ✅ SCCM can read stdout/stderr
- **Use for**: Detection testing (`cscript.exe "DetectScript.vbs"`)

## Script Features

### CreateDRShortcut_Enhanced.vbs
✅ **Chrome Installation Validation**: Checks both x64 and x86 Chrome paths  
✅ **Icon File Validation**: Verifies source icon exists before proceeding  
✅ **Directory Safety**: Creates required directories with error handling  
✅ **Path Resolution**: Uses script directory instead of current working directory  
✅ **Comprehensive Error Codes**: Specific exit codes for troubleshooting  

**Exit Codes:**
- `0` = Success
- `1` = Chrome not found  
- `2` = Icon file not found
- `3-6` = Directory creation failures
- `7` = Icon copy failure
- `8-9` = Shortcut creation failure  
- `10` = Shortcut verification failure

### DetectDRShortcut_Enhanced.vbs
✅ **OneDrive Sync Protection**: Validates icon file exists to prevent false positives  
✅ **Target Validation**: Verifies Chrome executable actually exists  
✅ **Corruption Protection**: Handles corrupted shortcut files gracefully  
✅ **Icon Location Validation**: Checks shortcut's icon property  
✅ **5-Point Validation**: Comprehensive validation system  

## Local Testing

### Test Installation and Detection
```cmd
# Test silent install
wscript.exe //B "CreateDRShortcut_Enhanced.vbs"

# Test detection (should show "DETECTED")
cscript.exe "DetectDRShortcut_Enhanced.vbs"

# Test silent uninstall  
wscript.exe //B "DeleteDRShortcut.vbs"
```

### Simulate SYSTEM Context
```cmd
# Use PsExec from Sysinternals
psexec -s -i cmd.exe
# Then run the test commands above
```

## Application Display Name in Software Center
To set the application name users see in Software Center:
1. In SCCM console, go to **Application** properties
2. On the **General** tab, set **Name** and **User-Friendly Name** to "Genesys Cloud DR"
3. Set description and other metadata for Software Center
4. Display name is controlled by SCCM application properties, not the scripts

## Working Shortcut Format

The shortcut target format:
```
"C:\Program Files\Google\Chrome\Application\chrome.exe" --app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --no-first-run
```

### Chrome Profile Strategy

**Current Approach (v2.1.0+):** Uses default Chrome profile
- ✅ **Seamless Microsoft Entra SSO**: Leverages existing authentication tokens
- ✅ **Extension Compatibility**: All Chrome extensions work immediately
- ✅ **No Caching Issues**: Extensions stay current, no temp folder cleanup needed
- ✅ **Better User Experience**: One-click access without re-authentication

**Previous Approach (v2.0.0):** Used dedicated Chrome profile
- ❌ **Extension Caching**: Old extension versions would get stuck in temp folder
- ❌ **Additional Authentication**: Users had to re-authenticate for SSO
- ❌ **Maintenance Overhead**: Required cleaning temp folders periodically

### Chrome Arguments Explained

- `--app=URL`: Opens Chrome in app mode (no browser UI, dedicated window)
- `--force-dark-mode`: Forces Chrome UI to use dark theme
- `--no-first-run`: Skips Chrome's initial setup screens and prompts

## Troubleshooting

### Common Issues and Solutions

**Problem**: Script fails with exit code 2  
**Solution**: Icon file not found. Script automatically uses script directory.

**Problem**: False positive detection with OneDrive sync  
**Solution**: Detection script validates icon file existence to prevent this.

**Problem**: Chrome not found during installation  
**Solution**: Script checks both x64 and x86 Chrome paths automatically.

**Problem**: Windows Script Host popups during installation  
**Solution**: Use `wscript.exe //B` for silent execution.

### General Notes
- Scripts handle comprehensive validation and error scenarios
- Shortcut properties window may show truncated Target field (display limitation only)
- For OneDrive sync environments, icon validation prevents false positives
- Always use `wscript.exe //B` for silent SCCM deployment 