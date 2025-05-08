/**
 * Environment Detection Module
 * Coordinates detection from various sources and determines the most reliable environment
 */

import { log, safeStorageGet, safeStorageSet, getCurrentTimestamp } from '../shared/utils';
import { DETECTION_METHODS } from '../shared/constants';
import { detectStrongEnvironmentPatterns, detectEnvironmentFromUrl } from './detectors/url-detector';
import { detectOrganizationId } from './detectors/org-id-detector';
import { detectEnvironmentFromDom } from './detectors/dom-detector';
import { updateBadgeUI, setOrgIdDetectionComplete, setInitializationComplete } from './badge-ui';

// Track current state
let currentEnvironment = null;
let detectedOrgId = null;
let detectionMethod = null;
let detectionSource = null;
let lastDetectionTime = null;

/**
 * Initialize environment detection state from storage
 * @returns {Promise<void>}
 */
export function initializeDetectionState() {
    return new Promise((resolve) => {
        safeStorageGet(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], 
            function(data) {
                if (data.environmentType) {
                    currentEnvironment = data.environmentType;
                    log('Loaded environment type from storage:', currentEnvironment);
                }
                
                if (data.detectedOrgId) {
                    detectedOrgId = data.detectedOrgId;
                    log('Loaded organization ID from storage:', detectedOrgId);
                }
                
                if (data.detectionMethod) {
                    detectionMethod = data.detectionMethod;
                    log('Loaded detection method from storage:', detectionMethod);
                }
                
                if (data.detectionSource) {
                    detectionSource = data.detectionSource;
                    log('Loaded detection source from storage:', detectionSource);
                }
                
                if (data.lastUpdated) {
                    lastDetectionTime = data.lastUpdated;
                    log('Loaded last detection time from storage:', lastDetectionTime);
                }
                
                // Immediately perform detection to get the most accurate environment
                detectEnvironment().then((result) => {
                    if (result && result.environment) {
                        log(`Initial environment detection result: ${result.environment}`);
                        updateEnvironment(result);
                        
                        // Mark org ID detection as complete if this was an org ID detection
                        if (result.method === 'org-id-detection') {
                            setOrgIdDetectionComplete(result.environment);
                        }
                    }
                    
                    // Mark initialization as complete
                    setInitializationComplete(currentEnvironment);
                    resolve();
                });
            }
        );
    });
}

/**
 * Get the confidence level for a detection method
 * @param {string} method - The detection method
 * @returns {number} The confidence level (0-1)
 */
function getConfidenceLevel(method) {
    const methodConfig = Object.values(DETECTION_METHODS).find(m => m.name === method);
    return methodConfig ? methodConfig.confidence : DETECTION_METHODS.DEFAULT.confidence;
}

/**
 * Update the current environment based on detection result
 * @param {object} detectionResult - The detection result
 * @param {boolean} [forceUpdate=false] - Force update even if confidence is lower
 * @returns {boolean} Whether the environment was updated
 */
export function updateEnvironment(detectionResult, forceUpdate = false) {
    if (!detectionResult || !detectionResult.environment) {
        log('Invalid detection result, skipping update');
        return false;
    }
    
    const { environment, orgId, method, source, confidence } = detectionResult;
    
    // Get the confidence level of the current detection method
    const currentConfidence = detectionMethod ? 
        getConfidenceLevel(detectionMethod) : 0;
    
    // Get the confidence level of the new detection method
    const newConfidence = confidence || getConfidenceLevel(method);
    
    // Skip if this is the same environment we already detected
    if (environment === currentEnvironment && (orgId === null || orgId === detectedOrgId)) {
        log(`Same environment ${environment} already detected, skipping update`);
        return false;
    }
    
    // Special case: Allow DR detection to override TEST when URL patterns strongly indicate DR
    // This handles the case where a TEST org ID might be present in DR environment
    if (currentEnvironment === 'test' && environment === 'dr') {
        // For bookmark navigation, we want to be more aggressive about accepting DR detection
        if (method === DETECTION_METHODS.HOSTNAME.name ||
            method === DETECTION_METHODS.URL_PATTERN.name) {
            
            log(`Allowing DR detection (${method}: ${source}) to override TEST detection because URL indicates DR environment`);
            // Continue with the update
        } else if (currentConfidence > newConfidence && !forceUpdate) {
            // Otherwise, respect confidence levels
            log(`Ignoring ${environment} detection from ${method} (confidence: ${newConfidence}) ` +
                `because we already have ${currentEnvironment} from ${detectionMethod} (confidence: ${currentConfidence})`);
            return false;
        }
    }
    // Standard confidence check for other cases
    else if (currentEnvironment !== null && currentConfidence > newConfidence && !forceUpdate) {
        log(`Ignoring ${environment} detection from ${method} (confidence: ${newConfidence}) ` +
            `because we already have ${currentEnvironment} from ${detectionMethod} (confidence: ${currentConfidence})`);
        return false;
    }
    
    log(`Updating environment to ${environment} (${method}: ${source})`);
    
    // Update cached values
    currentEnvironment = environment;
    if (orgId) detectedOrgId = orgId;
    detectionMethod = method;
    detectionSource = source;
    lastDetectionTime = getCurrentTimestamp();
    
    // Update storage
    safeStorageSet({
        environmentType: environment,
        detectedOrgId: orgId || detectedOrgId,
        detectionMethod: method,
        detectionSource: source,
        lastUpdated: lastDetectionTime
    });
    
    // Return true to indicate the environment was updated
    return true;
}

/**
 * Check the current URL for environment indicators
 * @param {string} url - The URL to check (defaults to current window location)
 * @returns {Promise<object|null>} Detection result or null if none found
 */
export async function checkCurrentUrlForEnvironment(url = window.location.href) {
    log('Checking current URL for environment indicators:', url);
    
    // First try to detect strong environment patterns
    const strongPatternResult = detectStrongEnvironmentPatterns(url);
    if (strongPatternResult) {
        log('Found strong environment pattern in URL');
        
        // For bookmark navigation, immediately update the badge for strong patterns
        // especially for DR patterns
        if (strongPatternResult.environment === 'dr') {
            log('Strong DR pattern found, immediately updating badge');
            updateBadgeUI('dr');
            updateEnvironment(strongPatternResult, true); // Force update
        }
        
        return strongPatternResult;
    }
    
    // If no strong patterns, do a more detailed URL analysis
    const urlResult = detectEnvironmentFromUrl(url);
    if (urlResult) {
        log('Found environment indicator in URL');
        
        // For bookmark navigation to DR, immediately update the badge
        if (urlResult.environment === 'dr') {
            log('DR environment detected in URL, immediately updating badge');
            updateBadgeUI('dr');
        }
        
        return urlResult;
    }
    
    log('No environment indicators found in URL');
    return null;
}

/**
 * Perform a complete environment detection using all available methods
 * @returns {Promise<object|null>} The most reliable detection result or null if none found
 */
export async function detectEnvironment() {
    try {
        log('Starting complete environment detection');
        
        // Check if this is a login page
        const isLoginPage = window.location.href.toLowerCase().includes('login.') && 
            (window.location.href.includes('/authenticate') || 
             document.title.toLowerCase().includes('login'));
             
        if (isLoginPage) {
            log('Login page detected - suppressing environment detection until authentication completes');
            // Return unknown environment for login pages
            return {
                environment: 'unknown',
                method: 'login-page-detection',
                source: 'login-page',
                confidence: 0
            };
        }
        
        // Check URL first (fastest and might override other methods for DR)
        const urlResult = await checkCurrentUrlForEnvironment();
        if (urlResult && urlResult.environment === 'dr') {
            log('Found DR environment in URL, using this result');
            return urlResult;
        }
        
        // Then check for organization ID (highest confidence)
        const orgIdResult = await detectOrganizationId();
        if (orgIdResult) {
            log('Found environment via organization ID, using this result');
            log(`Environment detected: ${orgIdResult.environment} (original case)`);
            
            // Ensure environment is always lowercase for consistent comparison
            orgIdResult.environment = orgIdResult.environment.toLowerCase();
            log(`Environment normalized: ${orgIdResult.environment} (lowercase)`);
            
            // Special case: if we detect 'prod' environment with org ID, always use that
            // and disregard any other detection methods
            if (orgIdResult.environment === 'prod') {
                log('PRODUCTION environment detected with org ID - using this result and hiding badge');
                return orgIdResult;
            }
            
            // Special case: if org ID indicates TEST but URL strongly indicates DR,
            // we should use the URL result instead
            if (orgIdResult.environment === 'test' && urlResult && urlResult.environment === 'dr') {
                log('URL indicates DR but org ID indicates TEST, using DR from URL');
                return urlResult;
            }
            
            return orgIdResult;
        }
        
        // If org ID detection failed, use URL result if available
        if (urlResult) {
            log('Using environment from URL');
            return urlResult;
        }
        
        // Finally check DOM elements
        const domResult = await detectEnvironmentFromDom();
        if (domResult) {
            log('Found environment via DOM elements');
            return domResult;
        }
        
        log('No environment detected using any method');
        return null;
    } catch (error) {
        log('Error in detectEnvironment:', error);
        return null;
    }
}

/**
 * Reset environment detection state and force redetection
 * @returns {Promise<object|null>} New detection result or null if none found
 */
export async function resetAndRedetectEnvironment() {
    log('Resetting and redetecting environment');
    
    // Store old values for comparison
    const oldEnvironment = currentEnvironment;
    
    // Reset state
    currentEnvironment = null;
    detectedOrgId = null;
    detectionMethod = null;
    detectionSource = null;
    
    // Perform detection with all methods
    const result = await detectEnvironment();
    
    // If no result but we had one before, try to restore from background
    if (!result && oldEnvironment) {
        log('No environment detected after reset, checking with background script');
        
        // Request current environment from background script
        return new Promise((resolve) => {
            safeSendMessage({
                action: 'getCurrentEnvironment',
                url: window.location.href
            }).then(response => {
                if (response && response.environmentType) {
                    log('Received environment from background:', response.environmentType);
                    
                    const backgroundResult = {
                        environment: response.environmentType,
                        orgId: response.detectedOrgId || null,
                        method: response.detectionMethod || DETECTION_METHODS.DEFAULT.name,
                        source: response.detectionSource || 'background-script',
                        confidence: getConfidenceLevel(response.detectionMethod)
                    };
                    
                    resolve(backgroundResult);
                } else {
                    log('No environment info from background script');
                    resolve(null);
                }
            });
        });
    }
    
    return result;
}

/**
 * Update environment badge based on navigation changes
 * Ensures the badge reflects the current environment after tab switches
 * @returns {Promise<boolean>} True if badge was updated
 */
export async function updateBadgeAfterNavigation() {
    try {
        log('Updating badge after navigation');
        
        // For bookmark navigation, we need to be more aggressive about checking
        // the URL and updating the badge
        
        // Force immediate URL check first (for tab switches and bookmark navigation)
        const urlResult = await checkCurrentUrlForEnvironment();
        if (urlResult) {
            log('Found environment in URL after navigation:', urlResult.environment);
            
            // For bookmark navigation to DR, force the update
            const forceUpdate = urlResult.environment === 'dr';
            
            updateBadgeUI(urlResult.environment);
            updateEnvironment(urlResult, forceUpdate);
            
            // For DR environment, we want to be extra sure the badge is updated
            if (urlResult.environment === 'dr') {
                // Send a message to the background script to ensure it knows about the DR environment
                safeSendMessage({
                    action: 'strongDrPatternDetected',
                    pattern: urlResult.source || 'url-detection',
                    url: window.location.href
                });
            }
            
            return true;
        }
        
        // If no direct URL match, perform complete detection
        const result = await detectEnvironment();
        if (result) {
            log('Found environment after complete detection:', result.environment);
            
            // For bookmark navigation to DR, force the update
            const forceUpdate = result.environment === 'dr';
            
            if (updateEnvironment(result, forceUpdate)) {
                updateBadgeUI(result.environment);
                return true;
            }
        }
        
        return false;
    } catch (error) {
        log('Error updating badge after navigation:', error);
        return false;
    }
}

/**
 * Get the current environment detection state
 * @returns {object} The current state
 */
export function getCurrentState() {
    return {
        environment: currentEnvironment,
        orgId: detectedOrgId,
        method: detectionMethod,
        source: detectionSource,
        lastUpdated: lastDetectionTime
    };
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
                    if (chrome.runtime.lastError.message.includes('Extension context invalidated')) {
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

// Export safeSendMessage for use in other modules
export { safeSendMessage };