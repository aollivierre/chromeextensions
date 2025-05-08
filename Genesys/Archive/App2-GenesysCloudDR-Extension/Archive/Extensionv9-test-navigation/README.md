# Genesys Cloud Environment Badge

A Chrome extension that displays a badge indicating which Genesys Cloud environment (DR, TEST, DEV) you're currently browsing. The badge updates immediately when switching between tabs without requiring a page refresh.

## Features

- Displays a colored badge in the top center of the page: "DR" (red), "TEST" (amber), or "DEV" (blue)
- Updates immediately when switching between tabs
- No page refresh required
- Lightweight and focused on a single task

## Installation

1. Download or clone this repository
2. Open Chrome and navigate to `chrome://extensions/`
3. Enable "Developer mode" (toggle in the top-right corner)
4. Click "Load unpacked" and select the folder containing these files
5. The extension is now installed and active

## Testing

1. Open multiple tabs with different Genesys Cloud environments:
   - DR environments (URLs containing: .dr., -dr., -dr-, /dr/, or wawanesa-dr)
   - TEST environments (URLs containing: .test., -test-, or wawanesa-test)
   - DEV environments (URLs containing: .dev., -dev-, or wawanesa-dev)
2. Switch between tabs - the badge should update immediately to show the current environment
3. No page refresh should be needed to see the correct environment badge

## Files

- `manifest.json`: Extension configuration
- `background.js`: Handles tab events and environment detection
- `content.js`: Creates and updates the badge on the page
- `styles.css`: Styles for the environment badge