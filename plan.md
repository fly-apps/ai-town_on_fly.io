# AI Town Fly.io Deployment Project Plan

## Objective
Create a streamlined version of AI Town for the fly-apps organization that makes it easy for users to deploy their own conversational AI testing environment on Fly.io infrastructure.

## Use Case
- **Primary Goal**: Qualitative testing of conversational AI
- **Target Users**: AI researchers, product teams, developers building conversational AI
- **Value Proposition**: Private AI conversation lab for testing LLM models, agent behaviors, and conversation strategies

## Repository Strategy: Fork + Transfer Approach

### Phase 1: Personal Development
1. **Fork a16z-infra/ai-town to personal GitHub** (YOUR-USERNAME/ai-town)
2. **Develop Fly deployment improvements** in development branch
3. **Test thoroughly** - ensure deployment works flawlessly
4. **Polish documentation** and user experience

### Phase 2: Transfer to fly-apps
1. **Transfer ownership** to fly-apps organization via GitHub settings
2. **Maintain fork relationship** and commit history
3. **Preserve attribution** to original a16z-infra project

## Technical Implementation Plan

### Repository Structure (Post-Fork)
```
ai-town/
├── [all original files]           # Unchanged from upstream
├── scripts/
│   ├── deploy-to-fly.sh          # One-click deployment script
│   └── setup-fly-secrets.sh      # API key configuration helper
├── docs/
│   └── FLY_DEPLOYMENT.md         # Detailed Fly.io instructions
├── fly.template.toml             # Template with optimal defaults
└── README.md                     # Updated with Fly section
```

### Key Files to Create

#### 1. `scripts/deploy-to-fly.sh` - One-Click Deploy
```bash
#!/bin/bash
echo "🧪 Deploy AI Town - Conversational AI Testing Lab"
echo "This will create your private AI testing environment on Fly.io"

read -p "Enter your OpenAI API key: " -s OPENAI_KEY
read -p "Enter a unique app name: " APP_NAME

# Deploy self-hosted Convex backend
fly launch --name "${APP_NAME}-backend" --dockerfile fly/backend/Dockerfile

# Deploy frontend  
fly launch --name "${APP_NAME}" --env VITE_CONVEX_URL="https://${APP_NAME}-backend.fly.dev"

# Configure secrets
fly -a "${APP_NAME}-backend" secrets set OPENAI_API_KEY="$OPENAI_KEY"

echo "🎉 Your AI testing lab is ready at: https://${APP_NAME}.fly.dev"
```

#### 2. `docs/FLY_DEPLOYMENT.md` - Comprehensive Guide
- Prerequisites (Fly CLI, API keys)
- Step-by-step deployment instructions
- Configuration options
- Troubleshooting guide
- Cost estimation
- Usage examples for AI testing

#### 3. Updated `README.md` - Add Fly Section
```markdown
## 🚀 Deploy on Fly.io

The fastest way to get AI Town running for conversational AI testing:

```bash
git clone https://github.com/fly-apps/ai-town
cd ai-town
./scripts/deploy-to-fly.sh
```

Perfect for testing:
- Multi-agent conversations and emergent behaviors
- Different LLM providers and models
- Conversation prompts and agent personalities
- Memory systems and relationship dynamics

See [FLY_DEPLOYMENT.md](docs/FLY_DEPLOYMENT.md) for detailed instructions.

---
*This is a fork of [a16z-infra/ai-town](https://github.com/a16z-infra/ai-town) optimized for Fly.io deployment.*
```

## Deployment Architecture

### Target Deployment Pattern
- **Frontend**: Fly machine running React app
- **Backend**: Self-hosted Convex on Fly machine
- **LLM**: External API (OpenAI, Together, Anthropic)
- **Database**: Convex handles all data persistence
- **Vector Search**: Convex built-in vector database

### Configuration Strategy
- **Minimal config required**: Just API keys
- **Smart defaults**: Pre-configured resource allocations
- **Automated setup**: Script handles Convex backend deployment and linking

## Development Workflow

### Setup Commands
```bash
# 1. Fork a16z-infra/ai-town to personal GitHub
# 2. Clone and setup
git clone https://github.com/YOUR-USERNAME/ai-town.git
cd ai-town
git remote add upstream https://github.com/a16z-infra/ai-town.git
git checkout -b fly-deployment-improvements

# 3. Develop and test improvements
# 4. Transfer to fly-apps when ready
```

### Maintenance Strategy
```bash
# Periodic sync from upstream
git fetch upstream
git merge upstream/main
# Resolve conflicts in Fly-specific files
# Test deployment still works
```

## Success Criteria
- [ ] One-command deployment from fresh git clone
- [ ] Clear documentation for AI testing use cases
- [ ] Minimal user configuration required (just API keys)
- [ ] Preserves all original AI Town functionality
- [ ] Maintains attribution to original project
- [ ] Easy to sync updates from upstream

## Next Steps
1. **Fork repository** to personal GitHub
2. **Create deployment script** with automated Convex setup
3. **Test deployment process** end-to-end
4. **Document AI testing workflows** 
5. **Polish user experience**
6. **Transfer to fly-apps** organization

## Key Benefits for Fly Community
- **Educational**: Shows multi-service deployment patterns
- **Practical**: Real tool for AI development workflows
- **Showcase**: Demonstrates Fly's capabilities for AI applications
- **Attribution**: Maintains credit to original innovative project