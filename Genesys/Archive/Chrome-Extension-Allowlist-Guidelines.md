# Chrome Extension Allowlist - Enterprise Guidelines

## Overview

This document outlines our organization's approach to managing Chrome extensions in enterprise environments. We maintain a curated list of approved Chrome extensions that can be installed by users within our organization, balancing security requirements with productivity needs.

## Why We Use an Allowlist

Chrome extensions can access sensitive data, modify web content, and potentially impact system security. To mitigate these risks, we:

1. Block installation of all extensions by default (using the wildcard blocker)
2. Explicitly allow only vetted and approved extensions
3. Force-install critical extensions required for business operations

This approach significantly reduces the attack surface while ensuring users have access to the tools they need.

## Technical Implementation

We deploy our extension policies via SCCM using the Chrome enterprise policies. Specifically:

- **ExtensionInstallBlocklist**: Contains a wildcard (*) to block all extensions by default
- **ExtensionInstallAllowlist**: Contains our list of approved extensions
- **ExtensionInstallForcelist**: Contains extensions that are automatically installed for all users

> **Important**: As per [Chrome's documentation](https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions), all extensions for Windows and macOS must come from the Chrome Web Store. Local CRX installations are not supported on these platforms.

> **Clarification**: Enterprise policies like `ExtensionInstallAllowlist` and `ExtensionInstallForcelist` **require** the extension's ID from the Chrome Web Store. These policies do **not** support deploying extensions using local file paths, local `.crx` files, or methods like `--load-extension`. Such methods are suitable only for local development or testing, not for enterprise policy deployment.

## Current Approved Extensions

Below is our current list of approved extensions. These extensions have been reviewed for security, functionality, and business need.

<!-- Insert your extension list here -->
```
## APPROVED CHROME EXTENSIONS
<!-- This is where you would paste your extracted extension list -->
```

## Requesting New Extensions

If you need an extension that's not on the approved list, follow these steps:

1. **Verify Chrome Web Store Availability**: The extension must be published on the Chrome Web Store.

2. **Submit a Request**: Fill out the Extension Request Form, including:
   - Extension name and Chrome Web Store URL
   - Business justification for the extension
   - Department or teams that require the extension
   - Whether it should be allowlisted (optional install) or forcelisted (auto-installed)

3. **Security Review**: The security team will evaluate the extension for:
   - Required permissions and their scope
   - Data handling practices
   - Developer reputation
   - Update history and maintenance
   - Known vulnerabilities

4. **Approval Process**:
   - Requests are reviewed on a monthly basis
   - High-priority business needs may be expedited
   - Approved extensions are added to the allowlist in the next policy update

## Deployment Timeline

Once approved, extensions are deployed according to the following schedule:

1. Added to the SCCM package for Chrome policies
2. Tested in the staging environment (1-2 weeks)
3. Deployed to production (during the monthly update window)

## Extension Management

Our IT department uses the `Enable-LocalExtensions.ps1` script to manage Chrome extension policies through the registry. This script provides:

- Visualization of currently allowed and forced extensions
- Addition of new extensions to the allowlist or forcelist
- Removal of extensions from the lists
- Verification of policy configuration

## FAQ

**Q: Why can't I just install any extension I want?**  
A: Chrome extensions can pose significant security risks. Our allowlist approach mitigates these risks while still providing access to necessary tools.

**Q: How long does the approval process take?**  
A: Typically 2-4 weeks, depending on the complexity of the extension and its permissions.

**Q: Can I get an extension that's not in the Chrome Web Store?**  
A: No. For Windows and macOS, Chrome only supports extensions from the Chrome Web Store for enterprise deployment.

**Q: What if an extension is critical for my job function?**  
A: Include this information in your request form. Business-critical extensions may receive expedited review.

## References

- [Chrome Extension Installation Methods](https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions)
- [Chrome Enterprise Policies](https://chromeenterprise.google/policies/)
- [Extension Security Best Practices](https://developer.chrome.com/docs/extensions/develop/security-privacy/stay-secure)

## Document Information

- **Last Updated**: <!-- Insert date here -->
- **Maintained By**: IT Security and Operations Team
- **Review Cycle**: Quarterly 