# Genesys Cloud Organization ID Detector

## Overview
A minimal Chrome extension that detects the presence of a specific Genesys Cloud Organization ID (`d9ee1fd7-868c-4ea0-af89-5b9813db863d`) on web pages within the Genesys Cloud environment.

## Key Findings

- **Confirmed Detection**: The extension successfully detects the target Organization ID (`d9ee1fd7-868c-4ea0-af89-5b9813db863d`) within the Genesys Cloud environment.

- **Detection Location**: The Organization ID was consistently found in browser storage (localStorage/sessionStorage) when accessing various Genesys Cloud API endpoints.

- **Verified API Endpoints**: The following API endpoints were confirmed to have access to the target Organization ID:
  - `/api/v2/organizations/me`
  - `/api/v2/users/me` (with various expand parameters)
  - `/api/v2/tokens/me`

- **Detection Method**: The extension uses content script injection to search for the exact Organization ID string in multiple possible locations:
  - Browser storage (localStorage/sessionStorage)
  - DOM elements
  - JavaScript global objects
  - HTML content

## Technical Implementation

The extension monitors web requests to Genesys Cloud domains and injects a content script to verify the presence of the target Organization ID. When detected, it logs the URL and detection location to the background script console.

### Components:
- **manifest.json**: Contains extension configuration and permissions
- **background.js**: Implements the detection logic and content script injection

### Detection Strategy:
1. Monitor network requests to specific Genesys Cloud API endpoints
2. Inject a content script to verify the Organization ID exists in the page context
3. Search multiple potential locations for the ID (storage, DOM, JavaScript objects)
4. Log detailed information when the ID is detected

## Installation

1. Clone this repository
2. Open Chrome and navigate to `chrome://extensions/`
3. Enable "Developer mode"
4. Click "Load unpacked" and select the extension directory
5. Visit a Genesys Cloud page and check the background console for detection logs

## Permissions

- `webRequest`: Required to monitor network requests to Genesys Cloud APIs
- `scripting`: Required to inject detection scripts
- `webNavigation`: Required to monitor page navigation events

## Host Permissions

- `*://*.pure.cloud/*`
- `*://*.mypurecloud.com/*`
- `*://*.genesys.cloud/*` 