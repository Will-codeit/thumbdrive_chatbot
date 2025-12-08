# Testing Requirements & Checklist

This document outlines all testing requirements before distributing the DeepSeek-V3 thumb drive setup.

## 🎯 Testing Goals

1. Verify all scripts work correctly from the scripts folder
2. Ensure first-time user experience is smooth
3. Validate all paths and dependencies are correct
4. Confirm documentation is accurate
5. Test on clean Mac (not your dev environment)

---

## 📋 Pre-Distribution Checklist

### Phase 1: File Structure & Permissions

- [ ] All scripts are in `scripts/` folder
- [ ] All scripts are executable (`chmod +x scripts/*.sh`)
- [ ] Documentation files are at root level
- [ ] `.gitignore` excludes large files (llama.cpp, models, logs)
- [ ] No outdated or redundant files remain

**Verification:**
```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama
ls -la scripts/
# All .sh files should have executable permissions (x)
```

---

### Phase 2: Documentation Accuracy

- [ ] `readme.md` has correct paths (`./scripts/run.sh`)
- [ ] `getstarted.md` references correct script locations
- [ ] `INSTALLATION.md` has accurate folder structure
- [ ] All links between docs work correctly
- [ ] Version info is current (December 2025)

**Verification:**
```bash
# Check all script references in documentation
grep -r "\.sh" *.md
# Verify they all reference scripts/ folder
```

---

### Phase 3: Script Functionality Tests

#### Test 1: Setup Script
**Purpose:** Verify first-time setup works

- [ ] Run `./scripts/setup.sh`
- [ ] Clones llama.cpp successfully
- [ ] Detects Apple Silicon vs Intel correctly
- [ ] Builds llama.cpp without errors
- [ ] Creates `models/` and `logs/` directories
- [ ] Prompts for model download
- [ ] Completes without errors

**Commands:**
```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama
./scripts/setup.sh
# Follow prompts, verify success messages
```

**Expected Output:**
```
✓ Directories created
✓ llama.cpp cloned
✓ Detected Apple Silicon - enabling Metal acceleration
✓ Build complete!
✓ Setup Complete!
```

---

#### Test 2: Model Download
**Purpose:** Verify model download works

- [ ] Run `./scripts/download-model.sh`
- [ ] Checks for Hugging Face CLI
- [ ] Downloads model successfully OR provides clear manual instructions
- [ ] Model saved to correct location: `models/deepseek-v3-Q4_K_M.gguf`
- [ ] File size is correct (~40GB)

**Commands:**
```bash
./scripts/download-model.sh
# Or manually download for testing
ls -lh models/
```

**Note:** For testing, you may want to use a smaller model first to verify the process works.

---

#### Test 3: Server Startup
**Purpose:** Verify server starts correctly

- [ ] Run `./scripts/start-server.sh`
- [ ] Finds llama.cpp binary
- [ ] Finds model file
- [ ] Server starts without errors
- [ ] Shows correct configuration (port 8080, context size, etc.)
- [ ] Server responds to requests

**Commands:**
```bash
./scripts/start-server.sh
# In another terminal:
curl http://localhost:8080/health
```

**Expected Output:**
```
🚀 Starting DeepSeek-V3 Server...
📊 Model: models/deepseek-v3-Q4_K_M.gguf
🌐 Server: http://localhost:8080
💾 Context: 4096 tokens
```

---

#### Test 4: Main Launcher (CLI)
**Purpose:** Verify run.sh orchestrates everything

- [ ] Run `./scripts/run.sh`
- [ ] Checks system requirements (RAM, macOS version)
- [ ] Detects missing llama.cpp and runs setup
- [ ] Detects missing model and offers to download
- [ ] Starts server successfully
- [ ] Provides clear error messages if issues

**Commands:**
```bash
# Test on fresh copy without llama.cpp
./scripts/run.sh
```

---

#### Test 5: GUI Launcher
**Purpose:** Verify launcher.sh shows dialogs correctly

- [ ] Run `./scripts/launcher.sh`
- [ ] Shows system check dialog with requirements
- [ ] "Ready to start?" button works
- [ ] Detects missing components
- [ ] Opens Terminal windows for progress
- [ ] Launches gui-chat.sh when ready

**Commands:**
```bash
./scripts/launcher.sh
```

**Expected Behavior:**
- macOS dialog appears with system info
- Yes/No buttons work
- Progress notifications appear
- Terminal opens automatically for downloads/builds

---

#### Test 6: Chat Interface (Terminal)
**Purpose:** Verify CLI chat works

- [ ] Server is running (start with `./scripts/run.sh`)
- [ ] Run `./scripts/chat.sh` in new terminal
- [ ] Shows welcome message
- [ ] Accepts user input
- [ ] Sends requests to server
- [ ] Displays AI responses
- [ ] `exit` command works

**Commands:**
```bash
# Terminal 1: Start server
./scripts/run.sh

# Terminal 2: Start chat
./scripts/chat.sh
```

**Test Conversation:**
```
You: Hello, who are you?
DeepSeek: [Should respond with introduction]

You: exit
[Should exit cleanly]
```

---

#### Test 7: GUI Chat Interface
**Purpose:** Verify web chat interface works

- [ ] Run `./scripts/gui-chat.sh`
- [ ] Detects if server is running
- [ ] Starts server automatically if needed
- [ ] Opens browser with chat interface
- [ ] Shows welcome message
- [ ] Can send messages
- [ ] Receives responses
- [ ] UI looks good (no broken styling)
- [ ] Code blocks display correctly
- [ ] Loading indicator works

**Commands:**
```bash
./scripts/gui-chat.sh
```

**Test Cases:**
1. Send simple message: "Hello"
2. Request code: "Write a Python hello world"
3. Long response: "Explain quantum computing"
4. Test markdown: Messages with **bold** and `code`

---

#### Test 8: API Testing
**Purpose:** Verify API is working correctly

- [ ] Server is running
- [ ] Run `./scripts/test-api.sh`
- [ ] Connects to server
- [ ] Sends test prompt
- [ ] Receives valid JSON response
- [ ] Response includes AI-generated text
- [ ] No error messages

**Commands:**
```bash
./scripts/test-api.sh
```

**Expected Output:**
```
✅ Server is responding!

Response:
{
  "choices": [
    {
      "message": {
        "content": "print('Hello, World!')"
      }
    }
  ]
}
```

---

#### Test 9: Auto-Launch App Creation
**Purpose:** Verify .app bundle is created correctly

- [ ] Run `./scripts/create-autorun.sh`
- [ ] Creates `Start DeepSeek.app` in root directory
- [ ] App bundle has correct structure (Contents/MacOS, Contents/Resources)
- [ ] Info.plist is valid
- [ ] Executable script has correct path navigation
- [ ] Double-clicking app works
- [ ] App calls launcher.sh correctly

**Commands:**
```bash
./scripts/create-autorun.sh
ls -la "Start DeepSeek.app"
# Try double-clicking it in Finder
```

**macOS Security Test:**
- [ ] First-run security warning appears
- [ ] Right-click → Open works
- [ ] "Open" button in dialog allows execution
- [ ] Subsequent runs don't show warning

---

### Phase 4: Integration Tests

#### Full Fresh Install Test
**Purpose:** Simulate first-time user experience

1. [ ] Copy folder to clean thumb drive
2. [ ] Plug into Mac with no prior setup
3. [ ] Open Terminal
4. [ ] Navigate to folder
5. [ ] Run `./scripts/run.sh`
6. [ ] Complete full setup process
7. [ ] Download model
8. [ ] Start server
9. [ ] Open chat interface
10. [ ] Have conversation with AI

**Critical Success Criteria:**
- No manual intervention needed (except answering y/n prompts)
- All steps complete successfully
- User can chat with AI at the end
- Process is smooth and intuitive

---

#### GUI-Only Test
**Purpose:** Test non-technical user flow with GUI launcher

1. [ ] Fresh copy on thumb drive
2. [ ] Run `./scripts/create-autorun.sh`
3. [ ] Double-click `Start DeepSeek.app`
4. [ ] Follow GUI prompts only
5. [ ] Complete setup
6. [ ] Chat interface opens automatically
7. [ ] Successfully chat with AI

**User Experience Checklist:**
- [ ] Dialogs are clear and friendly
- [ ] Progress is visible
- [ ] No scary error messages
- [ ] Works without Terminal knowledge
- [ ] Can return to app later and it "just works"

---

### Phase 5: Edge Cases & Error Handling

#### Test Insufficient RAM
- [ ] Test on Mac with 8GB RAM
- [ ] Verify warning message appears
- [ ] System doesn't crash
- [ ] Clear guidance provided

#### Test Insufficient Disk Space
- [ ] Test with < 40GB free
- [ ] Verify space check works
- [ ] Clear error message shown
- [ ] Doesn't attempt download

#### Test Port Conflict
- [ ] Start something else on port 8080
- [ ] Try to start server
- [ ] Verify error is clear
- [ ] Instructions to resolve provided

#### Test Missing Dependencies
- [ ] Remove llama.cpp folder
- [ ] Run server directly
- [ ] Verify helpful error message
- [ ] Points to setup.sh

#### Test Interrupted Download
- [ ] Start model download
- [ ] Cancel mid-download (Ctrl+C)
- [ ] Restart download
- [ ] Verify it handles partial files
- [ ] Can resume or restart cleanly

---

### Phase 6: Compatibility Testing

#### macOS Versions
- [ ] macOS 10.15 Catalina
- [ ] macOS 11 Big Sur
- [ ] macOS 12 Monterey
- [ ] macOS 13 Ventura
- [ ] macOS 14 Sonoma
- [ ] macOS 15 Sequoia

#### Hardware
- [ ] Apple Silicon M1
- [ ] Apple Silicon M2
- [ ] Apple Silicon M3/M4
- [ ] Intel Mac (if accessible)

#### RAM Configurations
- [ ] 16GB RAM (minimum)
- [ ] 32GB RAM (recommended)
- [ ] 64GB+ RAM (optimal)

---

### Phase 7: Documentation Validation

#### User Journey - Complete Beginner
- [ ] Can find getting started instructions
- [ ] `getstarted.md` is clear and easy to follow
- [ ] Commands work as documented
- [ ] Troubleshooting section helps with issues
- [ ] No assumptions about prior knowledge

#### Developer Journey - Setting Up Distribution
- [ ] `INSTALLATION.md` has all needed info
- [ ] Can set up thumb drive for distribution
- [ ] Advanced configuration is clear
- [ ] Testing checklist (this doc) is helpful

#### Quick Reference - Experienced User
- [ ] `readme.md` provides quick overview
- [ ] Can find scripts quickly
- [ ] Links to detailed docs work
- [ ] Command reference is accurate

---

### Phase 8: Performance & Resource Testing

#### Memory Usage
- [ ] Monitor RAM usage during:
  - Server startup
  - First inference
  - Long conversation (10+ exchanges)
  - Multiple parallel requests
- [ ] Verify stays within reasonable limits
- [ ] No memory leaks over extended use

#### CPU Usage
- [ ] Monitor CPU during:
  - Idle (server running, no requests)
  - Active inference
  - Multiple conversations
- [ ] Verify Metal acceleration is working (Apple Silicon)

#### Response Times
- [ ] First response: < 30 seconds (model loading)
- [ ] Subsequent responses: < 10 seconds for simple queries
- [ ] Long responses: Reasonable streaming/progress
- [ ] No timeouts or hangs

**Monitoring Commands:**
```bash
# Memory usage
top -l 1 | grep server

# CPU usage
ps aux | grep server

# Network (verify nothing going externally after setup)
lsof -i | grep server
```

---

## 🚨 Critical Issues (Must Fix Before Distribution)

If any of these fail, **do not distribute**:

- [ ] Scripts fail to execute due to permissions
- [ ] Paths are incorrect (scripts can't find files)
- [ ] Setup fails on fresh Mac
- [ ] Model download fails consistently
- [ ] Server won't start
- [ ] Chat interface doesn't load
- [ ] Security warnings prevent execution
- [ ] Data leaks outside the local system
- [ ] Documentation has wrong instructions

---

## ⚠️ Important Issues (Should Fix)

These should be addressed but aren't blocking:

- [ ] Suboptimal performance on Intel Macs
- [ ] Minor UI glitches in chat interface
- [ ] Verbose log output clutters terminal
- [ ] Download progress not visible
- [ ] Error messages could be more helpful

---

## 📝 Testing Report Template

After testing, document results:

```markdown
# Test Report - [Date]

## Test Environment
- macOS Version: 
- Hardware: 
- RAM: 
- Disk Space: 

## Tests Passed
- [ ] Setup script
- [ ] Model download
- [ ] Server startup
- [ ] CLI launcher
- [ ] GUI launcher
- [ ] Terminal chat
- [ ] Web chat
- [ ] API test
- [ ] App creation

## Tests Failed
[List any failures with details]

## Issues Found
[Document bugs, errors, or unexpected behavior]

## Performance Notes
- Startup time: 
- Response time: 
- Memory usage: 
- CPU usage: 

## User Experience Notes
[Comments on ease of use, clarity, etc.]

## Recommendations
[Suggestions for improvements]

## Ready for Distribution?
[ ] YES - All critical tests passed
[ ] NO - Issues must be resolved first
```

---

## 🔄 Continuous Testing

Before each distribution:
1. Run through Phase 1-3 (basics)
2. Do at least one full fresh install test
3. Verify on clean Mac if possible
4. Update documentation if anything changed
5. Test the "Start DeepSeek.app" if including it

---

## 📞 Getting Help

If you encounter issues during testing:
1. Check server logs in `logs/` directory
2. Review error messages carefully
3. Test each component individually
4. Verify file paths and permissions
5. Try on different Mac if available
6. Check llama.cpp GitHub for known issues

---

**Last Updated:** December 3, 2025
