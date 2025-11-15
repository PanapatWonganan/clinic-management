<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MembershipBundleDeal extends Model
{
    protected $fillable = [
        'role_id',
        'name',
        'display_name',
        'description',
        'required_quantity',
        'free_quantity',
        'unit_price',
        'total_price',
        'total_value',
        'savings_amount',
        'savings_percentage',
        'level',
        'is_active',
    ];

    protected $casts = [
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'total_value' => 'decimal:2',
        'savings_amount' => 'decimal:2',
        'savings_percentage' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Get the role that owns the bundle deal.
     */
    public function role(): BelongsTo
    {
        return $this->belongsTo(Role::class);
    }

    /**
     * Scope a query to only include active bundle deals.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get total quantity (required + free)
     */
    public function getTotalQuantityAttribute(): int
    {
        return $this->required_quantity + $this->free_quantity;
    }

    /**
     * Get effective price per unit (including free items)
     */
    public function getEffectivePricePerUnitAttribute(): float
    {
        return $this->total_price / $this->total_quantity;
    }

    /**
     * Calculate bundle deal for given quantity
     */
    public static function calculateBestDeal(int $roleId, int $quantity): ?array
    {
        $deals = static::where('role_id', $roleId)
            ->where('is_active', true)
            ->where('required_quantity', '<=', $quantity)
            ->orderBy('level', 'desc')
            ->get();

        if ($deals->isEmpty()) {
            return null;
        }

        $bestDeal = $deals->first();
        $bundles = intval($quantity / $bestDeal->required_quantity);
        $remainingItems = $quantity % $bestDeal->required_quantity;

        return [
            'bundle_deal' => $bestDeal,
            'bundles_count' => $bundles,
            'total_paid_items' => $bundles * $bestDeal->required_quantity,
            'total_free_items' => $bundles * $bestDeal->free_quantity,
            'remaining_items' => $remainingItems,
            'total_price' => ($bundles * $bestDeal->total_price) + ($remainingItems * $bestDeal->unit_price),
            'total_savings' => $bundles * $bestDeal->savings_amount,
        ];
    }
}
