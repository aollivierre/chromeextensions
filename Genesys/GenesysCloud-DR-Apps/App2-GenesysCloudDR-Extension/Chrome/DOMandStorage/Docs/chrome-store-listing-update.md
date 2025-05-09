# Chrome Web Store Listing Update Instructions

Follow these steps to update your Chrome Web Store listing to address policy violations:

## Step 1: Host Your Privacy Policy

1. Take the `privacy-policy.md` file created earlier
2. Replace `[YOUR CONTACT EMAIL ADDRESS]` with your actual contact email
3. Host this file online where it's publicly accessible. Options include:
   - GitHub Pages
   - Company website
   - Google Drive (shared publicly)
   - Any web hosting service
4. Copy the URL where the privacy policy is hosted

## Step 2: Update Your Store Listing

Log in to the [Chrome Developer Dashboard](https://chrome.google.com/webstore/devconsole/) and edit your extension listing:

### Description Section

Replace your current description with this template:

```
This extension helps users easily identify Genesys Cloud disaster recovery (DR), test (TEST), and development (DEV) environments by displaying a color-coded visual badge at the top of the interface:

• Red badge for DR environments
• Orange badge for TEST environments
• Blue badge for DEV environments
• No badge for PROD environments

The extension reads the organization name displayed in the Genesys Cloud interface, or alternatively, an organization ID from local browser storage (as a fallback), to determine the environment type. All processing is done locally within your browser, and no data is transmitted externally.

This is an internal tool developed for specific organizations and is not affiliated with, endorsed by, or officially connected to Genesys Cloud.
```

### Privacy Practices Section

1. In the "Privacy Practices" section, add the URL to your hosted privacy policy
2. When asked what data the extension collects, select only:
   - "Website content"
3. State that the extension:
   - Does not transmit data
   - Does not use data for personalization
   - Does not share data with third parties

### Store Visibility

Keep your extension as "Unlisted" if it's intended for internal use only.

### Permissions Justification

In the permissions justification section (appears when you've selected permissions your extension uses), explain:

```
This extension requires access to `*://*.mypurecloud.com/*` and `*://*.pure.cloud/*` to read the organization name from the page content and display a visual environment badge. The 'storage' permission is used to access an organization ID from local browser storage as a fallback identification method if the primary DOM-based method fails. This enhances the reliability of the badge display. All data is processed locally and is not transmitted externally.
```

## Step 3: Single Purpose Justification

When prompted to provide your extension's "single purpose", use this text:

```
This extension's single purpose is to provide visual identification of different Genesys Cloud environments through color-coded badges, helping users avoid mistakes when working in disaster recovery (DR) or test environments.
```

## Step 4: Affiliation Statement

Add this disclaimer to the end of your description:

```
IMPORTANT: This extension is not affiliated with, endorsed by, or officially connected to Genesys Cloud or any of its subsidiaries or affiliates. "Genesys" and "Genesys Cloud" are trademarks of Genesys Telecommunications Laboratories, Inc.
```

## Step 5: Resubmit

1. Review all your changes
2. Click the "Submit for Review" button
3. Wait for the review process (typically 1-3 business days)

## Future Considerations

After getting approved, consider implementing these changes in a future version:

1. Rename the extension to something more generic without "Genesys" in the name
2. Make the organization names configurable instead of hard-coded
3. Add a settings page for customization

Remember that the Chrome Web Store might request additional changes before approval, so be prepared to make further adjustments if needed. 