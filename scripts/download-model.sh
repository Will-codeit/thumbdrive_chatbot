#!/bin/bash

# Model download script
# Downloads DeepSeek-V2-Lite GGUF model

set -e

echo "════════════════════════════════════════════════════════"
echo "  📥 DeepSeek-V2-Lite Model Download"
echo "════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Create models directory
mkdir -p models

# Check if FORCE_MODEL is set (from launcher)
if [ ! -z "$FORCE_MODEL" ]; then
    echo "🎯 Using pre-configured: DeepSeek-V2-Lite $FORCE_MODEL"
    QUANT="$FORCE_MODEL"
else
    # Detect RAM and recommend appropriate model
    TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')

    echo "💻 Detected RAM: ${TOTAL_RAM}GB"
    echo ""

    # Determine recommended quantization based on RAM
    if [ $TOTAL_RAM -le 8 ]; then
        RECOMMENDED_MODEL="Q2_K"
        MODEL_SIZE="~5.4GB"
        echo "📌 Recommended for your system: Q2_K quantization"
        echo "   Size: ${MODEL_SIZE}"
        echo "   Quality: Good (optimized for 8GB RAM)"
    elif [ $TOTAL_RAM -le 16 ]; then
        RECOMMENDED_MODEL="Q3_K_M"
        MODEL_SIZE="~7.6GB"
        echo "📌 Recommended for your system: Q3_K_M quantization"
        echo "   Size: ${MODEL_SIZE}"
        echo "   Quality: Very Good (balanced)"
    elif [ $TOTAL_RAM -le 32 ]; then
        RECOMMENDED_MODEL="Q4_K_M"
        MODEL_SIZE="~9GB"
        echo "📌 Recommended for your system: Q4_K_M quantization"
        echo "   Size: ${MODEL_SIZE}"
        echo "   Quality: High (standard)"
    else
        RECOMMENDED_MODEL="Q5_K_M"
        MODEL_SIZE="~11GB"
        echo "📌 Recommended for your system: Q5_K_M quantization"
        echo "   Size: ${MODEL_SIZE}"
        echo "   Quality: Very High"
    fi
    
    echo ""
    echo "Available quantizations for DeepSeek-V2-Lite:"
    echo "  Q2_K   (~5.4GB) - Best for 8GB RAM (smaller, good quality)"
    echo "  Q3_K_M (~7.6GB) - Best for 16GB RAM (balanced)"
    echo "  Q4_K_M (~9GB)   - Best for 24GB RAM (high quality)"
    echo "  Q5_K_M (~11GB)  - Best for 32GB+ RAM (very high quality)"
    echo "  Q6_K   (~13GB)  - Best for 64GB+ RAM (near-perfect)"

    echo ""
    read -p "Download ${RECOMMENDED_MODEL} (recommended)? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        QUANT=$RECOMMENDED_MODEL
    else
        echo ""
        echo "Choose model size:"
        echo "1) Q2_K   - For 8GB RAM (~5.4GB)"
        echo "2) Q3_K_M - For 16GB RAM (~7.6GB)"
        echo "3) Q4_K_M - For 24GB RAM (~9GB)"
        echo "4) Q5_K_M - For 32GB RAM (~11GB)"
        echo "5) Q6_K   - For 64GB+ RAM (~13GB)"
        read -p "Enter choice [1-5]: " -n 1 -r
        echo
        case $REPLY in
            1) QUANT="Q2_K" ;;
            2) QUANT="Q3_K_M" ;;
            3) QUANT="Q4_K_M" ;;
            4) QUANT="Q5_K_M" ;;
            5) QUANT="Q6_K" ;;
            *) QUANT="$RECOMMENDED_MODEL" ;;
        esac
    fi
fi

# Build the model filename - using mradermacher's DeepSeek-V2-Lite GGUF
CHOSEN_MODEL="deepseek-v2-lite-${QUANT}.gguf"
HF_REPO="mradermacher/DeepSeek-V2-Lite-GGUF"
HF_FILE="DeepSeek-V2-Lite.${QUANT}.gguf"

echo ""
echo "📦 Downloading: $CHOSEN_MODEL"
echo "📍 Repository: $HF_REPO"
echo "📄 File: $HF_FILE"
echo "This may take 10-30 minutes depending on your connection."
echo ""

echo ""
echo "🔄 Starting download..."

# Download using curl (more reliable than huggingface-cli)
DOWNLOAD_URL="https://huggingface.co/$HF_REPO/resolve/main/$HF_FILE"
OUTPUT_FILE="models/$HF_FILE"

echo "📥 Downloading from: $DOWNLOAD_URL"
echo "💾 Saving to: $OUTPUT_FILE"
echo ""
echo "⏳ This will take 10-30 minutes for a ~7GB file..."
echo ""

# Use curl with resume capability and progress bar
if curl -# -L -C - -o "$OUTPUT_FILE" "$DOWNLOAD_URL"; then
    # Rename the file to our standard naming
    if [ -f "$OUTPUT_FILE" ]; then
        mv "$OUTPUT_FILE" "models/$CHOSEN_MODEL"
        echo ""
        echo "✅ Model download complete!"
        echo ""
        echo "Downloaded: $CHOSEN_MODEL"
        echo "Location: models/$CHOSEN_MODEL"
        echo ""
    else
        echo ""
        echo "❌ Download failed - file not found after download."
        echo ""
        echo "Please try downloading manually:"
        echo "1. Go to: https://huggingface.co/$HF_REPO"
        echo "2. Download: $HF_FILE"
        echo "3. Place it in: models/$CHOSEN_MODEL"
        echo ""
        exit 1
    fi
else
    echo ""
    echo "❌ Download failed."
    echo ""
    echo "Please try downloading manually:"
    echo "1. Go to: https://huggingface.co/$HF_REPO"
    echo "2. Download: $HF_FILE"
    echo "3. Place it in: models/$CHOSEN_MODEL"
    echo ""
    exit 1
fi
