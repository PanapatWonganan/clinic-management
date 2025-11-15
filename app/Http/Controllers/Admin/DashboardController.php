<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        // **ใช้ข้อมูลตัวอย่างเพื่อแสดง Design ก่อน**
        
        // สถิติหลัก
        $stats = [
            'today_revenue' => 15750,
            'today_orders' => 12,
            'total_customers' => 156,
            'total_products' => 24,
            'this_month_revenue' => 285400,
            'this_month_orders' => 89,
            'new_customers' => 23,
            'low_stock_products' => 3,
            'revenue_change' => 12.5,
            'orders_change' => 8.3,
            'customers_change' => 15.2,
        ];
        
        // ข้อมูลสำหรับกราฟ
        $chartData = [
            'sales' => [
                'labels' => ['Jul 20', 'Jul 21', 'Jul 22', 'Jul 23', 'Jul 24', 'Jul 25', 'Jul 26'],
                'data' => [12500, 18200, 15800, 22100, 19500, 25300, 15750]
            ],
            'order_status' => [
                'pending' => 8,
                'confirmed' => 15,
                'shipped' => 12,
                'delivered' => 45,
                'cancelled' => 3,
            ]
        ];
        
        // ออเดอร์ล่าสุด
        $recentOrders = [
            [
                'id' => 1,
                'order_number' => 'ORD-20250726-001',
                'customer_name' => 'สมใส สวยงาม',
                'total_amount' => 1240,
                'formatted_total' => '฿1,240',
                'status' => 'confirmed',
                'status_text' => 'ยืนยันแล้ว',
                'status_color' => 'info',
                'created_at' => '26/07/2025 14:30',
                'items_count' => 3
            ],
            [
                'id' => 2,
                'order_number' => 'ORD-20250726-002',
                'customer_name' => 'วิภา คลาสสิค',
                'total_amount' => 990,
                'formatted_total' => '฿990',
                'status' => 'shipped',
                'status_text' => 'จัดส่งแล้ว',
                'status_color' => 'primary',
                'created_at' => '26/07/2025 11:15',
                'items_count' => 1
            ],
            [
                'id' => 3,
                'order_number' => 'ORD-20250725-015',
                'customer_name' => 'สมชาย ใจดี',
                'total_amount' => 2590,
                'formatted_total' => '฿2,590',
                'status' => 'delivered',
                'status_text' => 'ส่งสำเร็จ',
                'status_color' => 'success',
                'created_at' => '25/07/2025 16:45',
                'items_count' => 4
            ],
            [
                'id' => 4,
                'order_number' => 'ORD-20250725-012',
                'customer_name' => 'นิดา บิวตี้',
                'total_amount' => 750,
                'formatted_total' => '฿750',
                'status' => 'pending',
                'status_text' => 'รอดำเนินการ',
                'status_color' => 'warning',
                'created_at' => '25/07/2025 09:20',
                'items_count' => 2
            ]
        ];
        
        // สินค้าขายดี
        $topProducts = [
            [
                'name' => 'เซรั่มวิตามินซี ออร์แกนิค',
                'total_sold' => 45,
                'total_revenue' => 44550,
                'formatted_revenue' => '฿44,550',
                'image' => null,
                'stock' => 15
            ],
            [
                'name' => 'ครีมกันแดด SPF 50+',
                'total_sold' => 38,
                'total_revenue' => 17100,
                'formatted_revenue' => '฿17,100',
                'image' => null,
                'stock' => 22
            ],
            [
                'name' => 'มาส์กหน้าคอลลาเจน',
                'total_sold' => 32,
                'total_revenue' => 9568,
                'formatted_revenue' => '฿9,568',
                'image' => null,
                'stock' => 8
            ],
            [
                'name' => 'ลิปสติกเนื้อแมท',
                'total_sold' => 28,
                'total_revenue' => 9800,
                'formatted_revenue' => '฿9,800',
                'image' => null,
                'stock' => 5
            ]
        ];
        
        // สถิติสมาชิก
        $membershipStats = [
            'bronze' => 45,
            'silver' => 28,
            'gold' => 18,
            'platinum' => 8,
        ];

        return view('admin.dashboard.index', compact(
            'stats',
            'chartData', 
            'recentOrders',
            'topProducts',
            'membershipStats'
        ));
    }

    private function getMainStats()
    {
        $today = Carbon::today();
        $thisWeek = [Carbon::now()->startOfWeek(), Carbon::now()->endOfWeek()];
        $thisMonth = [Carbon::now()->startOfMonth(), Carbon::now()->endOfMonth()];
        $lastMonth = [Carbon::now()->subMonth()->startOfMonth(), Carbon::now()->subMonth()->endOfMonth()];

        // รายได้วันนี้
        $todayRevenue = Order::whereDate('created_at', $today)
            ->where('status', '!=', 'cancelled')
            ->sum('total_amount') ?? 0;

        // รายได้เดือนนี้
        $thisMonthRevenue = Order::whereBetween('created_at', $thisMonth)
            ->where('status', '!=', 'cancelled')
            ->sum('total_amount') ?? 0;

        // รายได้เดือนที่แล้ว
        $lastMonthRevenue = Order::whereBetween('created_at', $lastMonth)
            ->where('status', '!=', 'cancelled')
            ->sum('total_amount') ?? 0;

        // คำนวณ % เปลี่ยนแปลง
        $revenueChange = $lastMonthRevenue > 0 
            ? (($thisMonthRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100 
            : 0;

        // ออเดอร์วันนี้
        $todayOrders = Order::whereDate('created_at', $today)->count();
        
        // ออเดอร์เดือนนี้
        $thisMonthOrders = Order::whereBetween('created_at', $thisMonth)->count();
        $lastMonthOrders = Order::whereBetween('created_at', $lastMonth)->count();
        
        $ordersChange = $lastMonthOrders > 0 
            ? (($thisMonthOrders - $lastMonthOrders) / $lastMonthOrders) * 100 
            : 0;

        // ลูกค้าทั้งหมด
        $totalCustomers = User::count();
        
        // ลูกค้าใหม่เดือนนี้
        $newCustomers = User::whereBetween('created_at', $thisMonth)->count();
        $lastMonthNewCustomers = User::whereBetween('created_at', $lastMonth)->count();
        
        $customersChange = $lastMonthNewCustomers > 0 
            ? (($newCustomers - $lastMonthNewCustomers) / $lastMonthNewCustomers) * 100 
            : 0;

        // สินค้าทั้งหมด
        $totalProducts = Product::count();
        
        // สินค้าที่กำลังจะหมด (< 10 ชิ้น)
        $lowStockProducts = Product::where('stock_quantity', '<', 10)->count();

        return [
            'today_revenue' => $todayRevenue,
            'today_orders' => $todayOrders,
            'total_customers' => $totalCustomers,
            'total_products' => $totalProducts,
            'this_month_revenue' => $thisMonthRevenue,
            'this_month_orders' => $thisMonthOrders,
            'new_customers' => $newCustomers,
            'low_stock_products' => $lowStockProducts,
            'revenue_change' => $revenueChange,
            'orders_change' => $ordersChange,
            'customers_change' => $customersChange,
        ];
    }

    private function getChartData()
    {
        // ข้อมูลยอดขาย 7 วันที่ผ่านมา
        $salesData = [];
        $labels = [];
        
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $labels[] = $date->format('M d');
            
            $revenue = Order::whereDate('created_at', $date)
                ->where('status', '!=', 'cancelled')
                ->sum('total_amount') ?? 0;
                
            $salesData[] = $revenue;
        }

        // ข้อมูลสถานะออเดอร์
        $orderStatusData = [
            'pending' => Order::where('status', 'pending')->count(),
            'confirmed' => Order::where('status', 'confirmed')->count(),
            'shipped' => Order::where('status', 'shipped')->count(),
            'delivered' => Order::where('status', 'delivered')->count(),
            'cancelled' => Order::where('status', 'cancelled')->count(),
        ];

        return [
            'sales' => [
                'labels' => $labels,
                'data' => $salesData
            ],
            'order_status' => $orderStatusData
        ];
    }

    private function getRecentOrders()
    {
        return Order::with(['user', 'orderItems'])
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($order) {
                return [
                    'id' => $order->id,
                    'order_number' => $order->order_number ?? 'ORD-' . str_pad($order->id, 6, '0', STR_PAD_LEFT),
                    'customer_name' => $order->user->name ?? 'ไม่ระบุ',
                    'total_amount' => $order->total_amount,
                    'formatted_total' => '฿' . number_format($order->total_amount, 0),
                    'status' => $order->status,
                    'status_text' => $order->status_text,
                    'status_color' => $order->status_color,
                    'created_at' => $order->created_at->format('d/m/Y H:i'),
                    'items_count' => $order->orderItems->count()
                ];
            });
    }

    private function getTopProducts()
    {
        return OrderItem::with('product')
            ->selectRaw('product_id, SUM(quantity) as total_sold, SUM(quantity * price) as total_revenue')
            ->whereHas('order', function($query) {
                $query->where('status', '!=', 'cancelled');
            })
            ->groupBy('product_id')
            ->orderBy('total_sold', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'name' => $item->product->name ?? 'สินค้าไม่ระบุ',
                    'total_sold' => $item->total_sold,
                    'total_revenue' => $item->total_revenue,
                    'formatted_revenue' => '฿' . number_format($item->total_revenue, 0),
                    'image' => $item->product->image_path ?? null,
                    'stock' => $item->product->stock_quantity ?? 0
                ];
            });
    }

    private function getMembershipStats()
    {
        // สถิติการกระจายของลูกค้าตามระดับสมาชิก
        // ถ้ามี MembershipLevel model
        return [
            'bronze' => User::where('membership_level', 'bronze')->count(),
            'silver' => User::where('membership_level', 'silver')->count(), 
            'gold' => User::where('membership_level', 'gold')->count(),
            'platinum' => User::where('membership_level', 'platinum')->count(),
        ];
    }
} 