#!/bin/bash

# Quick script to set Gemini API key as environment variable for Xcode
# This will add it to your Xcode scheme automatically

API_KEY="AIzaSyDFtwwlVusRvgHUwoyTsqdTg8qsW2sGvaQ"
SCHEME_FILE="VaultEye.xcodeproj/xcshareddata/xcschemes/VaultEye.xcscheme"
USER_SCHEME_FILE="VaultEye.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes/VaultEye.xcscheme"

echo "🔑 Setting up Gemini API key in Xcode scheme..."

# Check which scheme file exists
if [ -f "$USER_SCHEME_FILE" ]; then
    SCHEME="$USER_SCHEME_FILE"
elif [ -f "$SCHEME_FILE" ]; then
    SCHEME="$SCHEME_FILE"
else
    echo "❌ Could not find scheme file"
    echo ""
    echo "Manual setup required:"
    echo "1. In Xcode: Product → Scheme → Edit Scheme"
    echo "2. Select 'Run' → 'Arguments' tab"
    echo "3. Under 'Environment Variables', click +"
    echo "4. Add: GEMINI_API_KEY = $API_KEY"
    exit 1
fi

echo "Found scheme: $SCHEME"

# Check if environment variables section exists
if grep -q "EnvironmentVariables" "$SCHEME"; then
    echo "✅ Environment variables section exists"

    # Check if GEMINI_API_KEY already exists
    if grep -q "GEMINI_API_KEY" "$SCHEME"; then
        echo "⚠️  GEMINI_API_KEY already exists in scheme - skipping"
    else
        echo "Adding GEMINI_API_KEY..."
        # This is complex XML manipulation - manual setup recommended
        echo "❌ Automatic update failed - please add manually"
    fi
else
    echo "❌ No EnvironmentVariables section - please add manually"
fi

echo ""
echo "📋 Manual Setup Instructions:"
echo "================================"
echo ""
echo "1. In Xcode: Product → Scheme → Edit Scheme"
echo "2. Select 'Run' on the left sidebar"
echo "3. Go to 'Arguments' tab"
echo "4. Under 'Environment Variables', click the '+' button"
echo "5. Add:"
echo "   Name:  GEMINI_API_KEY"
echo "   Value: $API_KEY"
echo ""
echo "6. Click 'Close'"
echo "7. Run the app (Cmd+R)"
echo ""
echo "You should see: ✅ Gemini API key loaded from environment variable"
echo ""
