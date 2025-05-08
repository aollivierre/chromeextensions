# Chrome Extension Resources for Genesys Cloud

This repository contains tools to prepare assets for a Genesys Cloud Chrome extension.

## Icon Generator

Creates properly formatted Chrome extension icons with a "DR" indicator in the bottom-right corner.

### Requirements

- Python 3.6 or higher
- PIL/Pillow library (`pip install pillow>=10.0.0`)

### Icon Files

- `create_chrome_extension_icon.py` - Python script to generate the Chrome extension icon
- `CreateChromeExtensionIcon.ps1` - PowerShell script to easily run the Python script on Windows
- `GenesysCloud_icon.ico` - Original icon to use as base (required)

### Chrome Extension Icon Requirements

The generated icon follows Chrome extension requirements:
- 128x128 pixel total size
- 96x96 pixel actual icon size with 16px padding on all sides
- PNG format
- Red "DR" indicator in the bottom-right corner
- Subtle white glow to ensure visibility on dark backgrounds

## Screenshot Formatter

Formats screenshots to meet Chrome Web Store requirements.

### Screenshot Files

- `format_screenshot.py` - Python script to format a single screenshot
- `format_all_screenshots.py` - Python script to format all screenshots in a directory
- `Format-Screenshots.ps1` - PowerShell script to easily run either Python script

### Chrome Web Store Screenshot Requirements

- Exact size: 1280x800 or 640x400 pixels
- JPEG or 24-bit PNG with no alpha (transparency)
- Maximum of 5 screenshots allowed
- At least one screenshot required

### Using the Screenshot Formatter

#### Format a Single Screenshot

PowerShell:
```
.\Format-Screenshots.ps1 -InputPath "path\to\screenshot.png" -OutputPath "formatted_screenshot.png" -Size "1280x800" -SingleFile
```

Python:
```
python format_screenshot.py "path/to/screenshot.png" "formatted_screenshot.png" "1280x800"
```

#### Format All Screenshots in a Directory

PowerShell:
```
.\Format-Screenshots.ps1 -InputPath "path\to\screenshots" -OutputPath "formatted_screenshots" -Size "1280x800"
```

Python:
```
python format_all_screenshots.py "path/to/screenshots" "formatted_screenshots" "1280x800"
```

## Customization

Edit the Python scripts to change:
- Icon indicator size or position
- Screenshot formatting options
- Text content, size, or font
- Glow intensity 