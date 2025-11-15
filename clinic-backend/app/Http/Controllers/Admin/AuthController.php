<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $credentials = $request->only('email', 'password');

        // ถ้าไม่มี admin user ในระบบ ให้สร้าง default admin
        if (User::where('is_admin', true)->count() == 0) {
            User::create([
                'name' => 'Admin',
                'email' => 'admin@exquiller.com',
                'password' => Hash::make('Admin@123'),
                'email_verified_at' => now(),
                'is_admin' => true,
            ]);
        }

        if (Auth::attempt($credentials)) {
            $user = Auth::user();

            // ตรวจสอบว่าเป็น admin หรือไม่
            if (!$user->is_admin) {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'คุณไม่มีสิทธิ์เข้าถึงระบบหลังบ้าน',
                ])->onlyInput('email');
            }

            $request->session()->regenerate();
            return redirect()->intended(route('admin.dashboard'));
        }

        return back()->withErrors([
            'email' => 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง',
        ])->onlyInput('email');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('admin.login');
    }
    
    public function export(Request $request)
    {
        $type = $request->get('type', 'orders');
        $format = $request->get('format', 'csv');
        
        try {
            $data = $this->getExportData($type);
            $filename = $type . '_report_' . date('Y-m-d') . '.' . $format;
            
            if ($format === 'csv') {
                return $this->exportAsCsv($data, $filename, $type);
            } else {
                return $this->exportAsJson($data, $filename);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => 'ไม่สามารถส่งออกข้อมูลได้: ' . $e->getMessage()], 500);
        }
    }
    
    private function getExportData($type)
    {
        switch ($type) {
            case 'orders':
                return \App\Models\Order::with(['user', 'orderItems.product'])
                    ->orderBy('created_at', 'desc')
                    ->get()
                    ->map(function ($order) {
                        return [
                            'order_number' => $order->order_number,
                            'customer_name' => $order->user->name ?? 'N/A',
                            'customer_email' => $order->user->email ?? 'N/A',
                            'total_amount' => $order->total_amount,
                            'status' => $order->status,
                            'payment_method' => $order->payment_method,
                            'created_at' => $order->created_at->format('Y-m-d H:i:s'),
                            'items_count' => $order->orderItems->count(),
                        ];
                    });
                    
            case 'customers':
                return \App\Models\User::orderBy('created_at', 'desc')
                    ->get()
                    ->map(function ($user) {
                        $ordersCount = \App\Models\Order::where('user_id', $user->id)->count();
                        $totalSpent = \App\Models\Order::where('user_id', $user->id)
                            ->where('status', '!=', 'cancelled')
                            ->sum('total_amount');
                            
                        return [
                            'name' => $user->name,
                            'email' => $user->email,
                            'phone' => $user->phone ?? 'N/A',
                            'address' => $user->address ?? 'N/A',
                            'district' => $user->district ?? 'N/A',
                            'province' => $user->province ?? 'N/A',
                            'postal_code' => $user->postal_code ?? 'N/A',
                            'total_orders' => $ordersCount,
                            'total_spent' => $totalSpent,
                            'registered_at' => $user->created_at->format('Y-m-d H:i:s'),
                        ];
                    });
                    
            case 'products':
                return \App\Models\Product::orderBy('name')
                    ->get()
                    ->map(function ($product) {
                        $totalSold = \App\Models\OrderItem::where('product_id', $product->id)
                            ->sum('quantity');
                        $totalRevenue = \App\Models\OrderItem::where('product_id', $product->id)
                            ->sum('total_price');
                            
                        return [
                            'name' => $product->name,
                            'description' => $product->description ?? 'N/A',
                            'price' => $product->price,
                            'points' => $product->points,
                            'category' => $product->category,
                            'stock' => $product->stock,
                            'is_active' => $product->is_active ? 'Yes' : 'No',
                            'total_sold' => $totalSold,
                            'total_revenue' => $totalRevenue,
                            'created_at' => $product->created_at->format('Y-m-d H:i:s'),
                        ];
                    });
                    
            case 'revenue':
                // รายงานรายได้รายวัน 30 วันล่าสุด
                $revenueData = [];
                for ($i = 29; $i >= 0; $i--) {
                    $date = now()->subDays($i);
                    $dailyRevenue = \App\Models\Order::whereDate('created_at', $date)
                        ->where('status', '!=', 'cancelled')
                        ->sum('total_amount');
                    $dailyOrders = \App\Models\Order::whereDate('created_at', $date)
                        ->where('status', '!=', 'cancelled')
                        ->count();
                        
                    $revenueData[] = [
                        'date' => $date->format('Y-m-d'),
                        'day_name' => $date->format('l'),
                        'daily_revenue' => $dailyRevenue,
                        'daily_orders' => $dailyOrders,
                        'average_order_value' => $dailyOrders > 0 ? round($dailyRevenue / $dailyOrders, 2) : 0,
                    ];
                }
                return collect($revenueData);
                
            default:
                throw new \Exception('ประเภทข้อมูลไม่ถูกต้อง');
        }
    }
    
    private function exportAsCsv($data, $filename, $type)
    {
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
            'Pragma' => 'no-cache',
            'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
            'Expires' => '0',
        ];
        
        $callback = function() use ($data, $type) {
            $file = fopen('php://output', 'w');
            
            // Add BOM for UTF-8
            fprintf($file, chr(0xEF).chr(0xBB).chr(0xBF));
            
            // Add headers based on type
            if ($data->isNotEmpty()) {
                fputcsv($file, array_keys($data->first()));
            }
            
            // Add data rows
            foreach ($data as $row) {
                fputcsv($file, array_values($row));
            }
            
            fclose($file);
        };
        
        return response()->stream($callback, 200, $headers);
    }
    
    private function exportAsJson($data, $filename)
    {
        $headers = [
            'Content-Type' => 'application/json; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ];
        
        return response()->json([
            'data' => $data,
            'exported_at' => now()->format('Y-m-d H:i:s'),
            'total_records' => $data->count(),
        ], 200, $headers);
    }
}
