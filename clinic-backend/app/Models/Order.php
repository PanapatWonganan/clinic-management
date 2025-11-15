<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Jobs\SendTelegramNotification;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'user_id',
        'shipping_address_id',
        'total_amount',
        'status',
        'delivery_method',
        'payment_method',
        'payment_status',
        'payment_slip_status',
        'tracking_number',
        'notes',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
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
            self::STATUS_PAYMENT_UPLOADED
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
            self::STATUS_DELIVERED
        ]);
    }

    // Stock reduction should happen when status changes to 'paid'
    protected static function booted()
    {
        static::updated(function ($order) {
            // If status changed, send notification
            if ($order->isDirty('status')) {
                $oldStatus = $order->getOriginal('status');
                $newStatus = $order->status;
                
                // Send Telegram notification for status change
                SendTelegramNotification::dispatch($order, 'status_update', $oldStatus, $newStatus);
                
                // If status changed to 'paid', reduce stock
                if ($newStatus === self::STATUS_PAID) {
                    $order->reduceProductStock();
                }
            }
        });
    }

    // Reduce product stock for all order items
    public function reduceProductStock()
    {
        foreach ($this->orderItems as $item) {
            $product = $item->product;
            if ($product && $product->stock >= $item->quantity) {
                $product->decrement('stock', $item->quantity);
                
                // Log stock reduction
                \Log::info("Stock reduced for product {$product->id}: -{$item->quantity}, remaining: {$product->fresh()->stock}");
                
                // Check for low stock after reduction
                $updatedProduct = $product->fresh();
                $threshold = config('telegram.low_stock_threshold', 5);
                
                if ($updatedProduct->stock <= $threshold && $updatedProduct->is_active) {
                    // Send immediate low stock notification for this specific product
                    \App\Jobs\SendLowStockNotification::dispatch(collect([$updatedProduct]), $threshold);
                }
            } else {
                // Log if insufficient stock
                \Log::warning("Insufficient stock for product {$product->id}. Required: {$item->quantity}, Available: {$product->stock}");
            }
        }
    }
}
