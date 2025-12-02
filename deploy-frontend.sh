#!/bin/bash

# Script to build and deploy Flutter frontend to production

echo "🔨 Building Flutter web with production flag..."
flutter build web --release --dart-define=PRODUCTION=true

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"

    echo "📦 Deploying to /var/www/exquillermember.com..."
    rsync -av --delete build/web/ /var/www/exquillermember.com/

    echo "🔄 Restarting Nginx..."
    systemctl restart nginx

    echo "✅ Deployment completed!"
else
    echo "❌ Build failed!"
    exit 1
fi
