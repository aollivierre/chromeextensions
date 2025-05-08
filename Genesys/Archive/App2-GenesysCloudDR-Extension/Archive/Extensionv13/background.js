// Background script for Genesys Cloud Environment Badge
const AUTH_TOKEN_KEY = 'gcucc-ui-auth-token';

// Monitor for tab updates
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && 
      (tab.url?.includes('mypurecloud.com') || 
       tab.url?.includes('pure.cloud') || 
       tab.url?.includes('genesys.cloud'))) {
    
    // Execute script to monitor localStorage
    chrome.scripting.executeScript({
      target: {tabId: tabId},
      function: setupStorageMonitor,
      args: [AUTH_TOKEN_KEY]
    });
  }
});

// This function runs in the context of the webpage
function setupStorageMonitor(tokenKey) {
  // Skip if already monitoring
  if (window.__gcBadgeMonitorActive) return;
  window.__gcBadgeMonitorActive = true;
  
  // Listen for storage events
  window.addEventListener('storage', (event) => {
    if (event.key === tokenKey) {
      // Notify our content script to refresh the badge
      window.dispatchEvent(new CustomEvent('gc-refresh-badge'));
    }
  });
  
  // Force initial check
  window.dispatchEvent(new CustomEvent('gc-refresh-badge'));
}

// Listen for messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'refreshBadge') {
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
      if (tabs[0]) {
        chrome.scripting.executeScript({
          target: {tabId: tabs[0].id},
          function: () => {
            window.dispatchEvent(new CustomEvent('gc-refresh-badge'));
          }
        });
      }
    });
    sendResponse({status: 'refresh triggered'});
  }
  return true;
});