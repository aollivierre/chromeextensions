/**
 * URL Detector Module
 * Detects environment information from URL patterns
 */

import { log, parseUrl } from '../../shared/utils';
import { 
    ENVIRONMENT_PATTERNS, 
    STRONG_DR_PATTERNS, 
    STRONG_TEST_PATTERNS,
    EXCLUDE_WORDS 
} from '../../shared/patterns';
import { DETECTION_METHODS } from '../../shared/constants';

/**
 * Checks if a URL contains strong environment patterns
 * @param {string} url - The URL to check
 * @returns {object|null} Detection result or null if no strong pattern found
 */
export function detectStrongEnvironmentPatterns(url) {
    if (!url) return null;

    const urlLower = url.toLowerCase();
    
    // Check for strong DR patterns first (highest priority)
    const hasDrPattern = STRONG_DR_PATTERNS.some(pattern => urlLower.includes(pattern));
    
    if (hasDrPattern) {
        // Find the specific pattern for reporting
        const matchedPattern = STRONG_DR_PATTERNS.find(pattern => urlLower.includes(pattern));
        return {
            environment: 'dr',
            confidence: DETECTION_METHODS.URL_PATTERN.confidence,
            method: DETECTION_METHODS.URL_PATTERN.name,
            source: `strong-dr-pattern:${matchedPattern}`,
            pattern: matchedPattern
        };
    }
    
    // Check for strong TEST patterns
    const hasTestPattern = STRONG_TEST_PATTERNS.some(pattern => urlLower.includes(pattern));
    
    if (hasTestPattern) {
        // Find the specific pattern for reporting
        const matchedPattern = STRONG_TEST_PATTERNS.find(pattern => urlLower.includes(pattern));
        return {
            environment: 'test',
            confidence: DETECTION_METHODS.URL_PATTERN.confidence,
            method: DETECTION_METHODS.URL_PATTERN.name,
            source: `strong-test-pattern:${matchedPattern}`,
            pattern: matchedPattern
        };
    }
    
    // No strong patterns found
    return null;
}

/**
 * Performs a detailed check of a URL for environment patterns
 * @param {string} url - The URL to check
 * @returns {object|null} Detection result or null if no pattern found
 */
export function detectEnvironmentFromUrl(url) {
    if (!url) return null;
    
    try {
        // First check for strong patterns that should override other detection
        const strongPatternResult = detectStrongEnvironmentPatterns(url);
        if (strongPatternResult) {
            return strongPatternResult;
        }
        
        const parsedUrl = parseUrl(url);
        if (!parsedUrl) return null;
        
        const { hostname, path, fullText } = parsedUrl;
        
        // Check for DR patterns in detail (unless URL contains exclusion words)
        const hasDrExcludeWord = EXCLUDE_WORDS.dr.some(word => fullText.includes(word));
        
        if (!hasDrExcludeWord) {
            // Special case for DR login URLs that might be more reliable
            if (hostname.includes('login') && fullText.includes('wawanesa-dr')) {
                return {
                    environment: 'dr',
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence,
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: 'login-wawanesa-dr',
                    pattern: 'wawanesa-dr'
                };
            }
            
            // Check general DR patterns
            for (const pattern of ENVIRONMENT_PATTERNS.dr) {
                if (fullText.includes(pattern)) {
                    return {
                        environment: 'dr',
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence,
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`,
                        pattern: pattern
                    };
                }
            }
        }

        // Check for TEST patterns
        const hasTestExcludeWord = EXCLUDE_WORDS.test.some(word => fullText.includes(word));
        
        if (!hasTestExcludeWord) {
            for (const pattern of ENVIRONMENT_PATTERNS.test) {
                if (fullText.includes(pattern)) {
                    return {
                        environment: 'test',
                        confidence: DETECTION_METHODS.URL_PATTERN.confidence,
                        method: DETECTION_METHODS.URL_PATTERN.name,
                        source: `url-pattern:${pattern}`,
                        pattern: pattern
                    };
                }
            }
        }

        // Check for DEV patterns
        for (const pattern of ENVIRONMENT_PATTERNS.dev) {
            if (fullText.includes(pattern)) {
                return {
                    environment: 'dev',
                    confidence: DETECTION_METHODS.URL_PATTERN.confidence,
                    method: DETECTION_METHODS.URL_PATTERN.name,
                    source: `url-pattern:${pattern}`,
                    pattern: pattern
                };
            }
        }
        
        // Check for API endpoints that might indicate DR environment
        if (path.includes('/api/')) {
            if (path.includes('/dr/') || path.includes('/dr-api/')) {
                return {
                    environment: 'dr',
                    confidence: DETECTION_METHODS.API_ENDPOINT.confidence,
                    method: DETECTION_METHODS.API_ENDPOINT.name,
                    source: path,
                    pattern: path.includes('/dr/') ? '/dr/' : '/dr-api/'
                };
            }
        }
        
        log('No environment patterns found in URL');
        return null;
    } catch (error) {
        log('Error checking URL for environment patterns:', error);
        return null;
    }
}