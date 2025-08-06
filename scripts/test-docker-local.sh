#!/bin/bash

set -e

echo "🐳 AI Town Docker Local Testing"
echo "==============================="

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

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_success "Docker is running"

# Check docker-compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available."
    exit 1
fi

print_success "Docker Compose is available"

# Check for environment file
if [ ! -f ".env.local" ]; then
    print_warning "Creating .env.local for Docker setup..."
    
    cat > .env.local << 'EOF'
# Docker Compose Configuration
OPENAI_API_KEY=your-openai-api-key-here
# REPLICATE_API_TOKEN=your-replicate-token

# Docker-specific settings
CONVEX_SELF_HOSTED_URL=http://127.0.0.1:3210
CONVEX_SELF_HOSTED_ADMIN_KEY=will-be-generated
EOF
    
    print_warning "Please edit .env.local with your OpenAI API key"
    exit 1
fi

print_status "Starting Docker Compose services..."

# Start the services
docker compose up --build -d

print_success "Services started!"

# Wait for backend to be ready
print_status "Waiting for backend to be ready..."
sleep 10

# Generate admin key
print_status "Generating admin key..."
ADMIN_KEY=$(docker compose exec backend ./generate_admin_key.sh 2>/dev/null | tail -1)

if [ -z "$ADMIN_KEY" ]; then
    print_error "Failed to generate admin key"
    docker compose logs backend
    exit 1
fi

print_success "Admin key generated"

# Update .env.local with the admin key
sed -i.bak "s/CONVEX_SELF_HOSTED_ADMIN_KEY=.*/CONVEX_SELF_HOSTED_ADMIN_KEY=\"$ADMIN_KEY\"/" .env.local
rm .env.local.bak

print_status "Setting up Convex backend..."
npm run predev

print_status "Initializing AI Town world..."
npm run dev:backend &
DEV_PID=$!
sleep 5
kill $DEV_PID 2>/dev/null || true

echo ""
echo "🎉 Docker Setup Complete!"
echo "========================="
print_success "AI Town is running in Docker!"
echo ""
echo "📱 Access points:"
echo "  Frontend:  http://localhost:5173"
echo "  Backend:   http://localhost:3210"
echo "  Dashboard: http://localhost:6791"
echo ""
echo "🔑 Admin key for dashboard:"
echo "  $ADMIN_KEY"
echo ""
echo "🔧 Useful commands:"
echo "  docker compose logs frontend   # Frontend logs"
echo "  docker compose logs backend    # Backend logs"
echo "  docker compose stop           # Stop services"
echo "  docker compose down           # Stop and remove"
echo ""
echo "🧪 To start developing:"
echo "  npm run dev:backend    # Connect to Docker backend"