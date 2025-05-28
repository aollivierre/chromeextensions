# Release Notes - Genesys Cloud DR Shortcut v2.1.0

**Release Date:** December 19, 2024  
**Release Type:** Minor Version - SSO & Extension Optimization  
**Compatibility:** SCCM Application Deployment  

## 🚀 What's New in v2.1.0

### Enterprise SSO Optimization
The v2.1.0 release addresses critical enterprise authentication and extension compatibility requirements by **removing the dedicated Chrome profile** approach in favor of using the **default Chrome profile**.

**Key Benefits:**
- 🔐 **Seamless Microsoft Entra SSO**: Leverages existing authentication tokens
- 🔌 **Full Extension Compatibility**: All Chrome extensions work immediately
- ⚡ **Faster Performance**: No profile initialization overhead
- 🧹 **Zero Maintenance**: No temp folder cleanup required

### The Problem Solved
**Previous Challenge (v2.0.0):**
- Dedicated Chrome profile required users to re-authenticate via SSO
- Chrome extensions (including visual indicators) had caching issues
- Old extension versions would get stuck in temp profile folder
- Required periodic cleanup of `C:\Temp\GenesysPOC\ChromeUserData`

**New Solution (v2.1.0):**
- Uses default Chrome profile with existing SSO tokens
- Extensions work immediately with current versions
- No temp folder dependencies or cleanup needed
- One-click access to Genesys DR without authentication prompts

## 🔧 Technical Changes

### Chrome Arguments Update
**Previous (v2.0.0):**
```cmd
--app=URL --force-dark-mode --user-data-dir="C:\Temp\GenesysPOC\ChromeUserData" --no-first-run
```

**Current (v2.1.0):**
```cmd
--app=URL --force-dark-mode --no-first-run
```

### Script Improvements
- ✅ **Removed**: Dedicated profile creation logic
- ✅ **Removed**: Temp folder creation and management
- ✅ **Maintained**: All existing validation and error handling
- ✅ **Enhanced**: SSO and extension compatibility

## 📋 Deployment Guide

### SCCM Configuration (No Changes Required)

**Installation Command:** *(Same as v2.0.0)*
```cmd
wscript.exe //B "CreateDRShortcut_Enhanced.vbs"
```

**Detection Method:** *(Same as v2.0.0)*
- Type: Script (VBScript)
- Content: Paste full content of `DetectDRShortcut_Enhanced.vbs`

**Uninstall Command:** *(Same as v2.0.0)*
```cmd
wscript.exe //B "DeleteDRShortcut.vbs"
```

### Migration from v2.0.0

**Required Actions:**
1. ✅ Update SCCM application package with v2.1.0 scripts
2. ✅ Test SSO functionality in pilot environment
3. ✅ Verify extension compatibility

**Optional Cleanup:**
- Remove existing temp folders: `C:\Temp\GenesysPOC\ChromeUserData` (will no longer be used)

**No Configuration Changes:**
- ✅ Same SCCM detection method
- ✅ Same installation/uninstall commands
- ✅ Same validation and error handling

## 📈 Performance & User Experience

### Authentication Improvements
- **v2.0.0:** Required re-authentication via Microsoft Entra SSO
- **v2.1.0:** Seamless authentication using existing tokens

### Extension Support
- **v2.0.0:** Extension caching issues, old versions stuck in profile
- **v2.1.0:** Current extensions work immediately, no caching problems

### Startup Performance
- **v2.0.0:** Profile initialization overhead
- **v2.1.0:** Instant startup using existing profile

### Maintenance
- **v2.0.0:** Periodic temp folder cleanup required
- **v2.1.0:** Zero maintenance overhead

## ⚠️ Compatibility Notes

### Backwards Compatibility
- ✅ **Fully Compatible**: v2.1.0 scripts work with shortcuts created by v2.0.0
- ✅ **No Breaking Changes**: Existing SCCM configuration remains valid
- ✅ **Enhanced Validation**: All existing validation logic preserved

### Environment Requirements
- **Chrome**: Same requirements as v2.0.0
- **SCCM**: Same configuration as v2.0.0
- **SSO**: Microsoft Entra ID (benefits from existing tokens)
- **Extensions**: Works with all standard Chrome extensions

## 🎯 Enterprise Benefits

### For IT Administrators
- 🔧 **Simplified Deployment**: No configuration changes required
- 📊 **Better Monitoring**: Fewer user authentication issues
- 🧹 **Reduced Maintenance**: No temp folder cleanup needed
- 📈 **Improved Success Rate**: Fewer SSO-related deployment failures

### For End Users
- ⚡ **Instant Access**: No re-authentication prompts
- 🔌 **Full Functionality**: All Chrome extensions work immediately
- 🎯 **Consistent Experience**: Same Chrome environment as normal browsing
- 💨 **Faster Performance**: Quicker startup times

---

**Deployment Recommendation:** Update to v2.1.0 immediately to benefit from improved SSO compatibility and extension support. No SCCM configuration changes required.

---

# Release Notes - Genesys Cloud DR Shortcut v2.0.0

**Release Date:** December 19, 2024  
**Release Type:** Major Version - Production Ready  
**Compatibility:** SCCM Application Deployment  

## 🚀 What's New

### Critical OneDrive Sync Protection
The most significant improvement in v2.0.0 addresses a critical issue discovered in enterprise environments where **OneDrive sync creates shortcuts before SCCM deployment**, leading to false positive detections.

**The Problem Solved:**
- OneDrive syncs shortcuts from other devices to new laptops
- Shortcuts appear WITHOUT icons (OneDrive doesn't sync icon files)
- Basic detection incorrectly reports "DETECTED" 
- SCCM skips installation thinking the app is already installed

**The Solution:**
- Enhanced detection validates icon file existence
- Prevents false positives in OneDrive-enabled environments
- Ensures applications are only marked as "detected" when properly installed

### Enhanced Validation & Reliability

**5-Point Validation System:**
1. ✅ Shortcut file existence
2. ✅ Target path verification (Chrome executable)
3. ✅ Argument pattern matching (DR URL)
4. ✅ **Icon file validation** (OneDrive protection)
5. ✅ Shortcut icon location verification

**Chrome Installation Detection:**
- Automatically detects x64 and x86 Chrome installations
- Fallback logic for different installation paths
- Prevents failures on systems with non-standard Chrome locations

**Comprehensive Error Handling:**
- Specific exit codes (0-10) for different failure scenarios
- Graceful handling of corrupted shortcuts
- Directory creation with error validation

## 🔧 Technical Improvements

### Path Resolution Enhancement
- **Fixed:** Script directory resolution using `WScript.ScriptFullName`
- **Solved:** Exit code 2 failures when run from different working directories
- **Improved:** Icon file location now relative to script location

### SCCM Compatibility Optimization
- **Detection Method:** Follows SCCM text-output conventions (not exit codes)
- **Silent Execution:** Enhanced `//B` flag compatibility
- **Error Handling:** Proper silent failure modes for enterprise deployment

### Security & Validation
- Multiple validation checkpoints prevent incomplete installations
- File existence verification before all operations
- Enhanced corruption detection and recovery

## 📋 Deployment Guide

### SCCM Configuration

**Installation Command:**
```cmd
wscript.exe //B "CreateDRShortcut_Enhanced.vbs"
```

**Detection Method:**
- Type: Script (VBScript)
- Content: Paste full content of `DetectDRShortcut_Enhanced.vbs`

**Uninstall Command:**
```cmd
wscript.exe //B "DeleteDRShortcut.vbs"
```

### Pre-Deployment Checklist

- [ ] Verify `GenesysCloud_DR_256.ico` is in the same directory as scripts
- [ ] Test installation in pilot environment
- [ ] Validate detection in OneDrive sync environment
- [ ] Confirm Chrome is available on target systems
- [ ] Update SCCM application with new script content

### Testing Commands

**Local Testing:**
```cmd
# Test installation
wscript.exe //B "CreateDRShortcut_Enhanced.vbs"

# Test detection
cscript.exe "DetectDRShortcut_Enhanced.vbs"

# Test uninstall
wscript.exe //B "DeleteDRShortcut.vbs"
```

## ⚠️ Breaking Changes

### Detection Method Update Required
- **v1.0.0 Detection:** Basic shortcut validation only
- **v2.0.0 Detection:** Includes icon file validation (OneDrive protection)

**Impact:** Shortcuts created by v1.0.0 without proper icon installation may not be detected by v2.0.0 detection script. This is intentional behavior to ensure proper installation validation.

**Mitigation:** Update SCCM detection method with v2.0.0 script content.

## 🐛 Issues Resolved

| Issue | Description | Resolution |
|-------|-------------|------------|
| OneDrive False Positives | Detection reported installed when only shortcut synced | Icon validation prevents false positives |
| Exit Code 2 Failures | Script failed when icon not in working directory | Path resolution uses script directory |
| Chrome Path Variations | Failed on x86 or non-standard Chrome paths | Multi-path detection with fallback |
| Silent Execution Issues | Popups during SCCM deployment | Enhanced `//B` flag handling |

## 📈 Performance & Reliability

### Validation Improvements
- **v1.0.0:** 2-point basic validation
- **v2.0.0:** 5-point comprehensive validation

### Error Handling
- **v1.0.0:** Basic error handling
- **v2.0.0:** Specific exit codes with detailed error scenarios

### Environment Support
- **Enhanced:** OneDrive sync environments
- **Enhanced:** Variable Chrome installation paths
- **Enhanced:** SCCM enterprise deployment scenarios

## 🔮 Future Considerations

### Monitoring Recommendations
- Monitor SCCM deployment success rates in OneDrive environments
- Track detection accuracy improvements
- Validate error code distribution for troubleshooting

### Potential Enhancements
- Additional browser support (if required)
- Enhanced logging capabilities (if needed for troubleshooting)
- Registry-based detection alternatives (if file-based validation limitations discovered)

## 📞 Support Information

### Troubleshooting
See `README.md` for comprehensive troubleshooting guide including:
- Common error codes and solutions
- OneDrive sync environment considerations
- SCCM deployment best practices

### Documentation
- `README.md`: Complete deployment and configuration guide
- `CHANGELOG.md`: Detailed version history and changes
- `Shortcut-Truncation-Note.md`: Windows shortcut display limitations

---

**Deployment Recommendation:** Test in pilot environment before enterprise-wide rollout to validate OneDrive sync protection effectiveness in your specific environment. 