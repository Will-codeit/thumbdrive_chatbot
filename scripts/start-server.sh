#!/bin/bash

# DeepSeek Server Startup Script

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Run memory safety check first
echo "🔍 Running memory safety check..."
if ! ./scripts/check-memory.sh; then
    echo ""
    echo "❌ Server startup cancelled due to memory safety concerns."
    echo ""
    exit 1
fi

# Load user configuration if exists
CONFIG_FILE="$SCRIPT_DIR/.config"
if [ -f "$CONFIG_FILE" ]; then
    echo "📋 Loading user configuration..."
    source "$CONFIG_FILE"
    
    # Use configured values
    MODEL_NAME=${MODEL:-"Q4_K_M"}
    MODEL_VERSION=${VERSION:-"v2-lite"}
    CONTEXT_SIZE=${CONTEXT:-4096}
    GPU_LAYERS=${GPU_LAYERS:-33}
    PORT=${PORT:-8080}
    THREADS=${THREADS:-8}
    PARALLEL=${PARALLEL:-2}
    
    echo "   Version: DeepSeek-${MODEL_VERSION}"
    echo "   Model: $MODEL_NAME"
    echo "   Context: $CONTEXT_SIZE tokens"
    echo "   GPU Layers: $GPU_LAYERS"
    echo ""
else
    # Detect available RAM and configure accordingly
    TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')

    # Auto-select model and settings based on RAM
    if [ $TOTAL_RAM -le 8 ]; then
        MODEL_NAME="Q2_K"
        CONTEXT_SIZE=2048
        GPU_LAYERS=20
        BATCH_SIZE=256
        echo "⚙️  8GB RAM detected - using optimized settings"
        echo "   Model: Q2_K (smaller, good quality)"
        echo "   Context: 2048 tokens"
    elif [ $TOTAL_RAM -le 16 ]; then
        MODEL_NAME="Q3_K_M"
        CONTEXT_SIZE=4096
        GPU_LAYERS=33
        BATCH_SIZE=512
        echo "⚙️  16GB RAM detected - using balanced settings"
    elif [ $TOTAL_RAM -le 32 ]; then
        MODEL_NAME="Q4_K_M"
        CONTEXT_SIZE=8192
        GPU_LAYERS=99
        BATCH_SIZE=512
        echo "⚙️  32GB RAM detected - using high-quality settings"
    else
        MODEL_NAME="Q5_K_M"
        CONTEXT_SIZE=16384
        GPU_LAYERS=99
        BATCH_SIZE=512
        echo "⚙️  ${TOTAL_RAM}GB RAM detected - using optimal settings"
    fi
    
    MODEL_VERSION="v2-lite"
    PORT=8080
    THREADS=8
    PARALLEL=2
fi

# Try to find available model (check v2-lite, v2, and v3)
MODEL_PATH=""
if [ -f "models/deepseek-v2-lite-${MODEL_NAME}.gguf" ]; then
    MODEL_PATH="models/deepseek-v2-lite-${MODEL_NAME}.gguf"
    MODEL_VERSION="v2-lite"
elif [ -f "models/DeepSeek-V2-Lite.${MODEL_NAME}.gguf" ]; then
    MODEL_PATH="models/DeepSeek-V2-Lite.${MODEL_NAME}.gguf"
    MODEL_VERSION="v2-lite"
elif [ -f "models/deepseek-v2-${MODEL_NAME}.gguf" ]; then
    MODEL_PATH="models/deepseek-v2-${MODEL_NAME}.gguf"
    MODEL_VERSION="v2"
elif [ -f "models/deepseek-v3-${MODEL_NAME}.gguf" ]; then
    MODEL_PATH="models/deepseek-v3-${MODEL_NAME}.gguf"
    MODEL_VERSION="v3"
fi

HOST="0.0.0.0"
BATCH_SIZE=${BATCH_SIZE:-512}

# Check if llama.cpp exists
if [ ! -d "technical/llama.cpp" ]; then
    echo "❌ llama.cpp not found. Please run scripts/setup.sh first."
    exit 1
fi

# Check if model exists
if [ -z "$MODEL_PATH" ] || [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Model not found"
    echo ""
    echo "Looking for: deepseek-${MODEL_VERSION}-${MODEL_NAME}.gguf"
    echo ""
    echo "Available models in models/ folder:"
    ls -lh models/*.gguf 2>/dev/null || echo "  (none found)"
    echo ""
    echo "Run: ./scripts/download-model.sh"
    exit 1
fi

# Convert version to uppercase for display (bash 3.2 compatible)
MODEL_VERSION_UPPER=$(echo "$MODEL_VERSION" | tr '[:lower:]' '[:upper:]')

echo "🚀 Starting DeepSeek-${MODEL_VERSION_UPPER} Server..."
echo "📊 Model: $MODEL_PATH"
echo "🌐 Server: http://localhost:$PORT"
echo "💾 Context: $CONTEXT_SIZE tokens"
echo "🎮 GPU Layers: $GPU_LAYERS"
echo "🧵 CPU Threads: $THREADS"
echo ""

# Create a crash log directory
mkdir -p logs

# Set memory limits for the process
MEMORY_LIMIT=$((CONTEXT_SIZE * 2 / 1024))  # Rough estimate in MB

cd technical/llama.cpp

# Trap signals for graceful shutdown
trap 'echo ""; echo "⚠️  Received shutdown signal. Stopping server..."; kill $SERVER_PID 2>/dev/null; exit 0' INT TERM

# Start server with optimized settings and memory monitoring
echo "💡 Starting with memory-safe settings..."
echo "   (Server will auto-shutdown if memory pressure becomes critical)"
echo ""

# Start the server in background to monitor it
./build/bin/llama-server \
    -m "../../$MODEL_PATH" \
    -c $CONTEXT_SIZE \
    -b $BATCH_SIZE \
    -ngl $GPU_LAYERS \
    --host $HOST \
    --port $PORT \
    --threads $THREADS \
    --parallel $PARALLEL \
    --mlock 2>&1 | tee "../../logs/server_$(date +%Y%m%d_%H%M%S).log" &

SERVER_PID=$!

# Monitor memory pressure in background
(
    sleep 30  # Wait for model to load
    while kill -0 $SERVER_PID 2>/dev/null; do
        # Check memory pressure every 30 seconds
        MEM_FREE=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage:" | awk '{print $5}' | tr -d '%')
        
        if [ ! -z "$MEM_FREE" ] && [ "$MEM_FREE" -lt 5 ]; then
            echo ""
            echo "⚠️  CRITICAL: Memory pressure detected (${MEM_FREE}% free)"
            echo "   Stopping server to prevent system crash..."
            echo ""
            kill $SERVER_PID 2>/dev/null
            exit 1
        fi
        
        sleep 30
    done
) &

MONITOR_PID=$!

# Wait for server process
wait $SERVER_PID
EXIT_CODE=$?

# Kill monitor process
kill $MONITOR_PID 2>/dev/null

# Check exit code
if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Server stopped with error code: $EXIT_CODE"
    echo ""
    echo "Check the logs in: logs/"
    echo ""
    echo "Common causes:"
    echo "  • Out of memory - try a smaller model (./SWITCH_MODEL.command)"
    echo "  • Model file corrupted - re-download the model"
    echo "  • Port already in use - close other applications"
    echo ""
fi

exit $EXIT_CODE

