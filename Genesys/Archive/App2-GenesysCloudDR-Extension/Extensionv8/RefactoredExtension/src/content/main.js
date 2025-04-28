/**
 * Content Script Main Module
 * Entry point for content script functionality
 */

import { log } from '../shared/utils';
import { createEnvironmentBadge, updateBadgeUI } from './badge-ui';
import { 
    initializeDetectionState, 
    detectEnvironment, 
    updateEnvironment, 
    checkCurrentUrlForEnvironment 
} from './environment-detection';
import { setupNavigationMonitoring } from './navigation-monitoring';
import { setupNetworkMonitoring } from './network-monitoring';
import { getStorageData, saveStorageData } from './storage-utils';

// Track initialization state
let isInitialized = false;

/**
 * Initialize the extension content script
 */
async function initialize() {
    if (isInitialized) {
        log('Content script already initialized, skipping');
        return;
    }

    log('Content script initializing');
    
    try {
        // Step 1: Create the environment badge first (make it visible early)
        createEnvironmentBadge();
        
        // Step 2: Initialize detection state from storage
        await initializeDetectionState();
        
        // Step 3: Check URL immediately for strong environment indicators
        // Strong DR patterns should take precedence immediately
        const urlResult = await checkCurrentUrlForEnvironment();
        if (urlResult && urlResult.environment === 'dr') {
            log('Found DR environment in URL, updating immediately');
            updateEnvironment(urlResult);
            updateBadgeUI(urlResult.environment);
        } else {
            // Step 4: Load environment from storage (if available)
            const data = await getStorageData(['environmentType']);
            if (data.environmentType) {
                log('Using environment from storage:', data.environmentType);
                updateBadgeUI(data.environmentType);
            }
        }
        
        // Step 5: Set up navigation monitoring (for SPAs)
        // Pass the handleUrlChange function to ensure badge updates on navigation
        setupNavigationMonitoring();
        
        // Step 6: Set up network request monitoring
        setupNetworkMonitoring(handleUrlChange);
        
        // Step 7: Perform a complete environment detection
        performDetection();
        
        // Mark as initialized
        isInitialized = true;
        log('Content script initialized successfully');
    } catch (error) {
        log('Error during initialization:', error);
    }
}

/**
 * Perform a complete environment detection
 */
async function performDetection() {
    try {
        log('Performing complete environment detection');
        
        // Detect environment using all available methods
        const result = await detectEnvironment();
        
        if (result) {
            log('Environment detected:', result.environment);
            
            // Update environment in storage
            if (updateEnvironment(result)) {
                // Update badge UI to reflect new environment
                updateBadgeUI(result.environment);
            }
        } else {
            log('No environment detected');
            
            // If no environment detected, use 'unknown'
            updateBadgeUI('unknown');
        }
    } catch (error) {
        log('Error performing detection:', error);
    }
}

/**
 * Handle URL changes from navigation monitoring
 * @param {string} newUrl - The new URL
 */
function handleUrlChange(newUrl) {
    log('URL change detected:', newUrl);
    
    // For bookmark navigation, we need to be more aggressive about checking
    // the URL and updating the badge
    
    // Check the new URL for environment indicators and update if needed
    checkCurrentUrlForEnvironment(newUrl)
        .then(result => {
            if (result) {
                log('Found environment in new URL:', result.environment);
                
                // For bookmark navigation to DR, force the update
                const forceUpdate = result.environment === 'dr';
                
                if (updateEnvironment(result, forceUpdate)) {
                    updateBadgeUI(result.environment);
                    
                    // For DR environment, we want to be extra sure the badge is updated
                    if (result.environment === 'dr') {
                        // Send a message to the background script to ensure it knows about the DR environment
                        chrome.runtime.sendMessage({
                            action: 'strongDrPatternDetected',
                            pattern: result.source || 'url-detection',
                            url: window.location.href
                        });
                    }
                }
            } else {
                // If no environment indicators in URL, do a complete detection
                performDetection();
            }
        })
        .catch(error => {
            log('Error checking URL after change:', error);
        });
}

/**
 * Extract organization ID from the page
 */
async function extractOrganizationId() {
    try {
        log('Extracting organization ID from page');
        
        // Use our detection module to extract org ID
        const result = await detectEnvironment();
        
        if (result && result.orgId) {
            log('Extracted organization ID:', result.orgId);
            
            // Send to background script
            chrome.runtime.sendMessage({
                action: 'reportOrganizationId',
                orgId: result.orgId,
                source: result.source || 'content-script-extraction'
            }, function(response) {
                if (response && response.success) {
                    log('Background acknowledged organization ID');
                }
            });
            
            return true;
        } else {
            log('No organization ID found in page');
            return false;
        }
    } catch (error) {
        log('Error extracting organization ID:', error);
        return false;
    }
}

/**
 * Set up message handling from background script and other parts of the extension
 */
function setupMessageHandling() {
    chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        try {
            if (message.action === 'environmentChange') {
                log('Received environment change:', message.environment, 'Org ID:', message.orgId || 'Not Provided');
                
                // For bookmark navigation, check if this is a DR environment
                const isDrEnvironment = message.environment === 'dr';
                
                // Update badge with new environment
                updateBadgeUI(message.environment);
                
                // If org ID provided by background, store it
                if (message.orgId) {
                    log('Storing organization ID from background:', message.orgId);
                    saveStorageData({ detectedOrgId: message.orgId });
                }
                
                // For DR environment, check the current URL again to ensure we're showing the correct badge
                if (isDrEnvironment) {
                    log('DR environment received, double-checking URL');
                    checkCurrentUrlForEnvironment().then(result => {
                        if (result && result.environment === 'dr') {
                            log('Confirmed DR environment from URL check');
                            updateBadgeUI('dr');
                        }
                    });
                }
                
                // Acknowledge receipt
                sendResponse({ success: true });
            }
            
            // Handle request to extract org ID from the page
            if (message.action === 'extractOrgIdFromPage') {
                log('Request to extract org ID from page');
                extractOrganizationId();
                sendResponse({ success: true });
            }
            
            // Handle request to redetect environment
            if (message.action === 'redetectEnvironment') {
                log('Request to redetect environment');
                performDetection();
                sendResponse({ success: true });
            }
            
            // Handle updateBadge action (for tab activation)
            if (message.action === 'updateBadge' && message.environment) {
                log('Received direct badge update request:', message.environment);
                updateBadgeUI(message.environment);
                sendResponse({ success: true });
            }
        } catch (error) {
            log('Error handling message:', error);
            sendResponse({ success: false, error: error.message });
        }
        return true; // Keep the message channel open for async responses
    });
}

// Initialize when DOM is ready
if (document.readyState === 'interactive' || document.readyState === 'complete') {
    log('Document already ready, initializing now');
    initialize();
} else {
    log('Document not ready, waiting for DOMContentLoaded');
    document.addEventListener('DOMContentLoaded', function() {
        log('DOMContentLoaded fired, initializing');
        initialize();
    });
}

// Set up message handling
setupMessageHandling();

// Add badge persistence mechanisms

// 1. Check periodically to ensure badge is present
setInterval(() => {
    const badge = document.getElementById('genesys-environment-badge');
    if (!badge || badge.style.display === 'none') {
        log('Badge not found or hidden, recreating');
        createEnvironmentBadge();
        
        // Re-apply environment if known
        getStorageData(['environmentType']).then(data => {
            if (data.environmentType) {
                updateBadgeUI(data.environmentType);
            }
        });
    }
}, 2000);

// 2. Set up DOM Mutation Observer to detect when badge might be removed
if (document.body) {
    setupMutationObserver();
} else {
    document.addEventListener('DOMContentLoaded', setupMutationObserver);
}

/**
 * Set up mutation observer to monitor DOM changes that might affect the badge
 */
function setupMutationObserver() {
    try {
        const observer = new MutationObserver(mutations => {
            const badge = document.getElementById('genesys-environment-badge');
            if (!badge) {
                log('Badge removed from DOM, recreating');
                createEnvironmentBadge();
                
                // Re-apply environment if known
                getStorageData(['environmentType']).then(data => {
                    if (data.environmentType) {
                        updateBadgeUI(data.environmentType);
                    }
                });
            }
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
        
        log('Mutation observer set up for badge persistence');
    } catch (error) {
        log('Error setting up mutation observer:', error);
    }
}

// Export key functions for potential use in other modules
export {
    initialize,
    performDetection,
    extractOrganizationId
};