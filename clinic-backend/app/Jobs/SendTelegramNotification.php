<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Services\TelegramService;
use App\Models\Order;
use Illuminate\Support\Facades\Log;

class SendTelegramNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $timeout = 30;
    public $tries = 3;
    public $backoff = [5, 15, 30]; // Retry delays in seconds

    protected $order;
    protected $type;
    protected $oldStatus;
    protected $newStatus;

    /**
     * Create a new job instance.
     */
    public function __construct(Order $order, string $type, $oldStatus = null, $newStatus = null)
    {
        $this->order = $order;
        $this->type = $type;
        $this->oldStatus = $oldStatus;
        $this->newStatus = $newStatus;
        
        // Set queue priority based on notification type
        $this->onQueue($type === 'new_order' ? 'high' : 'default');
    }

    /**
     * Execute the job.
     */
    public function handle(TelegramService $telegramService): void
    {
        try {
            $success = false;
            
            switch ($this->type) {
                case 'new_order':
                    if (config('telegram.notifications.new_order', true)) {
                        $success = $telegramService->sendNewOrderNotification($this->order);
                    }
                    break;
                    
                case 'status_update':
                    if (config('telegram.notifications.status_update', true)) {
                        $success = $telegramService->sendStatusUpdateNotification(
                            $this->order, 
                            $this->oldStatus, 
                            $this->newStatus
                        );
                    }
                    break;
                    
                case 'payment_slip':
                    if (config('telegram.notifications.payment_slip', true)) {
                        $success = $telegramService->sendPaymentSlipNotification($this->order);
                    }
                    break;

                case 'payment_success':
                    if (config('telegram.notifications.payment_success', true)) {
                        $success = $telegramService->sendPaymentSuccessNotification($this->order);
                    }
                    break;

                default:
                    Log::warning("Unknown Telegram notification type: {$this->type}");
                    return;
            }

            if ($success) {
                Log::info("Telegram notification sent successfully", [
                    'type' => $this->type,
                    'order_id' => $this->order->id,
                    'order_number' => $this->order->order_number
                ]);
            } else {
                Log::warning("Failed to send Telegram notification", [
                    'type' => $this->type,
                    'order_id' => $this->order->id,
                    'attempt' => $this->attempts()
                ]);
                
                // If not the last attempt, throw exception to trigger retry
                if ($this->attempts() < $this->tries) {
                    throw new \Exception("Failed to send Telegram notification, retrying...");
                }
            }
            
        } catch (\Exception $e) {
            Log::error("Telegram notification job failed", [
                'type' => $this->type,
                'order_id' => $this->order->id,
                'error' => $e->getMessage(),
                'attempt' => $this->attempts()
            ]);
            
            // Re-throw to trigger retry mechanism
            throw $e;
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(\Throwable $exception): void
    {
        Log::error("Telegram notification job failed permanently", [
            'type' => $this->type,
            'order_id' => $this->order->id,
            'order_number' => $this->order->order_number,
            'error' => $exception->getMessage(),
            'attempts' => $this->attempts()
        ]);
    }
}