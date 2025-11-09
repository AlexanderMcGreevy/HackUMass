# Rename App to Obscurafy - Xcode Setup

## App Name Changed: VaultEye → Obscurafy

The app has been renamed from **VaultEye** to **Obscurafy**. Follow these steps to update your Xcode project.

## Required Xcode Configuration Changes

### 1. Update Display Name

1. Open Xcode project
2. Select **VaultEye** target
3. Go to **General** tab
4. Find **Display Name** field
5. Change from `VaultEye` to `Obscurafy`

### 2. Update Background Task Identifier

1. Select **VaultEye** target (you can rename this target later if desired)
2. Go to **Info** tab
3. Find **Permitted background task scheduler identifiers**
4. Change value from `com.vaulteye.scan` to `com.obscurafy.scan`

### 3. Update Privacy Descriptions

Update these three privacy descriptions in the **Info** tab:

**Privacy - Photo Library Usage Description:**
```
Obscurafy needs access to your photos to scan for sensitive information
```

**Privacy - Photo Library Additions Usage Description:**
```
Obscurafy needs to save redacted images to your photo library
```

**Privacy - User Notifications Usage Description:**
```
Obscurafy sends notifications when background scans complete
```

### 4. Update Bundle Identifier (Optional but Recommended)

1. Select **VaultEye** target
2. Go to **Signing & Capabilities** tab
3. Change **Bundle Identifier** from `com.yourname.VaultEye` to `com.yourname.Obscurafy`

**Note:** Changing bundle identifier means:
- App will be treated as new installation
- Previous scan data will not carry over
- Will need to grant permissions again

### 5. Rename Target (Optional)

If you want to rename the Xcode target itself:

1. Select **VaultEye** target in project navigator
2. Click on target name to edit
3. Rename to `Obscurafy`
4. Xcode will ask to rename schemes - click **Rename**

## Code Changes Already Made

The following code changes have already been made in the source files:

✅ Updated `BGTasks.taskIdentifier` to `com.obscurafy.scan`
✅ Updated all logger subsystems from `com.vaulteye.app` to `com.obscurafy.app`
✅ Updated user-facing permission message in ContentView
✅ Updated code comments with new task identifier
✅ Updated privacy description templates

## What Stays the Same

- All functionality remains identical
- File names and folder structure unchanged
- Test targets keep their names (or rename if desired)
- Git repository folder name unchanged

## Testing After Rename

1. Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Delete app from simulator/device
3. Build and run
4. Verify app shows as "Obscurafy" on home screen
5. Test background scanning still works
6. Verify notifications show "Obscurafy"

## Expected Results

**Home Screen:**
```
Before: 📱 VaultEye
After:  📱 Obscurafy
```

**Notifications:**
```
Before: "VaultEye: Scan complete..."
After:  "Obscurafy: Scan complete..."
```

**Permission Prompts:**
```
Before: "VaultEye needs access to..."
After:  "Obscurafy needs access to..."
```

**Background Tasks:**
```
Before: com.vaulteye.scan
After:  com.obscurafy.scan
```

## Quick Checklist

Use this checklist to verify all changes:

- [ ] Display Name changed to "Obscurafy"
- [ ] Background task identifier: `com.obscurafy.scan`
- [ ] Photo Library permission: mentions "Obscurafy"
- [ ] Photo Library Add permission: mentions "Obscurafy"
- [ ] Notifications permission: mentions "Obscurafy"
- [ ] Bundle identifier updated (optional)
- [ ] Target renamed (optional)
- [ ] Clean build completed
- [ ] App installed on device
- [ ] App name shows as "Obscurafy" on home screen
- [ ] Permissions request mentions "Obscurafy"
- [ ] Background scanning works
- [ ] Notifications display "Obscurafy"

## Troubleshooting

**App still shows "VaultEye" on home screen**
- Check Display Name in General tab
- Clean build and reinstall app

**Background tasks not working**
- Verify task identifier is `com.obscurafy.scan` in Info tab
- Check BGTasks.swift has correct identifier (already updated)
- Clean build and reinstall

**Permissions show old name**
- Update privacy descriptions in Info tab
- Reinstall app (permissions are cached)

**Build errors after rename**
- Clean build folder (Cmd+Shift+K)
- Close and reopen Xcode
- Verify no typos in bundle identifier

---

**The code is ready! Just update the Xcode project settings above.** 🎉
