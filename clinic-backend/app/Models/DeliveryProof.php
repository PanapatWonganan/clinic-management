<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryProof extends Model
{
    protected $fillable = [
        'order_id',
        'image_path',
        'original_filename',
        'file_size',
        'mime_type',
        'uploaded_by',
        'notes',
    ];

    protected $casts = [
        'file_size' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $appends = [
        'image_url',
        'file_size_formatted',
    ];

    // Relationships
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    // Accessors
    public function getImageUrlAttribute(): string
    {
        return asset('storage/' . $this->image_path);
    }

    public function getFileSizeFormattedAttribute(): string
    {
        if (!$this->file_size) return 'N/A';
        
        $bytes = $this->file_size;
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
}
