<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Services\TelegramService;
use App\Models\Product;
use Illuminate\Support\Facades\Log;

class SendLowStockNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $timeout = 60;
    public $tries = 2;

    protected $lowStockProducts;
    protected $threshold;

    public function __construct($lowStockProducts, $threshold = 5)
    {
        $this->lowStockProducts = $lowStockProducts;
        $this->threshold = $threshold;
        $this->onQueue('notifications');
    }

    public function handle(TelegramService $telegramService): void
    {
        try {
            if (!config('telegram.notifications.low_stock', true)) {
                Log::info('Low stock notifications disabled, skipping');
                return;
            }

            if (empty($this->lowStockProducts)) {
                Log::info('No low stock products found');
                return;
            }

            $message = $this->formatLowStockMessage();
            
            $success = $telegramService->sendMessage($message);

            if ($success) {
                Log::info("Low stock notification sent successfully", [
                    'products_count' => count($this->lowStockProducts),
                    'threshold' => $this->threshold
                ]);
            } else {
                throw new \Exception("Failed to send low stock notification");
            }

        } catch (\Exception $e) {
            Log::error("Low stock notification job failed", [
                'error' => $e->getMessage(),
                'products_count' => count($this->lowStockProducts ?? [])
            ]);
            
            throw $e;
        }
    }

    private function formatLowStockMessage()
    {
        $message = "⚠️ <b>แจ้งเตือนสินค้าใกล้หมด</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📦 <b>สินค้าที่เหลือน้อยกว่า {$this->threshold} ชิ้น:</b>\n\n";

        foreach ($this->lowStockProducts as $product) {
            $stockEmoji = $this->getStockEmoji($product->stock);
            $message .= "{$stockEmoji} <b>{$product->name}</b>\n";
            $message .= "   เหลือ: <b>{$product->stock} ชิ้น</b>\n";
            $message .= "   ราคา: ฿" . number_format($product->price, 0) . "\n";
            
            if ($product->category) {
                $message .= "   หมวด: {$product->category}\n";
            }
            $message .= "\n";
        }

        $message .= "🔔 <i>แจ้งเตือนเมื่อสินค้าเหลือน้อยกว่า {$this->threshold} ชิ้น</i>\n";
        $message .= "⏰ " . now()->locale('th')->isoFormat('DD MMM YYYY HH:mm') . "\n\n";
        $message .= "🔗 <a href='" . config('app.url') . "/admin/products'>จัดการสินค้า</a>";

        return $message;
    }

    private function getStockEmoji($stock)
    {
        if ($stock <= 0) return '🔴'; // หมด
        if ($stock <= 2) return '🟡'; // เหลือน้อยมาก  
        if ($stock <= 5) return '🟠'; // เหลือน้อย
        return '🟢'; // ปกติ
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("Low stock notification job failed permanently", [
            'error' => $exception->getMessage(),
            'products_count' => count($this->lowStockProducts ?? [])
        ]);
    }
}