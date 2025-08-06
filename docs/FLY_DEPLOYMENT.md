# AI Town - Fly.io Deployment Guide

Complete guide for deploying AI Town as a conversational AI testing lab on Fly.io infrastructure.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start (One-Click Deploy)](#quick-start-one-click-deploy)
- [Manual Deployment](#manual-deployment)
- [Configuration](#configuration)
- [LLM Provider Setup](#llm-provider-setup)
- [Advanced Configuration](#advanced-configuration)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Security Best Practices](#security-best-practices)

## Overview

AI Town on Fly.io provides a complete conversational AI testing environment with:

- **Frontend**: React application for user interaction
- **Backend**: Self-hosted Convex backend for real-time data and AI processing
- **LLM Integration**: Support for OpenAI, Together.ai, Ollama, and custom APIs
- **Auto-scaling**: Intelligent machine scaling based on usage
- **Global deployment**: Deploy close to your users worldwide

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   LLM Provider  │
│   (React/Vite)  │────│   (Convex)      │────│   (OpenAI/etc)  │
│   fly.dev       │    │   fly.dev       │    │   External API  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

### Required Tools

1. **Fly.io CLI**: Install and authenticate
   ```bash
   # macOS
   brew install flyctl
   
   # Linux/WSL
   curl -L https://fly.io/install.sh | sh
   
   # Windows
   # Download from https://github.com/superfly/flyctl/releases
   ```

2. **Fly.io Account**: Sign up at [fly.io](https://fly.io)
   ```bash
   flyctl auth login
   ```

3. **Node.js**: Version 18 or higher
   ```bash
   node --version  # Should be 18.x.x or higher
   npm --version
   ```

### Required API Keys

Choose one LLM provider:

- **OpenAI**: Get API key from [platform.openai.com](https://platform.openai.com/account/api-keys)
- **Together.ai**: Get API key from [api.together.xyz](https://api.together.xyz/settings/api-keys)
- **Ollama**: Set up local tunnel (see [Local Ollama Setup](#local-ollama-setup))
- **Custom**: Any OpenAI-compatible API

### Optional Services

- **Replicate**: For background music generation ([replicate.com](https://replicate.com/account/api-tokens))
- **Clerk**: For user authentication ([clerk.com](https://clerk.com))

## Quick Start (One-Click Deploy)

The fastest way to deploy AI Town for testing:

```bash
git clone https://github.com/fly-apps/ai-town
cd ai-town
./scripts/deploy-to-fly.sh
```

This script will:

1. ✅ Check prerequisites
2. 🔧 Prompt for configuration (API keys, app name)
3. 🚀 Deploy backend and frontend
4. 🔐 Configure secrets
5. 🎉 Provide access URLs

**Total deployment time**: ~5-10 minutes

## Manual Deployment

For more control over the deployment process:

### Step 1: Clone and Setup

```bash
git clone https://github.com/fly-apps/ai-town
cd ai-town
npm install
```

### Step 2: Deploy Backend (Convex)

```bash
cd fly/backend

# Create app
flyctl launch --name "your-app-backend" --no-deploy

# Deploy
flyctl deploy
```

### Step 3: Configure Backend Secrets

```bash
# OpenAI (recommended for testing)
flyctl secrets set OPENAI_API_KEY="your-openai-key" --app "your-app-backend"

# Or use the configuration helper
cd ../..
./scripts/setup-fly-secrets.sh
```

### Step 4: Deploy Frontend

```bash
# Update vite.config.ts with your domain
# Update fly.toml with your backend URL

flyctl launch --name "your-app" --no-deploy
flyctl secrets set VITE_CONVEX_URL="https://your-app-backend.fly.dev"
flyctl deploy
```

### Step 5: Initialize Data

```bash
# Connect to your backend and initialize the world
# This step is automatically handled by the Convex backend
```

## Configuration

### Environment Variables

#### Frontend (.env or Fly secrets)

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_CONVEX_URL` | Backend Convex URL | ✅ |
| `VITE_CLERK_PUBLISHABLE_KEY` | Clerk auth key | ❌ |

#### Backend (Fly secrets)

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key | ✅ (or other LLM) |
| `OPENAI_CHAT_MODEL` | Chat model name | ❌ |
| `OPENAI_EMBEDDING_MODEL` | Embedding model | ❌ |
| `TOGETHER_API_KEY` | Together.ai API key | ❌ |
| `OLLAMA_HOST` | Ollama tunnel URL | ❌ |
| `REPLICATE_API_TOKEN` | For music generation | ❌ |

### Setting Secrets

```bash
# Using flyctl
flyctl secrets set KEY="value" --app "your-app-name"

# Using the helper script
./scripts/setup-fly-secrets.sh

# List current secrets
flyctl secrets list --app "your-app-name"
```

## LLM Provider Setup

### OpenAI (Recommended)

Best for testing and development:

```bash
flyctl secrets set OPENAI_API_KEY="sk-..." --app "your-backend"
flyctl secrets set OPENAI_CHAT_MODEL="gpt-3.5-turbo" --app "your-backend"
flyctl secrets set OPENAI_EMBEDDING_MODEL="text-embedding-ada-002" --app "your-backend"
```

**Cost**: ~$0.01-0.10 per conversation depending on model

### Together.ai

Best for open source models:

```bash
flyctl secrets set TOGETHER_API_KEY="..." --app "your-backend"
flyctl secrets set TOGETHER_CHAT_MODEL="meta-llama/Llama-2-70b-chat-hf" --app "your-backend"
flyctl secrets set TOGETHER_EMBEDDING_MODEL="togethercomputer/m2-bert-80M-8k-retrieval" --app "your-backend"
```

**Cost**: ~$0.001-0.01 per conversation

### Local Ollama Setup

For complete privacy and control:

1. **Install Ollama locally**:
   ```bash
   # macOS
   brew install ollama
   ollama serve
   
   # Pull models
   ollama pull llama3
   ollama pull mxbai-embed-large
   ```

2. **Create tunnel** (choose one):
   
   **Option A: ngrok**
   ```bash
   ngrok http 11434
   # Copy the https URL
   ```
   
   **Option B: tunnelmole**
   ```bash
   npm install -g tunnelmole
   tmole 11434
   # Copy the https URL
   ```

3. **Configure AI Town**:
   ```bash
   flyctl secrets set OLLAMA_HOST="https://your-tunnel-url.ngrok.io" --app "your-backend"
   flyctl secrets set OLLAMA_MODEL="llama3" --app "your-backend"
   flyctl secrets set OLLAMA_EMBEDDING_MODEL="mxbai-embed-large" --app "your-backend"
   ```

**Cost**: Free (local compute only)

## Advanced Configuration

### Custom Domains

```bash
# Add custom domain
flyctl certs create your-domain.com --app "your-app"

# Update DNS
# A record: your-domain.com -> [your app IP]
```

### Scaling

```bash
# Horizontal scaling
flyctl scale count 3 --app "your-app"

# Vertical scaling
flyctl scale vm performance-2x --app "your-app"

# Auto-scaling (in fly.toml)
min_machines_running = 1
max_machines_running = 10
```

### Multiple Regions

```toml
# In fly.toml
[[regions]]
region = "iad"  # US East
primary = true

[[regions]]
region = "lax"  # US West

[[regions]]
region = "fra"  # Europe
```

### Background Music

```bash
# Enable music generation
flyctl secrets set REPLICATE_API_TOKEN="your-token" --app "your-backend"

# Customize music prompts in convex/music.ts
```

## Monitoring & Maintenance

### Viewing Logs

```bash
# Real-time logs
flyctl logs --app "your-app"

# Specific time range
flyctl logs --app "your-app" --since="1h"

# Backend logs
flyctl logs --app "your-backend"
```

### Health Monitoring

```bash
# App status
flyctl status --app "your-app"

# Machine details
flyctl machine list --app "your-app"

# Resource usage
flyctl metrics --app "your-app"
```

### Updating

```bash
# Pull latest changes
git pull origin main

# Redeploy
flyctl deploy --app "your-app"
flyctl deploy --app "your-backend"
```

### Database Management

```bash
# Access Convex dashboard
# Visit: https://your-backend.fly.dev

# Reset world (via backend logs/dashboard)
# The Convex backend provides admin functions
```

## Troubleshooting

### Common Issues

#### 1. App Won't Start

```bash
# Check logs
flyctl logs --app "your-app"

# Check machine status
flyctl machine list --app "your-app"

# Restart machines
flyctl machine restart --app "your-app"
```

#### 2. Backend Connection Issues

```bash
# Verify backend URL
curl https://your-backend.fly.dev/version

# Check secrets
flyctl secrets list --app "your-backend"

# Test API connection
flyctl ssh console --app "your-backend"
```

#### 3. LLM API Errors

```bash
# Check API key configuration
flyctl secrets list --app "your-backend"

# Test API manually
curl -H "Authorization: Bearer your-api-key" \
     https://api.openai.com/v1/models
```

#### 4. Out of Memory

```bash
# Scale up memory
flyctl scale vm performance-2x --app "your-app"

# Check memory usage
flyctl metrics --app "your-app"
```

#### 5. Ollama Connection Issues

```bash
# Test tunnel
curl https://your-tunnel-url.ngrok.io

# Check Ollama locally
curl http://localhost:11434

# Verify models
ollama list
```

### Debug Mode

```bash
# Enable debug logging
flyctl secrets set LOG_LEVEL="debug" --app "your-backend"

# SSH into machine
flyctl ssh console --app "your-app"
```

## Cost Optimization

### Expected Costs

| Component | Cost (USD/month) |
|-----------|------------------|
| Frontend (1GB RAM) | ~$10-20 |
| Backend (1GB RAM) | ~$10-20 |
| OpenAI API | ~$5-50 |
| **Total** | **~$25-90** |

### Optimization Tips

1. **Auto-stop machines** for development:
   ```toml
   auto_stop_machines = "stop"
   min_machines_running = 0  # Dev only
   ```

2. **Use shared CPU** for low traffic:
   ```toml
   cpu_kind = "shared"
   cpus = 1
   ```

3. **Monitor usage**:
   ```bash
   flyctl metrics --app "your-app"
   flyctl dashboard --app "your-app"
   ```

4. **Choose efficient LLM**:
   - Development: gpt-3.5-turbo
   - Production: gpt-4 or Together.ai models

5. **Regional deployment**:
   - Deploy close to users
   - Use single region for testing

## Security Best Practices

### 1. API Key Management

```bash
# ✅ Store in Fly secrets
flyctl secrets set API_KEY="..." --app "your-app"

# ❌ Never commit to code
# ❌ Never expose in frontend
```

### 2. HTTPS Only

```toml
# In fly.toml
force_https = true
```

### 3. Access Control

```bash
# Restrict SSH access
flyctl ssh issue --app "your-app" --hours 1

# Monitor access logs
flyctl logs --app "your-app" | grep "access"
```

### 4. Regular Updates

```bash
# Update dependencies
npm update

# Redeploy regularly
flyctl deploy --app "your-app"
```

### 5. Backup Strategy

```bash
# Export Convex data
# Use Convex dashboard export features

# Backup configuration
git commit -a -m "Save current config"
```

## Use Cases for AI Testing

AI Town on Fly.io is perfect for:

### 1. Multi-Agent Research
- Test conversation dynamics between AI agents
- Observe emergent behaviors in social settings
- Experiment with different personality configurations

### 2. LLM Comparison
- A/B test different models (OpenAI vs Together.ai vs local)
- Compare response quality and speed
- Test cost vs performance trade-offs

### 3. Prompt Engineering
- Iterate on agent personalities and conversation starters
- Test different conversation contexts
- Optimize prompts for specific behaviors

### 4. Memory System Testing
- Evaluate how agents remember past conversations
- Test relationship building over time
- Experiment with different memory architectures

### 5. Performance Testing
- Load test with multiple concurrent conversations
- Monitor resource usage under different loads
- Test scaling behavior

## Getting Help

- **Documentation**: This guide and [README.md](../README.md)
- **Logs**: `flyctl logs --app "your-app"`
- **Community**: [AI Stack Devs Discord](https://discord.gg/PQUmTBTGmT)
- **Fly.io Support**: [fly.io/docs](https://fly.io/docs)
- **GitHub Issues**: [Report bugs](https://github.com/fly-apps/ai-town/issues)

---

*This deployment guide is part of the AI Town fork optimized for Fly.io. Original project: [a16z-infra/ai-town](https://github.com/a16z-infra/ai-town)*