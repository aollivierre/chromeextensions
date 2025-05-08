# Chrome Web Store Submission Guide for Genesys DR Extension

**Context:** For enterprise deployment (SCCM, Intune, etc.) on Windows and macOS, publishing your extension to the Chrome Web Store is the **required and only supported method** for reliable deployment via policies like `ExtensionInstallForcelist`. Local CRX files or loading unpacked extensions via command line (`--load-extension`) are not suitable for enterprise deployment. The `--load-extension` can work ONLY if you do not set a wild card * on the Block All Extensions policy so keep `--load-extension` for testing purposes only.

## Visibility Options

Good news! You can publish your extension as **unlisted**, which is perfect for internal company use:

- **Unlisted**: Extension won't appear in search results or categories, but will have a public URL you can share with your team and use in deployment policies. This is the recommended option for internal tools
- **Public**: Visible to everyone in the Chrome Web Store (generally not needed for internal enterprise tools)

## Required Information for Submission

### Basic Details
- **Extension Name**: "Genesys DR Environment Indicator" (already in your manifest)
- **Summary**: A brief one-sentence description (max 132 characters)
  - Example: "Adds prominent visual indicators to Genesys Cloud DR environments for easy identification"
- **Description**: Detailed explanation (max 16,000 characters)
  - Example: "This extension adds visual cues to Genesys DR environments, helping users easily identify when they're working in a disaster recovery instance. Clear visual indicators prevent confusion and potential mistakes when switching between production and DR environments."
- **Primary Category**: Choose "Developer Tools" or "Productivity"
- **Language**: English (default)

### Graphic Assets
- **Extension Icon**: 
  - 128x128 PNG icon (required)
  - Design should be simple and recognizable
  - Suggestion: Use Genesys logo with a "DR" overlay or indicator
- **Screenshots**: At least 1 required, up to 5 allowed
  - 1280x800 or 640x400 pixels
  - Show the extension working in the Genesys environment
  - Include captions explaining what's shown

### Additional Information
- **Website**: Optional - can use your company website
- **YouTube Video**: Optional - skip this
- **Homepage URL**: Optional - your internal documentation URL if available

### Distribution Details
- **Visibility**: Select "Unlisted" when prompted
- **Regions**: "All regions" is fine for unlisted extensions
- **Adult Content**: Select "No"

### Privacy Requirements
- **Privacy Policy**: Required even for unlisted extensions
  - Create a simple document stating:
    - What data your extension collects (appears minimal - only page content for visual modifications)
    - That data isn't transmitted anywhere
    - Contact information (your work email)
  - Host this document on any accessible URL (company intranet page, GitHub, etc.)
  - Enter the URL in the submission form

### Attestations
- **Single Purpose**: Describe the single purpose of your extension
  - Example: "This extension's sole purpose is to provide visual identification of DR environments in Genesys Cloud"
- **Permissions Justification**: Explain why you need the permissions in your manifest
  - `activeTab`: "Required to modify the appearance of Genesys Cloud pages"
  - Host permissions: "Required to identify and modify only Genesys Cloud pages"

## Publishing Process

1. **Prepare Your ZIP File**:
   - Remove the "id" and "key" fields from manifest.json
   - ZIP all extension files (manifest.json, dr-style.css, dr-script.js)
   - Do not include unnecessary files

2. **Submit for Review**:
   - Upload the ZIP file
   - Fill out all the details above
   - Submit for review
   - Review typically takes 1-3 business days

3. **After Approval**:
   - You'll receive the official extension ID
   - Use this ID in your ExtensionInstallAllowlist policy
   - Share the extension URL with your team

## Rejection Contingency Plan

If your extension gets rejected during the Web Store review process:

1.  Read the reviewer's feedback carefully.
2.  Make the required changes to your extension's code or manifest.
3.  Resubmit the updated extension for review.

If you face persistent issues with Web Store approval that cannot be resolved, **true enterprise deployment becomes significantly more challenging**. The alternative methods have major drawbacks:

1.  **Enterprise Self-Hosting:** This involves hosting the `.crx` file and an update manifest XML file on your own internal web server. It's complex to set up, requires careful management of update manifests and signing keys, and may still face policy restrictions. See: [https://developer.chrome.com/docs/extensions/how-to/distribute/self-host-extensions](https://developer.chrome.com/docs/extensions/how-to/distribute/self-host-extensions)
2.  **Local Loading (`--load-extension` via Shortcut):** As detailed elsewhere, this method is **only suitable for limited testing or development, NOT for enterprise deployment**. It requires specific shortcuts, doesn't persist across normal browser use, and can be blocked by common enterprise policies (`ExtensionInstallBlocklist` = `*`). It should not be considered a viable alternative to Web Store deployment for enterprise use.

**Recommendation:** Focus on resolving any Web Store submission issues, as it provides the most robust and manageable deployment path for enterprise environments.

## Helpful Links

- Chrome Developer Dashboard: https://chrome.google.com/webstore/devconsole/
- Publishing Requirements: https://developer.chrome.com/docs/webstore/publish/
- Privacy Policy Guidelines: https://developer.chrome.com/docs/webstore/user_data/
- Enterprise Distribution: https://developer.chrome.com/docs/extensions/mv3/external_extensions/ 