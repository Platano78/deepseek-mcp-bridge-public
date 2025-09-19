# CONFIGURATION.md

# MKG Server v8.0.0 - Configuration Guide

## 🔧 Complete Configuration Reference

### Environment Variables

#### Core Configuration
```bash
# Server Mode
NODE_ENV=production
MCP_SERVER_MODE=true
MCP_SERVER_NAME=mkg-server

# Local Model Configuration
MKG_SERVER_PORT=8001
DEEPSEEK_ENDPOINT=http://localhost:8001/v1
VALIDATION_ENABLED=true

# Cloud Provider API Keys
NVIDIA_API_KEY=your-nvidia-api-key-here
DEEPSEEK_API_KEY=your-deepseek-api-key-here
QWEN_CLOUD_API_KEY=your-qwen-cloud-api-key-here
OPENAI_API_KEY=your-openai-api-key-here

# Performance Tuning
MAX_CONCURRENT_REQUESTS=10
CACHE_TTL=900
HEALTH_CHECK_INTERVAL=30
ROUTING_TIMEOUT=100
FIM_CACHE_TTL=900

# Logging and Monitoring
LOG_LEVEL=info
METRICS_ENABLED=true
DEBUG=false

# Security
CORS_ENABLED=false
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=100
```

#### Advanced Configuration
```bash
# Smart Routing
LOCAL_FIRST_THRESHOLD=0.95
COMPLEXITY_THRESHOLD_SIMPLE=500
COMPLEXITY_THRESHOLD_MEDIUM=2000
COMPLEXITY_THRESHOLD_COMPLEX=8000

# Memory Management
NODE_OPTIONS="--max-old-space-size=4096"
UV_THREADPOOL_SIZE=8
CACHE_SIZE_MB=256

# File Operations
MAX_FILE_SIZE=50
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=7
TEMP_DIR=/tmp

# Endpoint Health
HEALTH_CHECK_TIMEOUT=5000
ENDPOINT_RETRY_COUNT=3
FAILOVER_TIMEOUT=1000
```

## 🚀 Smart Routing Configuration

### Routing Priority Setup
```javascript
// Default endpoint configuration
const endpoints = {
  local: {
    name: 'Qwen3-Coder-30B-A3B-Instruct-FP8',
    url: 'http://localhost:8001/v1/chat/completions',
    healthUrl: 'http://localhost:8001/health',
    maxTokens: 131072,
    priority: 1
  },
  nvidiaDeepSeek: {
    name: 'NVIDIA-DeepSeek-V3.1',
    url: 'https://integrate.api.nvidia.com/v1/chat/completions',
    maxTokens: 65536,
    priority: 2
  },
  nvidiaQwen: {
    name: 'NVIDIA-Qwen-3-Coder-480B',
    url: 'https://integrate.api.nvidia.com/v1/chat/completions',
    maxTokens: 32768,
    priority: 3
  }
};
```

### Complexity-Based Routing
```bash
# Routing thresholds (in tokens)
SIMPLE_TASK_THRESHOLD=500      # Local processing preferred
MEDIUM_TASK_THRESHOLD=2000     # Smart routing decision
COMPLEX_TASK_THRESHOLD=8000    # Cloud escalation considered

# Local processing percentage
LOCAL_FIRST_THRESHOLD=0.95     # 95% local, 5% cloud
```

### Custom Routing Rules
```javascript
// Pattern-based routing
const routingPatterns = {
  coding: {
    patterns: ['function', 'class', 'debug', 'implement'],
    preferredEndpoint: 'local'
  },
  analysis: {
    patterns: ['analyze', 'review', 'security', 'performance'],
    preferredEndpoint: 'nvidiaDeepSeek'
  },
  generation: {
    patterns: ['generate', 'create', 'scaffold'],
    preferredEndpoint: 'nvidiaQwen'
  }
};
```

## 🐳 Local Model Configuration

### Docker Compose Options

#### Option 1: Qwen3-Coder-30B-FP8 (Recommended)
```yaml
# docker-compose.qwen3-coder-30b-fp8.yml
version: '3.8'

services:
  qwen3-coder-30b-fp8:
    image: vllm/vllm-openai:latest
    container_name: qwen3-coder-30b-fp8
    ports:
      - "8001:8000"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - CUDA_VISIBLE_DEVICES=0
    volumes:
      - model_cache:/root/.cache/huggingface
      - ./logs:/app/logs
    command: [
      "--model", "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8",
      "--host", "0.0.0.0",
      "--port", "8000",
      "--served-model-name", "qwen3-coder-30b-fp8",
      "--max-model-len", "32768",
      "--gpu-memory-utilization", "0.85",
      "--tensor-parallel-size", "1",
      "--dtype", "auto",
      "--quantization", "fp8",
      "--enable-lora",
      "--max-loras", "4",
      "--trust-remote-code",
      "--disable-log-stats",
      "--api-key", "your-api-key-here"
    ]
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 300s

volumes:
  model_cache:
    driver: local
```

#### Option 2: Qwen2.5-Coder-7B (Lighter)
```yaml
# docker-compose.qwen2.5-coder-7b-8001.yml
version: '3.8'

services:
  qwen25-coder-7b:
    image: vllm/vllm-openai:latest
    container_name: qwen25-coder-7b
    ports:
      - "8001:8000"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    command: [
      "--model", "Qwen/Qwen2.5-Coder-7B-Instruct",
      "--host", "0.0.0.0",
      "--port", "8000",
      "--max-model-len", "32768",
      "--gpu-memory-utilization", "0.70",
      "--trust-remote-code"
    ]
    restart: unless-stopped
```

#### Option 3: Custom Model
```yaml
# Custom configuration template
services:
  custom-model:
    image: vllm/vllm-openai:latest
    container_name: your-custom-model
    ports:
      - "8001:8000"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    command: [
      "--model", "your-model-name",
      "--host", "0.0.0.0",
      "--port", "8000",
      "--max-model-len", "your-context-length",
      "--gpu-memory-utilization", "0.85",
      "--trust-remote-code"
    ]
```

### Local Model Startup
```bash
# Start recommended model
docker-compose -f docker-compose.qwen3-coder-30b-fp8.yml up -d

# Check status
docker ps | grep qwen3-coder
docker logs qwen3-coder-30b-fp8 -f

# Test endpoint
curl http://localhost:8001/health
curl http://localhost:8001/v1/models
```

## ☁️ Cloud Provider Configuration

### NVIDIA Cloud Setup
```bash
# Get API key from NVIDIA
# Visit: https://build.nvidia.com/
# Sign up and obtain API key

# Set environment variable
export NVIDIA_API_KEY="your-nvidia-api-key"

# Test connectivity
curl -H "Authorization: Bearer $NVIDIA_API_KEY" \
     https://integrate.api.nvidia.com/v1/models
```

#### Available NVIDIA Models
```javascript
const nvidiaModels = {
  deepseek: {
    name: 'deepseek-ai/deepseek-v3.1',
    maxTokens: 65536,
    strengths: ['reasoning', 'analysis', 'complex-problems']
  },
  qwen: {
    name: 'qwen/qwen3-coder-480b-a35b-instruct',
    maxTokens: 32768,
    strengths: ['coding', 'implementation', 'debugging']
  }
};
```

### DeepSeek Cloud Setup (Optional)
```bash
# Get API key from DeepSeek
# Visit: https://platform.deepseek.com/
export DEEPSEEK_API_KEY="your-deepseek-api-key"

# Test connectivity
curl -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
     https://api.deepseek.com/v1/models
```

### OpenAI Setup (Optional Fallback)
```bash
# Standard OpenAI configuration
export OPENAI_API_KEY="your-openai-api-key"

# Test connectivity
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models
```

## 🔧 MCP Integration Configuration

### Claude Desktop Configuration

#### Basic Configuration
```json
{
  "mcpServers": {
    "mkg-server": {
      "command": "node",
      "args": ["server-mecha-king-ghidorah-simplified.js"],
      "cwd": "/path/to/mkg-server",
      "env": {
        "MCP_SERVER_MODE": "true",
        "NODE_ENV": "production"
      }
    }
  }
}
```

#### Full Production Configuration
```json
{
  "mcpServers": {
    "mecha-king-ghidorah-global": {
      "command": "node",
      "args": [
        "/path/to/server-mecha-king-ghidorah-simplified.js"
      ],
      "cwd": "/path/to/mkg-server",
      "env": {
        "MCP_SERVER_NAME": "mecha-king-ghidorah-global",
        "NODE_ENV": "production",
        "NVIDIA_API_KEY": "your-nvidia-api-key",
        "DEEPSEEK_API_KEY": "${DEEPSEEK_API_KEY}",
        "QWEN_CLOUD_API_KEY": "${QWEN_CLOUD_API_KEY}",
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "DEEPSEEK_ENDPOINT": "http://localhost:8001/v1",
        "MCP_SERVER_MODE": "true",
        "MKG_SERVER_PORT": "8001",
        "VALIDATION_ENABLED": "true",
        "MAX_CONCURRENT_REQUESTS": "10",
        "CACHE_TTL": "900"
      }
    }
  }
}
```

#### Development Configuration
```json
{
  "mcpServers": {
    "mkg-dev": {
      "command": "node",
      "args": ["server-mecha-king-ghidorah-simplified.js"],
      "cwd": "/path/to/mkg-server",
      "env": {
        "NODE_ENV": "development",
        "DEBUG": "true",
        "LOG_LEVEL": "debug",
        "MCP_SERVER_MODE": "true"
      }
    }
  }
}
```

### Environment Variable Management

#### Method 1: System Environment
```bash
# Add to ~/.bashrc or ~/.profile
export NVIDIA_API_KEY="your-api-key"
export MKG_SERVER_PORT="8001"
export VALIDATION_ENABLED="true"

# Reload
source ~/.bashrc
```

#### Method 2: .env File
```bash
# Create .env file in project root
cat > .env << 'EOF'
NVIDIA_API_KEY=your-nvidia-api-key
DEEPSEEK_ENDPOINT=http://localhost:8001/v1
MKG_SERVER_PORT=8001
NODE_ENV=production
MCP_SERVER_MODE=true
VALIDATION_ENABLED=true
MAX_CONCURRENT_REQUESTS=10
CACHE_TTL=900
EOF

# Secure the file
chmod 600 .env
```

#### Method 3: Docker Environment
```yaml
# In docker-compose.yml
services:
  mkg-server:
    build: .
    environment:
      - NVIDIA_API_KEY=${NVIDIA_API_KEY}
      - NODE_ENV=production
      - MCP_SERVER_MODE=true
    env_file:
      - .env
```

## ⚡ Performance Configuration

### Memory Optimization
```bash
# Node.js memory settings
NODE_OPTIONS="--max-old-space-size=4096 --optimize-for-size"

# Thread pool size
UV_THREADPOOL_SIZE=8

# V8 optimization flags
NODE_OPTIONS="$NODE_OPTIONS --max-semi-space-size=128"
```

### Caching Configuration
```javascript
// Cache settings
const cacheConfig = {
  fim: {
    ttl: 900,        // 15 minutes
    maxSize: 1000,   // Max cache entries
    keyLength: 50    // Cache key truncation
  },
  health: {
    ttl: 30,         // 30 seconds
    maxSize: 100
  },
  routing: {
    ttl: 300,        // 5 minutes
    maxSize: 500
  }
};
```

### Concurrent Processing
```bash
# Request concurrency
MAX_CONCURRENT_REQUESTS=10

# File processing concurrency
MAX_CONCURRENT_FILES=5

# Batch processing
BATCH_SIZE=50
BATCH_TIMEOUT=5000
```

## 🛡️ Security Configuration

### File Operation Security
```bash
# File size limits (MB)
MAX_FILE_SIZE=50

# Path validation
ALLOW_ABSOLUTE_PATHS=false
BLOCK_PARENT_TRAVERSAL=true

# Backup settings
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=7
BACKUP_DIR=./backups
```

### API Security
```bash
# Rate limiting
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=100
RATE_LIMIT_WINDOW=60000

# CORS settings
CORS_ENABLED=false
ALLOWED_ORIGINS=""

# Input validation
VALIDATE_INPUTS=true
SANITIZE_OUTPUTS=true
```

### Access Control
```bash
# File permissions
FILE_READ_PERMISSIONS=0644
FILE_WRITE_PERMISSIONS=0644
DIRECTORY_PERMISSIONS=0755

# Process security
RUN_AS_USER=mkg-server
CHROOT_ENABLED=false
```

## 📊 Monitoring Configuration

### Health Check Settings
```bash
# Health check intervals
HEALTH_CHECK_INTERVAL=30
HEALTH_CHECK_TIMEOUT=5000
ENDPOINT_RETRY_COUNT=3

# Health check endpoints
LOCAL_HEALTH_URL=http://localhost:8001/health
NVIDIA_HEALTH_URL=https://integrate.api.nvidia.com/v1/models
```

### Metrics Collection
```bash
# Metrics settings
METRICS_ENABLED=true
METRICS_INTERVAL=60
METRICS_RETENTION_HOURS=24

# Performance monitoring
TRACK_RESPONSE_TIMES=true
TRACK_ERROR_RATES=true
TRACK_ROUTING_DECISIONS=true
```

### Logging Configuration
```bash
# Log levels: error, warn, info, debug
LOG_LEVEL=info

# Log destinations
LOG_TO_FILE=true
LOG_TO_CONSOLE=true
LOG_FILE=./logs/mkg-server.log

# Log rotation
LOG_MAX_SIZE=100MB
LOG_MAX_FILES=5
LOG_DATE_PATTERN=YYYY-MM-DD
```

## 🔧 Platform-Specific Configuration

### Windows Configuration
```bash
# WSL2 endpoint (if using WSL2)
DEEPSEEK_ENDPOINT=http://172.23.16.1:8001/v1

# Windows paths
USE_WINDOWS_PATHS=true
PATH_SEPARATOR=\\

# PowerShell environment
$env:NVIDIA_API_KEY="your-api-key"
$env:NODE_ENV="production"
```

### Linux Configuration
```bash
# Standard localhost
DEEPSEEK_ENDPOINT=http://localhost:8001/v1

# System service configuration
SYSTEMD_SERVICE=true
SERVICE_USER=mkg-server
SERVICE_GROUP=mkg-server

# File permissions
umask 022
```

### macOS Configuration
```bash
# Standard configuration
DEEPSEEK_ENDPOINT=http://localhost:8001/v1

# Homebrew Node.js
NODE_PATH=/opt/homebrew/bin/node

# macOS security
ALLOW_UNSIGNED_EXTENSIONS=false
```

## 🚀 Deployment Configurations

### Development Environment
```bash
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
CACHE_TTL=60
HEALTH_CHECK_INTERVAL=10
VALIDATION_ENABLED=false
```

### Staging Environment
```bash
NODE_ENV=staging
DEBUG=false
LOG_LEVEL=info
CACHE_TTL=300
HEALTH_CHECK_INTERVAL=30
VALIDATION_ENABLED=true
RATE_LIMIT_ENABLED=false
```

### Production Environment
```bash
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warn
CACHE_TTL=900
HEALTH_CHECK_INTERVAL=30
VALIDATION_ENABLED=true
RATE_LIMIT_ENABLED=true
METRICS_ENABLED=true
BACKUP_ENABLED=true
```

## 📋 Configuration Validation

### Validation Script
```javascript
#!/usr/bin/env node
import fs from 'fs';

const validateConfig = () => {
  console.log('🔍 Validating MKG Server Configuration...\n');

  // Check required environment variables
  const required = [
    'NODE_ENV',
    'MCP_SERVER_MODE'
  ];

  const optional = [
    'NVIDIA_API_KEY',
    'DEEPSEEK_ENDPOINT',
    'MKG_SERVER_PORT'
  ];

  // Validate required
  for (const env of required) {
    if (process.env[env]) {
      console.log(`✅ ${env}: ${process.env[env]}`);
    } else {
      console.log(`❌ ${env}: Missing (required)`);
    }
  }

  // Validate optional
  for (const env of optional) {
    if (process.env[env]) {
      console.log(`✅ ${env}: Configured`);
    } else {
      console.log(`⚠️ ${env}: Not configured (optional)`);
    }
  }

  console.log('\n🎯 Configuration validation complete!');
};

validateConfig();
```

### Configuration Test
```bash
# Run validation
node validate-config.js

# Test with sample configuration
npm run test:config

# Verify MCP integration
npm run test:mcp
```

This comprehensive configuration guide covers all aspects of setting up and tuning the MKG Server v8.0.0 for optimal performance and security.