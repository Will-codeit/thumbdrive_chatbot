#!/bin/bash

# Clear Memory Cache Script
# Clears cached files from RAM to free up memory on macOS
# Compatible with both Intel (x86_64) and Apple Silicon (arm64) Macs

set -e  # Exit on error
trap 'echo ""; echo "❌ Script failed. Please report this error."; exit 1' ERR

echo "════════════════════════════════════════════════════════"
echo "  🧹 Clear Memory Cache"
echo "════════════════════════════════════════════════════════"
echo ""

# Detect system architecture and OS version
ARCH=$(uname -m)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo "$OS_VERSION" | cut -d. -f1)

echo "🖥️  System Information:"
echo "   Architecture: $ARCH"
echo "   macOS Version: $OS_VERSION"

# Validate macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo ""
    echo "❌ Error: This script only works on macOS"
    exit 1
fi

# Check for minimum macOS version (10.9+)
if [ "$OS_MAJOR" -lt 10 ]; then
    echo ""
    echo "❌ Error: This script requires macOS 10.9 or later"
    exit 1
fi

# Architecture-specific notes
case "$ARCH" in
    arm64)
        echo "   Type: Apple Silicon (M-series chip)"
        DYLD_CACHE_PATH="/var/db/dyld/dyld_shared_cache_arm64e"
        ;;
    x86_64)
        echo "   Type: Intel processor"
        DYLD_CACHE_PATH="/var/db/dyld/dyld_shared_cache_x86_64"
        ;;
    *)
        echo "   Type: Unknown ($ARCH)"
        DYLD_CACHE_PATH=""
        ;;
esac

echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script requires administrator privileges to clear system caches."
    echo ""
    echo "Re-running with sudo..."
    echo ""
    exec sudo -E "$0" "$@"
fi

echo "Checking current memory usage..."
echo ""

# Get memory stats before (with error handling)
get_memory_stats() {
    if ! command -v vm_stat &> /dev/null; then
        echo "   ⚠️  vm_stat not available, skipping memory stats"
        return
    fi
    
    vm_stat 2>/dev/null | awk '
        /Pages free/ {free=$3}
        /Pages active/ {active=$3}
        /Pages inactive/ {inactive=$3}
        /Pages wired down/ {wired=$4}
        /Pages purgeable/ {purgeable=$3}
        /File-backed pages/ {file_backed=$3}
        END {
            page_size = 4096
            free_gb = (free * page_size) / (1024*1024*1024)
            inactive_gb = (inactive * page_size) / (1024*1024*1024)
            purgeable_gb = (purgeable * page_size) / (1024*1024*1024)
            file_backed_gb = (file_backed * page_size) / (1024*1024*1024)
            
            printf "Free Memory:        %.2f GB\n", free_gb
            printf "Inactive Memory:    %.2f GB\n", inactive_gb
            printf "Purgeable Memory:   %.2f GB\n", purgeable_gb
            printf "File-backed Pages:  %.2f GB\n", file_backed_gb
        }' || echo "   ⚠️  Could not parse memory statistics"
}

echo "📊 Before clearing cache:"
get_memory_stats
echo ""

echo "🧹 Clearing memory cache..."
echo ""

# Step 1: Purge disk cache (this is the main cache clearing command)
echo "1️⃣  Purging disk cache..."
if command -v purge &> /dev/null; then
    echo "   ⏳ Running purge (this may take 30-60 seconds)..."
    if purge 2>/dev/null; then
        echo "   ✅ Disk cache purged"
    else
        echo "   ⚠️  Purge command failed (may not be critical)"
    fi
else
    echo "   ⚠️  'purge' command not available on this system"
    echo "   ℹ️  Trying alternative method..."
    
    # Alternative: sync to flush file system buffers
    if command -v sync &> /dev/null; then
        sync
        echo "   ✅ File system buffers flushed"
    fi
fi
echo ""

# Step 2: Clear user-level caches (safe to do without restart)
echo "2️⃣  Clearing user caches..."
CACHES_CLEARED=0

if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    USER_CACHE="$USER_HOME/Library/Caches"
    
    if [ ! -d "$USER_CACHE" ]; then
        echo "   ⚠️  User cache directory not found: $USER_CACHE"
    else
        # Clear Safari cache
        if [ -d "$USER_CACHE/com.apple.Safari" ]; then
            rm -rf "$USER_CACHE/com.apple.Safari/"* 2>/dev/null && {
                echo "   ✅ Safari cache cleared"
                CACHES_CLEARED=$((CACHES_CLEARED + 1))
            } || echo "   ⚠️  Could not clear Safari cache"
        fi
        
        # Clear Chrome cache
        if [ -d "$USER_CACHE/Google/Chrome" ]; then
            rm -rf "$USER_CACHE/Google/Chrome/Default/Cache" 2>/dev/null && {
                echo "   ✅ Chrome cache cleared"
                CACHES_CLEARED=$((CACHES_CLEARED + 1))
            } || echo "   ⚠️  Could not clear Chrome cache"
        fi
        
        # Clear Firefox cache
        if [ -d "$USER_CACHE/Firefox" ]; then
            rm -rf "$USER_CACHE/Firefox/Profiles/"*/cache* 2>/dev/null && {
                echo "   ✅ Firefox cache cleared"
                CACHES_CLEARED=$((CACHES_CLEARED + 1))
            } || echo "   ⚠️  Could not clear Firefox cache"
        fi
        
        # Clear Edge cache
        if [ -d "$USER_CACHE/Microsoft Edge" ]; then
            rm -rf "$USER_CACHE/Microsoft Edge/Default/Cache" 2>/dev/null && {
                echo "   ✅ Edge cache cleared"
                CACHES_CLEARED=$((CACHES_CLEARED + 1))
            } || echo "   ⚠️  Could not clear Edge cache"
        fi
        
        if [ $CACHES_CLEARED -eq 0 ]; then
            echo "   ℹ️  No browser caches found to clear"
        fi
    fi
else
    echo "   ⚠️  Could not determine user home directory"
fi
echo ""

# Step 3: Clear system-level caches (requires sudo)
echo "3️⃣  Clearing system caches..."

# Clear dynamic linker cache (architecture-specific)
if [ -n "$DYLD_CACHE_PATH" ] && [ -f "$DYLD_CACHE_PATH" ]; then
    echo "   ℹ️  Dyld cache found ($ARCH) - will be rebuilt on next boot"
elif [ -n "$DYLD_CACHE_PATH" ]; then
    echo "   ℹ️  Dyld cache not found (normal for some systems)"
fi

# Clear DNS cache (with error handling for different macOS versions)
echo "   🌐 Flushing DNS cache..."
if command -v dscacheutil &> /dev/null; then
    dscacheutil -flushcache 2>/dev/null && echo "   ✅ DNS cache flushed (dscacheutil)" || true
fi

# Different methods for different macOS versions
if [ "$OS_MAJOR" -ge 11 ]; then
    # macOS 11+ (Big Sur and later)
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null && echo "   ✅ DNS responder restarted" || true
elif [ "$OS_MAJOR" -eq 10 ]; then
    # macOS 10.x
    sudo killall -HUP mDNSResponder 2>/dev/null && echo "   ✅ DNS responder restarted" || true
    sudo killall mDNSResponderHelper 2>/dev/null || true
    sudo dscacheutil -flushcache 2>/dev/null || true
fi

echo ""

# Step 4: Show memory stats after
echo "📊 After clearing cache:"
sleep 2  # Wait for system to settle
get_memory_stats
echo ""

# Calculate freed memory
echo "════════════════════════════════════════════════════════"
echo "  ✅ Cache clearing complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "💡 Tips to keep memory free:"
echo "  • Close unused browser tabs"
echo "  • Quit apps you're not using"
echo "  • Restart your Mac periodically"
echo "  • Use Activity Monitor to find memory hogs"
echo ""
echo "🔍 To monitor memory in real-time, run:"
echo "   ./scripts/memory-watchdog.sh"
echo ""
echo "ℹ️  System Info: $ARCH | macOS $OS_VERSION"
echo ""
