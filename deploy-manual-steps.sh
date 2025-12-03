#!/bin/bash

# Manual Deployment Steps - Run these commands on PRODUCTION SERVER
# SSH into server first: ssh root@45.32.102.242

echo "==================================================================="
echo "  MANUAL DEPLOYMENT SCRIPT"
echo "  Copy these commands and paste into SSH terminal on production"
echo "==================================================================="
echo ""
echo "# Step 1: Commit and push build to GitHub"
echo "git add frontend-build.tar.gz"
echo "git commit -m 'Update frontend build with image fixes'"
echo "git push origin main"
echo ""
echo "==================================================================="
echo "# Step 2: SSH into production server"
echo "ssh root@45.32.102.242"
echo ""
echo "==================================================================="
echo "# Step 3: Run these commands ON THE SERVER:"
echo "==================================================================="
echo ""
cat << 'SERVER_COMMANDS'
# Navigate to deployment directory
cd ~/deployment

# Pull latest code (includes frontend-build.tar.gz)
git pull origin main

# Backup current frontend
BACKUP_NAME="exquillermember.com.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p /var/www/backups
cp -r /var/www/exquillermember.com "/var/www/backups/$BACKUP_NAME"
echo "✅ Backup saved: /var/www/backups/$BACKUP_NAME"

# Clear current deployment
rm -rf /var/www/exquillermember.com/*

# Extract new build
tar -xzf frontend-build.tar.gz -C /var/www/exquillermember.com/

# Set permissions
chown -R www-data:www-data /var/www/exquillermember.com
chmod -R 755 /var/www/exquillermember.com

# Clear backend cache
cd ~/deployment/clinic-backend
php artisan view:clear
php artisan cache:clear
php artisan config:clear

# Restart Nginx
systemctl restart nginx

echo "✅ Deployment completed!"
echo "🌐 Test at: https://exquillermember.com"
SERVER_COMMANDS

echo ""
echo "==================================================================="
echo "  After deployment, test:"
echo "  1. Open: https://exquillermember.com"
echo "  2. Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)"
echo "  3. Check if images display correctly"
echo "==================================================================="
