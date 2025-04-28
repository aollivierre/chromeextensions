/**
 * Background Storage Service
 * Handles all storage operations for the background script
 */

import { log } from '../shared/utils';

class StorageService {
    constructor() {
        this.initialized = false;
        this.cachedData = {};
    }

    /**
     * Initialize the storage service
     * @returns {Promise<boolean>} True if initialization was successful
     */
    async initialize() {
        if (this.initialized) {
            return true;
        }

        try {
            log('Initializing storage service');
            
            // Load initial data from storage
            const data = await this.getAll();
            this.cachedData = data;
            
            this.initialized = true;
            log('Storage service initialized with data:', this.cachedData);
            return true;
        } catch (error) {
            log('Error initializing storage service:', error);
            return false;
        }
    }

    /**
     * Get a value from storage
     * @param {string} key - The key to retrieve
     * @returns {Promise<any>} The value or undefined if not found
     */
    async get(key) {
        try {
            // Check cache first
            if (this.cachedData[key] !== undefined) {
                return this.cachedData[key];
            }
            
            return new Promise((resolve) => {
                chrome.storage.sync.get(key, (data) => {
                    if (chrome.runtime.lastError) {
                        log('Error getting data from storage:', chrome.runtime.lastError);
                        resolve(undefined);
                    } else {
                        // Update cache
                        this.cachedData[key] = data[key];
                        resolve(data[key]);
                    }
                });
            });
        } catch (error) {
            log('Error in get:', error);
            return undefined;
        }
    }

    /**
     * Get multiple values from storage
     * @param {string[]} keys - The keys to retrieve
     * @returns {Promise<object>} Object containing the requested keys/values
     */
    async getMultiple(keys) {
        try {
            // Check if all keys are in cache
            const allInCache = keys.every(key => this.cachedData[key] !== undefined);
            if (allInCache) {
                const result = {};
                keys.forEach(key => {
                    result[key] = this.cachedData[key];
                });
                return result;
            }
            
            return new Promise((resolve) => {
                chrome.storage.sync.get(keys, (data) => {
                    if (chrome.runtime.lastError) {
                        log('Error getting multiple data from storage:', chrome.runtime.lastError);
                        resolve({});
                    } else {
                        // Update cache
                        Object.keys(data).forEach(key => {
                            this.cachedData[key] = data[key];
                        });
                        resolve(data);
                    }
                });
            });
        } catch (error) {
            log('Error in getMultiple:', error);
            return {};
        }
    }

    /**
     * Get all values from storage
     * @returns {Promise<object>} Object containing all storage data
     */
    async getAll() {
        try {
            return new Promise((resolve) => {
                chrome.storage.sync.get(null, (data) => {
                    if (chrome.runtime.lastError) {
                        log('Error getting all data from storage:', chrome.runtime.lastError);
                        resolve({});
                    } else {
                        // Update cache with all values
                        this.cachedData = { ...data };
                        resolve(data);
                    }
                });
            });
        } catch (error) {
            log('Error in getAll:', error);
            return {};
        }
    }

    /**
     * Set a value in storage
     * @param {string} key - The key to set
     * @param {any} value - The value to set
     * @returns {Promise<boolean>} True if set was successful
     */
    async set(key, value) {
        try {
            // Update cache immediately
            this.cachedData[key] = value;
            
            return new Promise((resolve) => {
                const data = { [key]: value };
                chrome.storage.sync.set(data, () => {
                    if (chrome.runtime.lastError) {
                        log('Error setting data in storage:', chrome.runtime.lastError);
                        // Revert cache on error
                        delete this.cachedData[key];
                        resolve(false);
                    } else {
                        resolve(true);
                    }
                });
            });
        } catch (error) {
            log('Error in set:', error);
            return false;
        }
    }

    /**
     * Set multiple values in storage
     * @param {object} data - Object containing key/value pairs to set
     * @returns {Promise<boolean>} True if set was successful
     */
    async setMultiple(data) {
        try {
            // Update cache immediately
            this.cachedData = { ...this.cachedData, ...data };
            
            return new Promise((resolve) => {
                chrome.storage.sync.set(data, () => {
                    if (chrome.runtime.lastError) {
                        log('Error setting multiple data in storage:', chrome.runtime.lastError);
                        // Revert cache on error (complex - just reload from storage)
                        this.getAll().then(() => resolve(false));
                    } else {
                        resolve(true);
                    }
                });
            });
        } catch (error) {
            log('Error in setMultiple:', error);
            return false;
        }
    }

    /**
     * Remove a key from storage
     * @param {string} key - The key to remove
     * @returns {Promise<boolean>} True if removal was successful
     */
    async remove(key) {
        try {
            // Update cache immediately
            delete this.cachedData[key];
            
            return new Promise((resolve) => {
                chrome.storage.sync.remove(key, () => {
                    if (chrome.runtime.lastError) {
                        log('Error removing data from storage:', chrome.runtime.lastError);
                        // Revert cache on error
                        this.get(key).then(value => {
                            this.cachedData[key] = value;
                            resolve(false);
                        });
                    } else {
                        resolve(true);
                    }
                });
            });
        } catch (error) {
            log('Error in remove:', error);
            return false;
        }
    }

    /**
     * Remove multiple keys from storage
     * @param {string[]} keys - The keys to remove
     * @returns {Promise<boolean>} True if removal was successful
     */
    async removeMultiple(keys) {
        try {
            // Update cache immediately
            keys.forEach(key => {
                delete this.cachedData[key];
            });
            
            return new Promise((resolve) => {
                chrome.storage.sync.remove(keys, () => {
                    if (chrome.runtime.lastError) {
                        log('Error removing multiple data from storage:', chrome.runtime.lastError);
                        // Revert cache on error
                        this.getAll().then(() => resolve(false));
                    } else {
                        resolve(true);
                    }
                });
            });
        } catch (error) {
            log('Error in removeMultiple:', error);
            return false;
        }
    }

    /**
     * Clear all data from storage
     * @returns {Promise<boolean>} True if clear was successful
     */
    async clear() {
        try {
            // Clear cache immediately
            this.cachedData = {};
            
            return new Promise((resolve) => {
                chrome.storage.sync.clear(() => {
                    if (chrome.runtime.lastError) {
                        log('Error clearing storage:', chrome.runtime.lastError);
                        // Revert cache on error
                        this.getAll().then(() => resolve(false));
                    } else {
                        resolve(true);
                    }
                });
            });
        } catch (error) {
            log('Error in clear:', error);
            return false;
        }
    }
}

// Create and export a singleton instance
const storageService = new StorageService();
export default storageService;