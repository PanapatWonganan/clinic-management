<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการคำสั่งซื้อ - Beauty Admin</title>
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

        .btn-secondary {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        .btn-primary {
            background: #8b5cf6;
            color: white;
            font-size: 0.875rem;
        }

        .btn-primary:hover {
            background: #7c3aed;
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

        .orders-table {
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
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-pending_payment { background: #fef3c7; color: #d97706; }
        .status-payment_uploaded { background: #dbeafe; color: #2563eb; }
        .status-paid { background: #d1fae5; color: #059669; }
        .status-confirmed { background: #dcfce7; color: #16a34a; }
        .status-processing { background: #e0f2fe; color: #0891b2; }
        .status-shipped { background: #f3e8ff; color: #7c3aed; }
        .status-delivered { background: #ecfccb; color: #65a30d; }
        .status-cancelled { background: #fee2e2; color: #dc2626; }

        .payment-slips {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .slip-count {
            background: #8b5cf6;
            color: white;
            padding: 0.25rem 0.5rem;
            border-radius: 0.5rem;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .no-orders {
            text-align: center;
            padding: 3rem;
            color: #64748b;
        }

        .pagination {
            display: flex;
            justify-content: center;
            margin-top: 2rem;
            gap: 0.5rem;
        }

        .pagination a, .pagination span {
            padding: 0.5rem 0.75rem;
            border: 1px solid #e2e8f0;
            border-radius: 0.375rem;
            color: #64748b;
            text-decoration: none;
        }

        .pagination .current {
            background: #8b5cf6;
            color: white;
            border-color: #8b5cf6;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-shopping-cart"></i> จัดการคำสั่งซื้อ</h1>
            </div>
            <div style="display: flex; gap: 0.5rem;">
                <a href="{{ route('admin.rewards.index') }}" class="btn btn-primary">
                    <i class="fas fa-gift"></i>
                    จัดการรางวัล
                </a>
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">{{ $stats['total_orders'] }}</div>
                <div class="stat-label">คำสั่งซื้อทั้งหมด</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['pending_payment'] }}</div>
                <div class="stat-label">รอชำระเงิน</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['payment_uploaded'] }}</div>
                <div class="stat-label">อัพโหลดสลิปแล้ว</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['paid'] }}</div>
                <div class="stat-label">ชำระเงินแล้ว</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ $stats['delivered'] }}</div>
                <div class="stat-label">ส่งสำเร็จแล้ว</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">฿{{ number_format($stats['total_revenue'], 2) }}</div>
                <div class="stat-label">ยอดขายรวม</div>
            </div>
        </div>

        <div class="orders-table">
            @if($orders->count() > 0)
                <table>
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>ลูกค้า</th>
                            <th>ยอดรวม</th>
                            <th>สถานะ</th>
                            <th>Payment Slips</th>
                            <th>วันที่สั่ง</th>
                            <th>จัดการ</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($orders as $order)
                        <tr>
                            <td>
                                <span style="font-weight: 600; color: #8b5cf6;">
                                    #{{ $order->order_number ?? $order->id }}
                                </span>
                            </td>
                            <td>
                                <div>
                                    <div style="font-weight: 500;">{{ $order->user->name ?? 'ไม่ระบุ' }}</div>
                                    <div style="color: #64748b; font-size: 0.875rem;">{{ $order->user->email ?? '' }}</div>
                                </div>
                            </td>
                            <td>
                                <span style="font-weight: 600;">฿{{ number_format($order->total_amount, 2) }}</span>
                            </td>
                            <td>
                                <span class="status-badge status-{{ $order->status }}">
                                    {{ $order->status_display }}
                                </span>
                            </td>
                            <td>
                                <div class="payment-slips">
                                    @if($order->paymentSlips->count() > 0)
                                        <span class="slip-count">{{ $order->paymentSlips->count() }} สลิป</span>
                                        @foreach($order->paymentSlips as $slip)
                                            <span class="status-badge status-{{ $slip->status }}">
                                                {{ $slip->status_display }}
                                            </span>
                                        @endforeach
                                    @else
                                        <span style="color: #9ca3af;">ไม่มีสลิป</span>
                                    @endif
                                </div>
                            </td>
                            <td>
                                <div style="font-size: 0.875rem;">
                                    <div>{{ $order->created_at->format('d/m/Y') }}</div>
                                    <div style="color: #64748b;">{{ $order->created_at->format('H:i') }}</div>
                                </div>
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem;">
                                    <a href="{{ route('admin.orders.show', $order->id) }}" class="btn btn-primary">
                                        <i class="fas fa-eye"></i> ดูรายละเอียด
                                    </a>
                                </div>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                
                <div class="pagination">
                    {{ $orders->links() }}
                </div>
            @else
                <div class="no-orders">
                    <i class="fas fa-shopping-cart" style="font-size: 3rem; color: #cbd5e1; margin-bottom: 1rem;"></i>
                    <h3>ยังไม่มีคำสั่งซื้อ</h3>
                    <p>เมื่อมีลูกค้าสั่งซื้อสินค้า คำสั่งซื้อจะแสดงที่นี่</p>
                </div>
            @endif
        </div>
    </div>
</body>
</html>