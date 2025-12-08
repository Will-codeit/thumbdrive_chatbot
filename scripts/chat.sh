#!/bin/bash

# Interactive chat script using the DeepSeek API

PORT=8080
API_URL="http://localhost:$PORT/v1/chat/completions"

echo "════════════════════════════════════════════════════════"
echo "  💬 DeepSeek-V3 Interactive Chat"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Make sure the server is running first (./run.sh)"
echo "Type 'exit' or 'quit' to stop."
echo ""

while true; do
    echo -n "You: "
    read USER_INPUT
    
    if [[ "$USER_INPUT" == "exit" ]] || [[ "$USER_INPUT" == "quit" ]]; then
        echo "Goodbye!"
        break
    fi
    
    if [[ -z "$USER_INPUT" ]]; then
        continue
    fi
    
    echo -n "DeepSeek: "
    
    # Send request to API and extract response
    curl -s "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"messages\": [
                {\"role\": \"user\", \"content\": \"$USER_INPUT\"}
            ],
            \"temperature\": 0.7,
            \"max_tokens\": 500,
            \"stream\": false
        }" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null || echo "Error: Could not connect to server"
    
    echo ""
done
