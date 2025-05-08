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

// URL patterns for different environments - important for DR detection!
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
    function(details) {
        if (details.frameId === 0 && 
            (details.url.includes('.pure.cloud/') || 
             details.url.includes('.mypurecloud.com/') || 
             details.url.includes('.genesys.cloud/'))) {
          
            setTimeout(() => {
                checkUrlForEnvironment(details.tabId, details.url);
                if (!details.url.includes('/api/v2/')) {
                    injectPageDetectionScript(details.tabId, details.url);
                }
            }, 1000);
        }
    }
);

// Listen for tabs being updated to capture more navigation events
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    // Only process complete loads of relevant URLs
    if (changeInfo.status === 'complete' && tab.url && 
        (tab.url.includes('pure.cloud') || tab.url.includes('mypurecloud.com') || 
         tab.url.includes('genesys.cloud'))) {
        
        log('Tab updated:', tab.url);
        
        // Check URL for environment indicators (both hostname and patterns)
        checkUrlForEnvironment(tabId, tab.url);
        
        // Inject script to check for org ID
        if (!tab.url.includes('/api/v2/')) {
            setTimeout(() => {
                injectPageDetectionScript(tabId, tab.url);
            }, 1000);
        }
    }
});

// Set up web request listener
if (chrome.webRequest) {
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
    log('Web request listener set up successfully');
} else {
    log('Web request API not available');
}

// Check URL for environment indicators (hostname and patterns)
function checkUrlForEnvironment(tabId, url) {
    try {
        const urlLower = url.toLowerCase();
        const parsedUrl = new URL(urlLower);
        const hostname = parsedUrl.hostname.toLowerCase();
        const path = parsedUrl.pathname;
        const fullUrlText = `${hostname}${path}${parsedUrl.hash}`;
        
        // First check if this is clearly a DR URL by specific patterns
        // These are so definitive that we should trust them regardless of other detection methods
        const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
        const hasStrongDrPattern = strongDrPatterns.some(pattern => urlLower.includes(pattern));
        
        if (hasStrongDrPattern) {
            log(`Strong DR pattern found in URL: ${url}`);
            // For strong DR patterns, we'll prioritize this over any existing detection
            for (const pattern of strongDrPatterns) {
                if (urlLower.includes(pattern)) {
                    updateEnvironment('dr', null, DETECTION_METHODS.URL_PATTERN.name, `strong-dr-pattern:${pattern}`, tabId);
                    return;
                }
            }
        }
        
        // Check if we already have a high-confidence environment detection
        chrome.storage.sync.get(['environmentType', 'detectionMethod'], function(data) {
            // If we already have organization ID based detection, respect it
            // unless we already determined this is a strong DR URL above
            if (data.environmentType && 
                data.detectionMethod === DETECTION_METHODS.ORG_ID.name && 
                !hasStrongDrPattern) {
                log(`Already have high-confidence detection (${data.detectionMethod}): ${data.environmentType}, skipping URL pattern detection`);
                return;
            }
            
            // Continue with standard URL detection logic
            // 1. Check for known hostnames (high confidence)
            for (const [knownHostname, environment] of Object.entries(HOSTNAME_MAPPINGS)) {
                if (hostname.includes(knownHostname)) {
                    log(`Hostname match: ${knownHostname} -> ${environment}`);
                    
                    // Update environment based on hostname
                    updateEnvironment(environment, null, DETECTION_METHODS.HOSTNAME.name, knownHostname, tabId);
                    return;
                }
            }

            // 2. Check for DR patterns (unless URL contains exclusion words)
            const hasDrExcludeWord = EXCLUDE_WORDS.dr.some(word => fullUrlText.includes(word));
            
            if (!hasDrExcludeWord) {
                // Special case for DR login URLs that might be more reliable
                if (hostname.includes('login') && fullUrlText.includes('wawanesa-dr')) {
                    log('Found DR login URL with organization name');
                    updateEnvironment('dr', null, DETECTION_METHODS.URL_PATTERN.name, 'login-wawanesa-dr', tabId);
                    return;
                }
                
                for (const pattern of ENVIRONMENT_PATTERNS.dr) {
                    if (urlLower.includes(pattern)) {
                        log(`DR pattern match in URL: ${pattern}`);
                        updateEnvironment('dr', null, DETECTION_METHODS.URL_PATTERN.name, `url-pattern:${pattern}`, tabId);
                        return;
                    }
                }
            }

            // 3. Check for API endpoints that might indicate DR environment
            if (path.includes('/api/')) {
                if (path.includes('/dr/') || path.includes('/dr-api/')) {
                    log('DR API endpoint detected in path');
                    updateEnvironment('dr', null, DETECTION_METHODS.API_ENDPOINT.name, path, tabId);
                    return;
                }
            }

            log('No environment indicators found in URL');
        });
    } catch (error) {
        log('Error checking URL:', error);
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
    
    try {
        chrome.scripting.executeScript({
            target: { tabId: tabId },
            func: checkApiResponseForOrgId,
            args: [Object.keys(ORGANIZATION_MAPPINGS), url]
        }).then(handleScriptResults)
            .catch(error => log("Error executing API detection script:", error));
    } catch (error) {
        log('Error injecting script:', error);
    }
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
    
    try {
        chrome.scripting.executeScript({
            target: { tabId: tabId },
            func: checkPageForOrgId,
            args: [Object.keys(ORGANIZATION_MAPPINGS), url]
        }).then(handleScriptResults)
            .catch(error => log("Error executing page detection script:", error));
    } catch (error) {
        log('Error injecting page script:', error);
    }
}

// Function to deeply check page for org ID
function checkPageForOrgId(targetOrgIds, pageUrl) {
    return new Promise((resolve) => {
        try {
            // Check entire page content
            const pageContent = document.body.innerText;
            for (const targetOrgId of targetOrgIds) {
                if (pageContent && pageContent.includes(targetOrgId)) {
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
    // Get the confidence level of the current detection method
    const currentMethodConfidence = 
        lastDetectionMethod ? 
        (DETECTION_METHODS[lastDetectionMethod] || DETECTION_METHODS.DEFAULT).confidence : 
        0;
    
    // Get the confidence level of the new detection method
    const newMethodConfidence = 
        (DETECTION_METHODS[method] || DETECTION_METHODS.DEFAULT).confidence;
    
    // Skip if this is the same environment we already detected
    if (environment === currentEnvironment && (orgId === null || orgId === detectedOrgId)) {
        log(`Same environment ${environment} already detected, skipping update`);
        return;
    }
    
    // Special case: Allow DR detection to override TEST when URL patterns strongly indicate DR
    // This handles the case where a TEST org ID might be present in DR environment
    if (currentEnvironment === 'test' && environment === 'dr') {
        if (method === DETECTION_METHODS.HOSTNAME.name || 
            (method === DETECTION_METHODS.URL_PATTERN.name && 
             (source.includes('wawanesa-dr') || source.includes('/dr/')))) {
            
            log(`Allowing DR detection (${method}: ${source}) to override TEST detection because URL strongly indicates DR environment`);
            // Continue with the update
        } else if (currentMethodConfidence > newMethodConfidence) {
            // Otherwise, respect confidence levels
            log(`Ignoring ${environment} detection from ${method} (confidence: ${newMethodConfidence}) ` +
                `because we already have ${currentEnvironment} from ${lastDetectionMethod} (confidence: ${currentMethodConfidence})`);
            return;
        }
    }
    // Standard confidence check for other cases
    else if (currentEnvironment !== null && currentMethodConfidence > newMethodConfidence) {
        log(`Ignoring ${environment} detection from ${method} (confidence: ${newMethodConfidence}) ` +
            `because we already have ${currentEnvironment} from ${lastDetectionMethod} (confidence: ${currentMethodConfidence})`);
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
    
    // Handle strong DR pattern detection from content script
    if (message.action === 'strongDrPatternDetected') {
        log('Content script detected strong DR pattern:', message.pattern, 'in URL:', message.url);
        
        // Always set to DR environment with high confidence
        updateEnvironment('dr', null, DETECTION_METHODS.URL_PATTERN.name, `strong-pattern:${message.pattern}`);
        
        sendResponse({ success: true });
        return true;
    }
    
    // Handle URL pattern based environment override
    if (message.action === 'urlPatternOverride') {
        log('Content script detected URL pattern override to', message.environment, 'for URL:', message.url);
        
        // Update environment based on URL pattern with high confidence
        updateEnvironment(message.environment, null, DETECTION_METHODS.URL_PATTERN.name, `url-override:${message.pattern}-pattern`);
        
        sendResponse({ success: true });
        return true;
    }
    
    // Handle check for specific URL (from popup)
    if (message.action === 'checkSpecificUrl') {
        log('Popup requested URL check for:', message.url);
        
        if (message.url) {
            // Directly check this URL for environment indicators
            const tabId = message.tabId || null;
            checkUrlForEnvironment(tabId, message.url);
            
            // Respond immediately but checking will happen asynchronously
            sendResponse({ success: true, message: 'URL check initiated' });
        } else {
            sendResponse({ success: false, message: 'No URL provided' });
        }
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
                        // Check for URL-based patterns first (for DR detection)
                        checkUrlForEnvironment(activeTab.id, activeTab.url);
                        
                        // Inject detection scripts in the active tab
                        injectPageDetectionScript(activeTab.id, activeTab.url);
                        
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

    // Handle getCurrentEnvironment message
    if (message.action === 'getCurrentEnvironment') {
        log('Current environment requested for URL:', message.url);
        
        // First check URL for strong patterns
        const url = message.url.toLowerCase();
        
        // Strong DR patterns override everything
        const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
        const hasStrongDrPattern = strongDrPatterns.some(pattern => url.includes(pattern));
        
        if (hasStrongDrPattern) {
            log('Strong DR pattern in URL - returning DR environment');
            sendResponse({ 
                environmentType: 'dr',
                detectionMethod: DETECTION_METHODS.URL_PATTERN.name,
                source: 'url-pattern',
                confidence: DETECTION_METHODS.URL_PATTERN.confidence
            });
            return true;
        }
        
        // Strong TEST patterns if no DR patterns
        const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
        const hasStrongTestPattern = strongTestPatterns.some(pattern => url.includes(pattern));
        
        if (hasStrongTestPattern) {
            log('Strong TEST pattern in URL - returning TEST environment');
            sendResponse({ 
                environmentType: 'test',
                detectionMethod: DETECTION_METHODS.URL_PATTERN.name,
                source: 'url-pattern',
                confidence: DETECTION_METHODS.URL_PATTERN.confidence
            });
            return true;
        }
        
        // Return current stored environment
        chrome.storage.sync.get(['environmentType', 'detectionMethod', 'detectionSource', 'detectionConfidence'], function(data) {
            log('Returning stored environment data:', data);
            sendResponse(data);
        });
        
        return true; // Keep message channel open for async response
    }
    
    return true; // Keep the message channel open for async responses
}); 