# 🚀 DEPLOYMENT NOTES - อ่านทุกครั้งก่อน Deploy!

## ⚠️ ข้อควรระวัง - อย่าลืม!

### 1. รูปภาพสินค้าบน Production
หลังจาก upload รูปสินค้าหรือ extract tar.gz ต้องรัน:

```bash
# Fix permissions ทุกครั้ง!
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage/
sudo chmod -R 775 /var/www/api.exquillermember.com/storage/
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/public/storage/
sudo chmod -R 755 /var/www/api.exquillermember.com/public/storage/
```

**สาเหตุ:** ไฟล์จาก macOS มีเป็น owner `501 staff` ทำให้ Nginx (www-data) อ่านไม่ได้

### 2. Storage Symlink
ถ้ารูปโหลดไม่ขึ้น ให้เช็ค symlink:

```bash
cd /var/www/api.exquillermember.com
php artisan storage:link
```

### 3. Git Version ที่ใช้งานได้ดี
**Current Working Version:** `9c6db16` (Fix membership progress bar auto-reload and bundle deal seeder)

**ไฟล์ที่แก้ในเวอร์ชั่นนี้:**
- ✅ รูปภาพสินค้าแสดงถูกต้อง (Order History + Home)
- ✅ Progress bar auto-reload หลัง checkout
- ✅ Backend seeder ใช้งานได้
- ✅ ไม่มี logo ใหม่ (ใช้ Flutter default)

**ห้ามทำ:**
- ❌ อย่า reset ไป commit ก่อนหน้า d7a523d (จะทำให้รูปหาย)
- ❌ อย่าเพิ่ม logo ใหม่โดยไม่ทดสอบให้ดีก่อน
- ❌ อย่า push code ใหม่โดยไม่ build + test ใน local ก่อน

---

## 📋 Deployment Checklist

### Deploy Frontend
```bash
# 1. SSH เข้า server
ssh root@45.32.102.242

# 2. Pull code
cd ~/deployment
git pull origin main

# 3. Extract frontend
tar -xzf frontend-production.tar.gz -C /var/www/exquillermember.com/
sudo chown -R www-data:www-data /var/www/exquillermember.com
sudo chmod -R 755 /var/www/exquillermember.com

# 4. Restart Nginx
sudo systemctl restart nginx
```

### Deploy Backend
```bash
# 1. Pull code
cd ~/deployment/clinic-backend
git pull origin main

# 2. Install dependencies
composer install --optimize-autoloader --no-dev

# 3. Sync to production
rsync -av --exclude=.git --exclude=.env ~/deployment/clinic-backend/ /var/www/api.exquillermember.com/

# 4. Fix permissions
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage/
sudo chmod -R 775 /var/www/api.exquillermember.com/storage/
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/bootstrap/cache
sudo chmod -R 775 /var/www/api.exquillermember.com/bootstrap/cache

# 5. Clear cache
cd /var/www/api.exquillermember.com
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# 6. Restart services
sudo systemctl restart php8.3-fpm
sudo supervisorctl restart laravel-worker:*
```

---

## 🔧 Common Issues & Solutions

### ปัญหา: รูปภาพไม่แสดง
```bash
# เช็ค permissions
ls -la /var/www/api.exquillermember.com/public/storage/products/

# ต้องเป็น www-data www-data
# ถ้าไม่ใช่ ให้รัน:
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage/
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/public/storage/

# เช็คว่าเข้าถึงได้หรือไม่
curl -I https://api.exquillermember.com/storage/products/1758125702_product1.png
```

### ปัญหา: Backend HTTP 500
```bash
# เช็ค Laravel log
tail -50 /var/www/api.exquillermember.com/storage/logs/laravel.log

# เช็ค Nginx error log
tail -50 /var/log/nginx/error.log

# มักเกิดจาก permissions หรือ cache
```

### ปัญหา: Telegram ไม่ส่ง
```bash
# เช็ค queue worker
sudo supervisorctl status

# ถ้า stopped ให้ start
sudo supervisorctl start laravel-worker:*

# เช็ค log
tail -f /var/www/api.exquillermember.com/storage/logs/worker.log
```

---

## 📞 Server Info

- **Server IP:** 45.32.102.242
- **SSH User:** root
- **Frontend:** https://exquillermember.com → `/var/www/exquillermember.com`
- **Backend:** https://api.exquillermember.com → `/var/www/api.exquillermember.com`
- **Deployment Repo:** `~/deployment`

### Database
- **Name:** clinic_db
- **User:** clinic_user
- **Password:** clinic_password_123

### Telegram
- **Bot Token:** (เก็บใน .env)
- **Chat ID:** (เก็บใน .env)

---

## ⚡ Quick Commands

```bash
# SSH
ssh root@45.32.102.242

# Restart All Services
sudo systemctl restart nginx && sudo systemctl restart php8.3-fpm && sudo supervisorctl restart laravel-worker:*

# Check Logs
tail -f /var/www/api.exquillermember.com/storage/logs/laravel.log
tail -f /var/log/nginx/error.log
tail -f /var/www/api.exquillermember.com/storage/logs/worker.log

# Fix Permissions (รันทุกครั้งหลัง deploy!)
sudo chown -R www-data:www-data /var/www/api.exquillermember.com/storage/
sudo chmod -R 775 /var/www/api.exquillermember.com/storage/
sudo chown -R www-data:www-data /var/www/exquillermember.com
sudo chmod -R 755 /var/www/exquillermember.com
```

---

**Last Updated:** December 4, 2025
**Current Git Version:** 9c6db16
**Status:** ✅ Production Working - DO NOT CHANGE!
