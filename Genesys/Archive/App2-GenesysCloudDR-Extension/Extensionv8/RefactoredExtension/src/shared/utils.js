/**
 * Shared utility functions
 */

import { DEBUG } from './constants';

/**
 * Logs messages to the console if debugging is enabled
 * @param {...any} args - Arguments to log
 */
export function log(...args) {
    if (DEBUG) {
        console.log('[Environment Extension]', ...args);
    }
}

/**
 * Safely retrieve data from Chrome storage sync
 * @param {string[]} keys - Keys to retrieve from storage
 * @param {function} callback - Callback function to handle retrieved data
 */
export function safeStorageGet(keys, callback) {
    try {
        if (chrome.storage && chrome.storage.sync) {
            chrome.storage.sync.get(keys, function(data) {
                if (chrome.runtime.lastError) {
                    log('Error accessing storage:', chrome.runtime.lastError);
                    callback({});
                } else {
                    callback(data);
                }
            });
        } else {
            log('Chrome storage API not available');
            callback({});
        }
    } catch (error) {
        log('Error accessing chrome.storage.sync:', error);
        callback({});
    }
}

/**
 * Safely save data to Chrome storage sync
 * @param {object} data - Data to save to storage
 * @param {function} [callback] - Optional callback function to execute after saving
 */
export function safeStorageSet(data, callback) {
    try {
        if (chrome.storage && chrome.storage.sync) {
            chrome.storage.sync.set(data, function() {
                if (chrome.runtime.lastError) {
                    log('Error saving to storage:', chrome.runtime.lastError);
                    if (callback) callback(false, chrome.runtime.lastError);
                } else {
                    log('Data saved to storage successfully');
                    if (callback) callback(true);
                }
            });
        } else {
            log('Chrome storage API not available for saving data');
            if (callback) callback(false, new Error('Chrome storage API not available'));
        }
    } catch (error) {
        log('Error accessing chrome.storage.sync:', error);
        if (callback) callback(false, error);
    }
}

/**
 * Get the current date and time as ISO string
 * @returns {string} Current date and time in ISO format
 */
export function getCurrentTimestamp() {
    return new Date().toISOString();
}

/**
 * Parse URL into components
 * @param {string} url - URL to parse
 * @returns {object} Parsed URL with hostname, path, and other components
 */
export function parseUrl(url) {
    try {
        const urlLower = url.toLowerCase();
        const parsedUrl = new URL(urlLower);
        return {
            hostname: parsedUrl.hostname,
            path: parsedUrl.pathname,
            hash: parsedUrl.hash,
            fullText: `${parsedUrl.hostname}${parsedUrl.pathname}${parsedUrl.hash}`,
            original: url
        };
    } catch (error) {
        log('Error parsing URL:', error);
        return null;
    }
}