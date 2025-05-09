(() => {
  // --- Configuration ---
  const DEBUG = true; // Set to true for verbose logging, false to disable

  // Configuration for environment badges based on ORG NAME (lowercase) - Primary Method
  const ENV_CONFIG = {
    'wawanesa-dr': { name: 'DR', color: 'red' },
    'wawanesa-test': { name: 'TEST', color: 'orange' },
    'wawanesa-dev': { name: 'DEV', color: 'blue' },
    'wawanesa': { name: 'PROD', color: null } // No badge for PROD
  };

  // Configuration for environment badges based on ORG ID - Fallback Storage Method
  const ORG_ID_ENV_CONFIG = {
    'd6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac': { name: 'DR (wawanesa-dr)', color: 'red' },
    'd9ee1fd7-868c-4ea0-af89-5b9813db863d': { name: 'TEST (wawanesa-test)', color: 'orange' },
    'a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a': { name: 'DEV (wawanesa-dev)', color: 'blue' },
    'f6b247d6-10d1-42e6-99bc-be52827a50f0': { name: 'PROD', color: null } // No badge for PROD
  };

  const STORAGE_AUTH_TOKEN_KEY = 'gcucc-ui-auth-token'; // Specific key for the new storage method

  // Log prefix for easy filtering in console
  const LOG_PREFIX = '[GC-ENV]';

  // Custom log function with prefix - respects DEBUG flag
  function log(...args) {
    if (!DEBUG) return;
    console.log(LOG_PREFIX, ...args);
  }

  // State variables
  let currentOrgName = null; // Tracks org name from DOM method
  let currentOrgId = null;   // Tracks org ID from Storage fallback
  let badgeElement = null;
  let canShowBadge = false; // Flag to prevent showing badge too early
  let usingFallbackMethod = false; // Flag to track if fallback is active

  /**
   * Get organization name from the DOM (Primary Method)
   * @returns {string|null} Organization name (lowercase) or null if not found
   */
  function getOrgNameFromDOM() {
    try {
      const selector = ".org-menu span";
      const element = document.querySelector(selector);
      if (element && element.textContent?.trim()) {
        const orgName = element.textContent.trim().toLowerCase();
        log(`DOM: Found org name: ${orgName}`);
        return orgName;
      }
      log('DOM: Org name not found using selector: ', selector);
      return null;
    } catch (error) {
      log('DOM: Error getting org name:', error);
      return null;
    }
  }

  /**
   * Get organization ID from localStorage (Fallback Storage Method)
   * @returns {string|null} Organization ID or null if not found
   */
  function getOrgIdFromStorage() {
    log(`Storage: Attempting to get orgId using key '${STORAGE_AUTH_TOKEN_KEY}'`);
    try {
      const authToken = localStorage.getItem(STORAGE_AUTH_TOKEN_KEY);
      if (!authToken) {
        log(`Storage: Auth token not found with key '${STORAGE_AUTH_TOKEN_KEY}'.`);
        return null;
      }
      log(`Storage: Found auth token string (length: ${authToken.length}).`);

      // Try parsing as JSON first
      try {
        const parsedToken = JSON.parse(authToken);
        if (parsedToken && parsedToken.orgId) {
          log(`Storage: Successfully parsed token, orgId: ${parsedToken.orgId}`);
          return parsedToken.orgId;
        }
        log('Storage: Parsed token, but orgId not found in JSON structure.');
      } catch (jsonError) {
        log(`Storage: Failed to parse token as JSON. Error: ${jsonError.message}. Will attempt direct string search for orgId.`);
        // Fallback: if JSON parsing fails, check if authToken string includes any known orgId
        for (const orgId of Object.keys(ORG_ID_ENV_CONFIG)) {
          if (authToken.includes(orgId)) {
            log(`Storage: Found orgId '${orgId}' by direct string search in token.`);
            return orgId;
          }
        }
        log('Storage: orgId not found by direct string search after JSON parse failure.');
      }
      return null; // Return null if orgId not found through either method
    } catch (error) {
      log('Storage: Error getting orgId:', error);
      return null;
    }
  }

  /**
   * Create or update badge based on detected organization
   * @param {object|null} configEntry - The configuration object from ENV_CONFIG or ORG_ID_ENV_CONFIG
   * @param {string|null} identifier - The detected organization name or ID. Null to clear badge.
   * @param {boolean} isOrgIdMethod - True if identifier is an Org ID, false if it's an Org Name.
   * @param {boolean} forceUpdate - Whether to force the update.
   */
  function updateBadge(configEntry, identifier, isOrgIdMethod, forceUpdate = false) {
    log(`UpdateBadge called. Identifier: '${identifier}', IsOrgId: ${isOrgIdMethod}, Force: ${forceUpdate}`);
    log(`Current state: currentOrgName: '${currentOrgName}', currentOrgId: '${currentOrgId}'`);

    if (!forceUpdate) {
      if (isOrgIdMethod && identifier === currentOrgId) {
        log('Badge not updated: OrgID same and not forced.');
        return;
      }
      if (!isOrgIdMethod && identifier === currentOrgName) {
        log('Badge not updated: OrgName same and not forced.');
        return;
      }
    }

    // Remove existing badge
    if (badgeElement) {
      try {
        badgeElement.remove(); // More modern way to remove
      } catch (e) {
        log('Minor issue removing old badge, likely already removed.');
      }
      badgeElement = null;
    }

    // If identifier is null, or no valid configEntry, or no color, clear badge and state
    if (!identifier || !configEntry || !configEntry.color) {
      log(`Clearing badge. Reason: Identifier null, or no config/color. Identifier: '${identifier}'`);
      currentOrgName = null;
      currentOrgId = null;
      return;
    }

    // Skip creating badge if we're not allowed yet (initial delay)
    if (!canShowBadge) {
      log(`Badge display suppressed for '${identifier}' - waiting for initial delay.`);
      return;
    }
    
    // Update current identifier state
    if (isOrgIdMethod) {
      currentOrgId = identifier;
      currentOrgName = null; // Clear the other type of identifier
    } else {
      currentOrgName = identifier;
      currentOrgId = null; // Clear the other type of identifier
    }
    log(`State updated: currentOrgName: '${currentOrgName}', currentOrgId: '${currentOrgId}'`);

    // Create badge element
    badgeElement = document.createElement('div');
    Object.assign(badgeElement.style, {
      position: 'fixed', top: '0', left: '50%', transform: 'translateX(-50%)',
      backgroundColor: configEntry.color, color: 'white', padding: '4px 12px',
      fontSize: '12px', fontWeight: 'bold', zIndex: '9999', textAlign: 'center',
      borderBottomLeftRadius: '4px', borderBottomRightRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)'
    });
    
    badgeElement.textContent = isOrgIdMethod ? configEntry.name : `${configEntry.name} (${identifier})`;
    
    document.body.appendChild(badgeElement);
    log(`Badge displayed: ${badgeElement.textContent}`);
  }

  /**
   * Poll for organization changes and update the badge.
   */
  function pollAndUpdateBadge() {
    const orgNameFromDom = getOrgNameFromDOM();

    if (orgNameFromDom) {
      log('Poll: DOM method succeeded.');
      const config = ENV_CONFIG[orgNameFromDom];
      updateBadge(config, orgNameFromDom, false); // isOrgIdMethod = false
      usingFallbackMethod = false; 
    } else {
      log('Poll: DOM method failed.');
      if (!usingFallbackMethod) {
        log('Poll: DOM failed, trying fallback storage method for the first time (or after DOM success).');
        usingFallbackMethod = true; 
        
        const orgIdFromStorage = getOrgIdFromStorage();
        if (orgIdFromStorage) {
          log(`Poll: Storage fallback succeeded with orgId: ${orgIdFromStorage}`);
          const config = ORG_ID_ENV_CONFIG[orgIdFromStorage];
          updateBadge(config, orgIdFromStorage, true); // isOrgIdMethod = true
        } else {
          log('Poll: Storage fallback also failed.');
          updateBadge(null, null, false); // Clear badge
        }
      } else {
        log('Poll: DOM failed, and already on fallback. No change in detection method.');
        if (!currentOrgId) {
            log('Poll: DOM failed, on fallback, and currentOrgId is null. Ensuring badge is cleared.');
            updateBadge(null, null, true); 
        }
      }
    }
  }

  // Initial check and setup polling
  function initialize() {
    log('Extension initialized - DOM monitoring & fallback will be set up.');
    
    setInterval(pollAndUpdateBadge, 1000); // Poll every 1 second
    log('Polling active - checking every 1000ms.');
    
    setTimeout(() => {
      canShowBadge = true;
      log('Initial delay complete - badges can now be displayed.');
      
      const orgNameFromDom = getOrgNameFromDOM();
      if (orgNameFromDom) {
        log('Initial Check: DOM method succeeded.');
        const config = ENV_CONFIG[orgNameFromDom];
        updateBadge(config, orgNameFromDom, false, true); // Force update
      } else {
        log('Initial Check: DOM method failed, trying fallback storage method.');
        const orgIdFromStorage = getOrgIdFromStorage();
        if (orgIdFromStorage) {
          log(`Initial Check: Storage fallback succeeded with orgId: ${orgIdFromStorage}`);
          const config = ORG_ID_ENV_CONFIG[orgIdFromStorage];
          updateBadge(config, orgIdFromStorage, true, true); // Force update
        } else {
          log('Initial Check: Storage fallback also failed.');
          updateBadge(null, null, false, true); // Force update to clear badge
        }
      }
    }, 3000); // 3-second delay
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    setTimeout(initialize, 100); // DOM ready, slight delay
  }
})(); 