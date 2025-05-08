/**
 * Organization ID Detector Module
 * Detects environment information based on organization IDs found in auth token
 */

import { log } from '../../shared/utils';
import { ORGANIZATION_MAPPINGS } from '../../shared/constants';
import { setOrgIdDetectionComplete } from '../badge-ui';

// The definitive localStorage key that contains org ID information
const AUTH_TOKEN_KEY = 'gcucc-ui-auth-token';

// Track the last detected auth token value to detect changes
let lastAuthTokenValue = null;

// Track whether polling is active
let pollingActive = false;

// Polling interval (milliseconds)
const POLL_INTERVAL = 500;  // Check every 500ms

/**
 * Get the current organization ID from localStorage
 * @returns {Object|null} Object with orgId, environment, and detection metadata or null if not found
 */
export function getCurrentOrgId() {
    try {
        // Get the latest auth token
        const authToken = localStorage.getItem(AUTH_TOKEN_KEY);
        if (!authToken) {
            log('Auth token not found in localStorage');
            lastAuthTokenValue = null;
            return null;
        }
        
        // Check if token has changed since last check
        const tokenChanged = authToken !== lastAuthTokenValue;
        if (tokenChanged) {
            log(`Auth token has changed. First 40 chars: ${authToken.substring(0, 40)}...`);
            lastAuthTokenValue = authToken;
        }
        
        // Debug: Log all the org IDs we're looking for
        if (tokenChanged) {
            log(`Looking for these org IDs:`, Object.keys(ORGANIZATION_MAPPINGS).join(', '));
        }
        
        // Find which org ID is in the token
        for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
            if (authToken.includes(orgId)) {
                if (tokenChanged) {
                    log(`Found organization ID ${orgId} in localStorage auth token`);
                    log(`Mapped to environment: ${environment.toUpperCase()}`);
                }
                
                return {
                    environment,
                    orgId,
                    confidence: 1.0, // Highest confidence since this is our single source of truth
                    method: 'org-id-detection',
                    source: `localStorage:${AUTH_TOKEN_KEY}`
                };
            }
        }
        
        if (tokenChanged) {
            log('No known organization ID found in auth token');
        }
        return null;
    } catch (error) {
        log('Error checking auth token for org ID:', error);
        return null;
    }
}

/**
 * Master function to check organization ID
 * @returns {Promise<object|null>} The detection result or null if not found
 */
export async function detectOrganizationId() {
    try {
        // Simply call the getCurrentOrgId function directly
        // We've simplified to use only one detection method
        return getCurrentOrgId();
    } catch (error) {
        log('Error in detectOrganizationId:', error);
        return null;
    }
}

/**
 * Safely send a message to the background script with error handling
 * @param {object} message - The message to send
 * @returns {Promise<any>} The response or null if error
 */
function safeSendMessage(message) {
    return new Promise((resolve) => {
        try {
            chrome.runtime.sendMessage(message, (response) => {
                if (chrome.runtime.lastError) {
                    // Handle extension context invalidated gracefully
                    if (chrome.runtime.lastError.message?.includes('Extension context invalidated')) {
                        log('Extension context invalidated - this is normal during updates');
                    } else {
                        log('Runtime error:', chrome.runtime.lastError.message);
                    }
                    resolve(null);
                    return;
                }
                resolve(response);
            });
        } catch (error) {
            // Catch any errors related to extension context
            log('Error sending message to background script:', error.message);
            resolve(null);
        }
    });
}

/**
 * Handler for storage changes
 * @param {Event} event - Storage event
 */
function handleStorageChange(event) {
    if (event.key === AUTH_TOKEN_KEY) {
        log('AUTH TOKEN CHANGED VIA STORAGE EVENT');
        // Force a detection and send the result to update the badge
        const result = getCurrentOrgId();
        if (result) {
            // Special case for production environments - force an update
            const isProdEnvironment = result.environment.toLowerCase() === 'prod';
            if (isProdEnvironment) {
                log('PRODUCTION ENVIRONMENT DETECTED - Forcing badge removal');
                // Immediately update local badge
                safeSendMessage({
                    action: 'environmentChanged',
                    result: result,
                    forceRefresh: true
                });
            } else {
                // Regular environment change notification
                safeSendMessage({
                    action: 'environmentChanged',
                    result: result
                });
            }
        } else {
            // If no result, notify of token change but unknown environment
            log('Auth token changed but no environment could be determined');
            safeSendMessage({
                action: 'authTokenChanged',
                hasToken: !!localStorage.getItem(AUTH_TOKEN_KEY)
            });
        }
    }
}

/**
 * Poll for auth token changes
 */
function pollAuthToken() {
    // Get current result
    const result = getCurrentOrgId();
    
    // If environment detected, notify
    if (result) {
        safeSendMessage({
            action: 'environmentDetectedPoll',
            result: result
        });
    }
}

/**
 * Start actively monitoring for environment changes
 */
export function startEnvironmentMonitoring() {
    log('Starting active environment monitoring');
    
    // Set up storage event listener
    window.addEventListener('storage', handleStorageChange);
    
    // Start polling if not already active
    if (!pollingActive) {
        log(`Setting up polling every ${POLL_INTERVAL}ms`);
        setInterval(pollAuthToken, POLL_INTERVAL);
        pollingActive = true;
    }
    
    // Perform initial check
    const initialResult = getCurrentOrgId();
    if (initialResult) {
        log(`Initial environment detected: ${initialResult.environment}`);
        
        // Signal that org ID detection has completed
        setOrgIdDetectionComplete(initialResult.environment);
    }
    
    return initialResult;
}

// Initialize monitoring when this module is loaded
startEnvironmentMonitoring();

// Export the direct detection function for easier access
export { getCurrentOrgId as detectOrgIdFromStorage };