#!/bin/bash

# First-time setup script for portable DeepSeek
# Run this once to prepare the thumb drive

set -e

echo "════════════════════════════════════════════════════════"
echo "  🔧 DeepSeek-V2-Lite First-Time Setup"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This setup will:"
echo "  1️⃣  Download llama.cpp (AI engine)"
echo "  2️⃣  Compile it for your Mac"
echo "  3️⃣  Set up required directories"
echo ""
echo "Time required: 5-10 minutes"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p models
mkdir -p logs
mkdir -p technical
echo "✓ Directories created"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ ERROR: git is not installed"
    echo ""
    echo "Git is required to download llama.cpp."
    echo ""
    echo "To install git:"
    echo "  1. Run: xcode-select --install"
    echo "  2. Click 'Install' in the popup"
    echo "  3. Wait for installation to complete"
    echo "  4. Run this setup again"
    echo ""
    exit 1
fi

# Check if cmake is installed
if ! command -v cmake &> /dev/null; then
    echo "❌ ERROR: cmake is not installed"
    echo ""
    echo "CMake is required to build llama.cpp."
    echo ""
    echo "To install cmake:"
    echo "  1. Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "  2. Run: brew install cmake"
    echo "  3. Run this setup again"
    echo ""
    echo "OR install Xcode Command Line Tools: xcode-select --install"
    echo ""
    exit 1
fi

# Clone llama.cpp if not present
if [ ! -d "technical/llama.cpp" ]; then
    echo "📦 Downloading llama.cpp..."
    echo "   (This may take 2-5 minutes)"
    echo ""
    
    cd technical
    if git clone https://github.com/ggerganov/llama.cpp 2>&1 | grep -v "^Cloning"; then
        echo ""
        echo "✓ llama.cpp downloaded"
    else
        echo ""
        echo "❌ Failed to download llama.cpp"
        echo ""
        echo "Please check your internet connection and try again."
        exit 1
    fi
    cd ..
    echo ""
else
    echo "✓ llama.cpp already exists"
    echo ""
fi

# Build llama.cpp using CMake
echo "🔨 Building llama.cpp..."
echo "   (This may take 3-5 minutes)"
echo ""

cd technical/llama.cpp

# Check for Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
    echo "✓ Detected Apple Silicon (M1/M2/M3/M4)"
    echo "✓ Enabling Metal GPU acceleration"
    echo ""
    mkdir -p build
    cd build
    
    if ! cmake .. -DGGML_METAL=ON; then
        echo ""
        echo "❌ CMake configuration failed"
        echo ""
        echo "Try installing Xcode Command Line Tools: xcode-select --install"
        exit 1
    fi
    
    if ! cmake --build . --config Release; then
        echo ""
        echo "❌ Build failed"
        echo ""
        echo "Please check that you have enough disk space and try again."
        exit 1
    fi
    
    cd ../..
else
    echo "✓ Detected Intel Mac"
    echo "✓ Building without GPU acceleration"
    echo ""
    mkdir -p build
    cd build
    
    if ! cmake ..; then
        echo ""
        echo "❌ CMake configuration failed"
        exit 1
    fi
    
    if ! cmake --build . --config Release; then
        echo ""
        echo "❌ Build failed"
        exit 1
    fi
    
    cd ../..
fi

cd ../..

echo ""
echo "✓ Build complete!"
echo ""

# Check if model already exists
MODEL_FOUND=""
for model_file in models/deepseek-v2-lite-*.gguf models/DeepSeek-V2-Lite.*.gguf; do
    if [ -f "$model_file" ]; then
        MODEL_FOUND="$model_file"
        echo "✅ Model already present: $(basename $model_file)"
        echo "   Skipping download."
        break
    fi
done

if [ -z "$MODEL_FOUND" ]; then
    # Check if we should download the model
    echo "📥 AI Model Download"
    echo ""
    echo "DeepSeek-V2-Lite requires 7-13GB depending on quality level."
    echo "Download takes 15-30 minutes depending on internet speed."
    echo ""
    read -p "Download AI model now? [Y/n]: " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if [ -f "scripts/download-model.sh" ]; then
            chmod +x scripts/download-model.sh
            ./scripts/download-model.sh
        else
            echo ""
            echo "⚠️  download-model.sh not found"
            echo ""
            echo "You can download the model later by running:"
            echo "  ./scripts/download-model.sh"
            echo ""
        fi
    else
        echo ""
        echo "⚠️  Skipping model download"
        echo ""
        echo "You'll need to download the model before using DeepSeek."
        echo "Run this command when ready:"
        echo "  ./scripts/download-model.sh"
        echo ""
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "To start DeepSeek, run:"
echo "  ./START_DEEPSEEK.command"
echo ""
echo "Or just double-click: START_DEEPSEEK.command"
echo ""
