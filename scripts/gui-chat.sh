#!/bin/bash

# GUI Chat Interface for DeepSeek-V3
# Opens a simple chat window using AppleScript

set -e

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

PORT=8080
API_URL="http://localhost:$PORT/v1/chat/completions"

# Check if server is running
if ! lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Server not running. Starting server..."
    
    # Start server in background Terminal
    osascript <<-APPLESCRIPT
        tell application "Terminal"
            do script "cd '$SCRIPT_DIR' && echo '🚀 Starting DeepSeek-V3 Server...' && echo 'Keep this window open.' && echo '' && ./scripts/start-server.sh"
        end tell
APPLESCRIPT
    
    # Wait for server to start listening on port
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "Server is listening on port $PORT"
            break
        fi
        sleep 1
    done
    
    if ! lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        osascript -e 'display dialog "Failed to start server. Please check the terminal window for errors." with title "DeepSeek-V3 Error" buttons {"OK"} default button "OK" with icon stop'
        exit 1
    fi
fi

# Wait for server to be fully ready (model loaded and accepting requests)
echo "Waiting for model to load (this may take 30-60 seconds)..."
for i in {1..60}; do
    if curl -s -X GET "http://localhost:$PORT/health" >/dev/null 2>&1; then
        echo "✅ Server is fully ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "⚠️  Server is taking longer than expected to load."
        echo "   Opening chat interface anyway..."
    fi
    sleep 1
    if [ $((i % 10)) -eq 0 ]; then
        echo "   Still loading... ($i seconds elapsed)"
    fi
done

# Create a temporary HTML chat interface
CHAT_HTML="/tmp/deepseek_chat.html"
cat > "$CHAT_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>DeepSeek-V3 Chat</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 800px;
            height: 90vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 24px;
            font-weight: bold;
        }
        .header small {
            display: block;
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        .chat-area {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .message {
            margin-bottom: 15px;
            padding: 12px 16px;
            border-radius: 12px;
            max-width: 80%;
            word-wrap: break-word;
            animation: slideIn 0.3s ease;
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .user-message {
            background: #667eea;
            color: white;
            margin-left: auto;
            text-align: right;
        }
        .ai-message {
            background: white;
            color: #333;
            border: 1px solid #ddd;
        }
        .input-area {
            padding: 20px;
            background: white;
            border-top: 1px solid #ddd;
            display: flex;
            gap: 10px;
        }
        input {
            flex: 1;
            padding: 12px 16px;
            border: 2px solid #ddd;
            border-radius: 25px;
            font-size: 16px;
            outline: none;
            transition: border-color 0.3s;
        }
        input:focus {
            border-color: #667eea;
        }
        button {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        button:active {
            transform: translateY(0);
        }
        button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }
        .loading {
            display: none;
            text-align: center;
            color: #999;
            font-style: italic;
            padding: 10px;
        }
        .loading.active {
            display: block;
        }
        pre {
            background: #f0f0f0;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
            margin: 10px 0;
        }
        code {
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            🤖 DeepSeek-V3
            <small>Running locally on your Mac • 100% Private</small>
        </div>
        <div class="chat-area" id="chatArea">
            <div class="message ai-message">
                👋 Hello! I'm DeepSeek-V3, running locally on your computer. I can help you with:
                <br><br>
                💻 Writing and debugging code<br>
                📝 Writing and editing text<br>
                🧮 Math and problem solving<br>
                📚 Answering questions<br>
                🎨 Creative brainstorming<br>
                <br>
                All conversations are private and never leave your Mac. What would you like to work on?
            </div>
        </div>
        <div class="loading" id="loading">DeepSeek is thinking...</div>
        <div class="input-area">
            <input type="text" id="userInput" placeholder="Type your message here..." autofocus>
            <button id="sendBtn" onclick="sendMessage()">Send</button>
        </div>
    </div>

    <script>
        const chatArea = document.getElementById('chatArea');
        const userInput = document.getElementById('userInput');
        const sendBtn = document.getElementById('sendBtn');
        const loading = document.getElementById('loading');

        userInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        async function sendMessage() {
            const message = userInput.value.trim();
            if (!message) return;

            // Add user message
            addMessage(message, 'user');
            userInput.value = '';
            sendBtn.disabled = true;
            loading.classList.add('active');

            try {
                const response = await fetch('http://localhost:8080/v1/chat/completions', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        messages: [{ role: 'user', content: message }],
                        temperature: 0.7,
                        max_tokens: 1000,
                        stream: false
                    })
                });

                const data = await response.json();
                const aiResponse = data.choices[0].message.content;
                
                addMessage(aiResponse, 'ai');
            } catch (error) {
                addMessage('❌ Error: Could not connect to DeepSeek server. Make sure the server is running.', 'ai');
            }

            loading.classList.remove('active');
            sendBtn.disabled = false;
            userInput.focus();
        }

        function addMessage(text, type) {
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}-message`;
            
            // Simple markdown-like formatting
            let formattedText = text
                .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
                .replace(/`([^`]+)`/g, '<code>$1</code>')
                .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
                .replace(/\n/g, '<br>');
            
            messageDiv.innerHTML = formattedText;
            chatArea.appendChild(messageDiv);
            chatArea.scrollTop = chatArea.scrollHeight;
        }
    </script>
</body>
</html>
HTMLEOF

# Open the chat interface in default browser
echo "Opening chat interface..."
open "$CHAT_HTML"

# Show notification
osascript -e 'display notification "Chat window opened in your browser" with title "DeepSeek-V3 Ready" sound name "Glass"'

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ DeepSeek-V3 Chat Interface Opened!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "The chat window should open in your browser."
echo "If not, open this file manually:"
echo "$CHAT_HTML"
echo ""
echo "To stop the server: Press Ctrl+C in the server terminal"
echo ""
