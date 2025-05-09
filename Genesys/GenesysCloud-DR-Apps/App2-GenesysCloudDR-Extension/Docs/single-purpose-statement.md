# Single Purpose and Permissions Justification

## Single Purpose Statement

The single purpose of this extension is to provide visual identification of different Genesys Cloud environments (DR, TEST, DEV, PROD) through color-coded badges at the top of the interface, helping users avoid mistakes when working in disaster recovery or test environments.

## Permissions Justification

### Content Script Permissions

This extension uses content scripts that run on Genesys Cloud domains:
- `*://*.mypurecloud.com/*`
- `*://*.pure.cloud/*`

**Justification**: These permissions are necessary because:
1. The extension needs to access the DOM of Genesys Cloud pages to read the organization name
2. The extension needs to insert the visual badge element into these pages
3. Access is limited to only Genesys Cloud domains where the extension's functionality is relevant
- Request network access
- Request background privileges
- Collect any user data beyond what's visible in the page DOM or accessed from a specific local storage key for fallback identification.

### Storage Permission (`storage`)

**Justification**: This permission is required to access a pre-existing authentication token from the browser's local storage. The extension reads this token solely to extract an organization ID as a fallback mechanism when the primary method of identifying the organization from the page's DOM fails. This enhances the reliability of displaying the correct environment badge. All data accessed from local storage is processed locally within the browser and is not transmitted externally. The extension does not write new data to local storage for its own tracking or operational purposes.

### No Additional Permissions

The extension does not request any additional permissions beyond the content script matches. It does not:
- Request storage permissions
- Request network access
- Request background privileges
- Collect any user data beyond what's visible in the page DOM

## How This Addresses Chrome Web Store Policies

### 1. Limited Use of Permissions

The extension follows the principle of least privilege by:
- Only requesting access to domains where its functionality is needed
- Not requesting any unnecessary permissions
- Processing all data locally within the browser

### 2. Transparent Purpose

The extension's single purpose is clearly articulated and directly related to its functionality:
- It provides visual environment indicators
- It helps prevent confusion between production and non-production environments
- It uses permissions that are directly related to this core purpose

### 3. User Data Protection

The extension:
- Does not collect personal information beyond what is needed for environment identification.
- Does not transmit any data outside the browser
- Processes organization names that are visible on the page or an organization ID found within a pre-existing local storage item.
- Does not store new persistent data for its own tracking.

This single purpose statement and permissions justification demonstrate that the extension complies with Chrome Web Store policies by having a clear, focused purpose with appropriate, minimal permissions needed to fulfill that purpose. 