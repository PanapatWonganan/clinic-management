<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentSlip extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'file_name',
        'file_path',
        'original_name',
        'file_size',
        'mime_type',
        'status',
        'admin_notes',
        'reviewed_at',
        'reviewed_by'
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'file_size' => 'integer'
    ];

    /**
     * Get the order that owns the payment slip
     */
    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Get the admin user who reviewed this slip
     */
    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    /**
     * Get status display name in Thai
     */
    public function getStatusDisplayAttribute()
    {
        $statuses = [
            'pending' => 'รอตรวจสอบ',
            'approved' => 'อนุมัติแล้ว',
            'rejected' => 'ปฏิเสธ'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    /**
     * Get file size in human readable format
     */
    public function getFileSizeFormattedAttribute()
    {
        $bytes = $this->file_size;
        
        if ($bytes < 1024) {
            return $bytes . ' B';
        } elseif ($bytes < 1024 * 1024) {
            return round($bytes / 1024, 2) . ' KB';
        } else {
            return round($bytes / (1024 * 1024), 2) . ' MB';
        }
    }

    /**
     * Scope for pending slips
     */
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    /**
     * Scope for approved slips
     */
    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    /**
     * Scope for rejected slips
     */
    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }
}