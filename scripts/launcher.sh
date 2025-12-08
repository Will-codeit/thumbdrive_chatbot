#!/bin/bash

# GUI Launcher for DeepSeek-V3
# This script shows GUI dialogs and manages the setup/launch process

set -e

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Configuration file
CONFIG_FILE="$SCRIPT_DIR/.config"

# Function to show dialog with osascript
show_dialog() {
    local title="$1"
    local message="$2"
    local icon="$3"  # note, caution, stop
    osascript -e "display dialog \"$message\" with title \"$title\" with icon $icon buttons {\"OK\"} default button \"OK\""
}

# Function to show yes/no dialog
ask_yes_no() {
    local title="$1"
    local message="$2"
    result=$(osascript -e "display dialog \"$message\" with title \"$title\" buttons {\"No\", \"Yes\"} default button \"Yes\"" 2>/dev/null)
    if [[ $result == *"Yes"* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to show progress
show_progress() {
    local message="$1"
    osascript -e "display notification \"$message\" with title \"DeepSeek-V3 Setup\""
}

# Function to show quick start dialog (when model is already present)
show_quick_start_dialog() {
    local model_name="$1"
    local model_size="$2"
    
    local result=$(osascript << EOF
tell application "System Events"
    activate
    set dialogText to "🚀 DeepSeek-V2-Lite Ready!

✅ Model found: ${model_name}
📦 Size: ${model_size}

Your AI chatbot is ready to use with the pre-configured model.

Would you like to:"
    
    set userChoice to button returned of (display dialog dialogText buttons {"Configure Settings", "Start Now!"} default button "Start Now!" with title "DeepSeek-V2-Lite")
    return userChoice
end tell
EOF
)
    
    echo "$result"
}

# Function to show configuration dialog
show_config_dialog() {
    local ram=$1
    
    # Determine recommended settings based on RAM for V2-Lite
    if [ $ram -le 8 ]; then
        DEFAULT_MODEL="Q3_K_M"
        DEFAULT_CONTEXT="2048"
        DEFAULT_GPU_LAYERS="20"
        MODEL_SIZE="~7GB"
    elif [ $ram -le 16 ]; then
        DEFAULT_MODEL="Q4_K_M"
        DEFAULT_CONTEXT="4096"
        DEFAULT_GPU_LAYERS="33"
        MODEL_SIZE="~9GB"
    elif [ $ram -le 32 ]; then
        DEFAULT_MODEL="Q5_K_M"
        DEFAULT_CONTEXT="8192"
        DEFAULT_GPU_LAYERS="99"
        MODEL_SIZE="~11GB"
    else
        DEFAULT_MODEL="Q6_K"
        DEFAULT_CONTEXT="16384"
        DEFAULT_GPU_LAYERS="99"
        MODEL_SIZE="~13GB"
    fi
    
    # Build configuration dialog using AppleScript
    local result=$(osascript << EOF
tell application "System Events"
    activate
    set dialogText to "🤖 DeepSeek-V2-Lite Configuration

Your System: ${ram}GB RAM
Recommended Model: ${DEFAULT_MODEL} (${MODEL_SIZE})

DeepSeek-V2-Lite is a 16B parameter model - excellent quality with efficient resource usage!

Configure your AI settings below:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 MODEL QUALITY (Choose one):
1️⃣  Q3_K_M (~7GB)  - Fast, good quality (8GB RAM)
2️⃣  Q4_K_M (~9GB)  - Balanced (16GB RAM) ⭐️ Default
3️⃣  Q5_K_M (~11GB) - High quality (32GB RAM)
4️⃣  Q6_K   (~13GB) - Near-perfect (64GB+ RAM)

💾 CONTEXT WINDOW (tokens for conversation memory):
• 2048 - Short conversations (fast)
• 4096 - Standard conversations ⭐️ Default
• 8192 - Long conversations (more RAM)
• 16384 - Very long documents (lots of RAM)

🎮 GPU ACCELERATION (layers on GPU):
• 20 - Minimal GPU use (8GB RAM)
• 33 - Balanced GPU/CPU ⭐️ Default for 16GB
• 99 - All layers on GPU (32GB+ RAM)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Would you like to use RECOMMENDED settings or CUSTOMIZE?"
    
    set userChoice to button returned of (display dialog dialogText buttons {"Cancel", "Customize", "Use Recommended"} default button "Use Recommended" with title "DeepSeek-V2-Lite Configuration")
    return userChoice
end tell
EOF
)
    
    echo "$result"
}

# Function to show custom configuration dialog
show_custom_dialog() {
    local ram=$1
    local temp_config="/tmp/deepseek_config_$$"
    
    # We only support V2-Lite now
    echo "VERSION='v2-lite'" > "$temp_config"
    source "$temp_config"
    
    # Model selection for V2-Lite (16B params)
    local model_choice=$(osascript << EOF
tell application "System Events"
    activate
    set modelList to {"Q3_K_M (~7GB) - Fast, good quality", "Q4_K_M (~9GB) - Balanced quality ⭐️", "Q5_K_M (~11GB) - High quality", "Q6_K (~13GB) - Near-perfect quality"}
    set chosenModel to choose from list modelList with prompt "Select DeepSeek-V2-Lite Model Quality:

V2-Lite is a 16B parameter model - excellent quality with efficient resource usage!

Choose based on your available RAM and storage." default items {"Q4_K_M (~9GB) - Balanced quality ⭐️"} with title "Model Selection"
    
    if chosenModel is false then
        return "cancelled"
    end if
    
    return item 1 of chosenModel
end tell
EOF
)
    
    if [[ "$model_choice" == "cancelled" ]]; then
        rm -f "$temp_config"
        echo "CANCELLED"
        return
    fi
    
    # Extract model name and write to temp file
    if [[ "$model_choice" == *"Q3_K_M"* ]]; then
        echo "MODEL='Q3_K_M'" >> "$temp_config"
    elif [[ "$model_choice" == *"Q5_K_M"* ]]; then
        echo "MODEL='Q5_K_M'" >> "$temp_config"
    elif [[ "$model_choice" == *"Q6_K"* ]]; then
        echo "MODEL='Q6_K'" >> "$temp_config"
    else
        echo "MODEL='Q4_K_M'" >> "$temp_config"
    fi
    
    source "$temp_config"
    
    # Context size selection
    local context_choice=$(osascript << EOF
tell application "System Events"
    activate
    set contextList to {"2048 tokens - Short conversations", "4096 tokens - Standard ⭐️", "8192 tokens - Long conversations", "16384 tokens - Very long documents"}
    set chosenContext to choose from list contextList with prompt "Select Context Window Size:

Context = how much conversation history the AI remembers.
Larger context = more memory usage." default items {"4096 tokens - Standard ⭐️"} with title "Context Size"
    
    if chosenContext is false then
        return "cancelled"
    end if
    
    return item 1 of chosenContext
end tell
EOF
)
    
    if [[ "$context_choice" == "cancelled" ]]; then
        rm -f "$temp_config"
        echo "CANCELLED"
        return
    fi
    
    # Extract context size and write to temp file
    local context_val=$(echo "$context_choice" | grep -o '[0-9]*' | head -1)
    echo "CONTEXT='$context_val'" >> "$temp_config"
    source "$temp_config"
    
    # GPU layers selection
    local gpu_choice=$(osascript << EOF
tell application "System Events"
    activate
    set gpuList to {"20 layers - Light GPU use (8GB RAM)", "33 layers - Balanced ⭐️ (16GB RAM)", "50 layers - Heavy GPU use (24GB RAM)", "99 layers - All on GPU (32GB+ RAM)"}
    set chosenGPU to choose from list gpuList with prompt "Select GPU Acceleration Level:

More layers on GPU = faster inference.
Choose based on your available RAM." default items {"33 layers - Balanced ⭐️ (16GB RAM)"} with title "GPU Acceleration"
    
    if chosenGPU is false then
        return "cancelled"
    end if
    
    return item 1 of chosenGPU
end tell
EOF
)
    
    if [[ "$gpu_choice" == "cancelled" ]]; then
        rm -f "$temp_config"
        echo "CANCELLED"
        return
    fi
    
    # Extract GPU layers and write to temp file
    local gpu_val=$(echo "$gpu_choice" | grep -o '[0-9]*' | head -1)
    echo "GPU_LAYERS='$gpu_val'" >> "$temp_config"
    source "$temp_config"
    
    # Advanced settings (optional)
    if ask_yes_no "Advanced Settings" "Would you like to configure advanced settings?\n\n• Server Port (default: 8080)\n• CPU Threads (default: 8)\n• Parallel Requests (default: 2)\n\nMost users can skip this."; then
        
        # Port configuration
        local port=$(osascript << EOF
tell application "System Events"
    activate
    set portInput to text returned of (display dialog "Enter server port number:" default answer "8080" with title "Port Configuration")
    return portInput
end tell
EOF
)
        echo "PORT='${port:-8080}'" >> "$temp_config"
        
        # Thread configuration
        local threads=$(osascript << EOF
tell application "System Events"
    activate
    set threadInput to text returned of (display dialog "Enter number of CPU threads:\n\n(Recommended: 4-8 for most Macs)" default answer "8" with title "Thread Configuration")
    return threadInput
end tell
EOF
)
        echo "THREADS='${threads:-8}'" >> "$temp_config"
        
        # Parallel requests
        local parallel=$(osascript << EOF
tell application "System Events"
    activate
    set parallelInput to text returned of (display dialog "Enter max parallel requests:\n\n(Recommended: 2-4)" default answer "2" with title "Parallel Requests")
    return parallelInput
end tell
EOF
)
        echo "PARALLEL='${parallel:-2}'" >> "$temp_config"
    else
        echo "PORT='8080'" >> "$temp_config"
        echo "THREADS='8'" >> "$temp_config"
        echo "PARALLEL='2'" >> "$temp_config"
    fi
    
    # Source the temp config one final time to get all variables
    source "$temp_config"
    
    # Save configuration to the actual config file
    cat > "$CONFIG_FILE" << CONF
VERSION=$VERSION
MODEL=$MODEL
CONTEXT=$CONTEXT
GPU_LAYERS=$GPU_LAYERS
PORT=$PORT
THREADS=$THREADS
PARALLEL=$PARALLEL
CONF
    
    # Clean up temp file
    rm -f "$temp_config"
    
    # Show summary
    osascript << EOF
tell application "System Events"
    activate
    display dialog "✅ Configuration Saved!

Model: DeepSeek-V2-Lite $MODEL
Context: $CONTEXT tokens
GPU Layers: $GPU_LAYERS
Port: $PORT
Threads: $THREADS
Parallel: $PARALLEL

These settings will be used when starting the server." buttons {"OK"} default button "OK" with title "Configuration Summary"
end tell
EOF
    
    echo "CONFIGURED"
}

# Check system requirements
echo "Checking system requirements..."

OS_VERSION=$(sw_vers -productVersion)
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
FREE_SPACE=$(df -g "$SCRIPT_DIR" | awk 'NR==2 {print $4}')

# Check for pre-downloaded models first
PREDOWNLOADED_MODEL=""
PREDOWNLOADED_SIZE=""

# Check for any existing model files
for model_file in models/deepseek-*.gguf; do
    if [ -f "$model_file" ]; then
        PREDOWNLOADED_MODEL=$(basename "$model_file")
        # Get file size in GB
        FILE_SIZE=$(du -h "$model_file" | awk '{print $1}')
        PREDOWNLOADED_SIZE="$FILE_SIZE"
        
        # Extract model type from filename (e.g., Q3_K_M from deepseek-v2-lite-Q3_K_M.gguf)
        MODEL_TYPE=$(echo "$PREDOWNLOADED_MODEL" | sed 's/deepseek-v2-lite-//' | sed 's/.gguf//')
        
        # If no config exists, create a default one for the pre-downloaded model
        if [ ! -f "$CONFIG_FILE" ]; then
            cat > "$CONFIG_FILE" << CONF
VERSION=v2-lite
MODEL=$MODEL_TYPE
CONTEXT=4096
GPU_LAYERS=33
PORT=8080
THREADS=8
PARALLEL=2
CONF
        fi
        
        break
    fi
done

# Load existing configuration if available
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if llama.cpp needs to be built
if [ ! -d "technical/llama.cpp/build" ]; then
    show_progress "Building llama.cpp..."
    
    # Show progress in Terminal app
    osascript <<-APPLESCRIPT
        tell application "Terminal"
            activate
            do script "cd '$SCRIPT_DIR' && echo '🔧 Setting up DeepSeek...' && echo '' && ./scripts/setup.sh && echo '' && echo '✅ Setup complete! Restarting launcher...' && sleep 2 && ./START_DEEPSEEK.command"
        end tell
APPLESCRIPT
    exit 0
fi

# If model is pre-downloaded and llama.cpp is built, show quick start option
if [ ! -z "$PREDOWNLOADED_MODEL" ] && [ -d "technical/llama.cpp/build" ]; then
    QUICK_START=$(show_quick_start_dialog "$PREDOWNLOADED_MODEL" "$PREDOWNLOADED_SIZE")
    
    if [[ "$QUICK_START" == "Start Now!" ]]; then
        # Launch immediately with pre-configured settings
        show_progress "Starting DeepSeek-V2-Lite..."
        ./scripts/gui-chat.sh
        exit 0
    fi
    # If user chose "Configure Settings", continue to configuration dialog below
fi

# Show system info and configuration dialog
CONFIG_CHOICE=$(show_config_dialog $TOTAL_RAM)

if [[ "$CONFIG_CHOICE" == "Cancel" ]]; then
    osascript -e 'display dialog "Setup cancelled." with title "DeepSeek-V3" buttons {"OK"} default button "OK"'
    exit 0
elif [[ "$CONFIG_CHOICE" == "Customize" ]]; then
    CUSTOM_RESULT=$(show_custom_dialog $TOTAL_RAM)
    if [[ "$CUSTOM_RESULT" == "CANCELLED" ]]; then
        osascript -e 'display dialog "Setup cancelled." with title "DeepSeek-V3" buttons {"OK"} default button "OK"'
        exit 0
    fi
    # Reload the config file that was just saved by show_custom_dialog
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
elif [[ "$CONFIG_CHOICE" == "Use Recommended" ]]; then
    # Use automatic defaults based on RAM for V2-Lite
    VERSION="v2-lite"
    if [ $TOTAL_RAM -le 8 ]; then
        MODEL="Q3_K_M"
        CONTEXT=2048
        GPU_LAYERS=20
    elif [ $TOTAL_RAM -le 16 ]; then
        MODEL="Q4_K_M"
        CONTEXT=4096
        GPU_LAYERS=33
    elif [ $TOTAL_RAM -le 32 ]; then
        MODEL="Q5_K_M"
        CONTEXT=8192
        GPU_LAYERS=99
    else
        MODEL="Q6_K"
        CONTEXT=16384
        GPU_LAYERS=99
    fi
    PORT=8080
    THREADS=8
    PARALLEL=2
    
    # Save recommended configuration
    cat > "$CONFIG_FILE" << CONF
VERSION=$VERSION
MODEL=$MODEL
CONTEXT=$CONTEXT
GPU_LAYERS=$GPU_LAYERS
PORT=$PORT
THREADS=$THREADS
PARALLEL=$PARALLEL
CONF
fi

# Check if llama.cpp exists
if [ ! -d "technical/llama.cpp" ] && [ ! -d "llama.cpp" ]; then
    show_progress "Building llama.cpp..."
    
    # Show progress in Terminal app
    osascript <<-APPLESCRIPT
        tell application "Terminal"
            activate
            do script "cd '$SCRIPT_DIR' && echo '🔧 Setting up DeepSeek...' && echo '' && ./scripts/setup.sh && echo '' && echo '✅ Setup complete! Starting chat interface...' && sleep 2 && ./scripts/gui-chat.sh"
        end tell
APPLESCRIPT
    exit 0
fi

# Load version from config, default to v2-lite
VERSION=${VERSION:-v2-lite}
MODEL=${MODEL:-Q3_K_M}

# Check if model exists (use configured model and version)
MODEL_PATH="models/deepseek-${VERSION}-${MODEL}.gguf"
if [ ! -f "$MODEL_PATH" ]; then
    # Get model size for display - V2-Lite only
    case $MODEL in
        Q3_K_M) MODEL_SIZE="~7GB" ;;
        Q4_K_M) MODEL_SIZE="~9GB" ;;
        Q5_K_M) MODEL_SIZE="~11GB" ;;
        Q6_K) MODEL_SIZE="~13GB" ;;
        *) MODEL_SIZE="~9GB" ;;
    esac
    
    if ask_yes_no "Download Model" "Ready to download AI model:\n\nModel: DeepSeek-V2-Lite ${MODEL}\nSize: ${MODEL_SIZE}\nTime: 10-30 minutes\n\nDownload now?"; then
        show_progress "Downloading model... This will take a while."
        
        # Export config for download script (only MODEL needed now)
        export FORCE_MODEL=$MODEL
        
        # Open Terminal to show download progress
        osascript <<-APPLESCRIPT
            tell application "Terminal"
                activate
                do script "cd '$SCRIPT_DIR' && export FORCE_MODEL='$MODEL' && echo '📥 Downloading DeepSeek-V2-Lite ${MODEL} model...' && echo 'This may take 10-30 minutes.' && echo '' && ./scripts/download-model.sh && echo '' && echo '✅ Download complete! Starting server...' && sleep 2 && ./scripts/gui-chat.sh"
            end tell
APPLESCRIPT
        exit 0
    else
        show_dialog "DeepSeek" "Cannot start without the AI model.\n\nYou can download it later by running this again." "caution"
        exit 0
    fi
fi

# Everything is ready, launch the chat interface
show_progress "Starting DeepSeek-V2-Lite..."
./scripts/gui-chat.sh
