# Genesys Cloud Environment Indicator

A Chrome extension that visually indicates the current Genesys Cloud environment (DR, TEST, DEV) by displaying a badge on the page.

## Features

- **Automatic Environment Detection**: Uses organization ID detection and URL patterns to determine the current environment
- **Visual Badge**: Displays a color-coded badge (red for DR, amber for TEST, blue for DEV) at the top of the page
- **Manual Override**: Allows users to manually set the environment when automatic detection fails
- **Persistent Settings**: Remembers settings between sessions
- **Multi-Environment Support**: Detects and differentiates between DR, TEST, and DEV environments

## Installation

1. Download the extension package
2. In Chrome, go to `chrome://extensions/`
3. Enable "Developer mode" (toggle in top-right)
4. Click "Load unpacked" and select the extension directory
5. The extension should now be installed and active

## Usage

### Automatic Detection

The extension will automatically detect the Genesys Cloud environment based on:

1. Organization ID detection (highest reliability)
2. Hostname and URL pattern matching (medium reliability)

A badge will appear at the top of the page indicating the detected environment.

### Manual Override

If automatic detection fails:

1. Click the extension icon in Chrome toolbar
2. Click one of the environment buttons (DR, TEST, DEV)
3. The badge will update to reflect your selection

### Refresh Detection

To force a refresh of environment detection:

1. Click the extension icon in Chrome toolbar
2. Click "Refresh Detection"

### Clear Data

To reset all detection data:

1. Click the extension icon in Chrome toolbar
2. Click "Clear Data"

## Environment Colors

- **DR**: Red badge with "DR" text
- **TEST**: Amber badge with "TEST" text
- **DEV**: Blue badge with "DEV" text
- **Unknown**: Gray badge with "Unknown" text (fallback)

## Troubleshooting

- **Badge not appearing**: Reload the page or check extension permissions
- **Incorrect environment**: Use manual override or check the console logs for detection details
- **Extension not working**: Make sure you're on a Genesys Cloud domain and the extension is enabled

## Development

See the documentation in the `docs` directory for:

- Enhancement plan (`enhancement-plan.md`)
- Organization ID detection details (`org-id-detection.md`)

## License

Copyright © 2023. All rights reserved. 