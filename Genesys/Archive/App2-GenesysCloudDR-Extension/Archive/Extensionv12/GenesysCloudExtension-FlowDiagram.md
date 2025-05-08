# Genesys Cloud Environment Badge Extension - Flow Diagram

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Chrome Extension                             │
│                                                                  │
│  ┌───────────────────┐           ┌────────────────────────┐     │
│  │  Background Script │◄─────────►│    Content Script      │     │
│  │  (Service Worker)  │           │  (Runs in each tab)    │     │
│  └───────────────────┘           └────────────────────────┘     │
│           │                                   │                  │
│           ▼                                   ▼                  │
│  ┌───────────────────┐           ┌────────────────────────┐     │
│  │  Storage Service  │◄─────────►│      Badge UI          │     │
│  └───────────────────┘           └────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow for Environment Detection

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Environment Detection Flow                                      │
│                                                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │  Tab Navigation │────►│ URL Detection   │────►│  Org ID Detection│────►│  Badge Update   │    │
│  │  Events         │     │ (URL Patterns)  │     │  (localStorage)  │     │                 │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│         │                        │                       │                        ▲              │
│         │                        │                       │                        │              │
│         ▼                        ▼                       ▼                        │              │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐            │              │
│  │ Tab Monitor     │────►│ Environment     │────►│ Storage Service │────────────┘              │
│  │ (background)    │     │ Service         │     │                 │                            │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘                            │
│                                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Bookmark Navigation Issue Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Bookmark Navigation Issue                                       │
│                                                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │  User clicks    │────►│ Browser loads   │────►│  Extension      │────►│  Badge shows    │    │
│  │  bookmark to DR │     │ DR page         │     │  detects TEST   │     │  TEST instead   │    │
│  │  from TEST page │     │                 │     │  (from org ID)  │     │  of DR          │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│                                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Fixed Flow for Bookmark Navigation

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Fixed Bookmark Navigation Flow                                  │
│                                                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │  User clicks    │────►│ Tab Monitor     │────►│  Clear Tab      │────►│  Check URL for  │    │
│  │  bookmark to DR │     │ detects URL     │     │  Environment    │     │  Strong DR      │    │
│  │  from TEST page │     │ change          │     │  Cache          │     │  Patterns       │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│                                                                                  │              │
│                                                                                  ▼              │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │  Badge shows    │◄────│ Update Badge    │◄────│  Force DR       │◄────│  Prioritize DR  │    │
│  │  DR correctly   │     │ UI              │     │  Environment    │     │  URL Detection  │    │
│  │                 │     │                 │     │  Update         │     │                 │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│                                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Environment Detection Process

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              Environment Detection Process                                       │
│                                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                                          │    │
│  │  1. Tab Events (URL changes, tab activation, bookmark navigation)                        │    │
│  │                                                                                          │    │
│  └───────────────────────────────────────┬─────────────────────────────────────────────────┘    │
│                                          │                                                       │
│                                          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                                          │    │
│  │  2. URL Analysis                                                                         │    │
│  │     - Check for strong DR patterns (highest priority)                                    │    │
│  │     - Check for hostname matches                                                         │    │
│  │     - Check for environment patterns in URL                                              │    │
│  │                                                                                          │    │
│  └───────────────────────────────────────┬─────────────────────────────────────────────────┘    │
│                                          │                                                       │
│                                          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                                          │    │
│  │  3. Organization ID Detection                                                            │    │
│  │     - Extract org ID from localStorage                                                   │    │
│  │     - Map org ID to environment (DR, TEST, DEV)                                          │    │
│  │                                                                                          │    │
│  └───────────────────────────────────────┬─────────────────────────────────────────────────┘    │
│                                          │                                                       │
│                                          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                                          │    │
│  │  4. Environment Update Decision                                                          │    │
│  │     - Compare detection methods by confidence level                                      │    │
│  │     - Special case: DR detection can override TEST detection                             │    │
│  │     - For bookmark navigation: Force environment reset and prioritize DR detection       │    │
│  │                                                                                          │    │
│  └───────────────────────────────────────┬─────────────────────────────────────────────────┘    │
│                                          │                                                       │
│                                          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                                          │    │
│  │  5. Badge Update                                                                         │    │
│  │     - Update badge UI with environment (DR, TEST, DEV)                                   │    │
│  │     - Store environment in extension storage                                             │    │
│  │     - Notify all relevant tabs about environment change                                  │    │
│  │                                                                                          │    │
│  └─────────────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Key Components and Their Roles

1. **Tab Monitor** (background/monitors/tab-monitor.js)
   - Monitors tab navigation, activation, and URL changes
   - Detects bookmark navigation
   - Triggers environment detection process

2. **Environment Service** (background/environment-service.js)
   - Analyzes URLs for environment indicators
   - Processes organization IDs
   - Makes environment update decisions based on confidence levels
   - Notifies tabs about environment changes

3. **Content Script** (content/main.js)
   - Sets up navigation monitoring in each tab
   - Creates and updates the environment badge
   - Communicates with background script

4. **Environment Detection** (content/environment-detection.js)
   - Detects environment from URL patterns
   - Extracts organization IDs from localStorage
   - Updates badge UI based on detected environment

5. **Badge UI** (content/badge-ui.js)
   - Creates and styles the environment badge
   - Updates badge appearance based on environment (DR, TEST, DEV)

## Fix Implementation

The bookmark navigation issue was fixed by:

1. Adding explicit detection for bookmark navigation in tab-monitor.js
2. Clearing tab-specific environment cache when bookmark navigation is detected
3. Enhancing URL detection to always check for strong DR patterns
4. Modifying environment update logic to prioritize DR environment detection
5. Implementing immediate badge updates when strong DR patterns are detected
6. Adding multiple verification points to ensure correct badge display