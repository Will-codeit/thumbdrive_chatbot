#!/bin/bash

# Model Switcher Script
# Easily switch between downloaded models

set -e

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

CONFIG_FILE="$SCRIPT_DIR/.config"

echo "════════════════════════════════════════════════════════"
echo "  🔄 DeepSeek Model Switcher"
echo "════════════════════════════════════════════════════════"
echo ""

# Find all available models
echo "📦 Scanning for available models..."
echo ""

MODELS=()
MODEL_SIZES=()
MODEL_NAMES=()

for model_file in models/deepseek-*.gguf; do
    if [ -f "$model_file" ]; then
        basename=$(basename "$model_file")
        # Extract quantization type (e.g., Q2_K, Q3_K_M)
        quant=$(echo "$basename" | sed 's/deepseek-v2-lite-//' | sed 's/.gguf//')
        size=$(du -h "$model_file" | awk '{print $1}')
        
        MODELS+=("$quant")
        MODEL_SIZES+=("$size")
        MODEL_NAMES+=("$basename")
    fi
done

if [ ${#MODELS[@]} -eq 0 ]; then
    echo "❌ No models found in models/ folder"
    echo ""
    echo "Please download a model first:"
    echo "  ./scripts/download-model.sh"
    exit 1
fi

# Show current model
CURRENT_MODEL=""
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    CURRENT_MODEL=$MODEL
fi

echo "Available models:"
echo ""
for i in "${!MODELS[@]}"; do
    marker=""
    if [ "${MODELS[$i]}" == "$CURRENT_MODEL" ]; then
        marker=" ⭐️ CURRENT"
    fi
    
    # Add quality description
    case "${MODELS[$i]}" in
        Q2_K)   quality="Good quality (8GB RAM)" ;;
        Q3_K_M) quality="Very good (16GB RAM)" ;;
        Q4_K_M) quality="High quality (24GB RAM)" ;;
        Q5_K_M) quality="Very high (32GB RAM)" ;;
        Q6_K)   quality="Near-perfect (64GB+ RAM)" ;;
        *)      quality="Unknown" ;;
    esac
    
    echo "  $((i+1))) ${MODELS[$i]} (${MODEL_SIZES[$i]}) - $quality$marker"
done

echo ""
read -p "Select model number [1-${#MODELS[@]}]: " -n 1 -r
echo ""

# Validate input
if ! [[ $REPLY =~ ^[0-9]+$ ]] || [ $REPLY -lt 1 ] || [ $REPLY -gt ${#MODELS[@]} ]; then
    echo "❌ Invalid selection"
    exit 1
fi

SELECTED_INDEX=$((REPLY-1))
SELECTED_MODEL="${MODELS[$SELECTED_INDEX]}"

echo ""
echo "✅ Switching to: $SELECTED_MODEL (${MODEL_SIZES[$SELECTED_INDEX]})"
echo ""

# Detect RAM and suggest optimal settings
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')

case "$SELECTED_MODEL" in
    Q2_K)
        SUGGESTED_CONTEXT=2048
        SUGGESTED_GPU=20
        echo "💡 Recommended settings for Q2_K on ${TOTAL_RAM}GB RAM:"
        ;;
    Q3_K_M)
        if [ $TOTAL_RAM -le 8 ]; then
            SUGGESTED_CONTEXT=2048
            SUGGESTED_GPU=20
            echo "⚠️  Warning: Q3_K_M may be tight on 8GB RAM"
        else
            SUGGESTED_CONTEXT=4096
            SUGGESTED_GPU=33
        fi
        echo "💡 Recommended settings for Q3_K_M on ${TOTAL_RAM}GB RAM:"
        ;;
    Q4_K_M)
        SUGGESTED_CONTEXT=8192
        SUGGESTED_GPU=50
        echo "💡 Recommended settings for Q4_K_M on ${TOTAL_RAM}GB RAM:"
        ;;
    Q5_K_M|Q6_K)
        SUGGESTED_CONTEXT=16384
        SUGGESTED_GPU=99
        echo "💡 Recommended settings for $SELECTED_MODEL on ${TOTAL_RAM}GB RAM:"
        ;;
    *)
        SUGGESTED_CONTEXT=4096
        SUGGESTED_GPU=33
        echo "💡 Recommended settings:"
        ;;
esac

echo "   Context: $SUGGESTED_CONTEXT tokens"
echo "   GPU Layers: $SUGGESTED_GPU"
echo ""

read -p "Use recommended settings? [Y/n]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    CONTEXT=$SUGGESTED_CONTEXT
    GPU_LAYERS=$SUGGESTED_GPU
else
    echo ""
    read -p "Enter context size (2048/4096/8192/16384): " CONTEXT
    read -p "Enter GPU layers (20/33/50/99): " GPU_LAYERS
fi

# Update config file
cat > "$CONFIG_FILE" << CONF
VERSION=v2-lite
MODEL=$SELECTED_MODEL
CONTEXT=$CONTEXT
GPU_LAYERS=$GPU_LAYERS
PORT=8080
THREADS=8
PARALLEL=2
CONF

echo ""
echo "✅ Configuration updated!"
echo ""
echo "Model: DeepSeek-V2-Lite $SELECTED_MODEL"
echo "Context: $CONTEXT tokens"
echo "GPU Layers: $GPU_LAYERS"
echo ""
echo "Run START_DEEPSEEK.command to use the new model."
echo ""
