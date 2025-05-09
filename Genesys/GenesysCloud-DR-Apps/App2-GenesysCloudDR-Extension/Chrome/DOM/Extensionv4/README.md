# Genesys Cloud Environment Badge

A minimalist Chrome extension that displays environment badges for Genesys Cloud based on organization ID detection.

## Features

- Automatically detects Genesys Cloud environment based on authentication token
- Displays a color-coded badge at the top of the page:
  - DR environment (Red)
  - TEST environment (Orange)
  - DEV environment (Blue)
  - No badge for PROD environment

## Installation

1. Download or clone this repository
2. Open Chrome and navigate to `chrome://extensions/`
3. Enable "Developer mode" in the top-right corner
4. Click "Load unpacked" and select the directory containing the extension files
5. The extension will automatically activate when you visit any Genesys Cloud domain

## How It Works

- Checks localStorage for the Genesys Cloud authentication token (`gcucc-ui-auth-token`)
- Parses the JWT token to extract the organization ID
- Displays an appropriate badge based on the detected environment
- Polls for changes every 500ms and updates the badge if needed

## Supported Domains

- *.mypurecloud.com
- *.pure.cloud
- *.genesys.cloud 