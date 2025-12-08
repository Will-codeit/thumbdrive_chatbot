#!/bin/bash

# Memory Watchdog - Monitors and alerts on memory usage
# Can be run alongside the server to prevent crashes

INTERVAL=10  # Check every 10 seconds
WARNING_THRESHOLD=10  # Warn when free memory < 10%
CRITICAL_THRESHOLD=5  # Auto-shutdown when free memory < 5%

echo "🐕 Memory Watchdog Started"
echo "   Monitoring memory every ${INTERVAL} seconds"
echo "   Warning threshold: ${WARNING_THRESHOLD}% free"
echo "   Critical threshold: ${CRITICAL_THRESHOLD}% free"
echo ""

while true; do
    # Get memory pressure percentage
    MEM_FREE=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage:" | awk '{print $5}' | tr -d '%')
    
    if [ -z "$MEM_FREE" ]; then
        sleep $INTERVAL
        continue
    fi
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    if (( $(echo "$MEM_FREE < $CRITICAL_THRESHOLD" | bc -l) )); then
        echo "[$TIMESTAMP] 🚨 CRITICAL: ${MEM_FREE}% free - System may crash!"
        osascript -e "display notification \"Only ${MEM_FREE}% memory free! Close applications immediately.\" with title \"CRITICAL: Memory Alert\" sound name \"Basso\""
    elif (( $(echo "$MEM_FREE < $WARNING_THRESHOLD" | bc -l) )); then
        echo "[$TIMESTAMP] ⚠️  WARNING: ${MEM_FREE}% free - Close some applications"
    else
        echo "[$TIMESTAMP] ✅ OK: ${MEM_FREE}% free"
    fi
    
    sleep $INTERVAL
done
