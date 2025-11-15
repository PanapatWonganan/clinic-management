# 🚀 Deployment Guide - Clinic Management System

## 📋 Table of Contents
1. [Project Structure](#project-structure)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Backend Deployment](#backend-deployment)
5. [Frontend Deployment](#frontend-deployment)
6. [Update Workflow](#update-workflow)
7. [Troubleshooting](#troubleshooting)

---

## 🏗️ Project Structure

```
project/
├── clinic-backend/          # Laravel API (api.exquiller.com)
│   ├── app/
│   ├── config/
│   ├── database/
│   ├── routes/
│   └── ...
├── lib/                     # Flutter Frontend
├── web/                     # Flutter Web Build Output
├── deploy-backend.sh        # Backend deployment script
├── deploy-frontend.sh       # Frontend deployment script
└── .github/workflows/       # GitHub Actions (auto-deploy)
```

**Domains:**
- Frontend: `exquiller.com`
- Backend API: `api.exquiller.com`

---

## ✅ Prerequisites

### On Your Server (via SSH)

#### 1. Web Server
- **Nginx** or **Apache**
- PHP >= 8.1
- Composer
- Node.js & npm (for Laravel Mix if needed)

#### 2. Database
- MySQL/MariaDB or PostgreSQL

#### 3. Required PHP Extensions
```bash
php -m | grep -E 'pdo|mbstring|xml|ctype|json|tokenizer|openssl|fileinfo|bcmath|curl'
```

#### 4. Git
```bash
git --version
```

#### 5. SSL Certificates
- Let's Encrypt (Certbot) for HTTPS

### On Your Local Machine

1. **Git** configured
2. **SSH access** to your server
3. **GitHub account** with repo access

---

## 🎯 Initial Setup

### Step 1: Create GitHub Repository

```bash
# In your local project
cd "/Users/janejiramalai/Downloads/project 2"

# Initialize git (if not already)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit - Clinic Management System"

# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/clinic-management.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 2: Server Directory Structure

SSH into your server and create directories:

```bash
ssh user@your-server

# Create directories
sudo mkdir -p /var/www/exquiller.com
sudo mkdir -p /var/www/api.exquiller.com

# Set ownership
sudo chown -R $USER:$USER /var/www/exquiller.com
sudo chown -R $USER:$USER /var/www/api.exquiller.com
```

### Step 3: Clone Repository on Server

```bash
# Clone to a deployment directory
cd ~
git clone https://github.com/YOUR_USERNAME/clinic-management.git deployment

# Or if using SSH
git clone git@github.com:YOUR_USERNAME/clinic-management.git deployment
```

---

## 🔧 Backend Deployment (api.exquiller.com)

### Manual Deployment (First Time)

```bash
# SSH to server
ssh user@your-server

# Navigate to deployment directory
cd ~/deployment/clinic-backend

# Install dependencies
composer install --optimize-autoloader --no-dev

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure .env file
nano .env
```

### Required .env Configuration

```env
APP_NAME="Clinic Management"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.exquiller.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password

# Payment Gateway
PAYSOLUTIONS_TEST_MODE=false
PAYSOLUTIONS_API_KEY=your_production_key
PAYSOLUTIONS_SECRET_KEY=your_secret
PAYSOLUTIONS_MERCHANT_ID=your_merchant_id
PAYSOLUTIONS_CALLBACK_URL=https://api.exquiller.com/api/payment/callback
PAYSOLUTIONS_RETURN_URL=https://exquiller.com/payment/success

# Telegram
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id

# Queue
QUEUE_CONNECTION=database
```

### Database Migration

```bash
# Run migrations
php artisan migrate --force

# Run seeders (if needed)
php artisan db:seed --force
```

### File Permissions

```bash
# Set proper permissions
chmod -R 755 /var/www/api.exquiller.com
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### Symlink to Public Directory

```bash
# Create symlink from deployment to web root
ln -sf ~/deployment/clinic-backend/public /var/www/api.exquiller.com/current

# Or copy files
rsync -av ~/deployment/clinic-backend/ /var/www/api.exquiller.com/ --exclude=.git
```

### Setup Queue Worker

Create supervisor configuration:

```bash
sudo nano /etc/supervisor/conf.d/clinic-queue.conf
```

```ini
[program:clinic-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/api.exquiller.com/artisan queue:work --queue=high,default --tries=3 --timeout=90
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/api.exquiller.com/storage/logs/queue-worker.log
stopwaitsecs=3600
```

```bash
# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start clinic-queue:*
```

### Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/api.exquiller.com
```

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name api.exquiller.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.exquiller.com;

    root /var/www/api.exquiller.com/public;
    index index.php index.html;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.exquiller.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.exquiller.com/privkey.pem;

    # Logs
    access_log /var/log/nginx/api.exquiller.com-access.log;
    error_log /var/log/nginx/api.exquiller.com-error.log;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # PHP-FPM
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # File upload limit
    client_max_body_size 50M;
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/api.exquiller.com /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

---

## 🎨 Frontend Deployment (exquiller.com)

### Build Flutter Web

```bash
# On your local machine or server
cd ~/deployment

# Build for web with proper base href
flutter build web --release --base-href="/" --web-renderer canvaskit

# The output will be in build/web/
```

### Deploy to Server

```bash
# Copy build files to web root
rsync -av build/web/ /var/www/exquiller.com/ --delete

# Or use SCP from local
scp -r build/web/* user@your-server:/var/www/exquiller.com/
```

### Configure API URL

Before building, update API URL in Flutter:

```dart
// lib/config/api_config.dart or wherever you define API URL
class ApiConfig {
  static const String baseUrl = 'https://api.exquiller.com';
}
```

### Nginx Configuration for Frontend

```bash
sudo nano /etc/nginx/sites-available/exquiller.com
```

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name exquiller.com www.exquiller.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name exquiller.com www.exquiller.com;

    root /var/www/exquiller.com;
    index index.html;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/exquiller.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/exquiller.com/privkey.pem;

    # Logs
    access_log /var/log/nginx/exquiller.com-access.log;
    error_log /var/log/nginx/exquiller.com-error.log;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Flutter Web routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/exquiller.com /etc/nginx/sites-enabled/

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 Update Workflow (After Initial Setup)

### Using Deployment Scripts

See `deploy-backend.sh` and `deploy-frontend.sh` in the project root.

### Manual Update Process

#### Update Backend:

```bash
# SSH to server
ssh user@your-server

# Navigate to deployment directory
cd ~/deployment

# Pull latest changes
git pull origin main

# Update backend
cd clinic-backend
composer install --optimize-autoloader --no-dev
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan queue:restart

# Copy to production (if using symlink approach)
rsync -av --exclude=.git ~/deployment/clinic-backend/ /var/www/api.exquiller.com/

# Restart services
sudo supervisorctl restart clinic-queue:*
sudo systemctl reload php8.1-fpm
```

#### Update Frontend:

```bash
# On local or server
cd ~/deployment

# Pull latest changes
git pull origin main

# Build Flutter web
flutter build web --release --base-href="/" --web-renderer canvaskit

# Deploy
rsync -av build/web/ /var/www/exquiller.com/ --delete
```

### Using GitHub Actions (Recommended)

GitHub Actions will automatically deploy when you push to main branch.
See `.github/workflows/deploy.yml` for configuration.

To deploy:

```bash
# On your local machine
git add .
git commit -m "Your commit message"
git push origin main

# GitHub Actions will automatically:
# 1. Run tests
# 2. Build frontend
# 3. Deploy backend via SSH
# 4. Deploy frontend via SSH
```

---

## 🐛 Troubleshooting

### Backend Issues

#### 500 Error
```bash
# Check Laravel logs
tail -f /var/www/api.exquiller.com/storage/logs/laravel.log

# Check PHP-FPM logs
tail -f /var/log/php8.1-fpm.log

# Check Nginx logs
tail -f /var/log/nginx/api.exquiller.com-error.log
```

#### Permission Issues
```bash
cd /var/www/api.exquiller.com
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

#### Queue Not Processing
```bash
# Check supervisor status
sudo supervisorctl status clinic-queue:*

# Restart queue
sudo supervisorctl restart clinic-queue:*

# Check queue logs
tail -f /var/www/api.exquiller.com/storage/logs/queue-worker.log
```

### Frontend Issues

#### Blank Page
- Check browser console for errors
- Verify API URL is correct in `lib/config/api_config.dart`
- Check nginx error logs

#### CORS Issues
Add to Laravel `config/cors.php`:
```php
'allowed_origins' => ['https://exquiller.com'],
```

### SSL Certificate Renewal

```bash
# Auto-renewal is usually setup, but manual renewal:
sudo certbot renew
sudo systemctl reload nginx
```

---

## 📞 Support

For issues:
1. Check logs first
2. Review this guide
3. Check Laravel documentation
4. Check Flutter Web documentation

---

## 🔐 Security Checklist

- [ ] `.env` file is not in Git repository
- [ ] `APP_DEBUG=false` in production
- [ ] Strong database passwords
- [ ] SSL certificates installed and auto-renewing
- [ ] File permissions set correctly
- [ ] Firewall configured (allow 22, 80, 443)
- [ ] Regular backups scheduled
- [ ] Payment gateway in production mode with real credentials

---

## 📝 Notes

- Always test in staging environment first
- Keep backups before major updates
- Monitor error logs regularly
- Update dependencies regularly for security patches
