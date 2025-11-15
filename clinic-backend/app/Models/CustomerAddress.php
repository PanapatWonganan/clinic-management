<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerAddress extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'recipient_name',
        'phone',
        'address_line_1',
        'address_line_2',
        'district',
        'province',
        'postal_code',
        'province_id',
        'district_id',
        'sub_district_id',
        'is_default',
    ];

    protected $casts = [
        'is_default' => 'boolean',
    ];

    // Relationships
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'shipping_address_id');
    }

    // Accessors
    public function getFullAddressAttribute(): string
    {
        $parts = array_filter([
            $this->address_line_1,
            $this->address_line_2,
            $this->district,
            $this->province,
            $this->postal_code,
        ]);

        return implode(', ', $parts);
    }

    // Scopes
    public function scopeDefault($query)
    {
        return $query->where('is_default', true);
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    // Static methods
    public static function setAsDefault($userId, $addressId)
    {
        // Remove default from all addresses for this user
        static::where('user_id', $userId)->update(['is_default' => false]);
        
        // Set the specified address as default
        static::where('id', $addressId)->where('user_id', $userId)->update(['is_default' => true]);
    }

    public static function createDefault($userId, array $addressData)
    {
        // Remove default from all existing addresses
        static::where('user_id', $userId)->update(['is_default' => false]);
        
        // Create new default address
        return static::create(array_merge($addressData, [
            'user_id' => $userId,
            'is_default' => true,
        ]));
    }
}
