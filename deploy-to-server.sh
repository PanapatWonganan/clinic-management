#!/bin/bash

# Build and deploy Flutter web to production server

echo "🔨 Building Flutter web with production flag..."
flutter build web --release --dart-define=PRODUCTION=true

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    echo "📦 Deploying to production server..."
    rsync -avz --delete build/web/ root@45.32.102.242:/var/www/exquillermember.com/
    
    echo "✅ Deployment completed!"
    echo "🌐 Frontend: https://exquillermember.com"
else
    echo "❌ Build failed!"
    exit 1
fi
