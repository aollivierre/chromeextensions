(() => {
  // --- Configuration ---
  const DEBUG = false; // Set to true for verbose logging, false to disable

  // Configuration for environment badges based on ORG NAME (lowercase)
  const ENV_CONFIG = {
    'wawanesa-dr': { name: 'DR', color: 'red' },
    'wawanesa-test': { name: 'TEST', color: 'orange' },
    'wawanesa-dev': { name: 'DEV', color: 'blue' },
    'wawanesa': { name: 'PROD', color: null } // No badge for PROD
  };

  // Log prefix for easy filtering in console
  const LOG_PREFIX = '[GC-ENV]';

  // Custom log function with prefix - respects DEBUG flag
  function log(...args) {
    if (!DEBUG) return; // Do nothing if DEBUG is false
    console.log(LOG_PREFIX, ...args);
  }

  // Track the current detected org name to avoid unnecessary updates
  let currentOrgName = null; // Changed from currentEnvId
  let badgeElement = null;
  
  // Flag to prevent showing badge too early during page transitions
  let canShowBadge = false;

  /**
   * Get organization name from the DOM
   * @returns {string|null} Organization name (lowercase) or null if not found
   */
  function getOrgNameFromDOM() {
    try {
      // Use the specific selector that worked based on logs
      const selector = ".org-menu span";
      const element = document.querySelector(selector);
      
      if (element && element.textContent?.trim()) {
          const orgName = element.textContent.trim().toLowerCase();
          log(`Found org name via selector '${selector}': ${orgName}`);
          return orgName;
      }

      log('Organization name not found in DOM using selector: ', selector);
      return null;
    } catch (error) {
      log('Error getting org name from DOM:', error);
      return null;
    }
  }

  /**
   * Create or update badge based on detected organization name and corresponding environment config
   * @param {object|null} envConfig - The configuration object from ENV_CONFIG or null
   * @param {string|null} orgName - The detected organization name (lowercase)
   * @param {boolean} force - Whether to force the update
   */
  function updateBadge(envConfig, orgName, force = false) {
    // Don't update if orgName hasn't changed and not forcing
    if (orgName === currentOrgName && !force) return;

    if (orgName !== currentOrgName) {
      log(`Detected organization name change: ${orgName || 'unknown'}`);
    } else if (force) {
      log(`Forcing badge update for organization: ${orgName || 'unknown'}`);
    }

    currentOrgName = orgName; // Update tracked org name

    // Remove existing badge
    if (badgeElement) {
      try {
        document.body.removeChild(badgeElement);
      } catch (e) {
        // Ignore error if element is already gone
        log('Minor issue removing old badge, likely already removed.'); 
      }
      badgeElement = null;
    }

    // If no envConfig (meaning org name not found/matched or is PROD with no color), don't show badge
    if (!envConfig || !envConfig.color) {
      // Only log if orgName was actually found but didn't map or was PROD
      if (orgName) {
        log(`No badge needed for organization: ${orgName} (Env: ${envConfig?.name || 'Unknown/PROD'})`);
      }
      return;
    }

    // Skip creating badge if we're not allowed yet
    if (!canShowBadge) {
      log(`Badge display suppressed for ${orgName} - waiting for initial delay.`);
      return;
    }
    
    // Create badge element
    badgeElement = document.createElement('div');
    
    // Set badge styles
    Object.assign(badgeElement.style, {
      position: 'fixed',
      top: '0',
      left: '50%',
      transform: 'translateX(-50%)',
      backgroundColor: envConfig.color, // Use color from envConfig
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
    
    // Set badge text using envConfig.name and the originally detected (but now lowercased) orgName
    // Displaying the actual detected name might be more informative
    badgeElement.textContent = `${envConfig.name} (${orgName})`; 
    
    // Add badge to page
    document.body.appendChild(badgeElement);
    log(`Badge displayed: ${badgeElement.textContent}`);
  }

  /**
   * Poll for organization name changes in the DOM and update the badge
   */
  function pollAndUpdateBadge() {
    const orgName = getOrgNameFromDOM(); // Returns lowercase name or null
    const envConfig = orgName ? ENV_CONFIG[orgName] : null; // Lookup using lowercase name
    
    // Update badge if needed (logic is inside updateBadge)
    updateBadge(envConfig, orgName); 
  }

  // Initial check and setup polling
  function initialize() {
    log('Extension initialized - starting DOM monitoring for org name');
    
    // Start polling the DOM for the org name
    setInterval(pollAndUpdateBadge, 1000); // Check DOM every 1 second (adjust as needed)
    log('Polling active - checking DOM every 1000ms');
    
    // Delay before showing badge to prevent flashes during load/login
    setTimeout(() => {
      canShowBadge = true;
      log('Initial delay complete - badges can now be displayed');
      
      // Force check after delay to show badge immediately if applicable
      const orgName = getOrgNameFromDOM();
      const envConfig = orgName ? ENV_CONFIG[orgName] : null;
      updateBadge(envConfig, orgName, true); // Force update
    }, 3000); // 3 second delay
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    // DOM is already ready, run initialize directly, but perhaps slightly delayed
    // to ensure dynamic elements are more likely to be present.
    setTimeout(initialize, 100); 
  }
})(); 