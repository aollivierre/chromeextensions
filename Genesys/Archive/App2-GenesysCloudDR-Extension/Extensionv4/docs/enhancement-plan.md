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
- [ ] 1. Test in all environments
  - [ ] a. Verify DR environment detection
  - [ ] b. Verify test environment detection via organization ID
  - [ ] c. Verify dev environment detection via organization ID

- [ ] 2. Performance optimization
  - [ ] a. Review code for unnecessary operations
  - [ ] b. Optimize environment detection to minimize impact

- [ ] 3. Documentation
  - [ ] a. Update comments to reflect new functionality
  - [ ] b. Document organization ID mapping for maintenance 