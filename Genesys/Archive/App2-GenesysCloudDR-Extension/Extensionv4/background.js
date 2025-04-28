// Background script for organization ID detection and environment mapping

// Known organization IDs mapped to environments
const ORGANIZATION_MAPPINGS = {
    // DR environment mappings
    "70af5856-802a-423a-b07a-5f420c8e325d": "dr",   // Wawanesa-DR

    // Test environment mappings
    "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test", // Wawanesa-Test
    "a3fb3658-fd69-4632-89bb-2fe5c9d10d7d": "test", // Possible Test Org ID
    "b4ff7eec-5c7d-4c34-9f40-d07fb432a1b2": "test", // Possible Test Org ID
    "e31a8aa5-bdba-4ae1-a91a-9e44f3feaa9d": "test", // Possible Test Org ID
    
    // Dev environment mappings
    "63ba1711-bcf1-4a4b-a101-f458280264b0": "dev",  // Development Org
    
    // Add new organization IDs here as they are discovered
};

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
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    // Only process complete loads of relevant URLs
    if (changeInfo.status === 'complete' && tab.url && 
        (tab.url.includes('pure.cloud') || tab.url.includes('mypurecloud.com') || tab.url.includes('genesys.cloud'))) {
        log('Tab updated:', tab.url);
        
        // Detect environment from URL and other available information
        detectEnvironment(tab.url, tab.title).then(result => {
            const { environment, confidence, method, source } = result;
            
            if (environment && environment !== 'unknown') {
                log(`Detected environment: ${environment} (confidence: ${confidence}, method: ${method}, source: ${source})`);
                
                // Update current environment
                currentEnvironment = environment;
                lastDetectionMethod = method;
                lastDetectionSource = source;
                lastDetectionTime = new Date().toISOString();
                
                // Store detected environment
                chrome.storage.sync.set({ 
                    environmentType: environment,
                    detectionMethod: method,
                    detectionSource: source,
                    lastUpdated: lastDetectionTime
                }, function() {
                    // Notify tab about environment change
                    notifyTab(tabId, environment);
                });
            }
        });
    }
});

// Detect environment from URL and other available information
async function detectEnvironment(url, title = '') {
    const urlLower = url.toLowerCase();
    const titleLower = title ? title.toLowerCase() : '';
    
    try {
        // Step 1: Parse URL components
        const parsedUrl = new URL(urlLower);
        const hostname = parsedUrl.hostname;
        const path = parsedUrl.pathname;
        const fragment = parsedUrl.hash;
        const fullUrlText = `${hostname}${path}${fragment}`;
        
        log('URL components:', { hostname, path, fragment });
        
        // Step 2: Check for known organization ID in the URL (highest confidence)
        const orgIdMatch = urlLower.match(/org(?:anization)?[=\/]([a-f0-9-]{36})/i);
        if (orgIdMatch && orgIdMatch[1] && ORGANIZATION_MAPPINGS[orgIdMatch[1]]) {
            const orgId = orgIdMatch[1];
            const environment = ORGANIZATION_MAPPINGS[orgId];
            log(`URL contains mapped organization ID: ${orgId} -> ${environment}`);
            
            // Save the detected org ID for future reference
            detectedOrgId = orgId;
            
            return { 
                environment, 
                confidence: DETECTION_METHODS.ORG_ID.confidence, 
                method: DETECTION_METHODS.ORG_ID.name,
                source: `${orgId}`
            };
        }
        
        // Step 3: Check for known hostnames (high confidence)
        for (const [knownHostname, environment] of Object.entries(HOSTNAME_MAPPINGS)) {
            if (hostname.includes(knownHostname)) {
                log(`Hostname match: ${knownHostname} -> ${environment}`);
                return { 
                    environment, 
                    confidence: DETECTION_METHODS.HOSTNAME.confidence, 
                    method: DETECTION_METHODS.HOSTNAME.name,
                    source: knownHostname
                };
            }
        }
        
        // Step 4: Check for API endpoints that might indicate environment
        if (path.includes('/api/')) {
            if (path.includes('/dr/') || path.includes('/dr-api/')) {
                log('DR API endpoint detected');
                return { 
                    environment: 'dr', 
                    confidence: DETECTION_METHODS.API_ENDPOINT.confidence, 
                    method: DETECTION_METHODS.API_ENDPOINT.name,
                    source: path
                };
            }
            
            if (path.includes('/test/') || path.includes('/test-api/')) {
                log('Test API endpoint detected');
                return { 
                    environment: 'test', 
                    confidence: DETECTION_METHODS.API_ENDPOINT.confidence, 
                    method: DETECTION_METHODS.API_ENDPOINT.name,
                    source: path
                };
            }
        }
        
        // Step 5: Check for DR patterns (unless URL contains exclusion words)
        const hasDrExcludeWord = EXCLUDE_WORDS.dr.some(word => fullUrlText.includes(word));
        
        if (!hasDrExcludeWord) {
            // Special case for DR login URLs that might be more reliable
            if (hostname.includes('login') && fullUrlText.includes('wawanesa-dr')) {
                log('Found DR login URL with organization name');
                return { 
                    environment: 'dr', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: 'login-wawanesa-dr'
                };
            }
            
            for (const pattern of ENVIRONMENT_PATTERNS.dr) {
                if (urlLower.includes(pattern)) {
                    log(`DR pattern match in URL: ${pattern}`);
                    return { 
                        environment: 'dr', 
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`
                    };
                }
                
                if (titleLower.includes(pattern)) {
                    log(`DR pattern match in title: ${pattern}`);
                    return { 
                        environment: 'dr', 
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence, 
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `title-pattern:${pattern}`
                    };
                }
            }
        }
        
        // Step 6: Check for test patterns
        const hasTestExcludeWord = EXCLUDE_WORDS.test.some(word => fullUrlText.includes(word));
            
        if (!hasTestExcludeWord) {
            // Special case for test login URLs
            if (hostname.includes('login') && fullUrlText.includes('wawanesa-test')) {
                log('Found Test login URL with organization name');
                return { 
                    environment: 'test', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: 'login-wawanesa-test'
                };
            }
            
            for (const pattern of ENVIRONMENT_PATTERNS.test) {
                if (urlLower.includes(pattern)) {
                    log(`Test pattern match in URL: ${pattern}`);
                    return { 
                        environment: 'test', 
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`
                    };
                }
                
                if (titleLower.includes(pattern)) {
                    log(`Test pattern match in title: ${pattern}`);
                    return { 
                        environment: 'test', 
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence, 
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `title-pattern:${pattern}`
                    };
                }
            }
        }
        
        // Step 7: Check for dev patterns
        for (const pattern of ENVIRONMENT_PATTERNS.dev) {
            if (urlLower.includes(pattern)) {
                log(`Dev pattern match in URL: ${pattern}`);
                return { 
                    environment: 'dev', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: `url-pattern:${pattern}`
                };
            }
            
            if (titleLower.includes(pattern)) {
                log(`Dev pattern match in title: ${pattern}`);
                return { 
                    environment: 'dev', 
                    confidence: DETECTION_METHODS.TITLE_PATTERN.confidence, 
                    method: DETECTION_METHODS.TITLE_PATTERN.name,
                    source: `title-pattern:${pattern}`
                };
            }
        }
        
        // Step 8: If no environment detected yet, return unknown
        return { 
            environment: 'unknown', 
            confidence: DETECTION_METHODS.DEFAULT.confidence, 
            method: DETECTION_METHODS.DEFAULT.name,
            source: 'default'
        };
    } catch (error) {
        log('Error detecting environment:', error);
        return { 
            environment: 'unknown', 
            confidence: 0.3, 
            method: 'error',
            source: error.message
        };
    }
}

// Monitor web requests to extract organization ID
chrome.webRequest.onBeforeSendHeaders.addListener(
    function(details) {
        // Enhanced logging for organization ID detection
        log('Checking request for org ID:', details.url);
        
        try {
            // Extract organization ID from URL - expanded pattern matching
            const orgIdPatterns = [
                /\/api\/v2\/organizations\/([a-f0-9-]{36})/i,
                /\/api\/v1\/organizations\/([a-f0-9-]{36})/i,
                /\/api\/v\d+\/org(?:anization)?s?\/([a-f0-9-]{36})/i,
                /organizationId=([a-f0-9-]{36})/i,
                /org(?:anization)?Id=([a-f0-9-]{36})/i,
                /org(?:anization)?=([a-f0-9-]{36})/i
            ];
            
            for (const pattern of orgIdPatterns) {
                const match = details.url.match(pattern);
                if (match && match[1] && match[1] !== 'me') {
                    const orgId = match[1];
                    log('Found organization ID in URL:', orgId, 'Known mapping?', !!ORGANIZATION_MAPPINGS[orgId]);
                    setOrganizationId(orgId, details.url);
                    return;
                }
            }
            
            // Check headers for org ID - expanded header names
            if (details.requestHeaders) {
                log('Checking request headers for org ID');
                details.requestHeaders.forEach(header => {
                    if (header.name.toLowerCase().includes('org')) {
                        log('Potential org header:', header.name, header.value);
                    }
                });
                
                const orgHeaders = [
                    'x-organization-id',
                    'organizationid',
                    'organization-id',
                    'org-id',
                    'orgid',
                    'x-org-id'
                ];
                
                for (const headerName of orgHeaders) {
                    const orgHeader = details.requestHeaders.find(h => 
                        h.name.toLowerCase() === headerName);
                    
                    if (orgHeader && orgHeader.value) {
                        const headerValue = orgHeader.value.trim();
                        // Check if value looks like a UUID/GUID
                        if (headerValue.match(/^[a-f0-9-]{36}$/i)) {
                            log('Found organization ID in header:', headerValue, 'Known mapping?', !!ORGANIZATION_MAPPINGS[headerValue]);
                            setOrganizationId(headerValue, 'request-header');
                            return;
                        }
                    }
                }
            }
        } catch (error) {
            log('Error extracting organization ID:', error);
        }
    },
    { urls: ["https://*.mypurecloud.com/*", "https://*.pure.cloud/*", "https://*.genesys.cloud/*"] },
    ["requestHeaders"]
);

// Monitor API responses to extract organization ID
chrome.webRequest.onCompleted.addListener(
    function(details) {
        // Only process successful GET responses from specific endpoints
        if (details.method !== 'GET' || details.statusCode < 200 || details.statusCode >= 300) {
            return;
        }

        // Focus on specific API endpoints that return organization data
        const targetUrls = [
            '/api/v2/organizations/me',
            '/api/v1/org', // Less common but possible
            '/api/v2/users/me' // Often contains org info
        ];

        if (details.tabId > 0 && targetUrls.some(target => details.url.includes(target))) {

            log('Processing potential organization API response:', details.url, 'Tab ID:', details.tabId);

            // For Manifest V3, inject a script to attempt extraction from page context
            // immediately after the request completes. This has a higher chance of
            // finding the ID if it's stored in a global variable or SDK object.
            chrome.scripting.executeScript({
                target: { tabId: details.tabId },
                func: attemptOrgIdExtractionFromPageContext, // Defined below
                args: [details.url] // Pass URL for logging context if needed
            }).then(injectionResults => {
                if (chrome.runtime.lastError) {
                    log(`Script injection failed for tab ${details.tabId}: ${chrome.runtime.lastError.message}`);
                    return;
                }

                if (injectionResults && injectionResults[0] && injectionResults[0].result) {
                    const extractedOrgId = injectionResults[0].result;
                    if (extractedOrgId) {
                        log(`Script injection successfully extracted Org ID: ${extractedOrgId} from ${details.url}`);
                        // Pass the extracted ID and the source URL to setOrganizationId
                        setOrganizationId(extractedOrgId, `script-injection:${details.url}`);
                    } else {
                        log(`Script injection ran but did not find Org ID from ${details.url}`);
                    }
                } else {
                     log(`Script injection on tab ${details.tabId} did not return a result for ${details.url}`);
                }
            }).catch(error => {
                // Catch potential errors during script execution (e.g., tab closed)
                log(`Error executing script on tab ${details.tabId}: ${error}`);
            });
        }
    },
    { urls: [ // Keep the URL filters fairly specific
        "https://*.mypurecloud.com/api/v*/organizations/me*",
        "https://*.mypurecloud.com/api/v*/org*",
        "https://*.mypurecloud.com/api/v*/users/me*",
        "https://*.pure.cloud/api/v*/organizations/me*",
        "https://*.pure.cloud/api/v*/org*",
        "https://*.pure.cloud/api/v*/users/me*",
        "https://*.genesys.cloud/api/v*/organizations/me*",
        "https://*.genesys.cloud/api/v*/org*",
        "https://*.genesys.cloud/api/v*/users/me*"
    ]}
);

// Function to be injected into the page context to find the Org ID
// This function runs in the page's scope, NOT the background script's scope.
async function attemptOrgIdExtractionFromPageContext(sourceUrl) {
    // Define the target Org ID for logging/confirmation if needed
    const targetTestOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    console.log(`[Genesys Env Ext - Injected Script] Running for ${sourceUrl}`);

    // Regex for UUID format
    const orgIdRegex = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i;

    // Focus on the most likely base objects based on page logs and common Genesys patterns
    const baseObjectsToCheck = [
        window.GenesysCloudWebrtcSdk,
        window.PC,
        window.purecloud,
        window.genesys,
        window.PCApp,
        window.__INITIAL_STATE__ // Keep this one as it often holds bootstrap data
    ];

    // Common property keys or nested paths where the Org ID might be stored within the base objects
    const potentialIdKeys = ['id', 'guid', 'orgId', 'organizationId'];
    const potentialNestedPaths = [
        'organization',
        'org',
        'session.organization',
        'config.organization',
        'config',
        'settings.organization',
        'orgInfo',
        'orgDetails',
        'session',
        'userSession.org',
        'userSession.organization', // From content script
        'entities.organizations.me' // For __INITIAL_STATE__
    ];

    // Inner async function to perform the check
    async function findId() {
        for (const baseObj of baseObjectsToCheck) {
            if (!baseObj) continue; // Skip if the base object doesn't exist

            const baseObjName = Object.keys(window).find(key => window[key] === baseObj) || '[unknown base object]';
            console.log(`[Genesys Env Ext - Injected Script] Checking base object: ${baseObjName}`);

            // 1. Check direct properties of the base object
            for (const key of potentialIdKeys) {
                if (typeof baseObj[key] === 'string' && orgIdRegex.test(baseObj[key]) && baseObj[key] !== 'me') {
                    const foundId = baseObj[key];
                    console.log(`[Genesys Env Ext - Injected Script] Found Org ID directly in ${baseObjName}.${key}: ${foundId}`);
                    if (foundId === targetTestOrgId) console.log(`[Genesys Env Ext - Injected Script] Confirmed TARGET Org ID found.`);
                    return foundId;
                }
            }

            // 2. Check common nested paths within the base object
            for (const nestedPath of potentialNestedPaths) {
                try {
                    const parts = nestedPath.split('.');
                    let current = baseObj;
                    for (const part of parts) {
                        if (current && typeof current === 'object' && current !== null && part in current) {
                            current = current[part];
                        } else {
                            current = undefined; // Path doesn't fully exist within baseObj
                            break;
                        }
                    }

                    if (current) {
                        // A. Check if the final nested object itself has an ID property
                        if (typeof current === 'object' && current !== null) {
                             for (const key of potentialIdKeys) {
                                if (typeof current[key] === 'string' && orgIdRegex.test(current[key]) && current[key] !== 'me') {
                                    const foundId = current[key];
                                    console.log(`[Genesys Env Ext - Injected Script] Found Org ID in ${baseObjName}.${nestedPath}.${key}: ${foundId}`);
                                    if (foundId === targetTestOrgId) console.log(`[Genesys Env Ext - Injected Script] Confirmed TARGET Org ID found.`);
                                    return foundId;
                                }
                            }
                        }
                        // B. Check if the final value at the nested path is the ID string itself
                        else if (typeof current === 'string' && orgIdRegex.test(current) && current !== 'me') {
                            const foundId = current;
                            console.log(`[Genesys Env Ext - Injected Script] Found Org ID directly at ${baseObjName}.${nestedPath}: ${foundId}`);
                            if (foundId === targetTestOrgId) console.log(`[Genesys Env Ext - Injected Script] Confirmed TARGET Org ID found.`);
                            return foundId;
                        }
                    }
                } catch (e) {
                    // Ignore errors traversing nested paths
                    // console.warn(`[Genesys Env Ext - Injected Script] Error checking nested path ${baseObjName}.${nestedPath}: ${e.message}`);
                }
            }
        }
        return null; // Not found in this pass
    }

    // Retry mechanism
    let attempts = 0;
    const maxAttempts = 3;
    const initialDelay = 150; // ms
    const subsequentDelay = 250; // ms

    while (attempts < maxAttempts) {
        const foundOrgId = await findId();
        if (foundOrgId) {
            console.log(`[Genesys Env Ext - Injected Script] Found Org ID after ${attempts} retries.`);
            return foundOrgId;
        }
        attempts++;
        if (attempts < maxAttempts) {
            const delay = attempts === 1 ? initialDelay : subsequentDelay;
            console.log(`[Genesys Env Ext - Injected Script] Org ID not found, retrying in ${delay}ms...`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    console.log('[Genesys Env Ext - Injected Script] Org ID not found after all attempts.');
    return null; // Indicate Org ID not found
}

// Handle organization ID detection and environment mapping
function setOrganizationId(orgId, source) {
    if (!orgId || orgId === detectedOrgId) return;
    
    log('Organization ID detected:', orgId, 'source:', source);
    detectedOrgId = orgId;
    
    // Check if this is a known organization ID
    if (ORGANIZATION_MAPPINGS[orgId]) {
        const environment = ORGANIZATION_MAPPINGS[orgId];
        log(`Mapped organization ID to environment: ${environment}`);
        
        // Update detection info
        lastDetectionMethod = DETECTION_METHODS.ORG_ID.name;
        lastDetectionSource = source;
        lastDetectionTime = new Date().toISOString();
        
        // Store detected organization ID and environment
        chrome.storage.sync.set({ 
            detectedOrgId: orgId,
            environmentType: environment,
            detectionMethod: lastDetectionMethod,
            detectionSource: lastDetectionSource,
            lastUpdated: lastDetectionTime
        }, function() {
            // Update cached environment
            currentEnvironment = environment;
            
            // Notify open tabs about the environment change
            notifyEnvironmentChange(environment, orgId);
        });
        
        return;
    }
    
    // Store unknown organization IDs for future reference
    log('Unknown organization ID detected:', orgId);
    
    // Store last 10 unknown organization IDs for admin review
    chrome.storage.sync.get(['unknownOrgIds'], function(data) {
        let unknownIds = data.unknownOrgIds || [];
        
        // Only add if not already in the list
        if (!unknownIds.includes(orgId)) {
            // Add new ID to the start of the array
            unknownIds.unshift({
                id: orgId,
                source: source,
                detected: new Date().toISOString(),
                url: source.startsWith('http') ? source : 'header'
            });
            
            // Keep only the last 10 unknown IDs
            if (unknownIds.length > 10) {
                unknownIds = unknownIds.slice(0, 10);
            }
            
            // Save updated list
            chrome.storage.sync.set({ unknownOrgIds: unknownIds });
        }
    });
    
    // If not a known ID, don't override existing DR detection
    chrome.storage.sync.get(['environmentType'], function(data) {
        const currentType = data.environmentType;
        log('Current environment type:', currentType);
        
        // Don't override if already a DR environment
        if (currentType === 'dr') {
            log('Preserving DR environment type');
            return;
        }
        
        // Store the organization ID for future reference
        chrome.storage.sync.set({ 
            detectedOrgId: orgId,
            detectionSource: source,
            lastUpdated: new Date().toISOString()
        });
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
        log('Received getEnvironmentInfo request');
        
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
        setOrganizationId(message.orgId, message.source || 'content-script');
        sendResponse({ success: true });
        return true;
    }
    
    // Handle direct API organization fetch request
    if (message.action === 'fetchOrganizationInfo') {
        log('Received direct API organization info request');
        fetchOrganizationInfoDirectly(sender.tab.id)
            .then(result => {
                log('Direct API fetch result:', result);
                sendResponse(result);
            })
            .catch(error => {
                log('Error in direct API fetch:', error);
                sendResponse({ error: error.message });
            });
        return true; // Keep message channel open for async response
    }
    
    // Handle manual environment type setting
    if (message.action === 'setEnvironmentType' && message.environmentType) {
        log(`Received setEnvironmentType request: ${message.environmentType}`);
        
        const now = new Date().toISOString();
        
        // Update environment type in storage
        chrome.storage.sync.set({ 
            environmentType: message.environmentType,
            detectionMethod: 'Manual Override',
            detectionSource: 'user',
            lastUpdated: now
        }, function() {
            // Update cached environment
            currentEnvironment = message.environmentType;
            lastDetectionMethod = 'Manual Override';
            lastDetectionSource = 'user';
            lastDetectionTime = now;
            
            // Send success response
            sendResponse({ success: true });
            
            // Notify all tabs about manual change
            notifyEnvironmentChange(message.environmentType, null);
        });
        return true; // Keep message channel open for async response
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
                        detectEnvironment(activeTab.url, activeTab.title).then(result => {
                            const { environment, confidence, method, source } = result;
                            
                            if (environment) {
                                log(`Re-detected environment: ${environment} (confidence: ${confidence}, method: ${method})`);
                                
                                // Update values
                                currentEnvironment = environment;
                                lastDetectionMethod = method;
                                lastDetectionSource = source;
                                lastDetectionTime = new Date().toISOString();
                                
                                // Store detected environment
                                chrome.storage.sync.set({ 
                                    environmentType: environment,
                                    detectionMethod: method,
                                    detectionSource: source,
                                    lastUpdated: lastDetectionTime
                                }, function() {
                                    sendResponse({ 
                                        success: true,
                                        environment: environment,
                                        detectionMethod: method,
                                        detectionSource: source,
                                        lastUpdated: lastDetectionTime
                                    });
                                    
                                    // Notify current tab
                                    notifyTab(activeTab.id, environment);
                                });
                            } else {
                                sendResponse({ 
                                    success: true,
                                    environment: 'unknown',
                                    detectionMethod: 'refresh',
                                    detectionSource: 'user',
                                    lastUpdated: new Date().toISOString()
                                });
                            }
                        });
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

// Directly fetch organization information from Genesys Cloud API
async function fetchOrganizationInfoDirectly(tabId) {
    log('Attempting direct API access for organization info');
    
    try {
        // Try multiple endpoints to find organization ID
        const endpoints = [
            'https://api.cac1.pure.cloud/api/v2/organizations/me',
            'https://apps.cac1.pure.cloud/api/v1/org?fl=*',
            'https://api.usw2.pure.cloud/api/v2/organizations/me',
            'https://api.use2.pure.cloud/api/v2/organizations/me'
        ];
        
        for (const endpoint of endpoints) {
            try {
                log('Fetching from endpoint:', endpoint);
                
                // Execute a content script to make the fetch request in the tab's context
                // This way we inherit the tab's authentication
                const fetchResult = await chrome.scripting.executeScript({
                    target: { tabId: tabId },
                    func: async (endpoint) => {
                        try {
                            const response = await fetch(endpoint, {
                                credentials: 'include', // Include cookies for auth
                                headers: {
                                    'Accept': 'application/json'
                                }
                            });
                            
                            if (!response.ok) {
                                return { error: `API returned ${response.status}` };
                            }
                            
                            const data = await response.json();
                            return { success: true, data: data };
                        } catch (error) {
                            return { error: error.toString() };
                        }
                    },
                    args: [endpoint]
                });
                
                // Process the result
                if (fetchResult && fetchResult[0] && fetchResult[0].result) {
                    const result = fetchResult[0].result;
                    
                    if (result.success && result.data) {
                        const data = result.data;
                        
                        // Extract organization ID from response
                        let orgId = null;
                        
                        if (data.id) {
                            orgId = data.id;
                        } else if (data.guid) {
                            orgId = data.guid;
                        } else if (data.res && data.res.guid) {
                            orgId = data.res.guid;
                        } else if (data.organization && data.organization.id) {
                            orgId = data.organization.id;
                        }
                        
                        if (orgId) {
                            log('Found organization ID via direct API:', orgId);
                            // Set the org ID
                            setOrganizationId(orgId, `direct-api:${endpoint}`);
                            return { orgId: orgId, source: endpoint };
                        }
                    }
                }
            } catch (endpointError) {
                log('Error with endpoint', endpoint, ':', endpointError);
                // Continue to next endpoint
            }
        }
        
        return { error: 'No organization ID found in API responses' };
    } catch (error) {
        log('Error in direct API organization fetch:', error);
        return { error: error.toString() };
    }
} 