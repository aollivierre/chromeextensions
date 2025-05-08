/**
 * Tab Monitor Module
 * Monitors tab navigation and Genesys Cloud pages
 */

import { log } from '../../shared/utils';
import { GENESYS_CLOUD_DOMAINS } from '../../shared/patterns';
import environmentService from '../environment-service';

class TabMonitor {
    constructor() {
        this.initialized = false;
        this.trackedTabs = new Map(); // Track tabs with Genesys Cloud content
    }

    /**
     * Initialize the tab monitor
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing tab monitor');
            
            // Set up event listeners for tabs
            this.setupTabEventListeners();
            
            // Initial scan for existing tabs
            await this.scanExistingTabs();
            
            this.initialized = true;
            log('Tab monitor initialized');
            return true;
        } catch (error) {
            log('Error initializing tab monitor:', error);
            return false;
        }
    }

    /**
     * Set up event listeners for tab events
     */
    setupTabEventListeners() {
       // Listen for tab updates
       chrome.tabs.onUpdated.addListener(this.handleTabUpdated.bind(this));
       
       // Listen for tab removal
       chrome.tabs.onRemoved.addListener(this.handleTabRemoved.bind(this));
       
       // Listen for tab activation (user switches tab)
       chrome.tabs.onActivated.addListener(this.handleTabActivated.bind(this));
       
       log('Tab event listeners set up');
   }

   /**
    * Handle tab activation event (when user switches tabs)
    * @param {object} activeInfo - Information about the activated tab
    */
   handleTabActivated(activeInfo) {
       try {
           log(`Tab ${activeInfo.tabId} activated`);
           
           // Get the tab information
           chrome.tabs.get(activeInfo.tabId, (tab) => {
               if (chrome.runtime.lastError) {
                   log(`Error getting tab info: ${chrome.runtime.lastError.message}`);
                   return;
               }
               
               if (tab && tab.url) {
                   log(`Tab ${activeInfo.tabId} has URL: ${tab.url}`);
                   
                   // Process the tab immediately
                   this.processActivatedTab(tab.id, tab.url);
               }
           });
       } catch (error) {
           log(`Error handling tab activation: ${error}`);
       }
   }
   
   /**
    * Process an activated tab to immediately update the environment
    * @param {number} tabId - The tab ID
    * @param {string} url - The tab URL
    */
   processActivatedTab(tabId, url) {
       const isGenesysCloudUrl = this.isGenesysCloudUrl(url);
       
       if (isGenesysCloudUrl) {
           log(`Activated tab ${tabId} has Genesys Cloud URL: ${url}`);
           
           // Track this tab
           this.trackTab(tabId, url);
           
           // Immediately check URL for environment indicators and update the badge
           environmentService.checkUrlForEnvironment(tabId, url);
           
           // Inject detection script to extract organization ID
           if (!url.includes('/api/v2/')) {
               setTimeout(() => {
                   this.injectDetectionScript(tabId, url);
               }, 100);
           }
           
           // Notify the tab even if we don't detect a change, to ensure badge is displayed
           setTimeout(() => {
               const currentEnv = environmentService.getCurrentState().environment;
               if (currentEnv) {
                   environmentService.notifyTab(tabId, currentEnv);
               }
           }, 200);
       }
   }

    /**
     * Scan existing tabs for Genesys Cloud content
     * @returns {Promise<void>}
     */
    async scanExistingTabs() {
        return new Promise((resolve) => {
            // Query for existing Genesys Cloud tabs
            chrome.tabs.query({ 
                url: GENESYS_CLOUD_DOMAINS.map(domain => `*://*.${domain}/*`)
            }, (tabs) => {
                log(`Found ${tabs.length} existing Genesys Cloud tabs`);
                
                // Process each tab
                tabs.forEach(tab => {
                    this.trackTab(tab.id, tab.url);
                    environmentService.checkUrlForEnvironment(tab.id, tab.url);
                });
                
                resolve();
            });
        });
    }

    /**
     * Handle tab updated event
     * @param {number} tabId - The tab ID
     * @param {object} changeInfo - Information about the change
     * @param {object} tab - The tab object
     */
    handleTabUpdated(tabId, changeInfo, tab) {
        // Check if URL has changed in this update
        const urlChanged = changeInfo.url !== undefined;
        
        // Process URL changes or complete loads
        if ((urlChanged || changeInfo.status === 'complete') && tab.url) {
            const isGenesysCloudUrl = this.isGenesysCloudUrl(tab.url);
            
            if (isGenesysCloudUrl) {
                // Check if this is a URL change for an already tracked tab
                const isExistingTab = this.trackedTabs.has(tabId);
                const oldUrl = isExistingTab ? this.trackedTabs.get(tabId).url : null;
                const isNewUrl = oldUrl !== tab.url;
                
                if (isNewUrl) {
                    log(`Tab ${tabId} URL changed from ${oldUrl} to ${tab.url}`);
                } else {
                    log(`Tab ${tabId} updated with Genesys Cloud URL: ${tab.url}`);
                }
                
                // Track this tab
                this.trackTab(tabId, tab.url);
                
                // For bookmark navigation, we need to force a complete environment reset
                // This ensures we don't keep the old environment when navigating between environments
                if (isNewUrl && changeInfo.status === 'loading') {
                    log(`Potential bookmark navigation detected, forcing environment reset for tab ${tabId}`);
                    // Clear any cached environment data for this tab
                    environmentService.clearTabEnvironmentCache(tabId);
                }
                
                // Always check URL for environment indicators on any URL change
                // This is critical for bookmark navigation
                environmentService.checkUrlForEnvironment(tabId, tab.url);
                
                // Inject detection script for any Genesys Cloud page that's not an API URL
                // This ensures we detect org IDs after bookmark navigation
                if (!tab.url.includes('/api/v2/')) {
                    // Use a shorter timeout for URL changes to make detection faster
                    const timeout = urlChanged ? 100 : 1000;
                    setTimeout(() => {
                        this.injectDetectionScript(tabId, tab.url);
                    }, timeout);
                }
                
                // For bookmark navigation or URL changes, explicitly notify the tab
                // to ensure the badge is updated
                if (urlChanged || isNewUrl) {
                    // Use a longer timeout to ensure environment detection completes
                    setTimeout(() => {
                        const currentEnv = environmentService.getCurrentState().environment;
                        if (currentEnv) {
                            environmentService.notifyTab(tabId, currentEnv);
                        }
                    }, 500);
                }
            } else if (this.trackedTabs.has(tabId)) {
                // Tab was previously a Genesys Cloud tab but is no longer
                log(`Tab ${tabId} no longer has Genesys Cloud URL: ${tab.url}`);
                this.trackedTabs.delete(tabId);
            }
        }
    }

    /**
     * Handle tab removed event
     * @param {number} tabId - The tab ID
     */
    handleTabRemoved(tabId) {
        if (this.trackedTabs.has(tabId)) {
            log(`Tracked tab ${tabId} was closed`);
            this.trackedTabs.delete(tabId);
        }
    }

    /**
     * Track a tab with Genesys Cloud content
     * @param {number} tabId - The tab ID
     * @param {string} url - The tab URL
     */
    trackTab(tabId, url) {
        this.trackedTabs.set(tabId, {
            url: url,
            lastChecked: Date.now()
        });
        
        log(`Now tracking tab ${tabId} with URL: ${url}`);
    }

    /**
     * Check if a URL is a Genesys Cloud URL
     * @param {string} url - The URL to check
     * @returns {boolean} True if URL is a Genesys Cloud URL
     */
    isGenesysCloudUrl(url) {
        try {
            return GENESYS_CLOUD_DOMAINS.some(domain => url.includes(domain));
        } catch (error) {
            log('Error checking if URL is Genesys Cloud URL:', error);
            return false;
        }
    }

    /**
     * Inject detection script into a tab
     * @param {number} tabId - The tab ID
     * @param {string} url - The tab URL
     */
    injectDetectionScript(tabId, url) {
        try {
            // Skip invalid tab IDs
            if (tabId === -1) return;
            
            log(`Injecting detection script into tab ${tabId}`);
            
            // Use the chrome.scripting API to inject a script that directly extracts org IDs
            chrome.scripting.executeScript({
                target: { tabId: tabId },
                func: () => {
                    // Import organization mappings
                    const ORGANIZATION_MAPPINGS = {
                        "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test",
                        "c8548bdb-bad5-4fc2-9d77-2d6a54aac157": "dr",
                        "a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a": "dev"
                    };
                    
                    // Check localStorage for organization IDs
                    let foundOrgId = null;
                    let foundSource = null;
                    
                    // Check localStorage
                    for (let i = 0; i < localStorage.length; i++) {
                        const key = localStorage.key(i);
                        const value = localStorage.getItem(key);
                        
                        // Check each known organization ID
                        for (const orgId of Object.keys(ORGANIZATION_MAPPINGS)) {
                            if (value && value.includes(orgId)) {
                                foundOrgId = orgId;
                                foundSource = `localStorage:${key}`;
                                break;
                            }
                        }
                        
                        if (foundOrgId) break;
                    }
                    
                    // If found, send directly to background script
                    if (foundOrgId) {
                        chrome.runtime.sendMessage({
                            action: 'reportOrganizationId',
                            orgId: foundOrgId,
                            source: foundSource || 'direct-extraction'
                        });
                    } else {
                        // Also try to send a message to the content script as backup
                        chrome.runtime.sendMessage({
                            action: 'extractOrgIdFromPage'
                        });
                    }
                }
            }).catch(error => {
                log(`Error injecting script into tab ${tabId}:`, error);
            });
        } catch (error) {
            log(`Error setting up script injection for tab ${tabId}:`, error);
        }
    }

    /**
     * Get all currently tracked tabs
     * @returns {Map} Map of tracked tabs
     */
    getTrackedTabs() {
        return this.trackedTabs;
    }

    /**
     * Refresh environment detection for all tracked tabs
     */
    refreshAllTabs() {
        for (const [tabId, tabInfo] of this.trackedTabs.entries()) {
            log(`Refreshing environment detection for tab ${tabId}`);
            
            // Check URL again
            environmentService.checkUrlForEnvironment(tabId, tabInfo.url);
            
            // Ask content script to redetect environment
            try {
                chrome.tabs.sendMessage(tabId, { 
                    action: 'redetectEnvironment'
                }, (response) => {
                    if (chrome.runtime.lastError) {
                        // This can happen if content script isn't loaded (ignore)
                    } else {
                        log(`Tab ${tabId} acknowledged refresh request`);
                    }
                });
            } catch (error) {
                log(`Error sending refresh message to tab ${tabId}:`, error);
            }
            
            // Update last checked time
            tabInfo.lastChecked = Date.now();
        }
    }
}

// Create and export a singleton instance
const tabMonitor = new TabMonitor();
export default tabMonitor;