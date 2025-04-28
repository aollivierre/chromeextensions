// Environment extension popup script

// Environment configurations
const ENVIRONMENTS = {
    dr: {
        name: "DR",
        color: "#ff0000", // Red
        textColor: "#ffffff",
        description: "Disaster Recovery Environment"
    },
    test: {
        name: "TEST",
        color: "#d4a017", // Muted/darker yellow (amber)
        textColor: "#000000",
        description: "Test Environment"
    },
    dev: {
        name: "DEV",
        color: "#0066cc", // Blue
        textColor: "#ffffff",
        description: "Development Environment"
    },
    unknown: {
        name: "Unknown",
        color: "#808080", // Gray
        textColor: "#ffffff",
        description: "Environment Not Detected"
    }
};

// Debugging toggle
const DEBUG = true;

// Logging function
function log(...args) {
    if (DEBUG) {
        console.log('[Environment Extension]', ...args);
    }
}

// Safe storage access helper function
function safeStorageGet(keys, callback) {
    try {
        if (chrome.storage && chrome.storage.sync) {
            chrome.storage.sync.get(keys, function(data) {
                if (chrome.runtime.lastError) {
                    log('Error accessing storage:', chrome.runtime.lastError);
                    callback({});
                } else {
                    callback(data);
                }
            });
        } else {
            log('Chrome storage API not available');
            callback({});
        }
    } catch (error) {
        log('Error accessing chrome.storage.sync:', error);
        callback({});
    }
}

// Initialize popup
document.addEventListener('DOMContentLoaded', function() {
    log('Popup loaded');
    
    // First, check the active tab for the current URL
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        const activeTab = tabs[0];
        if (!activeTab) {
            log('No active tab found');
            
            // Fall back to storage
            getEnvironmentFromStorage();
            return;
        }
        
        log('Active tab URL:', activeTab.url);
        
        // Check if this is a Genesys Cloud URL
        if (activeTab.url.includes('pure.cloud') || 
            activeTab.url.includes('mypurecloud.com') || 
            activeTab.url.includes('genesys.cloud')) {
            
            // First check for strong URL patterns that would override storage
            checkUrlForEnvironmentPatterns(activeTab.url, function(detectedEnv) {
                if (detectedEnv) {
                    log('Environment detected from URL patterns:', detectedEnv);
                    
                    // Create data object with URL-based detection
                    const data = {
                        environmentType: detectedEnv,
                        detectedOrgId: null,
                        detectionMethod: 'URL Pattern',
                        detectionSource: 'popup-url-check',
                        lastUpdated: new Date().toISOString()
                    };
                    
                    // Update popup with URL pattern based environment
                    updatePopupContent(data);
                    
                    // Optionally, also check storage for additional details 
                    // like Org ID that might not be in the URL
                    safeStorageGet(['detectedOrgId'], function(storageData) {
                        if (storageData.detectedOrgId) {
                            data.detectedOrgId = storageData.detectedOrgId;
                            updatePopupContent(data);
                        }
                    });
                } else {
                    // If no strong URL patterns, fall back to storage
                    getEnvironmentFromStorage();
                }
            });
        } else {
            // Not a Genesys Cloud URL, fall back to storage
            getEnvironmentFromStorage();
        }
    });
    
    // Set up environment override buttons
    setupEnvironmentButtons();
    
    // Set up refresh button
    document.getElementById('refresh-button').addEventListener('click', function() {
        log('Refresh clicked');
        refreshEnvironmentDetection();
    });
    
    // Set up clear button
    document.getElementById('clear-button').addEventListener('click', function() {
        log('Clear clicked');
        clearEnvironmentDetection();
    });
});

// Check URL for environment patterns
function checkUrlForEnvironmentPatterns(url, callback) {
    if (!url) {
        callback(null);
        return;
    }
    
    const urlLower = url.toLowerCase();
    
    // Check for strong DR patterns first
    const strongDrPatterns = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];
    const hasDrPattern = strongDrPatterns.some(pattern => urlLower.includes(pattern));
    
    if (hasDrPattern) {
        callback('dr');
        return;
    }
    
    // Check for strong TEST patterns
    const strongTestPatterns = ['.test.', '-test-', 'wawanesa-test'];
    const hasTestPattern = strongTestPatterns.some(pattern => urlLower.includes(pattern));
    
    if (hasTestPattern) {
        callback('test');
        return;
    }
    
    // No strong patterns found
    callback(null);
}

// Get environment from storage
function getEnvironmentFromStorage() {
    log('Getting environment from storage');
    
    // Query current environment from storage
    safeStorageGet(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], function(data) {
        log('Retrieved data from storage:', data);
        updatePopupContent(data);
    });
}

// Update popup content with current environment information
function updatePopupContent(data) {
    const environment = data.environmentType || 'unknown';
    const orgId = data.detectedOrgId || 'Not detected';
    const method = data.detectionMethod || 'None';
    const source = data.detectionSource || 'None';
    const timestamp = data.lastUpdated ? new Date(data.lastUpdated).toLocaleString() : 'Never';
    
    // Get confidence value from detection method if available
    let confidence = 'N/A';
    if (method === 'Organization ID') {
        confidence = '95%';
    } else if (method === 'Hostname') {
        confidence = '95%';
    } else if (method === 'API Endpoint') {
        confidence = '90%';
    } else if (method === 'URL Pattern') {
        confidence = '85%';
    } else if (method === 'Page Title') {
        confidence = '80%';
    } else if (method === 'Manual Override') {
        confidence = '100%';
    }
    
    // Update environment info
    const envConfig = ENVIRONMENTS[environment] || ENVIRONMENTS.unknown;
    
    // Update header
    const header = document.getElementById('env-header');
    header.textContent = envConfig.name;
    header.style.backgroundColor = envConfig.color;
    header.style.color = envConfig.textColor;
    
    // Update description
    document.getElementById('env-description').textContent = envConfig.description;
    
    // Update details
    const orgIdElement = document.getElementById('env-org-id');
    orgIdElement.textContent = orgId;
    
    // Add copy functionality for org ID
    if (orgId && orgId !== 'Not detected') {
        orgIdElement.style.cursor = 'pointer';
        orgIdElement.title = 'Click to copy organization ID';
        orgIdElement.addEventListener('click', function() {
            navigator.clipboard.writeText(orgId).then(function() {
                document.getElementById('status-message').textContent = 'Organization ID copied to clipboard';
                setTimeout(function() {
                    document.getElementById('status-message').textContent = '';
                }, 2000);
            }).catch(function(err) {
                log('Failed to copy text: ', err);
                document.getElementById('status-message').textContent = 'Failed to copy to clipboard';
                setTimeout(function() {
                    document.getElementById('status-message').textContent = '';
                }, 2000);
            });
        });
    } else {
        orgIdElement.style.cursor = 'default';
        orgIdElement.title = '';
    }
    
    document.getElementById('env-detection-method').textContent = method;
    document.getElementById('env-confidence').textContent = confidence;
    document.getElementById('env-detection-source').textContent = source;
    document.getElementById('env-last-updated').textContent = timestamp;
    
    // Highlight the active environment button
    const buttons = document.querySelectorAll('.env-button');
    buttons.forEach(button => {
        if (button.dataset.env === environment) {
            button.classList.add('active');
        } else {
            button.classList.remove('active');
        }
    });
}

// Set up environment override buttons
function setupEnvironmentButtons() {
    const buttons = document.querySelectorAll('.env-button');
    
    buttons.forEach(button => {
        const env = button.dataset.env;
        
        // Apply environment styling
        if (ENVIRONMENTS[env]) {
            button.style.backgroundColor = ENVIRONMENTS[env].color;
            button.style.color = ENVIRONMENTS[env].textColor;
        }
        
        // Add click event
        button.addEventListener('click', function() {
            log(`Environment button clicked: ${env}`);
            setEnvironment(env);
        });
    });
}

// Set environment manually
function setEnvironment(environment) {
    // Skip if unknown
    if (environment === 'unknown') {
        log('Cannot manually set to unknown');
        return;
    }
    
    log(`Manually setting environment to: ${environment}`);
    
    // Notify background script to set environment
    try {
        chrome.runtime.sendMessage({
            action: 'setEnvironmentType',
            environmentType: environment
        }, function(response) {
            if (chrome.runtime.lastError) {
                log('Error communicating with background:', chrome.runtime.lastError);
                return;
            }
            
            log('Background script response:', response);
            
            // Refresh popup content
            safeStorageGet(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], function(data) {
                updatePopupContent(data);
            });
        });
    } catch (error) {
        log('Error sending message to background:', error);
    }
}

// Refresh environment detection
function refreshEnvironmentDetection() {
    log('Triggering refresh of environment detection');
    
    // Show loading state
    document.getElementById('status-message').textContent = 'Refreshing...';
    
    // First check the current tab's URL
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        const activeTab = tabs[0];
        if (!activeTab) {
            log('No active tab found during refresh');
            
            // Fall back to standard refresh through background
            standardRefresh();
            return;
        }
        
        log('Refresh - Active tab URL:', activeTab.url);
        
        // For Genesys Cloud URLs, check for strong patterns first
        if (activeTab.url.includes('pure.cloud') || 
            activeTab.url.includes('mypurecloud.com') || 
            activeTab.url.includes('genesys.cloud')) {
            
            // Tell the background script to check this specific URL
            chrome.runtime.sendMessage({
                action: 'checkSpecificUrl',
                url: activeTab.url,
                tabId: activeTab.id
            }, function(response) {
                log('URL check response:', response);
                
                // Get updated environment data from either URL check or storage
                checkUrlForEnvironmentPatterns(activeTab.url, function(detectedEnv) {
                    if (detectedEnv) {
                        log('Environment detected from URL during refresh:', detectedEnv);
                        
                        const data = {
                            environmentType: detectedEnv,
                            detectionMethod: 'URL Pattern',
                            detectionSource: 'popup-refresh-url-check',
                            lastUpdated: new Date().toISOString()
                        };
                        
                        // Update popup UI
                        updatePopupContent(data);
                        document.getElementById('status-message').textContent = 'Refreshed from URL';
                        
                        setTimeout(function() {
                            document.getElementById('status-message').textContent = '';
                        }, 2000);
                    } else {
                        // Fall back to standard refresh if no URL pattern
                        standardRefresh();
                    }
                });
            });
        } else {
            // Not a Genesys Cloud URL, use standard refresh
            standardRefresh();
        }
    });
}

// Standard refresh through background script
function standardRefresh() {
    // Ask background script to refresh detection
    chrome.runtime.sendMessage({
        action: 'refreshEnvironmentDetection'
    }, function(response) {
        log('Background script response:', response);
        
        if (response && response.success) {
            document.getElementById('status-message').textContent = 'Detection refreshed';
            
            // Get updated data
            setTimeout(function() {
                safeStorageGet(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], function(data) {
                    updatePopupContent(data);
                    document.getElementById('status-message').textContent = '';
                });
            }, 500);
        } else {
            document.getElementById('status-message').textContent = response?.message || 'Refresh failed';
            setTimeout(function() {
                document.getElementById('status-message').textContent = '';
            }, 2000);
        }
    });
}

// Clear environment detection
function clearEnvironmentDetection() {
    log('Clearing environment detection data');
    
    // Show loading state
    document.getElementById('status-message').textContent = 'Clearing...';
    
    // Request background script to clear data
    chrome.runtime.sendMessage({
        action: 'clearEnvironmentDetection'
    }, function(response) {
        log('Background script response:', response);
        
        if (response && response.success) {
            document.getElementById('status-message').textContent = 'Data cleared';
            
            // Reset UI
            updatePopupContent({});
            
            setTimeout(function() {
                document.getElementById('status-message').textContent = '';
            }, 2000);
        } else {
            document.getElementById('status-message').textContent = 'Clear failed';
            setTimeout(function() {
                document.getElementById('status-message').textContent = '';
            }, 2000);
        }
    });
} 