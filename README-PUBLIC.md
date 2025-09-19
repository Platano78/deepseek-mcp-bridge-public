# MKG (Mecha King Ghidorah) DeepSeek Bridge - Community Edition

[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**The Ultimate AI Coding Monster** - Smart AI routing system with configurable endpoints for local models, NVIDIA API, and DeepSeek API integration.

## 🚀 Quick Start

### 1. Choose Your Setup

**Option A: Local Model Setup (Recommended for Privacy)**
- Use any vLLM compatible model (DeepSeek, Qwen, CodeLlama, etc.)
- Run locally via LM Studio, Ollama, or direct vLLM
- No API keys required, unlimited usage

**Option B: NVIDIA API Integration (Recommended for Performance)**
- Access to Qwen 3 Coder 480B and DeepSeek V3
- Requires NVIDIA API key (get yours at [NVIDIA AI](https://build.nvidia.com))
- Professional-grade AI models

**Option C: DeepSeek API Integration (Recommended for Balance)**
- Official DeepSeek API access
- Requires DeepSeek API key
- Cost-effective solution

### 2. Installation

```bash
git clone https://github.com/Platano78/mkg-deepseek-bridge.git
cd mkg-deepseek-bridge
npm install
```

### 3. Configuration

#### For Local Model Setup:
```bash
cp .env.template.local .env
# Edit .env with your local model endpoint
```

#### For NVIDIA API:
```bash
cp .env.template.nvidia .env
# Edit .env and add your NVIDIA_API_KEY
```

#### For DeepSeek API:
```bash
cp .env.template.deepseek .env
# Edit .env and add your DEEPSEEK_API_KEY
```

### 4. Claude Desktop Integration

Copy the appropriate template:

**Local Model:**
```bash
cp claude-desktop-config.template.local.json ~/.config/claude-desktop/config.json
```

**NVIDIA API:**
```bash
cp claude-desktop-config.template.nvidia.json ~/.config/claude-desktop/config.json
```

**DeepSeek API:**
```bash
cp claude-desktop-config.template.deepseek.json ~/.config/claude-desktop/config.json
```

Update the `cwd` path in the config file to match your installation directory.

### 5. Start the Server

```bash
npm start
```

## 🎯 Available Tools

### `query_ai` - Smart AI Query with Routing
Query AI with automatic routing to the optimal endpoint based on task type.

**Parameters:**
- `prompt` (required): Your question or request
- `task_type` (optional): `coding`, `debugging`, `analysis`, `architecture`, `unlimited`, `general`
- `force_endpoint` (optional): Force specific endpoint
- `context` (optional): Additional context
- `max_tokens` (optional): Response length limit

**Examples:**
```javascript
// Automatic routing based on content
@query_ai(prompt="Implement a REST API with authentication")

// Specify task type for optimal routing
@query_ai(prompt="Review this code for security issues", task_type="analysis")

// Force specific endpoint
@query_ai(prompt="Analyze large codebase", force_endpoint="local")
```

### `check_status` - Health Check
Monitor the status of all configured endpoints.

### `read_file` - Safe File Reading
Read file contents with validation and security checks.

### `write_file` - Protected File Writing
Write files with automatic backup creation.

## 🔧 Configuration Options

### Smart Routing Behavior

The system automatically routes requests based on:

1. **Task Type Recognition**:
   - `coding`, `debugging` → Best coding-optimized endpoint
   - `analysis`, `research` → Best reasoning-optimized endpoint
   - `unlimited`, `large_context` → Local endpoint (no limits)

2. **Content Analysis**:
   - Coding patterns → Coding-specialized models
   - Analysis patterns → Reasoning-specialized models
   - Large prompts (>50KB) → Local unlimited endpoint

3. **Endpoint Priority**:
   - Priority 1: Specialized coding models (e.g., Qwen 3 Coder)
   - Priority 2: Reasoning models (e.g., DeepSeek V3)
   - Priority 3: Local models (unlimited capacity)

### Environment Variables

#### Required for Each Setup:

**Local Model:**
```bash
DEEPSEEK_ENDPOINT=http://localhost:1234/v1
DEEPSEEK_MODEL=your-model-name
```

**NVIDIA API:**
```bash
NVIDIA_API_KEY=your_nvidia_api_key
NVIDIA_QWEN_MODEL=qwen/qwen3-coder-480b-a35b-instruct
NVIDIA_DEEPSEEK_MODEL=deepseek-ai/deepseek-v3.1
```

**DeepSeek API:**
```bash
DEEPSEEK_API_KEY=your_deepseek_api_key
DEEPSEEK_MODEL=deepseek-coder
```

#### Optional Settings:
```bash
PORT=3000
MAX_CONCURRENT_REQUESTS=10
REQUEST_TIMEOUT=30000
ENABLE_CACHING=true
ENABLE_REQUEST_LOGGING=true
```

## 🏗️ Local Model Setup Guide

### Option 1: LM Studio (Easiest)
1. Download [LM Studio](https://lmstudio.ai/)
2. Download a DeepSeek Coder model (recommended: `deepseek-coder-v2-lite-instruct`)
3. Start local server on port 1234
4. Set `DEEPSEEK_ENDPOINT=http://localhost:1234/v1`

### Option 2: Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull DeepSeek model
ollama pull deepseek-coder:6.7b

# Start server
ollama serve
```

### Option 3: Direct vLLM
```bash
# Install vLLM
pip install vllm

# Start server with DeepSeek model
python -m vllm.entrypoints.openai.api_server \
  --model deepseek-ai/deepseek-coder-6.7b-instruct \
  --host 0.0.0.0 \
  --port 1234
```

## 🔑 API Key Setup

### NVIDIA API Key
1. Visit [NVIDIA AI](https://build.nvidia.com)
2. Create account and navigate to API keys
3. Generate new API key
4. Add to `.env` as `NVIDIA_API_KEY=nvapi-...`

### DeepSeek API Key
1. Visit [DeepSeek Platform](https://platform.deepseek.com)
2. Create account and get API key
3. Add to `.env` as `DEEPSEEK_API_KEY=sk-...`

## 🎮 Usage Examples

### Coding Tasks
```javascript
// Smart routing will select best coding model
@query_ai(
  prompt="Create a React component for user authentication",
  task_type="coding"
)
```

### Code Analysis
```javascript
// Routes to analysis-optimized model
@query_ai(
  prompt="Review this code for performance bottlenecks: [code]",
  task_type="analysis"
)
```

### Large Context Processing
```javascript
// Automatically routes to local model for unlimited processing
@query_ai(
  prompt="Analyze this entire codebase: [large files]",
  task_type="unlimited"
)
```

### Endpoint Comparison
```javascript
// Test different models on same task
@query_ai(prompt="Explain async/await", force_endpoint="nvidia_qwen")
@query_ai(prompt="Explain async/await", force_endpoint="local")
```

## 🛠️ Extending the System

### Adding New Providers

The system is designed for easy extension. To add a new AI provider:

1. **Add endpoint configuration** in `SmartAIRouter.setupEndpoints()`
2. **Configure authentication** in `AIQueryHandler.makeRequest()`
3. **Define specializations** for smart routing
4. **Add environment variables** for configuration

### Custom Routing Logic

Modify `SmartAIRouter.analyzePrompt()` to add custom routing patterns:

```javascript
// Example: Route database queries to specialized model
const databasePatterns = /\\b(SQL|database|query|schema)\\b/i;
if (databasePatterns.test(prompt)) {
  category = 'database';
}
```

## 🔒 Security Features

- **Path validation** - Prevents directory traversal attacks
- **Input sanitization** - Validates all API inputs
- **Automatic backups** - Creates backups before file modifications
- **Configurable CORS** - Secure cross-origin policies
- **Rate limiting** - Prevents abuse and overuse

## 🚨 Troubleshooting

### Common Issues

**"No available endpoints configured"**
- Check your `.env` file configuration
- Ensure at least one endpoint is properly configured
- Verify API keys are valid (if using cloud APIs)

**Local model connection failed**
- Verify local model server is running
- Check endpoint URL and port
- Test with `curl http://localhost:1234/v1/models`

**NVIDIA API authentication failed**
- Verify API key is correct and active
- Check API key permissions
- Ensure you have sufficient credits

### Health Check
```javascript
@check_status()
```

This will show the status of all configured endpoints and help identify issues.

## 📚 Documentation

- [Setup Guide](docs/setup-guide.md) - Detailed setup instructions
- [Configuration Reference](docs/configuration.md) - All configuration options
- [API Reference](docs/api-reference.md) - Complete tool documentation
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/Platano78/mkg-deepseek-bridge.git
cd mkg-deepseek-bridge
npm install
npm run test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/Platano78/mkg-deepseek-bridge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Platano78/mkg-deepseek-bridge/discussions)
- **Documentation**: [Wiki](https://github.com/Platano78/mkg-deepseek-bridge/wiki)

---

**Built with ❤️ for the AI development community**