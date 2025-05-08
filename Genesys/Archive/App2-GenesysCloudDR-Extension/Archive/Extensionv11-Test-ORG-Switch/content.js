// Organization ID mappings
const ORGANIZATIONS = {
  'f6b247d6-10d1-42e6-99bc-be52827a50f0': 'PROD',
  'd9ee1fd7-868c-4ea0-af89-5b9813db863d': 'TEST'
};

// Target localStorage key that contains the org ID
const TARGET_KEY = 'gcucc-ui-auth-token';

// Tracking state
let lastDetectedOrgId = null;
let lastSourceValue = null;
let detectionCount = 0;

/**
 * Simple logger function
 */
function log(...args) {
  console.log('[GenesysOrgLogger]', ...args);
}

/**
 * Check the specific localStorage key that contains auth token
 */
function checkStorage() {
  try {
    const now = new Date();
    const timeStr = now.toISOString();
    const readableTime = `${now.getHours()}:${now.getMinutes()}:${now.getSeconds()}.${now.getMilliseconds()}`;
    
    // Check the specific localStorage key we found contains the org ID
    const authToken = localStorage.getItem(TARGET_KEY);
    
    if (authToken) {
      // If the token changed from last check, log the change
      if (authToken !== lastSourceValue) {
        detectionCount++;
        
        log('======= AUTH TOKEN CHANGED ========');
        log(`Time: ${readableTime}`);
        log(`Check #${detectionCount}`);
        
        // Extract just a small part of the token to not flood the console
        // But enough to see if it's changing
        log(`Token (first 40 chars): ${authToken.substring(0, 40)}...`);
        
        // Check for each org ID
        let foundOrgId = null;
        let foundEnv = null;
        
        for (const [orgId, env] of Object.entries(ORGANIZATIONS)) {
          if (authToken.includes(orgId)) {
            foundOrgId = orgId;
            foundEnv = env;
            
            log(`FOUND ${env} ORG: ${orgId}`);
            
            // If org ID changed from last detection, highlight it
            if (orgId !== lastDetectedOrgId) {
              log('*** ORGANIZATION CHANGED ***');
              log(`Previous: ${lastDetectedOrgId || 'None'}`);
              log(`Current: ${orgId} (${env})`);
            }
            
            break;
          }
        }
        
        // If no known org ID was found, log that too
        if (!foundOrgId) {
          log('No known org ID found in token');
        }
        
        log('===================================');
        
        // Update state
        lastSourceValue = authToken;
        lastDetectedOrgId = foundOrgId;
      }
    } else {
      // If key is missing now but was present before, log that
      if (lastSourceValue !== null) {
        log('AUTH TOKEN REMOVED FROM STORAGE');
        lastSourceValue = null;
      }
    }
  } catch (error) {
    log('Error checking storage:', error);
  }
}

// Initial message
log('CACHE DIAGNOSTICS - Monitoring auth token for org ID changes');
log(`Target localStorage key: ${TARGET_KEY}`);
log('Known org IDs:', Object.entries(ORGANIZATIONS).map(([id, env]) => `${env}: ${id}`).join(', '));

// Run immediately
checkStorage();

// Set up interval
setInterval(checkStorage, 500); // Check more frequently to catch the transition 