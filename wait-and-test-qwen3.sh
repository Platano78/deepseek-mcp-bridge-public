#!/bin/bash

# Wait for Qwen3-Coder-30B-A3B-Instruct-FP8 to load and test
# This script monitors the deployment and runs tests once ready

set -e

# Configuration
HEALTH_ENDPOINT="http://localhost:8001/health"
MAX_WAIT_TIME=3600  # 1 hour for model loading
CHECK_INTERVAL=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for service to be healthy
wait_for_health() {
    log "Waiting for Qwen3-Coder-30B-A3B-Instruct-FP8 to load..."
    local wait_time=0

    while [ $wait_time -lt $MAX_WAIT_TIME ]; do
        if curl -f -s "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
            success "Model is loaded and healthy!"
            return 0
        fi

        log "Model still loading... (${wait_time}s/${MAX_WAIT_TIME}s)"

        # Show some progress info
        if [ $((wait_time % 120)) -eq 0 ]; then
            log "Checking container status..."
            docker-compose -f docker-compose.qwen3-coder-30b-fp8.yml ps

            log "Recent logs:"
            docker logs qwen3-coder-30b-fp8 --tail=5 2>&1 | grep -E "(INFO|WARN|ERROR)" | tail -3
        fi

        sleep $CHECK_INTERVAL
        wait_time=$((wait_time + CHECK_INTERVAL))
    done

    error "Model failed to load within ${MAX_WAIT_TIME} seconds"
    return 1
}

# Run comprehensive tests
run_tests() {
    log "Running comprehensive test suite..."

    if node test-qwen3-coder-30b-fp8.js; then
        success "All tests passed! Qwen3-Coder-30B-A3B-Instruct-FP8 is ready for production use."
        return 0
    else
        error "Some tests failed. Check the logs above."
        return 1
    fi
}

# Show final deployment status
show_final_status() {
    log "Deployment Status Summary:"
    echo "=========================================="
    echo "Model: Qwen3-Coder-30B-A3B-Instruct-FP8"
    echo "Endpoint: http://localhost:8001"
    echo "Health: $HEALTH_ENDPOINT"
    echo "Models: http://localhost:8001/v1/models"
    echo "Chat: http://localhost:8001/v1/chat/completions"
    echo "Completions: http://localhost:8001/v1/completions"
    echo "=========================================="
    echo "Ready for MKG server integration!"
}

# Main function
main() {
    log "Starting Qwen3-Coder-30B-A3B-Instruct-FP8 monitoring and testing..."

    if wait_for_health; then
        if run_tests; then
            show_final_status
            success "Deployment completed successfully!"
            exit 0
        else
            error "Tests failed"
            exit 1
        fi
    else
        error "Health check failed"
        exit 1
    fi
}

# Handle script arguments
case "${1:-monitor}" in
    "monitor")
        main
        ;;
    "test-only")
        if curl -f -s "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
            run_tests
        else
            error "Model is not healthy. Cannot run tests."
            exit 1
        fi
        ;;
    "status")
        if curl -f -s "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
            success "Model is healthy and ready"
            show_final_status
        else
            warning "Model is not yet ready"
            docker-compose -f docker-compose.qwen3-coder-30b-fp8.yml ps
        fi
        ;;
    *)
        echo "Usage: $0 [monitor|test-only|status]"
        echo "  monitor   - Wait for model to load and run tests (default)"
        echo "  test-only - Run tests only if model is ready"
        echo "  status    - Show current status"
        exit 1
        ;;
esac