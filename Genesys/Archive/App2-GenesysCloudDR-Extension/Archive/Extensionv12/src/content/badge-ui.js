/**
 * Badge UI Module
 * Handles the creation, styling, and updating of the environment badge
 */

import { ENVIRONMENTS } from '../shared/constants';
import { log } from '../shared/utils';

// Keep track of the badge element
let badgeElement = null;

// Simple initialization flags
let isInitializing = true;
let orgIdDetectionComplete = false;
let finalEnvironment = null;

// Keep track of detected DR org ID
let hasDrOrgId = false;

/**
 * Sets initialization complete and processes any pending environment updates
 */
export function setInitializationComplete(environment = null) {
    log(`Badge initialization complete. Final environment: ${environment || 'unchanged'}`);
    
    // If we received a final environment from org ID detection, use it
    if (environment) {
        finalEnvironment = environment;
        // Apply it immediately
        internalUpdateBadge(environment);
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
    
    // If we detected DR via org ID, mark it for future badge updates
    if (environment === 'dr') {
        hasDrOrgId = true;
        log(`DR environment confirmed by org ID - badge will remain visible`);
    }
    
    // Apply environment immediately - this is our source of truth
    internalUpdateBadge(environment);
    
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
        // IMPORTANT: If we've confirmed DR via org ID, never hide the badge
        if ((environmentType === 'prod' || environmentType === 'unknown') && !hasDrOrgId) {
            if (badgeElement) {
                badgeElement.style.display = 'none';
                log(`${environmentType === 'prod' ? 'Production environment' : 'Login page'} detected - badge hidden`);
            }
            return;
        }
        
        // If we have confirmed DR org ID, always show DR badge
        if (hasDrOrgId) {
            environmentType = 'dr';
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
    // If initialization is still in progress, wait
    if (isInitializing) {
        log(`Received badge update during initialization: ${environmentType} (will be queued)`);
        return;
    }
    
    // If we have confirmed DR via org ID, always show the DR badge
    if (hasDrOrgId && environmentType !== 'dr') {
        log(`Ignoring update to ${environmentType} because DR org ID was detected`);
        internalUpdateBadge('dr');
        return;
    }
    
    // For DR updates, always show the badge
    if (environmentType === 'dr') {
        internalUpdateBadge('dr');
        return;
    }
    
    // For all other cases, apply the update directly
    internalUpdateBadge(environmentType);
}

/**
 * Returns the current badge element
 * @returns {HTMLElement|null} The badge element or null if it doesn't exist
 */
export function getBadgeElement() {
    return badgeElement;
}

/**
 * Explicitly set that we've detected DR through org ID
 * @param {boolean} isDr - Whether DR has been detected
 */
export function setDrOrgIdDetected(isDr = true) {
    hasDrOrgId = isDr;
    if (isDr) {
        log('DR org ID explicitly detected - badge will remain visible');
        internalUpdateBadge('dr');
    }
}