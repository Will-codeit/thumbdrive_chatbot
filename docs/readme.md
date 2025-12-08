# DeepSeek-V3 Portable Setup

Run DeepSeek-V3 locally on your Mac from a thumb drive. Everything runs offline and private after initial setup.

## 🚀 Quick Start

### For End Users
If you received this on a thumb drive, see **[START_HERE.txt](../START_HERE.txt)** for instant instructions.

**Two ways to launch:**

1. **Recommended (thumb drive):** Double-click `START_DEEPSEEK.command`
   - Works instantly on any Mac
   - No security warnings
   - Perfect for portable thumb drive use

2. **Alternative:** Double-click `🚀 Start DeepSeek.app`
   - Nice icon and professional look
   - May require one-time security approval on macOS

Or manually via terminal:
```bash
cd /Volumes/YOUR_DRIVE_NAME/deep_seek_llama
./START_DEEPSEEK.command
```

### For Developers
Setting up the thumb drive for distribution? See **[INSTALLATION.md](INSTALLATION.md)** for complete setup instructions.

---

## 📋 About DeepSeek-V3

**DeepSeek-V3** is a powerful open-source AI model released in December 2025:
- **671B total parameters** (37B activated per token via MoE architecture)
- **128K context window** - handle long documents and conversations
- **Exceptional performance** on coding, math, and reasoning tasks
- **Competitive with GPT-4** and Claude 3.5 Sonnet
- **100% local and private** - runs entirely on your Mac

---

## 🎯 Features

- ✅ **Portable** - Runs from thumb drive, no installation needed
- ✅ **Private** - All data stays on your Mac, never sent to cloud
- ✅ **Offline** - Works without internet (after initial model download)
- ✅ **GUI Chat Interface** - Beautiful web-based chat window
- ✅ **OpenAI-Compatible API** - Use with existing tools and code
- ✅ **Easy Setup** - Automated scripts handle everything

---

## 📦 What's Included

### User Scripts
- **run.sh** - Main launcher with system checks
- **launcher.sh** - GUI version with dialog popups
- **chat.sh** - Interactive terminal chat
- **gui-chat.sh** - Beautiful web chat interface
- **test-api.sh** - Verify server is working

### Setup Scripts
- **setup.sh** - First-time installation
- **download-model.sh** - Download the AI model
- **start-server.sh** - Start the server
- **create-autorun.sh** - Build clickable .app launcher

### Documentation
- **getstarted.md** - User-friendly quick start guide
- **INSTALLATION.md** - Complete technical setup guide
- **readme.md** - This file

---

## 💻 System Requirements

- **macOS**: 10.15 or later
- **RAM**: 8GB minimum (with Q3 model), 16GB+ recommended, 32GB+ optimal
- **Storage**: 50GB+ free space on thumb drive
- **Internet**: Required for initial model download only (~25-50GB depending on model)
- **CPU**: Apple Silicon (M1/M2/M3/M4) recommended for best performance

### 🔍 Important: How Memory Works

**The model doesn't fully load into RAM!**

llama.cpp uses **memory-mapped files (mmap)**:
- The model stays on the thumb drive
- Only active portions load into RAM (typically 6-12GB)
- On Apple Silicon, layers offload to GPU (unified memory)
- The OS pages data in/out as needed

**Performance by RAM:**
- **8GB RAM**: ✅ Works with Q3_K_M model (~24GB file, 6-8GB in RAM) - Reduced quality, limited context
- **16GB RAM**: ✅✅ Works with Q4_K_M model (~40GB file, 8-12GB in RAM) - Good quality, standard performance
- **32GB RAM**: ✅✅✅ **Recommended** - Q5_K_M model, most of model fits in memory
- **64GB+ RAM**: ✅✅✅✅ **Optimal** - Q6_K model, entire model + large context in memory

### 📦 Model Selection (Automatic)

The system automatically chooses the best model for your RAM:

| Your RAM | Model Used | File Size | Quality | Speed |
|----------|------------|-----------|---------|-------|
| 8GB | Q3_K_M | ~24GB | Good | Fast |
| 16GB | Q4_K_M | ~40GB | Very Good | Moderate |
| 32GB | Q5_K_M | ~50GB | Excellent | Fast |
| 64GB+ | Q6_K | ~60GB | Near-Perfect | Very Fast |

---

## 🔧 How It Works

This setup uses:
1. **llama.cpp** - Efficient C++ inference engine with Metal acceleration
2. **DeepSeek-V3 (GGUF)** - Quantized model optimized for local inference
3. **OpenAI-Compatible API** - Standard REST API for chat completions

All components run locally with no external dependencies after setup.

---

## 📚 Documentation

- **[getstarted.md](../getstarted.md)** - Start here if you're new
- **[INSTALLATION.md](INSTALLATION.md)** - Technical setup and configuration
- **[llama.cpp docs](https://github.com/ggerganov/llama.cpp)** - Server documentation
- **[DeepSeek-V3 repo](https://github.com/deepseek-ai/DeepSeek-V3)** - Model information

---

## 🔒 Privacy & Security

- ✅ **100% Local** - Runs entirely on your Mac
- ✅ **No Cloud** - No data sent to external servers
- ✅ **Offline Capable** - Works without internet after setup
- ✅ **Open Source** - Auditable code and models
- ✅ **Your Data** - Conversations never leave your computer

Perfect for:
- Working with sensitive code or data
- Offline development
- Privacy-conscious users
- Air-gapped environments

---

## 🎨 Use Cases

- **💻 Coding** - Write, debug, and explain code
- **📝 Writing** - Generate and edit content
- **🧮 Math** - Solve complex problems
- **📚 Learning** - Get explanations and tutoring
- **🔍 Research** - Analyze and summarize documents
- **💡 Brainstorming** - Generate ideas and solutions

---

## 🚀 Performance Tips

1. **Apple Silicon** (M1/M2/M3/M4) provides best performance with Metal acceleration
2. **More RAM** = Better performance with larger context windows
3. **SSD/NVMe thumb drives** reduce initial load time (10-30 sec vs 1-3 min on USB 2.0)
4. **Close heavy apps** when running to free up RAM
5. **Adjust model quantization** for speed vs. quality trade-off

### 📌 Important: Thumb Drive Speed Impact

**Good news:** Thumb drive speed has **minimal impact on inference speed**!

- **Why?** The model uses memory-mapping (mmap) - only active parts load into RAM
- **Thumb drive only affects:** Initial startup time (10 seconds to 3 minutes depending on drive)
- **Thumb drive does NOT affect:** AI response speed once active portions are cached in RAM
- **After first few responses:** Most-used model weights are cached in RAM

**Recommendation:** USB 3.0+ thumb drives load faster, but even USB 2.0 works fine once cached.

### 💾 Memory Usage Reality Check

**The 40GB model doesn't fully load into RAM:**
- Uses **memory-mapped files** - model stays on disk
- Only **8-12GB typically in RAM** during inference (active layers + context)
- On Apple Silicon: GPU layers use unified memory (shared with RAM)
- **16GB RAM works** but will page from disk (slower)
- **32GB+ RAM recommended** for most model to stay resident

---

## 🛠️ Advanced Configuration

### Model Quantization Options
- **Q3_K_M** (~30GB) - Fastest, lower quality
- **Q4_K_M** (~40GB) - **Recommended balance**
- **Q5_K_M** (~50GB) - Better quality
- **Q6_K** (~60GB) - High quality
- **Q8_0** (~70GB) - Near original quality

### Server Settings
Edit `scripts/start-server.sh` to adjust:
- Context window size (default: 4096 tokens)
- Server port (default: 8080)
- Number of threads
- Parallel request handling

See [INSTALLATION.md](INSTALLATION.md) for details.

---

## 🐛 Troubleshooting

### Common Issues

**Scripts won't run:**
```bash
chmod +x scripts/*.sh
```

**Out of memory:**
- Close other applications
- Use smaller quantization (Q4_K_M or Q3_K_M)
- Reduce context size in settings

**Server won't start:**
- Check if port 8080 is in use: `lsof -i :8080`
- Change port in `scripts/start-server.sh`

**Model download fails:**
- Check internet connection
- Ensure 40GB+ free space
- Try manual download from Hugging Face

See [getstarted.md](../getstarted.md) for more troubleshooting help.

---

## 📦 Folder Structure

```
deep_seek_llama/
├── README.md                      # Simple overview (start here!)
├── START_HERE.txt                 # Quick visual guide
├── START_DEEPSEEK.command         # Double-click launcher (recommended)
├── 🚀 Start DeepSeek.app           # Alternative launcher with icon
├── getstarted.md                  # Detailed user guide
│
├── scripts/                       # Automation scripts
│   ├── run.sh                    # Main launcher
│   ├── launcher.sh               # GUI launcher
│   ├── setup.sh                  # Setup script
│   ├── chat.sh                   # Terminal chat
│   ├── gui-chat.sh               # Web chat interface
│   └── ... (more)
│
├── docs/                          # All documentation
│   ├── readme.md                 # Technical docs
│   ├── INSTALLATION.md           # Setup guide
│   ├── MEMORY_EXPLAINED.md       # Memory guide
│   └── TESTING.md                # Testing guide
│
├── technical/                     # Advanced/technical files
│   ├── llama.cpp/                # AI engine (auto-built)
│   ├── .git/                     # Git repository
│   └── logs/                     # Debug logs
│
├── models/                        # AI models (auto-downloaded)
└── logs/                          # Server logs
```

---

## 🤝 Contributing

This is a portable setup designed for ease of use. To improve it:
1. Test on different Mac configurations
2. Report issues or suggestions
3. Improve documentation
4. Add new features or optimizations

---

## 📄 License

- **DeepSeek-V3**: MIT License
- **llama.cpp**: MIT License
- **This Setup**: MIT License

See individual component repositories for full license details.

---

## 🔗 Resources

- [DeepSeek-V3 Official Repository](https://github.com/deepseek-ai/DeepSeek-V3)
- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [DeepSeek-V3 Models on Hugging Face](https://huggingface.co/models?search=deepseek-v3+gguf)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)

---

## 📞 Support

For help:
1. Check [getstarted.md](../getstarted.md) for user guides
2. Review [INSTALLATION.md](INSTALLATION.md) for technical details
3. Check server logs in `logs/` directory
4. Visit llama.cpp GitHub for community support

---

**Made with ❤️ for local AI enthusiasts**