# Genesys Cloud DR Shortcut (App1)

This SCCM application creates a desktop shortcut for the Genesys Cloud Disaster Recovery (DR) environment using VBScript.

## Dependencies

- App2-GenesysCloudDR-Extension (required first to install the Chrome extension)
- Google Chrome must be installed on the target system

## Files

### Main VBS Scripts (Recommended)
These scripts are completely self-contained and don't require command-line arguments:

- `CreateDRShortcut.vbs`: Creates the shortcut with hardcoded correct paths
- `DetectDRShortcut.vbs`: Detects if the shortcut is already installed
- `DeleteDRShortcut.vbs`: Removes the shortcut from the user's desktop
- `Shortcut-Truncation-Note.md`: Important documentation about the Windows shortcut properties display limitation

### Alternative Approaches
These files require parameters and may have issues with paths containing spaces:

- `CreateShortcut.vbs`: Creates the shortcut (requires command-line parameters)
- `DeleteShortcut.vbs`: Removes the shortcut (requires command-line parameters)
- `DetectShortcut.vbs`: Detects if the shortcut is already installed (has hardcoded values)
- `Install.cmd`: PowerShell-based installation
- `DirectInstall.cmd`: Direct PowerShell installation with hard-coded paths
- `Install-Alternative.cmd`: Alternative PowerShell installation
- `GenesysCloud_DR_256.ico`: Custom icon for the shortcut

## SCCM Configuration

### Recommended Configuration for 100% Silent Operation
For completely silent installation with no UI or popups:

- **Installation Program**: `wscript.exe //B "CreateDRShortcut.vbs"`
- **Uninstallation Program**: `wscript.exe //B "DeleteDRShortcut.vbs"`
- **Detection Method**: `cscript.exe //nologo "DetectDRShortcut.vbs"`

The `//B` flag runs the script in background mode, completely suppressing all UI elements, popups, and error messages. This ensures a 100% silent user experience.

### Alternative Configurations
These may still potentially show UI elements or brief console windows:

- **Option 1**: `cscript //nologo CreateDRShortcut.vbs` (console-based, may flash briefly)
- **Option 2**: `cmd.exe /c Install.cmd` (uses command wrappers)

- **Dependencies**: Add App2-GenesysCloudDR-Extension as a dependency
- **User Experience**: Install for user
- **Target**: User-targeted application

### Application Display Name in Software Center
To set the correct application name that users see in Software Center:
1. In the SCCM console, go to the **Application** properties
2. On the **General** tab, set the **Name** and **User-Friendly Name** fields to "Genesys Cloud DR"
3. You can also set a description and other metadata that will appear in Software Center
4. The display name is not controlled by the scripts but by these application properties in SCCM

## Preventing Windows Script Host Popups

The VBS scripts have been carefully designed to run silently without showing message boxes to users:

- **Problem:** Using `WScript.Echo` in VBS scripts causes a Windows Script Host popup message that interrupts the user experience
- **Solution 1:** We've removed all `WScript.Echo` statements from the installation and uninstallation scripts
- **Solution 2:** Using `wscript.exe //B` to run scripts in background mode, which suppresses all UI elements including popups
- **Exception:** The detection script still uses `WScript.Echo "DETECTED"` because it's required for SCCM detection, but this doesn't cause a popup in the detection context
- **Implementation:** If you need to add any debugging or status messages, avoid using `WScript.Echo` as it will generate popups
- **Command Line Flags:**
  - `//B` - Runs in background mode with no UI (best for silent installation)
  - `//nologo` - Suppresses script host banner but doesn't prevent popups

## Local Testing Outside SCCM

To test the silent behavior locally outside of SCCM:

1. **Test silent install:** `wscript.exe //B CreateDRShortcut.vbs`
2. **Test silent uninstall:** `wscript.exe //B DeleteDRShortcut.vbs`
3. **Test detection:** `cscript.exe //nologo DetectDRShortcut.vbs`
4. **Simulate SYSTEM context:** Use PsExec from Sysinternals: `psexec -s -i cmd.exe` then run the commands
5. **Verify by checking:** 
   - The shortcut appears/disappears without any visible UI
   - No popup dialogs appear at any point during execution

## Notes

- This application relies on the Chrome extension being installed by App2-GenesysCloudDR-Extension
- The shortcut points to the Chrome executable with parameters to load the extension and open the DR environment
- The custom icon provides visual differentiation between production and DR environments 
- **Important**: The shortcut properties window has a display limitation that truncates long command lines. This is only a display issue and does not affect functionality. See `Shortcut-Truncation-Note.md` for details.

## Working Shortcut Format

The correct shortcut target format is:
```
"C:\Program Files\Google\Chrome\Application\chrome.exe" --app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir="C:\Temp\GenesysPOC\ChromeUserData" --load-extension="C:\Program Files\GenesysPOC\ChromeExtension" --no-first-run
```

## Troubleshooting

- The self-contained VBS scripts (`CreateDRShortcut.vbs`, etc.) are the most reliable way to create the correct shortcut with proper quotes around the paths.
- If you're having issues with quotes in paths, use the self-contained VBS scripts as they have the correct format hardcoded.
- If you encounter issues with one approach, try another as they use different methods of creating the shortcut.
- When checking the shortcut in the properties window, be aware that the Target field may appear truncated due to Windows display limitations. This does not affect functionality.
- If you're seeing Windows Script Host popups during installation, change the installation command to use `wscript.exe //B` instead of `cscript //nologo`. 