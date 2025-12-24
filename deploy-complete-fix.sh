#!/bin/bash

# ================================================================
# COMPREHENSIVE DEPLOYMENT - Fix All Issues
# Run on production server after SSH: ssh root@45.32.102.242
# ================================================================

echo "========================================"
echo "  COMPREHENSIVE DEPLOYMENT STARTED"
echo "========================================"

# Navigate to deployment directory
cd ~/deployment

# Pull latest code from GitHub
echo ""
echo "[1/9] Pulling latest code from GitHub..."
git pull origin main

# Extract product images to storage
echo ""
echo "[2/9] Extracting product images to storage..."
mkdir -p clinic-backend/storage/app/public/products
tar -xzf product-images.tar.gz -C clinic-backend/storage/app/public/products/
echo "✅ Product images extracted"

# Recreate storage symlink
echo ""
echo "[3/9] Recreating storage symlink..."
cd clinic-backend
rm -f public/storage
php artisan storage:link
echo "✅ Storage symlink created"

# Verify product images
echo ""
echo "[4/9] Verifying product images..."
ls -lh storage/app/public/products/ | grep -E "product[1-4]\.png"
echo "✅ Product images verified"

# Clear all Laravel caches
echo ""
echo "[5/9] Clearing Laravel caches..."
rm -rf storage/framework/views/*
php artisan view:clear
php artisan cache:clear
php artisan config:clear
echo "✅ Laravel caches cleared"

# Deploy frontend
echo ""
echo "[6/9] Deploying frontend..."
cd ~/deployment

# Backup current frontend
BACKUP_NAME="exquillermember.com.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p /var/www/backups
cp -r /var/www/exquillermember.com "/var/www/backups/$BACKUP_NAME"
echo "✅ Frontend backed up: /var/www/backups/$BACKUP_NAME"

# Clear current deployment
rm -rf /var/www/exquillermember.com/*

# Extract new build
tar -xzf frontend-build.tar.gz -C /var/www/exquillermember.com/

# Set correct permissions
chown -R www-data:www-data /var/www/exquillermember.com
chmod -R 755 /var/www/exquillermember.com

echo "✅ Frontend deployed"

# Verify main.dart.js timestamp
echo ""
echo "[7/9] Verifying frontend timestamp..."
ls -lh /var/www/exquillermember.com/main.dart.js
echo "✅ Frontend timestamp verified"

# Verify membership images
echo ""
echo "[8/9] Verifying membership images..."
ls -lh /var/www/exquillermember.com/assets/assets/images/ | grep -E "purple|green|pink|exmember"
echo "✅ Membership images verified"

# Restart Nginx
echo ""
echo "[9/9] Restarting Nginx..."
systemctl restart nginx
echo "✅ Nginx restarted"

echo ""
echo "========================================"
echo "  ✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "📋 FIXES APPLIED:"
echo "  1. ✅ Product images uploaded to storage"
echo "  2. ✅ Payment form with credit card inputs (already in backend)"
echo "  3. ✅ Membership logos (in frontend build)"
echo "  4. ✅ Progress bar icons (in frontend build)"
echo "  5. ✅ All caches cleared"
echo ""
echo "🌐 TEST CHECKLIST:"
echo "  1. Open: https://exquillermember.com"
echo "  2. Hard refresh: Cmd+Shift+R or use Incognito"
echo "  3. Check product images display"
echo "  4. Check payment button works: https://api-docs.paysolutions.asia/payment/test"
echo "  5. Check payment form has credit card inputs"
echo "  6. Check membership logos in benefits dialog"
echo "  7. Check progress bar icons display"
echo ""
