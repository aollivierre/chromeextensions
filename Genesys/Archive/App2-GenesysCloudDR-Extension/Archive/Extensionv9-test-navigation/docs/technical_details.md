# Genesys Cloud Environment Badge - Technical Details

This document provides in-depth technical details about how the environment badge extension works, focusing on the key mechanisms that enable real-time badge updates when switching between tabs.

## Architecture

The extension follows a standard Chrome extension architecture with three main components:

```
Background Script ⟷ Messaging API ⟷ Content Script
```

## Background Script (background.js)

### Environment Detection

The environment detection is handled by a pattern-matching function that checks for specific identifiers in URLs:

```javascript
function detectEnvironment(url) {
  if (!url) return null;
  
  const lowerUrl = url.toLowerCase();
  
  // DR environment patterns
  if (lowerUrl.includes('.dr.') || 
      lowerUrl.includes('-dr.') || 
      lowerUrl.includes('-dr-') || 
      lowerUrl.includes('/dr/') || 
      lowerUrl.includes('wawanesa-dr')) {
    return 'DR';
  }
  
  // TEST environment patterns
  if (lowerUrl.includes('.test.') || 
      lowerUrl.includes('-test-') || 
      lowerUrl.includes('cac1.pure.cloud') ||
      lowerUrl.includes('usw2.pure.cloud')) {
    return 'TEST';
  }
  
  // DEV environment patterns
  if (lowerUrl.includes('.dev.') || 
      lowerUrl.includes('-dev-') || 
      lowerUrl.includes('inindca.com')) {
    return 'DEV';
  }
  
  // Default for unrecognized Genesys domains
  if (lowerUrl.includes('pure.cloud') || 
      lowerUrl.includes('mypurecloud.com')) {
    return 'TEST';
  }
  
  return null;
}
```

### Tab Event Listeners

Two critical event listeners handle tab changes:

1. **Tab Activation** - Detects when the user switches between tabs:

```javascript
chrome.tabs.onActivated.addListener(activeInfo => {
  chrome.tabs.get(activeInfo.tabId, tab => {
    processTab(tab.id, tab.url);
  }).catch(error => {
    console.error("Error getting tab information:", error);
  });
});
```

2. **Tab Updates** - Detects when a tab's URL changes:

```javascript
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    processTab(tabId, tab.url);
  }
});
```

### Message Passing

When an environment is detected, the background script sends a message to the content script:

```javascript
function sendEnvironmentToTab(tabId, environment) {
  chrome.tabs.sendMessage(tabId, {
    action: 'updateBadge',
    environment: environment
  });
}
```

## Content Script (content.js)

### Badge Creation

The badge is a simple div element added to the page:

```javascript
function createBadgeElement() {
  if (document.getElementById('genesys-env-badge')) {
    return document.getElementById('genesys-env-badge');
  }
  
  if (!document.body) {
    return null;
  }
  
  const badge = document.createElement('div');
  badge.id = 'genesys-env-badge';
  badge.className = 'genesys-env-badge';
  
  document.body.appendChild(badge);
  return badge;
}
```

### Message Handling

The content script listens for messages from the background script:

```javascript
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'updateBadge' && message.environment) {
    updateBadge(message.environment);
  }
});
```

### Document Ready Handling

To ensure the badge appears as early as possible:

```javascript
function onDocumentReady(callback) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', callback);
  } else {
    callback();
  }
}

onDocumentReady(() => {
  initBadge();
  // ... additional initialization
});
```

### Badge Persistence

Multiple strategies ensure the badge remains visible:

1. **Interval Checking** - Periodically verifies badge presence:

```javascript
setInterval(() => {
  if (!document.getElementById('genesys-env-badge') || 
      document.getElementById('genesys-env-badge').style.display === 'none') {
    initBadge();
  }
}, 2000);
```

2. **DOM Mutation Observer** - Watches for DOM changes that might affect the badge:

```javascript
const observer = new MutationObserver(mutations => {
  if (!document.getElementById('genesys-env-badge')) {
    initBadge();
  }
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});
```

## CSS Styling (styles.css)

The badge styling uses fixed positioning to ensure it's always visible:

```css
.genesys-env-badge {
  position: fixed;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: bold;
  color: white;
  pointer-events: none; /* Don't interfere with clicks */
}

/* Environment-specific colors */
.genesys-env-dr { background-color: #ff3b30; }    /* Red */
.genesys-env-test { background-color: #ff9500; }  /* Amber */
.genesys-env-dev { background-color: #007aff; }   /* Blue */
```

## Manifest Configuration (manifest.json)

The manifest includes several critical configurations:

1. **Permissions** - Enables tab access:
   ```json
   "permissions": ["tabs", "activeTab"]
   ```

2. **Host Permissions** - Specifies which domains the extension works on:
   ```json
   "host_permissions": [
     "*://*.genesyscloud.com/*",
     "*://*.mypurecloud.com/*",
     "*://*.pure.cloud/*",
     // ... additional domains
   ]
   ```

3. **Content Script Configuration** - Sets early execution for immediate badge visibility:
   ```json
   "content_scripts": [{
     "matches": ["*://*.genesyscloud.com/*", /* other domains */],
     "js": ["content.js"],
     "css": ["styles.css"],
     "run_at": "document_start",
     "all_frames": true
   }]
   ```

## Key Optimizations

1. **Error Handling** - All API calls include error handling to prevent extension crashes
2. **Document State Awareness** - Adapts to different document loading states
3. **Multiple Badge Verification Methods** - Uses several techniques to ensure badge visibility
4. **Performance Considerations** - Minimal processing in the critical path