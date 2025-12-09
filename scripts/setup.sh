#!/bin/bash

# First-time setup script for portable DeepSeek
# Run this once to prepare the thumb drive
# Compatible with Intel (x86_64) and Apple Silicon (arm64) Macs

set -e

echo "════════════════════════════════════════════════════════"
echo "  🔧 DeepSeek-V2-Lite First-Time Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# Detect system information
ARCH=$(uname -m)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo "$OS_VERSION" | cut -d. -f1)

echo "🖥️  System Information:"
echo "   Architecture: $ARCH"
case "$ARCH" in
    arm64)
        echo "   Type: Apple Silicon (M1/M2/M3/M4)"
        ;;
    x86_64)
        echo "   Type: Intel processor"
        ;;
    *)
        echo "   Type: Unknown ($ARCH) - attempting generic build"
        ;;
esac
echo "   macOS Version: $OS_VERSION"
echo ""

# Validate macOS version
if [ "$OS_MAJOR" -lt 10 ]; then
    echo "❌ ERROR: This requires macOS 10.9 or later"
    echo "   Your version: $OS_VERSION"
    exit 1
fi

echo "This setup will:"
echo "  1️⃣  Download llama.cpp (AI engine)"
echo "  2️⃣  Compile it for your Mac ($ARCH)"
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

# Check for make (required for building)
if ! command -v make &> /dev/null; then
    echo "⚠️  WARNING: 'make' not found. Installing Xcode Command Line Tools..."
    echo ""
    xcode-select --install 2>/dev/null || true
    echo ""
    echo "Please run this script again after Xcode tools are installed."
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
echo "🔨 Building llama.cpp for $ARCH..."
echo "   (This may take 3-5 minutes)"
echo ""

cd technical/llama.cpp

# Clean any previous build
rm -rf build
mkdir -p build
cd build

# Architecture-specific build configuration
case "$ARCH" in
    arm64)
        echo "✓ Detected Apple Silicon - enabling Metal GPU acceleration"
        echo ""
        
        if ! cmake .. -DGGML_METAL=ON 2>&1; then
            echo ""
            echo "❌ CMake configuration failed"
            echo ""
            echo "Try installing Xcode Command Line Tools: xcode-select --install"
            echo "Or install cmake via Homebrew: brew install cmake"
            exit 1
        fi
        ;;
        
    x86_64)
        echo "✓ Detected Intel Mac - building with CPU optimization"
        echo ""
        
        # Check if AVX2 is available for better performance
        if sysctl -a 2>/dev/null | grep -q "machdep.cpu.features.*AVX2"; then
            echo "✓ AVX2 support detected - enabling optimizations"
            CMAKE_FLAGS="-DGGML_AVX2=ON"
        else
            echo "ℹ️  Building without AVX2 optimizations"
            CMAKE_FLAGS=""
        fi
        
        if ! cmake .. $CMAKE_FLAGS 2>&1; then
            echo ""
            echo "❌ CMake configuration failed"
            echo ""
            echo "Try installing Xcode Command Line Tools: xcode-select --install"
            exit 1
        fi
        ;;
        
    *)
        echo "⚠️  Unknown architecture ($ARCH) - attempting generic build"
        echo ""
        
        if ! cmake .. 2>&1; then
            echo ""
            echo "❌ CMake configuration failed for $ARCH"
            echo ""
            echo "This system architecture may not be fully supported."
            echo "Please report this issue with your system details."
            exit 1
        fi
        ;;
esac

# Build with all available cores
NUM_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
echo ""
echo "🔨 Compiling with $NUM_CORES CPU cores..."
echo ""

if ! cmake --build . --config Release -j $NUM_CORES 2>&1 | tail -20; then
    echo ""
    echo "❌ Build failed"
    echo ""
    echo "Possible causes:"
    echo "  • Insufficient disk space"
    echo "  • Missing build tools (install: xcode-select --install)"
    echo "  • Corrupted llama.cpp download"
    echo ""
    echo "Try:"
    echo "  1. Free up disk space (need ~2GB free)"
    echo "  2. Delete technical/llama.cpp and run setup again"
    echo "  3. Install Xcode Command Line Tools"
    exit 1
fi

cd ../../..

echo ""
echo "✓ Build complete!"
echo ""

# Verify binary was created
if [ ! -f "technical/llama.cpp/build/bin/llama-server" ]; then
    echo "⚠️  WARNING: llama-server binary not found at expected location"
    echo ""
    # Try to find it
    FOUND_BINARY=$(find technical/llama.cpp/build -name "llama-server" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND_BINARY" ]; then
        echo "✓ Found binary at: $FOUND_BINARY"
    else
        echo "❌ Could not locate llama-server binary"
        echo "   Build may have failed silently"
        exit 1
    fi
fi

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
echo "✓ System: $ARCH ($OS_VERSION)"
echo "✓ llama.cpp built successfully"
echo "✓ Ready to run DeepSeek"
echo ""
echo "To start DeepSeek, run:"
echo "  ./START_DEEPSEEK.command"
echo ""
echo "Or just double-click: START_DEEPSEEK.command"
echo ""
