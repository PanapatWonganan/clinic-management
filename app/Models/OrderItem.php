<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    /** @use HasFactory<\Database\Factories\OrderItemFactory> */
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'quantity',
        'price',
        'total_price'
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'total_price' => 'decimal:2'
    ];

    // Relationships
    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    // Accessors
    public function getTotalPriceFormattedAttribute()
    {
        return number_format($this->total_price, 0) . '.-';
    }

    public function getPriceFormattedAttribute()
    {
        return number_format($this->price, 0) . '.-';
    }

    // Mutators
    public function setTotalPriceAttribute($value)
    {
        $this->attributes['total_price'] = $this->price * $this->quantity;
    }
} 