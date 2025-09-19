#!/bin/bash

# Script to enable Docker access in WSL2 after Docker Desktop integration is set up

echo "=== Docker WSL2 Integration Setup ==="
echo

# Check if Docker Desktop is running
echo "🔍 Checking Docker Desktop status..."

# Try to access Docker through Windows path
if /mnt/c/Program\ Files/Docker/Docker/resources/bin/docker.exe ps >/dev/null 2>&1; then
    echo "✅ Docker Desktop is running on Windows"
else
    echo "❌ Docker Desktop is not running or not accessible"
    echo "   Please start Docker Desktop on Windows first"
    exit 1
fi

# Check current WSL integration
echo "🔍 Checking WSL2 Docker integration..."

if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is accessible in WSL2"
    docker --version
    echo
    echo "🚀 Ready to start containers! Run:"
    echo "   ./start-qwen25-coder-7b-8001.sh"
else
    echo "❌ Docker WSL2 integration not enabled"
    echo
    echo "🔧 Please enable WSL2 integration in Docker Desktop:"
    echo "   1. Open Docker Desktop on Windows"
    echo "   2. Go to Settings → Resources → WSL Integration"
    echo "   3. Enable 'Enable integration with my default WSL distro'"
    echo "   4. Enable integration for this WSL distribution"
    echo "   5. Click 'Apply & Restart'"
    echo
    echo "🔄 Alternative: Create temporary alias for this session:"
    echo "   alias docker='/mnt/c/Program\ Files/Docker/Docker/resources/bin/docker.exe'"
    echo "   alias docker-compose='/mnt/c/Program\ Files/Docker/Docker/resources/bin/docker-compose.exe'"
fi

echo
echo "=== Manual Docker Commands (if integration not working) ==="
echo "Docker:         /mnt/c/Program\ Files/Docker/Docker/resources/bin/docker.exe"
echo "Docker Compose: /mnt/c/Program\ Files/Docker/Docker/resources/bin/docker-compose.exe"