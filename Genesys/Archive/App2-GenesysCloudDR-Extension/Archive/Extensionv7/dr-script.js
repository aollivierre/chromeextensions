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
        log('Request to extract org ID from page');
        extractOrganizationIdFromPageData();
        sendResponse({ success: true });
    }
});

// Initialize environment detection
function initializeDetection() {
    log('Initializing environment detection');

    // Set up initial environment values from storage
    chrome.storage.sync.get(['environmentType'], function(result) {
        if (result.environmentType) {
            log('Loaded environment type from storage:', result.environmentType);
            updateEnvironmentBadge(result.environmentType);
        } else {
            // Create badge with unknown state if no environment is detected yet
            createEnvironmentBadge();
        }
    });
    
    // Start organization ID detection
    searchForOrgIdInStorage();
    
    // Set up interval to periodically check for org ID
    setupDetectionInterval();
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

// Poll for the organization ID in JS context
function pollForOrgIdInJSContext(attemptsLeft = 3, interval = 1000) {
    log('Polling for organization ID in JS context');
    
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
}

// Create the environment badge element
function createEnvironmentBadge() {
    log('Creating environment badge');
    
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
}

// Update the environment badge with the detected environment
function updateEnvironmentBadge(environmentType) {
    log('Updating environment badge to:', environmentType);
    
    // Only update if environment changed
    if (currentEnvironment === environmentType && badgeElement) {
        log('Environment unchanged, skipping update');
        return;
    }
    
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
    const CHECK_INTERVAL = 10000; // 10 seconds
    
    // Initial checks
    searchForOrgIdInStorage();
    pollForOrgIdInJSContext();
    
    // Schedule regular checks
    setInterval(() => {
        if (!currentEnvironment || currentEnvironment === 'unknown') {
            log('Periodic environment detection check');
            searchForOrgIdInStorage();
            extractOrganizationIdFromPageData();
        }
    }, CHECK_INTERVAL);
}