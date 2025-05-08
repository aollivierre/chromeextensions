// Simple test script for Genesys Org ID detection
(function() {
    // Organization ID mappings
    const ORGANIZATIONS = {
        'f6b247d6-10d1-42e6-99bc-be52827a50f0': 'PROD',
        'd9ee1fd7-868c-4ea0-af89-5b9813db863d': 'TEST'
    };
    
    // Track state
    let lastDetectedOrg = null;
    let pollCount = 0;
    
    /**
     * Get the current organization ID from localStorage
     * @returns {Object|null} Object with orgId and environment, or null if not found
     */
    function getCurrentOrgId() {
        // Get the latest auth token
        const authToken = localStorage.getItem('gcucc-ui-auth-token');
        if (!authToken) return null;
        
        // Find which org ID is in the token
        for (const [orgId, env] of Object.entries(ORGANIZATIONS)) {
            if (authToken.includes(orgId)) {
                return { orgId, environment: env };
            }
        }
        
        return null;
    }
    
    /**
     * Check for org changes and log them
     */
    function checkForOrgChanges() {
        pollCount++;
        const current = getCurrentOrgId();
        
        // Log the check number every 20 polls
        if (pollCount % 20 === 0) {
            console.log(`[OrgDetector] Still running... (check #${pollCount})`);
        }
        
        // If no org detected, skip
        if (!current) return;
        
        // If this is the first detection or the org changed
        if (!lastDetectedOrg || current.orgId !== lastDetectedOrg.orgId) {
            const timestamp = new Date();
            console.log('=== ORGANIZATION DETECTED ===');
            console.log(`Time: ${timestamp.toLocaleTimeString()}.${timestamp.getMilliseconds()}`);
            console.log(`Organization: ${current.environment} (${current.orgId})`);
            
            if (lastDetectedOrg) {
                console.log(`Changed from: ${lastDetectedOrg.environment}`);
            }
            
            console.log('============================');
            
            // Update the last detected org
            lastDetectedOrg = current;
        }
    }
    
    // Initial log
    console.log('[OrgDetector] Starting monitoring for Genesys organization changes');
    console.log('[OrgDetector] Known organizations:', 
        Object.entries(ORGANIZATIONS).map(([id, env]) => `${env}: ${id}`).join(', '));
    
    // Initial check
    checkForOrgChanges();
    
    // Set up polling
    const POLL_INTERVAL = 500; // Check every 500ms
    setInterval(checkForOrgChanges, POLL_INTERVAL);
    
    // Store a reference for console debugging
    window.genesysOrgDetector = {
        getCurrentOrgId,
        getLastDetected: () => lastDetectedOrg
    };
    
    console.log('[OrgDetector] Successfully initialized');
    console.log('[OrgDetector] Access detector in console with window.genesysOrgDetector');
})(); 