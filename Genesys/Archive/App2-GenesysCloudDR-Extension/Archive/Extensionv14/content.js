(() => {
  // Configuration for environment badges
  const ENV_CONFIG = {
    'd6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac': { name: 'DR', color: 'red' },
    'd9ee1fd7-868c-4ea0-af89-5b9813db863d': { name: 'TEST', color: 'orange' },
    'a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a': { name: 'DEV', color: 'blue' },
    'f6b247d6-10d1-42e6-99bc-be52827a50f0': { name: 'PROD', color: null } // No badge for PROD
  };

  // The definitive localStorage key that contains org ID information
  const AUTH_TOKEN_KEY = 'gcucc-ui-auth-token';

  // Log prefix for easy filtering in console
  const LOG_PREFIX = '[GC-ENV]';

  // Custom log function with prefix
  function log(...args) {
    console.log(LOG_PREFIX, ...args);
  }

  // Track the current environment to avoid unnecessary updates
  let currentEnvId = null;
  let badgeElement = null;
  
  // Track the last detected auth token value to detect changes
  let lastAuthTokenValue = null;
  
  // Badge display control
  let canShowBadge = false;
  let badgeTimer = null;
  let lastUrlChecked = '';
  let badgeResetTimeout = null;
  let isEnvironmentChange = false;

  // Create or update badge based on environment
  function updateBadge(envId, force = false) {
    // Don't do anything if environment hasn't changed and not forcing update
    if (envId === currentEnvId && !force) return;
    
    // Log environment change or force update
    if (envId !== currentEnvId) {
      log(`Genesys Cloud environment changed: ${envId || 'unknown'}`);
      
      // When environment changes, reset the badge display state with full delay
      isEnvironmentChange = true;
      resetBadgeState(true);
    } else if (force) {
      log(`Forcing badge update for: ${envId || 'unknown'}`);
    }
    
    currentEnvId = envId;
    
    // Remove existing badge if present
    if (badgeElement) {
      document.body.removeChild(badgeElement);
      badgeElement = null;
    }
    
    // If no environment ID or it's PROD (or unknown), don't show badge
    if (!envId || !ENV_CONFIG[envId] || !ENV_CONFIG[envId].color) return;
    
    // Skip creating badge if we're not allowed to show it yet
    if (!canShowBadge) {
      log(`Badge display suppressed - waiting for delay to complete`);
      return;
    }
    
    // Create badge element
    badgeElement = document.createElement('div');
    const env = ENV_CONFIG[envId];
    
    // Set badge styles
    Object.assign(badgeElement.style, {
      position: 'fixed',
      top: '0',
      left: '50%',
      transform: 'translateX(-50%)',
      backgroundColor: env.color,
      color: 'white',
      padding: '4px 12px',
      fontSize: '12px',
      fontWeight: 'bold',
      zIndex: '9999',
      textAlign: 'center',
      borderBottomLeftRadius: '4px',
      borderBottomRightRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)'
    });
    
    // Set badge text
    badgeElement.textContent = env.name;
    
    // Add badge to page
    document.body.appendChild(badgeElement);
    log(`Badge displayed: ${env.name}`);
  }

  /**
   * Reset badge state when environment changes or page transitions
   * @param {boolean} fullReset - If true, apply full delay for environment change
   */
  function resetBadgeState(fullReset = false) {
    // Clear any existing timers
    if (badgeTimer) {
      clearTimeout(badgeTimer);
    }
    
    if (badgeResetTimeout) {
      clearTimeout(badgeResetTimeout);
    }
    
    // Remove existing badge if we're doing a full reset or this is an environment change
    if (fullReset && badgeElement) {
      document.body.removeChild(badgeElement);
      badgeElement = null;
    }
    
    // Disable badge display for full resets (environment changes)
    if (fullReset) {
      canShowBadge = false;
      log('Badge state reset - suppressing display during environment transition');
      
      // Set timeout to re-enable badge after delay - longer for environment changes
      const delayTime = isEnvironmentChange ? 5000 : 500;
      
      badgeTimer = setTimeout(() => {
        canShowBadge = true;
        isEnvironmentChange = false;
        log('Transition delay complete - badges can now be displayed');
        
        // Force check after delay to show badge if needed
        const orgId = getCurrentOrgId();
        updateBadge(orgId, true); // Force update
      }, delayTime);
      
      log(`Set badge delay timer for ${delayTime}ms`);
    } else {
      // For minor navigation events within same environment, 
      // we'll just do a quick badge refresh with minimal delay
      log('Minor navigation - quick badge refresh');
      
      // Very short delay to allow DOM to stabilize, but keep badge visible
      badgeTimer = setTimeout(() => {
        // Force check to show badge if needed
        const orgId = getCurrentOrgId();
        updateBadge(orgId, true); // Force update
      }, 100);
    }
  }
  
  /**
   * Check for URL changes which indicate page transitions
   */
  function checkForPageTransition() {
    const currentUrl = window.location.href;
    
    // If URL has changed, we're in a page transition
    if (currentUrl !== lastUrlChecked) {
      log(`Page transition detected: ${lastUrlChecked} -> ${currentUrl}`);
      lastUrlChecked = currentUrl;
      
      // Reset badge state on page transition but with minimal delay 
      // since this is likely a navigation within the same environment
      resetBadgeState(false);
    }
  }

  /**
   * Get the current organization ID from localStorage
   * @returns {string|null} Organization ID or null if not found
   */
  function getCurrentOrgId() {
    try {
      // Get the latest auth token
      const authToken = localStorage.getItem(AUTH_TOKEN_KEY);
      if (!authToken) {
        log('Auth token not found in localStorage');
        lastAuthTokenValue = null;
        return null;
      }
      
      // Check if token has changed since last check
      const tokenChanged = authToken !== lastAuthTokenValue;
      if (tokenChanged) {
        log(`Auth token has changed. First 40 chars: ${authToken.substring(0, 40)}...`);
        lastAuthTokenValue = authToken;
        
        // When auth token changes, this is a strong indicator of environment change
        // Reset badge state to prevent stale badge display
        isEnvironmentChange = true;
        resetBadgeState(true);
        
        // Debug: Log all the org IDs we're looking for
        log(`Looking for these org IDs:`, Object.keys(ENV_CONFIG).join(', '));
      }
      
      // Find which org ID is in the token
      for (const orgId of Object.keys(ENV_CONFIG)) {
        if (authToken.includes(orgId)) {
          if (tokenChanged) {
            log(`Found organization ID ${orgId} in localStorage auth token`);
            log(`Mapped to environment: ${ENV_CONFIG[orgId].name}`);
          }
          
          return orgId;
        }
      }
      
      if (tokenChanged) {
        log('No known organization ID found in auth token');
      }
      return null;
    } catch (error) {
      log('Error checking auth token for org ID:', error);
      return null;
    }
  }

  // Handler for storage changes
  function handleStorageChange(event) {
    if (event.key === AUTH_TOKEN_KEY) {
      log('AUTH TOKEN CHANGED VIA STORAGE EVENT');
      // Force a detection and update the badge
      isEnvironmentChange = true;
      resetBadgeState(true); // Reset badge state for storage events
      const orgId = getCurrentOrgId();
      updateBadge(orgId);
    }
  }

  // Handler for navigation events
  function handleNavigation() {
    log('Navigation event detected');
    resetBadgeState(false); // Use quick refresh for navigation events
  }

  // Poll for auth token changes
  function pollAuthToken() {
    // Check for page transitions
    checkForPageTransition();
    
    // Get current result
    const orgId = getCurrentOrgId();
    
    // Update badge if needed
    updateBadge(orgId);
  }

  // Initial check and setup polling
  function initialize() {
    log('Extension initialized - starting monitoring');
    
    // Record initial URL
    lastUrlChecked = window.location.href;
    
    // Set up storage event listener for changes from other tabs
    window.addEventListener('storage', handleStorageChange);
    
    // Listen for navigation events
    window.addEventListener('popstate', handleNavigation);
    window.addEventListener('hashchange', handleNavigation);
    
    // Start polling right away for detecting org ID
    setInterval(pollAuthToken, 500);
    log('Polling active - checking every 500ms');
    
    // Initial reset of badge state
    resetBadgeState();
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})(); 