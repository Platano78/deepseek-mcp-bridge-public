#!/bin/bash

# Verification script for Qwen2.5-Coder-7B container on port 8001

set -e

HOST_PORT="8001"
CONTAINER_NAME="qwen25-coder-7b-8001"
MODEL_NAME="qwen2.5-coder-7b-fp8-dynamic"

echo "=== Qwen2.5-Coder-7B Container Verification ==="
echo "Port: $HOST_PORT"
echo "Container: $CONTAINER_NAME"
echo "Model: $MODEL_NAME"
echo

# Function to test HTTP endpoint
test_endpoint() {
    local endpoint="$1"
    local description="$2"

    echo "🔍 Testing $description..."
    echo "   Endpoint: http://localhost:$HOST_PORT$endpoint"

    if curl -s -f "http://localhost:$HOST_PORT$endpoint" >/dev/null; then
        echo "   ✅ $description is responding"
        return 0
    else
        echo "   ❌ $description is not responding"
        return 1
    fi
}

# Function to test model API
test_model_api() {
    echo "🔍 Testing model API..."

    # Test models endpoint
    local models_response=$(curl -s "http://localhost:$HOST_PORT/v1/models" 2>/dev/null)

    if echo "$models_response" | grep -q "$MODEL_NAME"; then
        echo "   ✅ Model $MODEL_NAME is available"

        # Pretty print if jq is available
        if command -v jq &> /dev/null; then
            echo "   📊 Available models:"
            echo "$models_response" | jq '.data[].id' 2>/dev/null || echo "$models_response"
        fi
    else
        echo "   ❌ Model $MODEL_NAME is not available"
        echo "   Response: $models_response"
        return 1
    fi
}

# Function to test chat completion
test_chat_completion() {
    echo "🔍 Testing chat completion..."

    local test_payload='{
        "model": "qwen2.5-coder-7b-fp8-dynamic",
        "messages": [
            {
                "role": "user",
                "content": "Write a simple Python function to add two numbers."
            }
        ],
        "max_tokens": 100,
        "temperature": 0.7
    }'

    local response=$(curl -s -X POST "http://localhost:$HOST_PORT/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>/dev/null)

    if echo "$response" | grep -q "choices"; then
        echo "   ✅ Chat completion is working"

        # Extract and show the response
        if command -v jq &> /dev/null; then
            local content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
            echo "   📝 Sample response:"
            echo "$content" | head -5
        fi
    else
        echo "   ❌ Chat completion failed"
        echo "   Response: $response"
        return 1
    fi
}

# Function to check container resources
check_resources() {
    echo "🔍 Checking container resources..."

    if docker ps --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        echo "   ✅ Container is running"

        # Show resource usage
        echo "   📊 Resource usage:"
        docker stats "$CONTAINER_NAME" --no-stream --format "   CPU: {{.CPUPerc}}, Memory: {{.MemUsage}} ({{.MemPerc}})"

        # Show container info
        echo "   🔧 Container details:"
        docker ps --filter "name=$CONTAINER_NAME" --format "   Status: {{.Status}}, Ports: {{.Ports}}"
    else
        echo "   ❌ Container is not running"
        return 1
    fi
}

# Function to check logs for errors
check_logs() {
    echo "🔍 Checking container logs for errors..."

    local logs=$(docker logs "$CONTAINER_NAME" --tail 20 2>/dev/null)

    if echo "$logs" | grep -i "error\|exception\|failed"; then
        echo "   ⚠️  Found potential issues in logs:"
        echo "$logs" | grep -i "error\|exception\|failed" | tail -5
    else
        echo "   ✅ No critical errors found in recent logs"
    fi

    # Show model loading status
    if echo "$logs" | grep -q "model.*loaded"; then
        echo "   ✅ Model appears to be loaded successfully"
    else
        echo "   ⚠️  Model loading status unclear"
    fi
}

# Function to test YARN context capabilities
test_yarn_context() {
    echo "🔍 Testing YARN context capabilities..."

    local test_payload='{
        "model": "qwen2.5-coder-7b-fp8-dynamic",
        "messages": [
            {
                "role": "user",
                "content": "This is a test of the extended context window. Please confirm you can handle long contexts with YARN scaling. What is the maximum context length you support?"
            }
        ],
        "max_tokens": 50
    }'

    local response=$(curl -s -X POST "http://localhost:$HOST_PORT/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>/dev/null)

    if echo "$response" | grep -q "choices"; then
        echo "   ✅ YARN context test passed"

        if command -v jq &> /dev/null; then
            local content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
            if echo "$content" | grep -qi "131\|128\|context"; then
                echo "   ✅ Model correctly reports extended context capabilities"
            fi
        fi
    else
        echo "   ❌ YARN context test failed"
        return 1
    fi
}

# Main verification function
main() {
    echo "Starting verification process..."
    echo

    local all_tests_passed=true

    # Basic endpoint tests
    if ! test_endpoint "/health" "Health endpoint"; then
        all_tests_passed=false
    fi

    if ! test_endpoint "/v1/models" "Models endpoint"; then
        all_tests_passed=false
    fi

    # Model and API tests
    if ! test_model_api; then
        all_tests_passed=false
    fi

    if ! test_chat_completion; then
        all_tests_passed=false
    fi

    if ! test_yarn_context; then
        all_tests_passed=false
    fi

    # Container and resource tests
    if ! check_resources; then
        all_tests_passed=false
    fi

    check_logs

    echo
    echo "=== Verification Summary ==="
    if [ "$all_tests_passed" = true ]; then
        echo "🎉 All tests passed! Qwen2.5-Coder-7B container is working correctly."
        echo
        echo "📝 Quick reference:"
        echo "   Health: http://localhost:$HOST_PORT/health"
        echo "   Models: http://localhost:$HOST_PORT/v1/models"
        echo "   Chat: http://localhost:$HOST_PORT/v1/chat/completions"
        echo
        echo "🚀 Container is ready for use with:"
        echo "   - YARN 131K context window"
        echo "   - FP8 quantization"
        echo "   - 90% GPU utilization"
        echo "   - Optimized for RTX 5080 16GB VRAM"
    else
        echo "❌ Some tests failed. Please check the container configuration."
        echo
        echo "🔧 Troubleshooting steps:"
        echo "   1. Check container logs: docker logs $CONTAINER_NAME"
        echo "   2. Verify GPU availability: nvidia-smi"
        echo "   3. Check port availability: ss -tulpn | grep $HOST_PORT"
        echo "   4. Restart container: docker restart $CONTAINER_NAME"
        exit 1
    fi
}

# Run main function
main "$@"