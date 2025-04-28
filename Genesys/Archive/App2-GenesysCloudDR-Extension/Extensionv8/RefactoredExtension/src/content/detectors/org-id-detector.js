/**
 * Organization ID Detector Module
 * Detects environment information based on organization IDs found in various sources
 */

import { log } from '../../shared/utils';
import { ORGANIZATION_MAPPINGS, DETECTION_METHODS } from '../../shared/constants';

/**
 * Check browser storage for known organization IDs
 * @returns {Promise<object|null>} Detection result or null if no org ID found
 */
export function detectOrgIdFromStorage() {
    log('Searching for organization IDs in browser storage');
    
    return new Promise((resolve) => {
        try {
            // Check localStorage for the organization ID
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                const value = localStorage.getItem(key);
                
                // Check each known organization ID
                for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                    if (value && value.includes(orgId)) {
                        log(`Found organization ID ${orgId} in localStorage under key: ${key}`);
                        
                        resolve({
                            environment,
                            orgId,
                            confidence: DETECTION_METHODS.ORG_ID.confidence,
                            method: DETECTION_METHODS.ORG_ID.name,
                            source: `localStorage:${key}`
                        });
                        return;
                    }
                }
            }
            
            // Check sessionStorage for the organization ID
            for (let i = 0; i < sessionStorage.length; i++) {
                const key = sessionStorage.key(i);
                const value = sessionStorage.getItem(key);
                
                // Check each known organization ID
                for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                    if (value && value.includes(orgId)) {
                        log(`Found organization ID ${orgId} in sessionStorage under key: ${key}`);
                        
                        resolve({
                            environment,
                            orgId,
                            confidence: DETECTION_METHODS.ORG_ID.confidence,
                            method: DETECTION_METHODS.ORG_ID.name,
                            source: `sessionStorage:${key}`
                        });
                        return;
                    }
                }
            }
            
            log('No organization IDs found in browser storage');
            resolve(null);
        } catch (error) {
            log('Error searching storage for org ID:', error);
            resolve(null);
        }
    });
}

/**
 * Check for organization ID in common JS objects
 * @returns {Promise<object|null>} Detection result or null if no org ID found
 */
export function detectOrgIdFromJsContext() {
    log('Checking for org ID in JavaScript context');
    
    return new Promise((resolve) => {
        try {
            // Check common places where Genesys stores org data
            const commonOrgObjects = [
                // Organization data
                window.PC?.organization?.id,
                window.GenesysCloudWebrtcSdk?.config?.organization?.id,
                window.purecloud?.org?.id,
                
                // Session/auth objects
                window.PC?.authData?.org,
                
                // Global objects that might be set
                window.PURECLOUD_ORG_ID,
                window.ORGANIZATION_ID
            ];
            
            // Check each object against our known org IDs
            for (const obj of commonOrgObjects) {
                if (obj && ORGANIZATION_MAPPINGS[obj]) {
                    const orgId = obj;
                    const environment = ORGANIZATION_MAPPINGS[orgId];
                    
                    log(`Found organization ID ${orgId} in JavaScript context`);
                    
                    resolve({
                        environment,
                        orgId,
                        confidence: DETECTION_METHODS.ORG_ID.confidence,
                        method: DETECTION_METHODS.ORG_ID.name,
                        source: 'js-context-object'
                    });
                    return;
                }
            }
            
            log('No organization IDs found in JavaScript context');
            resolve(null);
        } catch (error) {
            log('Error checking JS context for org ID:', error);
            resolve(null);
        }
    });
}

/**
 * Check page content for organization IDs
 * @returns {Promise<object|null>} Detection result or null if no org ID found
 */
export function detectOrgIdFromPageContent() {
    log('Checking page content for organization IDs');
    
    return new Promise((resolve) => {
        try {
            // Check for each organization ID in the page text content
            const pageContent = document.body.innerText;
            
            for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                if (pageContent && pageContent.includes(orgId)) {
                    log(`Found organization ID ${orgId} in page content`);
                    
                    resolve({
                        environment,
                        orgId,
                        confidence: DETECTION_METHODS.ORG_ID.confidence * 0.9, // Slightly lower confidence for text content
                        method: DETECTION_METHODS.ORG_ID.name,
                        source: 'page-content'
                    });
                    return;
                }
            }
            
            // Check HTML for org ID (could be in hidden elements or attributes)
            const htmlContent = document.documentElement.outerHTML;
            
            for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                if (htmlContent.includes(orgId)) {
                    log(`Found organization ID ${orgId} in HTML content`);
                    
                    resolve({
                        environment,
                        orgId,
                        confidence: DETECTION_METHODS.ORG_ID.confidence * 0.95,
                        method: DETECTION_METHODS.ORG_ID.name,
                        source: 'html-content'
                    });
                    return;
                }
            }
            
            // Check script contents
            const scriptTags = Array.from(document.getElementsByTagName('script'));
            
            for (const script of scriptTags) {
                const scriptContent = script.textContent || '';
                
                for (const [orgId, environment] of Object.entries(ORGANIZATION_MAPPINGS)) {
                    if (scriptContent.includes(orgId)) {
                        log(`Found organization ID ${orgId} in script content`);
                        
                        resolve({
                            environment,
                            orgId,
                            confidence: DETECTION_METHODS.ORG_ID.confidence * 0.98,
                            method: DETECTION_METHODS.ORG_ID.name,
                            source: 'script-content'
                        });
                        return;
                    }
                }
            }
            
            log('No organization IDs found in page content');
            resolve(null);
        } catch (error) {
            log('Error checking page content for org ID:', error);
            resolve(null);
        }
    });
}

/**
 * Master function to check all possible org ID sources
 * @returns {Promise<object|null>} The first valid detection result or null if none found
 */
export async function detectOrganizationId() {
    try {
        // Check sources in order of reliability
        
        // 1. Check browser storage (most reliable)
        const storageResult = await detectOrgIdFromStorage();
        if (storageResult) return storageResult;
        
        // 2. Check JavaScript context objects
        const jsContextResult = await detectOrgIdFromJsContext();
        if (jsContextResult) return jsContextResult;
        
        // 3. Check page content
        const pageContentResult = await detectOrgIdFromPageContent();
        if (pageContentResult) return pageContentResult;
        
        // No org ID found in any source
        return null;
    } catch (error) {
        log('Error in detectOrganizationId:', error);
        return null;
    }
}