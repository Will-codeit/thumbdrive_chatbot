#!/bin/bash

# Main launcher script for portable DeepSeek setup
# This script checks requirements and starts the server

set -e

echo "════════════════════════════════════════════════════════"
echo "  🤖 DeepSeek-V3 Portable Server Launcher"
echo "════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# System checks
echo "🔍 Checking system requirements..."

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
echo "✓ macOS version: $OS_VERSION"

# Check available RAM
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
echo "✓ Total RAM: ${TOTAL_RAM}GB"

if [ $TOTAL_RAM -lt 8 ]; then
    echo "❌ Error: Less than 8GB RAM detected"
    echo "   DeepSeek-V3 requires at least 8GB RAM"
    echo "   Your system has ${TOTAL_RAM}GB"
    exit 1
elif [ $TOTAL_RAM -eq 8 ]; then
    echo "⚠️  8GB RAM detected - using optimized Q3 model"
    echo "   Performance will be limited. 16GB+ strongly recommended."
    echo "   The Q3 model (~24GB) will be used with reduced context."
elif [ $TOTAL_RAM -lt 16 ]; then
    echo "⚠️  ${TOTAL_RAM}GB RAM detected"
    echo "   System will work but 16GB+ recommended for better performance"
elif [ $TOTAL_RAM -lt 32 ]; then
    echo "ℹ️  Note: 32GB+ RAM recommended for optimal performance"
    echo "   The model uses memory-mapping, so it will work but page from disk"
fi

# Check if llama.cpp exists
if [ ! -d "llama.cpp" ]; then
    echo ""
    echo "📦 llama.cpp not found. Running first-time setup..."
    if [ ! -f "scripts/setup.sh" ]; then
        echo "❌ Error: setup.sh not found!"
        exit 1
    fi
    chmod +x scripts/setup.sh
    ./scripts/setup.sh
fi

# Check if llama.cpp server binary exists
if [ ! -f "llama.cpp/build/bin/llama-server" ]; then
    echo ""
    echo "🔨 Building llama.cpp (this may take a few minutes)..."
    cd llama.cpp
    mkdir -p build
    cd build
    if [[ $(uname -m) == 'arm64' ]]; then
        cmake .. -DGGML_METAL=ON
    else
        cmake ..
    fi
    cmake --build . --config Release
    cd ../..
    echo "✓ Build complete!"
fi

# Check if model exists
MODEL_PATH="models/deepseek-v3-Q4_K_M.gguf"
if [ ! -f "$MODEL_PATH" ]; then
    echo ""
    echo "📥 Model not found. Do you want to download it now? (~40GB)"
    echo "This is a one-time download and may take 30-60 minutes."
    read -p "Download now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "scripts/download-model.sh" ]; then
            chmod +x scripts/download-model.sh
            ./scripts/download-model.sh
        else
            echo "❌ Error: download-model.sh not found!"
            echo "Please download the model manually and place it in the models/ directory"
            exit 1
        fi
    else
        echo "❌ Cannot start server without a model."
        echo "Please download DeepSeek-V3 GGUF and place it in: $MODEL_PATH"
        exit 1
    fi
fi

echo ""
echo "✅ All requirements met!"
echo ""

# Make start-server.sh executable and run it
chmod +x scripts/start-server.sh
./scripts/start-server.sh
