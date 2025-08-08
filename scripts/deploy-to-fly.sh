#!/bin/bash

set -e  # Exit on any error

echo "🧪 AI Town - Conversational AI Testing Lab"
echo "============================================"
echo "This will create your private AI testing environment on Fly.io"
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

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install Node.js and npm first."
    exit 1
fi

print_success "All prerequisites check passed!"
echo ""

# Get user input
echo "🔧 Configuration Setup"
echo "======================"

# Get OpenAI API key
echo -n "Enter your OpenAI API key (will be hidden): "
read -s OPENAI_KEY
echo ""

if [ -z "$OPENAI_KEY" ]; then
    print_error "OpenAI API key is required!"
    exit 1
fi

# Get app name
echo -n "Enter a unique app name (lowercase, hyphens allowed): "
read APP_NAME

if [ -z "$APP_NAME" ]; then
    print_error "App name is required!"
    exit 1
fi

# Get preferred region (optional)
echo ""
echo "📍 Region Selection"
echo "Common regions:"
echo "  iad - US East (Virginia)"
echo "  lax - US West (Los Angeles)" 
echo "  fra - Europe (Frankfurt)"
echo "  nrt - Asia (Tokyo)"
echo "  syd - Australia (Sydney)"
echo ""
echo -n "Enter preferred region (default: iad): "
read PREFERRED_REGION

if [ -z "$PREFERRED_REGION" ]; then
    PREFERRED_REGION="iad"
fi

print_status "Using region: $PREFERRED_REGION"

# Validate app name format
if [[ ! "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
    print_error "App name must contain only lowercase letters, numbers, and hyphens!"
    exit 1
fi

# Check if app names are available
BACKEND_APP_NAME="${APP_NAME}-backend"
FRONTEND_APP_NAME="${APP_NAME}"

print_status "Checking app name availability..."

# Check backend app name
if flyctl apps list | grep -q "$BACKEND_APP_NAME"; then
    print_warning "App name '$BACKEND_APP_NAME' already exists. Will attempt to use existing app."
    BACKEND_APP_EXISTS=true
else
    BACKEND_APP_EXISTS=false
fi

# Check frontend app name
if flyctl apps list | grep -q "$FRONTEND_APP_NAME"; then
    print_error "App name '$FRONTEND_APP_NAME' is already taken. Please choose a different name."
    exit 1
fi

print_success "App names are available!"
echo ""

# Install dependencies if not already installed
print_status "Installing dependencies..."
if [ ! -d "node_modules" ]; then
    npm install
    print_success "Dependencies installed!"
else
    print_status "Dependencies already installed, skipping..."
fi

echo ""
print_status "🚀 Starting deployment process..."
echo ""

# Deploy self-hosted Convex backend
print_status "Deploying Convex backend to Fly.io..."

cd fly/backend

# Create fly.toml from template with dynamic app name (without volume mount initially)
cat > fly.toml << EOF
# fly.toml app configuration file for AI Town Convex backend
app = "${BACKEND_APP_NAME}"
primary_region = "${PREFERRED_REGION}"

[build]
image = "ghcr.io/get-convex/convex-backend:4499dd4fd7f2148687a7774599c613d052950f46"

[env]
TMPDIR = "/convex/data/tmp"

[http_service]
internal_port = 3210
force_https = true
auto_stop_machines = "stop"
auto_start_machines = true
min_machines_running = 1
processes = ["app"]

[[http_service.checks]]
interval = "5s"
timeout = "30s"
grace_period = "5s"
method = "GET"
path = "/version"
protocol = "http"

[[vm]]
memory = "1gb"
cpu_kind = "shared"
cpus = 1
EOF

# Create the app first (without launching to avoid source code detection)
if [ "$BACKEND_APP_EXISTS" = false ]; then
    print_status "Creating backend app..."
    if ! flyctl apps create "$BACKEND_APP_NAME"; then
        print_error "Failed to create backend app."
        exit 1
    fi
else
    print_status "Using existing backend app..."
fi

# Scale to 1 machine before deployment to prevent multiple machines
print_status "Setting machine count to 1 before deployment..."
flyctl scale count 1 --app "$BACKEND_APP_NAME"

# Deploy using the pre-built image first to establish the app's region
print_status "Deploying backend with Convex image..."
flyctl deploy --app "$BACKEND_APP_NAME"

# Get the actual region where the app was deployed
ACTUAL_REGION=$(flyctl status --app "$BACKEND_APP_NAME" | grep "Region" | head -1 | awk '{print $2}')
if [ -z "$ACTUAL_REGION" ]; then
    ACTUAL_REGION="$PREFERRED_REGION"
fi

print_status "App deployed in region: $ACTUAL_REGION"

# Create volumes for Convex data persistence in the same region as the deployed app
print_status "Creating persistent storage volumes in region: $ACTUAL_REGION"

# Get the number of machines that were created
MACHINE_COUNT=$(flyctl machine list --app "$BACKEND_APP_NAME" | grep -c "app")
print_status "Detected $MACHINE_COUNT machines, creating matching volumes..."

# Get current volume count
VOLUME_COUNT=$(flyctl volumes list --app "$BACKEND_APP_NAME" | grep -c "convex_data" || echo "0")

# Create additional volumes if needed
VOLUMES_NEEDED=$((MACHINE_COUNT - VOLUME_COUNT))
if [ $VOLUMES_NEEDED -gt 0 ]; then
    print_status "Creating $VOLUMES_NEEDED additional volumes..."
    for i in $(seq 1 $VOLUMES_NEEDED); do
        if ! flyctl volumes create convex_data --size 1 --region "$ACTUAL_REGION" --app "$BACKEND_APP_NAME" --yes; then
            print_error "Failed to create volume $i. This may cause deployment issues."
        fi
    done
else
    print_status "Sufficient volumes already exist."
fi

# Update fly.toml to include the volume mount now that volume exists
cat > fly.toml << EOF
# fly.toml app configuration file for AI Town Convex backend
app = "${BACKEND_APP_NAME}"
primary_region = "${ACTUAL_REGION}"

[build]
image = "ghcr.io/get-convex/convex-backend:4499dd4fd7f2148687a7774599c613d052950f46"

[env]
TMPDIR = "/convex/data/tmp"

[[mounts]]
source = "convex_data"
destination = "/convex/data"

[http_service]
internal_port = 3210
force_https = true
auto_stop_machines = "stop"
auto_start_machines = true
min_machines_running = 1
processes = ["app"]

[[http_service.checks]]
interval = "5s"
timeout = "30s"
grace_period = "5s"
method = "GET"
path = "/version"
protocol = "http"

[[vm]]
memory = "1gb"
cpu_kind = "shared"
cpus = 1
EOF

# Redeploy to attach the volume
print_status "Redeploying to attach volume..."
flyctl deploy --app "$BACKEND_APP_NAME"

cd ../..

print_success "Backend deployed successfully!"

# Get backend URL
BACKEND_URL="https://${BACKEND_APP_NAME}.fly.dev"
print_status "Backend URL: $BACKEND_URL"

# Deploy frontend
print_status "Deploying frontend to Fly.io..."

# Update vite.config.ts to allow the new domain
cat > vite.config.ts << EOF
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    allowedHosts: ['${FRONTEND_APP_NAME}.fly.dev', 'localhost', '127.0.0.1'],
  },
});
EOF

# Create fly.toml for frontend
cat > fly.toml << EOF
# fly.toml app configuration file for AI Town frontend
app = "${FRONTEND_APP_NAME}"
primary_region = "${PREFERRED_REGION}"

[build]

[env]
VITE_CONVEX_URL = "https://${BACKEND_APP_NAME}.fly.dev"

[http_service]
internal_port = 5173
force_https = true
auto_stop_machines = "stop"
auto_start_machines = true
min_machines_running = 1
processes = ["app"]

[[vm]]
memory = "1gb"
cpu_kind = "shared"
cpus = 1
EOF

# Create frontend app
flyctl apps create "$FRONTEND_APP_NAME"

# Set environment variables for frontend
flyctl secrets set VITE_CONVEX_URL="$BACKEND_URL" --app "$FRONTEND_APP_NAME"

# Deploy frontend
flyctl deploy --app "$FRONTEND_APP_NAME"

print_success "Frontend deployed successfully!"

# Configure secrets for backend
print_status "Configuring API keys..."
flyctl secrets set OPENAI_API_KEY="$OPENAI_KEY" --app "$BACKEND_APP_NAME"

print_success "API keys configured!"

echo ""
echo "🎉 Deployment Complete!"
echo "======================="
print_success "Your AI Town testing lab is ready!"
echo ""
echo "📱 Frontend URL: https://${FRONTEND_APP_NAME}.fly.dev"
echo "🔧 Backend URL:  https://${BACKEND_APP_NAME}.fly.dev"
echo ""
echo "🧪 Perfect for testing:"
echo "  • Multi-agent conversations and emergent behaviors"
echo "  • Different LLM providers and models"
echo "  • Conversation prompts and agent personalities"
echo "  • Memory systems and relationship dynamics"
echo ""
echo "📖 Next steps:"
echo "  • Visit your frontend URL to start using AI Town"
echo "  • Check the dashboard at https://${BACKEND_APP_NAME}.fly.dev"
echo "  • See docs/FLY_DEPLOYMENT.md for advanced configuration"
echo ""
print_warning "Note: It may take a few minutes for the apps to fully start up."
print_warning "If you encounter issues, check 'flyctl logs --app $FRONTEND_APP_NAME'"