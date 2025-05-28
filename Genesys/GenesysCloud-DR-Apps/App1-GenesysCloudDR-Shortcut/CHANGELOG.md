# Changelog

All notable changes to the Genesys Cloud DR Shortcut project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2024-12-19

### Changed
- **Chrome Profile Strategy**: Removed `--user-data-dir` parameter to use default Chrome profile instead of dedicated profile
- **SSO Compatibility**: Now leverages existing Microsoft Entra SSO tokens for seamless authentication
- **Extension Support**: All Chrome extensions now work immediately without caching issues

### Removed
- **Dedicated Profile Logic**: Removed temp folder creation (`C:\Temp\GenesysPOC\ChromeUserData`)
- **Profile Isolation**: Eliminated separate Chrome profile to prevent SSO and extension compatibility issues

### Fixed
- **Extension Caching Issues**: Resolved problem where old extension versions would get stuck in dedicated profile
- **SSO Re-authentication**: Eliminated need for users to re-authenticate when using SSO-based systems
- **Maintenance Overhead**: Removed need to periodically clean temp folders

### Benefits
- ✅ **Seamless Microsoft Entra SSO**: Authentication tokens from default profile work immediately
- ✅ **Current Extensions**: Visual indicator extensions and other Chrome extensions work without version conflicts
- ✅ **Better UX**: One-click access without additional authentication prompts
- ✅ **Simplified Maintenance**: No temp folder cleanup or profile management needed

## [2.0.0] - 2024-12-19

### Added
- **Critical OneDrive Sync Protection**: Detection now validates icon file existence to prevent false positives when OneDrive syncs shortcuts without icons
- **Chrome Installation Validation**: Creation script automatically detects and handles both x64 and x86 Chrome installations
- **Comprehensive Error Handling**: Added specific exit codes (0-10) for different failure scenarios in creation script
- **Path Resolution Enhancement**: Scripts now use script directory instead of current working directory for icon file location
- **5-Point Validation System**: Enhanced detection with target validation, argument matching, icon validation, icon location verification, and Chrome existence checks
- **Corruption Protection**: Detection script gracefully handles corrupted shortcut files
- **Directory Safety**: Creation script ensures all required directories exist before operations

### Changed
- **BREAKING**: Detection method now requires icon file validation - older shortcuts without proper icon installation will not be detected
- **Script Naming**: Renamed to `CreateDRShortcut_Enhanced.vbs` and `DetectDRShortcut_Enhanced.vbs` to reflect comprehensive improvements
- **Detection Logic**: Now uses silent exit instead of exit codes for SCCM compatibility
- **Icon Location**: Changed from relative to absolute path resolution using `WScript.ScriptFullName`

### Fixed
- **OneDrive Sync False Positives**: Prevents SCCM from skipping installation when OneDrive-synced shortcuts exist without proper setup
- **Icon Path Resolution**: Fixed script failing with exit code 2 when run from different working directories
- **Chrome Path Detection**: Added fallback logic for different Chrome installation paths
- **Silent Execution**: Ensured proper background mode execution with `//B` flag compatibility

### Security
- **Enhanced Validation**: Multiple checkpoints prevent execution with invalid or incomplete installations
- **File Existence Verification**: All file operations now include existence checks before proceeding

## [1.0.0] - 2024-12-18

### Added
- Initial release with basic shortcut creation and detection functionality
- `CreateDRShortcut.vbs`: Basic shortcut creation with hardcoded paths
- `DetectDRShortcut.vbs`: Basic detection using shortcut properties
- `DeleteDRShortcut.vbs`: Shortcut removal functionality
- `GenesysCloud_DR_256.ico`: Custom icon for visual differentiation
- Support for Chrome application mode with DR environment URL
- SCCM deployment configuration documentation

### Features
- Desktop shortcut creation pointing to Genesys Cloud DR environment
- Custom icon integration for visual identification
- Silent installation support with Windows Script Host
- Basic detection for SCCM application deployment
- User-targeted deployment compatibility

---

## Version Comparison

### v2.1.0 vs v2.0.0 vs v1.0.0

| Feature | v1.0.0 | v2.0.0 | v2.1.0 |
|---------|--------|--------|--------|
| OneDrive Sync Protection | ❌ None | ✅ Icon validation prevents false positives | ✅ Icon validation prevents false positives |
| Chrome Detection | ❌ Single path only | ✅ Multi-path detection with fallback | ✅ Multi-path detection with fallback |
| Error Handling | ❌ Basic | ✅ Comprehensive with specific exit codes | ✅ Comprehensive with specific exit codes |
| Path Resolution | ❌ Working directory dependent | ✅ Script directory based | ✅ Script directory based |
| Validation Points | ❌ 2-point basic | ✅ 5-point comprehensive | ✅ 5-point comprehensive |
| Corruption Handling | ❌ None | ✅ Graceful error handling | ✅ Graceful error handling |
| Directory Safety | ❌ Assumes directories exist | ✅ Creates directories with error handling | ✅ Creates directories with error handling |
| Chrome Profile | ❌ Default profile (basic) | ❌ Dedicated profile (isolation) | ✅ Default profile (SSO optimized) |
| SSO Compatibility | ❌ Basic | ❌ Requires re-authentication | ✅ Seamless Microsoft Entra SSO |
| Extension Support | ❌ Basic | ❌ Caching issues possible | ✅ Full compatibility, no caching issues |

## Migration Notes

### From v2.0.0 to v2.1.0

**SCCM Configuration Changes:**
- ✅ **No SCCM changes required**: Same scripts, only internal Chrome arguments changed
- ✅ **Automatic Benefits**: Existing deployments will benefit from improved SSO and extension compatibility
- ✅ **Backwards Compatible**: v2.1.0 scripts work with shortcuts created by v2.0.0

**User Experience Improvements:**
- **SSO**: Users will no longer need to re-authenticate when clicking the DR shortcut
- **Extensions**: All Chrome extensions (including visual indicators) will work immediately
- **Performance**: Faster startup due to no temp profile initialization

**Recommended Actions:**
1. Update SCCM application with v2.1.0 scripts
2. Test SSO functionality in pilot environment
3. Verify extension compatibility works as expected
4. Clean up any existing temp folders (optional): `C:\Temp\GenesysPOC\ChromeUserData`

### From v1.0.0 to v2.0.0

**SCCM Configuration Changes Required:**
- Update installation command to use `CreateDRShortcut_Enhanced.vbs`
- Update detection method to use `DetectDRShortcut_Enhanced.vbs` content
- No changes required for uninstallation command

**Compatibility:**
- v2.0.0 scripts can detect and work with shortcuts created by v1.0.0
- Enhanced validation may require re-deployment in OneDrive sync environments
- All existing functionality preserved with additional validation layers

**Recommended Upgrade Path:**
1. Deploy v2.0.0 creation script in SCCM
2. Update detection method with v2.0.0 script content
3. Test in pilot group before full deployment
4. Monitor for any OneDrive sync related detection improvements 