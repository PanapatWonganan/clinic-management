# Credit Card Payment Gateway Integration

## 📋 Overview

ระบบรองรับการชำระเงิน 2 วิธี:
1. **Transfer (Upload Slip)** - อัพโหลดหลักฐานการโอนเงิน
2. **Credit Card (Gateway)** - ชำระผ่าน Payment Gateway (PaySolutions)

---

## 🔄 Payment Flow Comparison

### 1. Transfer (Upload Slip) ✅
```
User สร้าง Order (payment_method='transfer')
    ↓ status='pending_payment'
User upload slip
    ↓ status='payment_uploaded'
Admin approve slip
    ↓ status='paid' → ลดสต็อกอัตโนมัติ
```

### 2. Credit Card (Gateway) 💳
```
User สร้าง Order (payment_method='credit_card')
    ↓ status='pending_payment'
User เรียก API สร้าง payment
    ↓ ได้ payment_url
User ชำระผ่าน gateway
    ↓ Callback จาก gateway
Order status='paid' → ลดสต็อกอัตโนมัติ
```

---

## 🚀 API Endpoints

### 1. สร้าง Payment Transaction
```http
POST /api/payment/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "order_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "transaction_id": "TEST_...",
    "payment_url": "http://localhost:8000/payment/test/ORD-...",
    "amount": "1000.00",
    "currency": "THB",
    "expired_at": "2025-11-10 18:30:00",
    "test_mode": true
  }
}
```

### 2. เช็คสถานะ Payment
```http
GET /api/payment/status/{paymentId}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "transaction_id": "TEST_...",
    "status": "success",
    "amount": "1000.00",
    "paid_at": "2025-11-10 18:00:00",
    "order": {
      "id": 1,
      "order_number": "ORD-20251110-001",
      "status": "paid"
    }
  }
}
```

### 3. Callback (Webhook) - No Auth
```http
POST /api/payment/callback
Content-Type: application/json

{
  "transaction_id": "TEST_...",
  "order_id": "ORD-20251110-001",
  "status": "success",
  "amount": "1000.00"
}
```

---

## ⚙️ Configuration

### Environment Variables (.env)
```env
# Test Mode (true = sandbox, false = production)
PAYSOLUTIONS_TEST_MODE=true

# API Credentials (เปลี่ยนเป็นของจริงตอน production)
PAYSOLUTIONS_API_KEY=your_api_key
PAYSOLUTIONS_SECRET_KEY=your_secret_key
PAYSOLUTIONS_MERCHANT_ID=your_merchant_id

# API URLs (จะเปลี่ยนอัตโนมัติตาม test_mode)
PAYSOLUTIONS_API_URL=https://apis.paysolutions.asia
PAYSOLUTIONS_PAYMENT_URL=https://www.thaiepay.com/epaylink/payment.aspx

# Callback URLs
PAYSOLUTIONS_CALLBACK_URL=${APP_URL}/api/payment/callback
PAYSOLUTIONS_RETURN_URL=${APP_URL}/payment/success
PAYSOLUTIONS_CANCEL_URL=${APP_URL}/payment/cancel

# Settings
PAYSOLUTIONS_CURRENCY=THB
PAYSOLUTIONS_LANGUAGE=TH
PAYSOLUTIONS_TIMEOUT=30
```

---

## 🎯 สิ่งสำคัญที่ต้องรู้

### 1. เฉพาะ Credit Card เท่านั้น
- Payment Gateway รองรับเฉพาะ `payment_method='credit_card'`
- ถ้า Order เป็น `transfer`, `cash`, หรือ `qr_code` จะไม่สามารถใช้ gateway ได้

### 2. Stock Management
- **ไม่**ลดสต็อกตอนสร้าง Order
- ลดสต็อกเมื่อ Order `status='paid'` เท่านั้น
- ลดสต็อกอัตโนมัติผ่าน Order Model Observer

### 3. Admin Dashboard
- แสดง Payment Slips สำหรับ transfer
- แสดง Payment Transactions สำหรับ credit_card
- สามารถดูประวัติการชำระเงินทั้ง 2 แบบ

### 4. Test Mode
- Test mode จะแสดงหน้าจำลองการชำระเงิน
- สามารถเลือก Success หรือ Failed ได้
- ไม่มีการเชื่อมต่อ gateway จริง

---

## 📊 Database Schema

### payment_transactions
```sql
- id
- order_id (FK → orders)
- transaction_id
- payment_gateway ('paysolutions')
- payment_method ('credit_card')
- amount
- currency ('THB')
- status (pending/processing/success/failed/cancelled)
- payment_url
- callback_data (JSON)
- error_message
- paid_at
- expired_at
- created_at
- updated_at
```

---

## 🧪 Testing

### Test Mode Flow:
1. สร้าง Order ด้วย `payment_method='credit_card'`
2. เรียก `/api/payment/create` {order_id}
3. เปิด `payment_url` ที่ได้รับ
4. เลือก "ชำระเงินสำเร็จ" หรือ "ชำระเงินล้มเหลว"
5. ระบบจะ callback อัตโนมัติ
6. เช็คสถานะ Order → ควรเป็น `paid` (ถ้าสำเร็จ)
7. เช็คสต็อกสินค้า → ควรลดลงแล้ว

### Manual Test Commands:
```bash
# 1. สร้าง Order ผ่าน API
curl -X POST http://localhost:8000/api/orders \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [{"product_id": 1, "quantity": 1}],
    "delivery_method": "delivery",
    "payment_method": "credit_card",
    "shipping_address_id": 1
  }'

# 2. สร้าง Payment
curl -X POST http://localhost:8000/api/payment/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_id": 1}'

# 3. Simulate Success
curl -X POST http://localhost:8000/api/payment/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "ORD-20251110-001",
    "amount": 1000,
    "status": "success"
  }'

# 4. Check Payment Status
curl http://localhost:8000/api/payment/status/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🔒 Security

1. **Authentication:**
   - `/api/payment/create` และ `/api/payment/status` ต้อง login
   - `/api/payment/callback` ไม่ต้อง auth (สำหรับ webhook)

2. **Authorization:**
   - User สามารถสร้าง payment เฉพาะ Order ของตัวเอง
   - เช็ค `order.user_id === auth()->id()`

3. **Validation:**
   - เช็ค Order status = 'pending_payment'
   - เช็ค payment_method = 'credit_card'
   - เช็คไม่มี payment success อยู่แล้ว

4. **Callback Verification:**
   - Production: ต้อง verify signature
   - Test mode: ข้าม signature check

---

## 🚧 Production Checklist

ก่อน deploy production:

- [ ] เปลี่ยน `PAYSOLUTIONS_TEST_MODE=false`
- [ ] ใส่ API credentials จริง
- [ ] ตั้ง callback URL ให้ถูกต้อง
- [ ] ทดสอบ payment flow ทั้งหมด
- [ ] เช็ค stock reduction ทำงานถูกต้อง
- [ ] เช็ค Telegram notification
- [ ] ทดสอบ failed payment scenario
- [ ] เช็ค admin dashboard แสดง transactions

---

## 📞 Support

- PaySolutions Support: support@paysolutions.asia
- LINE: @pay.sn
- Phone: (+66) 02-821-6163

---

## 📝 Notes

- Payment gateway รองรับเฉพาะ **บัตรเครดิต** เท่านั้น
- สำหรับการโอนเงิน ให้ใช้ระบบ Upload Slip แทน
- Test mode ไม่มีการเชื่อมต่อ gateway จริง
- Callback จะถูกเรียกอัตโนมัติจาก gateway
- Stock จะลดเมื่อ Order status = 'paid' เท่านั้น

---

**Version:** 1.0.0
**Last Updated:** 2025-11-10
**Environment:** Laravel 11, PHP 8.3
