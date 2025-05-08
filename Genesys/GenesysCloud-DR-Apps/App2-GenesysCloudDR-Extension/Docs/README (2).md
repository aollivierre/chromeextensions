# Genesys Cloud DR Chrome Extension - Development & Deployment Guide

**CRITICAL NOTE ON DEPLOYMENT METHODS:**

*   **Enterprise Deployment (SCCM, Intune, etc. on Windows/macOS):** The **ONLY** supported and reliable method is to publish the extension (e.g., as 'Unlisted') to the **Chrome Web Store** and deploy it using enterprise policies (`ExtensionInstallForcelist`) referencing the extension's **Web Store ID**. Deploying via policies pointing to local `.crx` files or file paths **DOES NOT WORK** reliably or is unsupported on Windows/macOS.
*   **Local Development/Testing ONLY:** Use `chrome://extensions` -> "Load unpacked" or use the `--load-extension="C:\path\to\unpacked\source"` command-line parameter when launching Chrome. The `--load-extension` method only works for the specific Chrome instance launched with it and may be blocked by enterprise policies (`ExtensionInstallBlocklist` = `*`).
*   **Local `.crx` Files:** There is no valid use case for *installing* local `.crx` files on Windows/macOS, either manually or via policy, for development or deployment. Packaging is only done to create the ZIP file for uploading to the Web Store.

This package contains scripts primarily intended to assist with **local development setup** or reflect **obsolete/non-functional** approaches.

## Available Scripts

### 1. Enable-LocalExtensions.ps1 (Development/Testing Environment Setup ONLY)

*   **Purpose:** Assists developers in configuring their **local machine** to allow loading of **unpacked** extensions using `--load-extension` or the "Load unpacked" button, potentially bypassing local policy blocks *for testing only*. **DO NOT use for enterprise deployment.**
*   **What it does (on local machine):** Attempts to remove blocking policies (like wildcard blocklist), set developer mode policies, create local directories, potentially create test shortcuts using `--load-extension`.
*   **When to use:** Strictly for **local development and testing** of unpacked extension source code.
*   **Usage:** `.\Enable-LocalExtensions.ps1 -ExtensionPath "C:\path\to\extension\source"`

### 2. Install-CRX-NoBlocking.ps1 (Obsolete / Non-Functional for Enterprise Deployment)

*   **Purpose:** **(Obsolete Concept)** This script attempted to install a packaged `.crx` extension file using Chrome policies pointing to local paths.
*   **Status:** This method is **NOT supported or reliable** for enterprise deployment on Windows/macOS. Chrome policies (`ExtensionInstallForcelist`, `ExtensionInstallAllowlist`) require a **Web Store ID**, not a local path.
*   **Recommendation:** **DO NOT USE** this script for deployment. Use the Chrome Web Store method.

### 3. Clean-ChromePolicies.ps1 (Obsolete / Use with Caution)

*   **Purpose:** **(Obsolete Context / Caution Advised)** This script attempted to clean up local Chrome policy registry entries, potentially related to failed local CRX installation attempts.
*   **Status:** Modifying policies directly can have unintended consequences. Use `chrome://policy` to review effective policies. If needed, manage enterprise policies via standard tools (GPO, Intune, SCCM Configuration Items), not local scripts for deployment.
*   **Recommendation:** Generally **avoid** unless troubleshooting specific local policy corruption under guidance.

## Preference Order / Recommended Approach

1.  **Enterprise Deployment:**
    *   Package extension source into a **ZIP** file.
    *   Upload ZIP to **Chrome Web Store** (publish as 'Unlisted' or 'Public').
    *   Obtain the **Extension ID** from the Web Store.
    *   Deploy using **`ExtensionInstallForcelist`** policy (via GPO, SCCM, Intune) with the Web Store ID and update URL (`https://clients2.google.com/service/update2/crx`).
2.  **Local Development/Testing:**
    *   Use `chrome://extensions` -> "Load unpacked" pointing to your source code directory.
    *   Alternatively, create a temporary shortcut using `--load-extension="C:\path\to\source"` (useful for testing app mode, but remember its limitations). The `Enable-LocalExtensions.ps1` script might assist in setting up the local environment for this.

## Files

*   `Enable-LocalExtensions.ps1`: PowerShell script for **local development environment setup ONLY**.
*   `Install-CRX-NoBlocking.ps1`: **Obsolete** script - DO NOT USE for deployment.
*   `Clean-ChromePolicies.ps1`: **Obsolete** / Use with caution.
*   `Detect-GenesysCloudDRExtension.ps1`, `Uninstall-GenesysCloudDRExtension.ps1`: These likely relate to the obsolete local CRX/file copy method and are **not relevant** for the standard Web Store deployment.
*   `GenesysCloudDR.crx`: **Obsolete artifact** for deployment. Packaging is done into a ZIP for Web Store upload.
*   `Extension/`: Directory containing the Chrome extension **source files** (`manifest.json`, `.css`, `.js`). This is what you ZIP for the Web Store or load unpacked locally.

## SCCM Configuration (Recommended: Policy-Based)

Deployment via SCCM should **not** involve running the scripts in this package (except perhaps for complex initial environment setup not related to the extension itself). Instead, configure SCCM to apply the necessary Chrome Policies via the registry:

1.  **Create Configuration Item/Baseline:**
    *   Target the registry key: `HKLM\Software\Policies\Google\Chrome\ExtensionInstallForcelist`
    *   Add a registry value:
        *   Name: The **Web Store Extension ID**
        *   Type: `REG_SZ`
        *   Value: `https://clients2.google.com/service/update2/crx`
    *   Ensure compliance remediation is enabled.
2.  **Deploy Baseline:** Deploy to the target collection.

*(Optionally configure `ExtensionInstallAllowlist` or `ExtensionInstallBlocklist` as needed, ensuring the DR extension ID is allowed if a blocklist is used).*

## How It Works (Correct Method: Web Store Deployment)

1.  Chrome browser on the client machine periodically checks configured `ExtensionInstallForcelist` policies.
2.  It contacts the update URL (`clients2.google.com/service/update2/crx`) specified in the policy value, requesting the extension with the given Web Store ID.
3.  The Chrome Web Store provides the latest version of the extension.
4.  Chrome downloads and installs/updates the extension automatically.
5.  The extension is active across all user profiles and browser instances, managed centrally.
6.  No local files (CRX or source) need to be deployed to client machines for this process.

## Important: Extension ID Stability (for Web Store Updates)

The extension ID is assigned by the Chrome Web Store upon initial upload. It remains stable as long as you upload updates to the *same* extension item in the developer dashboard.

*   The `.pem` key generated when you first packaged your extension (or the first time you uploaded) is **critical for signing subsequent updates** you upload to the Web Store. Losing this key means you cannot update your existing extension and would have to publish a new one with a new ID, requiring policy updates.
*   **Store the original `.pem` key securely.**

## Packaging the Extension (for Web Store Upload ONLY)

You need to package your extension source files (`manifest.json`, `.css`, icons, etc.) into a **ZIP file** to upload it to the Chrome Web Store developer console.

*   **Manual Method:** Select all files and subdirectories within your `Extension/` source folder and create a standard ZIP archive.
*   **Programmatic Method:** Use build tools or scripts (`7z`, `zip`, etc.) to create the ZIP archive from your source directory as part of your build process.

**Note:** While Chrome *can* pack extensions into `.crx` files locally (`chrome://extensions` -> Pack Extension, or command-line), this `.crx` file is **NOT used for uploading to the Web Store** (which takes a ZIP) and **NOT suitable for policy-based deployment** on Windows/macOS. 