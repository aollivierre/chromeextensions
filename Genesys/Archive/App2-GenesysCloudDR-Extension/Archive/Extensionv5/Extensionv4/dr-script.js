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

// Target Organization ID to detect
const TARGET_ORG_ID = 'd9ee1fd7-868c-4ea0-af89-5b9813db863d';

// Known organization IDs mapped to environments (matching background.js)
const ORGANIZATION_MAPPINGS = {
    // DR environment mappings
    "70af5856-802a-423a-b07a-5f420c8e325d": "dr",   // Wawanesa-DR

    // Test environment mappings
    "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test", // Wawanesa-Test (Primary target)
    
    // Dev environment mappings
    "63ba1711-bcf1-4a4b-a101-f458280264b0": "dev",  // Development Org
};

// URL patterns for DR detection (as a fallback)
const DR_PATTERNS = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr', 'disaster', 'failover', 'recovery'];

// Enable logging
const DEBUG = true;

// Track the current page URL for navigation detection
let currentPageUrl = window.location.href;
let lastDetectedEnvironment = null;
let urlCheckIntervalId = null;
let isNavigationMonitoringSetup = false;

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
    try {
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
            log('Request to extract org ID from page');
            extractOrganizationIdFromPageData();
            sendResponse({ success: true });
        }
    } catch (error) {
        log('Error handling message:', error);
        sendResponse({ success: false, error: error.message });
    }
    return true; // Keep the message channel open for async responses
});

// Initialize environment detection
function initializeDetection() {
    log('Initializing environment detection');

    try {
        // Create badge first to ensure it's visible
        createEnvironmentBadge();

        // Reset environment variables on new page load
        currentEnvironment = null;
        
        // Set up initial environment values from storage
        chrome.storage.sync.get(['environmentType'], function(result) {
            if (result.environmentType) {
                log('Loaded environment type from storage:', result.environmentType);
                
                // Double-check environment based on URL immediately
                checkEnvironmentForCurrentUrl(result.environmentType);
            }
        });
        
        // Start organization ID detection
        searchForOrgIdInStorage();
        
        // Check for DR patterns in URL as fallback
        checkForDrPatterns();
        
        // Set up interval to periodically check for org ID
        setupDetectionInterval();
        
        // Set up navigation monitoring
        setupNavigationMonitoring();
    } catch (error) {
        log('Error during initialization:', error);
    }
}

// Check if the environment matches the current URL
function checkEnvironmentForCurrentUrl(storedEnvironment) {
    const url = window.location.href.toLowerCase();
    
    // Check for strong DR patterns
    const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
    const hasStrongDrPattern = strongDrPatterns.some(pattern => url.includes(pattern));
    
    if (hasStrongDrPattern && storedEnvironment !== 'dr') {
        log('URL suggests DR but stored environment is', storedEnvironment, '- showing DR badge');
        updateEnvironmentBadge('dr');
        return;
    }
    
    // Check for strong TEST patterns
    const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
    const hasStrongTestPattern = strongTestPatterns.some(pattern => url.includes(pattern));
    
    if (hasStrongTestPattern && storedEnvironment !== 'test') {
        log('URL suggests TEST but stored environment is', storedEnvironment, '- showing TEST badge');
        updateEnvironmentBadge('test');
        return;
    }
    
    // If no conflict, use stored environment
    updateEnvironmentBadge(storedEnvironment);
}

// Setup monitoring for URL changes (SPA navigation)
function setupNavigationMonitoring() {
    if (isNavigationMonitoringSetup) {
        log('Navigation monitoring already set up, skipping');
        return;
    }
    
    log('Setting up enhanced navigation monitoring');

    // Store original history methods for later use
    const originalPushState = window.history.pushState;
    const originalReplaceState = window.history.replaceState;
    
    // Intercept History API methods to detect navigation
    window.history.pushState = function() {
        // Call original method
        originalPushState.apply(this, arguments);
        
        // Check for URL change
        if (window.location.href !== currentPageUrl) {
            log('pushState detected navigation from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            resetAndRedetectEnvironment();
        }
    };
    
    window.history.replaceState = function() {
        // Call original method
        originalReplaceState.apply(this, arguments);
        
        // Check for URL change
        if (window.location.href !== currentPageUrl) {
            log('replaceState detected navigation from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            resetAndRedetectEnvironment();
        }
    };
    
    // Use mutation observer to detect potential SPA navigation
    const observer = new MutationObserver(function(mutations) {
        // Only check URL if we detect significant DOM changes
        const significantChanges = mutations.some(mutation => 
            mutation.type === 'childList' && 
            (mutation.addedNodes.length > 3 || mutation.removedNodes.length > 3)
        );
        
        if (significantChanges && window.location.href !== currentPageUrl) {
            log('Significant DOM changes with URL change detected from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            
            // Reset environment and redetect for new page
            setTimeout(() => {
                resetAndRedetectEnvironment();
            }, 300);
        }
    });
    
    // Observe the document body for significant changes that might indicate navigation
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
    
    // Listen for popstate (browser back/forward)
    window.addEventListener('popstate', function() {
        if (window.location.href !== currentPageUrl) {
            log('popstate navigation detected from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            resetAndRedetectEnvironment();
        }
    });
    
    // For hash changes
    window.addEventListener('hashchange', function() {
        log('Hash change detected from', currentPageUrl, 'to', window.location.href);
        currentPageUrl = window.location.href;
        resetAndRedetectEnvironment();
    });
    
    // Monitor XHR/Fetch requests that might indicate navigation
    monitorNetworkRequests();
    
    // Start more frequent URL checking interval
    startFrequentUrlChecking();
    
    isNavigationMonitoringSetup = true;
}

// Monitor network requests that might indicate navigation
function monitorNetworkRequests() {
    // Intercept XMLHttpRequest
    const originalXhrOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function() {
        const url = arguments[1];
        
        // Check if this is likely a navigation-related API call (adjust patterns as needed for Genesys Cloud)
        if (typeof url === 'string' && 
            (url.includes('/api/v2/') || 
             url.includes('/routing/') || 
             url.includes('/analytics/') ||
             url.includes('/organization/') ||
             url.includes('/authorization/'))) {
            
            log('Potential navigation XHR detected:', url);
            
            // After XHR completes, check if URL changed
            this.addEventListener('load', function() {
                setTimeout(() => {
                    if (window.location.href !== currentPageUrl) {
                        log('URL changed after XHR completed:', window.location.href);
                        currentPageUrl = window.location.href;
                        resetAndRedetectEnvironment();
                    }
                }, 500);
            });
        }
        
        return originalXhrOpen.apply(this, arguments);
    };
    
    // Intercept Fetch API if available
    if (window.fetch) {
        const originalFetch = window.fetch;
        window.fetch = function() {
            const url = arguments[0]?.url || arguments[0];
            
            // Check if this is likely a navigation-related API call
            if (typeof url === 'string' && 
                (url.includes('/api/v2/') || 
                 url.includes('/routing/') || 
                 url.includes('/analytics/') ||
                 url.includes('/organization/') ||
                 url.includes('/authorization/'))) {
                
                log('Potential navigation Fetch detected:', url);
                
                // After fetch completes, check if URL changed
                originalFetch.apply(this, arguments)
                    .then(response => {
                        setTimeout(() => {
                            if (window.location.href !== currentPageUrl) {
                                log('URL changed after Fetch completed:', window.location.href);
                                currentPageUrl = window.location.href;
                                resetAndRedetectEnvironment();
                            }
                        }, 500);
                        return response;
                    })
                    .catch(error => {
                        throw error;
                    });
            }
            
            return originalFetch.apply(this, arguments);
        };
    }
}

// Start more frequent URL checking
function startFrequentUrlChecking() {
    // Clear any existing interval
    if (urlCheckIntervalId) {
        clearInterval(urlCheckIntervalId);
    }
    
    // Check URL more frequently (every 1.5 seconds)
    urlCheckIntervalId = setInterval(() => {
        if (window.location.href !== currentPageUrl) {
            log('URL change detected by interval checker, from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            resetAndRedetectEnvironment();
        }
    }, 1500);
}

// Reset environment detection and redetect for new page
function resetAndRedetectEnvironment() {
    log('Resetting and redetecting environment for new page');
    
    // Store the last environment for comparison
    lastDetectedEnvironment = currentEnvironment;
    currentEnvironment = null;
    
    // Get latest from storage
    chrome.storage.sync.get(['environmentType', 'detectionMethod'], function(data) {
        // Check URL first for strong indicators
        const url = window.location.href.toLowerCase();
        
        // Strong DR patterns override everything
        const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
        const hasStrongDrPattern = strongDrPatterns.some(pattern => url.includes(pattern));
        
        if (hasStrongDrPattern) {
            log('Strong DR pattern in new URL - showing DR badge');
            updateEnvironmentBadge('dr');
            return;
        }
        
        // Strong TEST patterns take precedence if no DR patterns
        const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
        const hasStrongTestPattern = strongTestPatterns.some(pattern => url.includes(pattern));
        
        if (hasStrongTestPattern) {
            log('Strong TEST pattern in new URL - showing TEST badge');
            updateEnvironmentBadge('test');
            return;
        }
        
        // For regular cases, redetect
        searchForOrgIdInStorage();
        checkForDrPatterns();
        
        // Also check background script directly for most recent environment
        chrome.runtime.sendMessage({
            action: 'getCurrentEnvironment',
            url: window.location.href
        }, function(response) {
            if (response && response.environmentType) {
                log('Received environment from background:', response.environmentType);
                updateEnvironmentBadge(response.environmentType);
            } else if (data.environmentType) {
                log('Using stored environment for new page:', data.environmentType);
                checkEnvironmentForCurrentUrl(data.environmentType);
            }
        });
    });
}

// Check browser storage for the target organization ID
function searchForOrgIdInStorage() {
    log('Searching for organization IDs in browser storage');
    
    try {
        // Check localStorage for the organization ID
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            const value = localStorage.getItem(key);
            
            // Check each known organization ID
            for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                if (value && value.includes(orgId)) {
                    log(`Found organization ID ${orgId} in localStorage under key: ${key}`);
                    sendOrganizationIdToBackground(orgId, `localStorage:${key}`);
                    return;
                }
            }
        }
        
        // Check sessionStorage for the organization ID
        for (let i = 0; i < sessionStorage.length; i++) {
            const key = sessionStorage.key(i);
            const value = sessionStorage.getItem(key);
            
            // Check each known organization ID
            for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                if (value && value.includes(orgId)) {
                    log(`Found organization ID ${orgId} in sessionStorage under key: ${key}`);
                    sendOrganizationIdToBackground(orgId, `sessionStorage:${key}`);
                    return;
                }
            }
        }
        
        log('No organization IDs found in browser storage');
    } catch (error) {
        log('Error searching storage for org ID:', error);
    }
}

// Check for DR patterns in URL as fallback
function checkForDrPatterns() {
    try {
        const url = window.location.href.toLowerCase();
        
        // First check for strong DR patterns that should override any existing detection
        const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
        for (const pattern of strongDrPatterns) {
            if (url.includes(pattern)) {
                log(`Found strong DR pattern in URL: ${pattern}`);
                // Strong DR patterns should override any existing environment
                updateEnvironmentBadge('dr');
                
                // Also inform the background script about this strong pattern
                chrome.runtime.sendMessage({
                    action: 'strongDrPatternDetected',
                    pattern: pattern,
                    url: url
                });
                
                return;
            }
        }
        
        // For other, less definitive DR patterns, check if we already have a TEST detection
        chrome.storage.sync.get(['environmentType', 'detectionMethod'], function(data) {
            // If we already have organization ID based TEST detection, respect it
            if (data.environmentType === 'test' && 
                data.detectionMethod === 'Organization ID') {
                log('Already have TEST environment from Organization ID, skipping weak DR pattern check');
                return;
            }
            
            // Check for other DR patterns
            for (const pattern of DR_PATTERNS) {
                // Skip patterns we already checked above
                if (strongDrPatterns.includes(pattern)) continue;
                
                if (url.includes(pattern)) {
                    log(`Found DR pattern in URL: ${pattern}`);
                    // Only update if we don't already have a valid environment
                    if (!currentEnvironment || currentEnvironment === 'unknown') {
                        updateEnvironmentBadge('dr');
                    }
                    return;
                }
            }
        });
    } catch (error) {
        log('Error checking for DR patterns:', error);
    }
}

// Poll for the organization ID in JS context
function pollForOrgIdInJSContext(attemptsLeft = 3, interval = 1000) {
    log('Polling for organization ID in JS context');
    
    try {
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
        
        // Check each org ID against the common object locations
        for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
            for (const obj of commonOrgObjects) {
                if (obj === orgId) {
                    log(`Found organization ID ${orgId} in JS context`);
                    sendOrganizationIdToBackground(orgId, 'js-context');
                    return;
                }
            }
        }
        
        // If not found and attempts remain, try again after interval
        if (attemptsLeft > 0) {
            setTimeout(() => {
                pollForOrgIdInJSContext(attemptsLeft - 1, interval);
            }, interval);
        }
    } catch (error) {
        log('Error polling for org ID in JS context:', error);
    }
}

// Create the environment badge element
function createEnvironmentBadge() {
    log('Creating environment badge');
    
    try {
        // If badge already exists, don't create another one
        if (document.getElementById('dr-environment-badge')) {
            log('Badge already exists, not creating another one');
            badgeElement = document.getElementById('dr-environment-badge');
            return;
        }
        
        // Create the badge element
        badgeElement = document.createElement('div');
        badgeElement.id = 'dr-environment-badge';
        badgeElement.textContent = 'ENV';
        badgeElement.style.backgroundColor = ENVIRONMENTS.unknown.color;
        badgeElement.style.color = ENVIRONMENTS.unknown.textColor;
        
        // Add tooltip with environment description
        badgeElement.title = ENVIRONMENTS.unknown.description;
        
        // Add badge to the document body
        document.body.appendChild(badgeElement);
        
        log('Environment badge created');
    } catch (error) {
        log('Error creating environment badge:', error);
    }
}

// Update the environment badge with the detected environment
function updateEnvironmentBadge(environmentType) {
    log('Updating environment badge to:', environmentType);
    
    try {
        // Skip invalid environment types
        if (!environmentType || !ENVIRONMENTS[environmentType]) {
            log('Invalid environment type:', environmentType);
            return;
        }
        
        // URL-based pattern check for final verification
        const url = window.location.href.toLowerCase();
        
        // Override detection for specific URL patterns
        const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
        const hasStrongDrPattern = strongDrPatterns.some(pattern => url.includes(pattern));
        
        const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
        const hasStrongTestPattern = strongTestPatterns.some(pattern => url.includes(pattern));
        
        // DR patterns take highest precedence
        if (hasStrongDrPattern) {
            log('URL has strong DR pattern - forcing DR badge');
            environmentType = 'dr';
        }
        // TEST patterns take second precedence if no DR patterns
        else if (hasStrongTestPattern && !hasStrongDrPattern) {
            log('URL has strong TEST pattern - forcing TEST badge');
            environmentType = 'test';
        }
        
        // Only update if environment has changed
        if (currentEnvironment === environmentType && badgeElement) {
            log('Environment unchanged, skipping update');
            return;
        }
        
        // Update current environment and badge
        updateBadgeUI(environmentType);
        
        // Notify background script about URL-based override
        if ((hasStrongDrPattern && environmentType === 'dr') || 
            (hasStrongTestPattern && environmentType === 'test')) {
            
            chrome.runtime.sendMessage({
                action: 'urlPatternOverride',
                environment: environmentType,
                url: url,
                pattern: hasStrongDrPattern ? 'dr' : 'test'
            });
        }
    } catch (error) {
        log('Error updating environment badge:', error);
    }
}

// Helper to update the badge UI with environment settings
function updateBadgeUI(environmentType) {
    // Update current environment tracking
    currentEnvironment = environmentType;
    
    // Get environment configuration
    const envConfig = ENVIRONMENTS[environmentType] || ENVIRONMENTS.unknown;
    
    // Create badge if it doesn't exist
    if (!badgeElement) {
        createEnvironmentBadge();
    }
    
    // Update badge text and styling
    badgeElement.textContent = envConfig.name;
    badgeElement.style.backgroundColor = envConfig.color;
    badgeElement.style.color = envConfig.textColor;
    badgeElement.title = envConfig.description;
    
    log('Badge updated to show:', envConfig.name);
}

// Extract organization ID from page data (used as fallback)
function extractOrganizationIdFromPageData() {
    log('Extracting organization ID from page data');
    
    try {
        // Check for org ID in document source
        const docSource = document.documentElement.outerHTML;
        
        // Check each known organization ID
        for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
            if (docSource.includes(orgId)) {
                log(`Found organization ID ${orgId} in document source`);
                sendOrganizationIdToBackground(orgId, 'document-source');
                return;
            }
        }
        
        // Check for org ID in any script tags
        const scriptTags = document.getElementsByTagName('script');
        for (let i = 0; i < scriptTags.length; i++) {
            const scriptContent = scriptTags[i].textContent;
            if (!scriptContent) continue;
            
            // Check each known organization ID
            for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                if (scriptContent.includes(orgId)) {
                    log(`Found organization ID ${orgId} in script tag`);
                    sendOrganizationIdToBackground(orgId, 'script-tag');
                    return;
                }
            }
        }
        
        log('No organization IDs found in page data');
    } catch (error) {
        log('Error extracting organization ID from page:', error);
    }
}

// Send detected organization ID to background script
function sendOrganizationIdToBackground(orgId, source) {
    log('Sending organization ID to background:', orgId, 'Source:', source);
    
    try {
        chrome.runtime.sendMessage({
            action: 'detectedOrganizationId',
            orgId: orgId,
            source: source
        }, function(response) {
            if (chrome.runtime.lastError) {
                log('Error sending org ID to background:', chrome.runtime.lastError);
                return;
            }
            
            log('Background script response:', response);
        });
    } catch (error) {
        log('Error sending message to background:', error);
    }
}

// Set up interval to periodically check for environment changes
function setupDetectionInterval() {
    const CHECK_INTERVAL = 3000; // Reduced from 5000 to 3000 ms
    
    try {
        // Initial checks
        searchForOrgIdInStorage();
        pollForOrgIdInJSContext();
        
        // Schedule regular checks
        setInterval(() => {
            // Standard check process
            chrome.storage.sync.get(['environmentType', 'detectionMethod'], function(data) {
                // Always perform URL-based check on each interval
                const url = window.location.href.toLowerCase();
                
                // Strong DR patterns override anything in storage
                const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
                const hasStrongDrPattern = strongDrPatterns.some(pattern => url.includes(pattern));
                
                if (hasStrongDrPattern && currentEnvironment !== 'dr') {
                    log('Strong DR pattern found in current URL - overriding to DR');
                    updateEnvironmentBadge('dr');
                    return;
                }
                
                // Strong TEST patterns for TEST environment
                const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
                const hasStrongTestPattern = strongTestPatterns.some(pattern => url.includes(pattern));
                
                if (hasStrongTestPattern && currentEnvironment !== 'test' && !hasStrongDrPattern) {
                    log('Strong TEST pattern found in current URL - overriding to TEST');
                    updateEnvironmentBadge('test');
                    return;
                }
                
                // If we have a valid environment from a reliable method, use it
                if (data.environmentType && data.detectionMethod) {
                    // Only update if the environment from storage doesn't match current display
                    // and there's no URL pattern override
                    if (currentEnvironment !== data.environmentType && 
                        !(hasStrongDrPattern && data.environmentType !== 'dr') &&
                        !(hasStrongTestPattern && data.environmentType !== 'test')) {
                        
                        log(`Using environment from storage: ${data.environmentType} (via ${data.detectionMethod})`);
                        updateEnvironmentBadge(data.environmentType);
                    }
                }
                // Only do fallback detection if we don't have a good environment
                else if (!currentEnvironment || currentEnvironment === 'unknown') {
                    log('Periodic environment detection check');
                    searchForOrgIdInStorage();
                    extractOrganizationIdFromPageData();
                    
                    // Only check for DR patterns if no environment is detected
                    if (!currentEnvironment || currentEnvironment === 'unknown') {
                        checkForDrPatterns();
                    }
                }
            });
        }, CHECK_INTERVAL);
    } catch (error) {
        log('Error setting up detection interval:', error);
    }
}