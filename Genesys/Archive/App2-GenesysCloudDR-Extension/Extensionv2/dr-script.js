// This script adds a DR environment banner through JavaScript
// This works as a backup to the CSS method
(function() {
    function addDRBanner() {
        console.log('DR Environment Extension: Adding DR banner...');
        
        // Add top banner if it doesn't exist
        if (!document.getElementById('dr-environment-top-banner')) {
            const topBanner = document.createElement('div');
            topBanner.id = 'dr-environment-top-banner';
            topBanner.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; ' +
                'background-color: #ff0000; color: white; text-align: center; ' +
                'padding: 4px; font-size: 12px; font-weight: bold; z-index: 9999999; ' +
                'box-shadow: 0 0 5px rgba(255,0,0,0.5);';
            topBanner.innerText = 'DR ORGANIZATION';
            document.body.appendChild(topBanner);
            console.log('DR Environment Extension: Top banner added');
        }
    }

    // Run immediately and also after load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addDRBanner);
    } else {
        addDRBanner();
    }
    
    console.log('DR Environment Extension loaded');
})();
