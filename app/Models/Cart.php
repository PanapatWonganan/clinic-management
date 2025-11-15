<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    /** @use HasFactory<\Database\Factories\CartFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id'
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function cartItems()
    {
        return $this->hasMany(CartItem::class);
    }

    // Accessors
    public function getTotalAmountAttribute()
    {
        return $this->cartItems->sum(function ($item) {
            return $item->quantity * $item->product->price;
        });
    }

    public function getTotalItemsAttribute()
    {
        return $this->cartItems->sum('quantity');
    }

    public function getTotalAmountFormattedAttribute()
    {
        return number_format($this->total_amount, 0) . '.-';
    }

    // Methods
    public function addItem($productId, $quantity = 1)
    {
        $existingItem = $this->cartItems()->where('product_id', $productId)->first();

        if ($existingItem) {
            $existingItem->increment('quantity', $quantity);
            return $existingItem;
        }

        return $this->cartItems()->create([
            'product_id' => $productId,
            'quantity' => $quantity
        ]);
    }

    public function removeItem($productId)
    {
        return $this->cartItems()->where('product_id', $productId)->delete();
    }

    public function updateItemQuantity($productId, $quantity)
    {
        if ($quantity <= 0) {
            return $this->removeItem($productId);
        }

        return $this->cartItems()->where('product_id', $productId)->update(['quantity' => $quantity]);
    }

    public function clear()
    {
        return $this->cartItems()->delete();
    }
} 