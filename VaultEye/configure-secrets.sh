#!/bin/bash

# Configuration script for VaultEye API keys
# This script helps you securely configure your Gemini API key

set -e

SECRETS_FILE="Secrets.xcconfig"
TEMPLATE_FILE="Secrets.xcconfig.template"
PROJECT_FILE="VaultEye.xcodeproj/project.pbxproj"

echo "🔐 VaultEye Secrets Configuration"
echo "=================================="
echo ""

# Check if Secrets.xcconfig exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ $SECRETS_FILE not found!"

    if [ -f "$TEMPLATE_FILE" ]; then
        echo "📋 Creating $SECRETS_FILE from template..."
        cp "$TEMPLATE_FILE" "$SECRETS_FILE"
        echo "✅ Created $SECRETS_FILE"
    else
        echo "❌ Template file not found. Creating new $SECRETS_FILE..."
        cat > "$SECRETS_FILE" << 'EOF'
// Secrets.xcconfig
// This file contains sensitive API keys and should NEVER be committed to Git

// Gemini API Key
// Get your key from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY = YOUR_GEMINI_API_KEY_HERE
EOF
        echo "✅ Created new $SECRETS_FILE"
    fi
    echo ""
fi

# Check if API key is set
CURRENT_KEY=$(grep "GEMINI_API_KEY" "$SECRETS_FILE" | cut -d'=' -f2 | xargs)

if [ "$CURRENT_KEY" = "YOUR_GEMINI_API_KEY_HERE" ] || [ -z "$CURRENT_KEY" ]; then
    echo "⚠️  Gemini API key is not configured!"
    echo ""
    echo "To configure your API key:"
    echo "1. Get your API key from: https://aistudio.google.com/app/apikey"
    echo "2. Edit $SECRETS_FILE"
    echo "3. Replace YOUR_GEMINI_API_KEY_HERE with your actual key"
    echo ""
    echo "Or run this command:"
    echo "  ./configure-secrets.sh YOUR_ACTUAL_API_KEY"
    echo ""

    # Check if API key was provided as argument
    if [ ! -z "$1" ]; then
        echo "🔑 Setting API key from command line argument..."
        sed -i.bak "s/GEMINI_API_KEY = .*/GEMINI_API_KEY = $1/" "$SECRETS_FILE"
        rm "${SECRETS_FILE}.bak" 2>/dev/null || true
        echo "✅ API key configured in $SECRETS_FILE"
        echo ""
    else
        exit 1
    fi
else
    echo "✅ Gemini API key is configured"
    echo "   Key: ${CURRENT_KEY:0:10}..." # Show first 10 chars only
    echo ""
fi

# Verify .gitignore includes Secrets.xcconfig
if [ -f ".gitignore" ]; then
    if grep -q "Secrets.xcconfig" ".gitignore"; then
        echo "✅ $SECRETS_FILE is in .gitignore"
    else
        echo "⚠️  Adding $SECRETS_FILE to .gitignore..."
        echo "" >> .gitignore
        echo "# API Keys and Secrets" >> .gitignore
        echo "Secrets.xcconfig" >> .gitignore
        echo "✅ Added to .gitignore"
    fi
else
    echo "⚠️  No .gitignore found - creating one..."
    echo "Secrets.xcconfig" > .gitignore
    echo "✅ Created .gitignore"
fi
echo ""

# Check if xcconfig is in Xcode project
echo "📝 Next steps:"
echo ""
echo "1. Open VaultEye.xcodeproj in Xcode"
echo "2. Add Secrets.xcconfig to the project:"
echo "   - File → Add Files to VaultEye"
echo "   - Select Secrets.xcconfig"
echo "   - Uncheck 'Copy items if needed'"
echo "   - Click Add"
echo ""
echo "3. Configure build settings:"
echo "   - Select VaultEye target"
echo "   - Go to Build Settings"
echo "   - Search for 'User-Defined'"
echo "   - Add: INFOPLIST_KEY_GeminiAPIKey = \$(GEMINI_API_KEY)"
echo ""
echo "4. Clean and rebuild (Cmd+Shift+K, then Cmd+B)"
echo ""
echo "Or use this one-liner to add the build setting:"
echo ""
echo "  See SETUP_SECRETS.md for detailed instructions"
echo ""

echo "✅ Configuration complete!"
echo ""
echo "⚠️  IMPORTANT: Never commit $SECRETS_FILE to Git!"
echo ""
