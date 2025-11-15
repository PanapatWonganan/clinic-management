<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class TelegramService
{
    private $botToken;
    private $chatId;
    private $apiUrl;

    public function __construct()
    {
        $this->botToken = config('telegram.bot_token');
        $this->chatId = config('telegram.chat_id');
        $this->apiUrl = "https://api.telegram.org/bot{$this->botToken}";
    }

    /**
     * ส่งแจ้งเตือนคำสั่งซื้อใหม่
     */
    public function sendNewOrderNotification(Order $order)
    {
        if (!$this->isConfigured()) {
            Log::warning('Telegram not configured, skipping notification');
            return false;
        }

        $message = $this->formatNewOrderMessage($order);
        
        return $this->sendMessage($message);
    }

    /**
     * ส่งแจ้งเตือนการเปลี่ยนสถานะ
     */
    public function sendStatusUpdateNotification(Order $order, $oldStatus, $newStatus)
    {
        if (!$this->isConfigured()) {
            return false;
        }

        $message = $this->formatStatusUpdateMessage($order, $oldStatus, $newStatus);
        
        return $this->sendMessage($message);
    }

    /**
     * ส่งแจ้งเตือนการอัปโหลดสลิป
     */
    public function sendPaymentSlipNotification(Order $order)
    {
        if (!$this->isConfigured()) {
            return false;
        }

        $message = $this->formatPaymentSlipMessage($order);

        return $this->sendMessage($message);
    }

    /**
     * ส่งแจ้งเตือนการชำระเงินสำเร็จผ่าน Payment Gateway
     */
    public function sendPaymentSuccessNotification(Order $order)
    {
        if (!$this->isConfigured()) {
            return false;
        }

        $message = $this->formatPaymentSuccessMessage($order);

        return $this->sendMessage($message);
    }

    /**
     * ส่งข้อความไป Telegram
     */
    public function sendMessage($message, $chatId = null)
    {
        try {
            $targetChatId = $chatId ?: $this->chatId;
            
            if (!$targetChatId) {
                Log::error('No Telegram chat ID configured');
                return false;
            }

            $response = Http::timeout(config('telegram.timeout', 10))
                ->post("{$this->apiUrl}/sendMessage", [
                    'chat_id' => $targetChatId,
                    'text' => $message,
                    'parse_mode' => 'HTML',
                    'disable_web_page_preview' => true,
                ]);

            if ($response->successful()) {
                $data = $response->json();
                Log::info('Telegram message sent successfully', [
                    'message_id' => $data['result']['message_id'] ?? null,
                    'chat_id' => $targetChatId
                ]);
                return true;
            } else {
                Log::error('Telegram API error', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return false;
            }
        } catch (\Exception $e) {
            Log::error('Telegram service error: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * จัดรูปแบบข้อความคำสั่งซื้อใหม่
     */
    private function formatNewOrderMessage(Order $order)
    {
        $user = $order->user;
        $items = $order->orderItems;
        $itemCount = $items->count();
        
        // สร้างรายการสินค้า
        $itemsList = '';
        foreach ($items->take(3) as $item) {
            $itemName = $item->product->name;
            $quantity = $item->quantity;
            $unitPrice = number_format($item->unit_price, 0);
            $totalPrice = number_format($item->total_price, 0);
            
            $itemsList .= "• <b>{$itemName}</b>\n";
            $itemsList .= "  จำนวน {$quantity} x ฿{$unitPrice} = <b>฿{$totalPrice}</b>\n";
        }
        if ($itemCount > 3) {
            $remaining = $itemCount - 3;
            $itemsList .= "• ... และอีก <b>{$remaining}</b> รายการ\n";
        }

        $message = "🆕 <b>คำสั่งซื้อใหม่!</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📋 <b>#{$order->order_number}</b>\n";
        $message .= "👤 {$user->name}";
        if ($user->phone) {
            $message .= " ({$user->phone})";
        }
        $message .= "\n";
        $message .= "💰 <b>฿" . number_format($order->total_amount, 0) . "</b> ({$itemCount} รายการ)\n\n";
        
        $message .= "📦 <b>สินค้า:</b>\n{$itemsList}\n";
        
        // ที่อยู่จัดส่ง
        if ($order->shippingAddress) {
            $address = $order->shippingAddress;
            $message .= "📍 <b>ที่อยู่:</b> {$address->district}, {$address->province}\n";
        }
        
        $message .= "⏰ " . Carbon::parse($order->created_at)->locale('th')->isoFormat('DD MMM YYYY - HH:mm') . "\n";
        $message .= "🔗 <a href='" . config('app.url') . "/admin/orders/{$order->id}'>ดูรายละเอียด</a>";

        return $message;
    }

    /**
     * จัดรูปแบบข้อความเปลี่ยนสถานะ
     */
    private function formatStatusUpdateMessage(Order $order, $oldStatus, $newStatus)
    {
        $statusEmoji = [
            'pending_payment' => '⏳',
            'payment_uploaded' => '📄',
            'paid' => '💰',
            'confirmed' => '✅', 
            'processing' => '🔄',
            'shipped' => '🚚',
            'delivered' => '📦',
            'cancelled' => '❌'
        ];

        $statusText = [
            'pending_payment' => 'รอชำระเงิน',
            'payment_uploaded' => 'อัปโหลดสลิปแล้ว',
            'paid' => 'ชำระเงินแล้ว',
            'confirmed' => 'ยืนยันแล้ว',
            'processing' => 'กำลังเตรียม',
            'shipped' => 'จัดส่งแล้ว',
            'delivered' => 'ส่งถึงแล้ว',
            'cancelled' => 'ยกเลิก'
        ];

        $message = "🔄 <b>อัปเดตสถานะคำสั่งซื้อ</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📋 <b>#{$order->order_number}</b>\n";
        $oldStatusText = $statusText[$oldStatus] ?? $oldStatus;
        $newStatusEmoji = $statusEmoji[$newStatus] ?? '🔄';
        $newStatusText = $statusText[$newStatus] ?? $newStatus;
        $message .= "📈 {$oldStatusText} → <b>{$newStatusEmoji} {$newStatusText}</b>\n";
        $message .= "👤 {$order->user->name}\n";
        $message .= "💰 <b>฿" . number_format($order->total_amount, 0) . "</b>\n";
        
        // แสดงสินค้าแรก
        if ($order->orderItems->count() > 0) {
            $firstItem = $order->orderItems->first();
            $message .= "📦 {$firstItem->product->name}";
            if ($order->orderItems->count() > 1) {
                $remaining = $order->orderItems->count() - 1;
                $message .= " และอีก {$remaining} รายการ";
            }
            $message .= "\n";
        }
        
        $message .= "⏰ " . Carbon::now()->locale('th')->diffForHumans() . "\n";
        $message .= "🔗 <a href='" . config('app.url') . "/admin/orders/{$order->id}'>ดูรายละเอียด</a>";

        return $message;
    }

    /**
     * จัดรูปแบบข้อความสลิปชำระเงิน
     */
    private function formatPaymentSlipMessage(Order $order)
    {
        $message = "💳 <b>อัปโหลดสลิปชำระเงิน</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📋 <b>#{$order->order_number}</b>\n";
        $message .= "👤 {$order->user->name}\n";
        $message .= "💰 <b>฿" . number_format($order->total_amount, 0) . "</b>\n";

        // แสดงสินค้าแรก
        if ($order->orderItems->count() > 0) {
            $firstItem = $order->orderItems->first();
            $message .= "📦 {$firstItem->product->name}";
            if ($order->orderItems->count() > 1) {
                $remaining = $order->orderItems->count() - 1;
                $message .= " และอีก {$remaining} รายการ";
            }
            $message .= "\n";
        }

        $message .= "⏰ " . Carbon::now()->locale('th')->diffForHumans() . "\n";
        $message .= "🔗 <a href='" . config('app.url') . "/admin/orders/{$order->id}'>ตรวจสอบสลิป</a>";

        return $message;
    }

    /**
     * จัดรูปแบบข้อความชำระเงินสำเร็จผ่าน Payment Gateway
     */
    private function formatPaymentSuccessMessage(Order $order)
    {
        $payment = $order->getSuccessfulPayment();

        $message = "✅💳 <b>ชำระเงินสำเร็จผ่าน Credit Card!</b>\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "📋 <b>#{$order->order_number}</b>\n";
        $message .= "👤 {$order->user->name}\n";
        $message .= "💰 <b>฿" . number_format($order->total_amount, 0) . "</b>\n";
        $message .= "💳 <b>ชำระผ่าน:</b> Credit Card (Payment Gateway)\n";

        // แสดง Transaction ID ถ้ามี
        if ($payment && $payment->transaction_id) {
            $message .= "🔖 <b>Transaction ID:</b> {$payment->transaction_id}\n";
        }

        // แสดงสินค้าแรก
        if ($order->orderItems->count() > 0) {
            $firstItem = $order->orderItems->first();
            $message .= "📦 {$firstItem->product->name}";
            if ($order->orderItems->count() > 1) {
                $remaining = $order->orderItems->count() - 1;
                $message .= " และอีก {$remaining} รายการ";
            }
            $message .= "\n";
        }

        $message .= "⏰ " . Carbon::now()->locale('th')->diffForHumans() . "\n";
        $message .= "🔗 <a href='" . config('app.url') . "/admin/orders/{$order->id}'>ดูรายละเอียด</a>";

        return $message;
    }

    /**
     * ตรวจสอบว่า Telegram ได้รับการ config หรือไม่
     */
    private function isConfigured()
    {
        return !empty($this->botToken) && !empty($this->chatId);
    }

    /**
     * ทดสอบการส่งข้อความ
     */
    public function testConnection()
    {
        if (!$this->isConfigured()) {
            return [
                'success' => false,
                'message' => 'Telegram bot not configured'
            ];
        }

        try {
            $testMessage = "🧪 <b>ทดสอบระบบแจ้งเตือน</b>\n";
            $testMessage .= "━━━━━━━━━━━━━━━━━━━━\n";
            $testMessage .= "✅ การเชื่อมต่อ Telegram Bot ทำงานปกติ\n";
            $testMessage .= "🕐 " . Carbon::now()->locale('th')->isoFormat('DD MMM YYYY - HH:mm:ss');

            $success = $this->sendMessage($testMessage);

            return [
                'success' => $success,
                'message' => $success ? 'Test message sent successfully' : 'Failed to send test message'
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'Test failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get Bot information
     */
    public function getBotInfo()
    {
        try {
            $response = Http::timeout(config('telegram.timeout', 10))
                ->get("{$this->apiUrl}/getMe");

            if ($response->successful()) {
                return $response->json()['result'] ?? null;
            }
            
            return null;
        } catch (\Exception $e) {
            Log::error('Failed to get bot info: ' . $e->getMessage());
            return null;
        }
    }
}