# Genesys Cloud Environment Badge Extension

## Overview

This Chrome extension creates a simple visual badge that shows which Genesys Cloud environment you're currently browsing (DR, TEST, or DEV). The badge updates instantly when switching between tabs without requiring a page refresh.

## Problem Solved

Before this extension, when switching between tabs with different Genesys environments, the badge would not update until the page was manually refreshed. This extension fixes that by:

1. Detecting tab switching events in real-time
2. Immediately updating the badge without page refresh
3. Supporting all Genesys Cloud domains and environments

## Technical Implementation

The extension uses three key files:

### 1. Background Script (background.js)

This is the "brain" of the extension that:

- Runs persistently in Chrome's background
- Listens for tab switching events via `chrome.tabs.onActivated`
- Analyzes URLs to determine which environment they belong to
- Sends messages to the content script when the environment changes

Key snippet:
```javascript
// Listen for tab activation (user switches tab)
chrome.tabs.onActivated.addListener(activeInfo => {
  chrome.tabs.get(activeInfo.tabId, tab => {
    processTab(tab.id, tab.url);
  }).catch(error => {
    console.error("Error getting tab information:", error);
  });
});
```

### 2. Content Script (content.js)

This script:

- Runs in the context of the webpage
- Creates and maintains the visual badge element
- Receives messages from the background script
- Updates the badge immediately when the environment changes

Key snippet:
```javascript
// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'updateBadge' && message.environment) {
    updateBadge(message.environment);
  }
});
```

### 3. Manifest (manifest.json)

The configuration file that ties everything together:

- Specifies permissions (tabs, activeTab)
- Lists all Genesys Cloud domains
- Connects the background and content scripts
- Sets the content script to run at document_start for immediate execution

## Key Insights for Success

1. **Tab Events vs Page Events**: The extension monitors tab switching at the browser level rather than page-level events, ensuring badge updates even when switching between static tabs.

2. **Early Execution**: The content script is set to run at document_start to ensure the badge appears as early as possible in page load.

3. **Multiple Detection Strategies**: The environment detection uses multiple URL patterns to identify environments across different domain formats.

4. **Robust Error Handling**: The extension includes fallbacks, retries, and error handling to ensure reliability.

## Simple Visual Indicators

- **DR Environment**: Red badge with "DR" text
- **TEST Environment**: Amber badge with "TEST" text
- **DEV Environment**: Blue badge with "DEV" text

## What Makes This Approach Better

1. **Lightweight**: The extension focuses solely on the badge functionality without bloat
2. **Real-time**: Uses Chrome's tab API for immediate updates without page refresh
3. **Non-intrusive**: The badge is positioned to be visible but not disruptive
4. **Comprehensive**: Handles all Genesys Cloud domains and environment formats