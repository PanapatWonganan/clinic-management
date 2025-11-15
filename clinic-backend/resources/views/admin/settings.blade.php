<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ตั้งค่าระบบ - Beauty Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            min-height: 100vh;
            color: #1e293b;
            padding: 2rem;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 1rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            padding: 2rem;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid #e2e8f0;
        }

        h1 {
            font-size: 1.875rem;
            font-weight: 700;
            color: #1e293b;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.75rem 1.5rem;
            border-radius: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            border: none;
        }

        .btn-secondary {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        .btn-primary {
            background: #6366f1;
            color: white;
        }

        .btn-primary:hover {
            background: #4f46e5;
        }

        .settings-section {
            margin-bottom: 2rem;
            padding: 1.5rem;
            background: #f8fafc;
            border-radius: 0.75rem;
            border: 1px solid #e2e8f0;
        }

        .settings-section h3 {
            font-size: 1.25rem;
            margin-bottom: 1rem;
            color: #1e293b;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        .form-label {
            display: block;
            font-weight: 500;
            margin-bottom: 0.5rem;
            color: #374151;
        }

        .form-input {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid #d1d5db;
            border-radius: 0.5rem;
            font-size: 0.875rem;
        }

        .form-input:focus {
            outline: none;
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-cog"></i> ตั้งค่าระบบ</h1>
            </div>
            <div>
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
            </div>
        </div>

        <div class="settings-section">
            <h3><i class="fas fa-store"></i> ข้อมูลร้าน</h3>
            <div class="form-group">
                <label class="form-label">ชื่อร้าน</label>
                <input type="text" class="form-input" value="Beauty Clinic">
            </div>
            <div class="form-group">
                <label class="form-label">ที่อยู่</label>
                <textarea class="form-input" rows="3">123 ถนนสุขุมวิท แขวงคลองเตย เขตคลองเตย กรุงเทพมหานคร 10110</textarea>
            </div>
            <div class="form-group">
                <label class="form-label">เบอร์โทร</label>
                <input type="text" class="form-input" value="02-123-4567">
            </div>
            <div class="form-group">
                <label class="form-label">อีเมล</label>
                <input type="email" class="form-input" value="contact@beautyclinic.com">
            </div>
        </div>

        <div class="settings-section">
            <h3><i class="fas fa-bell"></i> การแจ้งเตือน</h3>
            <div class="form-group">
                <label style="display: flex; align-items: center; gap: 0.5rem;">
                    <input type="checkbox" checked> แจ้งเตือนออเดอร์ใหม่
                </label>
            </div>
            <div class="form-group">
                <label style="display: flex; align-items: center; gap: 0.5rem;">
                    <input type="checkbox" checked> แจ้งเตือนสินค้าใกล้หมด
                </label>
            </div>
            <div class="form-group">
                <label style="display: flex; align-items: center; gap: 0.5rem;">
                    <input type="checkbox" checked> แจ้งเตือนนัดหมายใหม่
                </label>
            </div>
        </div>

        <div class="settings-section">
            <h3><i class="fas fa-palette"></i> การแสดงผล</h3>
            <div class="form-group">
                <label class="form-label">ธีมสี</label>
                <select class="form-input">
                    <option value="default">Default (น้ำเงิน)</option>
                    <option value="green">เขียว</option>
                    <option value="purple">ม่วง</option>
                    <option value="pink">ชมพู</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">ภาษาระบบ</label>
                <select class="form-input">
                    <option value="th">ไทย</option>
                    <option value="en">English</option>
                </select>
            </div>
        </div>

        <div style="text-align: center; padding-top: 1rem;">
            <button class="btn btn-primary" onclick="alert('บันทึกการตั้งค่าเรียบร้อย!')">
                <i class="fas fa-save"></i>
                บันทึกการตั้งค่า
            </button>
        </div>
    </div>
</body>
</html>