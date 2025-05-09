# Affiliation Disclaimer and Organization Information

## Affiliation Disclaimer

This extension, "Genesys Cloud Environment Badge," is an internal tool developed for use within specific organizations that use Genesys Cloud services. It is:

- **NOT** affiliated with Genesys Cloud
- **NOT** endorsed by Genesys Cloud
- **NOT** officially connected to Genesys Cloud or any of its subsidiaries or affiliates

All references to "Genesys Cloud," "mypurecloud.com," "pure.cloud," and "genesys.cloud" are used solely for compatibility purposes to identify the platforms where this extension operates. The extension does not claim any association with or endorsement from Genesys Cloud.

## Organization-Specific Functionality

This extension contains organization names in its configuration that are used to identify different environments:

```javascript
const ENV_CONFIG = {
  'wawanesa-dr': { name: 'DR', color: 'red' },
  'wawanesa-test': { name: 'TEST', color: 'orange' },
  'wawanesa-dev': { name: 'DEV', color: 'blue' },
  'wawanesa': { name: 'PROD', color: null } // No badge for PROD
};
```

### Authorization Statement

The inclusion of these organization names is authorized for internal use within our organization. The extension is designed specifically for employees of the organization listed in the extension code and is not intended for general public use.

### Future Plans

In future versions of this extension, we plan to:

1. Make organization names configurable through a settings page
2. Remove hard-coded organization names
3. Allow users to customize the badge colors and labels

## Trademark Acknowledgment

"Genesys" and "Genesys Cloud" are trademarks or registered trademarks of Genesys Telecommunications Laboratories, Inc. This extension acknowledges these trademarks and does not claim any rights to them.

---

For questions about this disclaimer or the extension's usage within our organization, please contact:
[YOUR CONTACT INFORMATION] 