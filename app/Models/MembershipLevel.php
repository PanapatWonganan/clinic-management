<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MembershipLevel extends Model
{
    /** @use HasFactory<\Database\Factories\MembershipLevelFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'required_boxes',
        'free_boxes', 
        'description',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean'
    ];

    // Relationships
    public function users()
    {
        return $this->hasMany(User::class, 'current_membership_level_id');
    }

    // Accessors
    public function getBoxesDisplayAttribute()
    {
        return $this->required_boxes . ' กล่อง';
    }

    public function getFreeDisplayAttribute()
    {
        return 'ฟรี ' . $this->free_boxes;
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Static methods
    public static function calculateMembershipLevel($totalPurchases)
    {
        return self::active()
                   ->where('required_boxes', '<=', $totalPurchases)
                   ->orderBy('required_boxes', 'desc')
                   ->first();
    }

    public static function getProgressForUser($user)
    {
        $currentLevel = $user->currentMembershipLevel;
        if (!$currentLevel) {
            $nextLevel = self::active()->orderBy('required_boxes')->first();
            if (!$nextLevel) return 0;
            
            return ($user->total_purchases / $nextLevel->required_boxes) * 100;
        }

        $nextLevel = self::active()
                        ->where('required_boxes', '>', $currentLevel->required_boxes)
                        ->orderBy('required_boxes')
                        ->first();

        if (!$nextLevel) return 100; // Max level reached

        $progress = (($user->total_purchases - $currentLevel->required_boxes) / 
                    ($nextLevel->required_boxes - $currentLevel->required_boxes)) * 100;

        return min(100, max(0, $progress));
    }
} 