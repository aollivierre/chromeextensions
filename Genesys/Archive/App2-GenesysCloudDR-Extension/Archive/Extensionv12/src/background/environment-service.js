/**
 * Background Environment Service
 * Handles environment detection, validation, and management
 */

import { log } from '../shared/utils';
import { ORGANIZATION_MAPPINGS, HOSTNAME_MAPPINGS, DETECTION_METHODS } from '../shared/constants';
import { ENVIRONMENT_PATTERNS, STRONG_DR_PATTERNS, EXCLUDE_WORDS } from '../shared/patterns';
import storageService from './storage-service';

class EnvironmentService {
    constructor() {
        this.initialized = false;
        this.currentEnvironment = null;
        this.detectedOrgId = null;
        this.lastDetectionMethod = null;
        this.lastDetectionSource = null;
        this.lastDetectionTime = null;
        this.processedUrls = new Set();
        this.tabEnvironmentCache = new Map(); // Track environment data by tab ID
    }

    /**
     * Initialize the environment service
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing environment service');
            
            // Load existing environment data from storage
            const data = await storageService.getMultiple([
                'environmentType', 
                'detectedOrgId', 
                'detectionMethod', 
                'detectionSource', 
                'lastUpdated'
            ]);
            
            if (data.environmentType) {
                this.currentEnvironment = data.environmentType;
                log('Loaded environment type:', this.currentEnvironment);
            }
            
            if (data.detectedOrgId) {
                this.detectedOrgId = data.detectedOrgId;
                log('Loaded organization ID:', this.detectedOrgId);
            }
            
            if (data.detectionMethod) {
                this.lastDetectionMethod = data.detectionMethod;
                log('Loaded detection method:', this.lastDetectionMethod);
            }
            
            if (data.detectionSource) {
                this.lastDetectionSource = data.detectionSource;
                log('Loaded detection source:', this.lastDetectionSource);
            }
            
            if (data.lastUpdated) {
                this.lastDetectionTime = data.lastUpdated;
                log('Loaded last detection time:', this.lastDetectionTime);
            }
            
            this.initialized = true;
            log('Environment service initialized');
            return true;
        } catch (error) {
            log('Error initializing environment service:', error);
            return false;
        }
    }

    /**
     * Check a URL for environment indicators
     * @param {number} tabId - The tab ID
     * @param {string} url - The URL to check
     * @returns {Promise<object|null>} Detection result or null if none found
     */
    async checkUrlForEnvironment(tabId, url) {
        try {
            const urlLower = url.toLowerCase();
            const parsedUrl = new URL(urlLower);
            const hostname = parsedUrl.hostname.toLowerCase();
            const path = parsedUrl.pathname;
            const fullUrlText = `${hostname}${path}${parsedUrl.hash}`;
            
            // IMPROVEMENT: Skip environment detection on login pages until auth occurs
            if (hostname.includes('login.') && 
                (parsedUrl.hash.includes('/authenticate') || 
                 path.includes('/authenticate') || 
                 fullUrlText.includes('login'))) {
                log(`Login page detected, skipping URL-based environment detection: ${url}`);
                return {
                    environment: 'unknown',
                    tabId,
                    url,
                    orgId: null,
                    method: 'login-page',
                    source: 'login-detection',
                    confidence: 0
                };
            }
            
            // First check if this is clearly a DR URL by specific patterns
            // These are so definitive that we should trust them regardless of other detection methods
            const hasStrongDrPattern = STRONG_DR_PATTERNS.some(pattern => urlLower.includes(pattern));
            
            if (hasStrongDrPattern) {
                log(`Strong DR pattern found in URL: ${url}`);
                
                // Find the specific pattern for reporting
                const matchedPattern = STRONG_DR_PATTERNS.find(pattern => urlLower.includes(pattern));
                
                // For strong DR patterns, we'll prioritize this over any existing detection
                const result = {
                    environment: 'dr',
                    tabId,
                    url,
                    orgId: null,
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: `strong-dr-pattern:${matchedPattern}`,
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence
                };
                
                // Update environment
                await this.updateEnvironment(result);
                return result;
            }
            
            // Check if we already have a high-confidence environment detection
            const data = await storageService.getMultiple(['environmentType', 'detectionMethod', 'detectedOrgId']);
            
            // IMPROVEMENT: If we have org ID detection, prioritize it over URL patterns
            if (data.environmentType && 
                data.detectionMethod === DETECTION_METHODS.ORG_ID.name &&
                data.detectedOrgId) {
                log(`Already have org ID based detection: ${data.environmentType}, skipping URL pattern detection`);
                return null;
            }
            
            // For bookmark navigation between environments, we need to check if the URL
            // contains strong patterns that should override existing detection
            
            // First, check if this URL contains any strong DR patterns
            // If it does, we should always use DR environment regardless of existing detection
            const hasDrPatternInUrl = STRONG_DR_PATTERNS.some(pattern => urlLower.includes(pattern));
            
            if (hasDrPatternInUrl) {
                log(`Strong DR pattern found in URL during standard detection: ${url}`);
                const matchedPattern = STRONG_DR_PATTERNS.find(pattern => urlLower.includes(pattern));
                
                const result = {
                    environment: 'dr',
                    tabId,
                    url,
                    orgId: null,
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: `strong-dr-pattern:${matchedPattern}`,
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence
                };
                
                await this.updateEnvironment(result);
                return result;
            }
            
            // If we already have organization ID based detection, respect it
            // unless we already determined this is a strong DR URL above
            if (data.environmentType &&
                data.detectionMethod === DETECTION_METHODS.ORG_ID.name) {
                log(`Already have high-confidence detection (${data.detectionMethod}): ${data.environmentType}, skipping URL pattern detection`);
                return null;
            }
            
            // Continue with standard URL detection logic
            // but with reduced confidence level
            
            // 1. Check for known hostnames (high confidence)
            for (const [knownHostname, environment] of Object.entries(HOSTNAME_MAPPINGS)) {
                if (hostname.includes(knownHostname)) {
                    log(`Hostname match: ${knownHostname} -> ${environment}`);
                    
                    const result = {
                        environment,
                        tabId,
                        url,
                        orgId: null,
                        method: DETECTION_METHODS.HOSTNAME.name,
                        source: knownHostname,
                        // IMPROVEMENT: Reduce confidence of URL detection
                        confidence: DETECTION_METHODS.HOSTNAME.confidence * 0.8
                    };
                    
                    // Update environment based on hostname
                    await this.updateEnvironment(result);
                    return result;
                }
            }

            // 2. Check for DR patterns (unless URL contains exclusion words)
            const hasDrExcludeWord = EXCLUDE_WORDS.dr.some(word => fullUrlText.includes(word));
            
            if (!hasDrExcludeWord) {
                // Special case for DR login URLs that might be more reliable
                if (hostname.includes('login') && fullUrlText.includes('wawanesa-dr')) {
                    log('Found DR login URL with organization name');
                    
                    const result = {
                        environment: 'dr',
                        tabId,
                        url,
                        orgId: null,
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: 'login-wawanesa-dr',
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence
                    };
                    
                    await this.updateEnvironment(result);
                    return result;
                }
                
                for (const pattern of ENVIRONMENT_PATTERNS.dr) {
                    if (urlLower.includes(pattern)) {
                        log(`DR pattern match in URL: ${pattern}`);
                        
                        const result = {
                            environment: 'dr',
                            tabId,
                            url,
                            orgId: null,
                            method: DETECTION_METHODS.URL_PATTERN.name,
                            source: `url-pattern:${pattern}`,
                            confidence: DETECTION_METHODS.URL_PATTERN.confidence
                        };
                        
                        await this.updateEnvironment(result);
                        return result;
                    }
                }
            }

            // 3. Check for TEST patterns
            for (const pattern of ENVIRONMENT_PATTERNS.test) {
                if (urlLower.includes(pattern)) {
                    log(`TEST pattern match in URL: ${pattern}`);
                    
                    const result = {
                        environment: 'test',
                        tabId,
                        url,
                        orgId: null,
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`,
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence
                    };
                    
                    await this.updateEnvironment(result);
                    return result;
                }
            }

            // 4. Check for DEV patterns
            for (const pattern of ENVIRONMENT_PATTERNS.dev) {
                if (urlLower.includes(pattern)) {
                    log(`DEV pattern match in URL: ${pattern}`);
                    
                    const result = {
                        environment: 'dev',
                        tabId,
                        url,
                        orgId: null,
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`,
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence
                    };
                    
                    await this.updateEnvironment(result);
                    return result;
                }
            }

            // 5. Check for API endpoints that might indicate DR environment
            if (path.includes('/api/')) {
                if (path.includes('/dr/') || path.includes('/dr-api/')) {
                    log('DR API endpoint detected in path');
                    
                    const result = {
                        environment: 'dr',
                        tabId,
                        url,
                        orgId: null,
                        method: DETECTION_METHODS.API_ENDPOINT.name,
                        source: path,
                        confidence: DETECTION_METHODS.API_ENDPOINT.confidence
                    };
                    
                    await this.updateEnvironment(result);
                    return result;
                }
            }

            log('No environment indicators found in URL');
            return null;
        } catch (error) {
            log('Error checking URL:', error);
            return null;
        }
    }

    /**
     * Process an organization ID detection
     * @param {string} orgId - The detected organization ID
     * @param {string} source - The source of the detection
     * @param {number} [tabId] - Optional tab ID where org ID was found
     * @returns {Promise<object|null>} Detection result or null if org ID is invalid
     */
    async processOrganizationId(orgId, source, tabId = null) {
        if (!orgId || typeof orgId !== 'string') {
            log('Invalid organization ID:', orgId);
            return null;
        }

        // Special handling for DR org ID
        if (orgId === "d6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac") {
            log(`DR Organization ID ${orgId} detected - forcing DR environment`);
            
            const result = {
                environment: "dr",
                tabId,
                orgId,
                method: DETECTION_METHODS.ORG_ID.name,
                source: source || 'dr-org-detection',
                confidence: 1.0 // Maximum confidence for DR detection
            };
            
            // Force update environment to DR
            this.currentEnvironment = "dr";
            this.detectedOrgId = orgId;
            this.lastDetectionMethod = DETECTION_METHODS.ORG_ID.name;
            this.lastDetectionSource = source || 'dr-org-detection';
            this.lastDetectionTime = new Date().toISOString();
            
            // Minimal storage write to avoid quota issues
            try {
                await storageService.setMultiple({
                    environmentType: "dr",
                    detectedOrgId: orgId
                });
            } catch (error) {
                log('Error writing DR environment to storage - continuing with in-memory state');
            }
            
            // Notify all tabs with priority
            if (tabId) {
                this.notifyTab(tabId, "dr", orgId);
            }
            this.notifyEnvironmentChange("dr", orgId);
            
            return result;
        }
    
        // Map organization ID to environment for non-DR case
        const environment = ORGANIZATION_MAPPINGS[orgId];
        if (!environment) {
            log(`Organization ID ${orgId} not found in mappings`);
            return null;
        }

        log(`Organization ID ${orgId} mapped to environment: ${environment}`);
        
        const result = {
            environment,
            tabId,
            orgId,
            method: DETECTION_METHODS.ORG_ID.name,
            source: source || 'unknown',
            confidence: DETECTION_METHODS.ORG_ID.confidence
        };
        
        // Update environment
        await this.updateEnvironment(result);
        
        return result;
    }

    /**
     * Update environment information
     * @param {object} detectionResult - The detection result
     * @returns {Promise<boolean>} True if environment was updated
     */
    async updateEnvironment(detectionResult) {
        if (!detectionResult || !detectionResult.environment) {
            log('Invalid detection result, skipping update');
            return false;
        }
        
        const { environment, orgId, method, source, confidence } = detectionResult;
        
        // Get the confidence level of the current detection method
        const currentMethodConfidence = 
            this.lastDetectionMethod ? 
            (DETECTION_METHODS[this.lastDetectionMethod] || DETECTION_METHODS.DEFAULT).confidence : 
            0;
        
        // Get the confidence level of the new detection method
        const newMethodConfidence = confidence || 
            (DETECTION_METHODS[method] || DETECTION_METHODS.DEFAULT).confidence;
        
        // Special case for TEST and DEV environments with org ID
        // Always update if we're getting an org ID for TEST or DEV, even if environment is the same
        if ((environment === 'test' || environment === 'dev') && orgId &&
            method === DETECTION_METHODS.ORG_ID.name) {
            // Continue with the update to ensure we have the combined detection method
            log(`Updating TEST/DEV environment with org ID detection: ${orgId}`);
        }
        // Skip if this is the same environment we already detected (for other cases)
        else if (environment === this.currentEnvironment && (orgId === null || orgId === this.detectedOrgId)) {
            log(`Same environment ${environment} already detected, skipping update`);
            return false;
        }
        
        // Special case: Allow DR detection to override TEST when URL patterns strongly indicate DR
        // This handles the case where a TEST org ID might be present in DR environment
        if (this.currentEnvironment === 'test' && environment === 'dr') {
            // For bookmark navigation, we want to be more aggressive about accepting DR detection
            // to fix the issue where badge shows TEST when navigating to DR
            if (method === DETECTION_METHODS.HOSTNAME.name ||
                method === DETECTION_METHODS.URL_PATTERN.name) {
                
                log(`Allowing DR detection (${method}: ${source}) to override TEST detection because URL indicates DR environment`);
                // Continue with the update
            } else if (currentMethodConfidence > newMethodConfidence) {
                // Otherwise, respect confidence levels
                log(`Ignoring ${environment} detection from ${method} (confidence: ${newMethodConfidence}) ` +
                    `because we already have ${this.currentEnvironment} from ${this.lastDetectionMethod} (confidence: ${currentMethodConfidence})`);
                return false;
            }
        }
        // Standard confidence check for other cases
        else if (this.currentEnvironment !== null && currentMethodConfidence > newMethodConfidence) {
            log(`Ignoring ${environment} detection from ${method} (confidence: ${newMethodConfidence}) ` +
                `because we already have ${this.currentEnvironment} from ${this.lastDetectionMethod} (confidence: ${currentMethodConfidence})`);
            return false;
        }
        
        log(`Updating environment to ${environment} (${method}: ${source})`);
        
        // Update cached values
        this.currentEnvironment = environment;
        if (orgId) this.detectedOrgId = orgId;
        
        // For TEST and DEV environments, if we have an org ID, use a combined detection method
        let finalMethod = method;
        let finalSource = source;
        
        if ((environment === 'test' || environment === 'dev') && orgId) {
            // If the method is Organization ID, keep it as is
            if (method === DETECTION_METHODS.ORG_ID.name) {
                finalMethod = method;
                finalSource = source;
            }
            // If the method is Hostname or URL_PATTERN but we also have an org ID, indicate the combined approach
            else if (method === DETECTION_METHODS.HOSTNAME.name || method === DETECTION_METHODS.URL_PATTERN.name) {
                finalMethod = "URL+OrgID";
                finalSource = `${source} + ${orgId}`;
            }
        }
        
        this.lastDetectionMethod = finalMethod;
        this.lastDetectionSource = finalSource;
        this.lastDetectionTime = new Date().toISOString();
        
        // Update storage
        await storageService.setMultiple({
            environmentType: environment,
            detectedOrgId: orgId || this.detectedOrgId,
            detectionMethod: finalMethod,
            detectionSource: finalSource,
            lastUpdated: this.lastDetectionTime
        });
        
        // Notify tabs about environment change
        if (detectionResult.tabId) {
            // If we know which tab triggered this, notify it first
            this.notifyTab(detectionResult.tabId, environment, orgId);
        }
        
        // Then notify all other relevant tabs
        this.notifyEnvironmentChange(environment, orgId);
        
        return true;
    }

    /**
     * Notify all relevant tabs about an environment change
     * @param {string} environment - The new environment
     * @param {string} orgId - The organization ID (optional)
     */
    async notifyEnvironmentChange(environment, orgId = null) {
        try {
            // Query for Genesys Cloud tabs to notify
            chrome.tabs.query({ 
                url: [
                    "*://*.pure.cloud/*",
                    "*://*.mypurecloud.com/*",
                    "*://*.genesys.cloud/*"
                ] 
            }, (tabs) => {
                log(`Notifying ${tabs.length} tabs about environment change to ${environment}`);
                
                // Notify each tab
                tabs.forEach(tab => {
                    this.notifyTab(tab.id, environment, orgId);
                });
            });
        } catch (error) {
            log('Error notifying tabs:', error);
        }
    }

    /**
     * Clear any cached environment data for a specific tab
     * This is important for bookmark navigation between environments
     * @param {number} tabId - The tab ID to clear cache for
     */
    clearTabEnvironmentCache(tabId) {
        if (this.tabEnvironmentCache.has(tabId)) {
            log(`Clearing environment cache for tab ${tabId}`);
            this.tabEnvironmentCache.delete(tabId);
        }
    }

    /**
     * Notify a specific tab about environment change
     * @param {number} tabId - The tab ID to notify
     * @param {string} environment - The new environment
     * @param {string} orgId - The organization ID (optional)
     */
    notifyTab(tabId, environment, orgId = null) {
        // Simple caching to avoid redundant updates
        const existingCache = this.tabEnvironmentCache.get(tabId);
        const now = Date.now();
        
        // Special case: For DR environment with confirmed DR org ID, always update
        const isDrOrgId = orgId === "d6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac";
        
        // For non-DR cases, skip duplicate updates to reduce message traffic
        if (!isDrOrgId && existingCache && existingCache.environment === environment) {
            log(`Skipping duplicate environment update to tab ${tabId}`);
            return;
        }
        
        // Update the cache
        this.tabEnvironmentCache.set(tabId, {
            environment,
            orgId,
            timestamp: now
        });
        
        try {
            // Always include the org ID for proper prioritization
            chrome.tabs.sendMessage(tabId, {
                action: 'environmentChange',
                environment: environment,
                orgId: orgId || this.detectedOrgId
            }, (response) => {
                if (chrome.runtime.lastError) {
                    log(`Tab ${tabId} not ready for environment message: ${chrome.runtime.lastError.message}`);
                } else if (response && response.success) {
                    log(`Tab ${tabId} acknowledged environment change notification`);
                }
            });
        } catch (error) {
            log(`Error notifying tab ${tabId}:`, error);
        }
    }
    
    /**
     * Send an environment change message to a tab (backup method)
     * @param {number} tabId - The tab ID to notify
     * @param {string} environment - The new environment
     * @param {string} orgId - The organization ID (optional)
     */
    sendEnvironmentChangeMessage(tabId, environment, orgId = null) {
        try {
            chrome.tabs.sendMessage(tabId, {
                action: 'environmentChange',
                environment: environment,
                orgId: orgId
            }, (response) => {
                if (chrome.runtime.lastError) {
                    // This is expected for tabs that don't have the content script (ignore it)
                    log(`Tab ${tabId} not ready for environment message: ${chrome.runtime.lastError.message}`);
                } else if (response && response.success) {
                    log(`Tab ${tabId} acknowledged environment change notification`);
                }
            });
        } catch (error) {
            log(`Error sending environment change to tab ${tabId}:`, error);
        }
    }

    /**
     * Set environment manually (override from popup)
     * @param {string} environment - The environment to set
     * @returns {Promise<boolean>} True if environment was set
     */
    async setEnvironmentManually(environment) {
        if (!environment || !['dr', 'test', 'dev'].includes(environment)) {
            log('Invalid environment specified for manual override:', environment);
            return false;
        }
        
        log(`Manually setting environment to: ${environment}`);
        
        const result = {
            environment,
            orgId: this.detectedOrgId, // Keep existing org ID if available
            method: DETECTION_METHODS.MANUAL_OVERRIDE.name,
            source: 'user-override',
            confidence: DETECTION_METHODS.MANUAL_OVERRIDE.confidence
        };
        
        // Always update for manual overrides (ignore confidence)
        await this.updateEnvironment(result);
        return true;
    }

    /**
     * Clear all environment detection data
     * @returns {Promise<boolean>} True if clear was successful
     */
    async clearEnvironmentData() {
        try {
            log('Clearing all environment detection data');
            
            // Clear memory
            this.currentEnvironment = null;
            this.detectedOrgId = null;
            this.lastDetectionMethod = null;
            this.lastDetectionSource = null;
            this.lastDetectionTime = null;
            this.processedUrls.clear();
            
            // Clear from storage
            await storageService.removeMultiple([
                'environmentType',
                'detectedOrgId',
                'detectionMethod',
                'detectionSource',
                'lastUpdated'
            ]);
            
            // Notify tabs
            this.notifyEnvironmentChange('unknown');
            
            return true;
        } catch (error) {
            log('Error clearing environment data:', error);
            return false;
        }
    }

    /**
     * Refresh environment detection
     * @returns {Promise<boolean>} True if refresh was triggered
     */
    async refreshEnvironmentDetection() {
        try {
            log('Triggering refresh of environment detection');
            
            // Get active tabs that might contain Genesys pages
            chrome.tabs.query({ 
                active: true,
                url: [
                    "*://*.pure.cloud/*",
                    "*://*.mypurecloud.com/*",
                    "*://*.genesys.cloud/*"
                ] 
            }, (tabs) => {
                // Check each active tab
                tabs.forEach(tab => {
                    // First check URL directly
                    this.checkUrlForEnvironment(tab.id, tab.url);
                    
                    // Then ask content script to perform a detection
                    chrome.tabs.sendMessage(tab.id, { 
                        action: 'redetectEnvironment'
                    }, (response) => {
                        if (chrome.runtime.lastError) {
                            // This can happen if content script isn't loaded (ignore)
                        } else if (response && response.success) {
                            log(`Tab ${tab.id} acknowledged redetection request`);
                        }
                    });
                });
            });
            
            return true;
        } catch (error) {
            log('Error refreshing environment detection:', error);
            return false;
        }
    }

    /**
     * Get the current environment detection state
     * @returns {object} The current state
     */
    getCurrentState() {
        return {
            environmentType: this.currentEnvironment,
            detectedOrgId: this.detectedOrgId,
            detectionMethod: this.lastDetectionMethod,
            detectionSource: this.lastDetectionSource,
            lastUpdated: this.lastDetectionTime
        };
    }

    /**
     * Process a detection result from content script polling or storage events
     * This is a critical method for handling immediate environment changes
     * @param {object} detectionResult - The detection result from content script
     * @param {number} tabId - The tab ID
     * @param {boolean} forceUpdate - Whether to force an update even if environment hasn't changed
     * @returns {Promise<boolean>} True if the environment was updated
     */
    async processDetectionResult(detectionResult, tabId = null, forceUpdate = false) {
        try {
            if (!detectionResult || !detectionResult.environment) {
                log('Invalid detection result:', detectionResult);
                return false;
            }
            
            log('Processing detection result:', detectionResult.environment, 
                'from', detectionResult.source, 'with org ID:', detectionResult.orgId);
                
            // Add tab ID to the result if not present
            if (tabId && !detectionResult.tabId) {
                detectionResult.tabId = tabId;
            }
            
            // Make sure environment is lowercase for consistent comparison
            detectionResult.environment = detectionResult.environment.toLowerCase();
            
            // Special case for PROD - if we get a prod detection, make sure it's recognized correctly
            if (detectionResult.environment === 'prod' && detectionResult.orgId) {
                log('Production environment detected with orgID:', detectionResult.orgId);
                
                // Instead of keeping old environment, force the update to PROD
                // since this detection comes directly from auth token changes
                this.currentEnvironment = null;
                
                // Log extra debugging
                log('Forcing environment update due to PROD detection');
            }
                
            // Check if this is the same environment we already have
            if (!forceUpdate && 
                this.currentEnvironment === detectionResult.environment && 
                (this.detectedOrgId === detectionResult.orgId || !detectionResult.orgId)) {
                
                log(`Same environment ${detectionResult.environment} already detected, skipping update`);
                
                // Even if it's the same environment, notify the tab to ensure UI is correct
                if (tabId) {
                    await this.notifyTab(tabId, detectionResult.environment, detectionResult.orgId);
                }
                
                return false;
            }
            
            // If this is a new environment, update it
            const updated = await this.updateEnvironment(detectionResult);
            
            if (updated) {
                log(`Updated environment to ${detectionResult.environment} from detection result`);
                
                // Notify all tabs about the environment change
                await this.notifyEnvironmentChange(
                    detectionResult.environment, 
                    detectionResult.orgId
                );
                
                return true;
            }
            
            return false;
        } catch (error) {
            log('Error processing detection result:', error);
            return false;
        }
    }
}

// Create and export a singleton instance
const environmentService = new EnvironmentService();
export default environmentService;