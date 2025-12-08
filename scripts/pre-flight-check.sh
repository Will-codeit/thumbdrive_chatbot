#!/bin/bash

# Pre-flight check - Quick validation before starting DeepSeek
# This catches common issues and provides helpful guidance

echo "════════════════════════════════════════════════════════"
echo "  ✈️  DeepSeek Pre-Flight Check"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Running quick checks to ensure everything is ready..."
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

ISSUES_FOUND=0

# Check 1: Sufficient RAM
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
echo -n "✓ Checking RAM: ${TOTAL_RAM}GB "
if [ $TOTAL_RAM -lt 8 ]; then
    echo "❌"
    echo "  ERROR: Need at least 8GB RAM. Your Mac has ${TOTAL_RAM}GB."
    echo "  This Mac cannot run DeepSeek."
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
elif [ $TOTAL_RAM -eq 8 ]; then
    echo "⚠️  (minimum)"
    echo "  Note: 8GB RAM detected. Will use smaller Q2_K model."
    echo "  Performance will be limited. 16GB+ recommended."
else
    echo "✅"
fi

# Check 2: Disk space
FREE_SPACE=$(df -g "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
echo -n "✓ Checking disk space: ${FREE_SPACE}GB free "
if [ $FREE_SPACE -lt 10 ]; then
    echo "❌"
    echo "  ERROR: Need at least 10GB free space. You have ${FREE_SPACE}GB."
    echo "  Please free up disk space before continuing."
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
elif [ $FREE_SPACE -lt 20 ]; then
    echo "⚠️  (low)"
    echo "  Warning: Only ${FREE_SPACE}GB free. 20GB+ recommended."
else
    echo "✅"
fi

# Check 3: macOS version
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo $OS_VERSION | cut -d. -f1)
echo -n "✓ Checking macOS version: $OS_VERSION "
if [ $OS_MAJOR -ge 11 ]; then
    echo "✅"
elif [ $OS_MAJOR -eq 10 ]; then
    OS_MINOR=$(echo $OS_VERSION | cut -d. -f2)
    if [ $OS_MINOR -ge 15 ]; then
        echo "✅"
    else
        echo "❌"
        echo "  ERROR: macOS $OS_VERSION is too old. Need 10.15 or newer."
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
else
    echo "⚠️  (unknown)"
fi

# Check 4: Required directories
echo -n "✓ Checking directory structure "
MISSING=""
for dir in scripts models logs; do
    if [ ! -d "$dir" ]; then
        MISSING="$MISSING $dir"
    fi
done
if [ -z "$MISSING" ]; then
    echo "✅"
else
    echo "❌"
    echo "  ERROR: Missing directories:$MISSING"
    echo "  Installation may be corrupted."
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 5: Critical scripts exist
echo -n "✓ Checking scripts "
MISSING=""
for script in run.sh setup.sh start-server.sh; do
    if [ ! -f "scripts/$script" ]; then
        MISSING="$MISSING $script"
    fi
done
if [ -z "$MISSING" ]; then
    echo "✅"
else
    echo "❌"
    echo "  ERROR: Missing scripts:$MISSING"
    echo "  Installation may be corrupted."
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
echo "════════════════════════════════════════════════════════"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "  ✅ All checks passed!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    exit 0
else
    echo "  ❌ $ISSUES_FOUND issue(s) found"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Please resolve the issues above before starting DeepSeek."
    echo ""
    exit 1
fi
