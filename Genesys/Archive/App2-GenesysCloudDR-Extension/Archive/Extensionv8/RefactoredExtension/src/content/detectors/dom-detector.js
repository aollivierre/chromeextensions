/**
 * DOM Detector Module
 * Detects environment information from document and DOM elements
 */

import { log } from '../../shared/utils';
import { DETECTION_METHODS } from '../../shared/constants';
import { ENVIRONMENT_PATTERNS } from '../../shared/patterns';

/**
 * Check the page title for environment indicators
 * @returns {object|null} Detection result or null if no indicators found
 */
export function detectEnvironmentFromTitle() {
    log('Checking page title for environment indicators');
    
    try {
        const title = document.title.toLowerCase();
        
        if (!title) {
            log('Page title is empty');
            return null;
        }
        
        // Check for DR indicators in title
        for (const pattern of ENVIRONMENT_PATTERNS.dr) {
            if (title.includes(pattern)) {
                log(`Found DR pattern "${pattern}" in page title: ${title}`);
                return {
                    environment: 'dr',
                    confidence: DETECTION_METHODS.TITLE_PATTERN.confidence,
                    method: DETECTION_METHODS.TITLE_PATTERN.name,
                    source: `title-pattern:${pattern}`,
                    pattern: pattern
                };
            }
        }
        
        // Check for TEST indicators in title
        for (const pattern of ENVIRONMENT_PATTERNS.test) {
            if (title.includes(pattern)) {
                log(`Found TEST pattern "${pattern}" in page title: ${title}`);
                return {
                    environment: 'test',
                    confidence: DETECTION_METHODS.TITLE_PATTERN.confidence,
                    method: DETECTION_METHODS.TITLE_PATTERN.name,
                    source: `title-pattern:${pattern}`,
                    pattern: pattern
                };
            }
        }
        
        // Check for DEV indicators in title
        for (const pattern of ENVIRONMENT_PATTERNS.dev) {
            if (title.includes(pattern)) {
                log(`Found DEV pattern "${pattern}" in page title: ${title}`);
                return {
                    environment: 'dev',
                    confidence: DETECTION_METHODS.TITLE_PATTERN.confidence,
                    method: DETECTION_METHODS.TITLE_PATTERN.name,
                    source: `title-pattern:${pattern}`,
                    pattern: pattern
                };
            }
        }
        
        log('No environment indicators found in page title');
        return null;
    } catch (error) {
        log('Error checking page title for environment indicators:', error);
        return null;
    }
}

/**
 * Check meta tags for environment indicators
 * @returns {object|null} Detection result or null if no indicators found
 */
export function detectEnvironmentFromMetaTags() {
    log('Checking meta tags for environment indicators');
    
    try {
        const metaTags = document.querySelectorAll('meta');
        
        for (const meta of metaTags) {
            // Get content and name/property attributes
            const content = (meta.getAttribute('content') || '').toLowerCase();
            const name = (meta.getAttribute('name') || '').toLowerCase();
            const property = (meta.getAttribute('property') || '').toLowerCase();
            
            // Skip empty content
            if (!content) continue;
            
            // Skip CSRF tokens as they can contain pattern matches that lead to false positives
            if (name === 'csrf' || name === 'csrf-token' || name.includes('csrf')) {
                log(`Skipping CSRF meta tag: ${name}`);
                continue;
            }
            
            // Look for environment indicators in meta tag content
            
            // Check for DR indicators
            for (const pattern of ENVIRONMENT_PATTERNS.dr) {
                if (content.includes(pattern)) {
                    const metaIdentifier = name || property || 'unknown';
                    log(`Found DR pattern "${pattern}" in meta tag ${metaIdentifier}: ${content}`);
                    
                    return {
                        environment: 'dr',
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence * 0.9, // Slightly lower than title
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `meta-tag:${metaIdentifier}`,
                        pattern: pattern
                    };
                }
            }
            
            // Check for TEST indicators
            for (const pattern of ENVIRONMENT_PATTERNS.test) {
                if (content.includes(pattern)) {
                    const metaIdentifier = name || property || 'unknown';
                    log(`Found TEST pattern "${pattern}" in meta tag ${metaIdentifier}: ${content}`);
                    
                    return {
                        environment: 'test',
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence * 0.9,
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `meta-tag:${metaIdentifier}`,
                        pattern: pattern
                    };
                }
            }
            
            // Check for DEV indicators
            for (const pattern of ENVIRONMENT_PATTERNS.dev) {
                if (content.includes(pattern)) {
                    const metaIdentifier = name || property || 'unknown';
                    log(`Found DEV pattern "${pattern}" in meta tag ${metaIdentifier}: ${content}`);
                    
                    return {
                        environment: 'dev',
                        confidence: DETECTION_METHODS.TITLE_PATTERN.confidence * 0.9,
                        method: DETECTION_METHODS.TITLE_PATTERN.name,
                        source: `meta-tag:${metaIdentifier}`,
                        pattern: pattern
                    };
                }
            }
        }
        
        log('No environment indicators found in meta tags');
        return null;
    } catch (error) {
        log('Error checking meta tags for environment indicators:', error);
        return null;
    }
}

/**
 * Master function to check all DOM sources for environment information
 * @returns {Promise<object|null>} The first valid detection result or null if none found
 */
export async function detectEnvironmentFromDom() {
    try {
        // Check sources in order of reliability
        
        // 1. Check page title (most visible to user)
        const titleResult = detectEnvironmentFromTitle();
        if (titleResult) return titleResult;
        
        // 2. Check meta tags
        const metaTagResult = detectEnvironmentFromMetaTags();
        if (metaTagResult) return metaTagResult;
        
        // No environment indicators found in DOM
        return null;
    } catch (error) {
        log('Error in detectEnvironmentFromDom:', error);
        return null;
    }
}