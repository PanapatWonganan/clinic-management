# คำแนะนำการทดสอบ Payment Gateway (Option A - WebView)

**วันที่:** 11 พฤศจิกายน 2025
**สถานะ:** ✅ พัฒนาเสร็จแล้ว พร้อมทดสอบ

---

## 🎉 สิ่งที่ทำเสร็จแล้ว

### Backend (Laravel)
- ✅ PaySolutions Service พร้อมใช้งาน
- ✅ Payment Transaction Model และ Migration
- ✅ API Endpoints:
  - `POST /api/payment/create` - สร้าง payment
  - `GET /api/payment/status/{paymentId}` - เช็คสถานะ
  - `POST /api/payment/callback` - รับ callback จาก gateway
  - `GET /payment/test/{order_id}` - หน้าทดสอบ (test mode)
  - `POST /api/payment/simulate` - จำลองการชำระเงิน (test mode)
- ✅ Test Mode ทำงานได้
- ✅ เชื่อมต่อกับระบบ Order และ Stock Management

### Frontend (Flutter)
- ✅ เพิ่ม `webview_flutter` package
- ✅ สร้าง `PaymentWebViewScreen` - หน้า WebView สำหรับชำระเงิน
- ✅ แก้ไข `checkout_screen.dart` เพื่อรองรับ credit card payment
- ✅ รองรับทั้ง Mobile และ Web platform

---

## 🧪 ขั้นตอนการทดสอบ Payment Flow

### Step 1: เข้าสู่ระบบ

1. เปิด browser ไปที่ http://localhost:3000
2. Login ด้วยบัญชีผู้ใช้ที่มีอยู่
   - หากยังไม่มี ให้สมัครสมาชิกก่อน

### Step 2: เลือกสินค้า

1. ไปที่หน้า Products/Shop
2. เลือกสินค้าที่ต้องการซื้อ
3. กด "เพิ่มลงตะกร้า"
4. ไปที่หน้า Cart

### Step 3: Checkout

1. กด "ชำระเงิน" ในหน้า Cart
2. เลือกที่อยู่จัดส่ง (ถ้ามี)
3. เลือกวิธีการจัดส่ง (delivery/pickup)
4. **สำคัญ:** เลือก Payment Method = **"บัตรเครดิต/เดบิต"**
5. กด "ยืนยันคำสั่งซื้อ"

### Step 4: Payment Gateway (ส่วนใหม่!)

**หลังจากกด "ยืนยันคำสั่งซื้อ" จะเกิดอะไรขึ้น:**

1. **Loading Dialog:** "กำลังประมวลผลคำสั่งซื้อ..."
   - ระบบสร้าง Order ใน database

2. **Loading Dialog:** "กำลังเตรียมหน้าชำระเงิน..."
   - ระบบเรียก API `/payment/create`
   - ได้ `payment_url` และ `payment_id`

3. **Payment WebView Screen เปิดขึ้น:**
   - บน Mobile: แสดง WebView เต็มหน้าจอ
   - บน Web (Chrome): แสดงคำแนะนำให้คัดลอก URL และเปิดแท็บใหม่

### Step 5: ทดสอบการชำระเงิน (Test Mode)

**หน้า Test Payment Gateway จะแสดง:**

```
┌──────────────────────────────────┐
│  Payment Gateway Test            │
│  TEST MODE                       │
├──────────────────────────────────┤
│  Order ID: ORD-20251111-001      │
│  Amount: 1,000.00 THB            │
│  Gateway: PaySolutions (Test)    │
├──────────────────────────────────┤
│  เลือกผลการชำระเงิน:             │
│                                  │
│  [✓ ชำระเงินสำเร็จ]              │
│  [✗ ชำระเงินล้มเหลว]            │
│                                  │
│  ⚠️ นี่คือหน้าทดสอบ              │
│     ไม่มีการชำระเงินจริง          │
└──────────────────────────────────┘
```

**ทดสอบ 2 กรณี:**

#### กรณีที่ 1: ชำระเงินสำเร็จ ✅
1. กดปุ่ม "✓ ชำระเงินสำเร็จ"
2. ระบบจะ simulate callback ไป backend
3. Backend อัพเดท:
   - Payment status = 'success'
   - Order status = 'paid'
   - **ลดสต็อกสินค้าอัตโนมัติ**
   - ส่ง Telegram notification
4. WebView จะปิด
5. Navigate ไปหน้า "Payment Success Screen"

#### กรณีที่ 2: ชำระเงินล้มเหลว ❌
1. กดปุ่ม "✗ ชำระเงินล้มเหลว"
2. ระบบจะ simulate callback (failed)
3. Backend อัพเดท:
   - Payment status = 'failed'
   - Order status = 'pending_payment' (ยังค้างชำระ)
   - **ไม่ลดสต็อก**
4. แสดง dialog "ชำระเงินล้มเหลว"
5. กลับไปหน้า checkout เพื่อลองใหม่

### Step 6: ตรวจสอบผลลัพธ์

#### ตรวจสอบใน Frontend:
1. **ถ้าชำระสำเร็จ:**
   - เห็นหน้า "Payment Success Screen"
   - แสดงข้อมูล Order Number, Total Amount
   - มีปุ่ม "ติดตามคำสั่งซื้อ" และ "กลับสู่หน้าหลัก"

2. **ถ้าชำระล้มเหลว:**
   - เห็น error message
   - กลับไปหน้า checkout

#### ตรวจสอบใน Backend (Database):
```sql
-- 1. เช็ค Order
SELECT id, order_number, status, payment_method, total_amount
FROM orders
ORDER BY created_at DESC
LIMIT 1;

-- 2. เช็ค Payment Transaction
SELECT id, order_id, transaction_id, status, amount, paid_at
FROM payment_transactions
ORDER BY created_at DESC
LIMIT 1;

-- 3. เช็ค Stock (ควรลดลง)
SELECT id, name, stock
FROM products
WHERE id IN (SELECT product_id FROM order_items WHERE order_id = <order_id>);
```

#### ตรวจสอบใน Admin Dashboard:
1. Login ที่ http://localhost:8000/admin
2. ไปที่ "Orders" menu
3. ดู Order ที่เพิ่งสร้าง:
   - Status = 'paid' (ถ้าสำเร็จ)
   - Payment Method = 'credit_card'
   - มี Payment Transaction record

---

## 🔍 สิ่งที่ต้องตรวจสอบ

### ✅ Checklist การทดสอบ

- [ ] **Order Creation:** สร้าง Order ได้หรือไม่
- [ ] **Payment URL Generation:** ได้ payment_url จาก API หรือไม่
- [ ] **WebView Opens:** WebView เปิดได้หรือไม่
- [ ] **Test Payment Page:** หน้าทดสอบแสดงถูกต้องหรือไม่
- [ ] **Success Flow:**
  - [ ] กด "ชำระสำเร็จ" ทำงานได้
  - [ ] Callback ส่งไป backend
  - [ ] Order status = 'paid'
  - [ ] Payment status = 'success'
  - [ ] **Stock ลดลงอัตโนมัติ**
  - [ ] Navigate ไปหน้า success
- [ ] **Failed Flow:**
  - [ ] กด "ชำระล้มเหลว" ทำงานได้
  - [ ] แสดง error message
  - [ ] Order status ยังคงเป็น 'pending_payment'
  - [ ] **Stock ไม่ลด**
- [ ] **Admin Dashboard:** แสดง Order และ Payment Transaction

---

## 🐛 ปัญหาที่อาจเจอ และวิธีแก้

### 1. WebView ไม่เปิด
**อาการ:** กด "ยืนยันคำสั่งซื้อ" แล้วไม่มีอะไรเกิดขึ้น

**วิธีแก้:**
- เช็ค Console Log ว่ามี error อะไร
- ตรวจสอบว่า API `/payment/create` response 200 หรือไม่
- ดู Network tab ใน browser DevTools

### 2. Test Payment Page 404
**อาการ:** WebView เปิดแล้วแต่แสดง 404 Not Found

**วิธีแก้:**
```bash
# เช็คว่า backend route มีหรือไม่
php artisan route:list | grep payment

# ควรเห็น:
# GET|HEAD  payment/test/{order_id} ... PaymentController@testPaymentPage
```

### 3. Callback ไม่ทำงาน
**อาการ:** กด "ชำระสำเร็จ" แล้วแต่ Order status ไม่เปลี่ยน

**วิธีแก้:**
- เช็ค Laravel log:
```bash
tail -f storage/logs/laravel.log
```
- ดู error ใน Console
- เช็คว่า API `/payment/callback` มีหรือไม่

### 4. Stock ไม่ลด
**อาการ:** Order status = 'paid' แต่ Stock ไม่ลด

**วิธีแก้:**
- เช็ค Order Model Observer ทำงานหรือไม่
- ดู Log:
```bash
grep "Stock reduced" storage/logs/laravel.log
```
- เช็ค `app/Models/Order.php:134` (stock reduction logic)

### 5. Web Platform ไม่แสดง WebView
**อาการ:** บน Chrome แสดงหน้าขาวเปล่า

**วิธีแก้:**
- นี่เป็นปกติ เพราะ `webview_flutter` ไม่รองรับ Web
- ควรแสดง dialog ให้คัดลอก URL
- ถ้าไม่แสดง ให้เช็ค `PaymentWebViewScreen` line 60-90

---

## 📱 ทดสอบบน Mobile (Optional)

ถ้าต้องการทดสอบบน mobile device จริง:

### Android:
```bash
# เปิด Android Emulator หรือเชื่อมต่อ device
flutter run

# เปลี่ยน API_BASE_URL ใน app_config.dart
# จาก http://127.0.0.1:8000/api
# เป็น http://10.0.2.2:8000/api (สำหรับ Emulator)
# หรือ http://<your-ip>:8000/api (สำหรับ Real Device)
```

### iOS:
```bash
# เปิด iOS Simulator
open -a Simulator

# รัน Flutter
flutter run

# API_BASE_URL: http://127.0.0.1:8000/api (ใช้ได้ใน Simulator)
```

---

## 🚀 Production Deployment

เมื่อทดสอบเสร็จแล้ว พร้อม deploy production:

### 1. สมัคร PaySolutions Account
- ไปที่ https://paysolutions.asia
- สมัครบัญชี Merchant
- รอ approval (1-3 วัน)
- ได้ API Credentials จริง:
  - API Key
  - Secret Key
  - Merchant ID

### 2. เปลี่ยน Environment Variables
แก้ไข `/clinic-backend/.env`:
```env
# เปลี่ยนจาก test เป็น production
PAYSOLUTIONS_TEST_MODE=false

# ใส่ credentials จริง
PAYSOLUTIONS_API_KEY=your_real_api_key
PAYSOLUTIONS_SECRET_KEY=your_real_secret_key
PAYSOLUTIONS_MERCHANT_ID=your_real_merchant_id

# ตั้ง callback URL ให้ถูกต้อง
APP_URL=https://yourdomain.com
PAYSOLUTIONS_CALLBACK_URL=${APP_URL}/api/payment/callback
PAYSOLUTIONS_RETURN_URL=${APP_URL}/payment/success
PAYSOLUTIONS_CANCEL_URL=${APP_URL}/payment/cancel
```

### 3. ทดสอบด้วยบัตรจริง
- ใช้บัตรทดสอบของ PaySolutions (ถ้ามี)
- หรือใช้บัตรจริงของคุณเอง (จำนวนเล็กน้อย)
- ตรวจสอบว่า callback ทำงานถูกต้อง

### 4. Deploy to Server (45.32.102.242)
```bash
# SSH เข้าไปที่ server
ssh user@45.32.102.242

# Pull code ใหม่
cd /path/to/clinic-backend
git pull

# อัพเดท .env
nano .env
# (แก้ไข PAYSOLUTIONS_* variables)

# Clear cache
php artisan config:clear
php artisan cache:clear

# Restart web server
sudo systemctl restart nginx
# หรือ
sudo systemctl restart apache2
```

---

## 📞 ติดต่อ Support

**ถ้ามีปัญหา:**

### PaySolutions Support:
- Email: support@paysolutions.asia
- LINE: @pay.sn
- Phone: (+66) 02-821-6163

### Technical Issues:
- เช็ค Laravel log: `storage/logs/laravel.log`
- เช็ค Flutter console
- เช็ค Browser DevTools (Network, Console tabs)

---

## 📝 สรุป

### ✅ สิ่งที่พร้อมแล้ว:
1. Backend API สำหรับ payment gateway
2. Frontend WebView integration
3. Test Mode ทำงานได้
4. เชื่อมต่อกับ Order และ Stock Management

### 🔄 ขั้นตอนถัดไป:
1. ทดสอบตาม checklist
2. แก้ไข bug (ถ้ามี)
3. สมัคร PaySolutions account
4. Deploy to production
5. ทดสอบด้วยบัตรจริง

### ⏱️ Timeline:
- Testing: 1-2 ชั่วโมง
- PaySolutions signup: 1-3 วัน (รอ approval)
- Production deployment: 2-4 ชั่วโมง
- **รวม: 3-5 วัน**

---

**Happy Testing! 🎉**

หากมีปัญหาหรือคำถาม กรุณา screenshot error และส่งมาให้ดูครับ
