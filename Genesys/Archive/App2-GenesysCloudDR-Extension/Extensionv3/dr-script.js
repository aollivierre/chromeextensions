// DR environment indicator with customizable settings
(function() {
    // Store the badge elements globally within this script
    let textBadge = null;
    let dotBadge = null;
    let activeBadgeType = 'text'; // Default to text badge
    
    function createOrUpdateBadges() {
        console.log('DR Environment Extension: Creating/updating badges...');
        
        // Remove any existing indicators
        removeExistingBadges();
        
        // Create both badge types
        createTextBadge();
        createDotBadge();
        
        // Load saved settings
        chrome.storage.sync.get(['badgePosition', 'badgeType'], function(data) {
            const position = data.badgePosition || 'top-right';
            activeBadgeType = data.badgeType || 'text';
            
            console.log('DR Extension: Loaded settings - Position:', position, 'Type:', activeBadgeType);
            
            // Update badges with saved settings
            setPositionStyles(position);
            showActiveBadge();
            
            // Wait for body to be available
            waitForBodyThenAttach();
        });
    }
    
    function removeExistingBadges() {
        const existingTextBadge = document.getElementById('dr-text-badge');
        if (existingTextBadge) {
            existingTextBadge.remove();
        }
        
        const existingDotBadge = document.getElementById('dr-dot-badge');
        if (existingDotBadge) {
            existingDotBadge.remove();
        }
    }
    
    function createTextBadge() {
        // Create the text badge
        textBadge = document.createElement('div');
        textBadge.id = 'dr-text-badge';
        textBadge.innerText = 'DR ORGANIZATION';
        
        // Apply base styles inline
        textBadge.style.cssText = `
            position: fixed;
            background-color: rgba(255, 0, 0, 0.8);
            color: white;
            font-weight: bold;
            font-size: 12px;
            padding: 5px 10px;
            border-radius: 5px;
            box-shadow: 0 0 5px rgba(255,0,0,0.5);
            z-index: 2147483647;
            pointer-events: none;
            opacity: 1;
            text-shadow: 1px 1px 1px rgba(0,0,0,0.5);
            display: none;
        `;
    }
    
    function createDotBadge() {
        // Create the dot badge (pulsing indicator)
        dotBadge = document.createElement('div');
        dotBadge.id = 'dr-dot-badge';
        
        // Apply styles for the dot
        dotBadge.style.cssText = `
            position: fixed;
            background-color: rgba(255, 0, 0, 0.8);
            width: 12px;
            height: 12px;
            border-radius: 50%;
            box-shadow: 0 0 5px rgba(255,0,0,0.5);
            z-index: 2147483647;
            pointer-events: none;
            display: none;
        `;
    }
    
    function waitForBodyThenAttach() {
        const waitForBody = setInterval(function() {
            if (document.body) {
                document.body.appendChild(textBadge);
                document.body.appendChild(dotBadge);
                console.log('DR Extension: Badges attached to document body');
                clearInterval(waitForBody);
                
                // Setup animations and effects
                setupBadgeEffects();
            }
        }, 50);
    }
    
    function setupBadgeEffects() {
        // For text badge - fade out after 5 seconds
        setTimeout(function() {
            textBadge.style.opacity = '0.4';
            textBadge.style.transition = 'opacity 0.5s ease-in-out';
        }, 5000);
        
        // For dot badge - setup pulsing animation
        startPulsingAnimation();
    }
    
    function startPulsingAnimation() {
        let opacity = 0.7;
        let increasing = false;
        
        setInterval(function() {
            if (increasing) {
                opacity += 0.03;
                if (opacity >= 0.9) {
                    increasing = false;
                }
            } else {
                opacity -= 0.03;
                if (opacity <= 0.4) {
                    increasing = true;
                }
            }
            
            if (dotBadge) {
                dotBadge.style.opacity = opacity;
            }
        }, 100);
    }
    
    function showActiveBadge() {
        if (activeBadgeType === 'text') {
            if (textBadge) textBadge.style.display = 'block';
            if (dotBadge) dotBadge.style.display = 'none';
        } else {
            if (textBadge) textBadge.style.display = 'none';
            if (dotBadge) dotBadge.style.display = 'block';
        }
        console.log('DR Extension: Active badge type set to', activeBadgeType);
    }
    
    function setPositionStyles(position) {
        // Define the position settings for both badges
        let posStyles = {
            top: 'auto',
            right: 'auto',
            bottom: 'auto',
            left: 'auto',
            transform: 'none'
        };
        
        // Set position based on selected option
        switch (position) {
            case 'top-left':
                posStyles.top = '10px';
                posStyles.left = '10px';
                break;
            case 'top-center':
                posStyles.top = '10px';
                posStyles.left = '50%';
                posStyles.transform = 'translateX(-50%)';
                break;
            case 'top-right':
                posStyles.top = '10px';
                posStyles.right = '10px';
                break;
            case 'bottom-left':
                posStyles.bottom = '10px';
                posStyles.left = '10px';
                break;
            case 'bottom-center':
                posStyles.bottom = '10px';
                posStyles.left = '50%';
                posStyles.transform = 'translateX(-50%)';
                break;
            case 'bottom-right':
                posStyles.bottom = '10px';
                posStyles.right = '10px';
                break;
            default:
                posStyles.top = '10px';
                posStyles.right = '10px';
        }
        
        // Apply position styles to both badges
        applyPositionStyles(textBadge, posStyles);
        applyPositionStyles(dotBadge, posStyles);
        
        console.log('DR Extension: Badge position set to', position);
    }
    
    function applyPositionStyles(badge, posStyles) {
        if (!badge) return;
        
        // Reset all position properties first
        badge.style.top = 'auto';
        badge.style.right = 'auto';
        badge.style.bottom = 'auto';
        badge.style.left = 'auto';
        badge.style.transform = 'none';
        
        // Apply new position styles
        badge.style.top = posStyles.top;
        badge.style.right = posStyles.right;
        badge.style.bottom = posStyles.bottom;
        badge.style.left = posStyles.left;
        badge.style.transform = posStyles.transform;
    }
    
    // Listen for settings update messages from popup
    chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        if (message.action === 'updateBadge') {
            try {
                const changes = message.changes;
                
                if (changes.position) {
                    setPositionStyles(changes.position);
                }
                
                if (changes.type) {
                    activeBadgeType = changes.type;
                    showActiveBadge();
                }
                
                // Send a response to properly close the message port
                sendResponse({ success: true });
            } catch (error) {
                console.error('Error handling message:', error);
                sendResponse({ success: false, error: error.message });
            }
            // Don't return true since we're sending the response synchronously
        }
    });
    
    // Run immediately
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', createOrUpdateBadges);
    } else {
        createOrUpdateBadges();
    }
    
    // Also try a delayed execution as a backup
    setTimeout(createOrUpdateBadges, 500);
    
    console.log('DR Environment Extension loaded');
})(); 