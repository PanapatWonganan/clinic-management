<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Product;
use App\Models\Order;
use App\Models\CustomerAddress;
use App\Models\PaymentSlip;
use Illuminate\Http\Request;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        $today = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();
        
        // Calculate today's revenue from orders (only approved/paid orders)
        $todayRevenue = Order::whereDate('created_at', $today)
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->sum('total_amount');
            
        // Calculate today's orders count
        $todayOrders = Order::whereDate('created_at', $today)->count();
        
        // Calculate today's revenue change (compare with yesterday)
        $yesterday = Carbon::yesterday();
        $yesterdayRevenue = Order::whereDate('created_at', $yesterday)
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->sum('total_amount');
            
        $revenueChange = 0;
        if ($yesterdayRevenue > 0) {
            $revenueChange = (($todayRevenue - $yesterdayRevenue) / $yesterdayRevenue) * 100;
        } elseif ($todayRevenue > 0) {
            $revenueChange = 100;
        }
        
        // Calculate today's orders change (compare with yesterday) 
        $yesterdayOrders = Order::whereDate('created_at', $yesterday)->count();
        $ordersChange = 0;
        if ($yesterdayOrders > 0) {
            $ordersChange = (($todayOrders - $yesterdayOrders) / $yesterdayOrders) * 100;
        } elseif ($todayOrders > 0) {
            $ordersChange = 100;
        }
        
        // Calculate customers growth this month
        $totalCustomers = User::count();
        $newCustomersThisMonth = User::where('created_at', '>=', $thisMonth)->count();
        $lastMonth = Carbon::now()->subMonth()->startOfMonth();
        $lastMonthEnd = Carbon::now()->subMonth()->endOfMonth();
        $lastMonthCustomers = User::whereBetween('created_at', [$lastMonth, $lastMonthEnd])->count();
        
        $customersChange = 0;
        if ($lastMonthCustomers > 0) {
            $customersChange = (($newCustomersThisMonth - $lastMonthCustomers) / $lastMonthCustomers) * 100;
        } elseif ($newCustomersThisMonth > 0) {
            $customersChange = 100;
        }
        
        // Product statistics
        $totalProducts = Product::count();
        $lowStockProducts = Product::where('stock', '<=', 5)->count();
        
        $stats = [
            'today_revenue' => $todayRevenue,
            'today_orders' => $todayOrders, 
            'total_customers' => $totalCustomers,
            'total_products' => $totalProducts,
            'low_stock_products' => $lowStockProducts,
            'revenue_change' => $revenueChange,
            'orders_change' => $ordersChange,
            'customers_change' => $customersChange,
        ];
        
        // Get recent activities
        $recentActivities = $this->getRecentActivities();
        
        return view('admin-dashboard', compact('stats', 'recentActivities'));
    }

    /**
     * Get recent activities for AJAX requests
     */
    public function getActivities()
    {
        $recentActivities = $this->getRecentActivities();
        
        return response()->json([
            'success' => true,
            'activities' => $recentActivities
        ]);
    }

    /**
     * Get monthly sales data for chart
     */
    public function getSalesData(Request $request)
    {
        $request->validate([
            'year' => 'nullable|integer|min:2019|max:2029',
            'months_back' => 'nullable|integer|min:1|max:60',
            'days_back' => 'nullable|integer|min:1|max:365',
            'period_type' => 'nullable|string|in:days,months'
        ]);

        $periodType = $request->period_type ?? 'days';
        
        if ($periodType === 'days') {
            return $this->getDailySalesData($request);
        } else {
            return $this->getMonthlySalesData($request);
        }
    }

    private function getDailySalesData(Request $request)
    {
        $daysBack = $request->days_back ?? 7; // Default to 7 days
        
        $endDate = Carbon::now()->endOfDay();
        $startDate = $endDate->copy()->subDays($daysBack - 1)->startOfDay();

        $salesData = [];
        $currentDate = $startDate->copy();

        while ($currentDate <= $endDate) {
            $dayStart = $currentDate->copy()->startOfDay();
            $dayEnd = $currentDate->copy()->endOfDay();
            
            $dailyRevenue = Order::whereBetween('created_at', [$dayStart, $dayEnd])
                ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
                ->sum('total_amount');
                
            $dailyOrders = Order::whereBetween('created_at', [$dayStart, $dayEnd])
                ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
                ->count();

            $salesData[] = [
                'period' => $currentDate->format('Y-m-d'),
                'period_name' => $currentDate->locale('th')->isoFormat('DD MMM'),
                'revenue' => (float) $dailyRevenue,
                'orders' => $dailyOrders,
                'avg_order_value' => $dailyOrders > 0 ? (float) ($dailyRevenue / $dailyOrders) : 0
            ];

            $currentDate->addDay();
        }

        // Calculate growth rates
        for ($i = 1; $i < count($salesData); $i++) {
            $previous = $salesData[$i - 1];
            $current = &$salesData[$i];
            
            if ($previous['revenue'] > 0) {
                $current['revenue_growth'] = (($current['revenue'] - $previous['revenue']) / $previous['revenue']) * 100;
            } else {
                $current['revenue_growth'] = $current['revenue'] > 0 ? 100 : 0;
            }
            
            if ($previous['orders'] > 0) {
                $current['orders_growth'] = (($current['orders'] - $previous['orders']) / $previous['orders']) * 100;
            } else {
                $current['orders_growth'] = $current['orders'] > 0 ? 100 : 0;
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'period' => [
                    'start' => $startDate->format('Y-m-d'),
                    'end' => $endDate->format('Y-m-d'),
                    'days_count' => $daysBack,
                    'type' => 'daily'
                ],
                'sales' => $salesData,
                'summary' => [
                    'total_revenue' => array_sum(array_column($salesData, 'revenue')),
                    'total_orders' => array_sum(array_column($salesData, 'orders')),
                    'avg_daily_revenue' => count($salesData) > 0 ? array_sum(array_column($salesData, 'revenue')) / count($salesData) : 0,
                    'highest_day' => count($salesData) > 0 ? collect($salesData)->sortByDesc('revenue')->first() : null
                ]
            ]
        ]);
    }

    private function getMonthlySalesData(Request $request)
    {
        $year = $request->year ?? date('Y');
        $monthsBack = $request->months_back ?? 12; // Default to 12 months

        $endDate = Carbon::createFromDate($year, 12, 31)->endOfMonth();
        $startDate = $endDate->copy()->subMonths($monthsBack - 1)->startOfMonth();

        $salesData = [];
        $currentDate = $startDate->copy();

        while ($currentDate <= $endDate) {
            $monthStart = $currentDate->copy()->startOfMonth();
            $monthEnd = $currentDate->copy()->endOfMonth();
            
            $monthlyRevenue = Order::whereBetween('created_at', [$monthStart, $monthEnd])
                ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
                ->sum('total_amount');
                
            $monthlyOrders = Order::whereBetween('created_at', [$monthStart, $monthEnd])
                ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
                ->count();

            $salesData[] = [
                'period' => $currentDate->format('Y-m'),
                'period_name' => $currentDate->locale('th')->isoFormat('MMM YYYY'),
                'revenue' => (float) $monthlyRevenue,
                'orders' => $monthlyOrders,
                'avg_order_value' => $monthlyOrders > 0 ? (float) ($monthlyRevenue / $monthlyOrders) : 0
            ];

            $currentDate->addMonth();
        }

        // Calculate growth rates
        for ($i = 1; $i < count($salesData); $i++) {
            $previous = $salesData[$i - 1];
            $current = &$salesData[$i];
            
            if ($previous['revenue'] > 0) {
                $current['revenue_growth'] = (($current['revenue'] - $previous['revenue']) / $previous['revenue']) * 100;
            } else {
                $current['revenue_growth'] = $current['revenue'] > 0 ? 100 : 0;
            }
            
            if ($previous['orders'] > 0) {
                $current['orders_growth'] = (($current['orders'] - $previous['orders']) / $previous['orders']) * 100;
            } else {
                $current['orders_growth'] = $current['orders'] > 0 ? 100 : 0;
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'period' => [
                    'start' => $startDate->format('Y-m-d'),
                    'end' => $endDate->format('Y-m-d'),
                    'months_count' => $monthsBack,
                    'type' => 'monthly'
                ],
                'sales' => $salesData,
                'summary' => [
                    'total_revenue' => array_sum(array_column($salesData, 'revenue')),
                    'total_orders' => array_sum(array_column($salesData, 'orders')),
                    'avg_monthly_revenue' => count($salesData) > 0 ? array_sum(array_column($salesData, 'revenue')) / count($salesData) : 0,
                    'highest_period' => count($salesData) > 0 ? collect($salesData)->sortByDesc('revenue')->first() : null
                ]
            ]
        ]);
    }

    /**
     * Get available years with sales data
     */
    public function getAvailableYears()
    {
        $years = Order::selectRaw('YEAR(created_at) as year')
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->groupBy('year')
            ->orderBy('year', 'desc')
            ->pluck('year')
            ->toArray();

        // Ensure we have at least current year
        $currentYear = date('Y');
        if (!in_array($currentYear, $years)) {
            array_unshift($years, $currentYear);
        }

        return response()->json([
            'success' => true,
            'years' => $years,
            'latest_year' => !empty($years) ? $years[0] : $currentYear
        ]);
    }

    /**
     * Get recent activities from the database
     */
    private function getRecentActivities()
    {
        $activities = collect();
        
        // Recent orders (last 24 hours)
        $recentOrders = Order::with('user')
            ->where('created_at', '>=', Carbon::now()->subHours(24))
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();
            
        foreach ($recentOrders as $order) {
            $activities->push([
                'icon' => 'fas fa-shopping-cart',
                'title' => 'คำสั่งซื้อใหม่',
                'description' => 'คำสั่งซื้อ #' . $order->order_number . ' มูลค่า ฿' . number_format($order->total_amount, 0),
                'time' => $order->created_at,
                'type' => 'order'
            ]);
        }
        
        // Recent customer registrations (last 24 hours)
        $recentCustomers = User::where('created_at', '>=', Carbon::now()->subHours(24))
            ->orderBy('created_at', 'desc')
            ->limit(2)
            ->get();
            
        foreach ($recentCustomers as $customer) {
            $activities->push([
                'icon' => 'fas fa-user-plus',
                'title' => 'ลูกค้าใหม่สมัครสมาชิก',
                'description' => 'คุณ' . $customer->name . ' ได้สมัครเป็นสมาชิกใหม่',
                'time' => $customer->created_at,
                'type' => 'customer'
            ]);
        }
        
        // Recent address additions (last 24 hours)
        $recentAddresses = CustomerAddress::with('user')
            ->where('created_at', '>=', Carbon::now()->subHours(24))
            ->orderBy('created_at', 'desc')
            ->limit(2)
            ->get();
            
        foreach ($recentAddresses as $address) {
            $activities->push([
                'icon' => 'fas fa-map-marker-alt',
                'title' => 'เพิ่มที่อยู่ใหม่',
                'description' => 'คุณ' . $address->user->name . ' เพิ่มที่อยู่: ' . $address->district . ', ' . $address->province,
                'time' => $address->created_at,
                'type' => 'address'
            ]);
        }
        
        // Recent payment slips (last 24 hours)
        $recentPayments = PaymentSlip::with('order.user')
            ->where('created_at', '>=', Carbon::now()->subHours(24))
            ->orderBy('created_at', 'desc')
            ->limit(2)
            ->get();
            
        foreach ($recentPayments as $payment) {
            $activities->push([
                'icon' => 'fas fa-credit-card',
                'title' => 'อัพโหลดสลิปชำระเงิน',
                'description' => 'คำสั่งซื้อ #' . $payment->order->order_number . ' อัพโหลดสลิป',
                'time' => $payment->created_at,
                'type' => 'payment'
            ]);
        }
        
        // Low stock alerts
        $lowStockProducts = Product::where('stock', '<=', 5)
            ->orderBy('stock')
            ->limit(2)
            ->get();
            
        foreach ($lowStockProducts as $product) {
            $activities->push([
                'icon' => 'fas fa-exclamation-triangle',
                'title' => 'สินค้าใกล้หมดสต็อก',
                'description' => $product->name . ' เหลือในสต็อกเพียง ' . $product->stock . ' ชิ้น',
                'time' => $product->updated_at,
                'type' => 'stock'
            ]);
        }
        
        // Sort all activities by time and take the most recent 5
        return $activities->sortByDesc('time')->take(5)->values()->map(function($activity) {
            $activity['formatted_time'] = $this->formatRelativeTime($activity['time']);
            return $activity;
        });
    }
    
    /**
     * Format time as relative (e.g., "5 minutes ago")
     */
    private function formatRelativeTime($time)
    {
        $carbon = Carbon::parse($time);
        $diffInMinutes = $carbon->diffInMinutes(Carbon::now());
        
        if ($diffInMinutes < 1) {
            return 'เพิ่งเกิดขึ้น';
        } elseif ($diffInMinutes < 60) {
            return $diffInMinutes . ' นาทีที่แล้ว';
        } elseif ($diffInMinutes < 1440) { // Less than 24 hours
            $hours = floor($diffInMinutes / 60);
            return $hours . ' ชั่วโมงที่แล้ว';
        } else {
            $days = floor($diffInMinutes / 1440);
            return $days . ' วันที่แล้ว';
        }
    }
}
