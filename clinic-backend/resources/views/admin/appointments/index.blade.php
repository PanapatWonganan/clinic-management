<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการนัดหมาย - Beauty Admin</title>
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
            max-width: 1200px;
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

        .btn-primary {
            background: #6366f1;
            color: white;
        }

        .btn-primary:hover {
            background: #4f46e5;
        }

        .btn-secondary {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        .calendar-view {
            margin-bottom: 2rem;
        }

        .calendar-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 1rem;
            padding: 1rem;
            background: #f8fafc;
            border-radius: 0.75rem;
            border: 1px solid #e2e8f0;
        }

        .calendar-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 1px;
            background: #e2e8f0;
            border-radius: 0.75rem;
            overflow: hidden;
        }

        .calendar-day {
            background: white;
            padding: 1rem;
            min-height: 80px;
            display: flex;
            flex-direction: column;
        }

        .day-number {
            font-weight: 600;
            margin-bottom: 0.5rem;
        }

        .appointment-count {
            font-size: 0.75rem;
            color: #6366f1;
            background: #eff6ff;
            padding: 0.25rem 0.5rem;
            border-radius: 0.25rem;
        }

        .content {
            text-align: center;
            padding: 2rem 0;
        }

        .content h2 {
            font-size: 1.5rem;
            margin-bottom: 1rem;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-calendar-alt"></i> จัดการนัดหมาย</h1>
            </div>
            <div>
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
                <button class="btn btn-primary" onclick="alert('เตรียมเพิ่มฟังก์ชันเพิ่มนัดหมายใหม่')">
                    <i class="fas fa-calendar-plus"></i>
                    เพิ่มนัดหมาย
                </button>
            </div>
        </div>

        <div class="calendar-view">
            <div class="calendar-header">
                <h2 style="color: #1e293b; margin: 0;">
                    <i class="fas fa-calendar"></i>
                    {{ date('F Y') }}
                </h2>
                <div>
                    <button class="btn btn-secondary" onclick="alert('เปลี่ยนเดือนก่อนหน้า')">
                        <i class="fas fa-chevron-left"></i>
                    </button>
                    <button class="btn btn-secondary" onclick="alert('เปลี่ยนเดือนถัดไป')">
                        <i class="fas fa-chevron-right"></i>
                    </button>
                </div>
            </div>

            <div class="calendar-grid">
                @for($day = 1; $day <= 30; $day++)
                    <div class="calendar-day">
                        <div class="day-number">{{ $day }}</div>
                        @if($day % 7 == 0 || $day % 5 == 0)
                            <div class="appointment-count">{{ rand(1, 3) }} นัด</div>
                        @endif
                    </div>
                @endfor
            </div>
        </div>

        <div class="content">
            <div style="background: #f8fafc; border-radius: 0.5rem; padding: 1.5rem; text-align: left;">
                <h3 style="color: #1e293b; margin-bottom: 1rem;"><i class="fas fa-info-circle"></i> ฟังก์ชันที่จะมี:</h3>
                <ul style="color: #64748b; list-style: none; padding-left: 0;">
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> ปฏิทินนัดหมายแบบเต็ม</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> เพิ่ม แก้ไข ยกเลิกนัดหมาย</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> แจ้งเตือนนัดหมาย</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> รายการนัดหมายรายวัน</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> ประวัติการรักษา</li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>