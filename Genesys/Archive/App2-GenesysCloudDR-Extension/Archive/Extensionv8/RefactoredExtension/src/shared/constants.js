/**
 * Constants shared across the extension
 */

// Environment configuration
export const ENVIRONMENTS = {
    dr: {
        name: "DR",
        color: "#ff0000", // Red
        textColor: "#ffffff",
        description: "Disaster Recovery Environment"
    },
    test: {
        name: "TEST",
        color: "#d4a017", // Muted/darker yellow (amber)
        textColor: "#000000",
        description: "Test Environment"
    },
    dev: {
        name: "DEV",
        color: "#0066cc", // Blue
        textColor: "#ffffff",
        description: "Development Environment"
    },
    prod: {
        name: "PROD", 
        color: "#000000", // Black (won't be used)
        textColor: "#ffffff",
        description: "Production Environment - No Badge"
    },
    unknown: {
        name: "Unknown",
        color: "#808080", // Gray
        textColor: "#ffffff",
        description: "Environment Not Detected"
    }
};

// Known organization IDs mapped to environments
export const ORGANIZATION_MAPPINGS = {
    // Production environment - NO BADGE
    "f6b247d6-10d1-42e6-99bc-be52827a50f0": "prod", // Production Org - No Badge Display
    
    // DR environment mappings
    "d6154e9b-1f7a-40a4-9f06-e3a4c73fc4ac": "dr",   // Wawanesa-DR

    // Test environment mappings
    "d9ee1fd7-868c-4ea0-af89-5b9813db863d": "test", // Wawanesa-Test (Primary target)
    
    // Dev environment mappings
    "a7cbe8fc-fe81-47bc-bdd3-05a726c56c5a": "dev",  // Development Org
};

// Known hostnames mapped to environments
export const HOSTNAME_MAPPINGS = {
    // Test environments
    "cac1.pure.cloud": "test",    // CAC1 region is Test environment
    "usw2.pure.cloud": "test",    // USW2 region often used for Test
    "use2.pure.cloud": "test",    // USE2 region often used for Test
    "fra.pure.cloud": "test",     // FRA region often used for Test
    "login.mypurecloud.ca": "test", // Canadian login is typically TEST
    
    // DEV environments
    "use1.dev.us-east-1.aws.dev.genesys.cloud": "dev", // Dev environment hostname
    "dev.genesys.cloud": "dev",     // General dev environment
    
    // DR patterns in hostnames - these have highest confidence
    "dr.mypurecloud.com": "dr",     // Explicit DR in hostname
    "dr-api.mypurecloud.com": "dr", // DR API endpoint
};

// API endpoints that might contain org information
export const ORG_RELATED_ENDPOINTS = [
    '/api/v2/organizations/me',
    '/api/v2/users/me',
    '/api/v2/authorization/roles',
    '/api/v2/tokens/me'
];

// Detection methods with confidence levels
export const DETECTION_METHODS = {
    ORG_ID: { confidence: 0.95, name: "Organization ID" },
    HOSTNAME: { confidence: 0.95, name: "Hostname" },
    API_ENDPOINT: { confidence: 0.90, name: "API Endpoint" },
    URL_PATTERN: { confidence: 0.85, name: "URL Pattern" },
    TITLE_PATTERN: { confidence: 0.80, name: "Page Title" },
    MANUAL_OVERRIDE: { confidence: 1.00, name: "Manual Override" },
    DEFAULT: { confidence: 0.50, name: "Default" }
};

// Enable logging
export const DEBUG = true;