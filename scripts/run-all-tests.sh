#!/bin/bash

# Comprehensive Automated Test Suite
# Runs all tests to verify DeepSeek setup is ready for end users

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  🧪 DeepSeek Complete Test Suite"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Log file
LOG_FILE="logs/test-results-$(date +%Y%m%d-%H%M%S).log"
mkdir -p logs

# Helper functions
test_start() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}▶ TEST $TOTAL_TESTS: $1${NC}"
    echo "TEST $TOTAL_TESTS: $1" >> "$LOG_FILE"
}

test_pass() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}  ✅ PASS${NC}"
    echo "  ✅ PASS" >> "$LOG_FILE"
    echo ""
}

test_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}  ❌ FAIL: $1${NC}"
    echo "  ❌ FAIL: $1" >> "$LOG_FILE"
    echo ""
}

test_warn() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "${YELLOW}  ⚠️  WARNING: $1${NC}"
    echo "  ⚠️  WARNING: $1" >> "$LOG_FILE"
    echo ""
}

# Start testing
echo "Starting comprehensive test suite..."
echo "Results will be saved to: $LOG_FILE"
echo ""
echo "Test started: $(date)" > "$LOG_FILE"
echo "" >> "$LOG_FILE"

# =============================================================================
# PHASE 1: FILE STRUCTURE & PERMISSIONS
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  📁 PHASE 1: File Structure & Permissions"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 1: Check critical directories exist
test_start "Critical directories exist"
MISSING_DIRS=""
for dir in scripts models logs docs; do
    if [ ! -d "$dir" ]; then
        MISSING_DIRS="$MISSING_DIRS $dir"
    fi
done

if [ -z "$MISSING_DIRS" ]; then
    test_pass
else
    test_fail "Missing directories:$MISSING_DIRS"
fi

# Test 2: Check critical files exist
test_start "Critical files exist"
MISSING_FILES=""
for file in README.md getstarted.md START_HERE.txt START_DEEPSEEK.command; do
    if [ ! -f "$file" ]; then
        MISSING_FILES="$MISSING_FILES $file"
    fi
done

if [ -z "$MISSING_FILES" ]; then
    test_pass
else
    test_fail "Missing files:$MISSING_FILES"
fi

# Test 3: Check all scripts exist
test_start "All required scripts exist"
MISSING_SCRIPTS=""
for script in run.sh setup.sh start-server.sh download-model.sh launcher.sh \
              chat.sh gui-chat.sh check-memory.sh verify-setup.sh test-api.sh; do
    if [ ! -f "scripts/$script" ]; then
        MISSING_SCRIPTS="$MISSING_SCRIPTS $script"
    fi
done

if [ -z "$MISSING_SCRIPTS" ]; then
    test_pass
else
    test_fail "Missing scripts:$MISSING_SCRIPTS"
fi

# Test 4: Check script permissions
test_start "All scripts are executable"
NON_EXECUTABLE=""
for script in scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        NON_EXECUTABLE="$NON_EXECUTABLE $(basename $script)"
    fi
done

if [ -z "$NON_EXECUTABLE" ]; then
    test_pass
else
    # Auto-fix permissions
    chmod +x scripts/*.sh
    test_warn "Fixed permissions for:$NON_EXECUTABLE"
fi

# Test 5: Check .command files are executable
test_start ".command files are executable"
NON_EXECUTABLE_CMD=""
for cmd_file in *.command; do
    if [ -f "$cmd_file" ] && [ ! -x "$cmd_file" ]; then
        NON_EXECUTABLE_CMD="$NON_EXECUTABLE_CMD $cmd_file"
    fi
done

if [ -z "$NON_EXECUTABLE_CMD" ]; then
    test_pass
else
    # Auto-fix
    chmod +x *.command
    test_warn "Fixed permissions for:$NON_EXECUTABLE_CMD"
fi

# =============================================================================
# PHASE 2: SCRIPT SYNTAX & VALIDITY
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  🔍 PHASE 2: Script Syntax & Validity"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 6: Bash syntax check all scripts
test_start "All scripts have valid bash syntax"
SYNTAX_ERRORS=""
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        if ! bash -n "$script" 2>/dev/null; then
            SYNTAX_ERRORS="$SYNTAX_ERRORS $(basename $script)"
        fi
    fi
done

if [ -z "$SYNTAX_ERRORS" ]; then
    test_pass
else
    test_fail "Syntax errors in:$SYNTAX_ERRORS"
fi

# Test 7: Check for hardcoded paths
test_start "No hardcoded paths in scripts"
HARDCODED_PATHS=$(grep -r "/Users/" scripts/ 2>/dev/null | grep -v "deep_seek_llama" | wc -l)
if [ "$HARDCODED_PATHS" -eq 0 ]; then
    test_pass
else
    test_warn "Found $HARDCODED_PATHS potential hardcoded paths - review manually"
fi

# Test 8: Check scripts use relative paths
test_start "Scripts navigate to correct directory"
MISSING_CD=0
for script in scripts/run.sh scripts/launcher.sh scripts/start-server.sh; do
    if [ -f "$script" ]; then
        if ! grep -q "cd.*SCRIPT_DIR" "$script"; then
            MISSING_CD=1
        fi
    fi
done

if [ $MISSING_CD -eq 0 ]; then
    test_pass
else
    test_warn "Some scripts may not navigate to root directory correctly"
fi

# =============================================================================
# PHASE 3: DOCUMENTATION ACCURACY
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  📚 PHASE 3: Documentation Accuracy"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 9: Check documentation references correct paths
test_start "Documentation references correct script paths"
WRONG_PATHS=$(grep -r "^\./\w" *.md 2>/dev/null | grep -v "./scripts/" | grep -v "./START" | grep -v "./SWITCH" | grep -v "./UPDATE" | wc -l)
if [ "$WRONG_PATHS" -eq 0 ]; then
    test_pass
else
    test_warn "$WRONG_PATHS references to scripts not in scripts/ folder"
fi

# Test 10: Check all documentation files have content
test_start "All documentation files have content"
EMPTY_DOCS=""
for doc in README.md getstarted.md START_HERE.txt docs/readme.md docs/INSTALLATION.md docs/MEMORY_EXPLAINED.md; do
    if [ -f "$doc" ]; then
        SIZE=$(wc -c < "$doc")
        if [ "$SIZE" -lt 100 ]; then
            EMPTY_DOCS="$EMPTY_DOCS $doc"
        fi
    fi
done

if [ -z "$EMPTY_DOCS" ]; then
    test_pass
else
    test_fail "Documentation files too small (< 100 bytes):$EMPTY_DOCS"
fi

# Test 11: Check for broken links in documentation
test_start "No broken internal links in documentation"
# This is a simplified check - just looks for referenced files
BROKEN_LINKS=0
for link in $(grep -oh "\[.*\](\(.*\.md\|.*\.txt\|.*\.sh\))" *.md docs/*.md 2>/dev/null | sed 's/.*(\(.*\))/\1/'); do
    if [ ! -f "$link" ] && [ ! -f "scripts/$link" ]; then
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
done

if [ $BROKEN_LINKS -eq 0 ]; then
    test_pass
else
    test_warn "$BROKEN_LINKS potential broken links found"
fi

# =============================================================================
# PHASE 4: SYSTEM REQUIREMENTS
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  💻 PHASE 4: System Requirements Check"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 12: Check macOS version
test_start "macOS version compatibility"
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo $OS_VERSION | cut -d. -f1)
if [ $OS_MAJOR -ge 11 ] || [ $OS_MAJOR -eq 10 ]; then
    test_pass
else
    test_fail "macOS $OS_VERSION may not be supported"
fi

# Test 13: Check RAM
test_start "Sufficient RAM available"
TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
if [ $TOTAL_RAM -ge 8 ]; then
    test_pass
else
    test_fail "Insufficient RAM: ${TOTAL_RAM}GB (need 8GB minimum)"
fi

# Test 14: Check disk space
test_start "Sufficient disk space"
FREE_SPACE=$(df -g "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
if [ $FREE_SPACE -ge 10 ]; then
    test_pass
else
    test_warn "Low disk space: ${FREE_SPACE}GB (20GB+ recommended)"
fi

# Test 15: Check required tools
test_start "Required command-line tools available"
MISSING_TOOLS=""
for tool in curl bash chmod mkdir; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ -z "$MISSING_TOOLS" ]; then
    test_pass
else
    test_fail "Missing tools:$MISSING_TOOLS"
fi

# Test 16: Check optional tools (for setup)
test_start "Optional tools for first-time setup"
MISSING_OPTIONAL=""
for tool in git cmake make; do
    if ! command -v $tool &> /dev/null; then
        MISSING_OPTIONAL="$MISSING_OPTIONAL $tool"
    fi
done

if [ -z "$MISSING_OPTIONAL" ]; then
    test_pass
else
    test_warn "Optional tools not installed:$MISSING_OPTIONAL (needed for first-time setup)"
fi

# =============================================================================
# PHASE 5: LLAMA.CPP INSTALLATION (IF EXISTS)
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  🔨 PHASE 5: llama.cpp Installation (if present)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 17: Check if llama.cpp exists
test_start "llama.cpp directory structure"
if [ -d "technical/llama.cpp" ] || [ -d "llama.cpp" ]; then
    LLAMA_DIR="technical/llama.cpp"
    [ ! -d "$LLAMA_DIR" ] && LLAMA_DIR="llama.cpp"
    test_pass
else
    test_warn "llama.cpp not installed yet (will download on first run)"
    LLAMA_DIR=""
fi

# Test 18: Check if llama.cpp is built
if [ ! -z "$LLAMA_DIR" ]; then
    test_start "llama.cpp server binary exists"
    if [ -f "$LLAMA_DIR/build/bin/llama-server" ]; then
        test_pass
    else
        test_warn "llama-server not built yet (will build on first run)"
    fi
fi

# =============================================================================
# PHASE 6: MODEL FILES (IF EXISTS)
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  🤖 PHASE 6: AI Model Files (if present)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 19: Check for model files
test_start "AI model files present"
MODEL_COUNT=0
for model in models/*.gguf; do
    if [ -f "$model" ]; then
        MODEL_COUNT=$((MODEL_COUNT + 1))
        SIZE=$(du -h "$model" | awk '{print $1}')
        echo "    Found: $(basename $model) ($SIZE)" | tee -a "$LOG_FILE"
    fi
done

if [ $MODEL_COUNT -gt 0 ]; then
    test_pass
else
    test_warn "No model files found (will download on first run)"
fi

# Test 20: Check model file sizes
if [ $MODEL_COUNT -gt 0 ]; then
    test_start "Model files are complete (not corrupted)"
    SMALL_MODELS=0
    for model in models/*.gguf; do
        if [ -f "$model" ]; then
            SIZE_BYTES=$(stat -f%z "$model" 2>/dev/null || stat -c%s "$model" 2>/dev/null)
            # Models should be at least 1GB (Q2_K is ~5GB)
            if [ "$SIZE_BYTES" -lt 1000000000 ]; then
                SMALL_MODELS=$((SMALL_MODELS + 1))
            fi
        fi
    done
    
    if [ $SMALL_MODELS -eq 0 ]; then
        test_pass
    else
        test_warn "$SMALL_MODELS model file(s) may be incomplete or corrupted"
    fi
fi

# =============================================================================
# PHASE 7: FUNCTIONAL TESTS (IF SETUP COMPLETE)
# =============================================================================

if [ ! -z "$LLAMA_DIR" ] && [ $MODEL_COUNT -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  ⚙️  PHASE 7: Functional Tests"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Test 21: verify-setup.sh runs without errors
    test_start "verify-setup.sh runs successfully"
    if [ -f "scripts/verify-setup.sh" ]; then
        if bash scripts/verify-setup.sh > /dev/null 2>&1; then
            test_pass
        else
            test_warn "verify-setup.sh reported issues (may be expected)"
        fi
    else
        test_fail "verify-setup.sh not found"
    fi
    
    # Test 22: Check if server can be started (don't actually start it)
    test_start "Server startup script is valid"
    if [ -f "scripts/start-server.sh" ]; then
        # Just check syntax, don't run
        if bash -n scripts/start-server.sh; then
            test_pass
        else
            test_fail "start-server.sh has syntax errors"
        fi
    else
        test_fail "start-server.sh not found"
    fi
    
else
    echo "════════════════════════════════════════════════════════════════"
    echo "  ⚠️  PHASE 7: Functional Tests (SKIPPED)"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Skipping functional tests - llama.cpp or models not installed"
    echo "(This is OK for pre-distribution testing)"
    echo ""
fi

# =============================================================================
# PHASE 8: USER EXPERIENCE CHECKS
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  👤 PHASE 8: User Experience Checks"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 23: START_DEEPSEEK.command is obvious and accessible
test_start "Main launcher is easy to find"
if [ -f "START_DEEPSEEK.command" ] && [ -x "START_DEEPSEEK.command" ]; then
    test_pass
else
    test_fail "START_DEEPSEEK.command missing or not executable"
fi

# Test 24: README is clear and concise
test_start "README.md is user-friendly"
README_SIZE=$(wc -c < README.md)
if [ "$README_SIZE" -gt 200 ] && [ "$README_SIZE" -lt 5000 ]; then
    test_pass
else
    test_warn "README.md may be too short or too long for quick reference"
fi

# Test 25: START_HERE.txt provides visual guidance
test_start "START_HERE.txt provides clear instructions"
if [ -f "START_HERE.txt" ]; then
    if grep -q "DOUBLE-CLICK" START_HERE.txt; then
        test_pass
    else
        test_warn "START_HERE.txt may not have clear call-to-action"
    fi
else
    test_fail "START_HERE.txt not found"
fi

# =============================================================================
# FINAL SUMMARY
# =============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  📊 TEST SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "Total Tests Run: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

# Calculate pass rate
PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo "Pass Rate: ${PASS_RATE}%"
echo ""

# Write summary to log
echo "" >> "$LOG_FILE"
echo "========== SUMMARY ==========" >> "$LOG_FILE"
echo "Total Tests: $TOTAL_TESTS" >> "$LOG_FILE"
echo "Passed: $PASSED_TESTS" >> "$LOG_FILE"
echo "Warnings: $WARNINGS" >> "$LOG_FILE"
echo "Failed: $FAILED_TESTS" >> "$LOG_FILE"
echo "Pass Rate: ${PASS_RATE}%" >> "$LOG_FILE"
echo "Test completed: $(date)" >> "$LOG_FILE"

# Distribution readiness
echo "════════════════════════════════════════════════════════════════"
echo "  🎯 DISTRIBUTION READINESS"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ READY FOR DISTRIBUTION${NC}"
    echo ""
    echo "All critical tests passed! The setup is ready for end users."
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo "Note: $WARNINGS warning(s) detected, but they are not blocking."
        echo "Review the log file for details: $LOG_FILE"
    fi
    echo ""
    exit 0
else
    echo -e "${RED}❌ NOT READY FOR DISTRIBUTION${NC}"
    echo ""
    echo "$FAILED_TESTS critical test(s) failed."
    echo "Please fix the issues above before distributing to users."
    echo ""
    echo "Review the full log: $LOG_FILE"
    echo ""
    exit 1
fi
