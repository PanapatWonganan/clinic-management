#!/bin/bash

###############################################################################
# Frontend Deployment Script - exquiller.com
#
# This script builds and deploys the Flutter Web frontend to production server
#
# Usage: ./deploy-frontend.sh
###############################################################################

set -e  # Exit on error

# Configuration
SERVER_USER="your-server-user"
SERVER_HOST="your-server-ip-or-domain"
SERVER_PATH="/var/www/exquiller.com"
REPO_PATH="$HOME/deployment"
BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Frontend Deployment Script${NC}"
echo -e "${GREEN}  Target: exquiller.com${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Flutter is installed
echo -e "${YELLOW}➤ Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    echo -e "${RED}  Please install Flutter: https://flutter.dev/docs/get-started/install${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -n1)${NC}"
echo ""

# Check server connection
echo -e "${YELLOW}➤ Checking server connection...${NC}"
if ! ssh -o ConnectTimeout=5 "$SERVER_USER@$SERVER_HOST" "echo 'Connected'" &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to server. Please check:${NC}"
    echo -e "${RED}  - SERVER_USER and SERVER_HOST in this script${NC}"
    echo -e "${RED}  - SSH key is configured${NC}"
    echo -e "${RED}  - Server is accessible${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Server connection successful${NC}"
echo ""

# Option to build locally or on server
echo -e "${YELLOW}Where do you want to build Flutter Web?${NC}"
echo -e "  1) Local machine (faster if you have good internet)"
echo -e "  2) On server (recommended for consistency)"
read -p "Choose option [1-2]: " BUILD_OPTION

if [ "$BUILD_OPTION" = "1" ]; then
    #############################
    # BUILD LOCALLY
    #############################

    echo ""
    echo -e "${YELLOW}➤ Building Flutter Web locally...${NC}"

    # Get Flutter dependencies
    echo -e "${YELLOW}  - Getting Flutter dependencies...${NC}"
    flutter pub get

    # Build for web
    echo -e "${YELLOW}  - Building for production...${NC}"
    flutter build web --release --base-href="/" --web-renderer canvaskit

    echo -e "${GREEN}✓ Build completed${NC}"

    # Deploy to server
    echo -e "${YELLOW}➤ Deploying to server...${NC}"

    echo -e "${YELLOW}  - Creating backup...${NC}"
    ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH.backup && rsync -a $SERVER_PATH/ $SERVER_PATH.backup/" || true

    echo -e "${YELLOW}  - Uploading files...${NC}"
    rsync -avz --delete build/web/ "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

    echo -e "${GREEN}✓ Files uploaded${NC}"

else
    #############################
    # BUILD ON SERVER
    #############################

    echo ""
    echo -e "${YELLOW}➤ Building and deploying on server...${NC}"

    ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_PATH="$HOME/deployment"
SERVER_PATH="/var/www/exquiller.com"
BRANCH="main"

echo -e "${YELLOW}➤ Navigating to deployment directory...${NC}"
cd "$REPO_PATH"

echo -e "${YELLOW}➤ Pulling latest changes from GitHub...${NC}"
git fetch origin
git reset --hard origin/$BRANCH
echo -e "${GREEN}✓ Code updated${NC}"

echo -e "${YELLOW}➤ Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo -e "${YELLOW}➤ Building Flutter Web for production...${NC}"
flutter build web --release --base-href="/" --web-renderer canvaskit
echo -e "${GREEN}✓ Build completed${NC}"

echo -e "${YELLOW}➤ Creating backup...${NC}"
mkdir -p "$SERVER_PATH.backup"
rsync -a "$SERVER_PATH/" "$SERVER_PATH.backup/" || true
echo -e "${GREEN}✓ Backup created${NC}"

echo -e "${YELLOW}➤ Deploying to production directory...${NC}"
rsync -av --delete build/web/ "$SERVER_PATH/"
echo -e "${GREEN}✓ Files deployed${NC}"

echo -e "${YELLOW}➤ Setting file permissions...${NC}"
sudo chown -R www-data:www-data "$SERVER_PATH"
sudo chmod -R 755 "$SERVER_PATH"
echo -e "${GREEN}✓ Permissions set${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Frontend Deployment Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"

ENDSSH

fi

# Verify deployment
echo ""
echo -e "${YELLOW}➤ Verifying deployment...${NC}"
ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
SERVER_PATH="/var/www/exquiller.com"

if [ -f "$SERVER_PATH/index.html" ]; then
    echo -e "${GREEN}✓ index.html found${NC}"
else
    echo -e "${RED}✗ index.html not found!${NC}"
    exit 1
fi

if [ -d "$SERVER_PATH/assets" ]; then
    echo -e "${GREEN}✓ assets directory found${NC}"
else
    echo -e "${YELLOW}⚠ assets directory not found${NC}"
fi

ENDSSH

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Frontend URL: https://exquiller.com"
echo -e "Status: ${GREEN}Deployed${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Open https://exquiller.com in your browser"
echo -e "  2. Test the application"
echo -e "  3. Check browser console for any errors"
echo -e "  4. Verify API connectivity"
echo ""
echo -e "${GREEN}Rollback command (if needed):${NC}"
echo -e "  ssh $SERVER_USER@$SERVER_HOST 'rsync -av $SERVER_PATH.backup/ $SERVER_PATH/'"
echo ""
