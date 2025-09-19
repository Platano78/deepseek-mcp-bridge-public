# PRIVATE-SETUP.md

# MKG (Mecha King Ghidorah) Server v8.0.0 - Private Team Setup

## 🚀 Complete Working Setup with Real Configurations

### Production Environment Configuration

**Current Production Server**: `server-mecha-king-ghidorah-simplified.js`
- **Version**: v8.0.0 Enhanced
- **Performance**: <5s startup, <2s FIM responses, <100ms routing decisions
- **Local Model**: Qwen3-Coder-30B-A3B-Instruct-FP8 on port 8001
- **NVIDIA Cloud**: DeepSeek V3.1 + Qwen 3 Coder 480B integration

## 🔧 Prerequisites

### Hardware Requirements
- **GPU**: NVIDIA RTX 5080 16GB VRAM (or equivalent)
- **RAM**: 32GB+ recommended for optimal performance
- **Storage**: 100GB+ for model cache
- **Network**: Stable internet for NVIDIA cloud fallback

### Software Dependencies
```bash
# Node.js 18+ with ES modules support
node --version  # Ensure >=18.0.0

# Docker for local model container
docker --version
docker-compose --version

# NVIDIA Container Toolkit (for GPU support)
nvidia-smi  # Verify GPU access
```

## 🛠️ Step-by-Step Setup

### 1. Environment Configuration

Create `.env` file with working API keys:
```bash
# NVIDIA API Integration (WORKING KEY)
NVIDIA_API_KEY="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"

# Optional: Additional cloud providers
DEEPSEEK_API_KEY="your-deepseek-key-here"
QWEN_CLOUD_API_KEY="your-qwen-cloud-key-here"
OPENAI_API_KEY="your-openai-key-here"

# Local model configuration
MKG_SERVER_PORT="8001"
DEEPSEEK_ENDPOINT="http://172.23.16.1:8001/v1"
VALIDATION_ENABLED="true"
NODE_ENV="production"
```

### 2. Local Model Container Setup

#### Option A: Qwen3-Coder-30B-FP8 (Recommended)
```bash
# Start the primary model container
docker-compose -f docker-compose.qwen3-coder-30b-fp8.yml up -d

# Verify container health
docker logs qwen3-coder-30b-fp8 -f

# Check model endpoint
curl http://localhost:8001/health
curl http://localhost:8001/v1/models
```

#### Option B: Alternative Models
```bash
# Qwen2.5-Coder-7B (lighter resource usage)
docker-compose -f docker-compose.qwen2.5-coder-7b-8001.yml up -d

# Yarn-128K Production (if available)
docker-compose -f docker-compose.yarn-128k-production.yml up -d
```

### 3. MKG Server Installation

```bash
# Install dependencies
npm install

# Verify MCP SDK version
npm list @modelcontextprotocol/sdk

# Run comprehensive health check
node test-mkg-server-connectivity.js
```

### 4. Claude Code Integration

#### Update Claude Desktop Configuration
Edit `~/.claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "mecha-king-ghidorah-global": {
      "command": "node",
      "args": [
        "/home/platano/project/deepseek-mcp-bridge/server-mecha-king-ghidorah-simplified.js"
      ],
      "cwd": "/home/platano/project/deepseek-mcp-bridge",
      "env": {
        "MCP_SERVER_NAME": "mecha-king-ghidorah-global",
        "NODE_ENV": "production",
        "NVIDIA_API_KEY": "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",
        "DEEPSEEK_API_KEY": "${DEEPSEEK_API_KEY}",
        "QWEN_CLOUD_API_KEY": "${QWEN_CLOUD_API_KEY}",
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "DEEPSEEK_ENDPOINT": "http://172.23.16.1:8001/v1",
        "MCP_SERVER_MODE": "true",
        "MKG_SERVER_PORT": "8001",
        "VALIDATION_ENABLED": "true"
      }
    }
  }
}
```

### 5. Verify Installation

```bash
# Test MCP compliance
node test-mcp-compliance.js

# Test all 10 tools
node test-all-tools.js

# Verify smart routing
node test-smart-routing-complete.js

# Test NVIDIA cloud integration
node test-nvidia-api-integration.js

# Comprehensive workflow test
node test-mgk-complete-workflow.js
```

## 🎯 Available Tools & Aliases

### Core Tools (10 Total)
1. **analyze** - Universal code analysis with AI-driven file type detection
2. **generate** - Smart code generation with FIM support
3. **review** - Comprehensive code review (security, performance, quality)
4. **edit_file** - Intelligent file editing with validation
5. **health** - System health and diagnostics
6. **read** - Enhanced file reading
7. **write_files_atomic** - Atomic file writing operations
8. **validate_changes** - Code change validation
9. **multi_edit** - Multi-file editing with parallel processing
10. **backup_restore** - Enterprise backup management

### MKG Aliases
- `MKG_analyze`, `MKG_generate`, `MKG_review`, `MKG_edit`, `MKG_health`

### DeepSeek Aliases
- `deepseek_analyze`, `deepseek_generate`, `deepseek_review`, `deepseek_edit`, `deepseek_health`

## ⚡ Smart Routing Configuration

### Routing Priority
1. **Local (Priority 1)**: Qwen3-Coder-30B-A3B-Instruct-FP8 (port 8001)
2. **NVIDIA DeepSeek (Priority 2)**: NVIDIA-DeepSeek-V3.1
3. **NVIDIA Qwen (Priority 3)**: NVIDIA-Qwen-3-Coder-480B

### Routing Logic
- **95% Local Processing**: Most requests handled locally for speed
- **5% Cloud Escalation**: Complex tasks routed to NVIDIA cloud
- **<100ms Routing Decisions**: AI-driven complexity analysis
- **Automatic Failover**: Seamless endpoint switching on failures

### Complexity Thresholds
```javascript
simple: 500 tokens    → Local processing
medium: 2000 tokens   → Local with cloud consideration
complex: 8000 tokens  → Cloud escalation preferred
```

## 🏥 Health Monitoring

### Real-time Health Check
```bash
# Test all endpoints
curl -X POST http://localhost:3000/mcp/call_tool \
  -H "Content-Type: application/json" \
  -d '{"name": "health", "arguments": {"check_type": "comprehensive"}}'
```

### Expected Health Response
```json
{
  "endpoints": {
    "local": {
      "status": "healthy",
      "model": "Qwen3-Coder-30B-A3B-Instruct-FP8",
      "responseTime": "45.23ms",
      "priority": 1
    },
    "nvidiaDeepSeek": {
      "status": "healthy",
      "model": "NVIDIA-DeepSeek-V3.1",
      "responseTime": "156.78ms",
      "priority": 2
    }
  },
  "routing": {
    "localProcessing": "95%",
    "cloudEscalation": "5%",
    "totalRequests": 1247,
    "successRate": "99.2%"
  }
}
```

## 🔒 Security Configuration

### API Key Security
- NVIDIA API key hardcoded for team use (working key provided)
- Other cloud provider keys optional (use environment variables)
- Local model requires no authentication

### Network Security
- Local model bound to localhost:8001
- NVIDIA cloud uses HTTPS with Bearer token authentication
- Health checks validate endpoints before use

## 🚀 Production Deployment

### Startup Command
```bash
# Production startup
node server-mecha-king-ghidorah-simplified.js

# Alternative with PM2 for process management
pm2 start server-mecha-king-ghidorah-simplified.js --name "mkg-server"
```

### Performance Monitoring
```bash
# Monitor container resources
docker stats qwen3-coder-30b-fp8

# Check MKG server logs
tail -f logs/mkg-server.log

# Performance validation
node test-mkg-performance-testing.js
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Local Model Container Issues
```bash
# Check container status
docker ps | grep qwen3-coder

# Restart container
docker-compose -f docker-compose.qwen3-coder-30b-fp8.yml restart

# Check GPU access
nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

#### 2. NVIDIA API Issues
```bash
# Test NVIDIA API key
curl -H "Authorization: Bearer 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" \
     https://integrate.api.nvidia.com/v1/models

# Verify quota and limits
node test-nvidia-api-integration.js
```

#### 3. MCP Integration Issues
```bash
# Validate MCP compliance
node test-mcp-compliance.js

# Test Claude Desktop configuration
node test-claude-desktop-config.js

# Check tool registration
node test-claude-desktop-integration.js
```

### Performance Optimization

#### GPU Memory Management
```bash
# Monitor GPU memory usage
watch -n 1 nvidia-smi

# Adjust GPU memory utilization in docker-compose
# Change --gpu-memory-utilization from 0.85 to 0.75 if needed
```

#### Cache Optimization
- FIM cache: 15-minute timeout, automatic cleanup
- Health check cache: 30-second intervals
- Response cache: MD5 key generation for efficiency

## 📊 Team Usage Patterns

### Recommended Workflows

#### 1. Code Analysis
```javascript
// Use analyze tool for comprehensive code review
await callTool('analyze', {
  content: fileContent,
  analysis_type: 'comprehensive',
  language: 'javascript'
});
```

#### 2. Code Generation
```javascript
// Use generate tool for FIM completion
await callTool('generate', {
  prefix: 'function calculateTax(',
  suffix: ') { return total; }',
  language: 'javascript'
});
```

#### 3. File Modifications
```javascript
// Use edit_file for intelligent editing
await callTool('edit_file', {
  file_path: '/path/to/file.js',
  edits: [{
    line_start: 10,
    line_end: 15,
    new_content: 'improved code here'
  }],
  validation_mode: 'comprehensive'
});
```

### Team Best Practices
1. **Use local-first routing** for development speed
2. **Monitor health endpoints** regularly
3. **Leverage alias tools** for consistency
4. **Use comprehensive analysis** for code reviews
5. **Enable validation** for all file modifications

## 🎯 Production Ready Features

✅ **<5 second startup** (MCP compliance)
✅ **<2 second FIM responses** with smart routing
✅ **<100ms routing decisions** with 95% local processing
✅ **<16ms response times** for cached requests
✅ **Parallel processing** for batch operations
✅ **Automatic backup** creation before modifications
✅ **Enterprise-grade** validation and rollback
✅ **Real-time health** monitoring with failover

**The enhanced monster rises - smarter, faster, more powerful!** 🦖