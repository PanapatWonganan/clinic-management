#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Server Setup for Clinic Management   ${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Update system
echo -e "${YELLOW}➤ Updating system...${NC}"
apt update && apt upgrade -y

# Install essential packages
echo -e "${YELLOW}➤ Installing essential packages...${NC}"
apt install -y nginx mysql-server git curl zip unzip software-properties-common ufw

# Install PHP 8.3
echo -e "${YELLOW}➤ Installing PHP 8.3...${NC}"
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.3 php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl php8.3-dom

# Install Composer
echo -e "${YELLOW}➤ Installing Composer...${NC}"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Setup MySQL
echo -e "${YELLOW}➤ Setting up MySQL...${NC}"
mysql -e "CREATE DATABASE IF NOT EXISTS clinic_db;"
mysql -e "CREATE USER IF NOT EXISTS 'clinic_user'@'localhost' IDENTIFIED BY 'clinic_password_123';"
mysql -e "GRANT ALL PRIVILEGES ON clinic_db.* TO 'clinic_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Setup Firewall
echo -e "${YELLOW}➤ Configuring firewall...${NC}"
ufw allow 22
ufw allow 80
ufw allow 443
echo "y" | ufw enable

# Create directories
echo -e "${YELLOW}➤ Creating directories...${NC}"
mkdir -p /var/www/api.exquiller.com
mkdir -p /var/www/exquiller.com

# Clone repository
echo -e "${YELLOW}➤ Cloning repository...${NC}"
if [ ! -d "/root/clinic-management" ]; then
    cd /root
    git clone https://github.com/PanapatWonganan/clinic-management.git
fi

# Setup Backend
echo -e "${YELLOW}➤ Setting up Laravel backend...${NC}"
cd /root/clinic-management/clinic-backend

# Install dependencies
COMPOSER_ALLOW_SUPERUSER=1 composer install --optimize-autoloader --no-dev

# Copy .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    php artisan key:generate
fi

# Update .env with database credentials
sed -i 's/DB_DATABASE=.*/DB_DATABASE=clinic_db/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=clinic_user/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=clinic_password_123/' .env

# Run migrations
php artisan migrate --force

# Copy to production directory
rsync -av --delete /root/clinic-management/clinic-backend/ /var/www/api.exquiller.com/

# Set permissions
chown -R www-data:www-data /var/www/api.exquiller.com
chmod -R 755 /var/www/api.exquiller.com
chmod -R 775 /var/www/api.exquiller.com/storage
chmod -R 775 /var/www/api.exquiller.com/bootstrap/cache

# Create storage link
cd /var/www/api.exquiller.com
php artisan storage:link

# Nginx configuration for Backend
echo -e "${YELLOW}➤ Creating Nginx config for backend...${NC}"
cat > /etc/nginx/sites-available/api.exquiller.com << 'EOF'
server {
    listen 80;
    server_name api.exquiller.com;
    root /var/www/api.exquiller.com/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Nginx configuration for Frontend
echo -e "${YELLOW}➤ Creating Nginx config for frontend...${NC}"
cat > /etc/nginx/sites-available/exquiller.com << 'EOF'
server {
    listen 80;
    server_name exquiller.com www.exquiller.com;
    root /var/www/exquiller.com;

    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable sites
ln -sf /etc/nginx/sites-available/api.exquiller.com /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/exquiller.com /etc/nginx/sites-enabled/

# Remove default
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
echo -e "${YELLOW}➤ Reloading Nginx...${NC}"
nginx -t
systemctl restart nginx

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Completed Successfully! ✅${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Update /var/www/api.exquiller.com/.env with your settings"
echo -e "2. Install SSL: certbot --nginx -d api.exquiller.com -d exquiller.com"
echo -e "3. Deploy frontend: cd /root/clinic-management && flutter build web && rsync -av build/web/ /var/www/exquiller.com/"
echo -e "\n${GREEN}Database credentials:${NC}"
echo -e "Database: clinic_db"
echo -e "Username: clinic_user"
echo -e "Password: clinic_password_123"
