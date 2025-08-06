#!/bin/bash

set -e

echo "🧪 AI Town Local Development Setup"
echo "=================================="

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'.' -f1 | cut -d'v' -f2)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18+ required. Current version: $(node --version)"
    exit 1
fi

print_success "Node.js $(node --version) detected"

# Install dependencies
if [ ! -d "node_modules" ]; then
    print_status "Installing dependencies..."
    npm install
    print_success "Dependencies installed!"
else
    print_status "Dependencies already installed"
fi

# Check for environment file
if [ ! -f ".env.local" ]; then
    print_error ".env.local file not found!"
    print_status "Creating template .env.local file..."
    
    cat > .env.local << 'EOF'
# AI Town Local Development Configuration
# Configure with your actual API keys

# Required: Choose ONE LLM provider
OPENAI_API_KEY=your-openai-api-key-here

# Optional: Background music
# REPLICATE_API_TOKEN=your-replicate-token

# Development will auto-configure Convex settings
EOF
    
    print_warning "Please edit .env.local with your API keys before continuing"
    echo ""
    echo "Get OpenAI API key from: https://platform.openai.com/account/api-keys"
    echo "Then run this script again or run: npm run dev"
    exit 1
fi

# Check if OpenAI key is configured
if grep -q "your-openai-api-key-here" .env.local; then
    print_warning "Please configure your OpenAI API key in .env.local"
    echo "Edit .env.local and replace 'your-openai-api-key-here' with your actual API key"
    echo "Get it from: https://platform.openai.com/account/api-keys"
    exit 1
fi

print_success "Environment configuration looks good!"

echo ""
print_status "Setting up Convex backend..."

# Check if convex is available
if ! command -v npx &> /dev/null; then
    print_error "npx not available. Please ensure npm is properly installed."
    exit 1
fi

# Initialize Convex (this will create account if needed)
print_status "This will initialize Convex (you may need to log in)..."
npx convex deploy

print_success "Convex backend set up!"

echo ""
print_status "Initializing AI Town world..."
npx convex run init

print_success "AI Town world initialized!"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_success "AI Town is ready for local development!"
echo ""
echo "🚀 To start the development server:"
echo "  npm run dev"
echo ""
echo "📱 Access the app at:"
echo "  http://localhost:5173"
echo ""
echo "🔧 Useful commands:"
echo "  npm run dev:frontend    # Frontend only"
echo "  npm run dev:backend     # Backend only (with logs)"
echo "  npm run dashboard       # Open Convex dashboard"
echo ""
echo "🧪 For testing different LLM providers:"
echo "  Edit .env.local and restart with npm run dev"
echo ""
echo "🐛 If you encounter issues:"
echo "  npx convex run testing:stop     # Stop the simulation"
echo "  npx convex run testing:resume   # Resume the simulation"
echo "  npx convex run testing:kick     # Restart the simulation"