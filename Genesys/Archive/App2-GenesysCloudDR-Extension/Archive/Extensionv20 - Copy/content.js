(() => {
  // Configuration for environment badges and API endpoints
  const ENV_CONFIG = {
    'd6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac': { 
      name: 'DR', 
      color: 'red',
      apiDomain: 'api.mypurecloud.com' 
    },
    'd9ee1fd7-868c-4ea0-af89-5b9813db863d': { 
      name: 'TEST', 
      color: 'orange',
      apiDomain: 'api.cac1.pure.cloud' 
    },
    'a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a': { 
      name: 'DEV', 
      color: 'blue',
      apiDomain: 'api.cac1.pure.cloud'
    },
    'f6b247d6-10d1-42e6-99bc-be52827a50f0': { 
      name: 'PROD', 
      color: null, // No badge for PROD
      apiDomain: 'api.mypurecloud.com'
    }
  };

  // Multiple possible auth token storage locations to try
  const AUTH_SOURCES = [
    { storage: 'sessionStorage', key: 'gcui_auth', json: false },
    { storage: 'localStorage', key: 'gcucc-ui-auth-token', json: true, tokenKey: 'token' },
    { storage: 'localStorage', key: 'volt-ui-auth-token', json: true, tokenKey: 'token' },
    { storage: 'localStorage', key: 'pc_auth', json: true, tokenKey: 'authenticated.token' }
  ];
  
  // API endpoint paths and potential domains
  const API_PATH = '/api/v2/organizations/me';
  const API_DOMAINS = [
    'api.mypurecloud.com',
    'api.cac1.pure.cloud'
  ];
  
  // Log prefix for easy filtering in console
  const LOG_PREFIX = '[GC-ENV]';

  // Custom log function with prefix
  function log(...args) {
    console.log(LOG_PREFIX, ...args);
  }

  // Track the current environment to avoid unnecessary updates
  let currentEnvId = null;
  let badgeElement = null;
  
  // Flag to prevent showing badge too early during page transitions
  let canShowBadge = true; // Changed to true by default for testing
  
  // Create or update badge based on environment
  function updateBadge(envId, force = false) {
    // Don't do anything if environment hasn't changed and not forcing update
    if (envId === currentEnvId && !force) return;
    
    // Log environment change or force update
    if (envId !== currentEnvId) {
      log(`Genesys Cloud environment changed: ${envId || 'unknown'}`);
    } else if (force) {
      log(`Forcing badge update for: ${envId || 'unknown'}`);
    }
    
    currentEnvId = envId;
    
    // Remove existing badge if present
    if (badgeElement && badgeElement.parentNode) {
      log('Removing existing badge');
      try {
        document.body.removeChild(badgeElement);
      } catch (e) {
        log('Error removing badge:', e);
      }
      badgeElement = null;
    }
    
    // If no environment ID or it's PROD (or unknown), don't show badge
    if (!envId || !ENV_CONFIG[envId] || !ENV_CONFIG[envId].color) {
      log(`Not showing badge for: ${envId || 'unknown'} (null, unknown, or PROD)`);
      return;
    }
    
    // Skip creating badge if we're not allowed to show it yet
    if (!canShowBadge) {
      log(`Badge display suppressed - waiting for delay to complete`);
      return;
    }
    
    // Create badge element
    log(`Creating badge for environment: ${envId}`);
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
      zIndex: '99999', // Increased z-index to ensure visibility
      textAlign: 'center',
      borderBottomLeftRadius: '4px',
      borderBottomRightRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
      pointerEvents: 'none' // Ensure it doesn't block clicks
    });
    
    // Set badge text
    badgeElement.textContent = env.name;
    
    // Add badge to page
    log('Appending badge to document body');
    if (document.body) {
      document.body.appendChild(badgeElement);
      log(`Badge displayed: ${env.name}`);
    } else {
      log('Document body not available yet, cannot append badge');
    }
  }

  /**
   * Get a nested property from an object using a dot-notation path
   */
  function getNestedProperty(obj, path) {
    return path.split('.').reduce((prev, curr) => {
      return prev && prev[curr] ? prev[curr] : null;
    }, obj);
  }

  /**
   * Try to get auth token from various storage locations
   * @returns {string|null} Auth token or null if not found
   */
  function getAuthToken() {
    for (const source of AUTH_SOURCES) {
      try {
        const storage = window[source.storage];
        if (!storage) continue;
        
        const value = storage.getItem(source.key);
        if (!value) continue;
        
        let token = null;
        
        // Handle JSON format if specified
        if (source.json) {
          try {
            const parsed = JSON.parse(value);
            if (source.tokenKey) {
              // Handle nested keys like 'authenticated.token'
              token = getNestedProperty(parsed, source.tokenKey);
            } else if (parsed.token) {
              token = parsed.token;
            } else if (parsed.access_token) {
              token = parsed.access_token;
            } else if (parsed.accessToken) {
              token = parsed.accessToken;
            }
          } catch (e) {
            log(`Error parsing JSON from ${source.storage}.${source.key}:`, e);
          }
        } else {
          // Use raw value if not JSON
          token = value;
        }
        
        if (token) {
          log(`Found auth token in ${source.storage}.${source.key}`);
          return token;
        }
      } catch (err) {
        log(`Error checking ${source.storage}.${source.key}:`, err);
      }
    }
    
    log('No auth token found in any storage location');
    return null;
  }

  /**
   * Try parsing org ID directly from token if API fails
   * Fallback method in case API is unavailable
   */
  function parseOrgIdFromToken(token) {
    if (!token) return null;
    
    log('Attempting to parse organization ID directly from token');
    
    // Try to find any matching org IDs in the token
    for (const orgId of Object.keys(ENV_CONFIG)) {
      if (token.includes(orgId)) {
        log(`Found organization ID ${orgId} in token via direct parsing`);
        return orgId;
      }
    }
    
    return null;
  }

  /**
   * Try to get organization ID from API using specific domain
   * @param {string} apiDomain - The API domain to try
   * @param {string} authToken - The auth token to use
   * @returns {Promise<string|null>} Organization ID or null if request failed
   */
  async function tryApiDomain(apiDomain, authToken) {
    const url = `https://${apiDomain}${API_PATH}`;
    log(`Trying API endpoint: ${url} with token: ${authToken.substring(0, 10)}...`);
    
    try {
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });
      
      if (!response.ok) {
        log(`API request to ${apiDomain} failed with status: ${response.status}`);
        return null;
      }
      
      const data = await response.json();
      log(`API request to ${apiDomain} succeeded!`);
      return data.id || null;
    } catch (error) {
      log(`Error fetching from ${apiDomain}:`, error);
      return null;
    }
  }

  /**
   * Get the current organization ID from API
   * @returns {Promise<string|null>} Organization ID or null if not found
   */
  async function getCurrentOrgId() {
    try {
      // Get auth token
      const authToken = getAuthToken();
      if (!authToken) {
        log('No auth token found in any storage location');
        return null;
      }
      
      // First try to get org ID directly from token as a fast path
      const parsedOrgId = parseOrgIdFromToken(authToken);
      if (parsedOrgId) {
        log(`Using organization ID from token parsing: ${parsedOrgId}`);
        
        // Try the matched domain first for confirmation if available
        if (ENV_CONFIG[parsedOrgId] && ENV_CONFIG[parsedOrgId].apiDomain) {
          log(`Trying API confirmation with domain: ${ENV_CONFIG[parsedOrgId].apiDomain}`);
          const confirmedId = await tryApiDomain(ENV_CONFIG[parsedOrgId].apiDomain, authToken);
          if (confirmedId) {
            log(`API confirmed organization ID: ${confirmedId}`);
            return confirmedId;
          } else {
            log(`API confirmation failed, using token-parsed ID: ${parsedOrgId}`);
          }
        }
        
        // Return the parsed ID even if API confirmation fails
        return parsedOrgId;
      }
      
      // If token parsing didn't work, try all API domains
      log('Token parsing failed, trying API endpoints...');
      for (const domain of API_DOMAINS) {
        const orgId = await tryApiDomain(domain, authToken);
        if (orgId) {
          log(`Found organization ID via API (${domain}): ${orgId}`);
          
          // Log environment info if found in config
          if (ENV_CONFIG[orgId]) {
            log(`Mapped to environment: ${ENV_CONFIG[orgId].name}`);
          } else {
            log(`Organization ID ${orgId} not in known environments`);
          }
          
          return orgId;
        }
      }
      
      log('Could not determine organization ID from any API endpoint');
      return null;
    } catch (error) {
      log('Error in getCurrentOrgId:', error);
      return null;
    }
  }

  // Poll for organization changes
  async function pollOrgData() {
    try {
      // Get current organization ID
      const orgId = await getCurrentOrgId();
      
      // Update badge if needed
      updateBadge(orgId, false);
    } catch (error) {
      log('Error during polling:', error);
    }
  }

  // Initial check and setup polling
  function initialize() {
    log('Extension initialized - starting monitoring');
    
    // Start polling for org ID
    setInterval(pollOrgData, 5000); // Every 5 seconds
    log('Polling active - checking every 5 seconds');
    
    // Force initial badge display
    setTimeout(() => {
      log('Running initial check for organization ID');
      pollOrgData();
      
      // Force another check a bit later to ensure badge is shown
      setTimeout(() => {
        log('Running follow-up check for organization ID');
        pollOrgData();
      }, 2000);
    }, 1000);
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})(); 