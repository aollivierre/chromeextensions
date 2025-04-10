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
- `DeleteDRShortcut.vbs`: Removes the shortcut
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

### Option 1: Use Self-Contained VBS Scripts (Recommended)
- **Installation Program**: `cscript //nologo CreateDRShortcut.vbs`
- **Uninstallation Program**: `cscript //nologo DeleteDRShortcut.vbs`
- **Detection Method**: Use a script with `cscript //nologo DetectDRShortcut.vbs`

### Option 2: Use CMD Wrappers
- **Installation Program**: `cmd.exe /c Install.cmd`
- **Uninstallation Program**: `cmd.exe /c Uninstall.cmd`
- **Detection Method**: Use a script with `cmd.exe /c Detect.cmd`

- **Dependencies**: Add App2-GenesysCloudDR-Extension as a dependency
- **User Experience**: Install for user
- **Target**: User-targeted application

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