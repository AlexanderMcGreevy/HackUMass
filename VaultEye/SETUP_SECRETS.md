# API Keys Setup Guide

This guide explains how to securely configure API keys for VaultEye without exposing them in Git.

## Quick Setup (Recommended)

### Option A: Using the Configuration Script

```bash
# Run the configuration script with your API key
./configure-secrets.sh YOUR_ACTUAL_API_KEY_HERE

# Or run without arguments for interactive setup
./configure-secrets.sh
```

### Option B: Manual Setup

### 1. Configure Gemini API Key

The `Secrets.xcconfig` file is already created but needs your actual API key:

```bash
# Edit the Secrets.xcconfig file
open Secrets.xcconfig
```

Replace `YOUR_GEMINI_API_KEY_HERE` with your actual Gemini API key:

```
GEMINI_API_KEY = AIzaSyABC123YourActualKeyHere
```

### 2. Get Your Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key
5. Paste it into `Secrets.xcconfig`

### 3. Add the Config File to Xcode (One-time setup)

If not already configured in Xcode:

1. Open `VaultEye.xcodeproj` in Xcode
2. Select the VaultEye target
3. Go to "Build Settings" tab
4. Search for "Based on Configuration File"
5. For both Debug and Release:
   - Click the dropdown
   - Select "Secrets" (Secrets.xcconfig)

### 4. Verify Setup

Build and run the app. Check the console for:
- ✅ If working: `🔍 Starting Gemini analysis for photo: [id]`
- ⚠️ If not configured: `Gemini analysis skipped - service not configured`

## How It Works

### Security Architecture

1. **Secrets.xcconfig** (Git-ignored)
   - Contains actual API keys
   - Never committed to Git
   - Excluded in `.gitignore`

2. **Secrets.xcconfig.template** (Git-tracked)
   - Template file showing required keys
   - Committed to Git for team reference
   - Contains placeholder values

3. **Info.plist Integration**
   - Xcode reads `GEMINI_API_KEY` from xcconfig
   - Adds it to Info.plist at build time
   - App reads from Bundle at runtime

4. **Runtime Access**
   - `ContentView.makeGeminiService()` reads from Info.plist
   - Falls back to environment variable if not in plist
   - Returns `nil` if no key found (disables AI analysis)

### File Structure

```
VaultEye/
├── .gitignore                    # Excludes Secrets.xcconfig
├── Secrets.xcconfig              # YOUR API KEYS (Git-ignored) ⚠️
├── Secrets.xcconfig.template     # Template (Git-tracked) ✓
├── SETUP_SECRETS.md             # This file
└── VaultEye/
    └── ContentView.swift         # Reads from Info.plist
```

## Troubleshooting

### "Service not configured" error

**Problem**: Gemini analysis not running

**Solutions**:
1. Check `Secrets.xcconfig` has your real API key (not placeholder)
2. Verify xcconfig is linked in Xcode Build Settings
3. Clean build folder (Cmd+Shift+K) and rebuild
4. Check console for specific error messages

### API Key not working

**Problem**: Invalid API key error

**Solutions**:
1. Verify key is correct (copy/paste from AI Studio)
2. Check no extra spaces or quotes in xcconfig
3. Ensure API key has correct permissions in Google Cloud Console
4. Check API key hasn't expired

### For Team Members

**First-time setup**:
1. Clone the repository
2. Copy `Secrets.xcconfig.template` to `Secrets.xcconfig`
3. Add your own Gemini API key
4. Never commit `Secrets.xcconfig`

**Sharing keys securely**:
- Use a password manager (1Password, LastPass)
- Or secure messaging (Signal, encrypted email)
- Never commit to Git or share in plain text

## Alternative: Environment Variable

You can also use an environment variable instead of xcconfig:

### Option 1: Xcode Scheme Environment Variable

1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add: `GEMINI_API_KEY` = `your-key-here`

### Option 2: Launch Arguments

Pass at runtime (useful for testing):
```swift
// In your test setup
ProcessInfo.processInfo.environment["GEMINI_API_KEY"] = "test-key"
```

## Security Best Practices

✅ **DO**:
- Keep `Secrets.xcconfig` local only
- Use `.gitignore` to exclude secrets
- Rotate API keys periodically
- Use different keys for dev/prod
- Share keys through secure channels

❌ **DON'T**:
- Commit API keys to Git
- Share keys in chat/email
- Use production keys in development
- Hard-code keys in source files
- Upload keys to public repos

## Verifying Git Exclusion

Check that secrets are not tracked:

```bash
# Should show "Secrets.xcconfig" is ignored
git status

# Should NOT list Secrets.xcconfig
git ls-files | grep Secrets
```

## For CI/CD (GitHub Actions, etc.)

Add secrets as repository secrets:

1. GitHub → Settings → Secrets → Actions
2. Add `GEMINI_API_KEY`
3. Reference in workflow: `${{ secrets.GEMINI_API_KEY }}`

---

**Remember**: The security of your API keys is critical. Treat them like passwords and never expose them publicly.
