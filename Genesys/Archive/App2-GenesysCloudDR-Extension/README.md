# Genesys Cloud DR Chrome Extension Installation

This package contains scripts for installing the Genesys Cloud DR Chrome extension in corporate environments where standard extension installations may be restricted.

## Available Scripts

### 1. Enable-LocalExtensions.ps1

**Purpose:** Enables loading of unpacked extensions with the `--load-extension` parameter.

**What it does:**
- Removes blocking policies, especially the wildcard (*) blocklist entry
- Sets necessary developer mode policies
- Creates extension directory
- Creates a desktop shortcut that loads Chrome with the extension

**When to use:**
- For development and testing
- When you need to modify the extension code
- When working with unpacked extension (source files)

**Usage:**
```powershell
.\Enable-LocalExtensions.ps1 -ExtensionPath "C:\path\to\extension"
```

### 2. Install-CRX-NoBlocking.ps1

**Purpose:** Installs a packaged .crx extension file via Chrome policies.

**What it does:**
- Removes blocking policies
- Adds extension to the allowlist
- Adds extension to the force-install list
- Disables BlockExternalExtensions policy

**When to use:**
- For wider deployment of the extension via corporate policy
- When using a pre-packaged .crx file

**Usage:**
```powershell
.\Install-CRX-NoBlocking.ps1
```

### 3. Clean-ChromePolicies.ps1

**Purpose:** Cleans up Chrome policies, especially for fixing invalid allowlist entries.

**What it does:**
- Fixes invalid entries in the allowlist
- Removes wildcard blocking from the blocklist (when used with -Force)

**When to use:**
- When you need to repair broken Chrome policies
- When having issues with extension blocking

**Usage:**
```powershell
.\Clean-ChromePolicies.ps1 -Force
```

## Important Notes

1. **Extension ID Stability:** The extension ID (`idjmoolmcplbkjcldambblbojejkdpij`) is derived from the extension's public key. Always use the same .pem key file when packaging to maintain this ID.

2. **Corporate Policies:** These scripts temporarily modify Chrome policies to enable extension loading. Use with permission from your IT department.

3. **Preference Order:**
   - For development: Use `Enable-LocalExtensions.ps1` with unpacked extension
   - For deployment: Use `Install-CRX-NoBlocking.ps1` with packaged .crx file

4. **Policy Updates:** Run `gpupdate /force` and restart Chrome after applying changes.

## Troubleshooting

If extensions are still blocked:

1. Visit `chrome://policy` in Chrome to see all active policies
2. Check if wildcard (*) exists in the blocklist
3. Ensure your extension ID is in both the allowlist and forcelist
4. Verify that `BlockExternalExtensions` is set to 0
5. Make sure the CRX file path in the forcelist is correct

If automatic installation via forcelist fails, you can also try manually dragging the CRX file into Chrome.

## Files

- `Install-GenesysCloudDRExtension.ps1`: PowerShell script that installs the Chrome extension via Chrome policies
- `Detect-GenesysCloudDRExtension.ps1`: PowerShell script that detects if the extension is installed
- `Uninstall-GenesysCloudDRExtension.ps1`: PowerShell script that removes the extension and related policies
- `GenesysCloudDR.crx`: Packaged Chrome extension file (add this after packaging)
- `Extension/`: Directory containing the Chrome extension source files:
  - `manifest.json`: Extension manifest file defining permissions and content scripts
  - `dr-style.css`: CSS styling for visual differentiation
  - `dr-script.js`: JavaScript for adding the visual indicator

## SCCM Configuration

- **Installation Program**: `powershell.exe -ExecutionPolicy Bypass -File Install-GenesysCloudDRExtension.ps1`
- **Uninstallation Program**: `powershell.exe -ExecutionPolicy Bypass -File Uninstall-GenesysCloudDRExtension.ps1`
- **Detection Method**: Use a script with `powershell.exe -ExecutionPolicy Bypass -File Detect-GenesysCloudDRExtension.ps1`
- **Dependencies**: None
- **User Experience**: Install for system
- **Target**: System-targeted application

## Extension Details

The Chrome extension adds a red banner at the top of the Genesys Cloud DR environment with the text "DR ENVIRONMENT" to visually differentiate it from the production environment. The extension automatically activates when users visit Genesys Cloud DR URLs.

## Installation Details

The extension is deployed using these components:

1. **Extension Files**: Copied to `C:\Program Files\GenesysPOC\ChromeExtension\`
2. **CRX Package**: Stored at `C:\Program Files\GenesysPOC\GenesysCloudDR.crx`
3. **Chrome Policies**:
   - Extension added to allowlist
   - Extension added to force-install list
   - Developer mode enabled
4. **Desktop Shortcuts**: Created for both Production and DR environments

## How It Works

This installation approach uses Chrome's policy-based deployment mechanism to install and activate the extension automatically. Once installed:

1. The extension is automatically loaded when Chrome starts
2. No special command-line parameters are needed in shortcuts
3. Users see visual differentiation when visiting DR environment URLs

## Important: Extension ID Stability

The extension ID (`idjmoolmcplbkjcldambblbojejkdpij`) is derived from the private key (.pem file) used when packaging the extension, not from the extension content. 

**Critical considerations:**
- **ALWAYS use the same .pem file** when creating updates to maintain the same extension ID
- Store the .pem file securely but ensure it remains accessible for future updates
- If the .pem file is lost, a new ID will be generated, requiring policy updates across your environment
- The scripts assume this specific extension ID - changing it requires updating all scripts

## Packaging the Extension

### Manual Method

Before deploying via SCCM, you need to package the extension as a CRX file:
1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode"
3. Click "Pack extension" and select the Extension folder
4. If this is your first time packaging, leave the private key field empty
5. If updating an existing extension, browse to the previously generated .pem file
6. Click "Pack Extension" and Chrome will generate the .crx file
7. **Important:** Save both the .crx and .pem files securely
8. Add the .crx file to this package for deployment

### Programmatic Packaging

For automated builds, there are several methods to package extensions programmatically:

1. **Chrome Command Line** (requires Chrome installation):
   ```powershell
   # Using Chrome's command line tool
   & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --pack-extension="C:\path\to\extension" --pack-extension-key="C:\path\to\extension.pem"
   ```

2. **Node.js Tools** (for build servers):
   - Install Node.js and use the [crx](https://www.npmjs.com/package/crx) package:
   ```
   npm install -g crx
   crx pack ./extension -o extension.crx -p extension.pem
   ```

3. **PowerShell Module** (creates unsigned CRX):
   - Several GitHub projects provide PowerShell modules for CRX packaging
   - Use these in build pipelines for automated packaging

Whichever method you choose, always use the same .pem file to maintain extension ID consistency. 