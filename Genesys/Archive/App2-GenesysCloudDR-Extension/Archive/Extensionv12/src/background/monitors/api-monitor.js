/**
 * API Monitor Module
 * Monitors API requests for organization ID and environment information
 */

import { log } from '../../shared/utils';
import { ORG_RELATED_ENDPOINTS } from '../../shared/constants';
import environmentService from '../environment-service';

class ApiMonitor {
    constructor() {
        this.initialized = false;
        this.processedUrls = new Set(); // Track processed API URLs to avoid duplicates
    }

    /**
     * Initialize the API monitor
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing API monitor');
            
            // Set up web request listener
            this.setupWebRequestListener();
            
            this.initialized = true;
            log('API monitor initialized');
            return true;
        } catch (error) {
            log('Error initializing API monitor:', error);
            return false;
        }
    }

    /**
     * Set up web request listener for Genesys Cloud APIs
     */
    setupWebRequestListener() {
        if (!chrome.webRequest) {
            log('Web request API not available, cannot monitor API requests');
            return;
        }

        // Listen for API responses that might contain organization information
        chrome.webRequest.onCompleted.addListener(
            this.handleApiResponse.bind(this),
            { 
                urls: [
                    '*://*.pure.cloud/api/v2/*',
                    '*://*.mypurecloud.com/api/v2/*',
                    '*://*.genesys.cloud/api/v2/*'
                ]
            }
        );

        log('Web request listener set up successfully');
    }

    /**
     * Handle completed API responses
     * @param {object} details - Web request details
     */
    handleApiResponse(details) {
        // Only check relevant endpoints and avoid duplicates
        const isRelevantEndpoint = ORG_RELATED_ENDPOINTS.some(endpoint => 
            details.url.includes(endpoint)
        );
        
        if (!isRelevantEndpoint || details.tabId === -1) {
            return;
        }
        
        // Add to processed URLs to avoid reprocessing
        const urlKey = details.url.split('?')[0];
        if (this.processedUrls.has(urlKey)) {
            return;
        }
        this.processedUrls.add(urlKey);
        
        log(`Relevant API response detected: ${urlKey} (Tab ID: ${details.tabId})`);
        
        // Inject script to check API results that should be in the page context
        setTimeout(() => {
            this.injectApiDetectionScript(details.tabId, details.url);
        }, 300);
    }

    /**
     * Inject script to verify API results contain target organization IDs
     * @param {number} tabId - The tab ID
     * @param {string} url - The API URL
     */
    injectApiDetectionScript(tabId, url) {
        if (tabId === -1) return;
        
        try {
            log(`Injecting API detection script into tab ${tabId} for URL ${url}`);
            
            chrome.scripting.executeScript({
                target: { tabId: tabId },
                func: () => {
                    // Send a message to the content script to extract org ID
                    chrome.runtime.sendMessage({
                        action: 'extractOrgIdFromPage',
                        source: 'api-response'
                    });
                }
            }).catch(error => {
                log(`Error injecting API detection script into tab ${tabId}:`, error);
            });
        } catch (error) {
            log(`Error setting up API detection script injection for tab ${tabId}:`, error);
        }
    }

    /**
     * Clean up old processed URLs to prevent memory leaks
     * URLs older than 1 hour will be removed
     */
    cleanupProcessedUrls() {
        // For now, we'll just clear everything if it gets too large
        if (this.processedUrls.size > 1000) {
            log(`Cleaning up processed URLs list (size: ${this.processedUrls.size})`);
            this.processedUrls.clear();
        }
    }

    /**
     * Get the count of processed URLs
     * @returns {number} Number of processed URLs
     */
    getProcessedUrlCount() {
        return this.processedUrls.size;
    }

    /**
     * Process an API response directly
     * @param {string} url - The API URL
     * @param {object|string} data - The response data
     * @param {number} [tabId] - Optional tab ID
     * @returns {Promise<boolean>} True if processing was successful
     */
    async processApiResponse(url, data, tabId = null) {
        try {
            // Simple approach: look for organization ID in the response data
            if (!data) {
                log('No API response data provided');
                return false;
            }
            
            // Check if data is a string or object
            const responseText = typeof data === 'string' ? data : JSON.stringify(data);
            
            // Extract organization ID if available in JSON format
            let orgId = null;
            try {
                if (typeof data === 'object' && data.organization && data.organization.id) {
                    orgId = data.organization.id;
                    log(`Found organization ID in API response object: ${orgId}`);
                } else if (typeof data === 'string') {
                    // Try to parse JSON
                    const jsonData = JSON.parse(data);
                    if (jsonData.organization && jsonData.organization.id) {
                        orgId = jsonData.organization.id;
                        log(`Found organization ID in parsed API response: ${orgId}`);
                    }
                }
            } catch (e) {
                // Not JSON or couldn't parse
                log('Could not extract organization ID from API response data');
            }
            
            // If we found an org ID, process it
            if (orgId) {
                const result = await environmentService.processOrganizationId(orgId, `api-response:${url}`, tabId);
                return !!result;
            }
            
            return false;
        } catch (error) {
            log('Error processing API response:', error);
            return false;
        }
    }
}

// Create and export a singleton instance
const apiMonitor = new ApiMonitor();
export default apiMonitor;