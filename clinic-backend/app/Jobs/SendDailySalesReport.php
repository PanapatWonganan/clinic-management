<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\TelegramService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SendDailySalesReport implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $timeout = 60;

    public $tries = 2;

    protected $date;

    public function __construct($date = null)
    {
        if ($date instanceof \Carbon\Carbon) {
            $this->date = $date;
        } else {
            $this->date = $date ? Carbon::parse($date) : Carbon::yesterday();
        }
        $this->onQueue('reports');
    }

    public function handle(TelegramService $telegramService): void
    {
        try {
            if (! config('telegram.notifications.daily_sales_report', true)) {
                Log::info('Daily sales report disabled, skipping');

                return;
            }

            $reportDate = $this->date->format('Y-m-d');
            $dateRange = [
                $this->date->copy()->startOfDay(),
                $this->date->copy()->endOfDay(),
            ];

            // ดึงข้อมูลยอดขายรายวัน
            $dailySales = $this->getDailySalesData($dateRange);

            // ดึงข้อมูลสินค้าขายดี
            $topProducts = $this->getTopProductsData($dateRange);

            // ดึงข้อมูลสถิติเพิ่มเติม
            $statistics = $this->getStatistics($dateRange);

            $message = $this->formatDailySalesMessage($dailySales, $topProducts, $statistics);

            $success = $telegramService->sendMessage($message);

            if ($success) {
                Log::info('Daily sales report sent successfully', [
                    'date' => $reportDate,
                    'total_sales' => $dailySales['total_amount'],
                    'total_orders' => $dailySales['total_orders'],
                ]);
            } else {
                throw new \Exception('Failed to send daily sales report');
            }

        } catch (\Exception $e) {
            Log::error('Daily sales report job failed', [
                'date' => $this->date->format('Y-m-d'),
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    private function getDailySalesData($dateRange)
    {
        $orders = Order::whereBetween('created_at', $dateRange)
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->get();

        return [
            'total_orders' => $orders->count(),
            'total_amount' => $orders->sum('total_amount'),
            'pending_payment' => Order::whereBetween('created_at', $dateRange)
                ->where('status', 'pending_payment')->count(),
            'payment_uploaded' => Order::whereBetween('created_at', $dateRange)
                ->where('status', 'payment_uploaded')->count(),
        ];
    }

    private function getTopProductsData($dateRange)
    {
        return DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->whereBetween('orders.created_at', $dateRange)
            ->whereIn('orders.status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->select(
                'products.name',
                DB::raw('SUM(order_items.quantity) as total_quantity'),
                DB::raw('SUM(order_items.total_price) as total_revenue')
            )
            ->groupBy('products.id', 'products.name')
            ->orderBy('total_quantity', 'desc')
            ->limit(5)
            ->get();
    }

    private function getStatistics($dateRange)
    {
        // เปรียบเทียบกับวันก่อนหน้า
        $previousDate = [
            $this->date->copy()->subDay()->startOfDay(),
            $this->date->copy()->subDay()->endOfDay(),
        ];

        $todayRevenue = Order::whereBetween('created_at', $dateRange)
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->sum('total_amount');

        $yesterdayRevenue = Order::whereBetween('created_at', $previousDate)
            ->whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->sum('total_amount');

        $growthPercent = 0;
        if ($yesterdayRevenue > 0) {
            $growthPercent = (($todayRevenue - $yesterdayRevenue) / $yesterdayRevenue) * 100;
        }

        return [
            'growth_percent' => $growthPercent,
            'yesterday_revenue' => $yesterdayRevenue,
            'new_customers' => Order::whereBetween('created_at', $dateRange)
                ->distinct('user_id')->count('user_id'),
        ];
    }

    private function formatDailySalesMessage($sales, $topProducts, $stats)
    {
        $date = $this->date->locale('th')->isoFormat('DD MMMM YYYY');

        $message = "📊 <b>รายงานยอดขายรายวัน</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📅 <b>{$date}</b>\n\n";

        // ยอดขายรวม
        $message .= '💰 <b>ยอดขายรวม: ฿'.number_format($sales['total_amount'], 0)."</b>\n";
        $message .= "📦 คำสั่งซื้อทั้งหมด: {$sales['total_orders']} รายการ\n";

        // การเปรียบเทียบ
        if ($stats['growth_percent'] != 0) {
            $growthEmoji = $stats['growth_percent'] > 0 ? '📈' : '📉';
            $growthText = $stats['growth_percent'] > 0 ? '+' : '';
            $message .= "{$growthEmoji} เปรียบเทียบเมื่อวาน: {$growthText}".number_format($stats['growth_percent'], 1)."%\n";
        }

        $message .= "\n";

        // สถานะคำสั่งซื้อ
        $message .= "📋 <b>สถานะคำสั่งซื้อ:</b>\n";
        $message .= "• ⏳ รอชำระเงิน: {$sales['pending_payment']} รายการ\n";
        $message .= "• 📄 อัปโหลดสลิปแล้ว: {$sales['payment_uploaded']} รายการ\n\n";

        // สินค้าขายดี
        if ($topProducts->count() > 0) {
            $message .= "🏆 <b>สินค้าขายดี TOP 5:</b>\n";
            foreach ($topProducts as $index => $product) {
                $rank = $index + 1;
                $emoji = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][$index] ?? ($rank.'.');
                $message .= "{$emoji} {$product->name}\n";
                $message .= "   จำนวน {$product->total_quantity} ชิ้น (฿".number_format($product->total_revenue, 0).")\n";
            }
            $message .= "\n";
        }

        // สถิติเพิ่มเติม
        $message .= "👥 ลูกค้าที่สั่งซื้อ: {$stats['new_customers']} คน\n";
        $message .= '⏰ รายงาน ณ วันที่ '.Carbon::now()->locale('th')->isoFormat('DD MMM HH:mm')."\n\n";
        $message .= "🔗 <a href='".config('app.url')."/admin/dashboard'>ดูแดชบอร์ด</a>";

        return $message;
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('Daily sales report job failed permanently', [
            'date' => $this->date->format('Y-m-d'),
            'error' => $exception->getMessage(),
        ]);
    }
}
