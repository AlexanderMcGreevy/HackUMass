# Background Scan Setup Guide

## Overview
The VaultEye app now includes a background scanning system that can process your photo library even when the app is closed. This guide explains how to configure the required permissions and test the functionality.

## Info.plist Configuration

Since Xcode auto-generates the Info.plist, you need to add these entries through Xcode:

### 1. Background Task Identifier
1. Open the project in Xcode
2. Select the VaultEye target
3. Go to the "Info" tab
4. Click the "+" button to add a new key
5. Add key: `BGTaskSchedulerPermittedIdentifiers` (Array)
6. Add item: `com.vaulteye.scan` (String)

### 2. Background Modes
1. Select the VaultEye target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "Background Modes"
4. Check "Background processing"

### 3. Privacy Descriptions (if not already present)
Add these in the "Info" tab:

- `NSPhotoLibraryUsageDescription`: "VaultEye needs access to your photos to scan for sensitive information"
- `NSPhotoLibraryAddUsageDescription`: "VaultEye needs to save redacted images to your photo library"
- `NSUserNotificationsUsageDescription`: "VaultEye sends notifications when background scans complete"

## XML Format (for reference)

If you need to manually edit Info.plist, add these entries:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.vaulteye.scan</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>

<key>NSPhotoLibraryUsageDescription</key>
<string>VaultEye needs access to your photos to scan for sensitive information</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>VaultEye needs to save redacted images to your photo library</string>

<key>NSUserNotificationsUsageDescription</key>
<string>VaultEye sends notifications when background scans complete</string>
```

## Core ML Model Integration

The `ImageClassifier.swift` currently uses a mock classifier for testing. To integrate your actual Core ML model:

1. Add your `.mlmodel` file to the Xcode project
2. Xcode will auto-generate a Swift class for your model
3. Update `ImageClassifier.swift` line 33:

```swift
// Replace this line:
let mlModel = try createPlaceholderModel()

// With this:
let mlModel = try YourModelName(configuration: MLModelConfiguration()).model
```

4. In `BackgroundScanManager.swift` line 235, replace:
```swift
let confidence = await classifier.mockConfidence(for: cgImage)
```

With:
```swift
let confidence = try await classifier.confidence(for: cgImage)
```

## Testing Background Tasks

### In Simulator
Background tasks don't run automatically in the simulator. To test:

1. Run the app and start a scan
2. In Xcode, go to Debug → Simulate Background Fetch
3. Or use the command:
   ```bash
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.vaulteye.scan"]
   ```

### On Device
1. Install the app on a physical device
2. Start a scan
3. Close the app (swipe up to force quit)
4. Wait 5-10 minutes
5. iOS will eventually run the background task
6. You'll receive a notification when complete

Note: iOS decides when to run background tasks based on system load, battery, etc.

## Architecture

### Files Created

- **BackgroundScanManager.swift**: Main orchestration class
- **ImageClassifier.swift**: Core ML wrapper
- **ResultStore.swift**: JSON-based persistence
- **PhotoAccess.swift**: Photo library utilities
- **NotificationHelper.swift**: Local notification handling
- **BGTasks.swift**: Background task registration
- **ScanScreen.swift**: UI for scan control
- **SelectedImagesView.swift**: Display matched images

### Flow

1. User taps "Start Scan" in the ScanScreen tab
2. App requests Photos + Notifications permissions
3. Fetches all image asset IDs from Photos library
4. Processes images in batches, checkpointing every 20 images
5. If app goes to background, schedules BGProcessingTask
6. Background task continues processing from last checkpoint
7. On completion, saves results and sends notification
8. Matched images appear in the "Matched" tab

### Persistence

State is saved to: `Library/Application Support/ScanState.json`

Contains:
- List of all asset IDs to process
- Current cursor position
- Set of selected asset IDs (matched threshold)
- Completion status

### Memory Management

- Images are downscaled to max 1024x1024 before classification
- Assets processed in batches
- State checkpointed every 20 images
- Background task handles expiration gracefully

## Troubleshooting

### "Background task not running"
- Check that BGTaskSchedulerPermittedIdentifiers includes `com.vaulteye.scan`
- Verify Background Modes includes "Background processing"
- Background tasks only run on real devices (not simulator) unless simulated

### "No images found"
- Grant Photos permission when prompted
- Check that you have images in your Photos library

### "Classification errors"
- Ensure you've integrated a real Core ML model
- Check that the model is added to the Xcode target
- Verify model input/output types match expectations

## Integration with Existing Features

The background scan system works alongside your existing:
- Photo detection and flagging
- Swipe-to-delete/keep interface
- Text redaction feature

The "Matched" tab shows images that passed the ML confidence threshold, while the main "Photos" tab shows your existing detection results.
