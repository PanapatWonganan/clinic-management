#!/bin/bash

###############################################################################
# Backend Deployment Script - api.exquiller.com
#
# This script deploys the Laravel backend to production server
#
# Usage: ./deploy-backend.sh
###############################################################################

set -e  # Exit on error

# Configuration
SERVER_USER="your-server-user"
SERVER_HOST="your-server-ip-or-domain"
SERVER_PATH="/var/www/api.exquiller.com"
REPO_PATH="$HOME/deployment"
BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backend Deployment Script${NC}"
echo -e "${GREEN}  Target: api.exquiller.com${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if we can connect to server
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

# Deploy backend via SSH
echo -e "${YELLOW}➤ Deploying backend to server...${NC}"

ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_PATH="$HOME/deployment"
SERVER_PATH="/var/www/api.exquiller.com"
BRANCH="main"

echo -e "${YELLOW}➤ Navigating to deployment directory...${NC}"
cd "$REPO_PATH"

echo -e "${YELLOW}➤ Pulling latest changes from GitHub...${NC}"
git fetch origin
git reset --hard origin/$BRANCH
echo -e "${GREEN}✓ Code updated${NC}"

echo -e "${YELLOW}➤ Installing Composer dependencies...${NC}"
cd clinic-backend
composer install --optimize-autoloader --no-dev --no-interaction
echo -e "${GREEN}✓ Composer dependencies installed${NC}"

echo -e "${YELLOW}➤ Running database migrations...${NC}"
php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed${NC}"

echo -e "${YELLOW}➤ Clearing and caching configuration...${NC}"
php artisan config:clear
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo -e "${GREEN}✓ Cache cleared and rebuilt${NC}"

echo -e "${YELLOW}➤ Syncing files to production directory...${NC}"
rsync -av \
    --exclude=.git \
    --exclude=node_modules \
    --exclude=.env.example \
    --exclude=tests \
    --delete \
    "$REPO_PATH/clinic-backend/" "$SERVER_PATH/"
echo -e "${GREEN}✓ Files synced${NC}"

echo -e "${YELLOW}➤ Creating storage symlink...${NC}"
cd "$SERVER_PATH"
php artisan storage:link
echo -e "${GREEN}✓ Storage symlink created${NC}"

echo -e "${YELLOW}➤ Setting file permissions...${NC}"
sudo chown -R www-data:www-data storage bootstrap/cache public/storage
sudo chmod -R 775 storage bootstrap/cache
sudo chmod -R 755 public/storage
echo -e "${GREEN}✓ Permissions set${NC}"

echo -e "${YELLOW}➤ Restarting queue workers...${NC}"
php artisan queue:restart
if command -v supervisorctl &> /dev/null; then
    sudo supervisorctl restart clinic-queue:* || echo "Note: Supervisor not configured or queue workers not running"
fi
echo -e "${GREEN}✓ Queue workers restarted${NC}"

echo -e "${YELLOW}➤ Reloading PHP-FPM...${NC}"
if [ -f /etc/init.d/php8.1-fpm ]; then
    sudo systemctl reload php8.1-fpm
elif [ -f /etc/init.d/php8.2-fpm ]; then
    sudo systemctl reload php8.2-fpm
else
    echo -e "${YELLOW}⚠ PHP-FPM not found, skipping reload${NC}"
fi
echo -e "${GREEN}✓ PHP-FPM reloaded${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backend Deployment Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"

ENDSSH

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Backend URL: https://api.exquiller.com"
echo -e "Status: ${GREEN}Deployed${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Test API endpoints"
echo -e "  2. Check error logs: ssh $SERVER_USER@$SERVER_HOST 'tail -f $SERVER_PATH/storage/logs/laravel.log'"
echo -e "  3. Monitor queue: ssh $SERVER_USER@$SERVER_HOST 'sudo supervisorctl status clinic-queue:*'"
echo ""
