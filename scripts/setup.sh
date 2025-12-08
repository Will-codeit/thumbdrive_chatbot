#!/bin/bash

# First-time setup script for portable DeepSeek
# Run this once to prepare the thumb drive

set -e

echo "════════════════════════════════════════════════════════"
echo "  🔧 DeepSeek-V3 Portable Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p models
mkdir -p logs
echo "✓ Directories created"

# Clone llama.cpp if not present
if [ ! -d "llama.cpp" ]; then
    echo ""
    echo "📦 Cloning llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp
    echo "✓ llama.cpp cloned"
else
    echo "✓ llama.cpp already exists"
fi

# Build llama.cpp using CMake
echo ""
echo "🔨 Building llama.cpp with Metal support..."
cd llama.cpp

# Check for Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
    echo "✓ Detected Apple Silicon - enabling Metal acceleration"
    mkdir -p build
    cd build
    cmake .. -DGGML_METAL=ON
    cmake --build . --config Release
    cd ..
else
    echo "✓ Building for Intel Mac"
    mkdir -p build
    cd build
    cmake ..
    cmake --build . --config Release
    cd ..
fi

cd ..
echo "✓ Build complete!"

# Check if we should download the model
echo ""
echo "📥 Model Download"
echo "DeepSeek-V3 requires ~40GB of space."
echo "Would you like to download it now?"
read -p "Download model? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "scripts/download-model.sh" ]; then
        chmod +x scripts/download-model.sh
        ./scripts/download-model.sh
    else
        echo "⚠️  download-model.sh not found. You'll need to download manually."
    fi
else
    echo "⚠️  Skipping model download."
    echo "   You can download later by running: ./scripts/download-model.sh"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "To start the server, run: ./scripts/run.sh"
echo ""
