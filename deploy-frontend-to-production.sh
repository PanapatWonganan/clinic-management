#!/bin/bash

# Deploy Frontend to Production Server
# Usage: ./deploy-frontend-to-production.sh

set -e  # Exit on error

# Configuration
SERVER="root@45.32.102.242"
BUILD_FILE="frontend-build.tar.gz"
WEB_ROOT="/var/www/exquillermember.com"
BACKUP_DIR="/var/www/backups"

echo "🚀 Starting Frontend Deployment to Production..."
echo ""

# Check if build file exists
if [ ! -f "$BUILD_FILE" ]; then
    echo "❌ Error: $BUILD_FILE not found!"
    echo "   Please run 'flutter build web --release' first."
    exit 1
fi

echo "📦 Build file found: $BUILD_FILE"
BUILD_SIZE=$(du -h "$BUILD_FILE" | cut -f1)
echo "   Size: $BUILD_SIZE"
echo ""

# Upload to server
echo "⬆️  Uploading build to server..."
scp "$BUILD_FILE" "$SERVER:~/" || {
    echo "❌ Failed to upload build file!"
    exit 1
}
echo "✅ Upload completed!"
echo ""

# Deploy on server
echo "🔧 Deploying on production server..."
ssh "$SERVER" << 'ENDSSH'
set -e

BUILD_FILE="frontend-build.tar.gz"
WEB_ROOT="/var/www/exquillermember.com"
BACKUP_DIR="/var/www/backups"

echo "📋 Creating backup..."
BACKUP_NAME="exquillermember.com.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$WEB_ROOT" "$BACKUP_DIR/$BACKUP_NAME"
echo "   Backup saved: $BACKUP_DIR/$BACKUP_NAME"

echo "🗑️  Cleaning current deployment..."
rm -rf "$WEB_ROOT"/*

echo "📦 Extracting new build..."
mkdir -p "$WEB_ROOT"
tar -xzf ~/"$BUILD_FILE" -C "$WEB_ROOT/"

echo "🔒 Setting permissions..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "🧹 Cleaning up..."
rm ~/"$BUILD_FILE"

echo "🔄 Restarting Nginx..."
systemctl restart nginx

echo "✅ Frontend deployment completed!"
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deployment successful!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Clear Laravel cache on server:"
    echo "      ssh $SERVER 'cd ~/deployment/clinic-backend && php artisan view:clear && php artisan cache:clear'"
    echo ""
    echo "   2. Test the website:"
    echo "      https://exquillermember.com"
    echo ""
    echo "   3. Clear browser cache (Hard refresh):"
    echo "      - Mac: Cmd+Shift+R"
    echo "      - Windows/Linux: Ctrl+Shift+R"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi
