<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Beauty Admin Dashboard')</title>
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <style>
        :root {
            --main-purple: #8386CB;
            --purple-text: #383B77;
            --light-purple: #EEEEFF;
            --card-bg: #ADAFE2;
            --progress-bg: #EBECF8;
            --badge-bg: #DADCF4;
            --sidebar-width: 250px;
        }
        
        * {
            font-family: 'Prompt', sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #f8f9ff 0%, #e8ebff 100%);
            margin: 0;
            overflow-x: hidden;
        }
        
        /* Sidebar */
        .sidebar {
            position: fixed;
            top: 0;
            left: 0;
            height: 100vh;
            width: var(--sidebar-width);
            background: linear-gradient(180deg, var(--main-purple) 0%, var(--purple-text) 100%);
            color: white;
            z-index: 1000;
            transition: all 0.3s ease;
            box-shadow: 4px 0 20px rgba(131, 134, 203, 0.3);
        }
        
        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            text-align: center;
        }
        
        .sidebar-header h3 {
            margin: 0;
            font-weight: 600;
            color: white;
        }
        
        .sidebar-header .logo-icon {
            font-size: 2rem;
            color: #FE7798;
            margin-bottom: 10px;
        }
        
        .sidebar-menu {
            list-style: none;
            padding: 20px 0;
            margin: 0;
        }
        
        .sidebar-menu li {
            margin: 0;
        }
        
        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 15px 25px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
        }
        
        .sidebar-menu a:hover,
        .sidebar-menu a.active {
            background: rgba(255,255,255,0.1);
            color: white;
            border-left-color: #FE7798;
            transform: translateX(5px);
        }
        
        .sidebar-menu i {
            width: 20px;
            margin-right: 15px;
            text-align: center;
        }
        
        /* Main Content */
        .main-content {
            margin-left: var(--sidebar-width);
            min-height: 100vh;
            transition: all 0.3s ease;
        }
        
        /* Top Bar */
        .top-bar {
            background: white;
            padding: 15px 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }
        
        .page-title {
            font-size: 1.5rem;
            font-weight: 600;
            color: var(--purple-text);
            margin: 0;
        }
        
        .user-menu {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--main-purple), #FE7798);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
        }
        
        /* Cards */
        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 25px rgba(131, 134, 203, 0.1);
            border: 1px solid rgba(131, 134, 203, 0.1);
            transition: all 0.3s ease;
            height: 100%;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 40px rgba(131, 134, 203, 0.2);
        }
        
        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
            margin-bottom: 15px;
        }
        
        .stat-value {
            font-size: 2rem;
            font-weight: 700;
            color: var(--purple-text);
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #6B7280;
            font-size: 0.9rem;
            margin-bottom: 10px;
        }
        
        .stat-change {
            font-size: 0.8rem;
            padding: 4px 8px;
            border-radius: 20px;
            font-weight: 500;
        }
        
        .stat-change.positive {
            background: #D1FAE5;
            color: #065F46;
        }
        
        .stat-change.negative {
            background: #FEE2E2;
            color: #991B1B;
        }
        
        /* Chart Container */
        .chart-container {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 25px rgba(131, 134, 203, 0.1);
            margin-bottom: 25px;
        }
        
        .chart-title {
            font-size: 1.2rem;
            font-weight: 600;
            color: var(--purple-text);
            margin-bottom: 20px;
        }
        
        /* Recent Orders Table */
        .table-container {
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 25px rgba(131, 134, 203, 0.1);
        }
        
        .table-header {
            background: linear-gradient(135deg, var(--main-purple), var(--purple-text));
            color: white;
            padding: 20px 25px;
            font-weight: 600;
        }
        
        .table {
            margin-bottom: 0;
        }
        
        .table td {
            padding: 15px 25px;
            border-color: #F3F4F6;
            vertical-align: middle;
        }
        
        .badge {
            font-size: 0.75rem;
            padding: 6px 12px;
            border-radius: 20px;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }
            
            .main-content {
                margin-left: 0;
            }
            
            .top-bar {
                padding: 15px 20px;
            }
        }
        
        /* Custom Scrollbar */
        ::-webkit-scrollbar {
            width: 8px;
        }
        
        ::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        
        ::-webkit-scrollbar-thumb {
            background: var(--main-purple);
            border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
            background: var(--purple-text);
        }
    </style>
    
    @stack('styles')
</head>
<body>
    <!-- Sidebar -->
    <nav class="sidebar">
        <div class="sidebar-header">
            <div class="logo-icon">
                <i class="fas fa-gem"></i>
            </div>
            <h3>Beauty Admin</h3>
        </div>
        
        <ul class="sidebar-menu">
            <li>
                <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                    <i class="fas fa-tachometer-alt"></i>
                    <span>หน้าแรก</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.products.*') ? 'active' : '' }}">
                    <i class="fas fa-box"></i>
                    <span>สินค้า</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.orders.*') ? 'active' : '' }}">
                    <i class="fas fa-shopping-cart"></i>
                    <span>คำสั่งซื้อ</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.customers.*') ? 'active' : '' }}">
                    <i class="fas fa-users"></i>
                    <span>ลูกค้า</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.memberships.*') ? 'active' : '' }}">
                    <i class="fas fa-crown"></i>
                    <span>สมาชิก</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">
                    <i class="fas fa-chart-bar"></i>
                    <span>รายงาน</span>
                </a>
            </li>
            <li>
                <a href="#" class="{{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">
                    <i class="fas fa-cog"></i>
                    <span>ตั้งค่า</span>
                </a>
            </li>
            <li style="margin-top: 30px; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 20px;">
                <form method="POST" action="{{ route('admin.logout') }}">
                    @csrf
                    <button type="submit" style="background: none; border: none; width: 100%; text-align: left; padding: 15px 25px; color: rgba(255,255,255,0.8); display: flex; align-items: center; transition: all 0.3s ease;">
                        <i class="fas fa-sign-out-alt" style="width: 20px; margin-right: 15px; text-align: center;"></i>
                        <span>ออกจากระบบ</span>
                    </button>
                </form>
            </li>
        </ul>
    </nav>

    <!-- Main Content -->
    <main class="main-content">
        <!-- Top Bar -->
        <div class="top-bar">
            <h1 class="page-title">@yield('page-title', 'Dashboard')</h1>
            <div class="user-menu">
                <div class="user-avatar">
                    {{ substr(Auth::user()->name, 0, 1) }}
                </div>
                <div>
                    <div style="font-weight: 600; color: var(--purple-text);">{{ Auth::user()->name }}</div>
                    <div style="font-size: 0.8rem; color: #6B7280;">ผู้ดูแลระบบ</div>
                </div>
            </div>
        </div>

        <!-- Page Content -->
        <div class="container-fluid px-4">
            @yield('content')
        </div>
    </main>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    @stack('scripts')
</body>
</html> 