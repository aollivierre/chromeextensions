/**
 * Storage Utilities Module
 * Handles Chrome storage operations for the content script
 */

import { log } from '../shared/utils';

/**
 * Retrieve data from Chrome storage sync
 * @param {string[]} keys - Keys to retrieve
 * @returns {Promise<object>} Object containing the retrieved data
 */
export function getStorageData(keys) {
    return new Promise((resolve) => {
        try {
            if (chrome.storage && chrome.storage.sync) {
                chrome.storage.sync.get(keys, function(data) {
                    if (chrome.runtime.lastError) {
                        log('Error accessing storage:', chrome.runtime.lastError);
                        resolve({});
                    } else {
                        log('Retrieved data from storage:', data);
                        resolve(data);
                    }
                });
            } else {
                log('Chrome storage API not available');
                resolve({});
            }
        } catch (error) {
            log('Error accessing chrome.storage.sync:', error);
            resolve({});
        }
    });
}

/**
 * Save data to Chrome storage sync
 * @param {object} data - Data to save
 * @returns {Promise<boolean>} True if save was successful
 */
export function saveStorageData(data) {
    return new Promise((resolve) => {
        try {
            if (chrome.storage && chrome.storage.sync) {
                chrome.storage.sync.set(data, function() {
                    if (chrome.runtime.lastError) {
                        log('Error saving to storage:', chrome.runtime.lastError);
                        resolve(false);
                    } else {
                        log('Data saved to storage successfully:', data);
                        resolve(true);
                    }
                });
            } else {
                log('Chrome storage API not available for saving data');
                resolve(false);
            }
        } catch (error) {
            log('Error accessing chrome.storage.sync:', error);
            resolve(false);
        }
    });
}

/**
 * Remove keys from Chrome storage sync
 * @param {string[]} keys - Keys to remove
 * @returns {Promise<boolean>} True if removal was successful
 */
export function removeStorageData(keys) {
    return new Promise((resolve) => {
        try {
            if (chrome.storage && chrome.storage.sync) {
                chrome.storage.sync.remove(keys, function() {
                    if (chrome.runtime.lastError) {
                        log('Error removing from storage:', chrome.runtime.lastError);
                        resolve(false);
                    } else {
                        log('Keys removed from storage successfully:', keys);
                        resolve(true);
                    }
                });
            } else {
                log('Chrome storage API not available for removing data');
                resolve(false);
            }
        } catch (error) {
            log('Error accessing chrome.storage.sync:', error);
            resolve(false);
        }
    });
}

/**
 * Clear all data from Chrome storage sync
 * @returns {Promise<boolean>} True if clear was successful
 */
export function clearStorageData() {
    return new Promise((resolve) => {
        try {
            if (chrome.storage && chrome.storage.sync) {
                chrome.storage.sync.clear(function() {
                    if (chrome.runtime.lastError) {
                        log('Error clearing storage:', chrome.runtime.lastError);
                        resolve(false);
                    } else {
                        log('Storage cleared successfully');
                        resolve(true);
                    }
                });
            } else {
                log('Chrome storage API not available for clearing data');
                resolve(false);
            }
        } catch (error) {
            log('Error accessing chrome.storage.sync:', error);
            resolve(false);
        }
    });
}

/**
 * Send storage data to background script for synchronization
 * @param {object} data - Data to send
 * @returns {Promise<boolean>} True if sync was successful
 */
export function syncWithBackground(data) {
    return new Promise((resolve) => {
        try {
            chrome.runtime.sendMessage({
                action: 'syncStorageData',
                data: data
            }, function(response) {
                if (chrome.runtime.lastError) {
                    log('Error syncing with background:', chrome.runtime.lastError);
                    resolve(false);
                } else {
                    log('Data synced with background successfully:', response);
                    resolve(true);
                }
            });
        } catch (error) {
            log('Error sending message to background:', error);
            resolve(false);
        }
    });
}