<?php

namespace App\Services;

use App\Models\User;
use App\Models\MembershipBundleDeal;
use App\Models\UserClaimedReward;

class MembershipProgressService
{
    /**
     * Get membership progress for a user
     */
    public function getMembershipProgress(User $user): array
    {
        // Calculate real data from user's orders
        // ไม่นับ orders ที่เป็น free item (is_free_item_order = true)
        $completedOrders = $user->orders()
            ->whereIn('status', ['pending_payment', 'payment_uploaded', 'paid', 'confirmed', 'processing', 'shipped', 'delivered'])
            ->where(function ($query) {
                $query->where('is_free_item_order', false)
                      ->orWhereNull('is_free_item_order');
            })
            ->with('orderItems')
            ->get();

        $totalSpent = $completedOrders->sum('total_amount');
        $totalPurchasedQuantity = $completedOrders->sum(function ($order) {
            return $order->orderItems->sum('quantity');
        });

        // Calculate points: 1 point per 10,000 baht spent
        $currentPoints = floor($totalSpent / 10000);

        // Get claimed rewards (approved)
        $claimedRewards = UserClaimedReward::where('user_id', $user->id)
            ->where('status', 'approved')
            ->get();

        // Map membership_type to role_id
        $membershipToRoleId = [
            'exMember' => 1,
            'exVip' => 2,
            'exSuperVip' => 3,
            'exDoctor' => 4,
        ];

        $roleId = $membershipToRoleId[$user->membership_type] ?? 1;

        // Get bundle deals for user's membership type
        $bundleDeals = MembershipBundleDeal::where('is_active', true)
            ->where('role_id', $roleId)
            ->orderBy('level')
            ->get();

        $levelProgress = [];
        $totalEarnedItems = 0;
        $totalSavings = 0;

        // Calculate effective quantity (after last claim reset)
        $hasClaimedAnyReward = $claimedRewards->isNotEmpty();
        $effectiveQuantity = $totalPurchasedQuantity;

        if ($hasClaimedAnyReward) {
            $latestClaim = $claimedRewards->sortByDesc('created_at')->first();

            // ไม่นับ orders ที่เป็น free item
            $ordersQuery = $user->orders()
                ->whereIn('status', ['pending_payment', 'payment_uploaded', 'paid', 'confirmed', 'processing', 'shipped', 'delivered'])
                ->where(function ($q) {
                    $q->where('is_free_item_order', false)->orWhereNull('is_free_item_order');
                });

            if ($latestClaim->order_id) {
                $ordersQuery->where('id', '>', $latestClaim->order_id);
            } else {
                $ordersQuery->where('created_at', '>', $latestClaim->created_at);
            }

            $ordersAfterClaim = $ordersQuery->with('orderItems')->get();

            $effectiveQuantity = $ordersAfterClaim->sum(function ($order) {
                return $order->orderItems->sum('quantity');
            });
        }

        // Calculate level progress
        foreach ($bundleDeals as $deal) {
            if ($effectiveQuantity >= $deal->required_quantity) {
                $canClaim = true;
                $currentProgress = 100;
                $remainingForNext = 0;
            } else {
                $canClaim = false;
                $currentProgress = ($effectiveQuantity / $deal->required_quantity) * 100;
                $remainingForNext = $deal->required_quantity - $effectiveQuantity;
            }

            $levelProgress[] = [
                'level' => $deal->level,
                'name' => "Level {$deal->level}",
                'display_name' => $deal->display_name,
                'required_quantity' => $deal->required_quantity,
                'free_quantity' => $deal->free_quantity,
                'current_quantity' => min($effectiveQuantity, $deal->required_quantity),
                'progress_percentage' => round($currentProgress, 1),
                'is_completed' => $canClaim,
                'completed_bundles' => $canClaim ? 1 : 0,
                'earned_free_items' => $canClaim ? $deal->free_quantity : 0,
                'savings_amount' => $canClaim ? $deal->savings_amount : 0,
                'unit_price' => $deal->unit_price,
                'effective_price' => $deal->effective_price_per_unit,
                'remaining_for_next' => $remainingForNext
            ];

            if ($canClaim) {
                $totalEarnedItems += $deal->free_quantity;
                $totalSavings += $deal->savings_amount;
            }
        }

        // Get available rewards
        $availableRewards = $this->getAvailableRewards($levelProgress);

        return [
            'user_id' => $user->id,
            'membership_type' => $user->membership_type ?? 'exMember',
            'total_purchased_quantity' => $totalPurchasedQuantity,
            'effective_quantity' => $effectiveQuantity,
            'total_spent' => $totalSpent,
            'current_points' => $currentPoints,
            'total_earned_items' => $totalEarnedItems,
            'total_savings' => $totalSavings,
            'level_progress' => $levelProgress,
            'next_milestone' => $this->getNextMilestone($effectiveQuantity, $bundleDeals),
            'available_rewards' => $availableRewards,
            'has_claimed_before' => $hasClaimedAnyReward,
            'last_claim_date' => $hasClaimedAnyReward ? $claimedRewards->sortByDesc('created_at')->first()->created_at->toISOString() : null
        ];
    }

    /**
     * Get available rewards from level progress
     */
    private function getAvailableRewards(array $levelProgress): array
    {
        $availableRewards = [];

        foreach ($levelProgress as $level) {
            if ($level['is_completed'] && $level['completed_bundles'] > 0) {
                $availableRewards[] = [
                    'level' => $level['level'],
                    'required_quantity' => intval($level['required_quantity']),
                    'earned_free_items' => intval($level['earned_free_items']),
                    'savings_amount' => floatval($level['savings_amount']),
                    'unit_price' => floatval($level['unit_price']),
                    'display_name' => $level['display_name'],
                    'completed_bundles' => intval($level['completed_bundles'])
                ];
            }
        }

        return $availableRewards;
    }

    /**
     * Get next milestone info
     */
    private function getNextMilestone(int $currentQuantity, $bundleDeals): ?array
    {
        foreach ($bundleDeals as $deal) {
            $nextBundle = intval($currentQuantity / $deal->required_quantity) + 1;
            $nextMilestoneQuantity = $nextBundle * $deal->required_quantity;

            if ($nextMilestoneQuantity > $currentQuantity) {
                $remaining = $nextMilestoneQuantity - $currentQuantity;
                return [
                    'level' => $deal->level,
                    'target_quantity' => $nextMilestoneQuantity,
                    'remaining' => $remaining,
                    'free_quantity' => $deal->free_quantity,
                    'savings_amount' => $deal->savings_amount
                ];
            }
        }

        return null;
    }
}
