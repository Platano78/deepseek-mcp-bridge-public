# Smart MCP Bridge

**A flexible Model Context Protocol (MCP) bridge with intelligent routing between multiple AI providers.**

## 🌟 Features

- **Multi-Provider Support**: Connect to any combination of AI APIs (OpenAI, Anthropic, Google, DeepSeek, NVIDIA, etc.)
- **Smart Routing**: Automatically route requests to the most suitable AI provider based on content analysis
- **Local Model Support**: Optional integration with local models (Ollama, vLLM, etc.)
- **Enterprise-Ready**: Production-grade features including caching, rate limiting, and error handling
- **Easy Configuration**: Simple environment-based setup for any AI provider combination

## 🚀 Quick Start

### 1. Clone and Install

```bash
git clone https://github.com/your-username/smart-mcp-bridge.git
cd smart-mcp-bridge
npm install
```

### 2. Configure Your APIs

```bash
cp .env.template .env
# Edit .env with your preferred AI provider credentials
```

### 3. Choose Your AI Providers

Edit `.env` to configure any 2+ AI providers:

```bash
# Example: Using OpenAI + Anthropic
PRIMARY_API=openai
SECONDARY_API=anthropic

OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
```

### 4. Start the Bridge

```bash
npm start
```

## 🔧 Configuration Options

### Supported AI Providers

- **OpenAI**: GPT-4, GPT-3.5-turbo, and other OpenAI models
- **Anthropic**: Claude-3 family models
- **Google**: Gemini Pro and other Google AI models
- **DeepSeek**: DeepSeek Chat and Coder models
- **NVIDIA**: Models available through NVIDIA's API
- **Local Models**: Any OpenAI-compatible local server (Ollama, vLLM, etc.)

### Smart Routing Rules

The bridge automatically routes requests based on content analysis:

- **Analysis Tasks** → Secondary API (research, math, strategy)
- **Coding Tasks** → Primary API (development, debugging, implementation)
- **Large Content** → Local API (files >50KB, extensive context)

### Routing Patterns

Configure routing patterns in `.env`:

```bash
# Tasks routed to secondary API
ANALYSIS_PATTERNS=analyze,calculate,statistics,research,strategy

# Tasks routed to primary API
CODING_PATTERNS=function,class,debug,implement,code,api

# Content size threshold for local routing
LARGE_CONTENT_THRESHOLD=50000
```

## 📁 Project Structure

```
smart-mcp-bridge/
├── server.js              # Main server logic
├── src/                   # Core modules
│   ├── config.js         # Configuration management
│   ├── routing.js        # Smart routing logic
│   └── providers/        # AI provider integrations
├── .env.template         # Configuration template
├── package.json          # Dependencies
└── README.md            # This file
```

## 🔐 Environment Variables

### Required Settings

```bash
# Server Configuration
NODE_ENV=development
HOST=127.0.0.1
PORT=3000

# API Selection
PRIMARY_API=openai        # Your primary AI provider
SECONDARY_API=anthropic   # Your secondary AI provider

# API Keys (configure based on your chosen providers)
OPENAI_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
```

### Optional Settings

```bash
# Local Model Support
LOCAL_MODEL_ENABLED=false
LOCAL_MODEL_URL=http://localhost:11434/v1

# Performance Tuning
MAX_CONCURRENT_REQUESTS=10
REQUEST_TIMEOUT_MS=30000
CACHE_ENABLED=true

# Security
RATE_LIMIT_REQUESTS=100
VALIDATE_FILE_ACCESS=true
```

## 🚗 Usage Examples

### Basic Usage

```javascript
// The bridge automatically routes to the best provider
const response = await mcpBridge.query({
  prompt: "Explain quantum computing",
  tools: ["analyze"]
});
```

### Coding Tasks

```javascript
// Automatically routed to coding-optimized provider
const code = await mcpBridge.query({
  prompt: "Write a React component for user authentication",
  tools: ["generate"]
});
```

### Analysis Tasks

```javascript
// Automatically routed to analysis-optimized provider
const analysis = await mcpBridge.query({
  prompt: "Analyze the performance metrics and suggest optimizations",
  tools: ["analyze"]
});
```

## 🔧 Advanced Configuration

### Custom Provider Setup

Add support for custom AI providers by extending the provider configuration:

```javascript
// In src/providers/custom.js
export const customProvider = {
  name: 'custom',
  baseURL: process.env.CUSTOM_API_URL,
  apiKey: process.env.CUSTOM_API_KEY,
  model: process.env.CUSTOM_MODEL,
  // Implementation details...
};
```

### Custom Routing Rules

Modify routing patterns for your specific use case:

```bash
# Custom patterns in .env
ANALYSIS_PATTERNS=analyze,research,calculate,review,audit
CODING_PATTERNS=implement,debug,refactor,optimize,test
CREATIVE_PATTERNS=write,design,brainstorm,generate
```

## 🔒 Security

- All API keys are managed through environment variables
- File access validation prevents unauthorized file operations
- Rate limiting protects against abuse
- Input sanitization prevents injection attacks

## 📊 Monitoring

The bridge includes built-in monitoring:

- Request/response logging
- Performance metrics
- Error tracking
- Provider health checks

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [wiki](../../wiki) for detailed guides
- **Issues**: Report bugs or request features in [Issues](../../issues)
- **Discussions**: Join the community in [Discussions](../../discussions)

## 🌟 Star History

If you find this project useful, please consider giving it a star! ⭐

---

**Smart MCP Bridge** - Connecting AI providers intelligently since 2024 🚀