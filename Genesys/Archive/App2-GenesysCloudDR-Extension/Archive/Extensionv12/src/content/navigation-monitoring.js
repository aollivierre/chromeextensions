/**
 * Navigation Monitoring Module
 * Handles detection of Single Page Application (SPA) navigation
 */

import { log } from '../shared/utils';
import { resetAndRedetectEnvironment, updateBadgeAfterNavigation } from './environment-detection';

// Track current page URL for navigation detection
let currentPageUrl = window.location.href;
let isMonitoringSetup = false;

/**
 * Setup monitoring for URL changes in Single Page Applications
 * @returns {boolean} True if monitoring was setup, false if already setup
 */
export function setupNavigationMonitoring() {
    if (isMonitoringSetup) {
        log('Navigation monitoring already set up, skipping');
        return false;
    }
    
    log('Setting up enhanced navigation monitoring');

    try {
        // 1. Monitor History API
        monitorHistoryApi();
        
        // 2. Monitor DOM mutations for significant changes
        monitorDomMutations();
        
        // 3. Monitor browser history events
        monitorBrowserHistory();
        
        // 4. Set up periodic URL checking
        startPeriodicUrlCheck();
        
        isMonitoringSetup = true;
        return true;
    } catch (error) {
        log('Error setting up navigation monitoring:', error);
        return false;
    }
}

/**
 * Monitor History API methods (pushState and replaceState)
 */
function monitorHistoryApi() {
    // Store original history methods for later use
    const originalPushState = window.history.pushState;
    const originalReplaceState = window.history.replaceState;
    
    // Intercept pushState
    window.history.pushState = function() {
        // Call original method
        originalPushState.apply(this, arguments);
        
        // Check for URL change
        if (window.location.href !== currentPageUrl) {
            log('pushState detected navigation from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            handleUrlChange();
        }
    };
    
    // Intercept replaceState
    window.history.replaceState = function() {
        // Call original method
        originalReplaceState.apply(this, arguments);
        
        // Check for URL change
        if (window.location.href !== currentPageUrl) {
            log('replaceState detected navigation from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            handleUrlChange();
        }
    };

    log('History API monitoring set up');
}

/**
 * Monitor DOM mutations for significant changes that might indicate SPA navigation
 */
function monitorDomMutations() {
    const observer = new MutationObserver(function(mutations) {
        // Only check URL if we detect significant DOM changes
        const significantChanges = mutations.some(mutation => 
            mutation.type === 'childList' && 
            (mutation.addedNodes.length > 3 || mutation.removedNodes.length > 3)
        );
        
        if (significantChanges && window.location.href !== currentPageUrl) {
            log('Significant DOM changes with URL change detected from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            
            // Small delay to allow DOM to stabilize
            setTimeout(() => {
                handleUrlChange();
            }, 300);
        }
    });
    
    // Observe the document body for significant changes
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });

    log('DOM mutation monitoring set up');
}

/**
 * Monitor browser history events (popstate and hashchange)
 */
function monitorBrowserHistory() {
    // Listen for popstate (browser back/forward)
    window.addEventListener('popstate', function() {
        if (window.location.href !== currentPageUrl) {
            log('popstate navigation detected from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            handleUrlChange();
        }
    });
    
    // For hash changes
    window.addEventListener('hashchange', function() {
        log('Hash change detected from', currentPageUrl, 'to', window.location.href);
        currentPageUrl = window.location.href;
        handleUrlChange();
    });

    log('Browser history event monitoring set up');
}

/**
 * Start periodic checking of URL to catch any navigation changes missed by other methods
 */
function startPeriodicUrlCheck() {
    // Check URL periodically (every 1.5 seconds)
    setInterval(() => {
        if (window.location.href !== currentPageUrl) {
            log('URL change detected by interval checker, from', currentPageUrl, 'to', window.location.href);
            currentPageUrl = window.location.href;
            handleUrlChange();
        }
    }, 1500);

    log('Periodic URL checking set up');
}

/**
 * Handle URL changes by triggering environment redetection and updating badge
 */
function handleUrlChange() {
    log('Handling URL change, will redetect environment and update badge');
    
    // First reset and redetect the environment
    resetAndRedetectEnvironment()
        .then(result => {
            if (result) {
                log('Environment redetected after navigation:', result.environment);
                
                // Then explicitly update the badge to reflect the current environment
                return updateBadgeAfterNavigation();
            } else {
                log('No environment detected after navigation');
                // Still try to update badge based on URL patterns
                return updateBadgeAfterNavigation();
            }
        })
        .then(updated => {
            if (updated) {
                log('Badge successfully updated after navigation');
            }
        })
        .catch(error => {
            log('Error redetecting environment after navigation:', error);
        });
}

/**
 * Get the current page URL
 * @returns {string} The current page URL
 */
export function getCurrentPageUrl() {
    return currentPageUrl;
}

/**
 * Check if navigation monitoring has been set up
 * @returns {boolean} True if monitoring is set up
 */
export function isNavigationMonitoringSetup() {
    return isMonitoringSetup;
}