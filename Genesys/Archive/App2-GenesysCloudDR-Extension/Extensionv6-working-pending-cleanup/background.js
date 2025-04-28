// Target Organization ID to detect
const TARGET_ORG_ID = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';

// API endpoints that might contain org information
const ORG_RELATED_ENDPOINTS = [
  '/api/v2/organizations/me',
  '/api/v2/users/me',
  '/api/v2/authorization/roles',
  '/api/v2/tokens/me'
];

// Track URLs we've already processed to avoid duplicate logs
const processedUrls = new Set();

// Listen for network requests to capture API responses
chrome.webRequest.onCompleted.addListener(
  handleApiResponse,
  { 
    urls: [
      '*://*.pure.cloud/api/v2/*',
      '*://*.mypurecloud.com/api/v2/*',
      '*://*.genesys.cloud/api/v2/*'
    ]
  }
);

// Listen for page navigation to check app pages
chrome.webNavigation.onCompleted.addListener(
  (details) => {
    if (details.frameId === 0 && 
        (details.url.includes('.pure.cloud/') || 
         details.url.includes('.mypurecloud.com/') || 
         details.url.includes('.genesys.cloud/'))) {
      
      if (!details.url.includes('/api/v2/')) {
        setTimeout(() => {
          injectPageDetectionScript(details.tabId, details.url);
        }, 2000);
      }
    }
  }
);

// Handle API responses by injecting a verification script to check if the ID exists
function handleApiResponse(details) {
  // Only check relevant endpoints
  const isRelevantEndpoint = ORG_RELATED_ENDPOINTS.some(endpoint => 
    details.url.includes(endpoint)
  );
  
  if (!isRelevantEndpoint || details.tabId === -1) {
    return;
  }
  
  // Inject script to check API results that should be in the page context
  setTimeout(() => {
    injectApiDetectionScript(details.tabId, details.url);
  }, 300);
}

// Inject script to verify API results contain our target ID
function injectApiDetectionScript(tabId, url) {
  if (tabId === -1) return;
  
  chrome.scripting.executeScript({
    target: { tabId: tabId },
    func: checkApiResponseForOrgId,
    args: [TARGET_ORG_ID, url]
  }).then(handleScriptResults)
    .catch(error => console.error("Error executing script:", error));
}

// Check page context for the org ID after API responses
function checkApiResponseForOrgId(targetOrgId, apiUrl) {
  return new Promise((resolve) => {
    try {
      // Look for the target ID in relevant objects that might contain API response data
      
      // Check network response data if available via performance API
      const foundInResourceTiming = Array.from(performance.getEntriesByType('resource'))
        .some(resource => {
          return resource.name === apiUrl && resource.initiatorType === 'xmlhttprequest';
        });
      
      // Check common places where Genesys stores org data
      const commonOrgObjects = [
        // Organization data
        window.PC?.organization?.id,
        window.GenesysCloudWebrtcSdk?.config?.organization?.id,
        window.purecloud?.org?.id,
        
        // Session/auth objects
        window.PC?.authData?.org,
        
        // Global objects that might be set
        window.PURECLOUD_ORG_ID,
        window.ORGANIZATION_ID
      ];
      
      for (const obj of commonOrgObjects) {
        if (obj === targetOrgId) {
          return resolve({ 
            found: true, 
            url: apiUrl,
            location: 'direct-object-match'
          });
        }
      }
      
      // Check localStorage and sessionStorage
      const storageData = JSON.stringify({
        localStorage: { ...localStorage },
        sessionStorage: { ...sessionStorage }
      });
      
      if (storageData.includes(targetOrgId)) {
        return resolve({
          found: true,
          url: apiUrl,
          location: 'storage'
        });
      }
      
      // Get HTML to check for org ID
      const htmlContent = document.documentElement.outerHTML;
      if (htmlContent.includes(targetOrgId)) {
        return resolve({
          found: true,
          url: apiUrl,
          location: 'html-content'
        });
      }
      
      // If a specific API URL was called but we can't verify, still return a partial match
      if (foundInResourceTiming) {
        return resolve({
          found: true,
          url: apiUrl,
          location: 'api-called-not-verified',
          message: 'API was called but content could not be verified directly'
        });
      }
      
      resolve({ found: false });
    } catch (error) {
      console.error('Error in detection script:', error);
      resolve({ found: false, error: error.message });
    }
  });
}

// Inject script to check general page for org ID
function injectPageDetectionScript(tabId, url) {
  if (tabId === -1) return;
  
  chrome.scripting.executeScript({
    target: { tabId: tabId },
    func: checkPageForOrgId,
    args: [TARGET_ORG_ID, url]
  }).then(handleScriptResults)
    .catch(error => console.error("Error executing script:", error));
}

// Function to deeply check page for org ID
function checkPageForOrgId(targetOrgId, pageUrl) {
  return new Promise((resolve) => {
    try {
      // Check entire page content
      const pageContent = document.body.innerText;
      if (pageContent.includes(targetOrgId)) {
        return resolve({
          found: true,
          url: pageUrl,
          location: 'page-content'
        });
      }
      
      // Check HTML for org ID
      const htmlContent = document.documentElement.outerHTML;
      if (htmlContent.includes(targetOrgId)) {
        return resolve({
          found: true,
          url: pageUrl,
          location: 'html-content'
        });
      }
      
      // Check scripts
      const scriptTags = Array.from(document.getElementsByTagName('script'));
      for (const script of scriptTags) {
        const scriptContent = script.textContent || '';
        if (scriptContent.includes(targetOrgId)) {
          return resolve({
            found: true,
            url: pageUrl,
            location: 'script-content'
          });
        }
      }
      
      // Try to find in window objects
      const windowSearch = (obj, path = 'window', depth = 0) => {
        if (depth > 2 || !obj) return null;
        
        if (typeof obj === 'string' && obj === targetOrgId) {
          return path;
        }
        
        if (typeof obj === 'object') {
          for (const key in obj) {
            try {
              if (obj[key] === targetOrgId) {
                return `${path}.${key}`;
              }
              
              const result = windowSearch(obj[key], `${path}.${key}`, depth + 1);
              if (result) return result;
            } catch (e) {
              // Skip properties that can't be accessed
            }
          }
        }
        return null;
      };
      
      // Check main Genesys objects
      const objectsToSearch = [
        { obj: window.PC, name: 'PC' },
        { obj: window.purecloud, name: 'purecloud' },
        { obj: window.GenesysCloudWebrtcSdk, name: 'GenesysCloudWebrtcSdk' }
      ];
      
      for (const { obj, name } of objectsToSearch) {
        const location = windowSearch(obj, name);
        if (location) {
          return resolve({
            found: true,
            url: pageUrl,
            location
          });
        }
      }
      
      resolve({ found: false });
    } catch (error) {
      console.error('Error in page detection script:', error);
      resolve({ found: false, error: error.message });
    }
  });
}

// Handle results from the injected scripts
function handleScriptResults(results) {
  if (results && results[0]?.result?.found) {
    const result = results[0].result;
    const url = result.url || 'unknown URL';
    const location = result.location || 'unknown location';
    
    console.log(`[Org ID Detector] Target Org ID ${TARGET_ORG_ID} detected on URL: ${url}`);
    console.log(`[Org ID Detector] Detection location: ${location}`);
    
    if (result.message) {
      console.log(`[Org ID Detector] ${result.message}`);
    }
  }
} 