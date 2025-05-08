/**
 * Background Messaging Service
 * Handles communication between content scripts, popup, and background script
 */

import { log } from '../shared/utils';
import environmentService from './environment-service';
import storageService from './storage-service';

class MessagingService {
    constructor() {
        this.initialized = false;
        this.messageHandlers = {};
    }

    /**
     * Initialize the messaging service
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing messaging service');
            
            // Set up message handlers
            this.registerMessageHandlers();
            
            // Set up message listener
            this.setupMessageListener();
            
            this.initialized = true;
            log('Messaging service initialized');
            return true;
        } catch (error) {
            log('Error initializing messaging service:', error);
            return false;
        }
    }

    /**
     * Register all message handlers
     */
    registerMessageHandlers() {
        // Get current environment information
        this.registerHandler('getCurrentEnvironment', this.handleGetCurrentEnvironment.bind(this));
        
        // Set environment manually (from popup)
        this.registerHandler('setEnvironmentType', this.handleSetEnvironmentType.bind(this));
        
        // Clear environment detection data
        this.registerHandler('clearEnvironmentDetection', this.handleClearEnvironmentDetection.bind(this));
        
        // Refresh environment detection
        this.registerHandler('refreshEnvironmentDetection', this.handleRefreshEnvironmentDetection.bind(this));
        
        // Process organization ID from content script
        this.registerHandler('reportOrganizationId', this.handleReportOrganizationId.bind(this));
        
        // Strong DR pattern detected by content script
        this.registerHandler('strongDrPatternDetected', this.handleStrongDrPatternDetected.bind(this));
        
        // Check a specific URL for environment indicators
        this.registerHandler('checkSpecificUrl', this.handleCheckSpecificUrl.bind(this));
        
        // Sync storage data
        this.registerHandler('syncStorageData', this.handleSyncStorageData.bind(this));
        
        // Check API response for org ID
        this.registerHandler('checkApiResponse', this.handleCheckApiResponse.bind(this));
        
        // Check organization ID
        this.registerHandler('checkOrganizationId', this.handleCheckOrganizationId.bind(this));
        
        // NEW: Handle environment change detected by polling
        this.registerHandler('environmentDetectedPoll', this.handleEnvironmentDetectedPoll.bind(this));
        
        // NEW: Handle direct environment change notification
        this.registerHandler('environmentChanged', this.handleEnvironmentChanged.bind(this));
        
        // NEW: Handle auth token changed notification
        this.registerHandler('authTokenChanged', this.handleAuthTokenChanged.bind(this));
    }

    /**
     * Register a message handler
     * @param {string} action - The action to handle
     * @param {function} handler - The handler function
     */
    registerHandler(action, handler) {
        this.messageHandlers[action] = handler;
        log(`Registered message handler for action: ${action}`);
    }

    /**
     * Set up Chrome runtime message listener
     */
    setupMessageListener() {
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            this.handleMessage(message, sender, sendResponse);
            return true; // Keep the message channel open for async responses
        });
    }

    /**
     * Handle an incoming message
     * @param {object} message - The message
     * @param {object} sender - The sender
     * @param {function} sendResponse - The response function
     */
    async handleMessage(message, sender, sendResponse) {
        try {
            const { action } = message;
            
            if (!action) {
                log('Received message without action:', message);
                sendResponse({ success: false, error: 'No action specified' });
                return;
            }
            
            log(`Received message with action: ${action}`, message);
            
            // Find the appropriate handler
            const handler = this.messageHandlers[action];
            
            if (!handler) {
                log(`No handler found for action: ${action}`);
                sendResponse({ success: false, error: `Unknown action: ${action}` });
                return;
            }
            
            // Call the handler
            const result = await handler(message, sender);
            sendResponse(result);
        } catch (error) {
            log('Error handling message:', error);
            sendResponse({ success: false, error: error.message });
        }
    }

    /**
     * Handle getCurrentEnvironment message
     * @param {object} message - The message
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleGetCurrentEnvironment(message, sender) {
        const state = environmentService.getCurrentState();
        
        // If message includes URL, also check it
        if (message.url) {
            const tabId = sender.tab ? sender.tab.id : null;
            await environmentService.checkUrlForEnvironment(tabId, message.url);
            
            // Get updated state after URL check
            const updatedState = environmentService.getCurrentState();
            return updatedState;
        }
        
        return state;
    }

    /**
     * Handle setEnvironmentType message
     * @param {object} message - The message
     * @returns {object} The response
     */
    async handleSetEnvironmentType(message) {
        const success = await environmentService.setEnvironmentManually(message.environmentType);
        
        if (success) {
            return { 
                success: true, 
                environment: message.environmentType,
                message: `Environment manually set to ${message.environmentType}`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to set environment manually'
            };
        }
    }

    /**
     * Handle clearEnvironmentDetection message
     * @returns {object} The response
     */
    async handleClearEnvironmentDetection() {
        const success = await environmentService.clearEnvironmentData();
        
        if (success) {
            return { 
                success: true, 
                message: 'Environment detection data cleared'
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to clear environment detection data'
            };
        }
    }

    /**
     * Handle refreshEnvironmentDetection message
     * @returns {object} The response
     */
    async handleRefreshEnvironmentDetection() {
        const success = await environmentService.refreshEnvironmentDetection();
        
        if (success) {
            return { 
                success: true, 
                message: 'Environment detection refresh triggered'
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to trigger environment detection refresh'
            };
        }
    }

    /**
     * Handle reportOrganizationId message
     * @param {object} message - The message
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleReportOrganizationId(message, sender) {
        const { orgId, source } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        const result = await environmentService.processOrganizationId(orgId, source, tabId);
        
        if (result) {
            return { 
                success: true, 
                environment: result.environment,
                message: `Organization ID processed successfully, environment: ${result.environment}`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to process organization ID'
            };
        }
    }

    /**
     * Handle strongDrPatternDetected message
     * @param {object} message - The message
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleStrongDrPatternDetected(message, sender) {
        const { pattern, url } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        log(`Strong DR pattern detected in tab ${tabId}: ${pattern} (${url})`);
        
        // This should trigger DR environment detection
        const result = await environmentService.checkUrlForEnvironment(tabId, url);
        
        if (result && result.environment === 'dr') {
            return { 
                success: true, 
                environment: 'dr',
                message: `Strong DR pattern processed successfully`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to process strong DR pattern'
            };
        }
    }

    /**
     * Handle checkSpecificUrl message
     * @param {object} message - The message
     * @returns {object} The response
     */
    async handleCheckSpecificUrl(message) {
        const { url, tabId } = message;
        
        const result = await environmentService.checkUrlForEnvironment(tabId, url);
        
        if (result) {
            return { 
                success: true, 
                environment: result.environment,
                method: result.method,
                source: result.source,
                message: `URL checked successfully, environment: ${result.environment}`
            };
        } else {
            return { 
                success: true, 
                message: 'URL checked, no environment indicators found'
            };
        }
    }

    /**
     * Handle syncStorageData message
     * @param {object} message - The message
     * @returns {object} The response
     */
    async handleSyncStorageData(message) {
        const { data } = message;
        
        if (!data || typeof data !== 'object') {
            return { 
                success: false, 
                error: 'Invalid data for storage sync'
            };
        }
        
        const success = await storageService.setMultiple(data);
        
        if (success) {
            return { 
                success: true, 
                message: 'Storage data synced successfully'
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to sync storage data'
            };
        }
    }

    /**
     * Handle checkApiResponse message
     * @param {object} message - The message
     * @returns {object} The response
     */
    async handleCheckApiResponse(message) {
        const { data, url } = message;
        
        try {
            // Simple approach: look for organization ID in the response data
            if (!data) {
                return { success: false, error: 'No API response data provided' };
            }
            
            // Check if data is a string or object
            const responseText = typeof data === 'string' ? data : JSON.stringify(data);
            
            // Check for each known organization ID
            for (const orgId of Object.keys(environmentService.ORGANIZATION_MAPPINGS)) {
                if (responseText.includes(orgId)) {
                    log(`Found organization ID ${orgId} in API response`);
                    
                    const result = await environmentService.processOrganizationId(orgId, `api-response:${url}`);
                    
                    if (result) {
                        return { 
                            success: true, 
                            environment: result.environment,
                            orgId: orgId,
                            message: `Found organization ID in API response, environment: ${result.environment}`
                        };
                    }
                }
            }
            
            return { 
                success: true, 
                message: 'API response checked, no known organization IDs found'
            };
        } catch (error) {
            log('Error checking API response:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Handle checkOrganizationId message
     * @param {object} message - The message
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleCheckOrganizationId(message, sender) {
        const { orgId, source } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        const result = await environmentService.processOrganizationId(orgId, source, tabId);
        
        if (result) {
            return { 
                success: true, 
                environment: result.environment,
                message: `Organization ID processed successfully, environment: ${result.environment}`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to process organization ID'
            };
        }
    }

    /**
     * Handle environmentDetectedPoll message
     * @param {object} message - The message with the detection result
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleEnvironmentDetectedPoll(message, sender) {
        const { result } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        if (!result || !result.environment) {
            return { 
                success: false, 
                error: 'Invalid environment detection result'
            };
        }
        
        log('Received environment detection poll result:', result.environment, 'for org ID:', result.orgId);
        
        // Process the environment detection result
        const processResult = await environmentService.processDetectionResult(result, tabId);
        
        if (processResult) {
            return { 
                success: true, 
                environment: result.environment,
                message: `Environment poll processed successfully, environment: ${result.environment}`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to process environment detection poll'
            };
        }
    }

    /**
     * Handle environmentChanged message
     * @param {object} message - The message with the detection result
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleEnvironmentChanged(message, sender) {
        const { result, forceRefresh } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        if (!result || !result.environment) {
            return { 
                success: false, 
                error: 'Invalid environment change result'
            };
        }
        
        log('Received environment change notification:', result.environment, 'for org ID:', result.orgId);
        
        // Force an environment update because this is from a storage event
        // which indicates a definitive change
        const processResult = await environmentService.processDetectionResult(
            result, 
            tabId, 
            forceRefresh || false  // Use forceRefresh flag if provided
        );
        
        if (processResult) {
            return { 
                success: true, 
                environment: result.environment,
                message: `Environment change processed successfully, environment: ${result.environment}`
            };
        } else {
            return { 
                success: false, 
                error: 'Failed to process environment change'
            };
        }
    }

    /**
     * Handle authTokenChanged message
     * @param {object} message - The message with auth token information
     * @param {object} sender - The sender
     * @returns {object} The response
     */
    async handleAuthTokenChanged(message, sender) {
        const { hasToken } = message;
        const tabId = sender.tab ? sender.tab.id : null;
        
        log('Received auth token changed notification. Token present:', hasToken);
        
        // When auth token changes, we should force a refresh of the environment detection
        const refreshResult = await environmentService.refreshEnvironmentDetection();
        
        if (refreshResult) {
            return { 
                success: true, 
                message: `Auth token change triggered environment refresh`
            };
        } else {
            // If the refresh wasn't successful, clear the environment data
            // This is important for handling logout/token removal
            if (!hasToken) {
                log('Auth token removed - clearing environment data');
                await environmentService.clearEnvironmentData();
                
                // Ensure badge is updated to unknown
                if (tabId) {
                    chrome.tabs.sendMessage(tabId, {
                        action: 'updateBadge',
                        environment: 'unknown'
                    });
                }
            }
            
            return { 
                success: true, 
                message: 'Handled token change with fallback'
            };
        }
    }
}

// Create and export a singleton instance
const messagingService = new MessagingService();
export default messagingService;