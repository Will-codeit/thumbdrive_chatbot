# Installation & Setup Guide

This document provides detailed instructions for setting up DeepSeek-V3 on your thumb drive.

## Table of Contents

- [Quick Start](#quick-start)
- [Folder Structure](#folder-structure)
- [Scripts Overview](#scripts-overview)
- [Manual Setup](#manual-setup)
- [Creating the Auto-Launch App](#creating-the-auto-launch-app)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### For First-Time Setup (Preparing the Thumb Drive)

1. **Clone or download this repository to your thumb drive**
2. **Run the setup script:**
   ```bash
   cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama
   ./scripts/setup.sh
   ```
3. **Create the auto-launch application (optional):**
   ```bash
   ./scripts/create-autorun.sh
   ```
4. **Test it works:**
   ```bash
   ./scripts/run.sh
   ```

### For End Users (Using the Thumb Drive)

See [getstarted.md](getstarted.md) for user-friendly instructions.

---

## Folder Structure

```
deep_seek_llama/
├── readme.md                      # Technical documentation
├── getstarted.md                  # User-friendly quick start guide
├── INSTALLATION.md                # This file
├── AUTORUN_SETUP.txt             # Instructions for auto-launch app
├── THUMB_DRIVE_INSTRUCTIONS.txt  # Quick reference card
├── .gitignore                    # Git ignore rules
│
├── scripts/                      # All executable scripts
│   ├── run.sh                   # Main launcher (CLI version)
│   ├── launcher.sh              # GUI launcher (shows dialogs)
│   ├── setup.sh                 # First-time setup
│   ├── download-model.sh        # Model downloader
│   ├── start-server.sh          # Server startup
│   ├── chat.sh                  # Interactive chat CLI
│   ├── test-api.sh              # API testing tool
│   ├── gui-chat.sh              # Web-based chat interface
│   └── create-autorun.sh        # Creates "Start DeepSeek.app"
│
├── llama.cpp/                   # (Created by setup.sh)
│   └── server                   # Built llama.cpp server binary
│
├── models/                      # (Created by setup.sh)
│   └── deepseek-v3-Q4_K_M.gguf # AI model (~40GB)
│
└── logs/                        # (Created by setup.sh)
    └── server.log               # Server logs
```

---

## Scripts Overview

### User-Facing Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `run.sh` | Main launcher with checks | Primary way to start the server |
| `launcher.sh` | GUI version with dialogs | For non-technical users |
| `chat.sh` | Interactive terminal chat | Quick testing/chatting |
| `gui-chat.sh` | Beautiful web chat UI | Best user experience |
| `test-api.sh` | Test server connection | Verify setup works |

### Setup Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup.sh` | Full setup process | First time setup |
| `download-model.sh` | Download AI model | If model download fails |
| `start-server.sh` | Just start the server | Advanced users |
| `create-autorun.sh` | Build .app launcher | Create clickable app |

---

## Manual Setup

If automatic setup fails, follow these steps:

### 1. Install Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python (for Hugging Face CLI)
brew install python

# Install Hugging Face CLI
pip3 install huggingface-hub
```

### 2. Clone and Build llama.cpp

```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama

# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp

# Build for Apple Silicon
cd llama.cpp
LLAMA_METAL=1 make -j

# Or build for Intel Mac
# make -j
```

### 3. Download the Model

```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama

# Create models directory
mkdir -p models

# Download using Hugging Face CLI
huggingface-cli download deepseek-ai/DeepSeek-V3 \
    --include "*.gguf" \
    --local-dir models/

# Or download manually from:
# https://huggingface.co/models?search=deepseek-v3+gguf
# Place the file in: models/deepseek-v3-Q4_K_M.gguf
```

### 4. Test the Setup

```bash
./scripts/run.sh
```

---

## Creating the Auto-Launch App

For the best user experience, create a double-clickable application:

### 1. Run the App Creator

```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama
./scripts/create-autorun.sh
```

This creates `Start DeepSeek.app` in the scripts folder.

### 2. Move to Thumb Drive Root (Optional)

```bash
mv scripts/"Start DeepSeek.app" ./
```

Now users see the app immediately when they open the thumb drive.

### 3. First Run Security

The first time someone runs the app, macOS will show a security warning:

**Solution:**
1. Right-click (Control+click) the app
2. Select "Open"
3. Click "Open" in the dialog
4. This only needs to be done once per computer

---

## Troubleshooting

### Scripts Won't Execute

```bash
# Make all scripts executable
chmod +x scripts/*.sh
```

### Build Fails on Apple Silicon

```bash
# Ensure you're using the Metal flag
cd llama.cpp
make clean
LLAMA_METAL=1 make -j
```

### Build Fails on Intel Mac

```bash
# Build without Metal
cd llama.cpp
make clean
make -j
```

### Model Download Fails

**Option 1:** Try with different network
```bash
./scripts/download-model.sh
```

**Option 2:** Manual download
1. Visit https://huggingface.co/models?search=deepseek-v3+gguf
2. Download a Q4_K_M quantized GGUF file
3. Place it in `models/deepseek-v3-Q4_K_M.gguf`

### Server Won't Start

**Check port availability:**
```bash
lsof -i :8080
```

**Kill conflicting process:**
```bash
kill -9 <PID>
```

**Or use different port:**
Edit `scripts/start-server.sh` and change `PORT=8080` to `PORT=8081`

### Out of Memory

**Solutions:**
1. Close other applications
2. Use a smaller quantization (Q3_K_M instead of Q4_K_M)
3. Reduce context size in `scripts/start-server.sh`

---

## Advanced Configuration

### Changing the Model Quantization

Edit `scripts/start-server.sh` and `scripts/run.sh`:

```bash
MODEL_PATH="models/deepseek-v3-Q5_K_M.gguf"  # Change this
```

Available quantizations:
- **Q3_K_M** (~30GB) - Smallest, lower quality
- **Q4_K_M** (~40GB) - Recommended
- **Q5_K_M** (~50GB) - Better quality
- **Q6_K** (~60GB) - High quality
- **Q8_0** (~70GB) - Near original

### Adjusting Server Settings

Edit `scripts/start-server.sh`:

```bash
CONTEXT_SIZE=4096  # Increase for longer conversations
PORT=8080          # Change if port is in use
HOST="0.0.0.0"     # Change to "127.0.0.1" for localhost only
```

### Performance Tuning

Edit the server command in `scripts/start-server.sh`:

```bash
./server \
    -m "../$MODEL_PATH" \
    -c $CONTEXT_SIZE \
    -ngl 1 \              # GPU layers (increase for faster inference)
    --threads 8 \         # CPU threads (adjust for your CPU)
    --parallel 4          # Parallel requests
```

---

## Testing Checklist

Before distributing the thumb drive:

- [ ] `./scripts/setup.sh` runs without errors
- [ ] `./scripts/run.sh` starts the server
- [ ] `./scripts/chat.sh` can interact with the AI
- [ ] `./scripts/gui-chat.sh` opens web interface
- [ ] `./scripts/test-api.sh` shows successful response
- [ ] `Start DeepSeek.app` launches correctly
- [ ] Tested on clean Mac (not your dev machine)
- [ ] Tested with security warning bypass procedure
- [ ] All documentation is up to date

---

## Additional Resources

- [Official DeepSeek-V3 Repository](https://github.com/deepseek-ai/DeepSeek-V3)
- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [Hugging Face Models](https://huggingface.co/models?search=deepseek-v3+gguf)
- [User Guide](getstarted.md)
- [Auto-Launch Setup](AUTORUN_SETUP.txt)

---

## Support

For issues or questions:
1. Check [getstarted.md](getstarted.md) troubleshooting section
2. Review server logs in `logs/` directory
3. Check llama.cpp GitHub issues
4. Verify system meets minimum requirements (16GB RAM, macOS 10.15+)
