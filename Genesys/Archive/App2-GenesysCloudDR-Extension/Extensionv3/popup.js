// Script for handling badge position and type selection

document.addEventListener('DOMContentLoaded', function() {
    // Get all UI elements
    const positionButtons = document.querySelectorAll('.position-button');
    const typeButtons = document.querySelectorAll('.type-button');
    
    // Load saved settings
    chrome.storage.sync.get(['badgePosition', 'badgeType'], function(data) {
        const savedPosition = data.badgePosition || 'top-right'; // Default position
        const savedType = data.badgeType || 'text'; // Default type
        
        // Mark the currently selected position
        positionButtons.forEach(button => {
            if (button.dataset.position === savedPosition) {
                button.classList.add('selected');
            }
        });
        
        // Mark the currently selected type
        typeButtons.forEach(button => {
            if (button.dataset.type === savedType) {
                button.classList.add('selected');
            }
        });
    });
    
    // Add click handlers to position buttons
    positionButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Remove selected class from all position buttons
            positionButtons.forEach(btn => btn.classList.remove('selected'));
            
            // Add selected class to clicked button
            button.classList.add('selected');
            
            // Save the selected position
            const position = button.dataset.position;
            chrome.storage.sync.set({ badgePosition: position }, function() {
                console.log('Position saved:', position);
                
                // Update all tabs
                updateAllTabs({ position: position });
            });
        });
    });
    
    // Add click handlers to type buttons
    typeButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Remove selected class from all type buttons
            typeButtons.forEach(btn => btn.classList.remove('selected'));
            
            // Add selected class to clicked button
            button.classList.add('selected');
            
            // Save the selected type
            const type = button.dataset.type;
            chrome.storage.sync.set({ badgeType: type }, function() {
                console.log('Type saved:', type);
                
                // Update all tabs
                updateAllTabs({ type: type });
            });
        });
    });
    
    // Function to update all relevant tabs
    function updateAllTabs(changes) {
        try {
            chrome.tabs.query({ url: [
                "https://login.mypurecloud.com/*",
                "https://*.mypurecloud.com/*"
            ]}, function(tabs) {
                if (tabs && tabs.length > 0) {
                    tabs.forEach(tab => {
                        try {
                            // Send message but don't expect a response
                            chrome.tabs.sendMessage(tab.id, { 
                                action: 'updateBadge',
                                changes: changes
                            }).catch(error => {
                                // Silently catch errors when content script isn't ready
                                console.log(`Tab ${tab.id} not ready: ${error.message}`);
                            });
                        } catch (err) {
                            // Suppress errors from individual tabs
                            console.log(`Error sending to tab ${tab.id}: ${err.message}`);
                        }
                    });
                } else {
                    console.log('No matching tabs found for updates');
                }
            });
        } catch (error) {
            console.log('Error in updateAllTabs:', error.message);
        }
    }
}); 