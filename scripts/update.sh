#!/bin/bash

# Update script for DeepSeek-V2-Lite
# Downloads latest version from GitHub

set -e

echo "════════════════════════════════════════════════════════"
echo "  🔄 DeepSeek-V2-Lite Update"
echo "════════════════════════════════════════════════════════"
echo ""

# GitHub repository URL
GITHUB_REPO="https://github.com/will-codeit/deep_seek_llama.git"

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

echo "📍 Current location: $SCRIPT_DIR"
echo "📦 Repository: $GITHUB_REPO"
echo ""

# Backup user files before updating
echo "💾 Backing up your configuration and models..."
mkdir -p "$UPDATE_DIR/backup"

# Backup config file
if [ -f ".config" ]; then
    cp .config "$UPDATE_DIR/backup/.config"
    echo "  ✓ Saved configuration"
fi

# Backup models (don't re-download!)
if [ -d "models" ] && [ "$(ls -A models/*.gguf 2>/dev/null)" ]; then
    mkdir -p "$UPDATE_DIR/backup/models"
    cp models/*.gguf "$UPDATE_DIR/backup/models/" 2>/dev/null || true
    echo "  ✓ Saved downloaded models"
fi

echo ""
echo "🌐 Downloading latest version from GitHub..."
echo ""

# Clone the latest version
if git clone --depth 1 "$GITHUB_REPO" "$UPDATE_DIR/repo" 2>&1; then
    echo ""
    echo "✅ Downloaded latest version!"
    echo ""
    
    # Ask user to confirm update
    read -p "📋 Update found! Apply update now? [Y/n]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "🔄 Applying update..."
        
        # Copy new files (excluding models and config)
        rsync -av --delete \
            --exclude='models/' \
            --exclude='.config' \
            --exclude='.git' \
            --exclude='.gitignore' \
            --exclude='logs/' \
            --exclude='technical/llama.cpp/build/' \
            "$UPDATE_DIR/repo/" "$SCRIPT_DIR/"
        
        # Restore user files
        echo ""
        echo "�� Restoring your configuration and models..."
        
        if [ -f "$UPDATE_DIR/backup/.config" ]; then
            cp "$UPDATE_DIR/backup/.config" .config
            echo "  ✓ Restored configuration"
        fi
        
        if [ -d "$UPDATE_DIR/backup/models" ]; then
            mkdir -p models
            cp "$UPDATE_DIR/backup/models/"*.gguf models/ 2>/dev/null || true
            echo "  ✓ Restored models"
        fi
        
        # Make scripts executable
        chmod +x scripts/*.sh
        chmod +x START_DEEPSEEK.command
        
        echo ""
        echo "✅ Update complete!"
        echo ""
        echo "📝 Your configuration and downloaded models have been preserved."
        echo ""
    else
        echo ""
        echo "❌ Update cancelled."
        echo ""
    fi
else
    echo ""
    echo "❌ Failed to download update from GitHub."
    echo ""
    echo "Please check:"
    echo "  • Your internet connection"
    echo "  • The repository URL is correct: $GITHUB_REPO"
    echo "  • You have git installed: brew install git"
    echo ""
    exit 1
fi

# Cleanup
rm -rf "$UPDATE_DIR"

echo "🚀 You can now run START_DEEPSEEK.command to use the updated version!"
echo ""
