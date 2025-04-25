# Important Note: Shortcut Properties Window Truncation Behavior

When working with the Chrome shortcuts created by the scripts in this application, you may observe an unexpected behavior with the Windows shortcut properties window.

## Observed Behavior

- **In the Properties Window**: When viewing the shortcut's properties and looking at the "Target" field, you will see the command line appears to be truncated. 
  
  Example of truncated display:
  ```
  "C:\Program Files\Google\Chrome\Application\chrome.exe" --no-first-run --app=https://login.mypurecloud.com/#/authenticate-adv/org/wawanesa-dr --force-dark-mode --user-data-dir="C:\Temp\GenesysPOC\ChromeUserData" --load-extension="C:\Program Files\GenesysPOC\C
  ```

- **Actual Execution**: Despite the truncated display, the full command line is actually passed to Chrome when the shortcut is executed. This has been confirmed using Process Explorer, which shows the complete command line.

## Technical Explanation

This is a limitation of the Windows shortcut properties dialog window, which has a character limit for displaying the Target field. This is only a display limitation and does not affect the actual functionality:

1. The full command string is stored correctly in the .lnk file
2. When executed, Windows passes the entire command line to the application
3. Only the visual representation in the properties window is truncated

## Verification Methods

If you need to verify the actual command line being passed:

1. **Process Explorer**: Use Sysinternals Process Explorer to view the full command line of the Chrome process after launching it from the shortcut
2. **Task Manager (Windows 10/11)**: In newer Windows versions, you can see command lines in the Details tab (right-click on column headers and add "Command line")
3. **PowerShell**: Use `Get-Process chrome | Select-Object CommandLine` after launching Chrome from the shortcut

## Conclusion

All the shortcut creation methods in this application work correctly despite the misleading truncated display in the properties window. The scripts ensure that all parameters, including `--no-first-run` and the full extension path, are correctly included when Chrome is launched.

**Note on `--load-extension`:** Remember that using the `--load-extension` parameter only activates the extension for the specific Chrome instance launched by this shortcut. The extension will not be active in other Chrome windows opened normally, and this method may fail entirely if enterprise policies block all extensions (`ExtensionInstallBlocklist` = `*`). For persistent, enterprise-wide deployment, publishing the extension to the Chrome Web Store and deploying via policy is required. 