@extends('layouts.admin')

@section('page-title', 'Dashboard')

@section('content')
<!-- Stats Cards Row -->
<div class="row g-4 mb-4">
    <!-- Today Revenue -->
    <div class="col-lg-3 col-md-6">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #10B981, #34D399);">
                <i class="fas fa-dollar-sign"></i>
            </div>
            <div class="stat-value">฿{{ number_format($stats['today_revenue'], 0) }}</div>
            <div class="stat-label">รายได้วันนี้</div>
            <span class="stat-change {{ $stats['revenue_change'] >= 0 ? 'positive' : 'negative' }}">
                <i class="fas fa-{{ $stats['revenue_change'] >= 0 ? 'arrow-up' : 'arrow-down' }}"></i>
                {{ number_format(abs($stats['revenue_change']), 1) }}% จากเดือนที่แล้ว
            </span>
        </div>
    </div>

    <!-- Today Orders -->
    <div class="col-lg-3 col-md-6">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #3B82F6, #60A5FA);">
                <i class="fas fa-shopping-cart"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['today_orders']) }}</div>
            <div class="stat-label">ออเดอร์วันนี้</div>
            <span class="stat-change {{ $stats['orders_change'] >= 0 ? 'positive' : 'negative' }}">
                <i class="fas fa-{{ $stats['orders_change'] >= 0 ? 'arrow-up' : 'arrow-down' }}"></i>
                {{ number_format(abs($stats['orders_change']), 1) }}% จากเดือนที่แล้ว
            </span>
        </div>
    </div>

    <!-- Total Customers -->
    <div class="col-lg-3 col-md-6">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #8B5CF6, #A78BFA);">
                <i class="fas fa-users"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['total_customers']) }}</div>
            <div class="stat-label">ลูกค้าทั้งหมด</div>
            <span class="stat-change {{ $stats['customers_change'] >= 0 ? 'positive' : 'negative' }}">
                <i class="fas fa-{{ $stats['customers_change'] >= 0 ? 'arrow-up' : 'arrow-down' }}"></i>
                {{ number_format(abs($stats['customers_change']), 1) }}% ลูกค้าใหม่เดือนนี้
            </span>
        </div>
    </div>

    <!-- Total Products -->
    <div class="col-lg-3 col-md-6">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #F59E0B, #FBBF24);">
                <i class="fas fa-box"></i>
            </div>
            <div class="stat-value">{{ number_format($stats['total_products']) }}</div>
            <div class="stat-label">สินค้าทั้งหมด</div>
            @if($stats['low_stock_products'] > 0)
                <span class="stat-change negative">
                    <i class="fas fa-exclamation-triangle"></i>
                    {{ $stats['low_stock_products'] }} รายการใกล้หมด
                </span>
            @else
                <span class="stat-change positive">
                    <i class="fas fa-check"></i>
                    สต็อกเพียงพอ
                </span>
            @endif
        </div>
    </div>
</div>

<!-- Charts Row -->
<div class="row g-4 mb-4">
    <!-- Sales Chart -->
    <div class="col-lg-8">
        <div class="chart-container">
            <div class="chart-title">ยอดขาย 7 วันย้อนหลัง</div>
            <canvas id="salesChart" height="100"></canvas>
        </div>
    </div>

    <!-- Order Status Chart -->
    <div class="col-lg-4">
        <div class="chart-container">
            <div class="chart-title">สถานะคำสั่งซื้อ</div>
            <canvas id="orderStatusChart"></canvas>
        </div>
    </div>
</div>

<!-- Data Tables Row -->
<div class="row g-4">
    <!-- Recent Orders -->
    <div class="col-lg-8">
        <div class="table-container">
            <div class="table-header">
                <h5 class="mb-0">คำสั่งซื้อล่าสุด</h5>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>หมายเลขออเดอร์</th>
                            <th>ลูกค้า</th>
                            <th>ยอดรวม</th>
                            <th>สถานะ</th>
                            <th>วันที่</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($recentOrders as $order)
                            <tr>
                                <td>
                                    <span class="fw-bold text-primary">#{{ $order['order_number'] }}</span>
                                    <br>
                                    <small class="text-muted">{{ $order['items_count'] }} รายการ</small>
                                </td>
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="user-avatar me-2" style="width: 32px; height: 32px; font-size: 0.8rem;">
                                            {{ substr($order['customer_name'], 0, 1) }}
                                        </div>
                                        {{ $order['customer_name'] }}
                                    </div>
                                </td>
                                <td>
                                    <span class="fw-bold">{{ $order['formatted_total'] }}</span>
                                </td>
                                <td>
                                    <span class="badge bg-{{ $order['status_color'] }}">
                                        {{ $order['status_text'] }}
                                    </span>
                                </td>
                                <td>
                                    <small>{{ $order['created_at'] }}</small>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="text-center py-4">
                                    <i class="fas fa-shopping-cart fa-2x text-muted mb-2"></i>
                                    <p class="text-muted mb-0">ยังไม่มีคำสั่งซื้อ</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Top Products & Quick Stats -->
    <div class="col-lg-4">
        <!-- Top Products -->
        <div class="chart-container mb-4">
            <div class="chart-title">สินค้าขายดี</div>
            @forelse($topProducts as $product)
                <div class="d-flex align-items-center mb-3 pb-3 border-bottom">
                    <div class="flex-shrink-0 me-3">
                        @if($product['image'])
                            <img src="{{ $product['image'] }}" alt="{{ $product['name'] }}" 
                                 class="rounded" style="width: 48px; height: 48px; object-fit: cover;">
                        @else
                            <div style="width: 48px; height: 48px; background: linear-gradient(135deg, var(--main-purple), #FE7798); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: white;">
                                <i class="fas fa-box"></i>
                            </div>
                        @endif
                    </div>
                    <div class="flex-grow-1">
                        <h6 class="mb-1">{{ $product['name'] }}</h6>
                        <small class="text-muted">ขายได้ {{ $product['total_sold'] }} ชิ้น</small>
                        <div class="fw-bold text-success">{{ $product['formatted_revenue'] }}</div>
                    </div>
                </div>
            @empty
                <div class="text-center py-4">
                    <i class="fas fa-chart-bar fa-2x text-muted mb-2"></i>
                    <p class="text-muted mb-0">ยังไม่มีข้อมูลการขาย</p>
                </div>
            @endforelse
        </div>

        <!-- Membership Stats -->
        <div class="chart-container">
            <div class="chart-title">สถิติสมาชิก</div>
            <div class="row g-2">
                <div class="col-6">
                    <div class="text-center p-3" style="background: linear-gradient(135deg, #CD7F32, #E6A85C); border-radius: 10px; color: white;">
                        <i class="fas fa-medal fa-2x mb-2"></i>
                        <div class="fw-bold">{{ $membershipStats['bronze'] ?? 0 }}</div>
                        <small>Bronze</small>
                    </div>
                </div>
                <div class="col-6">
                    <div class="text-center p-3" style="background: linear-gradient(135deg, #C0C0C0, #E5E5E5); border-radius: 10px; color: #333;">
                        <i class="fas fa-medal fa-2x mb-2"></i>
                        <div class="fw-bold">{{ $membershipStats['silver'] ?? 0 }}</div>
                        <small>Silver</small>
                    </div>
                </div>
                <div class="col-6">
                    <div class="text-center p-3" style="background: linear-gradient(135deg, #FFD700, #FFA500); border-radius: 10px; color: white;">
                        <i class="fas fa-crown fa-2x mb-2"></i>
                        <div class="fw-bold">{{ $membershipStats['gold'] ?? 0 }}</div>
                        <small>Gold</small>
                    </div>
                </div>
                <div class="col-6">
                    <div class="text-center p-3" style="background: linear-gradient(135deg, #E5E4E2, #DCDCDC); border-radius: 10px; color: #333;">
                        <i class="fas fa-gem fa-2x mb-2"></i>
                        <div class="fw-bold">{{ $membershipStats['platinum'] ?? 0 }}</div>
                        <small>Platinum</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Quick Actions -->
<div class="row g-4 mt-4">
    <div class="col-12">
        <div class="chart-container">
            <div class="chart-title">ดำเนินการด่วน</div>
            <div class="row g-3">
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, var(--main-purple), var(--purple-text)); color: white; border-radius: 15px;">
                        <i class="fas fa-plus fa-2x mb-2"></i>
                        <br>เพิ่มสินค้า
                    </button>
                </div>
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, #10B981, #34D399); color: white; border-radius: 15px;">
                        <i class="fas fa-list fa-2x mb-2"></i>
                        <br>จัดการออเดอร์
                    </button>
                </div>
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; border-radius: 15px;">
                        <i class="fas fa-users fa-2x mb-2"></i>
                        <br>ลูกค้า
                    </button>
                </div>
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, #F59E0B, #FBBF24); color: white; border-radius: 15px;">
                        <i class="fas fa-chart-bar fa-2x mb-2"></i>
                        <br>รายงาน
                    </button>
                </div>
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, #8B5CF6, #A78BFA); color: white; border-radius: 15px;">
                        <i class="fas fa-crown fa-2x mb-2"></i>
                        <br>สมาชิก
                    </button>
                </div>
                <div class="col-lg-2 col-md-4 col-6">
                    <button class="btn w-100 p-3" style="background: linear-gradient(135deg, #6B7280, #9CA3AF); color: white; border-radius: 15px;">
                        <i class="fas fa-cog fa-2x mb-2"></i>
                        <br>ตั้งค่า
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
// Sales Chart
const salesCtx = document.getElementById('salesChart').getContext('2d');
new Chart(salesCtx, {
    type: 'line',
    data: {
        labels: @json($chartData['sales']['labels']),
        datasets: [{
            label: 'ยอดขาย (฿)',
            data: @json($chartData['sales']['data']),
            borderColor: '#8386CB',
            backgroundColor: 'rgba(131, 134, 203, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#8386CB',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 6,
            pointHoverRadius: 8
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(0,0,0,0.05)'
                },
                ticks: {
                    callback: function(value) {
                        return '฿' + value.toLocaleString();
                    }
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        },
        elements: {
            point: {
                hoverBackgroundColor: '#FE7798'
            }
        }
    }
});

// Order Status Chart
const statusCtx = document.getElementById('orderStatusChart').getContext('2d');
const statusData = @json($chartData['order_status']);
new Chart(statusCtx, {
    type: 'doughnut',
    data: {
        labels: ['รอดำเนินการ', 'ยืนยันแล้ว', 'จัดส่งแล้ว', 'ส่งสำเร็จ', 'ยกเลิก'],
        datasets: [{
            data: [
                statusData.pending || 0,
                statusData.confirmed || 0, 
                statusData.shipped || 0,
                statusData.delivered || 0,
                statusData.cancelled || 0
            ],
            backgroundColor: [
                '#F59E0B',
                '#3B82F6', 
                '#8B5CF6',
                '#10B981',
                '#EF4444'
            ],
            borderWidth: 0,
            cutout: '70%'
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 15,
                    usePointStyle: true,
                    font: {
                        size: 12
                    }
                }
            }
        }
    }
});

// Add click handlers for quick action buttons
document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-2px)';
        this.style.boxShadow = '0 8px 25px rgba(131, 134, 203, 0.3)';
    });
    
    button.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
        this.style.boxShadow = 'none';
    });
});
</script>
@endpush 