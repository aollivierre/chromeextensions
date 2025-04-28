/**
 * Organization ID Monitor
 * Specializes in tracking and validating organization IDs
 */

import { log } from '../../shared/utils';
import { ORGANIZATION_MAPPINGS } from '../../shared/constants';
import environmentService from '../environment-service';

class OrgIdMonitor {
    constructor() {
        this.initialized = false;
        this.detectedOrgIds = new Map(); // Tracks org IDs by tab ID
        this.orgMappings = ORGANIZATION_MAPPINGS;
    }

    /**
     * Initialize the organization ID monitor
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing organization ID monitor');
            
            // Load existing org ID from storage
            const { detectedOrgId } = await environmentService.getCurrentState();
            
            if (detectedOrgId) {
                log(`Loaded existing organization ID from storage: ${detectedOrgId}`);
            }
            
            this.initialized = true;
            log('Organization ID monitor initialized');
            return true;
        } catch (error) {
            log('Error initializing organization ID monitor:', error);
            return false;
        }
    }

    /**
     * Process a detected organization ID
     * @param {string} orgId - The organization ID
     * @param {string} source - Source of the detection
     * @param {number} [tabId] - Optional tab ID
     * @returns {Promise<object|null>} Detection result or null if invalid
     */
    async processOrganizationId(orgId, source, tabId = null) {
        if (!orgId || typeof orgId !== 'string') {
            log('Invalid organization ID:', orgId);
            return null;
        }

        // Validate organization ID format (GUID)
        if (!this.isValidGuid(orgId)) {
            log(`Invalid GUID format for organization ID: ${orgId}`);
            return null;
        }

        // Check if this org ID is in our mappings
        const environment = this.orgMappings[orgId];
        if (!environment) {
            log(`Organization ID ${orgId} not found in mappings`);
            return null;
        }

        log(`Valid organization ID detected: ${orgId} (${environment})`);
        
        // If there's a tab ID, track this org ID with the tab
        if (tabId) {
            this.trackOrgIdForTab(tabId, orgId, source);
        }
        
        // Forward to environment service
        return await environmentService.processOrganizationId(orgId, source, tabId);
    }

    /**
     * Track an organization ID for a specific tab
     * @param {number} tabId - The tab ID
     * @param {string} orgId - The organization ID
     * @param {string} source - Source of the detection
     */
    trackOrgIdForTab(tabId, orgId, source) {
        this.detectedOrgIds.set(tabId, {
            orgId,
            source,
            timestamp: Date.now()
        });
        
        log(`Now tracking organization ID ${orgId} for tab ${tabId}`);
    }

    /**
     * Check if a string is a valid GUID
     * @param {string} str - String to check
     * @returns {boolean} True if string is a valid GUID
     */
    isValidGuid(str) {
        if (!str) return false;
        
        // Basic GUID format check
        const guidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        return guidRegex.test(str);
    }

    /**
     * Get organization ID tracked for a tab
     * @param {number} tabId - The tab ID
     * @returns {string|null} The organization ID or null if not found
     */
    getOrgIdForTab(tabId) {
        const tabData = this.detectedOrgIds.get(tabId);
        return tabData ? tabData.orgId : null;
    }

    /**
     * Get all tracked organization IDs
     * @returns {Map} Map of tracked organization IDs by tab ID
     */
    getAllTrackedOrgIds() {
        return this.detectedOrgIds;
    }

    /**
     * Clear tracked organization ID for a tab
     * @param {number} tabId - The tab ID
     */
    clearOrgIdForTab(tabId) {
        if (this.detectedOrgIds.has(tabId)) {
            log(`Clearing tracked organization ID for tab ${tabId}`);
            this.detectedOrgIds.delete(tabId);
        }
    }

    /**
     * Clear all tracked organization IDs
     */
    clearAllTrackedOrgIds() {
        log('Clearing all tracked organization IDs');
        this.detectedOrgIds.clear();
    }

    /**
     * Check if an organization ID is for a DR environment
     * @param {string} orgId - The organization ID to check
     * @returns {boolean} True if organization ID is for a DR environment
     */
    isDrOrgId(orgId) {
        return this.orgMappings[orgId] === 'dr';
    }

    /**
     * Check if an organization ID is for a TEST environment
     * @param {string} orgId - The organization ID to check
     * @returns {boolean} True if organization ID is for a TEST environment
     */
    isTestOrgId(orgId) {
        return this.orgMappings[orgId] === 'test';
    }

    /**
     * Check if an organization ID is for a DEV environment
     * @param {string} orgId - The organization ID to check
     * @returns {boolean} True if organization ID is for a DEV environment
     */
    isDevOrgId(orgId) {
        return this.orgMappings[orgId] === 'dev';
    }

    /**
     * Add a new organization ID mapping
     * @param {string} orgId - The organization ID
     * @param {string} environment - The environment (dr, test, dev)
     * @returns {boolean} True if mapping was added
     */
    addOrgMapping(orgId, environment) {
        if (!this.isValidGuid(orgId) || !['dr', 'test', 'dev'].includes(environment)) {
            log(`Invalid organization ID or environment: ${orgId}, ${environment}`);
            return false;
        }
        
        this.orgMappings[orgId] = environment;
        log(`Added new organization ID mapping: ${orgId} -> ${environment}`);
        return true;
    }
}

// Create and export a singleton instance
const orgIdMonitor = new OrgIdMonitor();
export default orgIdMonitor;