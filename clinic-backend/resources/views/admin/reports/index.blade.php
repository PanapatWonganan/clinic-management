<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>รายงาน - Beauty Admin</title>
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

        .btn-secondary {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        .reports-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .report-card {
            background: #f8fafc;
            padding: 2rem;
            border-radius: 1rem;
            border: 1px solid #e2e8f0;
            text-align: center;
            transition: all 0.2s;
        }

        .report-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }

        .report-icon {
            width: 60px;
            height: 60px;
            background: #6366f1;
            border-radius: 1rem;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1rem;
            color: white;
            font-size: 1.5rem;
        }

        .report-card h3 {
            font-size: 1.25rem;
            margin-bottom: 0.5rem;
            color: #1e293b;
        }

        .report-card p {
            color: #64748b;
            margin-bottom: 1.5rem;
        }

        .report-btn {
            background: #6366f1;
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            border: none;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.2s;
        }

        .report-btn:hover {
            background: #4f46e5;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-chart-bar"></i> รายงาน</h1>
            </div>
            <div>
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
            </div>
        </div>

        <div class="reports-grid">
            <div class="report-card">
                <div class="report-icon" style="background: #10b981;">
                    <i class="fas fa-dollar-sign"></i>
                </div>
                <h3>รายงานรายได้</h3>
                <p>รายได้รายวัน รายสัปดาห์ และรายเดือน</p>
                <button class="report-btn" onclick="alert('เตรียมสร้างรายงานรายได้')">
                    <i class="fas fa-chart-line"></i>
                    ดูรายงาน
                </button>
            </div>

            <div class="report-card">
                <div class="report-icon" style="background: #f59e0b;">
                    <i class="fas fa-users"></i>
                </div>
                <h3>รายงานลูกค้า</h3>
                <p>สถิติลูกค้าใหม่ และการเข้าใช้บริการ</p>
                <button class="report-btn" onclick="alert('เตรียมสร้างรายงานลูกค้า')">
                    <i class="fas fa-user-chart"></i>
                    ดูรายงาน
                </button>
            </div>

            <div class="report-card">
                <div class="report-icon" style="background: #ef4444;">
                    <i class="fas fa-box"></i>
                </div>
                <h3>รายงานสินค้า</h3>
                <p>สินค้าขายดี สต็อก และยอดขาย</p>
                <button class="report-btn" onclick="alert('เตรียมสร้างรายงานสินค้า')">
                    <i class="fas fa-chart-pie"></i>
                    ดูรายงาน
                </button>
            </div>

            <div class="report-card">
                <div class="report-icon" style="background: #8b5cf6;">
                    <i class="fas fa-calendar-alt"></i>
                </div>
                <h3>รายงานนัดหมาย</h3>
                <p>สถิติการนัดหมายและการเข้ารับบริการ</p>
                <button class="report-btn" onclick="alert('เตรียมสร้างรายงานนัดหมาย')">
                    <i class="fas fa-calendar-check"></i>
                    ดูรายงาน
                </button>
            </div>
        </div>

        <div style="background: #f8fafc; border-radius: 0.5rem; padding: 1.5rem; text-align: left;">
            <h3 style="color: #1e293b; margin-bottom: 1rem;"><i class="fas fa-info-circle"></i> ฟังก์ชันรายงานที่จะมี:</h3>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
                <ul style="color: #64748b; list-style: none; padding-left: 0;">
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> กราฟรายได้แบบ Real-time</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> เปรียบเทียบยอดขายรายเดือน</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> Top 10 สินค้าขายดี</li>
                </ul>
                <ul style="color: #64748b; list-style: none; padding-left: 0;">
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> การเจริญเติบโตของลูกค้า</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> ส่งออกรายงาน PDF/Excel</li>
                    <li style="padding: 0.5rem 0;"><i class="fas fa-check"></i> การวิเคราะห์เชิงลึก</li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>