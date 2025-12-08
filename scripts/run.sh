#!/bin/bash

# Main launcher script for portable DeepSeek setup
# This script checks requirements and starts the server

set -e

echo "════════════════════════════════════════════════════════"
echo "  🤖 DeepSeek-V2-Lite Portable Server Launcher"
echo "════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Run pre-flight check
if [ -f "scripts/pre-flight-check.sh" ]; then
    if ! bash scripts/pre-flight-check.sh; then
        echo ""
        echo "Pre-flight check failed. Cannot continue."
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
    echo ""
fi

# System checks
echo "🔍 Running detailed system checks..."
echo ""

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
echo "✓ macOS version: $OS_VERSION"

# Check available RAM
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
echo "✓ Total RAM: ${TOTAL_RAM}GB"

if [ $TOTAL_RAM -lt 8 ]; then
    echo ""
    echo "❌ ERROR: Not Enough RAM"
    echo ""
    echo "DeepSeek requires at least 8GB RAM to run."
    echo "Your system has only ${TOTAL_RAM}GB."
    echo ""
    echo "This Mac cannot run DeepSeek. Try on a Mac with 8GB+ RAM."
    echo ""
    read -p "Press Enter to exit..."
    exit 1
elif [ $TOTAL_RAM -eq 8 ]; then
    echo "⚠️  8GB RAM detected - will use optimized Q2_K model"
    echo "   (Performance will be limited. 16GB+ recommended for better quality)"
elif [ $TOTAL_RAM -lt 16 ]; then
    echo "✓ ${TOTAL_RAM}GB RAM - will use Q3_K_M model (balanced quality)"
elif [ $TOTAL_RAM -lt 32 ]; then
    echo "✓ ${TOTAL_RAM}GB RAM - will use Q4_K_M model (high quality)"
else
    echo "✓ ${TOTAL_RAM}GB RAM - excellent! Will use Q5_K_M model (very high quality)"
fi

# Check disk space
FREE_SPACE=$(df -g "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
echo "✓ Free space: ${FREE_SPACE}GB"

if [ $FREE_SPACE -lt 10 ]; then
    echo ""
    echo "⚠️  WARNING: Low disk space (${FREE_SPACE}GB free)"
    echo ""
    echo "Recommended: 20GB+ free space"
    echo "Model download requires 5-13GB depending on quality"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Please free up disk space and try again."
        exit 1
    fi
fi

# Check if llama.cpp exists (handle both paths)
LLAMA_DIR=""
if [ -d "technical/llama.cpp" ]; then
    LLAMA_DIR="technical/llama.cpp"
elif [ -d "llama.cpp" ]; then
    LLAMA_DIR="llama.cpp"
fi

if [ -z "$LLAMA_DIR" ]; then
    echo ""
    echo "📦 First-time setup required..."
    echo ""
    echo "This will:"
    echo "  • Download llama.cpp (AI engine)"
    echo "  • Compile it for your Mac"
    echo "  • Takes about 5-10 minutes"
    echo ""
    read -p "Start setup now? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
    
    if [ ! -f "scripts/setup.sh" ]; then
        echo "❌ ERROR: setup.sh not found!"
        echo ""
        echo "The installation files may be corrupted."
        echo "Please re-download DeepSeek and try again."
        exit 1
    fi
    chmod +x scripts/setup.sh
    ./scripts/setup.sh
    
    # Re-check after setup
    if [ -d "technical/llama.cpp" ]; then
        LLAMA_DIR="technical/llama.cpp"
    elif [ -d "llama.cpp" ]; then
        LLAMA_DIR="llama.cpp"
    else
        echo "❌ Setup failed - llama.cpp not found after setup"
        exit 1
    fi
fi

# Check if llama.cpp server binary exists
SERVER_BIN="${LLAMA_DIR}/build/bin/llama-server"
if [ ! -f "$SERVER_BIN" ]; then
    echo ""
    echo "🔨 Building llama.cpp (first time only, takes 3-5 minutes)..."
    cd "$LLAMA_DIR"
    mkdir -p build
    cd build
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "✓ Detected Apple Silicon - enabling Metal acceleration"
        cmake .. -DGGML_METAL=ON
    else
        echo "✓ Building for Intel Mac"
        cmake ..
    fi
    cmake --build . --config Release
    cd "$SCRIPT_DIR"
    
    if [ ! -f "$SERVER_BIN" ]; then
        echo ""
        echo "❌ Build failed!"
        echo ""
        echo "Could not compile llama.cpp. Possible causes:"
        echo "  • Missing Xcode Command Line Tools"
        echo "  • Insufficient disk space"
        echo ""
        echo "Try running: xcode-select --install"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
    echo "✓ Build complete!"
fi

# Check if any model exists
MODEL_FOUND=""
for model_file in models/deepseek-v2-lite-*.gguf models/DeepSeek-V2-Lite-*.gguf; do
    if [ -f "$model_file" ]; then
        MODEL_FOUND="$model_file"
        echo "✓ Found model: $(basename $model_file)"
        break
    fi
done

if [ -z "$MODEL_FOUND" ]; then
    echo ""
    echo "📥 AI Model Download Required"
    echo ""
    
    # Recommend model based on RAM
    if [ $TOTAL_RAM -le 8 ]; then
        RECOMMENDED="Q2_K (~5GB, good quality)"
    elif [ $TOTAL_RAM -le 16 ]; then
        RECOMMENDED="Q3_K_M (~7GB, very good quality)"
    elif [ $TOTAL_RAM -le 32 ]; then
        RECOMMENDED="Q4_K_M (~9GB, high quality)"
    else
        RECOMMENDED="Q5_K_M (~11GB, very high quality)"
    fi
    
    echo "Recommended for your ${TOTAL_RAM}GB RAM: $RECOMMENDED"
    echo ""
    echo "Download takes 15-30 minutes depending on internet speed."
    echo ""
    read -p "Download AI model now? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "❌ Cannot start without AI model."
        echo ""
        echo "To download later, run: ./scripts/download-model.sh"
        echo ""
        exit 1
    fi
    
    if [ ! -f "scripts/download-model.sh" ]; then
        echo "❌ ERROR: download-model.sh not found!"
        exit 1
    fi
    
    chmod +x scripts/download-model.sh
    ./scripts/download-model.sh
    
    # Verify download succeeded
    MODEL_FOUND=""
    for model_file in models/deepseek-v2-lite-*.gguf models/DeepSeek-V2-Lite-*.gguf; do
        if [ -f "$model_file" ]; then
            MODEL_FOUND="$model_file"
            break
        fi
    done
    
    if [ -z "$MODEL_FOUND" ]; then
        echo ""
        echo "❌ Model download failed or was cancelled."
        echo ""
        echo "Please try again or download manually from:"
        echo "https://huggingface.co/mradermacher/DeepSeek-V2-Lite-GGUF"
        echo ""
        exit 1
    fi
fi

echo ""
echo "✅ All requirements met!"
echo ""
echo "🚀 Starting DeepSeek..."
echo ""

# Make start-server.sh executable and run it
chmod +x scripts/start-server.sh
exec ./scripts/start-server.sh
