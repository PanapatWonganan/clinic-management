<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Beauty Clinic Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --primary: #6366f1;
            --primary-light: #818cf8;
            --primary-dark: #4f46e5;
            --secondary: #f1f5f9;
            --accent: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --text-primary: #1e293b;
            --text-secondary: #64748b;
            --border: #e2e8f0;
            --white: #ffffff;
            --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            min-height: 100vh;
            color: var(--text-primary);
        }

        .dashboard {
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            width: 280px;
            background: var(--white);
            box-shadow: var(--shadow-lg);
            display: flex;
            flex-direction: column;
        }

        .sidebar-header {
            padding: 2rem 1.5rem;
            border-bottom: 1px solid var(--border);
        }

        .logo {
            display: flex;
            align-items: center;
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--primary);
            text-decoration: none;
        }

        .logo i {
            margin-right: 0.75rem;
            font-size: 1.75rem;
        }

        .sidebar-nav {
            flex: 1;
            padding: 1.5rem 0;
        }

        .nav-item {
            display: block;
            padding: 0.875rem 1.5rem;
            color: var(--text-secondary);
            text-decoration: none;
            transition: all 0.2s;
            border-left: 3px solid transparent;
            margin: 0.25rem 0;
        }

        .nav-item:hover, .nav-item.active {
            background: linear-gradient(90deg, rgba(99, 102, 241, 0.1) 0%, transparent 100%);
            color: var(--primary);
            border-left-color: var(--primary);
        }

        .nav-item i {
            margin-right: 0.75rem;
            width: 20px;
            text-align: center;
        }

        .sidebar-footer {
            padding: 1.5rem;
            border-top: 1px solid var(--border);
        }

        .user-profile {
            display: flex;
            align-items: center;
            padding: 0.75rem;
            border-radius: 0.75rem;
            background: var(--secondary);
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            margin-right: 0.75rem;
        }

        .user-info h4 {
            font-size: 0.875rem;
            font-weight: 600;
            margin-bottom: 0.25rem;
        }

        .user-info p {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }

        /* Main Content */
        .main-content {
            flex: 1;
            padding: 2rem;
            overflow-y: auto;
        }

        .header {
            margin-bottom: 2rem;
        }

        .header h1 {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }

        .header p {
            color: var(--text-secondary);
            font-size: 1.125rem;
        }

        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--white);
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            transition: all 0.3s;
            position: relative;
            overflow: hidden;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }

        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--primary), var(--primary-light));
        }

        .stat-card.accent::before {
            background: linear-gradient(90deg, var(--accent), #34d399);
        }

        .stat-card.warning::before {
            background: linear-gradient(90deg, var(--warning), #fbbf24);
        }

        .stat-card.danger::before {
            background: linear-gradient(90deg, var(--danger), #f87171);
        }

        .stat-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            color: white;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
        }

        .stat-card.accent .stat-icon {
            background: linear-gradient(135deg, var(--accent), #34d399);
        }

        .stat-card.warning .stat-icon {
            background: linear-gradient(135deg, var(--warning), #fbbf24);
        }

        .stat-card.danger .stat-icon {
            background: linear-gradient(135deg, var(--danger), #f87171);
        }

        .stat-value {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
            color: var(--text-primary);
        }

        .stat-label {
            font-size: 0.875rem;
            color: var(--text-secondary);
            margin-bottom: 1rem;
        }

        .stat-change {
            display: flex;
            align-items: center;
            font-size: 0.875rem;
            font-weight: 500;
        }

        .stat-change.positive {
            color: var(--accent);
        }

        .stat-change.negative {
            color: var(--danger);
        }

        .stat-change i {
            margin-right: 0.5rem;
        }

        /* Quick Actions */
        .quick-actions {
            background: var(--white);
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            margin-bottom: 2rem;
        }

        .quick-actions h2 {
            font-size: 1.5rem;
            font-weight: 600;
            margin-bottom: 1.5rem;
            color: var(--text-primary);
        }

        .actions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
        }

        .action-btn {
            display: flex;
            align-items: center;
            padding: 1rem 1.5rem;
            border: 2px solid var(--border);
            border-radius: 0.75rem;
            text-decoration: none;
            color: var(--text-primary);
            transition: all 0.2s;
            background: var(--white);
        }

        .action-btn:hover {
            border-color: var(--primary);
            transform: translateY(-1px);
            box-shadow: var(--shadow);
        }

        .action-btn i {
            margin-right: 0.75rem;
            font-size: 1.25rem;
            color: var(--primary);
        }

        .action-btn span {
            font-weight: 500;
        }

        /* Logout Button */
        .logout-btn {
            background: linear-gradient(135deg, var(--danger), #f87171);
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            font-size: 0.875rem;
            width: 100%;
            justify-content: center;
        }

        .logout-btn:hover {
            transform: translateY(-1px);
            box-shadow: var(--shadow);
        }

        .logout-btn i {
            margin-right: 0.5rem;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .dashboard {
                flex-direction: column;
            }

            .sidebar {
                width: 100%;
                height: auto;
            }

            .main-content {
                padding: 1rem;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <!-- Sidebar -->
        <aside class="sidebar">
            <div class="sidebar-header">
                <a href="#" class="logo">
                    <i class="fas fa-gem"></i>
                    Beauty Admin
                </a>
            </div>

            <nav class="sidebar-nav">
                <a href="#" class="nav-item active">
                    <i class="fas fa-home"></i>
                    Dashboard
                </a>
                <a href="{{ route('admin.customers.index') }}" class="nav-item">
                    <i class="fas fa-users"></i>
                    จัดการลูกค้า
                </a>
                <a href="{{ route('admin.products.index') }}" class="nav-item">
                    <i class="fas fa-box"></i>
                    จัดการสินค้า
                </a>
                <a href="#" class="nav-item">
                    <i class="fas fa-shopping-cart"></i>
                    คำสั่งซื้อ
                </a>
                <a href="#" class="nav-item">
                    <i class="fas fa-calendar-alt"></i>
                    นัดหมาย
                </a>
                <a href="#" class="nav-item">
                    <i class="fas fa-chart-bar"></i>
                    รายงาน
                </a>
                <a href="#" class="nav-item">
                    <i class="fas fa-cog"></i>
                    ตั้งค่า
                </a>
            </nav>

            <div class="sidebar-footer">
                <div class="user-profile">
                    <div class="user-avatar">A</div>
                    <div class="user-info">
                        <h4>Admin</h4>
                        <p>ผู้ดูแลระบบ</p>
                    </div>
                </div>
                <div style="margin-top: 1rem;">
                    <form method="POST" action="{{ route('admin.logout') }}">
                        @csrf
                        <button type="submit" class="logout-btn">
                            <i class="fas fa-sign-out-alt"></i>
                            ออกจากระบบ
                        </button>
                    </form>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="main-content">
            <header class="header">
                <h1>Dashboard</h1>
                <p>ภาพรวมธุรกิจของคุณวันนี้</p>
            </header>

            <!-- Stats Grid -->
            <div class="stats-grid">
                <div class="stat-card accent">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-dollar-sign"></i>
                        </div>
                    </div>
                    <div class="stat-value">฿15,750</div>
                    <div class="stat-label">รายได้วันนี้</div>
                    <div class="stat-change positive">
                        <i class="fas fa-arrow-up"></i>
                        +12.5% จากเมื่อวาน
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-shopping-bag"></i>
                        </div>
                    </div>
                    <div class="stat-value">24</div>
                    <div class="stat-label">คำสั่งซื้อวันนี้</div>
                    <div class="stat-change positive">
                        <i class="fas fa-arrow-up"></i>
                        +8.3% จากเมื่อวาน
                    </div>
                </div>

                <div class="stat-card warning">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-users"></i>
                        </div>
                    </div>
                    <div class="stat-value">{{ \App\Models\User::count() }}</div>
                    <div class="stat-label">ลูกค้าทั้งหมด</div>
                    <div class="stat-change positive">
                        <i class="fas fa-arrow-up"></i>
                        +15.2% เดือนนี้
                    </div>
                </div>

                <div class="stat-card danger">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-box"></i>
                        </div>
                    </div>
                    <div class="stat-value">{{ \App\Models\Product::count() }}</div>
                    <div class="stat-label">สินค้าทั้งหมด</div>
                    <div class="stat-change negative">
                        <i class="fas fa-exclamation-triangle"></i>
                        {{ \App\Models\Product::where('stock', '<=', 5)->count() }} รายการใกล้หมด
                    </div>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <h2>การดำเนินการด่วน</h2>
                <div class="actions-grid">
                    <a href="{{ route('admin.customers.index') }}" class="action-btn">
                        <i class="fas fa-user-plus"></i>
                        <span>เพิ่มลูกค้าใหม่</span>
                    </a>
                    <a href="{{ route('admin.products.index') }}" class="action-btn">
                        <i class="fas fa-plus"></i>
                        <span>เพิ่มสินค้าใหม่</span>
                    </a>
                    <a href="#" class="action-btn">
                        <i class="fas fa-calendar-plus"></i>
                        <span>เพิ่มนัดหมาย</span>
                    </a>
                    <a href="{{ route('admin.export') }}" class="action-btn">
                        <i class="fas fa-download"></i>
                        <span>ส่งออกข้อมูล</span>
                    </a>
                </div>
            </div>
        </main>
    </div>
</body>
</html> 