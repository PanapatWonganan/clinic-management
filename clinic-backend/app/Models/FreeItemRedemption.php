<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FreeItemRedemption extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'claimed_reward_id',
        'product_id',
        'quantity',
        'status',
        'shipping_address_id',
        'order_id', // เชื่อมกับ order (กรณีส่งพร้อม order)
        'tracking_number',
        'notes',
        'admin_notes',
        'approved_at',
        'shipped_at',
        'delivered_at',
    ];

    protected $casts = [
        'approved_at' => 'datetime',
        'shipped_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_APPROVED = 'approved';
    const STATUS_PREPARING = 'preparing';
    const STATUS_SHIPPED = 'shipped';
    const STATUS_DELIVERED = 'delivered';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Get the user that owns this redemption
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the claimed reward this redemption is from
     */
    public function claimedReward()
    {
        return $this->belongsTo(UserClaimedReward::class, 'claimed_reward_id');
    }

    /**
     * Get the product being redeemed
     */
    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Get the shipping address
     */
    public function shippingAddress()
    {
        return $this->belongsTo(CustomerAddress::class, 'shipping_address_id');
    }

    /**
     * Scope for pending redemptions
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope for active redemptions (not cancelled/delivered)
     */
    public function scopeActive($query)
    {
        return $query->whereNotIn('status', [self::STATUS_CANCELLED, self::STATUS_DELIVERED]);
    }

    /**
     * Get status label in Thai
     */
    public function getStatusLabelAttribute()
    {
        return match($this->status) {
            self::STATUS_PENDING => 'รอดำเนินการ',
            self::STATUS_APPROVED => 'อนุมัติแล้ว',
            self::STATUS_PREPARING => 'กำลังจัดเตรียม',
            self::STATUS_SHIPPED => 'จัดส่งแล้ว',
            self::STATUS_DELIVERED => 'ส่งถึงแล้ว',
            self::STATUS_CANCELLED => 'ยกเลิก',
            default => $this->status,
        };
    }
}
