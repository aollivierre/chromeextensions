# Chrome Web Store Submission Guide for Genesys DR Extension

## Visibility Options

Good news! You can publish your extension as **unlisted**, which is perfect for internal company use:

- **Unlisted**: Extension won't appear in search results or categories, but will have a public URL you can share with your team
- **Public**: Visible to everyone in the Chrome Web Store (not recommended for your use case)

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

If your extension gets rejected for any reason:

1. Read the feedback carefully
2. Make required changes
3. Resubmit

If you continue having issues with the Web Store, you can:
1. Use the enterprise self-hosting option: https://developer.chrome.com/docs/extensions/mv3/external_extensions/
2. Continue using the local extension loading method with your script

## Helpful Links

- Chrome Developer Dashboard: https://chrome.google.com/webstore/devconsole/
- Publishing Requirements: https://developer.chrome.com/docs/webstore/publish/
- Privacy Policy Guidelines: https://developer.chrome.com/docs/webstore/user_data/
- Enterprise Distribution: https://developer.chrome.com/docs/extensions/mv3/external_extensions/ 