<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends \Illuminate\Foundation\Auth\User
{
    use HasFactory, Notifiable, HasApiTokens;

    // Membership type constants
    const MEMBERSHIP_EXMEMBER = 'exMember';
    const MEMBERSHIP_EXDOCTOR = 'exDoctor';
    const MEMBERSHIP_EXVIP = 'exVip';
    const MEMBERSHIP_EXSUPERVIP = 'exSupervip';

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'address',
        'district',
        'province',
        'postal_code',
        'province_id',
        'district_id',
        'sub_district_id',
        'email_verified_at',
        'is_admin',
        'role_id',
        // Membership fields
        'membership_type',
        'membership_start_date',
        'membership_end_date',
        'membership_benefits',
        'membership_discount_rate',
        'membership_point_multiplier',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            // Membership casting
            'membership_start_date' => 'datetime',
            'membership_end_date' => 'datetime',
            'membership_benefits' => 'array',
            'membership_discount_rate' => 'decimal:2',
            'membership_point_multiplier' => 'decimal:2',
        ];
    }

    // Membership helper methods
    
    /**
     * Get all available membership types
     */
    public static function getMembershipTypes(): array
    {
        return [
            self::MEMBERSHIP_EXMEMBER => [
                'name' => 'EX MEMBER',
                'description' => 'Basic membership tier',
                'discount_rate' => 0.00,
                'point_multiplier' => 1.00,
                'color' => '#6B7280', // Gray
                'benefits' => [
                    'basic_access' => true,
                    'standard_support' => true,
                ]
            ],
            self::MEMBERSHIP_EXDOCTOR => [
                'name' => 'EX DOCTOR',
                'description' => 'Special membership for medical professionals',
                'discount_rate' => 15.00,
                'point_multiplier' => 1.50,
                'color' => '#3B82F6', // Blue
                'benefits' => [
                    'doctor_exclusive_products' => true,
                    'medical_information' => true,
                    'priority_support' => true,
                    'professional_discount' => true,
                ]
            ],
            self::MEMBERSHIP_EXVIP => [
                'name' => 'EX VIP',
                'description' => 'Premium membership tier',
                'discount_rate' => 20.00,
                'point_multiplier' => 2.00,
                'color' => '#F59E0B', // Gold
                'benefits' => [
                    'vip_exclusive_products' => true,
                    'free_shipping' => true,
                    'priority_support' => true,
                    'early_access' => true,
                    'vip_events' => true,
                ]
            ],
            self::MEMBERSHIP_EXSUPERVIP => [
                'name' => 'EX SUPERVIP',
                'description' => 'Highest tier membership',
                'discount_rate' => 25.00,
                'point_multiplier' => 3.00,
                'color' => '#8B5CF6', // Purple
                'benefits' => [
                    'super_vip_exclusive_products' => true,
                    'personal_consultant' => true,
                    'unlimited_support' => true,
                    'exclusive_events' => true,
                    'custom_orders' => true,
                    'premium_shipping' => true,
                ]
            ],
        ];
    }

    /**
     * Get membership information
     */
    public function getMembershipInfo(): array
    {
        $types = self::getMembershipTypes();
        return $types[$this->membership_type] ?? $types[self::MEMBERSHIP_EXMEMBER];
    }

    /**
     * Check if membership is active
     */
    public function isMembershipActive(): bool
    {
        if (!$this->membership_end_date) {
            return true; // Lifetime membership
        }
        
        return $this->membership_end_date->isFuture();
    }

    /**
     * Get membership status
     */
    public function getMembershipStatus(): string
    {
        if (!$this->membership_start_date) {
            return 'inactive';
        }
        
        if (!$this->isMembershipActive()) {
            return 'expired';
        }
        
        return 'active';
    }

    /**
     * Check if user has specific membership benefit
     */
    public function hasBenefit(string $benefit): bool
    {
        $membershipInfo = $this->getMembershipInfo();
        return $membershipInfo['benefits'][$benefit] ?? false;
    }

    /**
     * Calculate final price with membership discount
     */
    public function calculateDiscountedPrice(float $originalPrice): float
    {
        if (!$this->isMembershipActive()) {
            return $originalPrice;
        }

        $discountAmount = $originalPrice * ($this->membership_discount_rate / 100);
        return $originalPrice - $discountAmount;
    }

    /**
     * Calculate points with membership multiplier
     */
    public function calculatePoints(float $spentAmount): float
    {
        if (!$this->isMembershipActive()) {
            return $spentAmount; // 1:1 ratio for inactive
        }

        return $spentAmount * $this->membership_point_multiplier;
    }

    /**
     * Get the role that owns the user.
     */
    public function role(): BelongsTo
    {
        return $this->belongsTo(Role::class);
    }

    /**
     * Relationship with orders
     */
    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Relationship with customer addresses
     */
    public function customerAddresses()
    {
        return $this->hasMany(CustomerAddress::class);
    }

    /**
     * Alias for customerAddresses relationship
     */
    public function addresses()
    {
        return $this->hasMany(CustomerAddress::class);
    }

    /**
     * Get default address for the user
     */
    public function getDefaultAddress()
    {
        return $this->customerAddresses()->where('is_default', true)->first();
    }

    /**
     * Get all addresses ordered by default first
     */
    public function getAllAddresses()
    {
        return $this->customerAddresses()->orderByDesc('is_default')->orderBy('name')->get();
    }
}
