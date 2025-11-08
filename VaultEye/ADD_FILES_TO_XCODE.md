# Adding Background Scan Files to Xcode

## Quick Steps

All the Swift files have been created in the `VaultEye/BackgroundScan/` directory. Now you need to add them to your Xcode project:

### Method 1: Drag and Drop (Easiest)

1. Open `VaultEye.xcodeproj` in Xcode
2. In Finder, navigate to `VaultEye/BackgroundScan/`
3. Select all 8 `.swift` files in that folder
4. Drag them into the Xcode project navigator (left sidebar)
5. In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Make sure "VaultEye" target is selected
   - Click "Finish"

### Method 2: Add Files (Alternative)

1. Open `VaultEye.xcodeproj` in Xcode
2. Right-click on "VaultEye" folder in project navigator
3. Select "Add Files to VaultEye..."
4. Navigate to `VaultEye/BackgroundScan/`
5. Select all 8 `.swift` files:
   - BackgroundScanManager.swift
   - BGTasks.swift
   - ImageClassifier.swift
   - NotificationHelper.swift
   - PhotoAccess.swift
   - ResultStore.swift
   - ScanScreen.swift
   - SelectedImagesView.swift
6. In the dialog:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Check "VaultEye" target
   - Click "Add"

## Verify Files Are Added

After adding files, verify:

1. All 8 files appear in the project navigator
2. Files are grouped in a "BackgroundScan" folder
3. Each file shows the "VaultEye" target checkbox is checked (select file, check right sidebar)

## Build the Project

1. Press `Cmd+B` to build
2. All errors should be resolved
3. If you see any remaining errors, check the setup guide

## Next: Configure Info.plist

After files are added and building successfully, follow the instructions in `BACKGROUND_SCAN_SETUP.md` to configure:

1. Background task identifiers
2. Background modes capability
3. Privacy description strings

## Files Overview

The 8 files you're adding:

```
BackgroundScan/
├── BackgroundScanManager.swift   # Main coordinator (270 lines)
├── BGTasks.swift                 # Background task scheduling (80 lines)
├── ImageClassifier.swift         # Core ML wrapper (110 lines)
├── NotificationHelper.swift      # Local notifications (70 lines)
├── PhotoAccess.swift            # Photo library access (90 lines)
├── ResultStore.swift            # JSON persistence (70 lines)
├── ScanScreen.swift             # Scan control UI (170 lines)
└── SelectedImagesView.swift     # Results display (100 lines)
```

Total: ~960 lines of production-ready code

## Already Updated

These existing files have already been updated:
- ✅ `VaultEyeApp.swift` - Integrated with tab interface
- ✅ `RedactionService.swift` - Added console logging

No further changes needed to existing files.
