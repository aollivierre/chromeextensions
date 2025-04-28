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
    
    // Query current environment from storage
    safeStorageGet(['environmentType', 'detectedOrgId', 'detectionMethod', 'detectionSource', 'lastUpdated'], function(data) {
        log('Retrieved data from storage:', data);
        updatePopupContent(data);
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