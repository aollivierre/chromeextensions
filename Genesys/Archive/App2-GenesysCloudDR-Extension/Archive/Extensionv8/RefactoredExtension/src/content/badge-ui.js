/**
 * Badge UI Module
 * Handles the creation, styling, and updating of the environment badge
 */

import { ENVIRONMENTS } from '../shared/constants';
import { log } from '../shared/utils';

// Keep track of the badge element
let badgeElement = null;

// Add initialization lock to prevent race conditions
let isInitializing = true;
let pendingDetection = null;
let orgIdDetectionComplete = false;

// Track final environment
let finalEnvironment = null;

/**
 * Sets initialization complete and processes any pending environment updates
 */
export function setInitializationComplete(environment = null) {
    log(`Badge initialization complete. Final environment: ${environment || 'unchanged'}`);
    
    // If we received a final environment from org ID detection, use it
    if (environment) {
        finalEnvironment = environment;
    }
    
    // Process any pending detection that was received during initialization
    if (pendingDetection) {
        log(`Processing pending detection: ${pendingDetection}`);
        internalUpdateBadge(pendingDetection);
        pendingDetection = null;
    } else if (finalEnvironment) {
        // Use final environment if we have one
        internalUpdateBadge(finalEnvironment);
    }
    
    // Mark initialization complete
    isInitializing = false;
    
    return finalEnvironment;
}

/**
 * Mark that org ID detection has completed with result
 */
export function setOrgIdDetectionComplete(environment) {
    log(`Org ID detection complete with environment: ${environment}`);
    
    // Always prioritize org ID detection results
    orgIdDetectionComplete = true;
    finalEnvironment = environment;
    
    // If this is prod or unknown, immediately update badge 
    if (environment === 'prod' || environment === 'unknown') {
        internalUpdateBadge(environment);
    }
    
    return environment;
}

/**
 * Creates the environment badge in the DOM if it doesn't already exist
 * @returns {HTMLElement} The badge element
 */
export function createEnvironmentBadge() {
    log('Creating environment badge');

    try {
        // Check if badge already exists
        if (badgeElement && document.body.contains(badgeElement)) {
            log('Badge already exists, returning existing element');
            return badgeElement;
        }

        // Create badge element
        badgeElement = document.createElement('div');
        badgeElement.id = 'genesys-environment-badge';
        badgeElement.className = 'genesys-environment-badge';
        
        // Set initial styles
        badgeElement.style.position = 'fixed';
        badgeElement.style.top = '10px';
        badgeElement.style.left = '50%';
        badgeElement.style.transform = 'translateX(-50%)';
        badgeElement.style.zIndex = '9999999';
        badgeElement.style.padding = '5px 10px';
        badgeElement.style.fontFamily = 'Arial, sans-serif';
        badgeElement.style.fontWeight = 'bold';
        badgeElement.style.fontSize = '12px';
        badgeElement.style.borderRadius = '4px';
        badgeElement.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.3)';
        badgeElement.style.userSelect = 'none';
        badgeElement.style.cursor = 'default';
        badgeElement.style.transition = 'background-color 0.3s ease';
        badgeElement.style.pointerEvents = 'none'; // Don't interfere with clicks
        
        // Start with badge hidden until we know the environment
        badgeElement.style.display = 'none';
        
        // Add tooltip behavior
        badgeElement.title = 'Genesys Cloud Environment';
        
        // Add to DOM
        if (document.body) {
            document.body.appendChild(badgeElement);
            log('Badge added to DOM');
        } else {
            // If document.body is not available yet, wait until it is
            log('document.body not available, waiting for it to be ready');
            const observer = new MutationObserver(function(mutations, obs) {
                if (document.body) {
                    document.body.appendChild(badgeElement);
                    log('Badge added to DOM after waiting');
                    obs.disconnect();
                }
            });
            
            observer.observe(document.documentElement, {
                childList: true,
                subtree: true
            });
        }
        
        return badgeElement;
    } catch (error) {
        log('Error creating badge:', error);
        return null;
    }
}

/**
 * Internal function to update badge UI without initialization checks
 */
function internalUpdateBadge(environmentType) {
    try {
        // For Production environment or login pages, hide badge completely
        if (environmentType === 'prod' || environmentType === 'unknown') {
            if (badgeElement) {
                badgeElement.style.display = 'none';
                log(`${environmentType === 'prod' ? 'Production environment' : 'Login page'} detected - badge hidden`);
            }
            return;
        }
        
        // Ensure badge exists
        if (!badgeElement) {
            badgeElement = createEnvironmentBadge();
        }
        
        // Get environment config
        const envConfig = ENVIRONMENTS[environmentType] || ENVIRONMENTS.unknown;
        
        // Update badge appearance
        badgeElement.textContent = envConfig.name;
        badgeElement.style.backgroundColor = envConfig.color;
        badgeElement.style.color = envConfig.textColor;
        badgeElement.title = envConfig.description;
        
        // Add environment-specific class
        badgeElement.className = 'genesys-environment-badge';
        badgeElement.classList.add(`genesys-env-${environmentType}`);
        
        // Ensure badge is visible
        badgeElement.style.display = 'block';
        
        log(`Badge UI updated to ${environmentType} environment`);
    } catch (error) {
        log('Error updating badge UI:', error);
    }
}

/**
 * Updates the badge UI to reflect the current environment
 * @param {string} environmentType - The environment type (dr, test, dev, unknown)
 */
export function updateBadgeUI(environmentType) {
    // Handle initialization lock
    if (isInitializing) {
        // If org ID detection has completed, always respect that result
        if (orgIdDetectionComplete && finalEnvironment) {
            log(`Ignoring update to ${environmentType} because org ID detection provided ${finalEnvironment}`);
            return;
        }
        
        // Otherwise, store the request to process after initialization
        log(`Received badge update during initialization: ${environmentType} (will be queued)`);
        pendingDetection = environmentType;
        return;
    }
    
    // Normal operation after initialization
    internalUpdateBadge(environmentType);
}

/**
 * Returns the current badge element
 * @returns {HTMLElement|null} The badge element or null if it doesn't exist
 */
export function getBadgeElement() {
    return badgeElement;
}