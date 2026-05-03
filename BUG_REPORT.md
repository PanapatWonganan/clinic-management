# BUG_REPORT.md

Audit ของ codebase Exquiller Member (Flutter `lib/` + Laravel `clinic-backend/`)
สรุปวันที่: 2026-05-03

## วิธี audit
- `flutter analyze` → 143 issues (ไม่มี error, ส่วนใหญ่เป็น `info` + warning)
- `./vendor/bin/pint --test` → 82 ไฟล์มี style issue (cosmetic, ไม่กระทบ behavior — ไม่ list ในรายงานนี้)
- ไม่ติดตั้ง phpstan / larastan
- อ่านโค้ด critical surfaces: payment, auth, order, payment slip, profile/membership, free item redemption, product, customer address, IsAdmin middleware, bootstrap/app.php, Order model, PaySolutionsService, ApiService, AuthService, payment_webview_screen, payment_pending_screen, main.dart

ลำดับ bug จาก Critical → Low ตามผลกระทบจริงต่อ data integrity, security, และ UX

---

## 🔴 CRITICAL

### [x] C1. Stock race condition — ไม่มี row-level lock บนตอน `decrement`
**ไฟล์:**
- `clinic-backend/app/Models/Order.php:149-172` (`reduceProductStock`)
- `clinic-backend/app/Http/Controllers/OrderController.php:118-127, 234-239, 302-306`
- `clinic-backend/app/Http/Controllers/FreeItemRedemptionController.php:194-197, 297-300`

**ทำไมเป็น bug:**
ทุกที่ที่หัก stock อ่านค่าจาก `$product->stock` ด้วย query ปกติ (ไม่มี `lockForUpdate()`) แล้วค่อยตัดสินใจว่าจะ `decrement` หรือไม่ — เป็น check-then-act pattern คลาสสิก
- 2 requests พร้อมกัน เห็น `stock = 1` ทั้งคู่ → ทั้งคู่ผ่านเช็ค → ทั้งคู่ `decrement` → stock กลายเป็น `-1`
- โค้ดใน `Order::reduceProductStock()` เรียก `$product->decrement` หลังเช็ค `>=` ก็มีช่องเดียวกันเพราะ check และ decrement ไม่ได้อยู่ใน transaction-locked region
- โอกาสเกิดสูงโดยเฉพาะตอน flash sale หรือสินค้าใกล้หมด

**วิธีแก้ที่แนะนำ:**
```php
DB::transaction(function () use ($item) {
    $product = Product::where('id', $item['product_id'])->lockForUpdate()->first();
    if ($product->stock < $item['quantity']) throw new \Exception('out of stock');
    $product->decrement('stock', $item['quantity']);
});
```
หรือใช้ atomic conditional update:
```php
$updated = Product::where('id', $id)->where('stock', '>=', $qty)
    ->update(['stock' => DB::raw("stock - $qty")]);
if ($updated === 0) throw new \Exception('out of stock');
```

---

### [x] C2. Order number ไม่ unique เพราะใช้ `count() + 1` race
**ไฟล์:** `clinic-backend/app/Http/Controllers/OrderController.php:150` และ `FreeItemRedemptionController.php:326`

**ทำไมเป็น bug:**
```php
$orderNumber = 'ORD-' . date('Ymd') . '-' . str_pad(Order::whereDate('created_at', today())->count() + 1, 3, '0', STR_PAD_LEFT);
```
สอง requests มาพร้อมกัน → count() เห็นเลขเดียวกัน → สร้าง order_number ซ้ำ → ถ้า DB มี unique constraint จะ throw, ถ้าไม่มีก็จะมี order_number ซ้ำในระบบ
ยิ่งกว่านั้น `OrderController` สร้าง `ORD-...-NNN` ส่วน `FreeItemRedemption` สร้าง `FREE-...-NNN` แต่ `count()` นับจาก `orders` table ทั้งหมด — ถ้ามีออเดอร์ฟรีและออเดอร์ปกติในวันเดียวกัน เลขท้ายอาจชนกันได้

**วิธีแก้:** ใช้ DB sequence/auto-increment, หรือ `Str::ulid()`, หรือใช้ `id` + checksum, หรือใช้ retry-on-duplicate loop (และเพิ่ม unique constraint บน `order_number`)

---

### [x] C3. `simulatePayment` เรียก `handleCallback` โดย bypass signature check
**ไฟล์:** `clinic-backend/app/Http/Controllers/PaymentController.php:408-467`

**ทำไมเป็น bug:**
- มี hard guard ที่ดี: `app()->environment('production')` + `isTestMode()`
- แต่ `handleCallback` (line 156-162) ใช้ `if (!$this->paymentService->isTestMode())` เพื่อ skip signature verify
- หมายความว่า ถ้า `APP_ENV !== production` แต่ `PAYSOLUTIONS_TEST_MODE=false` (config เพี้ยน) → callback signature ไม่ถูกตรวจ + simulate route ก็เปิดอยู่ (เพราะ guard ใช้ `&&` เลือก reject เฉพาะ both true)

อ่านอีกครั้ง: guard เป็น `OR` (`if (production) || (!isTestMode)`). ถ้า `production=false, testMode=false` → guard `false || true` → abort(404). OK ปลอดภัย ✅

**แต่ยังมี issue ที่ยังคง critical:**
`handleCallback` skip signature เมื่อ `isTestMode()` — staging server ที่ใช้ DB จริงและ test_mode=true จะรับ callback จาก attacker ภายนอกได้ทันที (ไม่ใช่แค่ simulate route) เพราะ `/api/payment/callback` ไม่มี auth และไม่มี IP allowlist
ถ้ามีคนรู้ว่า staging ใช้ `test_mode=true` → POST `/api/payment/callback` ตรง ๆ ด้วย order_id ที่เดาได้ + status=success → mark order paid

**วิธีแก้:**
- ตรวจ signature เสมอ ไม่ว่า test_mode หรือไม่ (อย่างน้อยตรวจว่า request มาจาก IP ของ PaySolutions หรือมี shared secret header)
- ใน test/staging ใช้ secret แยก แต่ verify อย่างเข้มงวดเหมือน production
- หรือ guard `/api/payment/callback` ด้วย IP allowlist + signature

---

### [x] C4. `verifyAndUpdatePayment` ไม่เช็คเจ้าของ order — IDOR
**ไฟล์:** `clinic-backend/app/Http/Controllers/PaymentController.php:286-384`

**ทำไมเป็น bug:**
Endpoint `POST /api/payment/verify/{paymentId}` อยู่หลัง `auth:sanctum` แต่ไม่ได้ตรวจว่า payment นั้นเป็นของ user ที่ login อยู่
- User A login → POST `/payment/verify/<paymentId ของ B>`
- ถ้า PaySolutions confirm ว่า paid (จากระบบจริง) → backend จะ mark order ของ B ว่า paid + reduce stock + ส่ง Telegram
- แม้จะไม่ได้แอบจ่ายแทนคนอื่น แต่ก็ trigger side effects ของ order คนอื่นได้ — และเปิดช่อง enumeration

เทียบกับ `createPayment` (line 55-60) ที่เช็ค `$order->user_id !== auth()->id()` — `verifyAndUpdatePayment` ลืมเช็คนี้

**วิธีแก้:** เพิ่ม guard
```php
if ($payment->order->user_id !== auth()->id()) {
    return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
}
```

---

### [x] C5. `checkStatus` ก็ไม่เช็คเจ้าของเหมือนกัน — leak payment status คนอื่น
**ไฟล์:** `clinic-backend/app/Http/Controllers/PaymentController.php:251-280`

**ทำไมเป็น bug:**
GET `/api/payment/status/{paymentId}` ส่ง transaction_id, status, amount, order_number กลับ — ไม่ตรวจว่า payment เป็นของ user → enumerate paymentId แล้วได้ข้อมูลคำสั่งซื้อของลูกค้าคนอื่น

**วิธีแก้:** เช็ค ownership เหมือน C4

---

## 🟠 HIGH

### [x] H1. `Order::booted()` static event อาจ trigger ซ้ำ + race กับ stock decrement ใน controller
**ไฟล์:** `clinic-backend/app/Models/Order.php:129-146`

**ทำไมเป็น bug:**
- `booted()` ตั้ง `static::updated` ให้ลด stock อัตโนมัติเมื่อ status เปลี่ยนเป็น `paid`
- `OrderController::cancel` (line 402-406) ก็ `$item->product->increment('stock', $item->quantity)` เอง
- `PaymentController::handleCallback` (line 211-214) update status เป็น paid → trigger booted → ลด stock
- ถ้าวันหลังมี admin/cron ที่ revert status (paid → pending → paid) จะลด stock 2 รอบ เพราะ event ไม่เช็คว่าเคยลดไปแล้ว
- ไม่มี idempotency key หรือ flag `stock_reduced_at`

**วิธีแก้:**
- เพิ่ม column `stock_reduced` (bool) บน `orders` หรือ `order_items` แล้วเช็คก่อนลด
- หรือย้าย logic นี้ไปที่ controller (explicit) แทน implicit event listener — เห็น flow ง่ายและ test ได้

---

### [x] H2. Reduce stock ใน `Order::booted()` ไม่อยู่ใน transaction → ไม่ atomic
**ไฟล์:** `clinic-backend/app/Models/Order.php:131-143` + `PaymentController::handleCallback:203-233`

**ทำไมเป็น bug:**
`handleCallback` เปิด `DB::beginTransaction()` แล้วเรียก `$order->update(['status' => 'paid'])` → trigger event → `reduceProductStock()` decrement หลายตัว
- ถ้า `decrement` ตัวที่ 3 ล้ม (เช่น deadlock) → exception → rollback transaction → status order revert แต่ stock ที่ decrement ไป 2 ตัวก่อนหน้าก็ rollback ด้วย ✅ OK
- **แต่** event ใน `static::updated` ไม่ guarantee ว่า run ก่อน `DB::commit()` — `updated` event run ทันทีหลัง `update()` query แต่ตัว listener ไม่ห่อ `try/catch` เลย → ถ้าล้มกลางคัน flag `paid` ค้างใน DB ตอน commit แต่ stock ลดไม่ครบ
- รวมถึง `SendTelegramNotification::dispatch` ที่อยู่ใน listener ด้วย → ถ้า queue connection sync จะ fire ภายใน transaction → side effect ส่งจริงก่อน commit, ถ้า rollback ก็แจ้งผิด

**วิธีแก้:**
- ย้าย stock reduction ออกมาเรียก explicit หลัง `DB::commit()`, หรือ
- ใช้ `DB::afterCommit()` (Laravel 9+) wrap dispatch
- ในตัว reduceProductStock ห่อ try/catch + log + rethrow

---

### [x] H3. `PaySolutionsService::generatePaymentUrl` ไม่ได้แนบ signature → callback verifies signature ที่ไม่เคย sign
**ไฟล์:** `clinic-backend/app/Services/PaySolutionsService.php:104-127, 132-168`

**ทำไมเป็น bug:**
- `generatePaymentUrl` build query string จาก `merchantid, refno, customeremail, productdetail, total, lang, cc` แต่ **ไม่** เรียก `generateSignature()` ก่อนแนบ
- `verifyCallback` คาดว่า callback มี `signature` field และ hash ทุก field + secret
- ถ้า PaySolutions จริง ๆ ใช้ scheme นี้ — request ที่เราส่งจะถูก gateway ปฏิเสธ (เพราะไม่มี signature)
- ถ้า PaySolutions ไม่ได้ใช้ scheme นี้ — `verifyCallback` ก็ไม่ตรงจริงอยู่ดี → ในโปรดักชัน signature check จะ fail ทุก callback → block ทุกการชำระเงิน
- โค้ดยังเป็น stub ที่ไม่ได้ integrate กับ PaySolutions จริง (`createPayment`/`getPaymentStatus` มี `mockCreatePayment` แต่ production path ก็ยิงไป `/order/orderdetailpost` โดยไม่มี signature)

**วิธีแก้:** อ่าน PaySolutions ePayment-L docs ใหม่ ตรวจว่า:
1. Request signing scheme คืออะไร (HMAC? sorted concat?)
2. Callback verifying scheme คืออะไร
แล้ว implement ให้ตรง — หรือถ้า gateway ใช้ shared API key ผ่าน header แทน signature ก็ลบ `verifyCallback`/`generateSignature` ทิ้งไปเลย แล้วล็อก `/api/payment/callback` ด้วย IP allowlist + secret header แทน

---

### [x] H4. Cancel order ไม่ใส่ `cancelled_by_user` flag — race กับ admin/payment callback
**ไฟล์:** `clinic-backend/app/Http/Controllers/OrderController.php:381-426`

**ทำไมเป็น bug:**
- User กด cancel order ที่อยู่ใน `pending_payment` → status เปลี่ยน `cancelled`
- ระหว่าง 2 requests ใน flight: payment callback มาถึง (PaySolutions confirm จ่าย) → callback update status เป็น `paid` → trigger stock reduce
- ตอนนี้ order มี status `paid` แม้ user เพิ่ง cancel + ลูกค้าอาจเสียเงินจริงแล้ว
- ไม่มี version/optimistic-lock บน `orders.status`

**วิธีแก้:**
- ใช้ DB transaction + `select ... for update` ตอน cancel
- ใน `handleCallback` ตรวจ `$order->status` ก่อน update เป็น paid — ถ้าเป็น `cancelled` แล้ว ให้ refund (หรืออย่างน้อย log + ไม่ flip status) แทนการ overwrite

---

### [x] H5. `OrderController::store` validate `delivery_method` แต่ใช้ `request->payment_method` โดยไม่ map
**ไฟล์:** `clinic-backend/app/Http/Controllers/OrderController.php:54`

**ทำไมเป็น bug:**
Validator รับ `payment_method` ใน `cash,transfer,credit_card,qr_code` แต่:
- Frontend (`payment_pending_screen.dart`) เช็ค `widget.paymentMethod == 'promptpay'`
- `PaymentController::createPayment` ปฏิเสธ order ที่ไม่ใช่ `credit_card`
- ค่า `qr_code`, `cash` จะ pass validation แต่ logic downstream ไม่รองรับครบ → order ค้างที่ `pending_payment` ไม่มีทาง paid

**วิธีแก้:** ตัด `qr_code` ออกจาก validator, หรือให้ flow `qr_code/transfer` route ไปที่ payment slip upload โดย explicit, หรือ map `promptpay` → `transfer` ฝั่ง frontend ให้ตรงกัน

---

### [x] H6. Membership upgrade query ไม่มี cap — user มีหลายระดับ skip ได้ทีเดียว
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProfileController.php:546-574`

**ทำไมเป็น bug:**
```php
$upgradeRule = DB::table('membership_upgrade_rules')
    ->where('from_type', $user->membership_type)
    ->where('min_spent', '<=', $totalSpent)
    ->where('is_active', true)
    ->first();
```
- เลือก rule แรกที่เจอ (ไม่ได้ `orderBy('min_spent', 'desc')`)
- ถ้ามีหลาย rule จาก `exMember` (เช่น exMember→exVip ที่ 50k, exMember→exSuperVip ที่ 200k) — user ที่จ่าย 250k จะได้แค่ rule ที่ DB return เป็นแถวแรก ซึ่งอาจเป็น exVip แทน exSuperVip
- เรียกใน `getMembershipProgress` ทุกครั้งที่ user load หน้า home → ทุกครั้ง upgrade เลื่อนทีละ rank ก็จะ promote ขึ้น (กิน DB write ที่ไม่จำเป็น)

**วิธีแก้:** `orderBy('min_spent', 'desc')->first()` เพื่อให้ได้ rule สูงสุดที่ qualify

---

### [x] H7. Logout ไม่มี throttle → revoke token ของคนอื่นได้ถ้ารู้ token
**ไฟล์:** `clinic-backend/routes/api.php:19`

**ทำไมเป็น bug:**
- `/auth/login` และ `/auth/register` มี `throttle:10,1` แต่ `/auth/logout` ไม่มี
- ปกติ logout ต้องมี valid token อยู่แล้ว — แต่ถ้า token leak (เช่น log file หรือ analytics) ผู้ที่ได้ token ไปสามารถ logout user นั้น ๆ เป็นจำนวนมากได้ (DoS)
- เป็น defense-in-depth issue ไม่ใช่ direct exploit

**วิธีแก้:** ห่อ logout ด้วย `throttle:30,1` เหมือน routes อื่น

---

### [x] H8. PaymentSlip upload — ไม่ revalidate file count ก่อนลบของเก่า
**ไฟล์:** `clinic-backend/app/Http/Controllers/PaymentSlipController.php:51-70`

**ทำไมเป็น bug:**
- ลบ `existingSlips` ก่อน (line 62-70) แล้วค่อยพยายาม save ของใหม่
- ถ้า save ไฟล์ใหม่ล้ม (disk เต็ม, mime parse ล้ม, etc.) → user เสียสลิปเก่าที่อนุมัติไปแล้ว ไม่มีของใหม่ทดแทน
- ไม่มี transaction หรือ try/catch รอบ "delete old → save new"

**วิธีแก้:** save new ก่อน → ถ้าสำเร็จค่อยลบเก่า, หรือใช้ DB transaction + Storage rollback (ลำบาก) หรืออย่างน้อยทำ soft-delete กับสลิปเก่า

---

### [x] H9. `PaymentSlipController::adminUpdateStatus` ไม่มี admin guard
**ไฟล์:** `clinic-backend/app/Http/Controllers/PaymentSlipController.php:237-284`

**ทำไมเป็น bug:**
- Method ชื่อ `adminUpdateStatus` แต่ใน `routes/api.php` ไม่มี route ที่ map มาที่นี่ — ต้องเช็คว่ามีในไฟล์อื่นหรือเปล่า
- ถ้ามีคน wire route นี้โดยลืม `admin` middleware → ลูกค้าทั่วไป approve สลิปตัวเองได้ → mark order paid → ได้ของฟรี
- ตอนนี้อาจปลอดภัยเพราะไม่มี route แต่เป็น footgun รอเกิด

**วิธีแก้:** ลบ method `adminIndex`/`adminUpdateStatus` ออกจาก controller นี้ ย้ายไป `Admin/PaymentSlipController` ที่อยู่หลัง `admin` middleware เสมอ

---

### [x] H10. `ProductController::store/update/destroy` ใช้ `$request->validate` ไม่ใช่ `Validator::make` → throw exception แทน return JSON 422
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProductController.php:166-272`

**ทำไมเป็น bug:**
- `$request->validate()` throw `ValidationException` ที่ Laravel จัดการเป็น HTML redirect by default
- ปกติ Laravel detect API request และ return JSON อยู่แล้ว แต่ก็ยังควรใช้ pattern เดียวกับ controller อื่น (Validator::make + return JSON 422) เพื่อ consistency
- ถ้า admin frontend ไม่ได้ส่ง `Accept: application/json` หรือ middleware ไม่ทำงาน → จะได้ HTML error แทน JSON

ไม่ critical ถ้า admin frontend ตั้ง header ถูกต้อง — แต่ inconsistent กับ controllers อื่น

---

## 🟡 MEDIUM

### [x] M1. `ProfileController::show` ส่งค่า default placeholder ออกไปเป็นข้อมูลจริง
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProfileController.php:21-26`

```php
'phone' => $user->phone ?? '081-234-5678',
'address' => $user->address ?? '123/45 หมู่ 6 ซอยลาดพร้าว 15 แยก 3\nถนนลาดพร้าว',
'district' => $user->district ?? 'จอมพล',
'province' => $user->province ?? 'กรุงเทพมหานคร',
'postalCode' => $user->postal_code ?? '10900',
```

User ที่ยังไม่ได้กรอกข้อมูล จะได้ข้อมูลปลอมที่ดูเหมือนจริง — ถ้าไม่ระวังจะใช้ค่านี้ส่งของไปที่ที่อยู่ผิด

**วิธีแก้:** return `null` แล้วให้ frontend แสดง "ยังไม่ได้กรอก"

---

### [x] M2. `ProductController::index` apply `exDoctor` price 850 hard-coded ใน controller
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProductController.php:31, 68`

**ทำไมเป็น bug:**
- magic number 850 ปรากฏ 2 ที่ ไม่มี source of truth
- ถ้าแก้ราคา exDoctor ต้องไล่แก้ทั้ง 2 จุด
- ไม่สามารถมี exDoctor pricing ต่อ product ได้ — fix ไปที่ 850 ทุกตัว

**วิธีแก้:** อ่านจาก `MembershipBundleDeal` หรือ `membership_pricing` table ที่ existing อยู่แล้ว

---

### [x] M3. ProductController image upload — predictable filename + ไม่ sanitize original name
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProductController.php:183, 232`

**ทำไมเป็น bug:**
```php
$imageName = time() . '_' . $image->getClientOriginalName();
```
- `time()` มี collision กรณี concurrent upload วินาทีเดียวกัน
- `getClientOriginalName()` มาจาก client โดยตรง — ถ้ามี `../` หรือ path traversal characters อาจหลุด (Laravel `storeAs` ฝั่ง implementation จะ throw แต่ตรวจไม่ได้ทุกเคส)
- รับเฉพาะ `image|mimes:jpeg,png,jpg,gif|max:2048` ดี แต่ไม่ตรวจ MIME ลึก (magic bytes)

**วิธีแก้:** ใช้ `Str::uuid().'.'.$image->extension()` หรือ `$image->hashName()` (Laravel ให้)

---

### [x] M4. `MembershipProgressService::getMembershipProgress` ที่ ProfileController call จาก loop ใน CustomerController:44 — N+1 รุนแรง
**ไฟล์:** `clinic-backend/app/Http/Controllers/Admin/CustomerController.php:42-66`

**ทำไมเป็น bug:**
- foreach customer (15 ต่อ page) → เรียก `getMembershipProgress` ที่ภายในจะ query orders + orderItems + bundleDeals + claimedRewards ของ user นั้น
- Loop ใน `$customers->getCollection()->each(...)` ยิง query หลายตัวต่อ customer → 1 page = 15 customers × ~5 queries = 75+ queries
- Plus `UserClaimedReward::where('user_id', ...)` 2 ครั้ง (line 53, 55) ต่อ customer
- หน้านี้จะช้ามากเมื่อมี customer หลายร้อย/พัน

**วิธีแก้:**
- Eager load `with(['orders.orderItems', 'claimedRewards'])` ตอนดึง customer
- ปรับ MembershipProgressService ให้รับ user ที่ pre-loaded แล้วและไม่ re-query
- หรือทำเป็น aggregated SQL ตัวเดียว

---

### [x] M5. `OrderController::index` page-level eager load อ่านได้ดี แต่ membership progress ที่ `ProfileController::getMembershipProgress` ก็ N+1 ใน loop bundleDeals
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProfileController.php:201-233`

**ทำไมเป็น bug:**
ใน `getMembershipProgressData` (line 470-512) ที่อยู่ใน foreach bundleDeals — ถ้า user มีการแลกรางวัล จะ loop bundleDeals (N levels) แล้วในแต่ละ iteration เรียก `$user->orders()->...->get()` ใหม่ → N × 1 query
- 6 levels = 6 queries เฉพาะตรงนี้
- ทั้งฟังก์ชันเรียกซ้ำใน `getMembershipProgress` หลัก (line 122-129) อีกชุด
- โดยรวม endpoint นี้ทำงาน ~10+ queries ต่อ request

**วิธีแก้:** ดึง orders + orderItems มาครั้งเดียวก่อน loop, ใช้ collection in-memory คำนวณ

---

### [x] M6. Frontend `payment_webview_screen.dart` — Timer poll ทำงานอยู่แม้ใน background
**ไฟล์:** `lib/screens/payment_webview_screen.dart:368-382`

**ทำไมเป็น bug:**
- Timer ทุก 3 วินาที — ถ้า user ลงไป background หรือ minimize app, timer ยัง fire (Flutter ปกติ pause widget rebuild แต่ Timer fire ตามปกติ)
- เปลือง bandwidth + battery + อาจโดน rate limit (`throttle:20,1`) ภายใน 1 นาที
- `_isCheckingStatus` guard ป้องกัน re-entry ดี แต่ก็ยัง fire request ทุก 3s ที่ไม่ใช่ตอน checking
- `_pollTimer` cancel ใน `dispose()` ✅ ถูกต้อง

**วิธีแก้:**
- ใช้ `WidgetsBindingObserver` แล้ว pause timer เมื่อ `AppLifecycleState.paused`
- หรือเพิ่ม backoff (3s → 6s → 12s) เมื่อยังไม่ success

---

### [x] M7. Frontend `_handleUnauthorized` ลบ token แต่ไม่ navigate ไป login
**ไฟล์:** `lib/services/api_service.dart:32-38` + `lib/services/auth_service.dart:29-33`

**ทำไมเป็น bug:**
- `clearSessionDueToUnauthorized()` ลบ token จาก memory + storage ✅
- แต่ไม่มีกลไก global ที่ navigate ไป LoginScreen — caller ต้อง handle เอง
- หลายที่ใน app เรียก ApiService แล้วเช็คแค่ `response.statusCode` → ได้ exception "Network error" ที่งง (เพราะ `parseResponse` throw ที่ line 230)
- User เห็น loading หรือ error แต่ยังคงอยู่บน screen เดิม → กดปุ่มต่อก็ได้ exception ซ้ำ ๆ

**วิธีแก้:**
- ใส่ navigator key global แล้ว push to login เมื่อ 401
- หรือใช้ event/notifier ที่ AuthService listen แล้วบังคับ navigation ผ่าน `MaterialApp.navigatorKey`

---

### [x] M8. Frontend `print()` ใน production code (analyzer flagged 30+ ครั้ง)
**ไฟล์:**
- `lib/models/order.dart:102, 103, 111, 112, 116, 120, 125`
- `lib/screens/checkout_screen.dart:260, 262, 292, 317, 375, 481, 862, 864`
- `lib/screens/payment_pending_screen.dart:56, 60`
- `lib/screens/redeem_free_items_screen.dart:41, 42, 51, 64, 71`
- `lib/services/product_service.dart:28, 62, 85`
- `lib/services/thai_address_service.dart:59, 62, 69, 70, 75, 86, 90, 94, 98, 126, 163, 187`
- `lib/widgets/payment_method_card.dart:802, 844, 854, 855, 860, 863, 867`

**ทำไมเป็น bug:**
- `print` ติดไป production → log token, order details, payment URL, addresses ใน console (Android logcat อ่านได้บางสถานการณ์)
- ลด performance เพราะ String interpolation
- analyzer rule `avoid_print` ตั้งใจ block

**วิธีแก้:** แทนด้วย `debugPrint` (auto-stripped บน release) หรือ proper logger; หรืออย่างน้อยห่อด้วย `if (kDebugMode)`

---

### [x] M9. `use_build_context_synchronously` analyzer warnings — 25+ ครั้ง
**ไฟล์:** `checkout_screen.dart` 18 จุด, `home_screen.dart` 3 จุด, `login_screen.dart` 4 จุด, `profile_*.dart` 7 จุด, `payment_pending_screen.dart:323`

**ทำไมเป็น bug:**
- Use `BuildContext` ข้าม `await` โดยไม่เช็ค `mounted` หรือ context guard ผิด
- ถ้า user ออกจาก screen ระหว่าง async call → exception "Looking up a deactivated widget's ancestor" หรือ Navigator stack เพี้ยน

**วิธีแก้:** ทุกครั้งหลัง `await` เช็ค `if (!mounted) return;` ก่อนใช้ context (snackbar, navigator, dialog)

---

### [x] M10. `lib/screens/order_tracking_screen.dart:104, 474` — `unreachable_switch_default`
**ทำไมเป็น bug:**
Switch ครอบทุก enum case แล้ว แต่ยังมี `default:` — code dead, แต่จริง ๆ คือสัญญาณว่ามี case ที่หายไป (Dart ไม่บังคับ exhaustiveness ถ้ามี default)
- ถ้าเพิ่ม status ใหม่ (เช่น `STATUS_RETURNED`) — สวิตช์จะเงียบ ๆ ตก default แทนที่จะ fail loud

**วิธีแก้:** ลบ `default:` แล้วใช้ exhaustive switch เพื่อให้ analyzer warn เมื่อเพิ่ม case

---

### [x] M11. `_loadDeliveryOptions` (`checkout_screen.dart:299`) และ `_handleEditAddress` (line 473), `_buildInputField` (`payment_method_card.dart:907`) ฯลฯ — unused declarations
**ไฟล์:** ดู analyzer output

**ทำไมเป็น bug:**
- Dead code ที่ engineering รุ่นต่อไปจะงงว่าใช้ทำอะไร
- บางอันคือ feature ที่กำลังทำค้าง — ถ้าตั้งใจไว้ใช้ ควรมี TODO หรือ feature flag
- `lib/widgets/reward_card.dart:200` มี `unnecessary_non_null_assertion` (`reward!['level']` แต่ analyzer บอกว่า `reward` ไม่มีทาง null) — ควรลบ `!` เพื่อให้ null safety ทำงานถูก

---

### [x] M12. `MembershipProgressService::getMembershipProgress` รับ user แต่ใน CustomerController ไม่ส่ง user ที่ pre-loaded
ดู M4 — รวมประเด็นเดียวกัน

---

### [x] M13. Reward card `_parseToDouble`, `_claimRewardToDatabase` declared แต่ไม่ใช้
**ไฟล์:** `lib/widgets/reward_card.dart:47, 405`

**ทำไมเป็น bug:** dead code; ถ้า claim flow เปลี่ยนไปแล้ว ควรลบ — ไม่งั้นคนอ่านต่อจะเข้าใจผิดว่ายังใช้

---

### [x] M14. `home_screen.dart:419` field `_pendingFreeItemPicked` — unused
**ไฟล์:** `lib/screens/home_screen.dart:419`

**ทำไมเป็น bug:** field ไม่ใช้ — กิน memory เล็กน้อย และเป็นสัญญาณว่า logic free item อาจจะมี edge case ที่ลืม wire

---

## 🟢 LOW

### [x] L1. `withOpacity` deprecated (47 จุด)
แทนด้วย `.withValues(alpha: x)` ตามที่ analyzer แนะนำ — ไม่กระทบ runtime แต่จะถูกลบใน Flutter version ถัดไป

### [x] L2. `prefer_const_constructors` (4 จุด)
สอบลด rebuild cost เล็กน้อย — `const` constructor ที่หาย

### [x] L3. Unused import `redeem_free_items_screen.dart` ใน `checkout_screen.dart:24`
ลบทิ้ง

### [x] L4. `non_constant_identifier_names` `_removed_showNewOrderFreeItemDialog` ที่ `checkout_screen.dart:1534`
ชื่อตัวแปร snake_case ไม่ตรง convention Dart — เปลี่ยนเป็น camelCase

### [x] L5. `_isLoading`, `_districts`, `_subDistricts` — unused fields
- `lib/screens/profile_edit_screen.dart:28` (`_isLoading`)
- `lib/services/thai_address_service.dart:16, 18` (`_districts`, `_subDistricts`)

### [x] L6. Pint style issues (82 ไฟล์)
รัน `./vendor/bin/pint` ก็จะ fix อัตโนมัติ — ไม่กระทบ behavior

### [x] L7. `lib/screens/profile_edit_screen.dart:65` `district` local variable unused
ลบทิ้งหรือใช้

### [x] L8. `clinic-backend/app/Http/Controllers/CartController.php` เป็น empty stub
ลบทิ้ง หรือ comment ระบุว่ายังไม่ implement (และ remove จาก autoload ถ้าไม่ใช้)

### [x] L9. Hardcoded API base URL `http://10.0.2.2:8000` ใน `ProductController` image URL replacement
**ไฟล์:** `clinic-backend/app/Http/Controllers/ProductController.php:40-42, 76-78, 102-104`

**ทำไมเป็น bug:** logic แทน URL จาก dev emulator → ไม่ควรอยู่ใน production controller. ถ้าจะ rewrite ควรทำผ่าน accessor บน Product model ตามค่า env ไม่ใช่ string match

### [x] L10. Production hostname mismatch — `app_config.dart` thai address path ใช้ `/test/address`
**ไฟล์:** `lib/constants/app_config.dart:32`

**ทำไมเป็น bug:** prefix `/test/` ดูเหมือน dev — ควรย้ายไป `/api/address` หรือ path ที่เป็น production-grade

---

## ภาพรวม / คำแนะนำเรียงความสำคัญ

ก่อน prod merge ครั้งถัดไปควรปิด:
1. **C1, C2** — race condition stock + order_number → data integrity เสี่ยง
2. **C3, C4, C5** — payment authorization gaps → security เสี่ยง (อาจถูก IDOR)
3. **H3** — verify ว่า PaySolutions integration จริงทำงาน (ไม่ใช่ stub) ก่อนรับเงินจริง
4. **H4** — race ระหว่าง cancel กับ payment callback → ลูกค้า dispute ได้

ที่ควรทำต่อในรอบถัดไป (ไม่เร่งเท่าด่วน):
5. **H1, H2** — refactor `Order::booted()` event เป็น explicit call
6. **M4, M5** — N+1 ในหน้า admin customer & membership progress
7. **M6, M7** — frontend lifecycle/auth handling
8. **M8** — replace `print` ด้วย `debugPrint`/logger ทั่วโปรเจกต์

ที่เป็น hygiene พื้นฐาน:
9. รัน `./vendor/bin/pint` (ไม่ใช่ `--test`) เพื่อ auto-fix style
10. แก้ analyzer warnings ที่ unused/use_build_context — ลด noise ใน CI
