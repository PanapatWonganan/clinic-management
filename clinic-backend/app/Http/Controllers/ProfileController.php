<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use App\Models\MembershipBundleDeal;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        
        return response()->json([
            'success' => true,
            'profile' => [
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? '081-234-5678',
                'address' => $user->address ?? '123/45 หมู่ 6 ซอยลาดพร้าว 15 แยก 3\nถนนลาดพร้าว',
                'district' => $user->district ?? 'จอมพล',
                'province' => $user->province ?? 'กรุงเทพมหานคร',
                'postalCode' => $user->postal_code ?? '10900',
                'provinceId' => $user->province_id,
                'districtId' => $user->district_id,
                'subDistrictId' => $user->sub_district_id,
            ]
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'district' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'postalCode' => 'nullable|string|max:10',
            'provinceId' => 'nullable|integer',
            'districtId' => 'nullable|integer',
            'subDistrictId' => 'nullable|integer',
            'password' => ['sometimes', Password::defaults()],
        ]);

        // Update password if provided
        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        // Map postalCode to postal_code for database
        if (isset($validated['postalCode'])) {
            $validated['postal_code'] = $validated['postalCode'];
            unset($validated['postalCode']);
        }

        // Map Thai address IDs to database columns and update string fields
        if (isset($validated['provinceId'])) {
            $validated['province_id'] = $validated['provinceId'];
            unset($validated['provinceId']);
        }

        if (isset($validated['districtId'])) {
            $validated['district_id'] = $validated['districtId'];
            unset($validated['districtId']);
        }

        if (isset($validated['subDistrictId'])) {
            $validated['sub_district_id'] = $validated['subDistrictId'];
            unset($validated['subDistrictId']);
        }

        // Update string fields from provided data (these come from Flutter when user selects from dropdowns)
        if (isset($validated['district'])) {
            // District field contains the sub-district name when using Thai address dropdown
            $validated['district'] = $validated['district'];
        }
        
        if (isset($validated['province'])) {
            $validated['province'] = $validated['province'];
        }
        
        if (isset($validated['postalCode'])) {
            // Already handled above, just ensure it's in the right format
        }

        $user->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'อัปเดตข้อมูลโปรไฟล์สำเร็จ',
            'profile' => [
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,
                'district' => $user->district,
                'province' => $user->province,
                'postalCode' => $user->postal_code,
                'provinceId' => $user->province_id,
                'districtId' => $user->district_id,
                'subDistrictId' => $user->sub_district_id,
            ]
        ]);
    }

    public function getMembershipProgress(Request $request)
    {
        $user = $request->user();

        // Check and perform upgrade if eligible
        $this->checkAndUpgradeMembership($user);

        // Calculate real data from user's orders
        $completedOrders = $user->orders()
            ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered'])
            ->with('orderItems')
            ->get();

        $totalSpent = $completedOrders->sum('total_amount');
        $totalPurchasedQuantity = $completedOrders->sum(function ($order) {
            return $order->orderItems->sum('quantity');
        });

        // Calculate points: 1 point per 10,000 baht spent
        $currentPoints = floor($totalSpent / 10000);

        // ดึงรางวัลที่แลกไปแล้ว (approved) เพื่อหัก quantity ออก
        $claimedRewards = \App\Models\UserClaimedReward::where('user_id', $user->id)
            ->where('status', 'approved')
            ->get();

        // Map membership_type to role_id for bundle deals filtering
        $membershipToRoleId = [
            'exMember' => 1,    // ex_member
            'exVip' => 2,       // ex_vip
            'exSuperVip' => 3,  // ex_supervip
            'exDoctor' => 4,    // ex_doctor
        ];

        $roleId = $membershipToRoleId[$user->membership_type] ?? 1; // Default to ex_member

        // Get bundle deals for user's specific membership type
        $bundleDeals = MembershipBundleDeal::where('is_active', true)
            ->where('role_id', $roleId)
            ->orderBy('level')
            ->get();

        $levelProgress = [];
        $totalEarnedItems = 0;
        $totalSavings = 0;

        // ตรวจสอบว่ามีการแลกรางวัลไปแล้วหรือไม่
        $hasClaimedAnyReward = $claimedRewards->isNotEmpty();

        // กำหนด base quantity ที่จะใช้คำนวณ
        $baseQuantity = $totalPurchasedQuantity;

        if ($hasClaimedAnyReward) {
            // ถ้าแลกรางวัลไปแล้ว ให้เริ่มใหม่หมด - ใช้ quantity หลังจากแลกล่าสุด
            $latestClaim = $claimedRewards->sortByDesc('created_at')->first();

            // หา orders ที่เกิดขึ้นหลังจากแลกรางวัลล่าสุด
            $ordersAfterClaim = $user->orders()
                ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered', 'payment_uploaded'])
                ->where('created_at', '>', $latestClaim->created_at)
                ->with('orderItems')
                ->get();

            $baseQuantity = $ordersAfterClaim->sum(function ($order) {
                return $order->orderItems->sum('quantity');
            });
        }

        // ดึง levels ที่เคยแลกไปแล้ว
        $claimedLevels = $claimedRewards->pluck('level')->toArray();

        // คำนวณ cascading levels - แต่ละ level ใช้ items ที่เหลือจาก level ก่อนหน้า
        $remainingQuantity = $baseQuantity;

        foreach ($bundleDeals as $deal) {
            // Logic ง่ายๆ: ตรวจสอบว่ามี quantity พอแลกหรือไม่
            if ($baseQuantity >= $deal->required_quantity) {
                $canClaim = true;
                $currentProgress = 100; // ครบแล้ว สามารถแลกได้
                $remainingForNext = 0;
            } else {
                $canClaim = false;
                $currentProgress = ($baseQuantity / $deal->required_quantity) * 100;
                $remainingForNext = $deal->required_quantity - $baseQuantity;
            }

            $levelProgress[] = [
                'level' => $deal->level,
                'name' => "Level {$deal->level}",
                'display_name' => $deal->display_name,
                'required_quantity' => $deal->required_quantity,
                'free_quantity' => $deal->free_quantity,
                'current_quantity' => min($baseQuantity, $deal->required_quantity),
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

        return response()->json([
            'success' => true,
            'data' => [
                'user_id' => $user->id,
                'membership_type' => $user->membership_type ?? 'exMember',
                'total_purchased_quantity' => $totalPurchasedQuantity,
                'total_spent' => $totalSpent,
                'current_points' => $currentPoints,
                'total_earned_items' => $totalEarnedItems,
                'total_savings' => $totalSavings,
                'level_progress' => $levelProgress,
                'next_milestone' => $this->getNextMilestone($totalPurchasedQuantity, $bundleDeals),
                'available_rewards' => $this->getAvailableRewards($levelProgress, $claimedLevels)
            ]
        ]);
    }

    private function getNextMilestone($currentQuantity, $bundleDeals)
    {
        foreach ($bundleDeals as $deal) {
            $nextBundle = intval($currentQuantity / $deal->required_quantity) + 1;
            $nextMilestoneQuantity = $nextBundle * $deal->required_quantity;

            if ($nextMilestoneQuantity > $currentQuantity) {
                $remaining = $nextMilestoneQuantity - $currentQuantity;
                return [
                    'level' => $deal->level,
                    'display_name' => $deal->display_name,
                    'target_quantity' => $nextMilestoneQuantity,
                    'remaining_quantity' => $remaining,
                    'reward_items' => $deal->free_quantity,
                    'potential_savings' => $deal->savings_amount
                ];
            }
        }

        return null;
    }

    private function getAvailableRewards($levelProgress, $claimedLevels = [])
    {
        $availableRewards = [];

        foreach ($levelProgress as $level) {
            // If the level is completed, has earned items, and hasn't been claimed yet
            if ($level['is_completed'] &&
                $level['completed_bundles'] > 0 &&
                !in_array($level['level'], $claimedLevels)) {

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

    public function claimReward(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'level' => 'required|integer|min:1|max:3',
            'reward_type' => 'required|string|in:bundle_deal',
        ]);

        // ตรวจสอบว่าผู้ใช้เคยแลกรางวัลนี้แล้วหรือไม่
        $existingClaim = \App\Models\UserClaimedReward::where('user_id', $user->id)
            ->where('level', $validated['level'])
            ->where('reward_type', $validated['reward_type'])
            ->first();

        if ($existingClaim) {
            return response()->json([
                'success' => false,
                'message' => 'คุณได้แลกรางวัลนี้ไปแล้ว',
                'error' => 'ALREADY_CLAIMED',
                'claim_status' => $existingClaim->status,
                'claimed_at' => $existingClaim->created_at->toISOString()
            ], 400);
        }

        // ตรวจสอบว่าผู้ใช้มีสิทธิ์แลกรางวัลนี้หรือไม่
        $progressData = $this->getMembershipProgressData($user);

        // ดึง levels ที่เคยแลกไปแล้ว (ยกเว้นการแลกปัจจุบัน)
        $claimedLevels = \App\Models\UserClaimedReward::where('user_id', $user->id)
            ->where('status', 'approved')
            ->pluck('level')
            ->toArray();

        $availableRewards = $this->getAvailableRewards($progressData['level_progress'], $claimedLevels);

        $targetReward = null;
        foreach ($availableRewards as $reward) {
            if ($reward['level'] == $validated['level']) {
                $targetReward = $reward;
                break;
            }
        }

        if (!$targetReward) {
            return response()->json([
                'success' => false,
                'message' => 'ไม่พบสิทธิ์การแลกรางวัลระดับนี้',
                'error' => 'REWARD_NOT_AVAILABLE'
            ], 400);
        }

        try {
            // บันทึกการแลกรางวัลลงฐานข้อมูล
            $claimedReward = \App\Models\UserClaimedReward::create([
                'user_id' => $user->id,
                'level' => $validated['level'],
                'reward_type' => $validated['reward_type'],
                'status' => 'pending'
            ]);

            return response()->json([
                'success' => true,
                'message' => 'ส่งคำขอแลกรางวัลแล้ว รอการอนุมัติจากแอดมิน',
                'claimed_reward' => [
                    'id' => $claimedReward->id,
                    'level' => $targetReward['level'],
                    'display_name' => $targetReward['display_name'],
                    'required_quantity' => $targetReward['required_quantity'],
                    'earned_free_items' => $targetReward['earned_free_items'],
                    'savings_amount' => $targetReward['savings_amount'],
                    'status' => 'pending',
                    'claimed_at' => $claimedReward->created_at->toISOString(),
                ],
                'remaining_rewards' => $this->getRemainingRewards($availableRewards, $validated['level'])
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการแลกรางวัล',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function getMembershipProgressData($user)
    {
        // คำนวณข้อมูลความคืบหน้าสมาชิก (คัดลอกจาก getMembershipProgress)
        $completedOrders = $user->orders()
            ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered'])
            ->with('orderItems')
            ->get();

        $totalSpent = $completedOrders->sum('total_amount');
        $totalPurchasedQuantity = $completedOrders->sum(function ($order) {
            return $order->orderItems->sum('quantity');
        });

        // ดึงรางวัลที่แลกไปแล้ว (approved) เพื่อหัก quantity ออก
        $claimedRewards = \App\Models\UserClaimedReward::where('user_id', $user->id)
            ->where('status', 'approved')
            ->get();

        $bundleDeals = \App\Models\MembershipBundleDeal::where('is_active', true)
            ->orderBy('level')
            ->get();

        $levelProgress = [];
        foreach ($bundleDeals as $deal) {
            // ตรวจสอบว่ามีการแลกรางวัลไปแล้วหรือไม่
            $hasClaimedAnyReward = $claimedRewards->isNotEmpty();

            if ($hasClaimedAnyReward) {
                // ถ้าแลกรางวัลไปแล้ว ให้เริ่มใหม่หมด - ใช้ quantity หลังจากแลกล่าสุด
                $latestClaim = $claimedRewards->sortByDesc('created_at')->first();

                // หา orders ที่เกิดขึ้นหลังจากแลกรางวัลล่าสุด
                $ordersAfterClaim = $user->orders()
                    ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered'])
                    ->where('created_at', '>', $latestClaim->created_at)
                    ->with('orderItems')
                    ->get();

                $quantityAfterClaim = $ordersAfterClaim->sum(function ($order) {
                    return $order->orderItems->sum('quantity');
                });

                $completedBundles = intval($quantityAfterClaim / $deal->required_quantity);
                $earnedFreeItems = $completedBundles * $deal->free_quantity;
                $bundleSavings = $completedBundles * $deal->savings_amount;
                $currentProgress = ($quantityAfterClaim / $deal->required_quantity) * 100;
                $effectiveQuantity = $quantityAfterClaim;
            } else {
                // ถ้ายังไม่เคยแลกรางวัล ใช้ calculation ปกติ
                $completedBundles = intval($totalPurchasedQuantity / $deal->required_quantity);
                $earnedFreeItems = $completedBundles * $deal->free_quantity;
                $bundleSavings = $completedBundles * $deal->savings_amount;
                $currentProgress = ($totalPurchasedQuantity / $deal->required_quantity) * 100;
                $effectiveQuantity = $totalPurchasedQuantity;
            }

            if ($currentProgress > 100) {
                $currentProgress = 100;
            }

            $levelProgress[] = [
                'level' => $deal->level,
                'name' => "Level {$deal->level}",
                'display_name' => $deal->display_name,
                'required_quantity' => $deal->required_quantity,
                'free_quantity' => $deal->free_quantity,
                'current_quantity' => $effectiveQuantity,
                'progress_percentage' => round($currentProgress, 1),
                'is_completed' => $completedBundles > 0,
                'completed_bundles' => $completedBundles,
                'earned_free_items' => $earnedFreeItems,
                'savings_amount' => $bundleSavings,
                'unit_price' => $deal->unit_price,
                'effective_price' => $deal->effective_price_per_unit,
                'remaining_for_next' => max(0, $deal->required_quantity - $effectiveQuantity)
            ];
        }

        return ['level_progress' => $levelProgress];
    }

    private function getRemainingRewards($availableRewards, $claimedLevel)
    {
        // ส่งกลับรางวัลที่เหลือหลังจากแลกรางวัลแล้ว
        return array_filter($availableRewards, function($reward) use ($claimedLevel) {
            return $reward['level'] !== $claimedLevel;
        });
    }

    private function checkAndUpgradeMembership($user)
    {
        // Skip upgrade for exDoctor - special role
        if ($user->membership_type === 'exDoctor') {
            return;
        }

        // Get current total spent
        $totalSpent = $user->orders()
            ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered'])
            ->sum('total_amount');

        // Check for possible upgrades
        $upgradeRule = \DB::table('membership_upgrade_rules')
            ->where('from_type', $user->membership_type)
            ->where('min_spent', '<=', $totalSpent)
            ->where('is_active', true)
            ->first();

        if ($upgradeRule) {
            // Perform upgrade
            $oldType = $user->membership_type;
            $user->membership_type = $upgradeRule->to_type;
            $user->save();

            // Log upgrade event
            $this->logMembershipUpgrade($user, $oldType, $upgradeRule->to_type, $totalSpent);
        }
    }

    private function logMembershipUpgrade($user, $fromType, $toType, $totalSpent)
    {
        // Create membership upgrade log (assuming we'll create this table later)
        try {
            \DB::table('membership_upgrade_logs')->insert([
                'user_id' => $user->id,
                'from_type' => $fromType,
                'to_type' => $toType,
                'total_spent_at_upgrade' => $totalSpent,
                'upgraded_at' => now(),
                'created_at' => now(),
            ]);
        } catch (\Exception $e) {
            // If table doesn't exist yet, just log to Laravel log
            \Log::info("User {$user->id} upgraded from {$fromType} to {$toType} at {$totalSpent} baht");
        }
    }
}