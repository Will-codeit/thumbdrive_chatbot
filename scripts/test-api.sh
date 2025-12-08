#!/bin/bash

# API test script to verify the server is working

PORT=8080
API_URL="http://localhost:$PORT/v1/chat/completions"

echo "════════════════════════════════════════════════════════"
echo "  🧪 DeepSeek-V3 API Test"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Testing connection to: $API_URL"
echo ""

# Test request
echo "Sending test prompt: 'Write a hello world in Python'"
echo ""

RESPONSE=$(curl -s "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "messages": [
            {"role": "user", "content": "Write a hello world in Python"}
        ],
        "temperature": 0.7,
        "max_tokens": 200,
        "stream": false
    }')

if [ $? -eq 0 ]; then
    echo "✅ Server is responding!"
    echo ""
    echo "Response:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
    echo "❌ Failed to connect to server"
    echo "Make sure the server is running with: ./run.sh"
fi

echo ""
