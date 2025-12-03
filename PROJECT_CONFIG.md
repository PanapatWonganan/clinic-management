# 🔥 PROJECT CONFIGURATION - อ่านทุกครั้งก่อนทำงาน! 🔥

## Server Information
- **Server IP**: `45.32.102.242`
- **SSH User**: `root`
- **SSH Key**: `~/.ssh/github_actions_deploy`

## Production URLs
- **Frontend**: https://exquillermember.com
- **Backend API**: https://api.exquillermember.com

## Server Paths (บน Production Server)
- **Frontend Path**: `/var/www/exquillermember.com`
- **Backend Path**: `/var/www/api.exquillermember.com`
- **Deployment Directory**: `~/deployment` (repo clone อยู่ที่นี่)

## Database Credentials
- **Database Name**: `clinic_db`
- **Username**: `clinic_user`
- **Password**: `clinic_password_123`

## Important Nginx Configs
- **Frontend Config**: `/etc/nginx/sites-available/exquillermember.com`
- **Backend Config**: `/etc/nginx/sites-available/api.exquillermember.com`

## PHP Version
- **PHP**: 8.3
- **PHP-FPM Socket**: `/var/run/php/php8.3-fpm.sock`

## Deployment Flow
1. Local: Build → Push to GitHub
2. Server: Pull → Deploy → Restart services
3. Files: `frontend-build.tar.gz` และ `product-images.tar.gz`

## Quick SSH Command
```bash
ssh root@45.32.102.242
```

## ⚠️ NEVER FORGET ⚠️
- Backend อยู่ที่ `/var/www/api.exquillermember.com` **ไม่ใช่** api.exquiller.com
- Frontend อยู่ที่ `/var/www/exquillermember.com` **ไม่ใช่** exquiller.com
- ทุกอย่างใช้ domain **exquillermember.com** ไม่ใช่ exquiller.com!
