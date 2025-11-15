<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Role extends Model
{
    protected $fillable = [
        'name',
        'display_name',
        'description',
        'level',
        'discount_percentage',
        'upgrade_required_amount',
        'upgrade_required_quantity',
        'upgrades_to_role_id',
        'upgrade_conditions',
        'auto_upgrade',
        'is_active',
    ];

    protected $casts = [
        'discount_percentage' => 'decimal:2',
        'upgrade_required_amount' => 'decimal:2',
        'auto_upgrade' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Get the users for the role.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get the bundle deals for the role.
     */
    public function bundleDeals(): HasMany
    {
        return $this->hasMany(MembershipBundleDeal::class);
    }

    /**
     * Get active bundle deals for the role.
     */
    public function activeBundleDeals(): HasMany
    {
        return $this->hasMany(MembershipBundleDeal::class)->where('is_active', true)->orderBy('level');
    }

    /**
     * Scope a query to only include active roles.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get role by name
     */
    public static function findByName(string $name): ?Role
    {
        return static::where('name', $name)->first();
    }

    /**
     * Get the role this role upgrades to
     */
    public function upgradesToRole()
    {
        return $this->belongsTo(Role::class, 'upgrades_to_role_id');
    }

    /**
     * Get roles that upgrade to this role
     */
    public function upgradesFromRoles()
    {
        return $this->hasMany(Role::class, 'upgrades_to_role_id');
    }

    /**
     * Check if user qualifies for upgrade based on total purchases
     */
    public function checkUpgradeEligibility(float $totalPurchaseAmount, int $totalPurchaseQuantity = 0): bool
    {
        if (!$this->upgrades_to_role_id || !$this->auto_upgrade) {
            return false;
        }

        // Check amount requirement
        if ($this->upgrade_required_amount && $totalPurchaseAmount < $this->upgrade_required_amount) {
            return false;
        }

        // Check quantity requirement
        if ($this->upgrade_required_quantity && $totalPurchaseQuantity < $this->upgrade_required_quantity) {
            return false;
        }

        return true;
    }

    /**
     * Get upgrade progress for user
     */
    public function getUpgradeProgress(float $totalPurchaseAmount, int $totalPurchaseQuantity = 0): array
    {
        if (!$this->upgrades_to_role_id) {
            return [
                'can_upgrade' => false,
                'message' => 'ไม่มีการอัพเกรดสำหรับระดับนี้'
            ];
        }

        $amountProgress = $this->upgrade_required_amount ?
            min(100, ($totalPurchaseAmount / $this->upgrade_required_amount) * 100) : 100;

        $quantityProgress = $this->upgrade_required_quantity ?
            min(100, ($totalPurchaseQuantity / $this->upgrade_required_quantity) * 100) : 100;

        $canUpgrade = $this->checkUpgradeEligibility($totalPurchaseAmount, $totalPurchaseQuantity);

        return [
            'can_upgrade' => $canUpgrade,
            'upgrades_to' => $this->upgradesToRole,
            'amount_progress' => $amountProgress,
            'quantity_progress' => $quantityProgress,
            'amount_required' => $this->upgrade_required_amount,
            'amount_current' => $totalPurchaseAmount,
            'amount_remaining' => max(0, $this->upgrade_required_amount - $totalPurchaseAmount),
            'quantity_required' => $this->upgrade_required_quantity,
            'quantity_current' => $totalPurchaseQuantity,
            'quantity_remaining' => max(0, $this->upgrade_required_quantity - $totalPurchaseQuantity),
        ];
    }
}
