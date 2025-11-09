# Quick Start - Add Your API Key

## Step 1: Add Your Gemini API Key (30 seconds)

Edit the `Secrets.xcconfig` file:

```bash
open Secrets.xcconfig
```

Replace this line:
```
GEMINI_API_KEY = YOUR_GEMINI_API_KEY_HERE
```

With your actual key:
```
GEMINI_API_KEY = AIzaSyABC123YourActualKeyHere
```

**Get your key**: https://aistudio.google.com/app/apikey

## Step 2: Build and Run

That's it! The app will now use your API key.

### How to verify it's working:

1. Build and run the app (Cmd+R)
2. Enable "AI Analysis" toggle in Background Scan tab
3. Run a scan
4. Go to Review tab
5. Check Xcode console for:
   ```
   🔍 Starting Gemini analysis for photo: [id]
   ✨ Gemini Analysis Results:
   ```

### Troubleshooting:

**If you see**: `⚠️ Gemini analysis skipped - service not configured`

Try this:
```bash
# Method 1: Add to Info.plist via Xcode
# Open VaultEye.xcodeproj
# Select VaultEye target → Info tab
# Add: GeminiAPIKey = $(GEMINI_API_KEY)

# Method 2: Use environment variable instead
# Edit scheme: Product → Scheme → Edit Scheme → Run → Arguments
# Add Environment Variable: GEMINI_API_KEY = your-key-here
```

**If you see**: `⚠️ Gemini analysis skipped - user has not consented`

Solution: Enable the "AI Analysis" toggle in the Background Scan tab.

## Security Notes:

✅ **Safe to commit**:
- `.gitignore`
- `Secrets.xcconfig.template`
- `SETUP_SECRETS.md`
- `configure-secrets.sh`

❌ **NEVER commit**:
- `Secrets.xcconfig` (contains your real API key)

The `.gitignore` file already protects `Secrets.xcconfig` from being committed.

---

For detailed setup instructions, see [SETUP_SECRETS.md](SETUP_SECRETS.md)
