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

// Environment name mapping
const ENV_NAME_MAPPING = {
  'dev': 'DEV',
  'test': 'TEST',
  'dr': 'DR',
  'prod': 'PROD',
  'cac1': 'DEV',
  'use2-core': 'DR'
};

// Environment color mapping
const ENV_COLOR_MAPPING = {
  'DEV': 'blue',
  'TEST': 'orange',
  'DR': 'red',
  'PROD': null
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

// Main function to find auth token and check organization
function init() {
  // Try to detect environment from meta tags first
  if (tryMetaTagDetection()) {
    return; // Meta tag detection succeeded, no need to continue
  }
  
  // Use direct DOM inspection to find environment markers
  tryDirectEnvironmentDetection();
  
  // Try to get auth token from various sources
  const authToken = getAuthToken();
  
  if (!authToken) {
    console.log(`${LOG_PREFIX} No auth token found`);
    return;
  }
  
  // Try to get organization info from API
  checkOrganization(authToken);
}

// Function to try extracting environment from meta tags
function tryMetaTagDetection() {
  const metaTags = document.querySelectorAll('meta[name*="config"][content]');
  
  for (const tag of metaTags) {
    try {
      console.log(`${LOG_PREFIX} Checking meta tag:`, tag.name);
      
      // Get content and decode it
      const content = decodeURIComponent(tag.content);
      const configData = JSON.parse(content);
      
      console.log(`${LOG_PREFIX} Parsed meta tag data:`, configData);
      
      // Check for environment indicators in the config
      if (configData.oauthProps) {
        // This is likely the main config with environment info
        
        // Check which environment is being used
        const envKeys = Object.keys(configData.oauthProps);
        console.log(`${LOG_PREFIX} Found environment keys:`, envKeys);
        
        // Check for specific domain in the URL or other indicators
        const currentHostname = window.location.hostname;
        const hostname = currentHostname.toLowerCase();
        
        let detectedEnv = null;
        
        // Check hostname for environment indicators
        if (hostname.includes('cac1') || hostname.includes('test')) {
          detectedEnv = hostname.includes('test') ? 'TEST' : 'DEV';
        } else if (hostname.includes('use2') || hostname.includes('dr')) {
          detectedEnv = 'DR';
        } else if (!hostname.includes('test') && !hostname.includes('dev') && !hostname.includes('dr')) {
          // If no test/dev/dr indicators, it's probably PROD
          detectedEnv = 'PROD';
        }
        
        if (detectedEnv) {
          console.log(`${LOG_PREFIX} Detected environment from hostname:`, detectedEnv);
          displayBadgeByName(detectedEnv);
          return true;
        }
        
        // Check for active client ID match
        if (configData.oauthProps.dev && configData.oauthProps.test) {
          const devClientId = configData.oauthProps.dev.clientId;
          const testClientId = configData.oauthProps.test.clientId;
          
          // Try to determine which environment by checking localStorage
          try {
            const clientId = localStorage.getItem('gc_client_id') || sessionStorage.getItem('gc_client_id');
            if (clientId) {
              if (clientId === devClientId) {
                console.log(`${LOG_PREFIX} Matched dev client ID`);
                displayBadgeByName('DEV');
                return true;
              } else if (clientId === testClientId) {
                console.log(`${LOG_PREFIX} Matched test client ID`);
                displayBadgeByName('TEST');
                return true;
              }
            }
          } catch (e) {
            console.log(`${LOG_PREFIX} Error checking client ID:`, e);
          }
        }
      }
      
      // Check for environment key directly
      if (configData.environment) {
        const env = configData.environment.toLowerCase();
        if (env !== 'production') {
          // Non-production environment
          console.log(`${LOG_PREFIX} Found non-production environment:`, env);
          if (ENV_NAME_MAPPING[env]) {
            displayBadgeByName(ENV_NAME_MAPPING[env]);
            return true;
          }
        }
      }
    } catch (e) {
      console.log(`${LOG_PREFIX} Error parsing meta tag:`, e);
    }
  }
  
  return false;
}

// Display badge by environment name
function displayBadgeByName(envName) {
  const color = ENV_COLOR_MAPPING[envName];
  
  if (!color) {
    console.log(`${LOG_PREFIX} No badge needed for ${envName}`);
    return;
  }
  
  // Check if badge already exists
  if (document.querySelector('#gc-env-badge')) {
    console.log(`${LOG_PREFIX} Badge already exists`);
    return;
  }
  
  // Create badge element
  const badge = document.createElement('div');
  badge.id = 'gc-env-badge';
  
  // Apply styles directly to the element
  badge.style.position = 'fixed';
  badge.style.top = '0';
  badge.style.left = '50%';
  badge.style.transform = 'translateX(-50%)';
  badge.style.padding = '4px 8px';
  badge.style.borderRadius = '0 0 4px 4px';
  badge.style.fontWeight = 'bold';
  badge.style.zIndex = '9999';
  badge.style.fontFamily = 'Arial, sans-serif';
  badge.style.fontSize = '12px';
  badge.style.color = 'white';
  badge.style.textAlign = 'center';
  
  // Apply color based on environment
  switch (color) {
    case 'red':
      badge.style.backgroundColor = '#d9534f';
      break;
    case 'orange':
      badge.style.backgroundColor = '#f0ad4e';
      break;
    case 'blue':
      badge.style.backgroundColor = '#5bc0de';
      break;
  }
  
  // Set badge text
  badge.textContent = envName;
  
  // Add badge to body
  document.body.appendChild(badge);
  console.log(`${LOG_PREFIX} Added ${envName} badge`);
}

// Try to detect environment from DOM elements
function tryDirectEnvironmentDetection() {
  // Sometimes environment info is in DOM
  try {
    // Look for elements that might contain environment info
    const envInfoElements = document.querySelectorAll('meta[name*="environment"], .environment-info, [data-environment]');
    for (const el of envInfoElements) {
      console.log(`${LOG_PREFIX} Found environment info element:`, el);
    }
  } catch (e) {
    console.log(`${LOG_PREFIX} Error searching DOM:`, e);
  }
}

// Function to get auth token from various storage locations
function getAuthToken() {
  for (const source of AUTH_SOURCES) {
    try {
      const storageObj = window[source.storage];
      if (!storageObj) continue;
      
      const rawData = storageObj.getItem(source.key);
      if (!rawData) continue;
      
      console.log(`${LOG_PREFIX} Found data in ${source.storage}.${source.key}`);
      
      if (!source.json) {
        return rawData;
      }
      
      const parsedData = JSON.parse(rawData);
      if (!parsedData) continue;
      
      // Navigate to the token within the object structure
      const tokenPath = source.tokenKey.split('.');
      let token = parsedData;
      for (const key of tokenPath) {
        if (!token) break;
        token = token[key];
      }
      
      if (token) {
        console.log(`${LOG_PREFIX} Successfully extracted token from ${source.storage}.${source.key}`);
        return token;
      }
    } catch (error) {
      console.log(`${LOG_PREFIX} Error accessing ${source.storage}.${source.key}:`, error);
    }
  }
  return null;
}

// Function to check organization using the auth token
function checkOrganization(token) {
  // Try each API domain
  for (const domain of API_DOMAINS) {
    const url = `https://${domain}${API_PATH}`;
    
    // Log sanitized request details
    console.log(`${LOG_PREFIX} Trying to fetch org info from: ${url}`);
    
    // Fetch organization info with proper headers
    fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache'
      }
    })
    .then(response => {
      console.log(`${LOG_PREFIX} Response status from ${domain}: ${response.status}`);
      if (!response.ok) throw new Error(`HTTP status ${response.status}`);
      return response.json();
    })
    .then(data => {
      console.log(`${LOG_PREFIX} Got data:`, data);
      if (data && data.id) {
        console.log(`${LOG_PREFIX} Organization ID:`, data.id);
        displayBadge(data.id);
      } else {
        console.log(`${LOG_PREFIX} Response has no org ID:`, data);
      }
    })
    .catch(error => {
      console.log(`${LOG_PREFIX} Error fetching from ${domain}:`, error);
      
      // Try alternative methods if available
      if (domain === 'api.mypurecloud.com') {
        tryAlternativeOrgDetection(token, domain);
      }
    });
  }
}

// Alternative method to get organization info
function tryAlternativeOrgDetection(token, domain) {
  // Try a different endpoint
  const userEndpoint = `https://${domain}/api/v2/users/me`;
  
  console.log(`${LOG_PREFIX} Trying alternative endpoint: ${userEndpoint}`);
  
  fetch(userEndpoint, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  })
  .then(response => {
    if (!response.ok) throw new Error(`API request failed: ${response.status}`);
    return response.json();
  })
  .then(data => {
    if (data && data.organization && data.organization.id) {
      console.log(`${LOG_PREFIX} Found org ID from user endpoint:`, data.organization.id);
      displayBadge(data.organization.id);
    }
  })
  .catch(error => {
    console.log(`${LOG_PREFIX} Error with alternative endpoint:`, error);
  });
}

// Function to create and display the environment badge
function displayBadge(orgId) {
  const config = ENV_CONFIG[orgId];
  if (!config || !config.color) {
    console.log(`${LOG_PREFIX} No badge needed for org ${orgId}`);
    return;
  }
  
  // Check if badge already exists
  if (document.querySelector('#gc-env-badge')) {
    console.log(`${LOG_PREFIX} Badge already exists`);
    return;
  }
  
  // Create badge element
  const badge = document.createElement('div');
  badge.id = 'gc-env-badge';
  
  // Apply styles directly to the element
  badge.style.position = 'fixed';
  badge.style.top = '0';
  badge.style.left = '50%';
  badge.style.transform = 'translateX(-50%)';
  badge.style.padding = '4px 8px';
  badge.style.borderRadius = '0 0 4px 4px';
  badge.style.fontWeight = 'bold';
  badge.style.zIndex = '9999';
  badge.style.fontFamily = 'Arial, sans-serif';
  badge.style.fontSize = '12px';
  badge.style.color = 'white';
  badge.style.textAlign = 'center';
  
  // Apply color based on environment
  switch (config.color) {
    case 'red':
      badge.style.backgroundColor = '#d9534f';
      break;
    case 'orange':
      badge.style.backgroundColor = '#f0ad4e';
      break;
    case 'blue':
      badge.style.backgroundColor = '#5bc0de';
      break;
  }
  
  // Set badge text
  badge.textContent = config.name;
  
  // Add badge to body
  document.body.appendChild(badge);
  console.log(`${LOG_PREFIX} Added ${config.name} badge`);
}

// Start the process when the page is fully loaded
if (document.readyState === 'complete') {
  init();
} else {
  window.addEventListener('load', init);
} 