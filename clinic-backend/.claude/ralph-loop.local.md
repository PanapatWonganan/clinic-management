---
active: true
iteration: 1
session_id: 
max_iterations: 30
completion_promise: "ALL_BUGS_FIXED"
started_at: "2026-05-03T08:41:43Z"
---

TASK: แก้ bug ตาม BUG_REPORT.md ทีละตัว

WORKFLOW:
1. อ่าน BUG_REPORT.md
2. หา bug ที่ยังไม่ติ๊ก [ ]
3. ถ้าเป็น Flutter → เขียน test reproduce bug ใน test/
4. ถ้าเป็น Laravel → เขียน test ใน tests/Feature/
5. รัน test → ยืนยันว่า fail (เพราะ bug มีจริง)
6. แก้ code
7. รัน test → ต้อง pass
8. รัน flutter test + php artisan test ทั้งหมด → ต้องไม่ break ของเดิม
9. ติ๊ก [x] ใน BUG_REPORT.md + commit
10. ทำ bug ถัดไป
11. เมื่อ bug ติ๊กครบ → output <promise>ALL_BUGS_FIXED</promise>

ห้าม:
- ลบ bug ออกจาก report โดยไม่แก้
- ใช้ // ignore: หรือ @phpstan-ignore
- ลบ test เดิม

