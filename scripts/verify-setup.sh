#!/bin/bash

# Setup Verification Script
# Quick automated check to verify the setup is ready for distribution

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║     DeepSeek-V3 Setup Verification Script             ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

echo "Running verification checks..."
echo ""

# Check 1: Folder structure
echo "1. Checking folder structure..."
if [ -d "scripts" ]; then
    pass "scripts/ folder exists"
else
    fail "scripts/ folder missing"
fi

# Check 2: All scripts present
echo ""
echo "2. Checking required scripts..."
REQUIRED_SCRIPTS=(
    "scripts/run.sh"
    "scripts/launcher.sh"
    "scripts/setup.sh"
    "scripts/download-model.sh"
    "scripts/start-server.sh"
    "scripts/chat.sh"
    "scripts/gui-chat.sh"
    "scripts/test-api.sh"
    "scripts/create-autorun.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        pass "$script exists"
        
        # Check if executable
        if [ -x "$script" ]; then
            pass "  └─ executable"
        else
            warn "  └─ not executable (run: chmod +x $script)"
        fi
    else
        fail "$script missing"
    fi
done

# Check 3: Documentation files
echo ""
echo "3. Checking documentation..."
DOCS=("readme.md" "getstarted.md" "INSTALLATION.md" "TESTING.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        pass "$doc exists"
    else
        fail "$doc missing"
    fi
done

# Check 4: .gitignore
echo ""
echo "4. Checking .gitignore..."
if [ -f ".gitignore" ]; then
    pass ".gitignore exists"
    
    # Check critical entries
    if grep -q "llama.cpp/" .gitignore; then
        pass "  └─ ignores llama.cpp/"
    else
        warn "  └─ should ignore llama.cpp/"
    fi
    
    if grep -q "models/" .gitignore; then
        pass "  └─ ignores models/"
    else
        warn "  └─ should ignore models/"
    fi
    
    if grep -q "*.gguf" .gitignore; then
        pass "  └─ ignores *.gguf"
    else
        warn "  └─ should ignore *.gguf"
    fi
else
    fail ".gitignore missing"
fi

# Check 5: Path references in scripts
echo ""
echo "5. Checking script paths..."

# Check if scripts reference parent directory correctly
if grep -q 'cd \.\.' scripts/run.sh; then
    pass "run.sh navigates to parent directory"
else
    fail "run.sh doesn't navigate to parent directory"
fi

if grep -q 'cd \.\.' scripts/launcher.sh; then
    pass "launcher.sh navigates to parent directory"
else
    fail "launcher.sh doesn't navigate to parent directory"
fi

if grep -q 'cd \.\.' scripts/setup.sh; then
    pass "setup.sh navigates to parent directory"
else
    fail "setup.sh doesn't navigate to parent directory"
fi

if grep -q 'cd \.\.' scripts/download-model.sh; then
    pass "download-model.sh navigates to parent directory"
else
    fail "download-model.sh doesn't navigate to parent directory"
fi

if grep -q 'cd \.\.' scripts/start-server.sh; then
    pass "start-server.sh navigates to parent directory"
else
    fail "start-server.sh doesn't navigate to parent directory"
fi

if grep -q 'cd \.\.' scripts/gui-chat.sh; then
    pass "gui-chat.sh navigates to parent directory"
else
    fail "gui-chat.sh doesn't navigate to parent directory"
fi

# Check 6: Documentation references correct paths
echo ""
echo "6. Checking documentation paths..."

if grep -q "./scripts/run.sh" getstarted.md; then
    pass "getstarted.md references ./scripts/run.sh"
else
    fail "getstarted.md has incorrect path references"
fi

if grep -q "./scripts/" readme.md; then
    pass "readme.md references scripts folder"
else
    warn "readme.md may have incorrect path references"
fi

# Check 7: No legacy files
echo ""
echo "7. Checking for legacy/unwanted files..."

LEGACY_FILES=(
    "run.sh"
    "setup.sh"
    "start-server.sh"
    "THUMB_DRIVE_INSTRUCTIONS.txt"
    "AUTORUN_SETUP.txt"
)

LEGACY_FOUND=0
for file in "${LEGACY_FILES[@]}"; do
    if [ -f "$file" ]; then
        warn "Legacy file found: $file (should be in scripts/ or removed)"
        ((LEGACY_FOUND++))
    fi
done

if [ $LEGACY_FOUND -eq 0 ]; then
    pass "No legacy files in root"
fi

# Check 8: System requirements (optional info)
echo ""
echo "8. System information (for reference)..."
echo "   macOS: $(sw_vers -productVersion)"
echo "   RAM: $(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)'})GB"
echo "   Arch: $(uname -m)"

# Check 9: Test if llama.cpp exists (it shouldn't on fresh setup)
echo ""
echo "9. Checking setup state..."
if [ -d "llama.cpp" ]; then
    warn "llama.cpp/ exists (this is normal if already set up)"
    
    if [ -f "llama.cpp/server" ]; then
        pass "  └─ llama.cpp server binary found"
    else
        warn "  └─ llama.cpp server binary missing (needs rebuild)"
    fi
else
    pass "llama.cpp/ not present (fresh setup ready)"
fi

if [ -d "models" ]; then
    warn "models/ exists (this is normal if already set up)"
    
    if [ -f "models/deepseek-v3-Q4_K_M.gguf" ]; then
        pass "  └─ Model file found"
        MODEL_SIZE=$(ls -lh models/deepseek-v3-Q4_K_M.gguf | awk '{print $5}')
        echo "     Size: $MODEL_SIZE"
    else
        warn "  └─ No model file found"
    fi
else
    pass "models/ not present (fresh setup ready)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo "                    SUMMARY"
echo "════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED!${NC}"
    echo ""
    echo "The setup is ready for distribution."
    echo ""
    echo "Next steps:"
    echo "1. Copy to thumb drive"
    echo "2. Test on clean Mac (see TESTING.md)"
    echo "3. Optionally run ./scripts/create-autorun.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "The setup should work, but review warnings above."
    echo "See TESTING.md for comprehensive testing."
    exit 0
else
    echo -e "${RED}✗ VERIFICATION FAILED${NC}"
    echo ""
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Please fix the errors above before distribution."
    echo "See TESTING.md for details."
    exit 1
fi
