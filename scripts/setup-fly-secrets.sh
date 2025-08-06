#!/bin/bash

set -e  # Exit on any error

echo "🔐 AI Town - Fly.io Secrets Configuration"
echo "========================================="
echo "This script helps you configure API keys and secrets for your AI Town deployment"
echo ""

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    print_error "flyctl CLI is not installed. Please install it first:"
    echo "  brew install flyctl"
    echo "  or visit: https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

# Check if user is logged in to Fly
if ! flyctl auth whoami &> /dev/null; then
    print_error "You are not logged in to Fly.io. Please run:"
    echo "  flyctl auth login"
    exit 1
fi

print_success "Prerequisites check passed!"
echo ""

# Get app name
echo "🔧 App Configuration"
echo "==================="
echo -n "Enter your backend app name (e.g., myapp-backend): "
read BACKEND_APP_NAME

if [ -z "$BACKEND_APP_NAME" ]; then
    print_error "Backend app name is required!"
    exit 1
fi

# Check if the app exists
if ! flyctl apps list | grep -q "$BACKEND_APP_NAME"; then
    print_error "App '$BACKEND_APP_NAME' does not exist. Please check the name or deploy first."
    exit 1
fi

echo ""
echo "🤖 LLM Provider Configuration"
echo "============================="
echo "Choose your LLM provider:"
echo "1) OpenAI (GPT-4, GPT-3.5)"
echo "2) Together.ai (Open source models)"
echo "3) Custom OpenAI-compatible API"
echo ""
echo -n "Enter your choice (1-3): "
read LLM_CHOICE

case $LLM_CHOICE in
    1)
        echo ""
        echo "🔑 OpenAI Configuration"
        echo "======================"
        echo -n "Enter your OpenAI API key: "
        read -s OPENAI_KEY
        echo ""
        
        if [ -z "$OPENAI_KEY" ]; then
            print_error "OpenAI API key is required!"
            exit 1
        fi
        
        print_status "Setting OpenAI API key..."
        flyctl secrets set OPENAI_API_KEY="$OPENAI_KEY" --app "$BACKEND_APP_NAME"
        
        echo -n "Enter OpenAI chat model (default: gpt-3.5-turbo): "
        read OPENAI_CHAT_MODEL
        OPENAI_CHAT_MODEL=${OPENAI_CHAT_MODEL:-gpt-3.5-turbo}
        
        echo -n "Enter OpenAI embedding model (default: text-embedding-ada-002): "
        read OPENAI_EMBEDDING_MODEL
        OPENAI_EMBEDDING_MODEL=${OPENAI_EMBEDDING_MODEL:-text-embedding-ada-002}
        
        flyctl secrets set OPENAI_CHAT_MODEL="$OPENAI_CHAT_MODEL" --app "$BACKEND_APP_NAME"
        flyctl secrets set OPENAI_EMBEDDING_MODEL="$OPENAI_EMBEDDING_MODEL" --app "$BACKEND_APP_NAME"
        
        print_success "OpenAI configuration complete!"
        ;;
        
    2)
        echo ""
        echo "🔑 Together.ai Configuration"
        echo "============================"
        echo -n "Enter your Together.ai API key: "
        read -s TOGETHER_KEY
        echo ""
        
        if [ -z "$TOGETHER_KEY" ]; then
            print_error "Together.ai API key is required!"
            exit 1
        fi
        
        print_status "Setting Together.ai API key..."
        flyctl secrets set TOGETHER_API_KEY="$TOGETHER_KEY" --app "$BACKEND_APP_NAME"
        
        echo -n "Enter Together chat model (default: meta-llama/Llama-2-70b-chat-hf): "
        read TOGETHER_CHAT_MODEL
        TOGETHER_CHAT_MODEL=${TOGETHER_CHAT_MODEL:-meta-llama/Llama-2-70b-chat-hf}
        
        echo -n "Enter Together embedding model (default: togethercomputer/m2-bert-80M-8k-retrieval): "
        read TOGETHER_EMBEDDING_MODEL
        TOGETHER_EMBEDDING_MODEL=${TOGETHER_EMBEDDING_MODEL:-togethercomputer/m2-bert-80M-8k-retrieval}
        
        flyctl secrets set TOGETHER_CHAT_MODEL="$TOGETHER_CHAT_MODEL" --app "$BACKEND_APP_NAME"
        flyctl secrets set TOGETHER_EMBEDDING_MODEL="$TOGETHER_EMBEDDING_MODEL" --app "$BACKEND_APP_NAME"
        
        print_success "Together.ai configuration complete!"
        ;;
        
    3)
        echo ""
        echo "🔑 Custom API Configuration"
        echo "==========================="
        echo -n "Enter your API URL: "
        read LLM_API_URL
        
        if [ -z "$LLM_API_URL" ]; then
            print_error "API URL is required!"
            exit 1
        fi
        
        echo -n "Enter your API key (leave empty if not required): "
        read -s LLM_API_KEY
        echo ""
        
        echo -n "Enter chat model name: "
        read LLM_MODEL
        
        if [ -z "$LLM_MODEL" ]; then
            print_error "Model name is required!"
            exit 1
        fi
        
        echo -n "Enter embedding model name: "
        read LLM_EMBEDDING_MODEL
        
        if [ -z "$LLM_EMBEDDING_MODEL" ]; then
            print_error "Embedding model name is required!"
            exit 1
        fi
        
        print_status "Setting custom API configuration..."
        flyctl secrets set LLM_API_URL="$LLM_API_URL" --app "$BACKEND_APP_NAME"
        flyctl secrets set LLM_MODEL="$LLM_MODEL" --app "$BACKEND_APP_NAME"
        flyctl secrets set LLM_EMBEDDING_MODEL="$LLM_EMBEDDING_MODEL" --app "$BACKEND_APP_NAME"
        
        if [ ! -z "$LLM_API_KEY" ]; then
            flyctl secrets set LLM_API_KEY="$LLM_API_KEY" --app "$BACKEND_APP_NAME"
        fi
        
        print_success "Custom API configuration complete!"
        ;;
        
    *)
        print_error "Invalid choice. Please run the script again and choose 1-3."
        exit 1
        ;;
esac

echo ""
echo "🎵 Optional: Background Music Configuration"
echo "=========================================="
echo "AI Town can generate background music using Replicate (optional)"
echo -n "Do you want to configure background music? (y/N): "
read CONFIGURE_MUSIC

if [[ "$CONFIGURE_MUSIC" =~ ^[Yy]$ ]]; then
    echo -n "Enter your Replicate API token: "
    read -s REPLICATE_TOKEN
    echo ""
    
    if [ ! -z "$REPLICATE_TOKEN" ]; then
        flyctl secrets set REPLICATE_API_TOKEN="$REPLICATE_TOKEN" --app "$BACKEND_APP_NAME"
        print_success "Replicate API token configured!"
    fi
fi

echo ""
echo "🎉 Configuration Complete!"
echo "=========================="
print_success "All secrets have been configured for app: $BACKEND_APP_NAME"
echo ""
echo "📋 Summary of configured secrets:"
flyctl secrets list --app "$BACKEND_APP_NAME"
echo ""
echo "🔄 You may need to restart your app for changes to take effect:"
echo "  flyctl restart --app $BACKEND_APP_NAME"
echo ""
print_warning "Remember to keep your API keys secure and never commit them to version control!"