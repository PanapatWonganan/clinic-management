<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exquiller Admin</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
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

        /* Recent Activity */
        .recent-activity {
            background: var(--white);
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
        }

        .activity-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .activity-header h3 {
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .activity-item {
            display: flex;
            align-items: center;
            padding: 1rem 0;
            border-bottom: 1px solid var(--border);
        }

        .activity-item:last-child {
            border-bottom: none;
        }

        .activity-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: var(--secondary);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 1rem;
            color: var(--primary);
        }

        .activity-content {
            flex: 1;
        }

        .activity-content h4 {
            font-size: 0.875rem;
            font-weight: 600;
            margin-bottom: 0.25rem;
        }

        .activity-content p {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }

        .activity-time {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }

        /* Sales Chart */
        .sales-chart-section {
            margin-bottom: 2rem;
        }

        .chart-container {
            background: var(--white);
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
        }

        .chart-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 2.5rem;
            flex-wrap: wrap;
            gap: 1rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid rgba(226, 232, 240, 0.5);
        }

        .chart-header h3 {
            font-size: 1.5rem;
            font-weight: 600;
            color: var(--text-primary);
            margin: 0;
        }

        .chart-header p {
            font-size: 0.875rem;
            color: var(--text-secondary);
            margin: 0.25rem 0 0 0;
        }

        .chart-controls {
            display: flex;
            gap: 1rem;
            align-items: center;
        }

        .year-selector, .period-selector, .period-type-selector {
            padding: 0.5rem 1rem;
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            background: var(--white);
            color: var(--text-primary);
            font-size: 0.875rem;
            cursor: pointer;
            transition: border-color 0.2s;
        }

        .year-selector:hover, .period-selector:hover, .period-type-selector:hover {
            border-color: var(--primary);
        }

        .year-selector:focus, .period-selector:focus, .period-type-selector:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .chart-wrapper {
            position: relative;
            height: 450px;
            margin-bottom: 2rem;
            border-radius: 0.5rem;
            overflow: visible;
            padding: 10px 0;
        }

        /* ApexCharts custom styling */
        .chart-wrapper .apexcharts-canvas {
            background: linear-gradient(135deg, #f8fafc 0%, #ffffff 100%);
        }

        .chart-wrapper .apexcharts-tooltip {
            border-radius: 0.5rem !important;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05) !important;
        }

        .chart-wrapper .apexcharts-toolbar {
            background: rgba(255, 255, 255, 0.9) !important;
            backdrop-filter: blur(10px) !important;
            border-radius: 0.5rem !important;
            border: 1px solid var(--border) !important;
        }

        .chart-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border);
        }

        .summary-item {
            text-align: center;
            padding: 1rem;
            background: var(--secondary);
            border-radius: 0.75rem;
        }

        .summary-value {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 0.25rem;
        }

        .summary-label {
            font-size: 0.875rem;
            color: var(--text-secondary);
        }

        .chart-loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 300px;
            color: var(--text-secondary);
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

            .actions-grid {
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
                    <i class="fas fa-spa"></i>
                    Exquiller Admin
                </a>
            </div>

            <nav class="sidebar-nav">
                <a href="{{ route('admin.dashboard') }}" class="nav-item active">
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
                <a href="{{ route('admin.orders.index') }}" class="nav-item">
                    <i class="fas fa-shopping-cart"></i>
                    คำสั่งซื้อ
                </a>
                <a href="{{ route('admin.appointments.index') }}" class="nav-item">
                    <i class="fas fa-calendar-alt"></i>
                    นัดหมาย
                </a>
                <a href="{{ route('admin.reports.index') }}" class="nav-item">
                    <i class="fas fa-chart-bar"></i>
                    รายงาน
                </a>
                <a href="{{ route('admin.settings') }}" class="nav-item">
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
                    <div class="stat-value">฿{{ number_format($stats['today_revenue'], 0) }}</div>
                    <div class="stat-label">รายได้วันนี้</div>
                    <div class="stat-change {{ $stats['revenue_change'] >= 0 ? 'positive' : 'negative' }}">
                        <i class="fas fa-arrow-{{ $stats['revenue_change'] >= 0 ? 'up' : 'down' }}"></i>
                        {{ $stats['revenue_change'] >= 0 ? '+' : '' }}{{ number_format($stats['revenue_change'], 1) }}% จากเมื่อวาน
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-shopping-bag"></i>
                        </div>
                    </div>
                    <div class="stat-value">{{ $stats['today_orders'] }}</div>
                    <div class="stat-label">คำสั่งซื้อวันนี้</div>
                    <div class="stat-change {{ $stats['orders_change'] >= 0 ? 'positive' : 'negative' }}">
                        <i class="fas fa-arrow-{{ $stats['orders_change'] >= 0 ? 'up' : 'down' }}"></i>
                        {{ $stats['orders_change'] >= 0 ? '+' : '' }}{{ number_format($stats['orders_change'], 1) }}% จากเมื่อวาน
                    </div>
                </div>

                <div class="stat-card warning">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-users"></i>
                        </div>
                    </div>
                    <div class="stat-value">{{ $stats['total_customers'] }}</div>
                    <div class="stat-label">ลูกค้าทั้งหมด</div>
                    <div class="stat-change {{ $stats['customers_change'] >= 0 ? 'positive' : 'negative' }}">
                        <i class="fas fa-arrow-{{ $stats['customers_change'] >= 0 ? 'up' : 'down' }}"></i>
                        {{ $stats['customers_change'] >= 0 ? '+' : '' }}{{ number_format($stats['customers_change'], 1) }}% เดือนนี้
                    </div>
                </div>

                <div class="stat-card danger">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-box"></i>
                        </div>
                    </div>
                    <div class="stat-value">{{ $stats['total_products'] }}</div>
                    <div class="stat-label">สินค้าทั้งหมด</div>
                    <div class="stat-change negative">
                        <i class="fas fa-exclamation-triangle"></i>
                        {{ $stats['low_stock_products'] }} รายการใกล้หมด
                    </div>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <h2>การดำเนินการด่วน</h2>
                <div class="actions-grid">
                    <a href="{{ route('admin.customers.index') }}" class="action-btn">
                        <i class="fas fa-user-plus"></i>
                        <span>จัดการลูกค้า</span>
                    </a>
                    <a href="{{ route('admin.products.index') }}" class="action-btn">
                        <i class="fas fa-plus"></i>
                        <span>จัดการสินค้า</span>
                    </a>
                    <a href="{{ route('admin.appointments.index') }}" class="action-btn">
                        <i class="fas fa-calendar-plus"></i>
                        <span>จัดการนัดหมาย</span>
                    </a>
                    <a href="{{ route('admin.export') }}" class="action-btn">
                        <i class="fas fa-download"></i>
                        <span>ส่งออกข้อมูล</span>
                    </a>
                </div>
            </div>

            <!-- Sales Chart -->
            <div class="sales-chart-section">
                <div class="chart-container">
                    <div class="chart-header">
                        <div>
                            <h3>ยอดขายรายเดือน</h3>
                            <p>รายได้และจำนวนคำสั่งซื้อ</p>
                        </div>
                        <div class="chart-controls">
                            <select id="periodTypeSelector" class="period-type-selector">
                                <option value="days" selected>รายวัน</option>
                                <option value="months">รายเดือน</option>
                            </select>
                            <select id="periodSelector" class="period-selector">
                                <!-- Options will be populated by JavaScript -->
                            </select>
                            <select id="yearSelector" class="year-selector" style="display: none;">
                                <option>กำลังโหลด...</option>
                            </select>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div id="salesChart"></div>
                    </div>
                    <div class="chart-summary" id="chartSummary">
                        <!-- Summary will be populated by JavaScript -->
                    </div>
                </div>
            </div>

            <!-- Recent Activity -->
            <div class="recent-activity">
                <div class="activity-header">
                    <h3>กิจกรรมล่าสุด</h3>
                    <a href="#" style="color: var(--primary); font-size: 0.875rem; text-decoration: none;">ดูทั้งหมด</a>
                </div>
                
                @if($recentActivities->count() > 0)
                    @foreach($recentActivities as $activity)
                    <div class="activity-item">
                        <div class="activity-icon">
                            <i class="{{ $activity['icon'] }}"></i>
                        </div>
                        <div class="activity-content">
                            <h4>{{ $activity['title'] }}</h4>
                            <p>{{ $activity['description'] }}</p>
                        </div>
                        <div class="activity-time">{{ $activity['formatted_time'] }}</div>
                    </div>
                    @endforeach
                @else
                    <div class="activity-item">
                        <div class="activity-icon">
                            <i class="fas fa-info-circle"></i>
                        </div>
                        <div class="activity-content">
                            <h4>ยังไม่มีกิจกรรม</h4>
                            <p>ไม่มีกิจกรรมในช่วง 24 ชั่วโมงที่ผ่านมา</p>
                        </div>
                        <div class="activity-time">-</div>
                    </div>
                @endif
            </div>
        </main>
    </div>

    <script>
        // Auto-refresh recent activities every 30 seconds
        function refreshRecentActivities() {
            fetch('{{ route("admin.dashboard.activities") }}', {
                method: 'GET',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    updateActivitiesDisplay(data.activities);
                }
            })
            .catch(error => {
                console.log('Failed to refresh activities:', error);
            });
        }

        function updateActivitiesDisplay(activities) {
            const activityContainer = document.querySelector('.recent-activity');
            const activitySection = activityContainer.querySelector('.activity-header').nextElementSibling;
            
            // Clear existing activities (except header)
            const existingActivities = activityContainer.querySelectorAll('.activity-item');
            existingActivities.forEach(item => item.remove());

            if (activities.length > 0) {
                activities.forEach(activity => {
                    const activityItem = document.createElement('div');
                    activityItem.className = 'activity-item';
                    activityItem.innerHTML = `
                        <div class="activity-icon">
                            <i class="${activity.icon}"></i>
                        </div>
                        <div class="activity-content">
                            <h4>${activity.title}</h4>
                            <p>${activity.description}</p>
                        </div>
                        <div class="activity-time">${activity.formatted_time}</div>
                    `;
                    activityContainer.appendChild(activityItem);
                });
            } else {
                const activityItem = document.createElement('div');
                activityItem.className = 'activity-item';
                activityItem.innerHTML = `
                    <div class="activity-icon">
                        <i class="fas fa-info-circle"></i>
                    </div>
                    <div class="activity-content">
                        <h4>ยังไม่มีกิจกรรม</h4>
                        <p>ไม่มีกิจกรรมในช่วง 24 ชั่วโมงที่ผ่านมา</p>
                    </div>
                    <div class="activity-time">-</div>
                `;
                activityContainer.appendChild(activityItem);
            }
        }

        // Sales Chart functionality
        let salesChart = null;

        function initializeSalesChart() {
            const options = {
                series: [{
                    name: 'รายได้ (บาท)',
                    type: 'area',
                    data: []
                }, {
                    name: 'คำสั่งซื้อ',
                    type: 'line',
                    data: []
                }],
                chart: {
                    height: 380,
                    type: 'line',
                    fontFamily: 'Inter, sans-serif',
                    toolbar: {
                        show: true,
                        tools: {
                            download: true,
                            selection: false,
                            zoom: true,
                            zoomin: true,
                            zoomout: true,
                            pan: true,
                            reset: true
                        }
                    },
                    animations: {
                        enabled: true,
                        easing: 'easeinout',
                        speed: 800,
                        animateGradually: {
                            enabled: true,
                            delay: 150
                        },
                        dynamicAnimation: {
                            enabled: true,
                            speed: 350
                        }
                    }
                },
                colors: ['#667eea', '#10b981'],
                fill: {
                    type: ['gradient', 'solid'],
                    gradient: {
                        shade: 'light',
                        type: 'vertical',
                        shadeIntensity: 0.5,
                        gradientToColors: ['#764ba2', '#10b981'],
                        inverseColors: false,
                        opacityFrom: 0.8,
                        opacityTo: 0.1,
                        stops: [0, 100]
                    }
                },
                stroke: {
                    width: [0, 3],
                    curve: 'smooth'
                },
                plotOptions: {
                    area: {
                        fillTo: 'end'
                    }
                },
                dataLabels: {
                    enabled: false
                },
                legend: {
                    show: true,
                    position: 'bottom',
                    horizontalAlign: 'center',
                    floating: false,
                    fontSize: '14px',
                    fontWeight: 500,
                    offsetY: 10,
                    markers: {
                        width: 12,
                        height: 12,
                        radius: 6
                    },
                    itemMargin: {
                        horizontal: 20,
                        vertical: 5
                    }
                },
                xaxis: {
                    categories: [],
                    title: {
                        text: 'เดือน',
                        style: {
                            fontSize: '14px',
                            fontWeight: 600,
                            color: '#64748b'
                        }
                    },
                    labels: {
                        style: {
                            fontSize: '12px',
                            colors: '#64748b'
                        }
                    }
                },
                yaxis: [{
                    title: {
                        text: 'รายได้ (บาท)',
                        style: {
                            color: '#667eea',
                            fontSize: '14px',
                            fontWeight: 600
                        }
                    },
                    labels: {
                        style: {
                            colors: '#667eea',
                            fontSize: '12px'
                        },
                        formatter: function (value) {
                            return '฿' + new Intl.NumberFormat('th-TH').format(value);
                        }
                    }
                }, {
                    opposite: true,
                    title: {
                        text: 'จำนวนคำสั่งซื้อ',
                        style: {
                            color: '#10b981',
                            fontSize: '14px',
                            fontWeight: 600
                        }
                    },
                    labels: {
                        style: {
                            colors: '#10b981',
                            fontSize: '12px'
                        }
                    }
                }],
                grid: {
                    show: true,
                    borderColor: '#e2e8f0',
                    strokeDashArray: 3,
                    position: 'back',
                    padding: {
                        right: 30,
                        left: 20
                    }
                },
                tooltip: {
                    shared: true,
                    intersect: false,
                    theme: 'light',
                    style: {
                        fontSize: '14px',
                        fontFamily: 'Inter, sans-serif'
                    },
                    y: {
                        formatter: function (value, { series, seriesIndex, dataPointIndex, w }) {
                            if (seriesIndex === 0) {
                                return '฿' + new Intl.NumberFormat('th-TH').format(value);
                            } else {
                                return value + ' คำสั่งซื้อ';
                            }
                        }
                    }
                },
                responsive: [{
                    breakpoint: 768,
                    options: {
                        chart: {
                            height: 320
                        },
                        legend: {
                            position: 'bottom',
                            offsetY: 5
                        },
                        grid: {
                            padding: {
                                right: 15,
                                left: 10
                            }
                        }
                    }
                }]
            };

            salesChart = new ApexCharts(document.querySelector("#salesChart"), options);
            salesChart.render();
        }

        function updatePeriodOptions() {
            const periodType = document.getElementById('periodTypeSelector').value;
            const periodSelector = document.getElementById('periodSelector');
            const yearSelector = document.getElementById('yearSelector');
            
            if (periodType === 'days') {
                // Show daily options
                periodSelector.innerHTML = `
                    <option value="7" selected>7 วันล่าสุด</option>
                    <option value="30">30 วันล่าสุด</option>
                    <option value="90">90 วันล่าสุด</option>
                `;
                yearSelector.style.display = 'none';
                
                // Update chart title
                document.querySelector('.chart-header h3').textContent = 'ยอดขายรายวัน';
                document.querySelector('.chart-header p').textContent = 'รายได้และจำนวนคำสั่งซื้อรายวัน';
            } else {
                // Show monthly options
                periodSelector.innerHTML = `
                    <option value="12">12 เดือนล่าสุด</option>
                    <option value="24">24 เดือนล่าสุด</option>
                    <option value="36">36 เดือนล่าสุด</option>
                    <option value="48">48 เดือนล่าสุด</option>
                    <option value="60">60 เดือนล่าสุด (5 ปี)</option>
                `;
                yearSelector.style.display = 'inline-block';
                
                // Update chart title
                document.querySelector('.chart-header h3').textContent = 'ยอดขายรายเดือน';
                document.querySelector('.chart-header p').textContent = 'รายได้และจำนวนคำสั่งซื้อรายเดือน';
            }
        }

        function loadSalesData() {
            const periodType = document.getElementById('periodTypeSelector').value;
            const periodValue = document.getElementById('periodSelector').value;
            const year = document.getElementById('yearSelector').value;
            
            // Show loading state
            document.getElementById('chartSummary').innerHTML = '<div class="chart-loading"><i class="fas fa-spinner fa-spin"></i> กำลังโหลดข้อมูล...</div>';
            
            let url = `{{ route('admin.dashboard.sales-data') }}?period_type=${periodType}`;
            
            if (periodType === 'days') {
                url += `&days_back=${periodValue}`;
            } else {
                url += `&year=${year}&months_back=${periodValue}`;
            }
            
            fetch(url, {
                method: 'GET',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    updateChart(data.data);
                    updateChartSummary(data.data.summary, data.data.period.type);
                }
            })
            .catch(error => {
                console.error('Error loading sales data:', error);
                document.getElementById('chartSummary').innerHTML = '<div class="chart-loading" style="color: #ef4444;"><i class="fas fa-exclamation-triangle"></i> ไม่สามารถโหลดข้อมูลได้</div>';
            });
        }

        function updateChart(data) {
            const labels = data.sales.map(item => item.period_name);
            const revenueData = data.sales.map(item => item.revenue);
            const ordersData = data.sales.map(item => item.orders);

            // Update chart data
            salesChart.updateSeries([{
                name: 'รายได้ (บาท)',
                data: revenueData
            }, {
                name: 'คำสั่งซื้อ',
                data: ordersData
            }]);

            // Update categories (x-axis labels)
            salesChart.updateOptions({
                xaxis: {
                    categories: labels,
                    title: {
                        text: data.period.type === 'daily' ? 'วันที่' : 'เดือน',
                        style: {
                            fontSize: '14px',
                            fontWeight: 600,
                            color: '#64748b'
                        }
                    }
                },
                yaxis: [{
                    title: {
                        text: data.period.type === 'daily' ? 'รายได้รายวัน (บาท)' : 'รายได้รายเดือน (บาท)',
                        style: {
                            color: '#667eea',
                            fontSize: '14px',
                            fontWeight: 600
                        }
                    },
                    labels: {
                        style: {
                            colors: '#667eea',
                            fontSize: '12px'
                        },
                        formatter: function (value) {
                            return '฿' + new Intl.NumberFormat('th-TH').format(value);
                        }
                    }
                }, {
                    opposite: true,
                    title: {
                        text: data.period.type === 'daily' ? 'คำสั่งซื้อรายวัน' : 'คำสั่งซื้อรายเดือน',
                        style: {
                            color: '#10b981',
                            fontSize: '14px',
                            fontWeight: 600
                        }
                    },
                    labels: {
                        style: {
                            colors: '#10b981',
                            fontSize: '12px'
                        }
                    }
                }]
            });
        }

        function updateChartSummary(summary, periodType) {
            const isDaily = periodType === 'daily';
            const avgLabel = isDaily ? 'รายได้เฉลี่ย/วัน' : 'รายได้เฉลี่ย/เดือน';
            const avgValue = isDaily ? summary.avg_daily_revenue : summary.avg_monthly_revenue;
            const bestPeriodLabel = isDaily ? 'วันที่ขายดีที่สุด' : 'เดือนที่ขายดีที่สุด';
            
            const summaryHtml = `
                <div class="summary-item">
                    <div class="summary-value">฿${new Intl.NumberFormat('th-TH').format(summary.total_revenue)}</div>
                    <div class="summary-label">รายได้รวม</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value">${summary.total_orders.toLocaleString()}</div>
                    <div class="summary-label">คำสั่งซื้อรวม</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value">฿${new Intl.NumberFormat('th-TH').format(avgValue)}</div>
                    <div class="summary-label">${avgLabel}</div>
                </div>
                ${summary.highest_period || summary.highest_day ? `
                <div class="summary-item">
                    <div class="summary-value">${(summary.highest_period || summary.highest_day).period_name}</div>
                    <div class="summary-label">${bestPeriodLabel}</div>
                </div>
                ` : ''}
            `;
            document.getElementById('chartSummary').innerHTML = summaryHtml;
        }

        function loadAvailableYears() {
            return fetch('{{ route("admin.dashboard.available-years") }}', {
                method: 'GET',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    updateYearSelector(data.years, data.latest_year);
                    return data.latest_year;
                }
                return new Date().getFullYear();
            })
            .catch(error => {
                console.error('Error loading available years:', error);
                return new Date().getFullYear();
            });
        }

        function updateYearSelector(years, latestYear) {
            const yearSelector = document.getElementById('yearSelector');
            yearSelector.innerHTML = '';
            
            years.forEach(year => {
                const option = document.createElement('option');
                option.value = year;
                option.textContent = `${parseInt(year) + 543} (${year})`;
                if (year == latestYear) {
                    option.selected = true;
                }
                yearSelector.appendChild(option);
            });
        }

        // Start auto-refresh when page loads
        document.addEventListener('DOMContentLoaded', function() {
            // Initialize sales chart
            initializeSalesChart();
            
            // Initialize period options (default to daily)
            updatePeriodOptions();
            
            // Load available years for monthly view
            loadAvailableYears();
            
            // Load initial data (7 days by default)
            loadSalesData();
            
            // Add event listeners for selectors
            document.getElementById('periodTypeSelector').addEventListener('change', function() {
                updatePeriodOptions();
                loadSalesData();
            });
            document.getElementById('yearSelector').addEventListener('change', loadSalesData);
            document.getElementById('periodSelector').addEventListener('change', loadSalesData);
            
            // Refresh recent activities every 30 seconds
            setInterval(refreshRecentActivities, 30000);
        });
    </script>
</body>
</html>