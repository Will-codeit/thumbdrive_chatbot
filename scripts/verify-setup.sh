#!/bin/bash

# Verification script - checks that everything is set up correctly
# Run this to diagnose any issues before starting DeepSeek

echo "════════════════════════════════════════════════════════"
echo "  🔍 DeepSeek Setup Verification"
echo "════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

ERRORS=0
WARNINGS=0

echo "Running comprehensive system check..."
echo ""

# 1. Check macOS version
echo "1️⃣  Checking macOS version..."
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo $OS_VERSION | cut -d. -f1)
if [ $OS_MAJOR -ge 11 ]; then
    echo "   ✅ macOS $OS_VERSION (supported)"
elif [ $OS_MAJOR -eq 10 ]; then
    OS_MINOR=$(echo $OS_VERSION | cut -d. -f2)
    if [ $OS_MINOR -ge 15 ]; then
        echo "   ✅ macOS $OS_VERSION (supported)"
    else
        echo "   ❌ macOS $OS_VERSION (too old - need 10.15+)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ⚠️  macOS $OS_VERSION (unknown version)"
    WARNINGS=$((WARNINGS + 1))
fi

# 2. Check RAM
echo "2️⃣  Checking RAM..."
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
if [ $TOTAL_RAM -ge 16 ]; then
    echo "   ✅ ${TOTAL_RAM}GB RAM (excellent)"
elif [ $TOTAL_RAM -ge 8 ]; then
    echo "   ⚠️  ${TOTAL_RAM}GB RAM (minimum - 16GB+ recommended)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ❌ ${TOTAL_RAM}GB RAM (insufficient - need 8GB minimum)"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check disk space
echo "3️⃣  Checking disk space..."
FREE_SPACE=$(df -g "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
if [ $FREE_SPACE -ge 20 ]; then
    echo "   ✅ ${FREE_SPACE}GB free (good)"
elif [ $FREE_SPACE -ge 10 ]; then
    echo "   ⚠️  ${FREE_SPACE}GB free (low - 20GB+ recommended)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ❌ ${FREE_SPACE}GB free (insufficient - need 10GB minimum)"
    ERRORS=$((ERRORS + 1))
fi

# 4. Check required directories
echo "4️⃣  Checking directories..."
ALL_DIRS_OK=true
for dir in models logs scripts; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir/ exists"
    else
        echo "   ❌ $dir/ missing"
        ALL_DIRS_OK=false
        ERRORS=$((ERRORS + 1))
    fi
done

# 5. Check llama.cpp
echo "5️⃣  Checking llama.cpp installation..."
if [ -d "technical/llama.cpp" ]; then
    echo "   ✅ llama.cpp found in technical/"
    
    if [ -f "technical/llama.cpp/build/bin/llama-server" ]; then
        echo "   ✅ llama-server binary compiled"
    else
        echo "   ⚠️  llama-server not built yet (will build on first run)"
        WARNINGS=$((WARNINGS + 1))
    fi
elif [ -d "llama.cpp" ]; then
    echo "   ✅ llama.cpp found in root"
    
    if [ -f "llama.cpp/build/bin/llama-server" ]; then
        echo "   ✅ llama-server binary compiled"
    else
        echo "   ⚠️  llama-server not built yet (will build on first run)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ⚠️  llama.cpp not downloaded yet (will download on first run)"
    WARNINGS=$((WARNINGS + 1))
fi

# 6. Check for AI models
echo "6️⃣  Checking for AI models..."
MODEL_FOUND=""
MODEL_COUNT=0
for model_file in models/deepseek-v2-lite-*.gguf models/DeepSeek-V2-Lite.*.gguf; do
    if [ -f "$model_file" ]; then
        MODEL_FOUND="$model_file"
        MODEL_COUNT=$((MODEL_COUNT + 1))
        MODEL_SIZE=$(du -h "$model_file" | awk '{print $1}')
        echo "   ✅ $(basename $model_file) ($MODEL_SIZE)"
    fi
done

if [ $MODEL_COUNT -eq 0 ]; then
    echo "   ⚠️  No models found (will download on first run)"
    WARNINGS=$((WARNINGS + 1))
fi

# 7. Check essential scripts
echo "7️⃣  Checking essential scripts..."
SCRIPTS_OK=true
for script in setup.sh run.sh start-server.sh download-model.sh launcher.sh; do
    if [ -f "scripts/$script" ]; then
        if [ -x "scripts/$script" ]; then
            echo "   ✅ scripts/$script (executable)"
        else
            echo "   ⚠️  scripts/$script (needs permissions - will fix automatically)"
            chmod +x "scripts/$script"
        fi
    else
        echo "   ❌ scripts/$script (missing)"
        SCRIPTS_OK=false
        ERRORS=$((ERRORS + 1))
    fi
done

# 8. Check for required tools
echo "8️⃣  Checking required tools..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo "   ✅ git installed (version $GIT_VERSION)"
else
    echo "   ⚠️  git not installed (needed for first-time setup)"
    echo "      Install with: xcode-select --install"
    WARNINGS=$((WARNINGS + 1))
fi

if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1 | awk '{print $3}')
    echo "   ✅ cmake installed (version $CMAKE_VERSION)"
else
    echo "   ⚠️  cmake not installed (needed for first-time setup)"
    echo "      Install with: xcode-select --install"
    WARNINGS=$((WARNINGS + 1))
fi

if command -v curl &> /dev/null; then
    echo "   ✅ curl installed"
else
    echo "   ❌ curl not installed (required for downloads)"
    ERRORS=$((ERRORS + 1))
fi

# 9. Check if port 8080 is available
echo "9️⃣  Checking port availability..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    PORT_PROCESS=$(lsof -Pi :8080 -sTCP:LISTEN | tail -1 | awk '{print $1}')
    echo "   ⚠️  Port 8080 is in use by: $PORT_PROCESS"
    echo "      (Stop it or DeepSeek will use a different port)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ Port 8080 available"
fi

# 10. Check Apple Silicon / Intel
echo "🔟 Checking processor type..."
ARCH=$(uname -m)
if [[ $ARCH == 'arm64' ]]; then
    echo "   ✅ Apple Silicon detected (M1/M2/M3/M4)"
    echo "      GPU acceleration available!"
else
    echo "   ✅ Intel Mac detected"
    echo "      (Apple Silicon recommended for best performance)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo "  📊 Verification Summary"
echo "════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ Perfect! Everything is ready."
    echo ""
    echo "You can start DeepSeek by running:"
    echo "  ./START_DEEPSEEK.command"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Found $WARNINGS warning(s) but system is usable."
    echo ""
    echo "You can start DeepSeek by running:"
    echo "  ./START_DEEPSEEK.command"
    echo ""
    echo "The warnings above are not critical but may affect performance."
    echo ""
    exit 0
else
    echo "❌ Found $ERRORS error(s) and $WARNINGS warning(s)."
    echo ""
    echo "Please fix the errors above before starting DeepSeek."
    echo ""
    if [ $ERRORS -gt 0 ]; then
        echo "Critical issues that need fixing:"
        echo "  • Insufficient RAM or disk space"
        echo "  • Missing required directories or files"
        echo "  • Unsupported macOS version"
    fi
    echo ""
    exit 1
fi
