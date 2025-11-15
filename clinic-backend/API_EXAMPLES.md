# Clinic API Examples

## Base URL
```
http://localhost:8000/api
```

## 1. สร้างผู้ป่วยใหม่ (Create Patient)
```bash
curl -X POST http://localhost:8000/api/patients \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "first_name": "สมชาย",
    "last_name": "ใจดี",
    "email": "somchai@example.com",
    "phone": "081-234-5678",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "address": "123 ถนนสุขุมวิท กรุงเทพมหานคร",
    "emergency_contact": "081-987-6543"
  }'
```

## 2. ดูรายชื่อผู้ป่วยทั้งหมด (Get All Patients)
```bash
curl -X GET http://localhost:8000/api/patients \
  -H "Accept: application/json"
```

## 3. ดูข้อมูลผู้ป่วยคนหนึ่ง (Get Single Patient)
```bash
curl -X GET http://localhost:8000/api/patients/1 \
  -H "Accept: application/json"
```

## 4. สร้างการนัดหมาย (Create Appointment)
```bash
curl -X POST http://localhost:8000/api/appointments \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "patient_id": 1,
    "doctor_name": "หมอสมหญิง",
    "appointment_datetime": "2024-08-01 14:30:00",
    "status": "scheduled",
    "notes": "ตรวจสุขภาพประจำปี"
  }'
```

## 5. ดูการนัดหมายทั้งหมด (Get All Appointments)
```bash
curl -X GET http://localhost:8000/api/appointments \
  -H "Accept: application/json"
```

## 6. แก้ไขข้อมูลผู้ป่วย (Update Patient)
```bash
curl -X PUT http://localhost:8000/api/patients/1 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "phone": "082-345-6789"
  }'
```

## 7. ลบผู้ป่วย (Delete Patient)
```bash
curl -X DELETE http://localhost:8000/api/patients/1 \
  -H "Accept: application/json"
```

## Database Schema

### Patients Table
- id (Primary Key)
- first_name (VARCHAR)
- last_name (VARCHAR)
- email (VARCHAR, UNIQUE)
- phone (VARCHAR)
- date_of_birth (DATE)
- gender (ENUM: male, female, other)
- address (TEXT, NULLABLE)
- emergency_contact (VARCHAR, NULLABLE)
- created_at, updated_at (TIMESTAMPS)

### Appointments Table
- id (Primary Key)
- patient_id (Foreign Key)
- doctor_name (VARCHAR)
- appointment_datetime (DATETIME)
- status (ENUM: scheduled, completed, cancelled)
- notes (TEXT, NULLABLE)
- created_at, updated_at (TIMESTAMPS)

## วิธีการรัน Server
```bash
cd clinic-backend
php artisan serve
```

Server จะรันที่: http://localhost:8000 