// Background script for organization ID detection and environment mapping

// Known organization IDs mapped to environments
const ORGANIZATION_MAPPINGS = {
    // DR environment mappings
    "70af5856-802a-423a-b07a-5f420c8e325d": "dr",   // Wawanesa-DR

    // Test environment mappings
    "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test", // Wawanesa-Test (Primary target)
    
    // Dev environment mappings
    "63ba1711-bcf1-4a4b-a101-f458280264b0": "dev",  // Development Org
    
    // Add new organization IDs here as they are discovered
};

// API endpoints that might contain org information
const ORG_RELATED_ENDPOINTS = [
    '/api/v2/organizations/me',
    '/api/v2/users/me',
    '/api/v2/authorization/roles',
    '/api/v2/tokens/me'
];

// Known hostnames mapped to environments
const HOSTNAME_MAPPINGS = {
    // Test environments
    "cac1.pure.cloud": "test",    // CAC1 region is Test environment
    "usw2.pure.cloud": "test",    // USW2 region often used for Test
    "use2.pure.cloud": "test",    // USE2 region often used for Test
    "fra.pure.cloud": "test",     // FRA region often used for Test
    "login.mypurecloud.ca": "test", // Canadian login is typically TEST
    
    // DEV environments
    "use1.dev.us-east-1.aws.dev.genesys.cloud": "dev", // Dev environment hostname
    "dev.genesys.cloud": "dev",     // General dev environment
    
    // DR patterns in hostnames - these have highest confidence
    "dr.mypurecloud.com": "dr",     // Explicit DR in hostname
    "dr-api.mypurecloud.com": "dr", // DR API endpoint
};

// URL patterns for different environments
const ENVIRONMENT_PATTERNS = {
    dr: ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr', 'disaster', 'failover', 'recovery', 'dr-region'],
    test: ['.test.', '-test-', 'wawanesa-test', 'staging', 'qa', 'uat', 'testing', 'test-region'],
    dev: ['.dev.', '-dev-', 'wawanesa-dev', 'development', 'dev-region', 'sandbox']
};

// Words to exclude from pattern matching to avoid false positives
const EXCLUDE_WORDS = {
    dr: ['directory', 'drive', 'drop', 'draw', 'drawer', 'address'],
    test: ['latest', 'greatest', 'contest', 'testimony', 'protest', 'attestation', 'intestate']
};

// Detection methods with confidence levels
const DETECTION_METHODS = {
    ORG_ID: { confidence: 0.95, name: "Organization ID" },
    HOSTNAME: { confidence: 0.95, name: "Hostname" },
    API_ENDPOINT: { confidence: 0.90, name: "API Endpoint" },
    URL_PATTERN: { confidence: 0.85, name: "URL Pattern" },
    TITLE_PATTERN: { confidence: 0.80, name: "Page Title" },
    DEFAULT: { confidence: 0.50, name: "Default" }
};

// Track processed URLs to avoid duplicate operations
const processedUrls = new Set();

// Track detected organization ID
let detectedOrgId = null;
let currentEnvironment = null;
let lastDetectionMethod = null;
let lastDetectionSource = null;
let lastDetectionTime = null;

// Enable logging
const DEBUG = true;
function log(...args) {
    if (DEBUG) {
        console.log('[Environment Extension]', ...args);
    }
}

// Initialize on install or update
chrome.runtime.onInstalled.addListener(function() {
    log('Extension installed/updated');
    
    // Check for existing environment data
    chrome.storage.sync.get(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], function(data) {
        log('Initial data check:', data);
        
        if (data.environmentType) {
            currentEnvironment = data.environmentType;
        }
        
        if (data.detectedOrgId) {
            detectedOrgId = data.detectedOrgId;
        }
        
        if (data.detectionMethod) {
            lastDetectionMethod = data.detectionMethod;
        }
        
        if (data.detectionSource) {
            lastDetectionSource = data.detectionSource;
        }
        
        if (data.lastUpdated) {
            lastDetectionTime = data.lastUpdated;
        }
    });
});

// Listen for navigation events
chrome.webNavigation.onCompleted.addListener(
    (details) => {
        if (details.frameId === 0 && 
            (details.url.includes('.pure.cloud/') || 
             details.url.includes('.mypurecloud.com/') || 
             details.url.includes('.genesys.cloud/'))) {
          
            setTimeout(() => {
                checkHostnameForEnvironment(details.tabId, details.url);
                if (!details.url.includes('/api/v2/')) {
                    injectPageDetectionScript(details.tabId, details.url);
                }
            }, 1000);
        }
    }
);

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

// Check hostname for environment indicators
function checkHostnameForEnvironment(tabId, url) {
    try {
        const parsedUrl = new URL(url);
        const hostname = parsedUrl.hostname.toLowerCase();
        
        // Check for known hostnames (high confidence)
        for (const [knownHostname, environment] of Object.entries(HOSTNAME_MAPPINGS)) {
            if (hostname.includes(knownHostname)) {
                log(`Hostname match: ${knownHostname} -> ${environment}`);
                
                // Update environment based on hostname
                updateEnvironment(environment, null, DETECTION_METHODS.HOSTNAME.name, knownHostname, tabId);
                return;
            }
        }
    } catch (error) {
        log('Error checking hostname:', error);
    }
}

// Handle API responses by injecting a verification script
function handleApiResponse(details) {
    // Only check relevant endpoints and avoid duplicates
    const isRelevantEndpoint = ORG_RELATED_ENDPOINTS.some(endpoint => 
        details.url.includes(endpoint)
    );
    
    if (!isRelevantEndpoint || details.tabId === -1) {
        return;
    }
    
    // Add to processed URLs to avoid reprocessing
    const urlKey = details.url.split('?')[0];
    if (processedUrls.has(urlKey)) {
        return;
    }
    processedUrls.add(urlKey);
    
    // Inject script to check API results that should be in the page context
    setTimeout(() => {
        injectApiDetectionScript(details.tabId, details.url);
    }, 300);
}

// Inject script to verify API results contain our target organization IDs
function injectApiDetectionScript(tabId, url) {
    if (tabId === -1) return;
    
    chrome.scripting.executeScript({
        target: { tabId: tabId },
        func: checkApiResponseForOrgId,
        args: [Object.keys(ORGANIZATION_MAPPINGS), url]
    }).then(handleScriptResults)
        .catch(error => log("Error executing API detection script:", error));
}

// Check page context for the org ID after API responses
function checkApiResponseForOrgId(targetOrgIds, apiUrl) {
    return new Promise((resolve) => {
        try {
            // Check browser storage (most reliable location)
            const storageData = JSON.stringify({
                localStorage: { ...localStorage },
                sessionStorage: { ...sessionStorage }
            });
            
            // Check for each target organization ID
            for (const targetOrgId of targetOrgIds) {
                if (storageData.includes(targetOrgId)) {
                    return resolve({
                        found: true,
                        orgId: targetOrgId,
                        url: apiUrl,
                        location: 'storage'
                    });
                }
            }
            
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
                if (obj && targetOrgIds.includes(obj)) {
                    return resolve({ 
                        found: true, 
                        orgId: obj,
                        url: apiUrl,
                        location: 'direct-object-match'
                    });
                }
            }
            
            // Get HTML to check for org ID
            const htmlContent = document.documentElement.outerHTML;
            for (const targetOrgId of targetOrgIds) {
                if (htmlContent.includes(targetOrgId)) {
                    return resolve({
                        found: true,
                        orgId: targetOrgId,
                        url: apiUrl,
                        location: 'html-content'
                    });
                }
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
        args: [Object.keys(ORGANIZATION_MAPPINGS), url]
    }).then(handleScriptResults)
        .catch(error => log("Error executing page detection script:", error));
}

// Function to deeply check page for org ID
function checkPageForOrgId(targetOrgIds, pageUrl) {
    return new Promise((resolve) => {
        try {
            // Check entire page content
            const pageContent = document.body.innerText;
            for (const targetOrgId of targetOrgIds) {
                if (pageContent.includes(targetOrgId)) {
                    return resolve({
                        found: true,
                        orgId: targetOrgId,
                        url: pageUrl,
                        location: 'page-content'
                    });
                }
            }
            
            // Check HTML for org ID
            const htmlContent = document.documentElement.outerHTML;
            for (const targetOrgId of targetOrgIds) {
                if (htmlContent.includes(targetOrgId)) {
                    return resolve({
                        found: true,
                        orgId: targetOrgId,
                        url: pageUrl,
                        location: 'html-content'
                    });
                }
            }
            
            // Check scripts
            const scriptTags = Array.from(document.getElementsByTagName('script'));
            for (const script of scriptTags) {
                const scriptContent = script.textContent || '';
                for (const targetOrgId of targetOrgIds) {
                    if (scriptContent.includes(targetOrgId)) {
                        return resolve({
                            found: true,
                            orgId: targetOrgId,
                            url: pageUrl,
                            location: 'script-content'
                        });
                    }
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
        const orgId = result.orgId;
        const url = result.url || 'unknown URL';
        const location = result.location || 'unknown location';
        
        log(`[Org ID Detector] Target Org ID ${orgId} detected on URL: ${url}`);
        log(`[Org ID Detector] Detection location: ${location}`);
        
        // Map organization ID to environment
        if (ORGANIZATION_MAPPINGS[orgId]) {
            const environment = ORGANIZATION_MAPPINGS[orgId];
            log(`[Org ID Detector] Mapped to environment: ${environment}`);
            
            // Update detected environment
            updateEnvironment(environment, orgId, DETECTION_METHODS.ORG_ID.name, location);
        }
    }
}

// Update environment information and notify tabs
function updateEnvironment(environment, orgId, method, source, specificTabId = null) {
    // Skip if this is the same environment we already detected
    if (environment === currentEnvironment && (orgId === null || orgId === detectedOrgId)) {
        return;
    }
    
    log(`Updating environment to ${environment} (${method}: ${source})`);
    
    // Update cached values
    currentEnvironment = environment;
    if (orgId) detectedOrgId = orgId;
    lastDetectionMethod = method;
    lastDetectionSource = source;
    lastDetectionTime = new Date().toISOString();
    
    // Store in sync storage
    chrome.storage.sync.set({ 
        environmentType: environment,
        detectedOrgId: orgId || detectedOrgId,
        detectionMethod: method,
        detectionSource: source,
        lastUpdated: lastDetectionTime
    }, function() {
        // If specific tab provided, only notify that tab
        if (specificTabId !== null) {
            notifyTab(specificTabId, environment, orgId);
        } else {
            // Otherwise notify all relevant tabs
            notifyEnvironmentChange(environment, orgId);
        }
    });
}

// Function to notify tabs about environment change
function notifyEnvironmentChange(environment, orgId) {
    chrome.tabs.query({ url: [
        "https://login.mypurecloud.com/*",
        "https://*.mypurecloud.com/*",
        "https://*.pure.cloud/*",
        "https://*.genesys.cloud/*"
    ]}, function(tabs) {
        if (tabs && tabs.length > 0) {
            log(`Notifying ${tabs.length} tabs about environment change to ${environment}`);
            
            tabs.forEach(tab => {
                notifyTab(tab.id, environment, orgId);
            });
        }
    });
}

// Notify a specific tab about environment change
function notifyTab(tabId, environment, orgId = null) {
    try {
        chrome.tabs.sendMessage(tabId, { 
            action: 'environmentChange',
            environment: environment,
            orgId: orgId
        }).catch(error => {
            log(`Tab ${tabId} not ready: ${error.message}`);
        });
    } catch (err) {
        log(`Error sending to tab ${tabId}: ${err.message}`);
    }
}

// Listen for messages from content scripts or popup
chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
    if (message.action === 'getEnvironmentInfo') {
        // Return current environment info
        chrome.storage.sync.get([
            'detectedOrgId', 
            'environmentType', 
            'detectionMethod', 
            'detectionSource',
            'lastUpdated'
        ], function(data) {
            const response = {
                orgId: data.detectedOrgId || null,
                environment: data.environmentType || 'unknown',
                detectionMethod: data.detectionMethod || null,
                detectionSource: data.detectionSource || null,
                lastUpdated: data.lastUpdated || null
            };
            
            log('Sending environment info response:', response);
            sendResponse(response);
        });
        return true; // Keep message channel open for async response
    }
    
    // Handle organization ID detection from content script
    if (message.action === 'detectedOrganizationId' && message.orgId) {
        log('Content script detected organization ID:', message.orgId, 'source:', message.source);
        
        // Map to environment if known
        if (ORGANIZATION_MAPPINGS[message.orgId]) {
            const environment = ORGANIZATION_MAPPINGS[message.orgId];
            updateEnvironment(environment, message.orgId, DETECTION_METHODS.ORG_ID.name, message.source || 'content-script');
        }
        
        sendResponse({ success: true });
        return true;
    }
    
    // Handle manual environment type setting
    if (message.action === 'setEnvironmentType' && message.environmentType) {
        log(`Received setEnvironmentType request: ${message.environmentType}`);
        
        // Update environment manually
        updateEnvironment(message.environmentType, null, 'Manual Override', 'user');
        sendResponse({ success: true });
        return true;
    }
    
    // Handle refresh request
    if (message.action === 'refreshEnvironmentDetection') {
        log('Received refreshEnvironmentDetection request');
        
        // Clear current environment data
        chrome.storage.sync.remove([
            'environmentType',
            'detectionMethod',
            'detectionSource',
            'lastUpdated'
        ], function() {
            // Reset cached variables
            currentEnvironment = null;
            lastDetectionMethod = null;
            lastDetectionSource = null;
            lastDetectionTime = null;
            
            // Force detection on active tab
            chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
                if (tabs && tabs.length > 0) {
                    const activeTab = tabs[0];
                    
                    if (activeTab.url && (
                        activeTab.url.includes('pure.cloud') || 
                        activeTab.url.includes('mypurecloud.com') ||
                        activeTab.url.includes('genesys.cloud')
                    )) {
                        // Inject detection scripts in the active tab
                        injectPageDetectionScript(activeTab.id, activeTab.url);
                        checkHostnameForEnvironment(activeTab.id, activeTab.url);
                        
                        // Send a response after a short delay to allow detection to complete
                        setTimeout(() => {
                            chrome.storage.sync.get([
                                'environmentType',
                                'detectionMethod',
                                'detectionSource',
                                'lastUpdated'
                            ], function(data) {
                                sendResponse({
                                    success: true,
                                    environment: data.environmentType || 'unknown',
                                    detectionMethod: data.detectionMethod || 'refresh',
                                    detectionSource: data.detectionSource || 'user',
                                    lastUpdated: data.lastUpdated || new Date().toISOString()
                                });
                            });
                        }, 500);
                    } else {
                        sendResponse({ 
                            success: false, 
                            message: 'Active tab is not a Genesys Cloud page' 
                        });
                    }
                } else {
                    sendResponse({ success: false, message: 'No active tab found' });
                }
            });
        });
        return true; // Keep message channel open for async response
    }
    
    // Handle clear request
    if (message.action === 'clearEnvironmentDetection') {
        log('Received clearEnvironmentDetection request');
        
        // Clear all environment data
        chrome.storage.sync.remove([
            'environmentType',
            'detectedOrgId',
            'detectionMethod',
            'detectionSource',
            'lastUpdated'
        ], function() {
            // Reset cached variables
            detectedOrgId = null;
            currentEnvironment = null;
            lastDetectionMethod = null;
            lastDetectionSource = null;
            lastDetectionTime = null;
            
            // Send success response
            sendResponse({ success: true });
        });
        return true; // Keep message channel open for async response
    }
}); 