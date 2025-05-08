(() => {
  // Configuration for environment badges
  const ENV_CONFIG = {
    'd6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac': { name: 'DR', color: 'red' },
    'd9ee1fd7-868c-4ea0-af89-5b9813db863d': { name: 'TEST', color: 'orange' },
    'a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a': { name: 'DEV', color: 'blue' },
    'f6b247d6-10d1-42e6-99bc-be52827a50f0': { name: 'PROD', color: null }
  };

  const AUTH_TOKEN_KEY = 'gcucc-ui-auth-token';
  let badgeElement = null;
  let badgeVersion = 0;
  
  // Only create badge after explicit validation
  function createBadge(orgId) {
    removeBadge();
    
    if (!orgId || !ENV_CONFIG[orgId] || !ENV_CONFIG[orgId].color) {
      return;
    }
    
    badgeElement = document.createElement('div');
    const env = ENV_CONFIG[orgId];
    
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
    
    badgeElement.textContent = env.name;
    document.body.appendChild(badgeElement);
  }
  
  function removeBadge() {
    if (badgeElement) {
      try {
        document.body.removeChild(badgeElement);
      } catch (e) {}
      badgeElement = null;
    }
  }

  // Extract org ID with validation
  function validateAndGetOrgId() {
    badgeVersion++;
    const currentVersion = badgeVersion;
    
    try {
      const authToken = localStorage.getItem(AUTH_TOKEN_KEY);
      if (!authToken) return null;
      
      // Ensure we're still on the same validation request
      if (currentVersion !== badgeVersion) return null;
      
      try {
        const parsedToken = JSON.parse(authToken);
        return parsedToken.orgId;
      } catch {
        for (const orgId of Object.keys(ENV_CONFIG)) {
          if (authToken.includes(orgId)) return orgId;
        }
        return null;
      }
    } catch (error) {
      console.error('[GC-ENV] Error:', error);
      return null;
    }
  }
  
  function initialize() {
    // Remove any existing badge first
    removeBadge();
    
    // Listen for explicit refresh events from background script
    window.addEventListener('gc-refresh-badge', () => {
      const orgId = validateAndGetOrgId();
      createBadge(orgId);
    });
    
    // Listen for storage events directly
    window.addEventListener('storage', (event) => {
      if (event.key === AUTH_TOKEN_KEY) {
        const orgId = validateAndGetOrgId();
        createBadge(orgId);
      }
    });
    
    // Try to signal the background script that we're ready
    try {
      chrome.runtime.sendMessage({action: 'refreshBadge'}, (response) => {
        // Background script received our message
      });
    } catch (e) {
      // Extension context not available, already handled by direct storage listener
    }
    
    // Delay initial check until document is loaded
    if (document.readyState === 'complete') {
      // Wait for potential auth token updates
      setTimeout(() => {
        const orgId = validateAndGetOrgId();
        createBadge(orgId);
      }, 1000);
    } else {
      window.addEventListener('load', () => {
        setTimeout(() => {
          const orgId = validateAndGetOrgId();
          createBadge(orgId);
        }, 1000);
      });
    }
  }
  
  initialize();
})();