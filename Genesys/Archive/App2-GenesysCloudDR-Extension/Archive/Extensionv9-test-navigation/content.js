// Create badge element
function createBadgeElement() {
  // Check if the badge already exists
  if (document.getElementById('genesys-env-badge')) {
    return document.getElementById('genesys-env-badge');
  }
  
  // Check if body exists yet
  if (!document.body) {
    console.log("Body not available yet, will retry");
    return null;
  }
  
  // Create new badge element
  const badge = document.createElement('div');
  badge.id = 'genesys-env-badge';
  badge.className = 'genesys-env-badge';
  
  // Append to document body
  document.body.appendChild(badge);
  console.log("Badge element created successfully");
  return badge;
}

// Update badge with environment info
function updateBadge(environment) {
  const badge = createBadgeElement();
  
  if (!badge) {
    // If body isn't ready, retry after a short delay
    setTimeout(() => updateBadge(environment), 100);
    return;
  }
  
  // Set badge text
  badge.textContent = environment;
  
  // Set badge color based on environment
  badge.className = 'genesys-env-badge'; // Reset classes
  badge.classList.add(`genesys-env-${environment.toLowerCase()}`);
  
  // Make badge visible
  badge.style.display = 'block';
  
  console.log(`Badge updated: ${environment}`);
}

// Function to check if document is ready
function onDocumentReady(callback) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', callback);
  } else {
    callback();
  }
}

// Initialize badge immediately
function initBadge() {
  console.log("Initializing badge");
  
  // Request environment from background script
  chrome.runtime.sendMessage({ action: 'getEnvironment' }, response => {
    console.log("Got response from background script:", response);
    if (response && response.environment) {
      updateBadge(response.environment);
    } else {
      console.log("No environment detected in response");
    }
  }).catch(error => {
    console.error("Error getting environment:", error);
    // Retry after a short delay
    setTimeout(initBadge, 1000);
  });
}

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'updateBadge' && message.environment) {
    updateBadge(message.environment);
  }
});

// Wait for document to be ready before initializing
onDocumentReady(() => {
  // Initialize badge when content script loads and document is ready
  initBadge();
  
  // Re-check periodically to ensure badge is visible
  setInterval(() => {
    if (!document.getElementById('genesys-env-badge') ||
        document.getElementById('genesys-env-badge').style.display === 'none') {
      console.log("Badge not found or not visible, re-initializing");
      initBadge();
    }
  }, 2000);
  
  // Re-check for DOM changes that might affect badge visibility
  if (document.body) {
    const observer = new MutationObserver(mutations => {
      // Ensure our badge is still in the DOM and visible
      if (!document.getElementById('genesys-env-badge') ||
          document.getElementById('genesys-env-badge').style.display === 'none') {
        console.log("DOM changed, re-initializing badge");
        initBadge();
      }
    });
    
    // Start observing DOM changes
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
    console.log("Mutation observer started");
  }
});

// Also try to initialize immediately in case document is already ready
initBadge();