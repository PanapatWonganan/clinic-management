<?php

namespace App\Models;

use App\Jobs\SendTelegramNotification;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'user_id',
        'shipping_address_id',
        'total_amount',
        'subtotal',
        'delivery_fee',
        'discount',
        'status',
        'delivery_method',
        'payment_method',
        'payment_status',
        'payment_slip_status',
        'tracking_number',
        'notes',
        'is_free_item_order',
        'stock_reduced_at',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'subtotal' => 'decimal:2',
        'delivery_fee' => 'decimal:2',
        'discount' => 'decimal:2',
        'stock_reduced_at' => 'datetime',
    ];

    // Relationship with User
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Relationship with OrderItems
    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    // Relationship with PaymentSlips
    public function paymentSlips()
    {
        return $this->hasMany(PaymentSlip::class);
    }

    // Relationship with DeliveryProof
    public function deliveryProof()
    {
        return $this->hasOne(DeliveryProof::class);
    }

    // Relationship with CustomerAddress (shipping address)
    public function shippingAddress()
    {
        return $this->belongsTo(CustomerAddress::class, 'shipping_address_id');
    }

    // Relationship with PaymentTransactions (for credit card gateway)
    public function paymentTransactions()
    {
        return $this->hasMany(PaymentTransaction::class);
    }

    // Get successful payment transaction
    public function getSuccessfulPayment()
    {
        return $this->paymentTransactions()->where('status', 'success')->first();
    }

    // Status constants for better code readability
    const STATUS_PENDING_PAYMENT = 'pending_payment';

    const STATUS_PAYMENT_UPLOADED = 'payment_uploaded';

    const STATUS_PAID = 'paid';

    const STATUS_CONFIRMED = 'confirmed';

    const STATUS_PROCESSING = 'processing';

    const STATUS_SHIPPED = 'shipped';

    const STATUS_DELIVERED = 'delivered';

    const STATUS_CANCELLED = 'cancelled';

    // Get status display name in Thai
    public function getStatusDisplayAttribute()
    {
        $statuses = [
            self::STATUS_PENDING_PAYMENT => 'รอการชำระเงิน',
            self::STATUS_PAYMENT_UPLOADED => 'อัปโหลดสลิปแล้ว',
            self::STATUS_PAID => 'ชำระเงินแล้ว',
            self::STATUS_CONFIRMED => 'ยืนยันคำสั่งซื้อแล้ว',
            self::STATUS_PROCESSING => 'กำลังเตรียมสินค้า',
            self::STATUS_SHIPPED => 'จัดส่งแล้ว',
            self::STATUS_DELIVERED => 'ส่งถึงแล้ว',
            self::STATUS_CANCELLED => 'ยกเลิกแล้ว',
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    // Check if order needs payment
    public function needsPayment()
    {
        return in_array($this->status, [
            self::STATUS_PENDING_PAYMENT,
            self::STATUS_PAYMENT_UPLOADED,
        ]);
    }

    // Check if payment is completed
    public function isPaid()
    {
        return in_array($this->status, [
            self::STATUS_PAID,
            self::STATUS_CONFIRMED,
            self::STATUS_PROCESSING,
            self::STATUS_SHIPPED,
            self::STATUS_DELIVERED,
        ]);
    }

    // Stock reduction should happen when status changes to 'paid'.
    // Side effects (telegram dispatch, low-stock notification) are deferred to
    // afterCommit so they don't fire from inside an outer transaction that
    // might still roll back. Stock reduction itself is guarded by
    // stock_reduced_at so a status that flips paid→other→paid can only
    // decrement once.
    protected static function booted()
    {
        static::updated(function ($order) {
            if (! $order->isDirty('status')) {
                return;
            }
            $oldStatus = $order->getOriginal('status');
            $newStatus = $order->status;

            \DB::afterCommit(function () use ($order, $oldStatus, $newStatus) {
                SendTelegramNotification::dispatch($order, 'status_update', $oldStatus, $newStatus);
            });

            if ($newStatus === self::STATUS_PAID) {
                $order->reduceProductStock();
            }
        });
    }

    // Reduce product stock for all order items. Idempotent — sets
    // stock_reduced_at on first successful run and short-circuits later calls.
    public function reduceProductStock()
    {
        if ($this->stock_reduced_at !== null) {
            \Log::info("Stock reduction skipped — already applied at {$this->stock_reduced_at}", [
                'order_id' => $this->id,
            ]);

            return;
        }

        $reducedProducts = [];

        foreach ($this->orderItems as $item) {
            $product = $item->product;
            if (! $product) {
                continue;
            }

            // Atomic conditional decrement — prevents two concurrent paid orders
            // from both reading "stock >= qty" and then double-spending the row.
            $ok = \App\Services\StockService::tryDecrement($product->id, (int) $item->quantity);
            if (! $ok) {
                \Log::warning("Insufficient stock for product {$product->id}. Required: {$item->quantity}, Available: {$product->fresh()->stock}");

                continue;
            }

            $updatedProduct = $product->fresh();
            \Log::info("Stock reduced for product {$product->id}: -{$item->quantity}, remaining: {$updatedProduct->stock}");
            $reducedProducts[] = $updatedProduct;
        }

        // Mark as reduced atomically; using updateQuietly avoids re-entering
        // the updated() observer above and re-triggering the same logic.
        $this->forceFill(['stock_reduced_at' => now()])->saveQuietly();

        $threshold = config('telegram.low_stock_threshold', 5);
        $lowStockProducts = collect($reducedProducts)->filter(function ($p) use ($threshold) {
            return $p->stock <= $threshold && $p->is_active;
        })->values();

        if ($lowStockProducts->isNotEmpty()) {
            \DB::afterCommit(function () use ($lowStockProducts, $threshold) {
                \App\Jobs\SendLowStockNotification::dispatch($lowStockProducts, $threshold);
            });
        }
    }
}
