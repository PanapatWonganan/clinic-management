<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;

class RewardPointsService
{
    /**
     * Points earned = floor(total completed spend / 10000). Mirrors
     * ProfileController@getMembershipProgress so this never diverges from the
     * displayed current_points. Excludes free-item orders.
     *
     * Uses the same status list as ProfileController (pending_payment,
     * payment_uploaded, paid, confirmed, processing, shipped, delivered) —
     * NOT just 'completed'.
     */
    public function earnedPoints(User $user): int
    {
        $totalSpent = Order::where('user_id', $user->id)
            ->whereIn('status', ['pending_payment', 'payment_uploaded', 'paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->where(function ($query) {
                $query->where('is_free_item_order', false)
                    ->orWhereNull('is_free_item_order');
            })
            ->sum('total_amount');

        return (int) floor($totalSpent / 10000);
    }

    /**
     * Spendable balance = earned - already spent, never below 0 for display.
     */
    public function balance(User $user): int
    {
        return max(0, $this->earnedPoints($user) - (int) $user->points_spent);
    }
}
