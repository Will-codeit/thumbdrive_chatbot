# How We Fit a 40GB Model into 8GB RAM

A technical deep-dive into memory management for running large language models on limited hardware.

---

## 🤔 The Paradox

**Question:** How can a 40GB model file run on a Mac with only 8GB of RAM?

**Answer:** It doesn't all load at once! The model stays on disk, and only small portions are loaded into RAM as needed.

---

## 🔧 The Technology: Memory-Mapped Files (mmap)

### What is mmap?

**Memory-mapped files** (mmap) is an operating system feature that allows programs to treat files on disk as if they were in memory.

```
┌─────────────────────────────────────────┐
│     Thumb Drive (Physical Storage)      │
│  ┌───────────────────────────────────┐  │
│  │   deepseek-v3-Q4_K_M.gguf         │  │
│  │   Size: 40GB                      │  │
│  │                                   │  │
│  │   [Model Weights - Layer 1]      │◄─┐
│  │   [Model Weights - Layer 2]      │  │
│  │   [Model Weights - Layer 3]      │  │ mmap maps
│  │   ...                             │  │ file to
│  │   [Model Weights - Layer 80]     │  │ virtual
│  └───────────────────────────────────┘  │ memory
└─────────────────────────────────────────┘
                    │
                    │ Only needed pages
                    │ are loaded into RAM
                    ↓
┌─────────────────────────────────────────┐
│         RAM (Physical Memory 8GB)        │
│  ┌───────────────────────────────────┐  │
│  │  Active Model Pages (~6-8GB)      │  │
│  │                                   │  │
│  │  [Layer 5 weights]  ← Currently  │  │
│  │  [Layer 12 weights] ← processing │  │
│  │  [Layer 23 weights] ← these      │  │
│  │  [Context buffer]                │  │
│  │  [Inference state]               │  │
│  └───────────────────────────────────┘  │
│  Other RAM: OS, apps, buffers           │
└─────────────────────────────────────────┘
```

### How llama.cpp Uses mmap

When llama.cpp starts:

1. **Opens the 40GB file** on the thumb drive
2. **Maps it to virtual memory** (doesn't load it yet!)
3. **As inference runs**, only the needed weights are loaded
4. **OS handles paging** - swapping data in/out of RAM automatically

---

## 📊 Real Memory Usage Breakdown

### For Q4_K_M Model (40GB file) on 8GB RAM Mac:

```
Component                    Size in RAM    Notes
─────────────────────────────────────────────────────────
Active Model Layers          6-8 GB         Only layers being used
KV Cache (context)          ~512 MB         Conversation history
Inference Buffers           ~256 MB         Working memory
llama.cpp Server            ~128 MB         Program itself
Operating System            ~2 GB           macOS background
Other Apps                  Variable        User's programs
─────────────────────────────────────────────────────────
TOTAL IN USE                ~8 GB           Fits in 8GB!
```

**The other 32GB of model data?** Still on the thumb drive, loaded on-demand.

---

## 🔄 How Inference Works

### Step-by-Step Token Generation:

```
User Input: "Write a Python hello world"

Step 1: Tokenization
   "Write" → Token 5792
   "a" → Token 264
   "Python" → Token 13150
   ...
   ↓ Stored in context buffer (~few KB)

Step 2: Attention Layer 1
   ┌──────────────────────┐
   │ Load Layer 1 weights │ ← mmap loads ~500MB from disk
   │ Process tokens       │ ← Computation happens
   │ Generate output      │ ← Result stored in buffer
   └──────────────────────┘
   
Step 3: Attention Layer 2
   ┌──────────────────────┐
   │ Layer 1 may stay     │ ← Cached if RAM available
   │ Load Layer 2 weights │ ← mmap loads next ~500MB
   │ Process previous out │
   └──────────────────────┘
   
... Repeat for all 80 layers ...

Step 4: Output
   "print('Hello, World!')"
   
Step 5: Next Token (if continuing)
   - Only small portions re-loaded
   - Recently used layers often still cached
   - Fast subsequent generations
```

---

## 🧮 The Math

### Why This Works:

**DeepSeek-V3 Architecture:**
- 671B total parameters (full model)
- 37B active parameters per token (MoE - Mixture of Experts)
- Only ~5% of model is "active" at any time

**Q4_K_M Quantization:**
- Each parameter: ~4 bits (0.5 bytes)
- 37B active params × 0.5 bytes = ~18.5GB theoretical
- With optimizations: ~6-8GB actual RAM usage

**Why not 18.5GB?**
1. **Not all layers load at once** - processed sequentially
2. **Weight sharing** - some weights reused
3. **Sparse activation** - MoE only activates relevant experts
4. **Efficient caching** - frequently used weights stay resident

---

## 💾 Apple Silicon Advantage

### Unified Memory Architecture:

```
Traditional Computer:
┌─────────┐         ┌─────────┐
│   CPU   │◄───────►│   RAM   │
└─────────┘         └─────────┘
     │                   
     │ PCIe Bus          
     ↓                   
┌─────────┐         ┌─────────┐
│   GPU   │◄───────►│  VRAM   │
└─────────┘         └─────────┘
     ↑ Data must copy between RAM and VRAM

Apple Silicon (M1/M2/M3/M4):
┌────────────────────────────────┐
│      Unified Memory (8GB)      │
│  ┌──────────────────────────┐  │
│  │  Shared by CPU and GPU   │  │
│  │  No copying needed!      │  │
│  │  Direct GPU access       │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
       ↑              ↑
   ┌───┴───┐      ┌───┴───┐
   │  CPU  │      │  GPU  │
   └───────┘      └───────┘
```

**Benefits:**
- GPU can access model weights directly from RAM
- No RAM→VRAM copying overhead
- Faster inference on Apple Silicon
- More efficient memory usage

---

## ⚡ GPU Offloading

### What `-ngl 20` Means (8GB RAM Configuration):

```
Model has 80 layers total

CPU Processing:
┌─────────────────────────────────┐
│ Layers 1-60 (60 layers)        │ ← Processed on CPU
│ Load from disk → Process → Out │   Slower but works
└─────────────────────────────────┘

GPU Processing:
┌─────────────────────────────────┐
│ Layers 61-80 (20 layers)       │ ← Processed on GPU
│ Stay in unified memory          │   Much faster!
│ Metal acceleration active       │
└─────────────────────────────────┘
```

**Why only 20 layers on GPU with 8GB?**
- GPU layers stay fully resident in RAM
- 20 layers × ~300MB = ~6GB
- Leaves ~2GB for OS and other tasks
- Balance between speed and stability

**With 32GB RAM?**
- Can use `-ngl 99` (all layers on GPU)
- Entire model fits in unified memory
- Maximum performance!

---

## 🐌 Performance Impact

### 8GB vs 16GB vs 32GB RAM:

```
Time to Generate 100 Tokens:

8GB RAM (Q3_K_M, 20 GPU layers)
████████████████░░░░░░░░░░░░░░░░  ~12 seconds
- Frequent disk access
- Some layers CPU-only
- Still very usable!

16GB RAM (Q4_K_M, 33 GPU layers)
██████████░░░░░░░░░░░░░░░░░░░░░░  ~8 seconds
- More layers cached
- More GPU acceleration
- Smooth experience

32GB RAM (Q5_K_M, 99 GPU layers)
█████░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~5 seconds
- Most model in RAM
- All layers on GPU
- Fast responses

64GB RAM (Q6_K, 99 GPU layers, mlock)
███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~3 seconds
- Entire model locked in RAM
- Maximum quality
- Blazing fast
```

---

## 🔍 Paging Explained

### What Happens When RAM is Full:

```
1. Initial State (8GB RAM, starting server)
   ┌────────────────────────────┐
   │ RAM: 2GB free             │
   │ ├─ macOS: 4GB             │
   │ ├─ Model cache: 2GB       │
   │ └─ Available: 2GB         │
   └────────────────────────────┘
   Thumb Drive: Model file ready

2. First Inference (loading Layer 15)
   ┌────────────────────────────┐
   │ RAM: 500MB free           │
   │ ├─ macOS: 4GB             │
   │ ├─ Model cache: 3.5GB     │ ← Layer 15 loaded
   │ └─ Available: 500MB       │
   └────────────────────────────┘
   Thumb Drive: Reading Layer 15 (500MB)

3. Need Layer 47 (RAM full!)
   ┌────────────────────────────┐
   │ macOS pages out old data  │ ← OS evicts unused Layer 15
   │ ├─ macOS: 4GB             │
   │ ├─ Model cache: 3.5GB     │ ← Now has Layer 47
   │ └─ Available: 500MB       │
   └────────────────────────────┘
   Thumb Drive: Reading Layer 47 (500MB)
   
4. Need Layer 15 Again
   ┌────────────────────────────┐
   │ Must reload from disk!    │ ← This is the "slowness"
   │ ├─ macOS: 4GB             │
   │ ├─ Model cache: 3.5GB     │ ← Back to Layer 15
   │ └─ Available: 500MB       │
   └────────────────────────────┘
   Thumb Drive: Re-reading Layer 15
   
   ⚠️ This disk I/O is why more RAM = faster
```

---

## 🎯 Optimization Strategies

### What llama.cpp Does to Minimize RAM:

1. **Quantization** - Reduce precision
   - FP32 (32-bit): 4 bytes per param
   - Q8 (8-bit): 1 byte per param (4x smaller)
   - Q4 (4-bit): 0.5 bytes per param (8x smaller)
   - Q3 (3-bit): 0.375 bytes per param (10.6x smaller)

2. **Layer-by-Layer Processing**
   - Only load current layer
   - Discard after processing (if RAM tight)
   - Sequential processing reduces peak memory

3. **KV Cache Optimization**
   - Only store keys/values for context tokens
   - Configurable max context (2048 vs 16384)
   - Smaller context = less RAM

4. **Batch Size Control**
   - Process fewer tokens simultaneously
   - 8GB: batch_size=256
   - 32GB: batch_size=512
   - Lower batch = less RAM, slightly slower

5. **mlock (if enough RAM)**
   - Locks pages in RAM (prevents swapping)
   - Only on 16GB+ systems
   - Ensures hot paths stay fast

---

## 📈 Real-World Example

### User with 8GB Mac Running Q3_K_M:

```bash
$ ./scripts/run.sh

🔍 Checking system requirements...
✓ macOS version: 14.5
✓ Total RAM: 8GB
⚠️  8GB RAM detected - using optimized Q3 model

🚀 Starting DeepSeek-V3 Server...
⚙️  8GB RAM detected - using optimized settings
   Model: Q3_K_M (smaller, faster)
   Context: 2048 tokens
📊 Model: models/deepseek-v3-Q3_K_M.gguf
💾 Context: 2048 tokens
🎮 GPU Layers: 20

# Server starts...
# Memory usage steady at ~6.5GB
# Thumb drive activity during first few responses
# Then cached layers make it fast!

User: "Write a Python hello world"
# Response in ~3 seconds (first time, loading layers)

User: "Now explain what it does"  
# Response in ~1 second (layers cached!)

User: "Write it in JavaScript too"
# Response in ~1.5 seconds (similar layers reused)
```

---

## 🔬 Technical Details

### The GGUF File Format:

```
deepseek-v3-Q4_K_M.gguf (40GB file)
├── Header (metadata)
│   ├── Model architecture
│   ├── Quantization info
│   └── Tensor locations
├── Tensor Data (39.9GB)
│   ├── Layer 0 Attention Weights
│   ├── Layer 0 FFN Weights
│   ├── Layer 1 Attention Weights
│   ├── Layer 1 FFN Weights
│   ├── ...
│   └── Layer 79 Weights
└── Footer (checksums)

Each tensor has:
- Offset in file (byte position)
- Size (bytes)
- Dimensions (shape)
- Type (Q4_K, Q3_K, etc.)

llama.cpp uses these offsets to mmap
only the tensors it needs!
```

---

## 💡 Key Takeaways

1. **The model file stays on disk** - 40GB never loads into RAM
2. **Only active portions load** - typically 6-12GB depending on RAM
3. **OS handles paging** - automatically swaps data in/out
4. **More RAM = faster** - less disk I/O, more caching
5. **8GB works!** - with smaller model (Q3) and optimizations
6. **Apple Silicon helps** - unified memory architecture is efficient

---

## 🎓 Why This Matters

This technology enables:
- ✅ Running powerful AI on consumer hardware
- ✅ Privacy (no cloud needed)
- ✅ Offline operation (no internet)
- ✅ Cost savings (no API fees)
- ✅ Portability (thumb drive!)

**The magic:** Modern OS memory management + smart quantization + efficient inference = AI on your Mac! 🚀

---

**Last Updated:** December 3, 2025
