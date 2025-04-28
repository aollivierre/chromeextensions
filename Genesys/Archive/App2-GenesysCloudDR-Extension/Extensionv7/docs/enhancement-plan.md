# Genesys Cloud DR Extension Enhancement Plan

## Phase 1: UI Adjustments and Default Settings
- [x] 1. Remove bottom positioning options
  - [x] a. Remove bottom position elements from popup.html
  - [x] b. Update CSS grid layout in popup.html
  - [x] c. Remove bottom position cases from dr-script.js

- [x] 2. Remove batch type selection
  - [x] a. Remove badge type selector from popup.html
  - [x] b. Update the popup layout
  - [x] c. Modify popup.js to always use "text" badge type
  - [x] d. Update dr-script.js to default to text badge type

- [x] 3. Default badge position to top center
  - [x] a. Change default position in popup.js
  - [x] b. Change default position in dr-script.js
  - [x] c. Update UI to highlight top center by default

- [x] 4. Limit position options to top positions only
  - [x] a. Verify all code paths only show top left, top center, and top right

## Phase 2: Multi-Environment Support
- [x] 1. Add environment detection logic
  - [x] a. Retain current DR environment detection (URL-based)
  - [x] b. Add organization ID detection functionality
  - [x] c. Create mapping of organization IDs to environments (test/dev)

- [x] 2. Update badge display for different environments
  - [x] a. Modify badge text based on detected environment
  - [x] b. Update badge styling/colors for each environment
  - [x] c. Store environment-specific settings

- [x] 3. Implement organization ID extraction
  - [x] a. Add code to scan for organization ID in API calls
  - [x] b. Create function to monitor network requests
  - [x] c. Implement storage for found organization IDs

- [x] 4. Create environment switching logic
  - [x] a. Develop functions to handle environment changes
  - [x] b. Update manifest permissions if needed
  - [x] c. Test environment detection accuracy

## Phase 3: Testing and Finalization
- [x] 1. Test in all environments
  - [x] a. Verify DR environment detection
  - [x] b. Verify test environment detection via organization ID
  - [x] c. Verify dev environment detection via organization ID

- [x] 2. Performance optimization
  - [x] a. Review code for unnecessary operations
  - [x] b. Optimize environment detection to minimize impact

- [x] 3. Documentation
  - [x] a. Update comments to reflect new functionality
  - [x] b. Document organization ID mapping for maintenance

## Phase 4: Future Enhancements
- [ ] 1. Add automatic organization ID discovery
  - [ ] a. Create a mechanism to detect and store new organization IDs
  - [ ] b. Add admin UI to map detected IDs to environments
  - [ ] c. Implement sync functionality for sharing ID mappings

- [ ] 2. Enhance badge visibility options
  - [ ] a. Add transparency settings
  - [ ] b. Implement visibility timeout option
  - [ ] c. Add badge size customization

- [ ] 3. Add support for custom environment names
  - [ ] a. Create UI for customizing environment labels
  - [ ] b. Store custom labels in user preferences
  - [ ] c. Apply custom labels to badges 