# 🚀 วิธีการ Deploy Frontend ไป Production

## เตรียมความพร้อม

ตรวจสอบว่ามี SSH access ไป production server:
```bash
ssh root@45.32.102.242
```

ถ้า SSH ได้ แสดงว่าพร้อม deploy แล้ว!

---

## 📋 ขั้นตอนการ Deploy

### 1. Build Flutter Web (ทำแล้ว ✅)

```bash
cd "/Users/janejiramalai/Downloads/project 2"
flutter clean
flutter build web --release --dart-define=PRODUCTION=true
```

**ผลลัพธ์:**
- ✅ Build สำเร็จ: `build/web/`
- ✅ Package สำเร็จ: `frontend-build.tar.gz` (9.9 MB)
- ✅ ภาพครบ 37 ไฟล์

---

### 2. Deploy ไป Production Server

รันคำสั่งเดียว:

```bash
cd "/Users/janejiramalai/Downloads/project 2"
./deploy-frontend-to-production.sh
```

**Script จะทำอะไร:**
1. ✅ ตรวจสอบว่ามี build file
2. ✅ Upload `frontend-build.tar.gz` ไป server
3. ✅ Backup version เก่าไว้ที่ `/var/www/backups/`
4. ✅ Extract build ใหม่ไปที่ `/var/www/exquillermember.com/`
5. ✅ ตั้งค่า permissions
6. ✅ Restart Nginx

---

### 3. Clear Backend Cache (สำคัญ!)

หลัง deploy เสร็จ ให้รันคำสั่งนี้:

```bash
ssh root@45.32.102.242 'cd ~/deployment/clinic-backend && php artisan view:clear && php artisan cache:clear && php artisan config:clear'
```

---

### 4. ทดสอบ

1. **เปิด website:**
   ```
   https://exquillermember.com
   ```

2. **Clear browser cache (Hard refresh):**
   - **Mac:** `Cmd + Shift + R`
   - **Windows/Linux:** `Ctrl + Shift + R`

3. **ตรวจสอบว่าภาพแสดงครบ:**
   - ✅ Logo สมาชิก (Member/VIP/Super VIP/Doctor)
   - ✅ ขีดค่าพลัง (progress bar)
   - ✅ Level icons (purple/green/pink)
   - ✅ Dialog สิทธิ์สมาชิก

---

## 🆘 กรณีมีปัญหา

### ปัญหา: ภาพยังไม่แสดง

**วิธีแก้:**

1. **ตรวจสอบว่า deploy สำเร็จหรือไม่:**
   ```bash
   ssh root@45.32.102.242 'ls -la /var/www/exquillermember.com/assets/assets/images/ | grep -E "purple|pink|green|exmember"'
   ```

   ควรเห็น: `purple.png`, `green.png`, `pink.png`, `exmember-pink-1.png`, etc.

2. **Clear cache อีกครั้ง:**
   ```bash
   ssh root@45.32.102.242 'cd ~/deployment/clinic-backend && php artisan cache:clear && sudo systemctl restart nginx'
   ```

3. **ลบ browser cache แบบเต็มรูป:**
   - Chrome: Settings → Privacy → Clear browsing data → Cached images and files

### ปัญหา: Nginx error

**ดู logs:**
```bash
ssh root@45.32.102.242 'tail -50 /var/log/nginx/error.log'
```

### ปัญหา: Permission denied

**แก้ permissions:**
```bash
ssh root@45.32.102.242 'sudo chown -R www-data:www-data /var/www/exquillermember.com && sudo chmod -R 755 /var/www/exquillermember.com'
```

---

## 🔄 Rollback (กรณีต้องการย้อนกลับ)

ถ้า deploy แล้วเกิดปัญหา สามารถ rollback ได้:

```bash
ssh root@45.32.102.242
cd /var/www/backups
ls -lt  # ดู backup ล่าสุด

# Restore (แทน BACKUP_NAME ด้วยชื่อ backup ที่ต้องการ)
sudo rm -rf /var/www/exquillermember.com
sudo cp -r /var/www/backups/BACKUP_NAME /var/www/exquillermember.com
sudo chown -R www-data:www-data /var/www/exquillermember.com
sudo systemctl restart nginx
```

---

## 📝 สรุป Checklist

- [x] Build Flutter web สำเร็จ
- [x] Package tar.gz สำเร็จ
- [x] ตรวจสอบภาพครบ 37 ไฟล์
- [ ] รัน `./deploy-frontend-to-production.sh`
- [ ] Clear Laravel cache บน server
- [ ] ทดสอบเว็บไซต์ + Hard refresh browser
- [ ] ตรวจสอบภาพแสดงครบทุกหน้า

---

## 📞 ติดต่อ

มีปัญหาหรือข้อสงสัย:
- ตรวจสอบ logs: `/var/log/nginx/error.log`
- ตรวจสอบ Laravel logs: `~/deployment/clinic-backend/storage/logs/laravel.log`
