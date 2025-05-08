/**
 * Network Monitoring Module
 * Tracks XHR/fetch operations for navigation detection and API data
 */

import { log } from '../shared/utils';
import { NAVIGATION_API_PATTERNS, STRONG_DR_PATTERNS } from '../shared/patterns';
import { getCurrentPageUrl } from './navigation-monitoring';
import { updateEnvironment } from './environment-detection';
import { DETECTION_METHODS } from '../shared/constants';

// Track XHR requests that include org IDs
let isMonitoringSetup = false;

/**
 * Set up network request monitoring
 * @param {function} navigationCallback - Function to call when navigation is detected
 * @returns {boolean} True if monitoring was set up, false if already set up
 */
export function setupNetworkMonitoring(navigationCallback) {
    if (isMonitoringSetup) {
        log('Network monitoring already set up, skipping');
        return false;
    }
    
    log('Setting up network request monitoring');

    try {
        // 1. Monitor XMLHttpRequest
        monitorXhr(navigationCallback);
        
        // 2. Monitor Fetch API if available
        if (window.fetch) {
            monitorFetch(navigationCallback);
        }
        
        isMonitoringSetup = true;
        return true;
    } catch (error) {
        log('Error setting up network monitoring:', error);
        return false;
    }
}

/**
 * Monitor XMLHttpRequest for navigation and environment data
 * @param {function} navigationCallback - Function to call when navigation is detected
 */
function monitorXhr(navigationCallback) {
    // Store original XHR open method
    const originalXhrOpen = XMLHttpRequest.prototype.open;
    
    // Replace with monitored version
    XMLHttpRequest.prototype.open = function() {
        const url = arguments[1];
        
        // Check if this is a navigation-related API call
        if (typeof url === 'string') {
            // Track for navigation purposes
            const isNavigationApi = NAVIGATION_API_PATTERNS.some(pattern => url.includes(pattern));
            
            if (isNavigationApi) {
                log('Potential navigation XHR detected:', url);
                
                // Check URL for DR patterns while we're at it
                const urlLower = url.toLowerCase();
                const hasDrPattern = STRONG_DR_PATTERNS.some(pattern => urlLower.includes(pattern));
                
                if (hasDrPattern) {
                    const pattern = STRONG_DR_PATTERNS.find(p => urlLower.includes(p));
                    log(`Found DR pattern "${pattern}" in XHR URL:`, urlLower);
                    
                    // Update environment based on XHR URL
                    updateEnvironment({
                        environment: 'dr',
                        method: DETECTION_METHODS.API_ENDPOINT.name,
                        source: `xhr-url:${pattern}`,
                        confidence: DETECTION_METHODS.API_ENDPOINT.confidence
                    });
                }
                
                // After XHR completes, check if URL changed
                this.addEventListener('load', function() {
                    setTimeout(() => {
                        const pageUrl = window.location.href;
                        if (pageUrl !== getCurrentPageUrl()) {
                            log('URL changed after XHR completed:', pageUrl);
                            
                            // Notify navigation system
                            if (navigationCallback && typeof navigationCallback === 'function') {
                                navigationCallback(pageUrl);
                            }
                        }
                        
                        // Check response for org ID data regardless of URL change
                        try {
                            const responseText = this.responseText;
                            if (responseText && responseText.includes('organization') && 
                                (url.includes('/api/v2/organizations/') || url.includes('/api/v2/users/me'))) {
                                log('Found potential organization data in XHR response');
                                
                                // Request the background page to extract org ID
                                chrome.runtime.sendMessage({
                                    action: 'checkApiResponse',
                                    data: responseText,
                                    url: url
                                });
                            }
                        } catch (e) {
                            // Response might not be accessible due to CORS
                            log('Could not access XHR response:', e);
                        }
                    }, 500);
                });
            }
        }
        
        // Call original method
        return originalXhrOpen.apply(this, arguments);
    };

    log('XMLHttpRequest monitoring set up');
}

/**
 * Monitor Fetch API for navigation and environment data
 * @param {function} navigationCallback - Function to call when navigation is detected
 */
function monitorFetch(navigationCallback) {
    // Store original fetch
    const originalFetch = window.fetch;
    
    // Replace with monitored version
    window.fetch = function() {
        // Get URL (might be a Request object or string)
        const url = arguments[0]?.url || arguments[0];
        
        // Original call reference for chaining
        const fetchCall = originalFetch.apply(this, arguments);
        
        // Check if this is a navigation-related API call
        if (typeof url === 'string') {
            const isNavigationApi = NAVIGATION_API_PATTERNS.some(pattern => url.includes(pattern));
            
            if (isNavigationApi) {
                log('Potential navigation Fetch detected:', url);
                
                // Check URL for DR patterns
                const urlLower = url.toLowerCase();
                const hasDrPattern = STRONG_DR_PATTERNS.some(pattern => urlLower.includes(pattern));
                
                if (hasDrPattern) {
                    const pattern = STRONG_DR_PATTERNS.find(p => urlLower.includes(p));
                    log(`Found DR pattern "${pattern}" in Fetch URL:`, urlLower);
                    
                    // Update environment based on Fetch URL
                    updateEnvironment({
                        environment: 'dr',
                        method: DETECTION_METHODS.API_ENDPOINT.name,
                        source: `fetch-url:${pattern}`,
                        confidence: DETECTION_METHODS.API_ENDPOINT.confidence
                    });
                }
                
                // After fetch completes, check if URL changed
                fetchCall
                    .then(response => {
                        setTimeout(() => {
                            const pageUrl = window.location.href;
                            if (pageUrl !== getCurrentPageUrl()) {
                                log('URL changed after Fetch completed:', pageUrl);
                                
                                // Notify navigation system
                                if (navigationCallback && typeof navigationCallback === 'function') {
                                    navigationCallback(pageUrl);
                                }
                            }
                            
                            // Try to clone the response and check for org data
                            if (url.includes('/api/v2/organizations/') || url.includes('/api/v2/users/me')) {
                                try {
                                    // Clone the response to not interfere with the original
                                    const clonedResponse = response.clone();
                                    
                                    // Try to extract as JSON
                                    clonedResponse.json().then(data => {
                                        if (data && data.organization && data.organization.id) {
                                            log('Found organization ID in Fetch response:', data.organization.id);
                                            
                                            // Request the background page to check this org ID
                                            chrome.runtime.sendMessage({
                                                action: 'checkOrganizationId',
                                                orgId: data.organization.id,
                                                source: `fetch-response:${url}`
                                            });
                                        }
                                    }).catch(e => {
                                        log('Error parsing Fetch response as JSON:', e);
                                    });
                                } catch (e) {
                                    log('Error cloning Fetch response:', e);
                                }
                            }
                        }, 500);
                        
                        return response; // Important: return the original response
                    })
                    .catch(error => {
                        // Re-throw to not break error handling
                        throw error;
                    });
            }
        }
        
        return fetchCall; // Return the original fetch promise
    };

    log('Fetch API monitoring set up');
}

/**
 * Check if network monitoring is set up
 * @returns {boolean} True if monitoring is set up
 */
export function isNetworkMonitoringSetup() {
    return isMonitoringSetup;
}