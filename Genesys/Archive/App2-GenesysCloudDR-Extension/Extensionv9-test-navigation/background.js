// Function to detect environment from URL
function detectEnvironment(url) {
  if (!url) return null;
  
  // Convert URL to lowercase for case-insensitive matching
  const lowerUrl = url.toLowerCase();
  
  // Check for DR environment
  if (lowerUrl.includes('.dr.') ||
      lowerUrl.includes('-dr.') ||
      lowerUrl.includes('-dr-') ||
      lowerUrl.includes('/dr/') ||
      lowerUrl.includes('wawanesa-dr') ||
      lowerUrl.includes('login.mypurecloud.com') && lowerUrl.includes('wawanesa-dr')) {
    return 'DR';
  }
  
  // Check for TEST environment
  if (lowerUrl.includes('.test.') ||
      lowerUrl.includes('-test-') ||
      lowerUrl.includes('wawanesa-test') ||
      lowerUrl.includes('cac1.pure.cloud') ||  // cac1 is a test region
      lowerUrl.includes('usw2.pure.cloud') ||  // usw2 is often used for test
      lowerUrl.includes('apps.mypurecloud.com.au') || // AU instance is often used for test
      lowerUrl.includes('apps.mypurecloud.jp')) {     // JP instance is often used for test
    return 'TEST';
  }
  
  // Check for DEV environment
  if (lowerUrl.includes('.dev.') ||
      lowerUrl.includes('-dev-') ||
      lowerUrl.includes('wawanesa-dev') ||
      lowerUrl.includes('apps.inindca.com') ||  // inindca is a dev environment
      lowerUrl.includes('apps.inintca.com')) {  // inintca is a dev environment
    return 'DEV';
  }
  
  // Set a default for unrecognized Genesys Cloud domains
  if (lowerUrl.includes('pure.cloud') ||
      lowerUrl.includes('mypurecloud.com') ||
      lowerUrl.includes('genesyscloud.com')) {
    console.log("Default environment for: " + url);
    return 'TEST'; // Default to TEST for unknown Genesys Cloud domains
  }
  
  // No recognized environment
  return null;
}

// Function to send environment info to content script
function sendEnvironmentToTab(tabId, environment) {
  if (!environment) return;
  
  chrome.tabs.sendMessage(tabId, {
    action: 'updateBadge',
    environment: environment
  }).catch(error => {
    // Silently handle errors (content script might not be loaded yet)
    console.log("Error sending message:", error);
  });
}

// Function to process a tab and update its badge
function processTab(tabId, url) {
  const environment = detectEnvironment(url);
  if (environment) {
    sendEnvironmentToTab(tabId, environment);
  }
}

// Listen for tab activation (user switches tab)
chrome.tabs.onActivated.addListener(activeInfo => {
  chrome.tabs.get(activeInfo.tabId, tab => {
    processTab(tab.id, tab.url);
  }).catch(error => {
    console.error("Error getting tab information:", error);
  });
});

// Listen for tab updates (URL changes)
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  // Only process if the URL has changed and is complete
  if (changeInfo.status === 'complete' && tab.url) {
    processTab(tabId, tab.url);
  }
});

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'getEnvironment' && sender.tab) {
    const environment = detectEnvironment(sender.tab.url);
    sendResponse({ environment: environment });
  }
  // Return true to indicate we'll respond asynchronously
  return true;
});