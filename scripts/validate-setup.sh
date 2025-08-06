#!/bin/bash

echo "🔍 AI Town Fly.io Setup Validation"
echo "=================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
    else
        echo -e "${RED}✗${NC} $1 missing"
        ((ERRORS++))
    fi
}

check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 is executable"
    else
        echo -e "${RED}✗${NC} $1 is not executable"
        ((ERRORS++))
    fi
}

echo ""
echo "📁 Checking required files..."

check_file "scripts/deploy-to-fly.sh"
check_file "scripts/setup-fly-secrets.sh"
check_file "docs/FLY_DEPLOYMENT.md"
check_file "fly.template.toml"
check_file "Dockerfile"
check_file ".dockerignore"
check_file "vite.config.ts"
check_file "package.json"
check_file "README.md"

echo ""
echo "🔧 Checking script permissions..."

check_executable "scripts/deploy-to-fly.sh"
check_executable "scripts/setup-fly-secrets.sh"

echo ""
echo "📋 Checking script syntax..."

if bash -n scripts/deploy-to-fly.sh; then
    echo -e "${GREEN}✓${NC} deploy-to-fly.sh syntax is valid"
else
    echo -e "${RED}✗${NC} deploy-to-fly.sh has syntax errors"
    ((ERRORS++))
fi

if bash -n scripts/setup-fly-secrets.sh; then
    echo -e "${GREEN}✓${NC} setup-fly-secrets.sh syntax is valid"
else
    echo -e "${RED}✗${NC} setup-fly-secrets.sh has syntax errors"
    ((ERRORS++))
fi

echo ""
echo "📦 Checking package.json scripts..."

if grep -q '"preview"' package.json; then
    echo -e "${GREEN}✓${NC} preview script exists in package.json"
else
    echo -e "${RED}✗${NC} preview script missing from package.json"
    ((ERRORS++))
fi

echo ""
echo "🐳 Checking Docker configuration..."

if grep -q "CMD.*preview" Dockerfile; then
    echo -e "${GREEN}✓${NC} Dockerfile uses optimized production command"
else
    echo -e "${RED}✗${NC} Dockerfile may not be optimized"
    ((ERRORS++))
fi

if grep -q "node:18-alpine" Dockerfile; then
    echo -e "${GREEN}✓${NC} Dockerfile uses Alpine base image"
else
    echo -e "${RED}✗${NC} Dockerfile not using recommended Alpine image"
    ((ERRORS++))
fi

echo ""
echo "📖 Checking documentation..."

if grep -q "Deploy on Fly.io" README.md; then
    echo -e "${GREEN}✓${NC} README.md contains Fly.io deployment section"
else
    echo -e "${RED}✗${NC} README.md missing Fly.io deployment section"
    ((ERRORS++))
fi

if [ -s "docs/FLY_DEPLOYMENT.md" ]; then
    echo -e "${GREEN}✓${NC} FLY_DEPLOYMENT.md has content"
else
    echo -e "${RED}✗${NC} FLY_DEPLOYMENT.md is empty or missing"
    ((ERRORS++))
fi

echo ""
echo "🌐 Checking Vite configuration..."

if grep -q "host: true" vite.config.ts; then
    echo -e "${GREEN}✓${NC} Vite configured for Fly.io hosting"
else
    echo -e "${RED}✗${NC} Vite not configured for Fly.io"
    ((ERRORS++))
fi

if grep -q ".fly.dev" vite.config.ts; then
    echo -e "${GREEN}✓${NC} Vite allows Fly.io domains"
else
    echo -e "${RED}✗${NC} Vite may not allow Fly.io domains"
    ((ERRORS++))
fi

echo ""
echo "=================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Setup is complete and ready for deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Push to GitHub: git add . && git commit -m 'Complete Fly.io setup' && git push"
    echo "2. Test deployment: ./scripts/deploy-to-fly.sh"
    echo "3. Read full docs: docs/FLY_DEPLOYMENT.md"
else
    echo -e "${RED}❌ $ERRORS errors found. Please fix them before deploying.${NC}"
    exit 1
fi