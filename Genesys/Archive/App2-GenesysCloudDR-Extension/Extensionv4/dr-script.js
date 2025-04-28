// Content script for Genesys Cloud environment detection and badge display
// Handles environment detection and UI modifications

// Environment configuration
const ENVIRONMENTS = {
    dr: {
        name: "DR",
        color: "#ff0000", // Red
        textColor: "#ffffff",
        description: "Disaster Recovery Environment"
    },
    test: {
        name: "TEST",
        color: "#d4a017", // Muted/darker yellow (amber)
        textColor: "#000000",
        description: "Test Environment"
    },
    dev: {
        name: "DEV",
        color: "#0066cc", // Blue
        textColor: "#ffffff",
        description: "Development Environment"
    },
    unknown: {
        name: "Unknown",
        color: "#808080", // Gray
        textColor: "#ffffff",
        description: "Environment Not Detected"
    }
};

// Content-based detection patterns by environment
const CONTENT_PATTERNS = {
    dr: [
        'disaster recovery', 
        'dr environment', 
        'dr site', 
        'dr region',
        'wawanesa-dr',
        'failover',
        'recovery',
        'dr instance'
    ],
    test: [
        'test environment', 
        'test site', 
        'test region', 
        'wawanesa-test',
        'uat environment',
        'staging environment',
        'qa environment',
        'testing',
        'test-region'
    ],
    dev: [
        'dev environment', 
        'development', 
        'wawanesa-dev',
        'sandbox',
        'local environment',
        'dev-region'
    ]
};

// Known HTML element patterns that indicate environments
const ELEMENT_PATTERNS = {
    dr: ['dr-environment', 'disaster-recovery', 'dr-badge', 'dr-banner', 'dr-indicator'],
    test: ['test-environment', 'test-badge', 'test-banner', 'test-indicator', 'uat-indicator', 'qa-indicator'],
    dev: ['dev-environment', 'dev-badge', 'dev-banner', 'dev-indicator', 'development-indicator']
};

// Words to exclude for more accurate detection (false positives)
const EXCLUDE_WORDS = {
    dr: ['drive', 'directory', 'drop', 'drawer', 'address'],
    test: ['latest', 'greatest', 'testament', 'testimony', 'protest', 'attestation', 'contest', 'intestate'],
    dev: ['device', 'deviated', 'devote']
};

// Detection method confidence levels (matching background.js)
const DETECTION_METHODS = {
    ORG_ID: { confidence: 0.95, name: "Organization ID" },
    HOSTNAME: { confidence: 0.95, name: "Hostname" },
    API_ENDPOINT: { confidence: 0.90, name: "API Endpoint" },
    URL_PATTERN: { confidence: 0.85, name: "URL Pattern" },
    TITLE_PATTERN: { confidence: 0.80, name: "Page Title" },
    HTML_ELEMENT: { confidence: 0.85, name: "HTML Element" },
    PAGE_CONTENT: { confidence: 0.70, name: "Page Content" },
    DEFAULT: { confidence: 0.50, name: "Default" }
};

// Known hostnames mapped to environments (matching background.js)
const HOSTNAME_MAPPINGS = {
    // Test environments
    "cac1.pure.cloud": "test",
    "usw2.pure.cloud": "test",
    "use2.pure.cloud": "test",
    "fra.pure.cloud": "test",
    "login.mypurecloud.ca": "test",
    
    // DEV environments
    "use1.dev.us-east-1.aws.dev.genesys.cloud": "dev",
    "dev.genesys.cloud": "dev",
    
    // DR patterns in hostnames
    "dr.mypurecloud.com": "dr",
    "dr-api.mypurecloud.com": "dr"
};

// Enable logging
const DEBUG = true;

// Logging function
function log(...args) {
    if (DEBUG) {
        console.log('[Environment Extension]', ...args);
    }
}

// Safe storage set helper function
function safeStorageSet(data) {
    try {
        if (chrome.storage && chrome.storage.sync) {
            chrome.storage.sync.set(data, function() {
                if (chrome.runtime.lastError) {
                    log('Error saving to storage:', chrome.runtime.lastError);
                } else {
                    log('Data saved to storage successfully');
                }
            });
        } else {
            log('Chrome storage API not available for saving data');
        }
    } catch (error) {
        log('Error accessing chrome.storage.sync:', error);
    }
}

// Initialization
let currentEnvironment = null;
let badgeElement = null;
let lastDetectionMethod = null;
let lastDetectionSource = null;
log('Content script loaded');

// Initialize detection when DOM is ready
if (document.readyState === 'interactive' || document.readyState === 'complete') {
    log('Document already ready, initializing now');
    initializeDetection();
} else {
    log('Document not ready, waiting for DOMContentLoaded');
    document.addEventListener('DOMContentLoaded', function() {
        log('DOMContentLoaded fired, initializing');
        initializeDetection();
    });
}

// Listen for messages from background script
chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
    if (message.action === 'environmentChange') {
        log('Received environment change:', message.environment, 'Org ID:', message.orgId || 'Not Provided');
        
        // Update badge with new environment
        updateEnvironmentBadge(message.environment);
        
        // If org ID provided by background, store it
        if (message.orgId) {
            log('Storing organization ID from background:', message.orgId);
            safeStorageSet({ detectedOrgId: message.orgId });
        }
        
        // Acknowledge receipt
        sendResponse({ success: true });
    }
    
    // Handle request to extract org ID from the page
    if (message.action === 'extractOrgIdFromPage') {
        log('Request to extract org ID from page:', message.source);
        extractOrganizationIdFromPageData(message.source);
        sendResponse({ success: true });
    }
});

// Initialize environment detection
function initializeDetection() {
    log('Initializing environment detection');

    // Set up initial environment values
    chrome.storage.sync.get(['environmentType'], function(result) {
        if (result.environmentType) {
            log('Loaded environment type from storage:', result.environmentType);
            updateEnvironmentBadge(result.environmentType);
        }
    });
    
    // Set up message listener to handle environment change notifications
    chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
        log('Content script received message:', request);
        
        if (request.action === 'environmentChanged') {
            log('Environment changed to:', request.environmentType);
            updateEnvironmentBadge(request.environmentType);
        }
        else if (request.action === 'extractOrganizationId') {
            log('Extracting organization ID from page via message');
            // Call the correctly named function
            extractOrganizationIdFromPageData('message-listener'); 
        }
    });
    
    // Start detection methods
    // *** Problem Area 2: Direct call during initialization ***
    // Call the correctly named function
    log('Initial attempt to extract organization ID from page data');
    extractOrganizationIdFromPageData('initialize'); 
    setupDetectionInterval();
    searchForWawanesaTestText(); // New method to search specifically for Wawanesa-Test
    
    // *** ADDED: Start polling for Org ID in JS Context ***
    pollForOrgIdInJSContext();

    // Try fallback detection after a delay - Function not defined
    // log('Scheduling fallback detection');
    // setTimeout(fallbackDetection, 5000); 
}

// Function to search for "Wawanesa-Test" in page content
function searchForWawanesaTestText() {
    log('METHOD 12: Searching for Wawanesa-Test text in page');

    // Define the target text patterns
    const patterns = [
        /wawanesa[-\s]?test/i,
        /wawanesa test/i,
        /wawanesatest/i,
        /wawanesa[-\s]?qa[-\s]?test/i,
        /wt-/i
    ];

    // Define org ID regex pattern
    const orgIdPattern = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i;
    const targetOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';

    // Function to check if text is within range of org ID
    function checkProximityForOrgId(text, match, proximity = 200) {
        // Get a substring around the match to check for org IDs
        const startIndex = Math.max(0, text.indexOf(match) - proximity);
        const endIndex = Math.min(text.length, text.indexOf(match) + match.length + proximity);
        const contextText = text.substring(startIndex, endIndex);

        // Look for organization ID in the context text
        const orgIdMatch = contextText.match(orgIdPattern);
        if (orgIdMatch) {
            log(`METHOD 12: Found potential org ID near "Wawanesa-Test": ${orgIdMatch[0]}`);

            // If it's our target ID
            if (orgIdMatch[0] === targetOrgId) {
                log('✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID!');
                sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-proximity');
                updateEnvironmentBadge('test');
                return true;
            } else {
                sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-proximity-unconfirmed');
            }
        }
        return false;
    }

    // Check page source (outerHTML)
    const pageSource = document.documentElement.outerHTML;
    for (const pattern of patterns) {
        const matches = pageSource.match(pattern);
        if (matches) {
            log(`METHOD 12: Found "${matches[0]}" in page source`);
            if (checkProximityForOrgId(pageSource, matches[0])) {
                return; // Found the target ID, stop searching
            }
        }
    }

    // Direct DOM Search (replaces injected script logic)
    log('METHOD 12: Starting deep search for Wawanesa-Test text directly in DOM');

    function searchNode(node) {
        // Skip script tags and style tags
        if (node.nodeName === 'SCRIPT' || node.nodeName === 'STYLE') {
            return false;
        }

        // Check text nodes
        if (node.nodeType === Node.TEXT_NODE) {
            const text = node.textContent;
            for (const pattern of patterns) {
                if (pattern.test(text)) {
                    log(`METHOD 12: Found "${text.match(pattern)[0]}" in text node: ${text.trim().substring(0, 50)}`);
                    const orgIdMatch = text.match(orgIdPattern);
                    if (orgIdMatch) {
                        log(`METHOD 12: Found potential org ID: ${orgIdMatch[0]} in text node`);
                        if (orgIdMatch[0] === targetOrgId) {
                            log('✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID in text node!');
                            sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-text-node');
                            updateEnvironmentBadge('test');
                            return true; // Found target
                        } else {
                            sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-text-node-unconfirmed');
                        }
                    }
                }
            }
            // *** ADDED: Direct check for Target Org ID in text nodes ***
            if (text.includes(targetOrgId)) {
                 log(`✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID directly in text node: ${text.trim().substring(0, 50)}`);
                 sendOrganizationIdToBackground(targetOrgId, 'wawanesa-text-text-node-direct');
                 updateEnvironmentBadge('test');
                 return true; // Found target
            }
            // *** END ADDED ***
        }

        // Check element attributes
        if (node.nodeType === Node.ELEMENT_NODE) {
            for (const attr of node.attributes) {
                const text = attr.value;

                // *** ADDED: Direct check for Target Org ID in attributes ***
                if (text.includes(targetOrgId)) {
                    log(`✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID directly in attribute ${attr.name}!`);
                    sendOrganizationIdToBackground(targetOrgId, 'wawanesa-text-attribute-direct');
                    updateEnvironmentBadge('test');
                    return true; // Found target
                }
                // *** END ADDED ***

                for (const pattern of patterns) {
                    if (pattern.test(text)) {
                        log(`METHOD 12: Found "${text.match(pattern)[0]}" in attribute ${attr.name}: ${text.substring(0, 50)}`);
                        const orgIdMatch = text.match(orgIdPattern);
                        if (orgIdMatch) {
                            log(`METHOD 12: Found potential org ID: ${orgIdMatch[0]} in attribute`);
                            if (orgIdMatch[0] === targetOrgId) {
                                log('✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID in attribute!');
                                sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-attribute');
                                updateEnvironmentBadge('test');
                                return true; // Found target
                            } else {
                                sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-attribute-unconfirmed');
                            }
                        }
                    }
                }
            }

            // Check shadow DOM (if it exists)
            if (node.shadowRoot) {
                log('METHOD 12: Searching shadow DOM');
                if (searchAllChildren(node.shadowRoot)) {
                    return true; // Found target in shadow DOM
                }
            }
        }

        // Search children recursively
        if (node.childNodes) {
            if (searchAllChildren(node)) {
                return true; // Found target in children
            }
        }
        return false;
    }

    function searchAllChildren(node) {
        for (const child of node.childNodes) {
            if (searchNode(child)) {
                return true; // Found target in this branch
            }
        }
        return false;
    }

    // Start DOM search
    if (searchNode(document.documentElement)) {
        return; // Stop if found in DOM
    }

    // Check JavaScript context (window variables)
    log('METHOD 12: Checking JavaScript context for Wawanesa-Test text');
    try {
        const windowVars = Object.keys(window);
        for (const varName of windowVars) {
            try {
                if (typeof window[varName] === 'string') {
                    const varValue = window[varName];
                    for (const pattern of patterns) {
                        if (pattern.test(varValue)) {
                            log(`METHOD 12: Found "${varValue.match(pattern)[0]}" in window.${varName}`);
                            const orgIdMatch = varValue.match(orgIdPattern);
                            if (orgIdMatch) {
                                log(`METHOD 12: Found potential org ID: ${orgIdMatch[0]} in JS variable`);
                                if (orgIdMatch[0] === targetOrgId) {
                                    log('✓ METHOD 12 SUCCESS: Found Wawanesa-Test org ID in JS variable!');
                                    sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-js-variable');
                                    updateEnvironmentBadge('test');
                                    return; // Found target
                                } else {
                                    sendOrganizationIdToBackground(orgIdMatch[0], 'wawanesa-text-js-variable-unconfirmed');
                                }
                            }
                        }
                    }
                }
            } catch (e) {
                // Ignore access errors (e.g., security restrictions)
            }
        }
    } catch (e) {
        log('METHOD 12: Error searching JavaScript context:', e.message);
    }

    log('METHOD 12: Completed search for Wawanesa-Test text');
}

// *** ADDED: Polling function for JS Context ***
function pollForOrgIdInJSContext(attemptsLeft = 10, interval = 1000) {
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    log(`Polling for Org ID in JS Context (Attempts left: ${attemptsLeft})`);

    const pathsToCheck = [
        // Previous paths
        'window.PC',
        'window.PCApp',
        'window.purecloud',
        'window.genesys',
        'window.pureCloudSession',
        'window.organization',
        'window.PURECLOUD',
        'window.PURECLOUDAPP',
        'window.APP',
        'window.__INITIAL_STATE__',
        'window.appConfig',
        'window.PC_APP',
        'window.PureCloud',
        'window.Genesys',
        // More specific SDK/Config paths
        'window.purecloud.apps.sdk',
        'window.purecloud.apps.config',
        'window.purecloud.config',
        'window.purecloud.session',
        'window.genesys.sdk',
        'window.genesys.config',
        'window.genesys.session',
        'window.genesysPlatform.sdk',
        'window.genesysPlatform.config',
        'window.genesysPlatform.client',
        'window.gux', // Genesys UI framework, might hold config
        'window.GenesysCloudWebrtcSdk' // Specific SDK name
    ];

    let found = false;

    for (const path of pathsToCheck) {
        try {
            const parts = path.split('.');
            let obj = window;
            for (let i = 1; i < parts.length; i++) {
                if (obj && typeof obj === 'object' && obj !== null && parts[i] in obj) {
                     obj = obj[parts[i]];
                } else {
                     obj = null;
                     break;
                }
            }

            if (obj) {
                log(`Polling: Checking path ${path}`);
                // Check direct properties
                if (obj.id === testOrgId || obj.guid === testOrgId || obj.orgId === testOrgId || obj.organizationId === testOrgId) {
                    log(`✓ POLLING SUCCESS: Found Org ID directly in ${path}`);
                    sendOrganizationIdToBackground(testOrgId, `poll-js-${path.replace('window.','')}-direct`);
                    updateEnvironmentBadge('test');
                    found = true;
                    break;
                }

                // Check common nested structures based on console logs
                const potentialSubPaths = ['organization', 'org', 'config', 'session', 'details', 'settings'];
                for (const sub of potentialSubPaths) {
                    if (obj[sub] && typeof obj[sub] === 'object') {
                        if (obj[sub].id === testOrgId || obj[sub].guid === testOrgId || obj[sub].orgId === testOrgId) {
                            log(`✓ POLLING SUCCESS: Found Org ID in ${path}.${sub}.id/guid/orgId`);
                            sendOrganizationIdToBackground(testOrgId, `poll-js-${path.replace('window.','')}-${sub}`);
                            updateEnvironmentBadge('test');
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;

                // Check stringified version as a fallback
                let objString = '';
                try {
                    // Limit stringify depth/length to prevent performance issues
                    objString = JSON.stringify(obj, (key, value) => {
                        // Basic circular reference handler and depth limit
                        if (typeof value === 'object' && value !== null) {
                            if (key === 'parentNode' || key === 'ownerElement') return '[DOM]'; // Avoid DOM cycles
                            // Add more complex cycle detection if needed
                        }
                        return value;
                    }); // Consider adding a depth limit if complex objects cause issues
                } catch (e) { 
                    // log(`Polling: Could not stringify ${path}: ${e.message}`);
                    /* Ignore stringify errors */ 
                }

                if (objString && objString.includes(testOrgId)) {
                     log(`✓ POLLING SUCCESS: Found Org ID by stringifying ${path}`);
                     sendOrganizationIdToBackground(testOrgId, `poll-js-${path.replace('window.','')}-stringify`);
                     updateEnvironmentBadge('test');
                     found = true;
                     break;
                 }
            }
        } catch (e) {
            // log(`Polling: Error accessing path ${path}: ${e.message}`);
            // Ignore errors accessing paths
        }
    }

    if (!found && attemptsLeft > 0) {
        setTimeout(() => pollForOrgIdInJSContext(attemptsLeft - 1, interval), interval);
    } else if (found) {
        log('Polling stopped: Org ID found.');
    } else {
        log('Polling finished: Org ID not found in JS context.');
    }
}
// *** END ADDED ***

// METHOD 1: Direct search for the Wawanesa-Test org ID
function searchDirectlyForWawanesaTestOrgId() {
    log('METHOD 1: Direct page search for Wawanesa-Test org ID');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Search the entire page HTML
        const pageHtml = document.documentElement.outerHTML;
        if (pageHtml.includes(testOrgId)) {
            log('✓ METHOD 1 SUCCESS: Found Wawanesa-Test org ID in page HTML!');
            sendOrganizationIdToBackground(testOrgId, 'direct-page-search');
            return true;
        }
        
        // Search all text nodes in the DOM
        const textNodes = [];
        const walker = document.createTreeWalker(
            document.body, 
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        let node;
        while(node = walker.nextNode()) {
            if (node.nodeValue.includes(testOrgId)) {
                log('✓ METHOD 1 SUCCESS: Found Wawanesa-Test org ID in text node!');
                sendOrganizationIdToBackground(testOrgId, 'text-node-search');
                return true;
            }
        }
        
        // Search all attributes
        const allElements = document.getElementsByTagName('*');
        for (let i = 0; i < allElements.length; i++) {
            const el = allElements[i];
            const attributes = el.attributes;
            
            for (let j = 0; j < attributes.length; j++) {
                if (attributes[j].value.includes(testOrgId)) {
                    log('✓ METHOD 1 SUCCESS: Found Wawanesa-Test org ID in element attribute!', 
                        el.tagName, attributes[j].name);
                    sendOrganizationIdToBackground(testOrgId, 'attribute-search');
                    return true;
                }
            }
        }
        
        log('METHOD 1: Direct search did not find the org ID');
        return false;
    } catch (error) {
        log('METHOD 1: Error in direct search:', error);
        return false;
    }
}

// Detect environment from content (URL, document content, HTML structure)
async function detectEnvironmentFromContent() {
    // Default result
    let bestResult = { 
        environment: 'unknown', 
        confidence: DETECTION_METHODS.DEFAULT.confidence, 
        method: DETECTION_METHODS.DEFAULT.name,
        source: 'content-script'
    };
    
    try {
        // Get current URL
        const url = window.location.href.toLowerCase();
        const hostname = window.location.hostname;
        const path = window.location.pathname;
        const fragment = window.location.hash;
        const fullUrlText = `${hostname}${path}${window.location.search}${fragment}`;
        
        log('Analyzing URL:', url);
        
        // 1. Check for hostname-based patterns
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
        
        // 2. Check for API endpoints
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
        
        // 3. Extract organization ID from URL if present
        const orgIdMatch = url.match(/org(?:anization)?[=\/]([a-f0-9-]{36})/i);
        if (orgIdMatch && orgIdMatch[1]) {
            const orgId = orgIdMatch[1];
            log('Found organization ID in URL:', orgId);
            
            // Send to background script to check against known mappings
            return new Promise((resolve) => {
                chrome.runtime.sendMessage({ 
                    action: 'getEnvironmentInfo',
                    checkOrgId: orgId
                }, function(response) {
                    if (response && response.environment && response.environment !== 'unknown') {
                        log(`Background mapped organization ID to environment: ${response.environment}`);
                        resolve({ 
                            environment: response.environment, 
                            confidence: DETECTION_METHODS.ORG_ID.confidence, 
                            method: DETECTION_METHODS.ORG_ID.name,
                            source: orgId
                        });
                    } else {
                        // Continue with detection
                        resolve(bestResult);
                    }
                });
            });
        }
        
        // 4. Check URL for explicit patterns
        // DR environment patterns
        const hasDrExcludeWord = EXCLUDE_WORDS.dr.some(word => fullUrlText.includes(word));
        
        if (!hasDrExcludeWord) {
            // Special case for DR login URLs
            if (hostname.includes('login') && fullUrlText.includes('wawanesa-dr')) {
                log('Found DR login URL with organization name');
                bestResult = { 
                    environment: 'dr', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: 'login-wawanesa-dr'
                };
            }
            
            // Check all DR patterns
            for (const pattern of CONTENT_PATTERNS.dr) {
                if (url.includes(pattern)) {
                    log(`DR pattern match in URL: ${pattern}`);
                    const result = { 
                        environment: 'dr', 
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`
                    };
                    if (result.confidence > bestResult.confidence) {
                        bestResult = result;
                    }
                }
            }
        }
        
        // Test environment patterns
        const hasTestExcludeWord = EXCLUDE_WORDS.test.some(word => fullUrlText.includes(word));
        
        if (!hasTestExcludeWord) {
            // Special case for test login URLs
            if (hostname.includes('login') && fullUrlText.includes('wawanesa-test')) {
                log('Found Test login URL with organization name');
                bestResult = { 
                    environment: 'test', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: 'login-wawanesa-test'
                };
            }
            
            // Check all test patterns
            for (const pattern of CONTENT_PATTERNS.test) {
                if (url.includes(pattern)) {
                    log(`Test pattern match in URL: ${pattern}`);
                    const result = { 
                        environment: 'test', 
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`
                    };
                    if (result.confidence > bestResult.confidence) {
                        bestResult = result;
                    }
                }
            }
        }
        
        // Dev environment patterns
        for (const pattern of CONTENT_PATTERNS.dev) {
            if (url.includes(pattern)) {
                log(`Dev pattern match in URL: ${pattern}`);
                const result = { 
                    environment: 'dev', 
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence, 
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: `url-pattern:${pattern}`
                };
                if (result.confidence > bestResult.confidence) {
                    bestResult = result;
                }
            }
        }
        
        // 5. Check page title
        const title = document.title.toLowerCase();
        for (const env of Object.keys(CONTENT_PATTERNS)) {
            // Skip if we already have high confidence
            if (bestResult.confidence >= DETECTION_METHODS.URL_PATTERN.confidence) break;
            
            // Check for environment-specific patterns in title
            for (const pattern of CONTENT_PATTERNS[env]) {
                if (title.includes(pattern)) {
                    log(`${env.toUpperCase()} pattern match in title: ${pattern}`);
                    const result = { 
                        environment: env, 
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence, 
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `title-pattern:${pattern}`
                    };
                    if (result.confidence > bestResult.confidence) {
                        bestResult = result;
                    }
                    break;
                }
            }
        }
        
        // 6. Check for HTML element patterns
        for (const [env, patterns] of Object.entries(ELEMENT_PATTERNS)) {
            // Skip if we already have high confidence
            if (bestResult.confidence >= DETECTION_METHODS.URL_PATTERN.confidence) break;
            
            for (const pattern of patterns) {
                const elements = document.querySelectorAll(`[id*="${pattern}"], [class*="${pattern}"], [data-*="${pattern}"]`);
                if (elements.length > 0) {
                    log(`${env.toUpperCase()} HTML element pattern found: ${pattern}`);
                    const result = { 
                        environment: env, 
                        confidence: DETECTION_METHODS.HTML_ELEMENT.confidence, 
                        method: DETECTION_METHODS.HTML_ELEMENT.name,
                        source: `html-element:${pattern}`
                    };
                    if (result.confidence > bestResult.confidence) {
                        bestResult = result;
                    }
                    break;
                }
            }
        }
        
        // 7. Check page content for environment indicators (when confidence is still low)
        if (bestResult.confidence < DETECTION_METHODS.HTML_ELEMENT.confidence) {
            const bodyText = document.body ? document.body.innerText.toLowerCase() : '';
            
            for (const [env, patterns] of Object.entries(CONTENT_PATTERNS)) {
                for (const pattern of patterns) {
                    if (bodyText.includes(pattern)) {
                        log(`${env.toUpperCase()} content pattern found: ${pattern}`);
                        const result = { 
                            environment: env, 
                            confidence: DETECTION_METHODS.PAGE_CONTENT.confidence, 
                            method: DETECTION_METHODS.PAGE_CONTENT.name,
                            source: `page-content:${pattern}`
                        };
                        if (result.confidence > bestResult.confidence) {
                            bestResult = result;
                        }
                        break;
                    }
                }
            }
        }
        
        // 8. Look for organization ID in page metadata or visible elements
        const orgIdElements = document.querySelectorAll('[data-org-id], [data-organization-id]');
        if (orgIdElements.length > 0) {
            const orgIdElement = orgIdElements[0];
            const orgId = orgIdElement.getAttribute('data-org-id') || orgIdElement.getAttribute('data-organization-id');
            
            if (orgId) {
                log('Found organization ID in page:', orgId);
                
                // Send to background script to check against known mappings
                return new Promise((resolve) => {
                    chrome.runtime.sendMessage({ 
                        action: 'getEnvironmentInfo',
                        checkOrgId: orgId
                    }, function(response) {
                        if (response && response.environment && response.environment !== 'unknown') {
                            log(`Background mapped organization ID to environment: ${response.environment}`);
                            resolve({ 
                                environment: response.environment, 
                                confidence: DETECTION_METHODS.ORG_ID.confidence, 
                                method: DETECTION_METHODS.ORG_ID.name,
                                source: `element-org-id:${orgId}`
                            });
                        } else {
                            // Return the best result we found
                            resolve(bestResult);
                        }
                    });
                });
            }
        }
        
        log('Detection result:', bestResult);
        return bestResult;
        
    } catch (error) {
        log('Error detecting environment from content:', error);
        return { 
            environment: 'unknown', 
            confidence: 0.3, 
            method: 'error',
            source: error.message
        };
    }
}

// Create environment badge element
function createEnvironmentBadge() {
    // Check if badge already exists
    if (badgeElement) return;
    
    try {
        // Create badge container
        badgeElement = document.createElement('div');
        badgeElement.id = 'dr-environment-badge';
        badgeElement.style.position = 'fixed';
        badgeElement.style.top = '0';
        badgeElement.style.left = '50%';
        badgeElement.style.transform = 'translateX(-50%)'; // Center horizontally
        badgeElement.style.zIndex = '9999';
        badgeElement.style.padding = '5px 10px';
        badgeElement.style.fontFamily = 'Arial, sans-serif';
        badgeElement.style.fontWeight = 'bold';
        badgeElement.style.fontSize = '14px';
        badgeElement.style.borderBottomLeftRadius = '5px';
        badgeElement.style.borderBottomRightRadius = '5px';
        badgeElement.style.cursor = 'default';
        
        // Add tooltip with more information
        badgeElement.title = 'Environment Detection Extension';
        
        // Add badge to page - ensure body exists
        if (document.body) {
            document.body.appendChild(badgeElement);
            log('Badge created and added to DOM');
        } else {
            // If body doesn't exist yet, wait for it
            log('Document body not ready, setting up MutationObserver');
            // Set up a MutationObserver to wait for the body
            const observer = new MutationObserver(function(mutations) {
                if (document.body) {
                    document.body.appendChild(badgeElement);
                    log('Badge added to DOM after body became available');
                    observer.disconnect();
                }
            });
            
            observer.observe(document.documentElement, { childList: true, subtree: true });
        }
    } catch (error) {
        log('Error creating badge:', error);
    }
}

// Update environment badge based on detected environment
function updateEnvironmentBadge(environmentType) {
    if (!badgeElement) {
        createEnvironmentBadge();
    }
    
    try {
        const env = ENVIRONMENTS[environmentType] || ENVIRONMENTS.unknown;
        
        // Log the environment type and color being applied
        log(`Updating badge for environment: ${environmentType}, color: ${env.color}`);
        
        // Update badge appearance
        badgeElement.style.backgroundColor = env.color;
        badgeElement.style.color = env.textColor;
        badgeElement.textContent = env.name;
        badgeElement.title = env.description;
        
        // Ensure the badge is visible
        badgeElement.style.display = 'block';
        badgeElement.style.visibility = 'visible';
        badgeElement.style.opacity = '1';
        
        // Force the color to apply by temporarily removing and re-adding
        if (document.body.contains(badgeElement)) {
            document.body.removeChild(badgeElement);
            document.body.appendChild(badgeElement);
        }
        
        // Update current environment
        currentEnvironment = environmentType;
        
        log(`Badge updated to ${environmentType}`);
    } catch (error) {
        log('Error updating badge:', error);
    }
}

// Periodically check for URL changes or dynamic content changes
let lastUrl = window.location.href;
setInterval(function() {
    const currentUrl = window.location.href;
    
    // Check if URL changed
    if (currentUrl !== lastUrl) {
        log('URL changed:', currentUrl);
        lastUrl = currentUrl;
        
        // Re-detect environment, but with a slight delay to allow page to load
        setTimeout(function() {
            // First ask background script for current environment
            try {
                chrome.runtime.sendMessage({ action: 'getEnvironmentInfo' }, function(response) {
                    if (chrome.runtime.lastError) {
                        log('Error communicating with background script:', chrome.runtime.lastError);
                        fallbackToContentDetection();
                        return;
                    }
                    
                    if (response && response.environment && response.environment !== 'unknown') {
                        log(`Background already knows environment: ${response.environment}`);
                        
                        // Update badge
                        updateEnvironmentBadge(response.environment);
                        currentEnvironment = response.environment;
                    } else {
                        fallbackToContentDetection();
                    }
                });
            } catch (error) {
                log('Error sending message to background:', error);
                fallbackToContentDetection();
            }
            
            function fallbackToContentDetection() {
                log('Falling back to content-based detection');
                
                // Ensure the badge is created
                createEnvironmentBadge();
                
                // Detect environment from content as fallback
                detectEnvironmentFromContent().then(result => {
                    if (result.environment && result.environment !== 'unknown') {
                        log(`Detected environment from content: ${result.environment} (confidence: ${result.confidence}, method: ${result.method})`);
                        
                        // Update environment badge
                        updateEnvironmentBadge(result.environment);
                        
                        // Store detected environment
                        safeStorageSet({ 
                            environmentType: result.environment,
                            detectionMethod: result.method,
                            detectionSource: result.source || window.location.hostname,
                            lastUpdated: new Date().toISOString()
                        });
                        
                        // Notify background script about detected environment
                        try {
                            chrome.runtime.sendMessage({ 
                                action: 'setEnvironmentType',
                                environmentType: result.environment
                            });
                        } catch (error) {
                            log('Error sending message to background:', error);
                        }
                        
                        currentEnvironment = result.environment;
                    } else {
                        log('Could not detect environment from content');
                        updateEnvironmentBadge('unknown');
                    }
                }).catch(error => {
                    log('Error in content detection:', error);
                    updateEnvironmentBadge('unknown');
                });
            }
        }, 1000);
        
        // Also try our direct methods
        setTimeout(() => {
            log('Running periodic checks (Methods 1, 2, 5, 6, 9)');
            searchDirectlyForWawanesaTestOrgId();
            monitorConsoleObjectsForOrgId();
            // injectDirectCodeToFindOrgId(); // Removed - Requires injection
            searchShadowDOMForOrgId();
            checkCookiesForOrgId();
            // injectShadowDOMInterception(); // Removed - Requires injection
            
            // METHOD 9: Aggressive response logging - Only runs local checks now
            captureAndLogAllResponses();
        }, 3000);
    }
    
    // Check if badge still exists (might be removed by page scripts)
    if (!document.body.contains(badgeElement)) {
        log('Badge removed, recreating');
        badgeElement = null;
        createEnvironmentBadge();
        
        if (currentEnvironment) {
            updateEnvironmentBadge(currentEnvironment);
        }
    } else {
        // Force check that the correct color is being shown
        if (currentEnvironment === 'test') {
            const testEnv = ENVIRONMENTS.test;
            log('Forcing TEST environment color check:', testEnv.color);
            badgeElement.style.backgroundColor = testEnv.color;
            badgeElement.style.color = testEnv.textColor;
        }
    }
}, 2000);

// Extract organization ID from page data (API responses)
function extractOrganizationIdFromPageData(source) {
    log('Extracting organization ID from page data, source:', source);
    
    try {
        // Method 1: Look for organization ID in global JavaScript variables
        const pageVars = ['org', 'organization', 'orgData', 'orgInfo', 'userSession', 'session'];
        for (const varName of pageVars) {
            try {
                if (window[varName] && window[varName].guid) {
                    const orgId = window[varName].guid;
                    log('Found org ID in global var:', orgId);
                    sendOrganizationIdToBackground(orgId, `global-var:${varName}`);
                    return;
                }
            } catch (e) {
                // Ignore errors when checking window vars
            }
        }
        
        // Method 2: Check for organization ID in meta tags or data attributes
        const metaTags = document.querySelectorAll('meta[name*="org"], meta[name*="organization"], meta[property*="org"], meta[property*="organization"]');
        for (const tag of metaTags) {
            const content = tag.getAttribute('content');
            if (content && content.match(/^[a-f0-9-]{36}$/i)) {
                log('Found org ID in meta tag:', content);
                sendOrganizationIdToBackground(content, 'meta-tag');
                return;
            }
        }
        
        // Method 3: Look for data attributes on HTML elements
        const orgElements = document.querySelectorAll('[data-org-id], [data-organization-id], [data-orgid]');
        if (orgElements.length > 0) {
            for (const el of orgElements) {
                const orgId = el.getAttribute('data-org-id') || 
                             el.getAttribute('data-organization-id') || 
                             el.getAttribute('data-orgid');
                             
                if (orgId && orgId.match(/^[a-f0-9-]{36}$/i)) {
                    log('Found org ID in data attribute:', orgId);
                    sendOrganizationIdToBackground(orgId, 'data-attribute');
                    return;
                }
            }
        }
        
        // Method 4: Check local storage
        try {
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                if (key && (key.includes('org') || key.includes('session'))) {
                    const value = localStorage.getItem(key);
                    const guidMatch = value.match(/"guid"\s*:\s*"([a-f0-9-]{36})"/i);
                    if (guidMatch && guidMatch[1]) {
                        log('Found org ID in localStorage:', guidMatch[1]);
                        sendOrganizationIdToBackground(guidMatch[1], 'local-storage');
                        return;
                    }
                }
            }
        } catch (e) {
            // Silently continue if localStorage access fails
        }
        
        // Method 5: Look through script tags for embedded data
        const scripts = document.querySelectorAll('script:not([src])');
        for (const script of scripts) {
            const content = script.textContent;
            if (content && content.includes('organization') && content.includes('guid')) {
                const guidMatch = content.match(/"guid"\s*:\s*"([a-f0-9-]{36})"/i);
                if (guidMatch && guidMatch[1]) {
                    log('Found org ID in script tag:', guidMatch[1]);
                    sendOrganizationIdToBackground(guidMatch[1], 'script-tag');
                    return;
                }
            }
        }
    } catch (error) {
        log('Error extracting organization ID from page data:', error);
    }
}

// Send detected organization ID to background script
function sendOrganizationIdToBackground(orgId, source) {
    if (!orgId || orgId === 'me') return;
    
    // Validate organization ID format
    if (!orgId.match(/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i)) {
        log('Invalid organization ID format:', orgId);
        return;
    }
    
    // Log the detection with source
    log('Sending organization ID to background:', orgId, 'source:', source);
    
    // Explicit check for TEST environment (Wawanesa-Test organization ID)
    if (orgId === 'd9ee1fd7-868c-4ea0-af89-5b9813db863d') {
        log('✓ DETECTED WAWANESA-TEST ORGANIZATION ID!');
    }
    
    // Send message to background script
    try {
        chrome.runtime.sendMessage({
            action: 'detectedOrganizationId',
            orgId: orgId,
            source: source
        }, response => {
            // Handle response
            if (chrome.runtime.lastError) {
                log('Error in background script response:', chrome.runtime.lastError);
            } else if (response && response.success) {
                log('Background script processed organization ID successfully');
            }
        });
    } catch (error) {
        log('Error sending org ID to background:', error);
        
        // Fallback: Store directly in storage in case message passing failed
        try {
            chrome.storage.sync.set({ 
                detectedOrgId: orgId,
                detectionSource: source,
                lastUpdated: new Date().toISOString()
            }, function() {
                if (chrome.runtime.lastError) {
                    log('Error saving to storage:', chrome.runtime.lastError);
                } else {
                    log('Saved organization ID to storage as fallback');
                }
            });
        } catch (storageError) {
            log('Error accessing storage:', storageError);
        }
    }
}

// METHOD 2: Monitor JavaScript objects in Console/Window for org ID
function monitorConsoleObjectsForOrgId() {
    log('METHOD 2: Searching for org ID in JavaScript objects');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Define potentially interesting object paths
        const objectPaths = [
            'window.PC',
            'window.PCApp',
            'window.purecloud',
            'window.genesys',
            'window.pureCloudSession',
            'window.organization',
            'window.PURECLOUD',
            'window.PURECLOUDAPP',
            'window.APP',
            'window.__INITIAL_STATE__',
            'window.appConfig',
            'window.PC_APP',
            'window.PureCloud',
            'window.Genesys'
        ];
        
        // Function to recursively search an object for the org ID
        function searchObject(obj, path = '', depth = 0) {
            // Limit depth to avoid infinite recursion and stack overflow
            if (depth > 5) return false;
            
            // Skip if not an object or array, or if null
            if (!obj || typeof obj !== 'object') return false;
            
            // Skip DOM nodes to avoid complex circular references
            if (obj.nodeType && obj.nodeName) return false;
            
            try {
                // Convert to string for quick check
                const objStr = JSON.stringify(obj);
                if (objStr && objStr.includes(testOrgId)) {
                    log(`✓ METHOD 2 SUCCESS: Found org ID in object at path ${path}`);
                    sendOrganizationIdToBackground(testOrgId, `js-object:${path}`);
                    return true;
                }
            } catch (e) {
                // Skip objects that can't be stringified (like circular references)
            }
            
            // Search each property
            let found = false;
            try {
                // Get all enumerable properties
                const props = Object.keys(obj);
                
                for (const prop of props) {
                    // Skip properties that look like functions or DOM elements
                    if (typeof obj[prop] === 'function') continue;
                    if (obj[prop] && obj[prop].nodeType && obj[prop].nodeName) continue;
                    
                    // Direct property match
                    if (prop === 'guid' || prop === 'id' || prop === 'orgId' || prop === 'organizationId') {
                        if (obj[prop] === testOrgId) {
                            log(`✓ METHOD 2 SUCCESS: Found org ID directly in property ${path}.${prop}`);
                            sendOrganizationIdToBackground(testOrgId, `js-property:${path}.${prop}`);
                            return true;
                        }
                    }
                    
                    // Check if value contains the ID as a string
                    if (typeof obj[prop] === 'string' && obj[prop].includes(testOrgId)) {
                        log(`✓ METHOD 2 SUCCESS: Found org ID in string value at ${path}.${prop}`);
                        sendOrganizationIdToBackground(testOrgId, `js-string:${path}.${prop}`);
                        return true;
                    }
                    
                    // Recursively search deeper
                    const newPath = path ? `${path}.${prop}` : prop;
                    found = found || searchObject(obj[prop], newPath, depth + 1);
                    if (found) return true;
                }
            } catch (e) {
                // Skip errors accessing properties
            }
            
            return found;
        }
        
        // Try each path
        for (const path of objectPaths) {
            try {
                // Evaluate the path string to get the actual object
                const parts = path.split('.');
                let obj = window;
                
                for (const part of parts) {
                    if (obj && obj[part]) {
                        obj = obj[part];
                    } else {
                        obj = null;
                        break;
                    }
                }
                
                if (obj) {
                    log(`Searching object at path: ${path}`);
                    if (searchObject(obj, path)) {
                        return true;
                    }
                }
            } catch (e) {
                // Skip errors and continue to next path
            }
        }
        
        // Additional targeted search for window.purecloud objects
        try {
            if (window.purecloud && window.purecloud.apps) {
                log('Searching purecloud.apps...');
                searchObject(window.purecloud.apps, 'purecloud.apps');
            }
        } catch (e) {
            // Skip errors
        }
        
        log('METHOD 2: No org ID found in JavaScript objects');
        return false;
    } catch (error) {
        log('METHOD 2: Error searching JavaScript objects:', error);
        return false;
    }
}

// METHOD 3: Intercept all network responses with more aggressive pattern matching
function interceptAllNetworkResponses() {
    log('METHOD 3: Setting up aggressive network response monitoring');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Override fetch for all requests
        const originalFetch = window.fetch;
        window.fetch = function() {
            const url = arguments[0];
            const request = arguments[0] instanceof Request ? arguments[0] : null;
            const fetchUrl = request ? request.url : url;
            
            // Don't filter by URL - monitor all responses
            log('METHOD 3: Monitoring ALL fetch responses for:', fetchUrl);
            
            return originalFetch.apply(this, arguments)
                .then(response => {
                    // Clone the response to avoid consuming it
                    const clonedResponse = response.clone();
                    
                    // Process the response as text
                    clonedResponse.text().then(text => {
                        try {
                            if (text.includes(testOrgId)) {
                                log(`✓ METHOD 3 SUCCESS: Found org ID in fetch response from ${fetchUrl}`);
                                sendOrganizationIdToBackground(testOrgId, 'aggressive-fetch-monitor');
                            }
                        } catch (e) {
                            log('METHOD 3: Error processing fetch response:', e);
                        }
                    }).catch(error => {
                        log('METHOD 3: Error getting response text:', error);
                    });
                    
                    return response;
                });
        };
        
        // Add a MutationObserver to continuously scan for new content
        const observer = new MutationObserver((mutations) => {
            for (const mutation of mutations) {
                // Look for added nodes that might contain our ID
                if (mutation.addedNodes && mutation.addedNodes.length) {
                    for (const node of mutation.addedNodes) {
                        // Only process element nodes
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            // Check the HTML content
                            if (node.outerHTML && node.outerHTML.includes(testOrgId)) {
                                log('✓ METHOD 3 SUCCESS: Found org ID in dynamically added DOM element!');
                                sendOrganizationIdToBackground(testOrgId, 'mutation-observer');
                                break;
                            }
                            
                            // Check for any text nodes that might contain the ID
                            const walker = document.createTreeWalker(
                                node,
                                NodeFilter.SHOW_TEXT,
                                null,
                                false
                            );
                            
                            let textNode;
                            while (textNode = walker.nextNode()) {
                                if (textNode.nodeValue && textNode.nodeValue.includes(testOrgId)) {
                                    log('✓ METHOD 3 SUCCESS: Found org ID in dynamically added text node!');
                                    sendOrganizationIdToBackground(testOrgId, 'mutation-observer-text');
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        });
        
        // Start observing the entire document
        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
        
        log('METHOD 3: Aggressive network monitoring set up successfully');
        return true;
    } catch (error) {
        log('METHOD 3: Error setting up aggressive monitoring:', error);
        return false;
    }
}

// Add a direct script injection method to find the organization ID
function injectDirectCodeToFindOrgId() {
    log('METHOD 4: Direct code injection to find organization ID');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Create a script element to run in the page context
        const script = document.createElement('script');
        script.textContent = `
            (function() {
                // Search in direct script variables
                try {
                    // Direct code execution in page context
                    const TARGET_ORG_ID = '${testOrgId}';
                    
                    // Helper to log findings through DOM
                    function notifyExtension(message, source) {
                        document.dispatchEvent(new CustomEvent('GenesysExtensionOrgIdFound', {
                            detail: { 
                                orgId: TARGET_ORG_ID,
                                source: source,
                                message: message
                            }
                        }));
                    }
                    
                    // 1. Try window-level objects first
                    console.log("[Genesys Extension] Searching for organization ID...");
                    
                    if (window.purecloud && window.purecloud.apps) {
                        const pcApps = window.purecloud.apps;
                        console.log("[Genesys Extension] Found purecloud.apps object");
                        
                        if (pcApps.orgId === TARGET_ORG_ID || pcApps.organizationId === TARGET_ORG_ID) {
                            notifyExtension("Found in purecloud.apps direct property", "pcApps-direct");
                        }
                        else if (pcApps.pcEnvironment && pcApps.pcEnvironment.orgId === TARGET_ORG_ID) {
                            notifyExtension("Found in pcEnvironment", "pcEnvironment");
                        }
                    }
                    
                    // 2. Search for organization-related objects
                    if (window.GenesysCloudCore && window.GenesysCloudCore.config) {
                        const config = window.GenesysCloudCore.config;
                        if (config.organization && config.organization.id === TARGET_ORG_ID) {
                            notifyExtension("Found in GenesysCloudCore.config", "GenesysCloudCore");
                        }
                    }
                    
                    // 3. Look for auth objects
                    if (window.PCAuthController && window.PCAuthController.organizationId === TARGET_ORG_ID) {
                        notifyExtension("Found in PCAuthController", "PCAuthController");
                    }
                    
                    // 4. Look for injected API response objects
                    if (window.__INITIAL_STATE__ && 
                        JSON.stringify(window.__INITIAL_STATE__).includes(TARGET_ORG_ID)) {
                        notifyExtension("Found in __INITIAL_STATE__", "initial-state");
                    }
                    
                    // 5. Check org-specific objects
                    if (window.PC_API_DATA && window.PC_API_DATA.org) {
                        const org = window.PC_API_DATA.org;
                        if (org.id === TARGET_ORG_ID || org.guid === TARGET_ORG_ID) {
                            notifyExtension("Found in PC_API_DATA.org", "pc-api-data");
                        }
                    }
                    
                    // 6. Look in localStorage
                    for (let i = 0; i < localStorage.length; i++) {
                        const key = localStorage.key(i);
                        const value = localStorage.getItem(key);
                        
                        if (key && key.toLowerCase().includes('org') && value.includes(TARGET_ORG_ID)) {
                            notifyExtension("Found in localStorage: " + key, "localStorage");
                            break;
                        }
                    }
                    
                    // 7. Scan all global variables (dangerous, but effective)
                    for (let prop in window) {
                        try {
                            if (typeof window[prop] === 'object' && window[prop] !== null) {
                                const objStr = JSON.stringify(window[prop]);
                                if (objStr && objStr.includes(TARGET_ORG_ID)) {
                                    notifyExtension("Found in window." + prop, "window-prop-" + prop);
                                    break;
                                }
                            }
                        } catch (e) {
                            // Ignore errors for objects that can't be stringified
                        }
                    }
                } catch (error) {
                    console.error("[Genesys Extension] Error in injected script:", error);
                }
            })();
        `;
        
        // Append the script to the page
        document.head.appendChild(script);
        
        // Remove the script after execution
        setTimeout(() => {
            if (script.parentNode) {
                script.parentNode.removeChild(script);
            }
        }, 100);
        
        // Listen for custom events from the injected script
        document.addEventListener('GenesysExtensionOrgIdFound', function(event) {
            const detail = event.detail;
            log(`✓ METHOD 4 SUCCESS: Found org ID via injected script! Source: ${detail.source}, Message: ${detail.message}`);
            sendOrganizationIdToBackground(detail.orgId, `injected-script:${detail.source}`);
        });
        
        log('METHOD 4: Injected code to search for organization ID');
        return true;
    } catch (error) {
        log('METHOD 4: Error injecting code:', error);
        return false;
    }
}

// METHOD 5: Shadow DOM traversal to find organization ID in shadow roots
function searchShadowDOMForOrgId() {
    log('METHOD 5: Searching shadow DOM for organization ID');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Function to recursively search shadow roots
        function traverseShadowDom(root, depth = 0) {
            if (!root || depth > 10) return null; // Prevent infinite recursion
            
            // Check the text content of this root
            if (root.textContent && root.textContent.includes(testOrgId)) {
                log(`✓ METHOD 5 SUCCESS: Found org ID in shadow DOM text!`);
                return testOrgId;
            }
            
            // Check elements with potential org ID attributes
            const orgElements = root.querySelectorAll('[data-org-id], [data-organization-id], [data-orgid], [data-guid]');
            for (const el of orgElements) {
                const attrValue = el.getAttribute('data-org-id') || 
                                  el.getAttribute('data-organization-id') || 
                                  el.getAttribute('data-orgid') || 
                                  el.getAttribute('data-guid');
                
                if (attrValue === testOrgId) {
                    log(`✓ METHOD 5 SUCCESS: Found org ID in shadow DOM element attribute!`);
                    sendOrganizationIdToBackground(testOrgId, 'shadow-dom-attr');
                    return testOrgId;
                }
            }
            
            // Find all elements with shadow roots
            const allElements = Array.from(root.querySelectorAll('*'));
            
            // First identify elements with shadow roots
            const elementsWithShadowRoots = allElements.filter(el => el.shadowRoot);
            
            if (elementsWithShadowRoots.length > 0) {
                log(`Found ${elementsWithShadowRoots.length} shadow roots at depth ${depth}`);
            }
            
            // Recursively check each shadow root
            for (const element of elementsWithShadowRoots) {
                // Access the shadow root
                const shadowRoot = element.shadowRoot;
                
                // Check its text content directly first
                if (shadowRoot.textContent && shadowRoot.textContent.includes(testOrgId)) {
                    log(`✓ METHOD 5 SUCCESS: Found org ID in newly created shadow root!`);
                    sendOrganizationIdToBackground(testOrgId, 'shadow-interception');
                    return testOrgId;
                }
                
                // Search the shadow DOM tree recursively
                const foundId = traverseShadowDom(shadowRoot, depth + 1);
                if (foundId) {
                    return foundId;
                }
            }
            
            return null;
        }
        
        // Start traversal from document body
        const found = traverseShadowDom(document.body);
        
        if (!found) {
            log('METHOD 5: No organization ID found in shadow DOM');
            return false;
        }
        
        return true;
    } catch (error) {
        log('METHOD 5: Error searching shadow DOM:', error);
        return false;
    }
}

// METHOD 6: Check cookies for organization ID
function checkCookiesForOrgId() {
    log('METHOD 6: Checking cookies for organization ID');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Check for cookies containing organization ID patterns
        const cookies = document.cookie;
        
        // Check for direct match
        if (cookies.includes(testOrgId)) {
            log('✓ METHOD 6 SUCCESS: Found org ID directly in cookies!');
            sendOrganizationIdToBackground(testOrgId, 'cookie-direct');
            return true;
        }
        
        // Check for encoded versions (URL encoded)
        const encodedOrgId = encodeURIComponent(testOrgId);
        if (cookies.includes(encodedOrgId)) {
            log('✓ METHOD 6 SUCCESS: Found encoded org ID in cookies!');
            sendOrganizationIdToBackground(testOrgId, 'cookie-encoded');
            return true;
        }
        
        // Check for specific Genesys cookie patterns
        if (cookies.includes('purecloud.com%2Forg%2Fid')) {
            log('Found Genesys organization cookie pattern, attempting to extract...');
            
            // Parse cookies
            const cookieArray = cookies.split(';');
            for (const cookie of cookieArray) {
                const [name, value] = cookie.trim().split('=');
                
                // Look for organization-related cookies
                if (name.includes('org') || name.includes('session') || 
                    value.includes('org') || value.includes('d9ee1fd7')) {
                    
                    log('Found potential org cookie:', name);
                    
                    // Try to decode and check for our test org ID
                    try {
                        const decodedValue = decodeURIComponent(value);
                        if (decodedValue.includes(testOrgId)) {
                            log('✓ METHOD 6 SUCCESS: Found org ID in decoded cookie!');
                            sendOrganizationIdToBackground(testOrgId, 'cookie-decoded');
                            return true;
                        }
                    } catch (e) {
                        // Skip invalid URI components
                    }
                }
            }
        }
        
        log('METHOD 6: No organization ID found in cookies');
        return false;
    } catch (error) {
        log('METHOD 6: Error checking cookies:', error);
        return false;
    }
}

// METHOD 7: Inject script to intercept shadow DOM creation
function injectShadowDOMInterception() {
    log('METHOD 7: Injecting shadow DOM interception');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';
    
    try {
        // Create script to override attachShadow
        const script = document.createElement('script');
        script.textContent = `
            (function() {
                // Store the original attachShadow method
                const originalAttachShadow = Element.prototype.attachShadow;
                
                // Override attachShadow to monitor shadow root creation
                Element.prototype.attachShadow = function() {
                    // Call the original method to create the shadow root
                    const shadowRoot = originalAttachShadow.apply(this, arguments);
                    
                    // Dispatch an event with the shadow root
                    window.dispatchEvent(new CustomEvent('shadowrootcreated', {
                        detail: {
                            host: this,
                            root: shadowRoot
                        }
                    }));
                    
                    // Return the shadow root as normal
                    return shadowRoot;
                };
                
                console.log("[Genesys Extension] Shadow DOM interception installed");
                
                // Also monitor XHR responses
                const originalXHROpen = XMLHttpRequest.prototype.open;
                const originalXHRSend = XMLHttpRequest.prototype.send;
                
                XMLHttpRequest.prototype.open = function() {
                    this._url = arguments[1];
                    return originalXHROpen.apply(this, arguments);
                };
                
                XMLHttpRequest.prototype.send = function() {
                    const xhr = this;
                    const url = xhr._url;
                    
                    if (url && (url.includes('organization') || url.includes('org'))) {
                        const originalOnReadyStateChange = xhr.onreadystatechange;
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === 4 && xhr.status >= 200 && xhr.status < 300) {
                                try {
                                    const responseText = xhr.responseText;
                                    if (responseText && responseText.includes('${testOrgId}')) {
                                        window.dispatchEvent(new CustomEvent('orgidfound', {
                                            detail: {
                                                orgId: '${testOrgId}',
                                                source: 'injected-xhr-override'
                                            }
                                        }));
                                    }
                                } catch(e) {}
                            }
                            
                            if (originalOnReadyStateChange) {
                                originalOnReadyStateChange.apply(this, arguments);
                            }
                        };
                    }
                    
                    return originalXHRSend.apply(this, arguments);
                };
            })();
        `;
        
        // Add the script to the page
        document.documentElement.appendChild(script);
        script.remove();
        
        // Listen for shadow root creation events
        window.addEventListener('shadowrootcreated', function(event) {
            const detail = event.detail;
            log('Shadow root created:', detail.host.tagName);
            
            // Check the new shadow root for organization ID
            setTimeout(() => {
                try {
                    const root = detail.root;
                    if (root.textContent && root.textContent.includes(testOrgId)) {
                        log('✓ METHOD 7 SUCCESS: Found org ID in newly created shadow root!');
                        sendOrganizationIdToBackground(testOrgId, 'shadow-interception');
                    }
                } catch (e) {
                    log('Error checking new shadow root:', e);
                }
            }, 100);
        });
        
        // Listen for organization ID found events
        window.addEventListener('orgidfound', function(event) {
            const detail = event.detail;
            log(`✓ METHOD 7 SUCCESS: Found org ID via injected XHR override! Source: ${detail.source}`);
            sendOrganizationIdToBackground(detail.orgId, detail.source);
        });
        
        log('METHOD 7: Shadow DOM interception installed');
        return true;
    } catch (error) {
        log('METHOD 7: Error installing shadow DOM interception:', error);
        return false;
    }
}

// METHOD 8: Request organization ID directly from API via background script
function fetchOrganizationInfoFromAPI() {
    log('METHOD 8: Requesting organization ID directly from API');
    
    try {
        chrome.runtime.sendMessage({ 
            action: 'fetchOrganizationInfo'
        }, function(response) {
            if (chrome.runtime.lastError) {
                log('METHOD 8: Error communicating with background:', chrome.runtime.lastError);
                return;
            }
            
            if (response && response.orgId) {
                log(`✓ METHOD 8 SUCCESS: Background script found org ID via direct API: ${response.orgId}`);
                
                // No need to send the ID back to background - it already has it
                // Just update the UI
                if (response.orgId === 'd9ee1fd7-868c-4ea0-af89-5b9813db863d') {
                    log('✓ METHOD 8 SUCCESS: Confirmed Wawanesa-Test organization!');
                    updateEnvironmentBadge('test');
                }
                
                return true;
            } else if (response && response.error) {
                log('METHOD 8: API request failed:', response.error);
            } else {
                log('METHOD 8: No organization ID found via direct API');
            }
        });
        
        return true;
    } catch (error) {
        log('METHOD 8: Error requesting API info:', error);
        return false;
    }
}

// METHOD 9: Aggressive response capture and logging
function captureAndLogAllResponses() {
    log('METHOD 9: Checking existing data and scanning document (Network interception removed due to CSP)');
    const testOrgId = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';

    // Network interception (fetch/XHR override) logic removed as it requires
    // script injection or background script handling. Background script is preferred.

    // Function to check existing page data (global vars, etc.)
    function checkExistingData() {
        try {
            log("METHOD 9: Checking for existing data in page");

            // Specific to Genesys - check common object paths
            const pathsToCheck = [
                'window.purecloud',
                'window.genesysCloud',
                'window.appBootStrapData',
                'window.__INITIAL_STATE__',
                'window.PC',
                'window.PureCloud',
                'window.PURECLOUD_APPS'
                // Add more potential paths here if needed
            ];

            for (const path of pathsToCheck) {
                try {
                    // Evaluate the path safely
                    const parts = path.split('.');
                    let obj = window;
                    for (let i = 1; i < parts.length; i++) { // Start from 1 to skip 'window'
                        if (obj && typeof obj === 'object' && obj !== null && parts[i] in obj) {
                             obj = obj[parts[i]];
                        } else {
                             obj = null;
                             break;
                        }
                    }


                    if (obj) {
                        log("METHOD 9: Found object at path:", path);

                        // Convert to string for analysis (with error handling)
                        let objString = '';
                        try {
                            objString = JSON.stringify(obj);
                        } catch (e) {
                            log("METHOD 9: Could not stringify object at path:", path, e);
                            continue; // Skip this object
                        }


                        if (objString.includes(testOrgId)) {
                            log("METHOD 9: ✓ SUCCESS: Found target org ID in existing data at:", path);
                            sendOrganizationIdToBackground(testOrgId, `existing-data-${path.replace('window.','')}`);
                            updateEnvironmentBadge('test'); // Update badge immediately
                            return true; // Found it
                        } else if (objString.includes('"organization"') ||
                                   objString.includes('"orgId"') ||
                                   objString.includes('"guid"') ||
                                   objString.includes('Wawanesa-Test')) {

                            // Log preview of potentially interesting data
                            log(`METHOD 9: Found potentially relevant data in ${path}`);
                            log(`  Preview: ${objString.substring(0, 200)}...`);
                            // Potentially send this preview to background for more analysis if needed
                        }
                    }
                } catch (e) {
                    // Skip errors for individual paths
                    log(`METHOD 9: Error accessing path ${path}:`, e);
                }
            }
        } catch (error) {
            log("METHOD 9: Error checking existing data:", error);
        }
        return false; // Not found in existing data
    }

    // Function to scan document HTML
    function scanDocument() {
        try {
            log("METHOD 9: Scanning document for organization ID");
            const html = document.documentElement.outerHTML;

            if (html.includes(testOrgId)) {
                log("METHOD 9: ✓ SUCCESS: Found target org ID in document HTML!");

                // Find where in the document it appears (optional, for debugging)
                const lines = html.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].includes(testOrgId)) {
                        log("[Genesys Extension] Found in line", i + 1, ":", lines[i].substring(0, 200) + '...');
                        break; // Only log the first occurrence
                    }
                }
                sendOrganizationIdToBackground(testOrgId, 'document-html');
                updateEnvironmentBadge('test'); // Update badge immediately
                return true; // Found it
            }
        } catch (error) {
            log("METHOD 9: Error scanning document:", error);
        }
        return false; // Not found in document
    }

    // Run checks
    if (!checkExistingData()) {
        // Only scan document if not found in existing data
        scanDocument();
    }

    log("METHOD 9: Completed existing data check and document scan");
}

// Set up periodic URL checks
function setupDetectionInterval() {
    log('Setting up periodic environment detection');
    
    // URL patterns that indicate specific environments
    const URL_PATTERNS = {
        test: [
            /wawanesa[\s-]?test/i,
            /test\.wawanesa/i,
            /wt-/i,
            /test-env/i,
            /test[\s_-]env/i,
            /genesyscloud-test/i,
            /test\.genesyscloud/i
        ],
        dev: [
            /wawanesa[\s-]?dev/i,
            /dev\.wawanesa/i,
            /wd-/i,
            /dev-env/i,
            /dev[\s_-]env/i,
            /genesyscloud-dev/i,
            /dev\.genesyscloud/i
        ],
        qa: [
            /wawanesa[\s-]?qa/i,
            /qa\.wawanesa/i,
            /wqa-/i,
            /qa-env/i,
            /qa[\s_-]env/i,
            /genesyscloud-qa/i,
            /qa\.genesyscloud/i
        ],
        staging: [
            /wawanesa[\s-]?stag/i,
            /stag\.wawanesa/i,
            /ws-/i,
            /staging-env/i,
            /staging[\s_-]env/i,
            /genesyscloud-staging/i,
            /stag\.genesyscloud/i
        ],
        prod: [
            /wawanesa(?![\s-]?(test|dev|qa|stag))/i,
            /prod\.wawanesa/i,
            /wp-/i,
            /prod-env/i,
            /prod[\s_-]env/i,
            /genesyscloud(?![\s_-](test|dev|qa|staging))/i,
            /app\.genesyscloud/i
        ]
    };
    
    // Check for environment clues in the URL
    function checkUrlForEnvironment() {
        const currentUrl = window.location.href;
        const hostname = window.location.hostname;
        
        log('METHOD 11: Checking URL for environment clues:', currentUrl);
        
        // First check if the URL contains our target org ID
        if (currentUrl.includes('d9ee1fd7-868c-4ea0-af89-5b9813db863d')) {
            log('✓ METHOD 11 SUCCESS: Found target org ID in URL!');
            sendOrganizationIdToBackground('d9ee1fd7-868c-4ea0-af89-5b9813db863d', 'url-check');
            updateEnvironmentBadge('test');
            return 'test';
        }
        
        // Look for environment patterns in URL
        for (const [env, patterns] of Object.entries(URL_PATTERNS)) {
            for (const pattern of patterns) {
                if (pattern.test(currentUrl) || pattern.test(hostname)) {
                    log(`METHOD 11: URL pattern match for '${env}' environment`);
                    
                    // Update UI and notify background
                    updateEnvironmentBadge(env);
                    chrome.runtime.sendMessage({
                        action: 'setEnvironmentType',
                        environmentType: env,
                        detectionMethod: 'url-pattern',
                        source: pattern.toString()
                    });
                    
                    return env;
                }
            }
        }
        
        // Check for query parameters or hash values
        const urlParams = new URLSearchParams(window.location.search);
        const hashParams = new URLSearchParams(window.location.hash.substring(1));
        
        // Check for environment parameter
        const envParam = urlParams.get('env') || urlParams.get('environment') || 
                         hashParams.get('env') || hashParams.get('environment');
        
        if (envParam) {
            let detectedEnv = envParam.toLowerCase();
            
            // Normalize environment names
            if (detectedEnv.includes('test')) detectedEnv = 'test';
            else if (detectedEnv.includes('dev')) detectedEnv = 'dev';
            else if (detectedEnv.includes('qa')) detectedEnv = 'qa';
            else if (detectedEnv.includes('stag')) detectedEnv = 'staging';
            else if (detectedEnv.includes('prod')) detectedEnv = 'prod';
            
            if (['test', 'dev', 'qa', 'staging', 'prod'].includes(detectedEnv)) {
                log(`METHOD 11: Found environment in URL parameters: ${detectedEnv}`);
                
                // Update UI and notify background
                updateEnvironmentBadge(detectedEnv);
                chrome.runtime.sendMessage({
                    action: 'setEnvironmentType',
                    environmentType: detectedEnv,
                    detectionMethod: 'url-parameter',
                    source: `param=${envParam}`
                });
                
                return detectedEnv;
            }
        }
        
        // Check for org ID parameter
        const orgParam = urlParams.get('orgId') || urlParams.get('organizationId') || 
                         hashParams.get('orgId') || hashParams.get('organizationId');
        
        if (orgParam) {
            log(`METHOD 11: Found organization ID in URL parameters: ${orgParam}`);
            
            // If this is our target org ID
            if (orgParam === 'd9ee1fd7-868c-4ea0-af89-5b9813db863d') {
                log('✓ METHOD 11 SUCCESS: Found Wawanesa-Test org ID in URL parameters!');
                sendOrganizationIdToBackground(orgParam, 'url-parameter');
                updateEnvironmentBadge('test');
                return 'test';
            } else {
                sendOrganizationIdToBackground(orgParam, 'url-parameter-unconfirmed');
            }
        }
        
        // No environment detected from URL
        log('METHOD 11: No environment detected from URL');
        return null;
    }
    
    // Initial check
    checkUrlForEnvironment();
    
    // Set up interval to check periodically for URL changes (single page apps often change URL without a page reload)
    let lastUrl = window.location.href;
    setInterval(() => {
        const currentUrl = window.location.href;
        if (currentUrl !== lastUrl) {
            log('URL changed, rechecking environment:', currentUrl);
            lastUrl = currentUrl;
            checkUrlForEnvironment();
        }
    }, 1000);
}