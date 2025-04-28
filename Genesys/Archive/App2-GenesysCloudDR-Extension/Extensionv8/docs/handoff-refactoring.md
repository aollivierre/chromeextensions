
# Handoff Prompt: Genesys Cloud Environment Extension Refactoring

## Project Background

The Genesys Cloud Environment Extension is a Chrome extension that displays environment badges (DR, TEST, DEV) based on the current Genesys Cloud environment. The badge detection uses a combination of organization ID detection and URL pattern matching.

The extension currently works but suffers from significant code maintainability issues:

- Both background.js (~780 lines) and dr-script.js (~800 lines) are monolithic files
- Code organization is poor with related functionality scattered across files
- Navigation detection in SPAs is problematic (requires further improvement)
- Lacks a modular architecture making updates difficult

## Refactoring Plan Reference

I've created a structured refactoring plan in `docs/refactoring-plan.md` that outlines a 5-phase approach:

1. Project Setup and Initial Restructuring
2. Content Script Modularization
3. Background Script Modularization
4. Testing and Integration
5. Documentation and Cleanup

This plan provides a step-by-step guide to breaking down the monolithic scripts into smaller, more maintainable modules using a modern JS modular approach.

## Current State and Files

Key files in the current implementation:

1. **background.js**: Background service worker that handles detection logic and storage
2. **dr-script.js**: Content script that creates/updates the badge and monitors the page
3. **popup.js**: Handles the popup UI when the extension icon is clicked
4. **manifest.json**: Extension configuration

We've recently fixed navigation detection issues but the code needs substantial restructuring.

## Next Steps

The immediate next steps are:

1. Review `docs/refactoring-plan.md` for the detailed breakdown of tasks
2. Set up a module bundling system (webpack/rollup) for the extension
3. Create the proposed directory structure
4. Begin extracting shared constants and configurations
5. Proceed with modularizing the content script first (dr-script.js)

## Important Considerations

1. **Preserve Functionality**: The refactoring should maintain all existing functionality
2. **Incremental Approach**: Implement changes in small, testable chunks
3. **SPA Navigation**: Current SPA navigation detection has been improved but may need further refinement
4. **Testing**: Test each module thoroughly before proceeding to the next

The most critical aspect is to improve maintainability while ensuring the badge continues to update correctly when navigating between different Genesys Cloud environments (particularly DR to TEST transitions).

Please refer to the enhancement plan and recently added refactoring plan for a complete understanding of the project's status and future direction.
