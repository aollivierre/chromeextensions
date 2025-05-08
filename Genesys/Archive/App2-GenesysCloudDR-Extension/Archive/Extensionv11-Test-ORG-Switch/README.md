# Genesys Cloud Org ID Detector

A Chrome extension for monitoring and logging organization ID changes in Genesys Cloud. This extension helps diagnose issues with organization switching, specifically why badges or other UI elements aren't updating when switching between organizations in the same Chrome session.

## Features

- Monitors localStorage and sessionStorage for organization ID changes
- Checks page content for organization IDs
- Monitors network requests to organization-related endpoints
- Tracks authentication state changes
- Shows a floating indicator with the current organization ID
- Provides a simple popup UI for viewing detection events
- Logs all organization ID detections with timestamps

## Installation

1. Clone or download this repository
2. Open Chrome and navigate to `chrome://extensions/`
3. Enable "Developer mode" (toggle in the top-right corner)
4. Click "Load unpacked" and select the folder containing the extension files
5. The extension is now installed and will activate on Genesys Cloud domains

## Usage

1. Navigate to any Genesys Cloud domain (*.genesys.cloud, *.mypurecloud.com, *.pure.cloud)
2. The extension will automatically start monitoring for organization ID changes
3. A small floating indicator will appear in the bottom-right corner showing the detected organization ID
4. Click the extension icon in the Chrome toolbar to view recent detection events
5. Use the "Force Detection" button to manually trigger detection

## Detection Methods

The extension uses multiple methods to detect organization IDs:

- **Storage Monitoring**: Checks localStorage and sessionStorage for organization IDs
- **Network Request Monitoring**: Watches requests to organization-related API endpoints
- **DOM Monitoring**: Scans page content for organization ID patterns
- **Authentication Monitoring**: Tracks auth-related endpoints for session changes

## Troubleshooting

If the extension fails to detect organization changes:

1. Click the "Force Detection" button in the popup
2. Check the browser console for any error messages (F12 > Console)
3. Try refreshing the page
4. Make sure the extension has the necessary permissions

## License

MIT 