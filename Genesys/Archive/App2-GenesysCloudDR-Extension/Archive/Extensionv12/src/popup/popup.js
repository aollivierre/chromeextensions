/**
 * Popup Script for Genesys Cloud Environment Badge Extension
 * Displays current environment information and allows manual refresh
 */

import { log } from '../shared/utils';

document.addEventListener('DOMContentLoaded', function() {
    // Get DOM elements
    const environmentBadge = document.getElementById('environment-badge');
    const orgIdElement = document.getElementById('org-id');
    const detectionMethodElement = document.getElementById('detection-method');
    const detectionSourceElement = document.getElementById('detection-source');
    const lastUpdatedElement = document.getElementById('last-updated');
    const refreshButton = document.getElementById('refresh-button');
    
    // Check current tab and load environment information
    checkCurrentTabAndLoadInfo();
    
    // Set up refresh button
    refreshButton.addEventListener('click', function() {
        refreshEnvironmentDetection();
    });
    
    /**
     * Check if current tab is a Genesys Cloud site and load appropriate info
     */
    function checkCurrentTabAndLoadInfo() {
        chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
            if (tabs.length === 0) {
                // No active tab found, show unknown
                updateUI({ environmentType: 'unknown' });
                return;
            }
            
            const currentTab = tabs[0];
            const url = currentTab.url || '';
            
            // Check if this is a Genesys Cloud URL
            const isGenesysCloudUrl = isGenesysCloud(url);
            
            if (isGenesysCloudUrl) {
                // This is a Genesys Cloud site, load environment info from storage
                loadEnvironmentInfo();
            } else {
                // Not a Genesys Cloud site, show unknown
                updateUI({
                    environmentType: 'unknown',
                    detectionMethod: 'Not applicable',
                    detectionSource: 'Not on Genesys Cloud site',
                    lastUpdated: new Date().toISOString()
                });
            }
        });
    }
    
    /**
     * Check if a URL is a Genesys Cloud URL
     * @param {string} url - The URL to check
     * @returns {boolean} True if URL is a Genesys Cloud URL
     */
    function isGenesysCloud(url) {
        try {
            const genesysCloudDomains = [
                'pure.cloud',
                'mypurecloud.com',
                'genesys.cloud'
            ];
            
            return genesysCloudDomains.some(domain => url.includes(domain));
        } catch (error) {
            console.error('Error checking if URL is Genesys Cloud URL:', error);
            return false;
        }
    }
    
    /**
     * Load environment information from storage
     */
    function loadEnvironmentInfo() {
        chrome.storage.sync.get([
            'environmentType',
            'detectedOrgId',
            'detectionMethod',
            'detectionSource',
            'lastUpdated'
        ], function(data) {
            updateUI(data);
        });
    }
    
    /**
     * Update UI with environment information
     */
    function updateUI(data) {
        // Update environment badge
        const environment = data.environmentType || 'unknown';
        environmentBadge.textContent = environment.toUpperCase();
        environmentBadge.className = 'badge ' + environment;
        
        // Update organization ID
        // For DR environment, org ID is not needed for detection
        if (environment === 'dr' && data.detectionMethod !== 'Organization ID') {
            orgIdElement.textContent = 'Not required for DR';
        } else if (data.detectedOrgId) {
            orgIdElement.textContent = data.detectedOrgId;
        } else {
            orgIdElement.textContent = 'Not detected';
        }
        
        // Update detection method
        if (data.detectionMethod) {
            detectionMethodElement.textContent = data.detectionMethod;
        } else {
            detectionMethodElement.textContent = 'Not detected';
        }
        
        // Update detection source
        if (data.detectionSource) {
            detectionSourceElement.textContent = data.detectionSource;
        } else {
            detectionSourceElement.textContent = 'Not detected';
        }
        
        // Update last updated time
        if (data.lastUpdated) {
            const date = new Date(data.lastUpdated);
            lastUpdatedElement.textContent = date.toLocaleString();
        } else {
            lastUpdatedElement.textContent = 'Never';
        }
    }
    
    /**
     * Trigger a refresh of environment detection
     */
    function refreshEnvironmentDetection() {
        // Get the active tab
        chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
            if (tabs.length === 0) {
                return;
            }
            
            const activeTab = tabs[0];
            
            // Send message to content script to redetect environment
            chrome.tabs.sendMessage(activeTab.id, { 
                action: 'redetectEnvironment' 
            }, function(response) {
                // Check for error (content script might not be loaded)
                if (chrome.runtime.lastError) {
                    log('Error sending message:', chrome.runtime.lastError);
                    
                    // Try sending message to background script instead
                    chrome.runtime.sendMessage({
                        action: 'refreshEnvironmentDetection',
                        tabId: activeTab.id
                    });
                }
                
                // Wait a moment for detection to complete
                setTimeout(function() {
                    checkCurrentTabAndLoadInfo();
                }, 500);
            });
        });
    }
});