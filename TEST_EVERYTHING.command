#!/bin/bash

# One-click test runner for end-user validation
# Double-click this to verify everything is ready

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

clear

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║        🧪 DeepSeek Complete Test Suite                     ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This will run comprehensive tests to verify everything"
echo "is set up correctly for end users."
echo ""
read -p "Press Enter to start testing..."

# Run the test suite
if [ -f "scripts/run-all-tests.sh" ]; then
    bash scripts/run-all-tests.sh
else
    echo "❌ ERROR: run-all-tests.sh not found!"
    echo ""
    echo "The test suite is missing from scripts/"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
read -p "Press Enter to close this window..."
