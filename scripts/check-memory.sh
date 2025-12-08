#!/bin/bash

# Memory Safety Check Script
# Verifies sufficient memory before starting the model

set -e

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

CONFIG_FILE="$SCRIPT_DIR/.config"

# Function to get memory in GB
get_total_ram() {
    sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}'
}

get_available_ram() {
    # Get available memory in GB (free + inactive + purgeable)
    vm_stat | awk '
        /Pages free/ {free=$3}
        /Pages inactive/ {inactive=$3}
        /Pages purgeable/ {purgeable=$3}
        END {
            pages = free + inactive + purgeable
            gb = (pages * 4096) / (1024*1024*1024)
            printf "%.1f", gb
        }'
}

get_memory_pressure() {
    # Check memory pressure (returns percentage)
    memory_pressure | grep "System-wide memory free percentage:" | awk '{print $5}' | tr -d '%'
}

# Get model size requirements
get_model_size() {
    local model=$1
    case $model in
        Q2_K)   echo "5.4" ;;
        Q3_K_M) echo "7.6" ;;
        Q4_K_M) echo "9.0" ;;
        Q5_K_M) echo "11.0" ;;
        Q6_K)   echo "13.0" ;;
        *)      echo "7.6" ;;
    esac
}

# Check if we have enough memory
check_memory_safety() {
    local model=$1
    local total_ram=$2
    local available_ram=$3
    
    local model_size=$(get_model_size "$model")
    local overhead=2.0  # OS + browser + apps overhead
    local required=$(echo "$model_size + $overhead" | bc)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💾 Memory Safety Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Total RAM:     ${total_ram}GB"
    echo "Available RAM: ${available_ram}GB"
    echo "Model Size:    ${model_size}GB (${model})"
    echo "Overhead:      ${overhead}GB (OS + apps)"
    echo "Required:      ${required}GB"
    echo ""
    
    # Check if required memory exceeds total RAM
    if (( $(echo "$required > $total_ram" | bc -l) )); then
        echo "❌ INSUFFICIENT RAM"
        echo ""
        echo "This model requires ${required}GB but you only have ${total_ram}GB total RAM."
        echo ""
        echo "Recommended actions:"
        echo "  1. Switch to a smaller model (run: ./SWITCH_MODEL.command)"
        
        case $total_ram in
            8)  echo "     → Use Q2_K (5.4GB) for 8GB systems" ;;
            16) echo "     → Use Q3_K_M (7.6GB) for 16GB systems" ;;
            24) echo "     → Use Q4_K_M (9GB) for 24GB systems" ;;
        esac
        
        echo "  2. Close other applications to free memory"
        echo "  3. Restart your Mac to clear memory"
        echo ""
        return 1
    fi
    
    # Check if available memory is sufficient
    if (( $(echo "$required > $available_ram" | bc -l) )); then
        echo "⚠️  WARNING: Low available memory"
        echo ""
        echo "Available RAM (${available_ram}GB) is less than required (${required}GB)."
        echo "The system will use swap memory (disk), which may cause:"
        echo "  • Slow performance"
        echo "  • System freezing"
        echo "  • Potential crashes"
        echo ""
        echo "Recommended actions:"
        echo "  1. Close other applications (browsers, apps, etc.)"
        echo "  2. Use a smaller model (run: ./SWITCH_MODEL.command)"
        echo "  3. Restart your Mac to free memory"
        echo ""
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled for safety."
            return 1
        fi
        return 0
    fi
    
    # Check memory pressure
    local mem_pressure=$(get_memory_pressure)
    if [ ! -z "$mem_pressure" ] && (( $(echo "$mem_pressure < 20" | bc -l) )); then
        echo "⚠️  WARNING: High memory pressure detected"
        echo ""
        echo "Your system is already under memory pressure (${mem_pressure}% free)."
        echo "Loading a large model may cause system instability."
        echo ""
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled for safety."
            return 1
        fi
        return 0
    fi
    
    echo "✅ Memory check passed"
    echo ""
    return 0
}

# Main execution
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    MODEL=${MODEL:-Q3_K_M}
else
    MODEL="Q3_K_M"
fi

TOTAL_RAM=$(get_total_ram)
AVAILABLE_RAM=$(get_available_ram)

check_memory_safety "$MODEL" "$TOTAL_RAM" "$AVAILABLE_RAM"
exit_code=$?

exit $exit_code
