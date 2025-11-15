<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\Product;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function index()
    {
        return view('admin.reports.index');
    }

    public function revenue(Request $request)
    {
        $period = $request->get('period', 'monthly'); // daily, weekly, monthly, yearly
        
        // Only count revenue from approved/paid orders
        $query = Order::whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered']);
        
        switch ($period) {
            case 'daily':
                $data = $query->whereDate('created_at', today())
                    ->selectRaw('DATE(created_at) as date, SUM(total_amount) as total')
                    ->groupBy('date')
                    ->get();
                break;
                
            case 'weekly':
                $data = $query->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])
                    ->selectRaw('YEARWEEK(created_at) as week, SUM(total_amount) as total')
                    ->groupBy('week')
                    ->get();
                break;
                
            case 'yearly':
                $data = $query->whereYear('created_at', now()->year)
                    ->selectRaw('YEAR(created_at) as year, SUM(total_amount) as total')
                    ->groupBy('year')
                    ->get();
                break;
                
            default: // monthly
                $data = $query->whereYear('created_at', now()->year)
                    ->selectRaw('MONTH(created_at) as month, SUM(total_amount) as total')
                    ->groupBy('month')
                    ->get();
                break;
        }

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    public function customers()
    {
        $stats = [
            'total_customers' => User::count(),
            'new_customers_this_month' => User::whereMonth('created_at', now()->month)->count(),
            'active_customers' => User::whereHas('orders')->count(),
            'membership_breakdown' => User::selectRaw('membership_type, COUNT(*) as count')
                ->groupBy('membership_type')
                ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    public function products()
    {
        $stats = [
            'total_products' => Product::count(),
            'active_products' => Product::where('is_active', true)->count(),
            'low_stock_products' => Product::where('stock', '<=', 5)->count(),
            'out_of_stock_products' => Product::where('stock', 0)->count(),
            'best_selling_products' => Product::withCount('orderItems')
                ->orderBy('order_items_count', 'desc')
                ->take(5)
                ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }
}