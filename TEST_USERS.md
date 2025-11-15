# 🔐 Test User Credentials

สำหรับทดสอบ Payment Gateway

---

## Frontend Users (สำหรับทดสอบ)

### User 1: Test User (แนะนำ)
```
Email: test@example.com
Password: password
```
- ใช้สำหรับทดสอบทั่วไป

### User 2: Payment Test User (สร้างใหม่)
```
Email: payment@test.com
Password: 123456
Phone: 0812345678
```
- สร้างเพื่อทดสอบ Payment Gateway โดยเฉพาะ

---

## Admin User (สำหรับตรวจสอบ Backend)

```
URL: http://localhost:8000/admin/login
Email: admin@example.com
Password: password123
```
- ใช้ดู Orders, Payment Transactions, Customers

---

## 🧪 ขั้นตอนการทดสอบ Payment Gateway

### Step 1: Login
1. เปิด http://localhost:3000
2. Login ด้วย:
   - **Email:** `payment@test.com`
   - **Password:** `123456`

### Step 2: ซื้อสินค้า
1. ไปที่หน้า Products/Shop
2. เลือกสินค้าที่มี Stock > 0
3. เพิ่มลงตะกร้า
4. ไปที่ Cart → กด "ชำระเงิน"

### Step 3: Checkout
1. เลือกที่อยู่จัดส่ง (ถ้ายังไม่มี ให้สร้างก่อน)
2. เลือก Delivery Method
3. **สำคัญ:** เลือก Payment Method = **"บัตรเครดิต/เดบิต"**
4. กด "ยืนยันคำสั่งซื้อ"

### Step 4: ชำระเงิน (Test Mode)
1. WebView จะเปิดขึ้น (หรือ dialog บน web)
2. เห็นหน้า "Payment Gateway Test"
3. กดปุ่ม:
   - **"✓ ชำระเงินสำเร็จ"** → ทดสอบกรณีสำเร็จ
   - **"✗ ชำระเงินล้มเหลว"** → ทดสอบกรณีล้มเหลว

### Step 5: ตรวจสอบผล
- **ถ้าสำเร็จ:** เห็นหน้า Payment Success → Stock ลดลง
- **ถ้าล้มเหลว:** แสดง error → Order ยังค้างชำระ

---

## 🔍 ตรวจสอบใน Admin Dashboard

1. Login: http://localhost:8000/admin/login
   - Email: `admin@example.com`
   - Password: `password123`
2. ไปที่ "Orders" menu
3. เช็ค Order ที่เพิ่งสร้าง:
   - Order Number: ORD-YYYYMMDD-XXX
   - Status: 'paid' (ถ้าชำระสำเร็จ)
   - Payment Method: 'credit_card'
4. เช็ค Payment Transaction:
   - ดูได้ใน Order details
   - Status: 'success' หรือ 'failed'

---

## 📊 ตรวจสอบใน Database (Optional)

```sql
-- ดู Orders ล่าสุด
SELECT id, order_number, user_id, status, payment_method, total_amount, created_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- ดู Payment Transactions
SELECT id, order_id, transaction_id, status, amount, paid_at
FROM payment_transactions
ORDER BY created_at DESC
LIMIT 5;

-- ดู Stock สินค้า
SELECT id, name, stock, is_active
FROM products
WHERE stock < 10
ORDER BY stock ASC;
```

---

## 🚀 Tips

### ถ้า Login ไม่ได้:
- ลอง Register บัญชีใหม่
- หรือ reset password:
```bash
cd clinic-backend
php artisan tinker
$user = User::where('email', 'test@example.com')->first();
$user->password = Hash::make('password');
$user->save();
```

### ถ้า Payment ไม่ทำงาน:
- เช็ค Laravel log: `clinic-backend/storage/logs/laravel.log`
- เช็ค Browser console (F12)
- เช็คว่า Backend รันอยู่: http://localhost:8000

### ถ้า Stock ไม่ลด:
- เช็ค Order status เป็น 'paid' หรือไม่
- เช็ค Log:
```bash
tail -f clinic-backend/storage/logs/laravel.log | grep "Stock reduced"
```

---

**Happy Testing! 🎉**
