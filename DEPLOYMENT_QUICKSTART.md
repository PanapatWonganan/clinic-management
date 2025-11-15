# 🚀 Deployment Quick Start

> **สำหรับ: exquiller.com & api.exquiller.com**

## 📦 ไฟล์ที่สำคัญ

- `DEPLOYMENT_GUIDE.md` - คู่มือ deployment แบบละเอียดทุกขั้นตอน
- `GITHUB_ACTIONS_SETUP.md` - วิธีตั้งค่า GitHub Actions สำหรับ auto-deploy
- `deploy-backend.sh` - Script สำหรับ deploy backend แบบ manual
- `deploy-frontend.sh` - Script สำหรับ deploy frontend แบบ manual
- `.github/workflows/deploy.yml` - GitHub Actions workflow

## 🎯 เลือกวิธี Deployment

### วิธีที่ 1: GitHub Actions (แนะนำ) ⭐

**ข้อดี:**
- Deploy อัตโนมัติเมื่อ push code
- ไม่ต้องรัน script manual
- มี log เก็บไว้ดูได้

**วิธีใช้:**
```bash
# 1. ตั้งค่า GitHub Actions ตาม GITHUB_ACTIONS_SETUP.md
# 2. Push code
git add .
git commit -m "Update feature X"
git push origin main

# ✅ ระบบจะ deploy อัตโนมัติ!
```

**Setup:** อ่าน `GITHUB_ACTIONS_SETUP.md`

---

### วิธีที่ 2: Deployment Scripts (Manual)

**ข้อดี:**
- Deploy ได้ทันที ไม่ต้องรอ setup GitHub Actions
- เหมาะสำหรับ testing

**วิธีใช้:**

#### Deploy Backend:
```bash
# 1. แก้ไขข้อมูล server ใน deploy-backend.sh
nano deploy-backend.sh
# เปลี่ยน SERVER_USER และ SERVER_HOST

# 2. รัน script
./deploy-backend.sh
```

#### Deploy Frontend:
```bash
# 1. แก้ไขข้อมูล server ใน deploy-frontend.sh
nano deploy-frontend.sh
# เปลี่ยน SERVER_USER และ SERVER_HOST

# 2. รัน script
./deploy-frontend.sh
```

---

## ⚡ Quick Setup Checklist

### บน Server:

```bash
# 1. Clone repository
cd ~
git clone https://github.com/YOUR_USERNAME/clinic-management.git deployment

# 2. สร้าง .env สำหรับ backend
cd ~/deployment/clinic-backend
cp .env.example .env
nano .env  # แก้ไข config

# 3. ติดตั้ง dependencies
composer install --optimize-autoloader --no-dev

# 4. Generate key และ migrate database
php artisan key:generate
php artisan migrate --force

# 5. Setup Nginx (ดูใน DEPLOYMENT_GUIDE.md)
# 6. Setup Queue Worker (ดูใน DEPLOYMENT_GUIDE.md)
```

### ค่า Config ที่จำเป็น (.env):

```env
APP_URL=https://api.exquiller.com
DB_CONNECTION=mysql
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password

PAYSOLUTIONS_TEST_MODE=false
PAYSOLUTIONS_API_KEY=your_key
PAYSOLUTIONS_SECRET_KEY=your_secret
PAYSOLUTIONS_MERCHANT_ID=your_merchant_id

TELEGRAM_BOT_TOKEN=your_token
TELEGRAM_CHAT_ID=your_chat_id
```

---

## 🔄 การ Update Code

### ใช้ GitHub Actions:
```bash
git add .
git commit -m "Your changes"
git push origin main
# ✅ Deploy อัตโนมัติ
```

### ใช้ Scripts:
```bash
# Update backend
./deploy-backend.sh

# Update frontend
./deploy-frontend.sh

# หรือ update ทั้งสอง
./deploy-backend.sh && ./deploy-frontend.sh
```

### Manual (บน server):
```bash
ssh user@your-server

# Pull code ล่าสุด
cd ~/deployment
git pull origin main

# Backend
cd clinic-backend
composer install --optimize-autoloader --no-dev
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
sudo supervisorctl restart clinic-queue:*

# Frontend
cd ~/deployment
flutter build web --release
rsync -av build/web/ /var/www/exquiller.com/
```

---

## 🐛 แก้ปัญหาเบื้องต้น

### Backend ไม่ทำงาน
```bash
# ดู logs
ssh user@server
tail -f /var/www/api.exquiller.com/storage/logs/laravel.log

# ตรวจสอบ permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### Frontend ไม่อัพเดท
```bash
# Hard refresh browser
# Mac: Cmd + Shift + R
# Windows: Ctrl + Shift + R

# ตรวจสอบไฟล์บน server
ssh user@server
ls -la /var/www/exquiller.com/
```

### Queue ไม่ทำงาน
```bash
ssh user@server
sudo supervisorctl status clinic-queue:*
sudo supervisorctl restart clinic-queue:*
```

---

## 📚 เอกสารเพิ่มเติม

- **DEPLOYMENT_GUIDE.md** - คู่มือ deployment ฉบับสมบูรณ์
- **GITHUB_ACTIONS_SETUP.md** - Setup GitHub Actions ทีละขั้นตอน

---

## 🎯 แผนการ Deploy แบบง่าย

### ครั้งแรก (One-time setup):
1. อ่าน `DEPLOYMENT_GUIDE.md` → Setup server
2. อ่าน `GITHUB_ACTIONS_SETUP.md` → Setup GitHub Actions
3. Push code → Deploy อัตโนมัติ ✅

### ครั้งต่อๆ ไป:
```bash
git add .
git commit -m "Your changes"
git push origin main
# ✨ ทุกอย่างเสร็จอัตโนมัติ!
```

---

## ⏱️ เวลาที่ใช้

- **Setup ครั้งแรก:** 30-60 นาที
- **Deploy ต่อๆ ไป (GitHub Actions):** 2-5 นาที (อัตโนมัติ)
- **Deploy ต่อๆ ไป (Manual):** 5-10 นาที

---

## 💡 Tips

1. ✅ **แนะนำ:** ใช้ GitHub Actions สำหรับ production
2. ✅ **ทดสอบก่อน:** ใช้ manual scripts ทดสอบก่อนตั้งค่า GitHub Actions
3. ✅ **Backup:** สำรองข้อมูลก่อน deploy ครั้งสำคัญ
4. ✅ **Monitor:** เช็ค logs หลัง deploy เสมอ
5. ✅ **Security:** ไม่ commit .env หรือ secrets ลง Git

---

## 🆘 ต้องการความช่วยเหลือ?

1. อ่าน Troubleshooting ใน `DEPLOYMENT_GUIDE.md`
2. ดู GitHub Actions logs (ถ้าใช้ auto-deploy)
3. ดู server logs
4. ทดสอบ deploy แบบ manual ก่อน

---

**Happy Deploying! 🚀**
