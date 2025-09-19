# PRODUCTION-DEPLOYMENT.md

# MKG Server v8.0.0 - Production Deployment Guide

## 🚀 Enterprise Production Deployment

### Production Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                 MKG Production Stack                     │
├─────────────────────────────────────────────────────────┤
│  Claude Code Client                                     │
│  ↓ (MCP Protocol)                                       │
│  MKG Server v8.0.0 (Node.js)                          │
│  ↓ (Smart Routing)                                      │
│  ┌─────────────────┬─────────────────┬─────────────────┐ │
│  │ Local Container │ NVIDIA Cloud    │ Backup Systems  │ │
│  │ (Primary 95%)   │ (Fallback 5%)   │ (Monitoring)    │ │
│  └─────────────────┴─────────────────┴─────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 🏗️ Infrastructure Requirements

### Server Specifications
- **CPU**: 16+ cores (Intel Xeon or AMD EPYC recommended)
- **RAM**: 64GB+ for optimal performance
- **GPU**: NVIDIA RTX 4090/5080 with 16GB+ VRAM
- **Storage**: 1TB+ NVMe SSD for model cache and operations
- **Network**: 1Gbps+ with low latency to NVIDIA cloud

### Operating System
- **Recommended**: Ubuntu 22.04 LTS or CentOS 8+
- **Container Runtime**: Docker 24.0+ with nvidia-container-toolkit
- **Node.js**: v18.17.0+ with ES module support

## 🔧 Production Setup Steps

### 1. System Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Install Node.js 18+ using NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installations
docker --version
docker-compose --version
nvidia-smi
node --version
npm --version
```

### 2. Application Deployment

```bash
# Create production directory
sudo mkdir -p /opt/mkg-server
sudo chown $USER:$USER /opt/mkg-server
cd /opt/mkg-server

# Clone and setup MKG server
git clone https://github.com/your-org/mkg-server.git .
npm install --production

# Create production configuration
sudo mkdir -p /etc/mkg-server
sudo cp config/production.env /etc/mkg-server/.env
sudo chown root:root /etc/mkg-server/.env
sudo chmod 600 /etc/mkg-server/.env
```

### 3. Environment Configuration

Create `/etc/mkg-server/.env`:
```bash
# Production Environment Variables
NODE_ENV=production
MCP_SERVER_MODE=true
MCP_SERVER_NAME=mecha-king-ghidorah-production

# NVIDIA Cloud Integration (Production Key)
NVIDIA_API_KEY=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

# Local Model Configuration
MKG_SERVER_PORT=8001
DEEPSEEK_ENDPOINT=http://127.0.0.1:8001/v1
VALIDATION_ENABLED=true

# Performance Tuning
MAX_CONCURRENT_REQUESTS=10
CACHE_TTL=900
HEALTH_CHECK_INTERVAL=30
ROUTING_TIMEOUT=100

# Monitoring
LOG_LEVEL=info
METRICS_ENABLED=true
HEALTH_ENDPOINT_ENABLED=true

# Security
CORS_ENABLED=false
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=100
```

### 4. Container Orchestration

#### Production Docker Compose
Create `/opt/mkg-server/docker-compose.production.yml`:
```yaml
version: '3.8'

services:
  mkg-local-model:
    image: vllm/vllm-openai:latest
    container_name: mkg-qwen3-coder-production
    restart: unless-stopped
    ports:
      - "127.0.0.1:8001:8000"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - CUDA_VISIBLE_DEVICES=0
    volumes:
      - model_cache:/root/.cache/huggingface
      - ./logs:/app/logs
      - ./config:/app/config:ro
    command: [
      "--model", "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8",
      "--host", "0.0.0.0",
      "--port", "8000",
      "--served-model-name", "qwen3-coder-30b-fp8",
      "--max-model-len", "32768",
      "--gpu-memory-utilization", "0.80",
      "--tensor-parallel-size", "1",
      "--dtype", "auto",
      "--quantization", "fp8",
      "--enable-lora",
      "--max-loras", "4",
      "--trust-remote-code",
      "--disable-log-stats",
      "--api-key", "${PRODUCTION_MODEL_API_KEY:-default-key}"
    ]
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 300s
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
    security_opt:
      - no-new-privileges:true

  mkg-server:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: mkg-server-production
    restart: unless-stopped
    depends_on:
      - mkg-local-model
    ports:
      - "127.0.0.1:3001:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - /etc/mkg-server/.env
    volumes:
      - ./logs:/app/logs
      - ./backups:/app/backups
      - /tmp:/tmp:ro
    healthcheck:
      test: ["CMD", "node", "health-check.js"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
    security_opt:
      - no-new-privileges:true

volumes:
  model_cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/mkg-server/model_cache

networks:
  default:
    name: mkg-production-network
    driver: bridge
```

#### Production Dockerfile
Create `Dockerfile.production`:
```dockerfile
FROM node:18-alpine

# Security updates
RUN apk update && apk upgrade && apk add --no-cache curl

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S mkg && adduser -S mkg -u 1001

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Set ownership
RUN chown -R mkg:mkg /app

# Switch to non-root user
USER mkg

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node health-check.js

# Start application
CMD ["node", "server-mecha-king-ghidorah-simplified.js"]
```

### 5. Process Management with PM2

```bash
# Install PM2 globally
sudo npm install -g pm2

# Create PM2 ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'mkg-server-production',
    script: 'server-mecha-king-ghidorah-simplified.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '2G',
    env: {
      NODE_ENV: 'production'
    },
    env_file: '/etc/mkg-server/.env',
    log_file: '/opt/mkg-server/logs/combined.log',
    out_file: '/opt/mkg-server/logs/out.log',
    error_file: '/opt/mkg-server/logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    kill_timeout: 5000,
    restart_delay: 3000,
    max_restarts: 5,
    min_uptime: '30s'
  }]
};
EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Monitor
pm2 monit
```

## 🔒 Security Configuration

### 1. Firewall Setup

```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change 22 to your SSH port if different)
sudo ufw allow 22/tcp

# Allow MKG server (local access only)
sudo ufw allow from 127.0.0.1 to any port 3001
sudo ufw allow from 127.0.0.1 to any port 8001

# Allow NGINX reverse proxy
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw reload
```

### 2. NGINX Reverse Proxy

Install and configure NGINX:
```bash
sudo apt install nginx

# Create NGINX configuration
sudo tee /etc/nginx/sites-available/mkg-server << 'EOF'
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/ssl/certs/your-domain.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3001/health;
        access_log off;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/mkg-server /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. SSL Certificate Setup

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 Monitoring and Logging

### 1. System Monitoring

Create `/opt/mkg-server/monitoring/health-check.js`:
```javascript
#!/usr/bin/env node

const http = require('http');
const fs = require('fs');

const healthCheck = async () => {
  try {
    // Check MKG server
    const serverHealth = await fetch('http://127.0.0.1:3001/health');

    // Check local model
    const modelHealth = await fetch('http://127.0.0.1:8001/health');

    // Check disk space
    const stats = fs.statSync('/opt/mkg-server');

    const health = {
      timestamp: new Date().toISOString(),
      server: serverHealth.ok,
      model: modelHealth.ok,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      disk: stats
    };

    console.log(JSON.stringify(health));
    process.exit(serverHealth.ok && modelHealth.ok ? 0 : 1);
  } catch (error) {
    console.error('Health check failed:', error.message);
    process.exit(1);
  }
};

healthCheck();
```

### 2. Log Rotation

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/mkg-server << 'EOF'
/opt/mkg-server/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    postrotate
        /bin/kill -USR1 $(cat /opt/mkg-server/mkg-server.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
EOF
```

### 3. Monitoring Dashboard

Create monitoring script `/opt/mkg-server/monitoring/dashboard.sh`:
```bash
#!/bin/bash

echo "=== MKG Server Production Dashboard ==="
echo "Timestamp: $(date)"
echo

echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

echo "=== GPU Status ==="
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
echo

echo "=== PM2 Status ==="
pm2 status
echo

echo "=== System Resources ==="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h /opt/mkg-server | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo

echo "=== Recent Errors ==="
tail -n 10 /opt/mkg-server/logs/error.log 2>/dev/null | grep -v "^$"
```

## 🚀 Deployment Automation

### 1. Deployment Script

Create `/opt/mkg-server/scripts/deploy.sh`:
```bash
#!/bin/bash

set -e

echo "🚀 Starting MKG Server Production Deployment..."

# Backup current deployment
BACKUP_DIR="/opt/mkg-server/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /opt/mkg-server/* "$BACKUP_DIR/" 2>/dev/null || true

# Pull latest changes
git pull origin main

# Install/update dependencies
npm ci --production

# Run tests
npm test

# Stop services gracefully
pm2 stop mkg-server-production || true
docker-compose -f docker-compose.production.yml down

# Start local model container
docker-compose -f docker-compose.production.yml up -d mkg-local-model

# Wait for model to be ready
echo "⏳ Waiting for local model to be ready..."
for i in {1..60}; do
  if curl -s http://127.0.0.1:8001/health > /dev/null; then
    echo "✅ Local model is ready"
    break
  fi
  sleep 5
done

# Start MKG server
pm2 start ecosystem.config.js

# Verify deployment
sleep 10
if pm2 describe mkg-server-production | grep -q "online"; then
  echo "✅ MKG Server deployment successful"
else
  echo "❌ MKG Server deployment failed"
  exit 1
fi

# Run health checks
node monitoring/health-check.js

echo "🎉 Deployment completed successfully!"
```

### 2. Zero-Downtime Updates

Create `/opt/mkg-server/scripts/rolling-update.sh`:
```bash
#!/bin/bash

set -e

echo "🔄 Starting zero-downtime rolling update..."

# Health check function
health_check() {
  curl -s http://127.0.0.1:3001/health > /dev/null
}

# Graceful shutdown
echo "⏸️ Gracefully stopping MKG server..."
pm2 reload mkg-server-production --update-env

# Wait for reload to complete
sleep 5

# Verify health
if health_check; then
  echo "✅ Rolling update successful"
else
  echo "❌ Rolling update failed, rolling back..."
  pm2 restart mkg-server-production
  exit 1
fi

echo "🎉 Zero-downtime update completed!"
```

## 📈 Performance Optimization

### 1. System Tuning

```bash
# Optimize kernel parameters
sudo tee -a /etc/sysctl.conf << 'EOF'
# Network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr

# File descriptor limits
fs.file-max = 2097152

# Memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

sudo sysctl -p
```

### 2. Application Performance

Configure performance in `/etc/mkg-server/.env`:
```bash
# Performance tuning
NODE_OPTIONS="--max-old-space-size=4096"
UV_THREADPOOL_SIZE=8
MAX_CONCURRENT_REQUESTS=20
CACHE_SIZE_MB=256
FIM_CACHE_TTL=900
HEALTH_CHECK_CACHE_TTL=30
```

## 🔍 Troubleshooting

### Common Production Issues

#### 1. High Memory Usage
```bash
# Monitor memory usage
watch -n 1 'free -h && echo && ps aux --sort=-%mem | head -10'

# Adjust Node.js memory limits
export NODE_OPTIONS="--max-old-space-size=2048"
```

#### 2. GPU Memory Issues
```bash
# Monitor GPU memory
watch -n 1 nvidia-smi

# Restart model container with lower GPU utilization
docker-compose -f docker-compose.production.yml down
# Edit docker-compose.production.yml: change --gpu-memory-utilization to 0.70
docker-compose -f docker-compose.production.yml up -d
```

#### 3. Connection Issues
```bash
# Check network connectivity
curl -v http://127.0.0.1:8001/health
curl -v http://127.0.0.1:3001/health

# Check firewall rules
sudo ufw status numbered

# Check NGINX logs
sudo tail -f /var/log/nginx/error.log
```

### Emergency Procedures

#### 1. Service Recovery
```bash
# Complete service restart
sudo systemctl restart docker
docker-compose -f docker-compose.production.yml up -d
pm2 restart all

# Verify all services
./monitoring/dashboard.sh
```

#### 2. Rollback Procedure
```bash
# Stop current services
pm2 stop all
docker-compose -f docker-compose.production.yml down

# Restore from backup
LATEST_BACKUP=$(ls -1t /opt/mkg-server/backups | head -1)
cp -r "/opt/mkg-server/backups/$LATEST_BACKUP"/* /opt/mkg-server/

# Restart services
docker-compose -f docker-compose.production.yml up -d
pm2 start ecosystem.config.js
```

## 📋 Production Checklist

### Pre-Deployment
- [ ] Hardware requirements met
- [ ] NVIDIA drivers and container toolkit installed
- [ ] Security configurations applied
- [ ] SSL certificates configured
- [ ] Monitoring systems setup
- [ ] Backup procedures tested

### Deployment
- [ ] Environment variables configured
- [ ] Container images pulled and tested
- [ ] PM2 ecosystem configured
- [ ] NGINX reverse proxy setup
- [ ] Health checks passing
- [ ] Performance metrics baseline established

### Post-Deployment
- [ ] End-to-end testing completed
- [ ] Monitoring alerts configured
- [ ] Documentation updated
- [ ] Team notified of deployment
- [ ] Rollback plan validated

## 🎯 Production Metrics

### Target Performance
- **Startup Time**: <10 seconds
- **Response Time**: <2 seconds (95th percentile)
- **Throughput**: 100+ requests/minute
- **Availability**: 99.9% uptime
- **Error Rate**: <0.1%

### Monitoring KPIs
- GPU utilization: 70-85%
- Memory usage: <80% of available
- CPU usage: <70% average
- Disk I/O: <80% utilization
- Network latency: <50ms to NVIDIA cloud

**Production deployment complete - The enhanced monster rises in production!** 🦖