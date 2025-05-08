/**
 * Background Script Main Module
 * Entry point for the background service worker
 */

import { log } from '../shared/utils';
import storageService from './storage-service';
import environmentService from './environment-service';
import messagingService from './messaging-service';
import tabMonitor from './monitors/tab-monitor';
import apiMonitor from './monitors/api-monitor';
import orgIdMonitor from './monitors/org-id-monitor';

class BackgroundController {
    constructor() {
        this.initialized = false;
    }

    /**
     * Initialize all background services and monitors
     */
    async initialize() {
        if (this.initialized) {
            log('Background already initialized, skipping');
            return;
        }

        log('Initializing background script services');
        
        try {
            // Initialize services in order of dependency
            
            // 1. Storage service first (others depend on it)
            await storageService.initialize();
            
            // 2. Environment service (core functionality)
            await environmentService.initialize();
            
            // 3. Organization ID monitor
            await orgIdMonitor.initialize();
            
            // 4. API monitor
            await apiMonitor.initialize();
            
            // 5. Tab monitor
            await tabMonitor.initialize();
            
            // 6. Messaging service (handles communication)
            await messagingService.initialize();
            
            // Set up install/update handler
            this.setupInstallHandler();
            
            this.initialized = true;
            log('Background script initialization complete');
        } catch (error) {
            log('Error initializing background script:', error);
        }
    }

    /**
     * Set up handler for extension install or update
     */
    setupInstallHandler() {
        chrome.runtime.onInstalled.addListener((details) => {
            if (details.reason === 'install') {
                log('Extension installed');
                this.handleFirstInstall();
            } else if (details.reason === 'update') {
                log(`Extension updated from ${details.previousVersion} to ${chrome.runtime.getManifest().version}`);
                this.handleUpdate(details.previousVersion);
            }
        });
    }

    /**
     * Handle first-time extension installation
     */
    async handleFirstInstall() {
        log('Handling first-time installation');
        
        // You could initialize default settings here if needed
        await storageService.set('installDate', new Date().toISOString());
        
        // Open a welcome page or display initial instructions
        // chrome.tabs.create({ url: 'welcome.html' });
    }

    /**
     * Handle extension update
     * @param {string} previousVersion - Previous version number
     */
    async handleUpdate(previousVersion) {
        log(`Handling update from version ${previousVersion}`);
        
        // You could handle data migrations or display update notes here
        await storageService.set('lastUpdateDate', new Date().toISOString());
        await storageService.set('previousVersion', previousVersion);
        
        // If updating from a very old version, may need to migrate data format
        if (previousVersion && previousVersion.startsWith('1.')) {
            log('Migrating from v1.x format');
            await this.migrateFromV1();
        }
    }

    /**
     * Migrate data from version 1.x format if needed
     */
    async migrateFromV1() {
        // Check if migration is needed
        const needsMigration = await storageService.get('needsV1Migration');
        
        if (needsMigration === false) {
            log('Migration already performed, skipping');
            return;
        }
        
        log('Migrating data from v1.x format');
        
        try {
            // Perform migration logic here if needed
            
            // Mark migration as complete
            await storageService.set('needsV1Migration', false);
            log('Migration completed successfully');
        } catch (error) {
            log('Error during migration:', error);
            // Mark that migration needs to be attempted again
            await storageService.set('needsV1Migration', true);
        }
    }

    /**
     * Gracefully shutdown background services
     */
    async shutdown() {
        log('Shutting down background services');
        
        // Any cleanup needed for services
        
        this.initialized = false;
        log('Background services shutdown complete');
    }
}

// Create controller instance
const backgroundController = new BackgroundController();

// Initialize on script load
backgroundController.initialize();

// Add unload handler (may not be used in service workers but included for completeness)
self.addEventListener('unload', () => {
    backgroundController.shutdown();
});

// Export controller for potential testing or debugging
export default backgroundController;