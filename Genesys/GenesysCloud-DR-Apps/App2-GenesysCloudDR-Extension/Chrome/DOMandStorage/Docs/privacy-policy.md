# Privacy Policy for Genesys Cloud Environment Badge Extension

**Last Updated:** May 8, 2025

## Introduction

This Privacy Policy explains how the Genesys Cloud Environment Badge extension ("Extension", "we", "our", or "us") collects, uses, and protects information when you use our browser extension. We are committed to ensuring the privacy and security of our users.

## Information Collection

### Data Collected

The Extension collects and/or accesses the following limited information:

- **Organization Name (from DOM)**: The Extension reads the organization name that appears in the Genesys Cloud interface DOM (Document Object Model). This is done locally within your browser to determine which environment badge to display.
- **Organization ID (from Local Storage - Fallback)**: As a fallback method, the Extension may attempt to read an organization ID by accessing a specific, pre-existing key within your browser's local storage (`localStorage`). This key is typically associated with Genesys Cloud authentication tokens and contains the organization ID. This access is read-only for identification purposes.

The Extension does NOT:
- Transmit any data to external servers
- Store any new personal information persistently for its own tracking purposes
- Track your browsing activity beyond the current Genesys Cloud page for identification
- Use cookies or similar tracking technologies for its own purposes
- Collect any sensitive information beyond what is necessary for environment identification (org name/ID).

### Method of Collection

All data processing occurs entirely within your browser. The Extension uses DOM selectors to identify the organization name displayed in the Genesys Cloud interface. For the fallback method, it accesses a pre-existing token in `localStorage` (if available and accessible) to extract the organization ID. This information is temporarily used by the script while the Extension is active on a relevant page and is never transmitted outside your browser.

## Use of Information

The organization name and/or organization ID are used solely to:
- Determine the appropriate environment badge to display (DR, TEST, DEV, or none for PROD)
- Show a visual indicator of which Genesys Cloud environment you are currently using

## Data Sharing and Disclosure

We do not share, sell, rent, or trade any information with third parties. Since the Extension processes all data locally within your browser and does not transmit any data externally, there is no data sharing with third parties.

## Data Security

Since all processing occurs locally within your browser and no data is transmitted externally, the security risks associated with data collection are minimized. The Extension accesses data from local storage on a read-only basis for its fallback mechanism and does not write new persistent data for its own operational needs.

## Your Rights

Since we don't collect or store new personal data persistently for the extension's own purposes, and access to local storage is for existing data, standard data access/correction/deletion rights related to extension-specific data stores are not directly applicable. The extension relies on data already present in your browser environment (DOM, local storage item from Genesys Cloud).

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the Chrome Web Store listing. You are advised to review this Privacy Policy periodically for any changes.

## Contact Us

If you have any questions about this Privacy Policy, please contact us at:
[YOUR CONTACT EMAIL ADDRESS]

---

**Note**: This extension is an internal tool developed for use within specific organizations and is not affiliated with, endorsed by, or officially connected to Genesys Cloud or any of its subsidiaries or affiliates. 