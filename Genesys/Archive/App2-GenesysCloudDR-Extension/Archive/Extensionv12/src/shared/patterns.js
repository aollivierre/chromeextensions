/**
 * Pattern definitions for environment detection
 */

// URL patterns for different environments
export const ENVIRONMENT_PATTERNS = {
    dr: ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr', 'disaster', 'failover', 'recovery', 'dr-region'],
    test: ['.test.', '-test-', 'wawanesa-test', 'staging', 'uat', 'testing', 'test-region'],
    dev: ['.dev.', '-dev-', 'wawanesa-dev', 'development', 'dev-region', 'sandbox']
};

// Strong DR patterns that should override other detection methods
export const STRONG_DR_PATTERNS = ['.dr.', '-dr.', '-dr-', '/dr/', 'wawanesa-dr'];

// Strong TEST patterns
export const STRONG_TEST_PATTERNS = ['.test.', '-test-', 'wawanesa-test'];

// Words to exclude from pattern matching to avoid false positives
export const EXCLUDE_WORDS = {
    dr: ['directory', 'drive', 'drop', 'draw', 'drawer', 'address'],
    test: ['latest', 'greatest', 'contest', 'testimony', 'protest', 'attestation', 'intestate']
};

// Patterns that indicate navigation-related API calls
export const NAVIGATION_API_PATTERNS = [
    '/api/v2/', 
    '/routing/', 
    '/analytics/', 
    '/organization/', 
    '/authorization/'
];

// Base URLs for Genesys Cloud environments
export const GENESYS_CLOUD_DOMAINS = [
    'pure.cloud',
    'mypurecloud.com',
    'genesys.cloud'
];