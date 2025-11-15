<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการรางวัล - Beauty Admin</title>
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

        .top-nav {
            background: white;
            border-radius: 1rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            padding: 1rem 2rem;
            margin-bottom: 2rem;
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .nav-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            border-radius: 0.5rem;
            text-decoration: none;
            color: #64748b;
            font-weight: 500;
            transition: all 0.2s;
        }

        .nav-link:hover, .nav-link.active {
            background: #8b5cf6;
            color: white;
        }

        .container {
            max-width: 1400px;
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
            background: #8b5cf6;
            color: white;
            font-size: 0.875rem;
        }

        .btn-primary:hover {
            background: #7c3aed;
        }

        .btn-success {
            background: #10b981;
            color: white;
            font-size: 0.875rem;
        }

        .btn-success:hover {
            background: #059669;
        }

        .btn-danger {
            background: #ef4444;
            color: white;
            font-size: 0.875rem;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: #f8fafc;
            padding: 1.5rem;
            border-radius: 0.75rem;
            text-align: center;
            border: 1px solid #e2e8f0;
        }

        .stat-value {
            font-size: 1.5rem;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 0.5rem;
        }

        .stat-label {
            color: #64748b;
            font-size: 0.875rem;
        }

        .rewards-table {
            overflow-x: auto;
            border-radius: 0.75rem;
            border: 1px solid #e2e8f0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            background: #f8fafc;
            padding: 1rem;
            text-align: left;
            font-weight: 600;
            color: #374151;
            border-bottom: 1px solid #e2e8f0;
        }

        td {
            padding: 1rem;
            border-bottom: 1px solid #f3f4f6;
        }

        tr:hover {
            background: #f9fafb;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.25rem;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .status-pending {
            background: #fef3c7;
            color: #92400e;
        }

        .status-approved {
            background: #d1fae5;
            color: #065f46;
        }

        .status-rejected {
            background: #fee2e2;
            color: #991b1b;
        }

        .btn-sm {
            padding: 0.375rem 0.75rem;
            font-size: 0.75rem;
        }
    </style>
</head>
<body>
    <!-- Top Navigation -->
    <div class="top-nav">
        <a href="{{ route('admin.dashboard') }}" class="nav-link">
            <i class="fas fa-home"></i>
            Dashboard
        </a>
        <a href="{{ route('admin.customers.index') }}" class="nav-link">
            <i class="fas fa-users"></i>
            ลูกค้า
        </a>
        <a href="{{ route('admin.products.index') }}" class="nav-link">
            <i class="fas fa-box"></i>
            สินค้า
        </a>
        <a href="{{ route('admin.orders.index') }}" class="nav-link">
            <i class="fas fa-shopping-cart"></i>
            ออเดอร์
        </a>
        <a href="{{ route('admin.payment-slips.index') }}" class="nav-link">
            <i class="fas fa-receipt"></i>
            สลิป
        </a>
        <a href="{{ route('admin.rewards.index') }}" class="nav-link active">
            <i class="fas fa-gift"></i>
            รางวัล
        </a>
    </div>

    <div class="container">
        <div class="header">
            <h1><i class="fas fa-gift"></i> จัดการรางวัล</h1>
        </div>

        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">{{ $stats['total_claims'] }}</div>
                <div class="stat-label">รวมทั้งหมด</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['pending_claims'] }}</div>
                <div class="stat-label">รอดำเนินการ</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['approved_claims'] }}</div>
                <div class="stat-label">อนุมัติแล้ว</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['rejected_claims'] }}</div>
                <div class="stat-label">ปฏิเสธแล้ว</div>
            </div>
        </div>

        <!-- Rewards Table -->
        <div class="rewards-table">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>ผู้ใช้</th>
                        <th>Level</th>
                        <th>ประเภท</th>
                        <th>สถานะ</th>
                        <th>วันที่แลก</th>
                        <th>การจัดการ</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($rewards as $reward)
                        <tr>
                            <td>#{{ $reward->id }}</td>
                            <td>
                                <strong>{{ $reward->user->name ?? 'N/A' }}</strong><br>
                                <small class="text-gray-500">{{ $reward->user->email ?? 'N/A' }}</small>
                            </td>
                            <td>
                                <span class="font-semibold">Level {{ $reward->level }}</span>
                            </td>
                            <td>{{ $reward->reward_type }}</td>
                            <td>
                                <span class="status-badge status-{{ $reward->status }}">
                                    @if($reward->status === 'pending')
                                        <i class="fas fa-clock"></i> รอดำเนินการ
                                    @elseif($reward->status === 'approved')
                                        <i class="fas fa-check"></i> อนุมัติแล้ว
                                    @else
                                        <i class="fas fa-times"></i> ปฏิเสธแล้ว
                                    @endif
                                </span>
                            </td>
                            <td>{{ $reward->created_at->format('d/m/Y H:i') }}</td>
                            <td>
                                @if($reward->status === 'pending')
                                    <button class="btn btn-success btn-sm" onclick="updateRewardStatus({{ $reward->id }}, 'approved')">
                                        <i class="fas fa-check"></i> อนุมัติ
                                    </button>
                                    <button class="btn btn-danger btn-sm" onclick="updateRewardStatus({{ $reward->id }}, 'rejected')">
                                        <i class="fas fa-times"></i> ปฏิเสธ
                                    </button>
                                @else
                                    <span class="text-gray-500">-</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center text-gray-500">ไม่มีข้อมูลรางวัล</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        @if($rewards->hasPages())
            <div class="mt-4">
                {{ $rewards->links() }}
            </div>
        @endif
    </div>

    <script>
        function updateRewardStatus(rewardId, status) {
            if (!confirm(`คุณต้องการ${status === 'approved' ? 'อนุมัติ' : 'ปฏิเสธ'}รางวัลนี้หรือไม่?`)) {
                return;
            }

            fetch(`/admin/rewards/${rewardId}/status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({
                    status: status,
                    admin_notes: ''
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('เกิดข้อผิดพลาด: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('เกิดข้อผิดพลาดในการเชื่อมต่อ');
            });
        }
    </script>
</body>
</html>