<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UserClaimedReward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RewardController extends Controller
{
    public function index()
    {
        $rewards = UserClaimedReward::with(['user', 'approver'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        $stats = [
            'total_claims' => UserClaimedReward::count(),
            'pending_claims' => UserClaimedReward::where('status', 'pending')->count(),
            'approved_claims' => UserClaimedReward::where('status', 'approved')->count(),
            'rejected_claims' => UserClaimedReward::where('status', 'rejected')->count(),
        ];

        return view('admin.rewards.index', compact('rewards', 'stats'));
    }

    public function show($id)
    {
        $reward = UserClaimedReward::with(['user', 'approver'])->findOrFail($id);

        return view('admin.rewards.show', compact('reward'));
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,approved,rejected',
            'admin_notes' => 'nullable|string|max:1000',
        ]);

        $reward = UserClaimedReward::findOrFail($id);

        if ($reward->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'ไม่สามารถเปลี่ยนสถานะของรางวัลที่ได้รับการตอบกลับแล้ว',
            ], 422);
        }

        $reward->update([
            'status' => $request->status,
            'admin_notes' => $request->admin_notes,
            'approved_by' => Auth::id(),
            'approved_at' => now(),
        ]);

        $statusMessages = [
            'approved' => 'อนุมัติการแลกรางวัลเรียบร้อยแล้ว',
            'rejected' => 'ปฏิเสธการแลกรางวัลแล้ว',
        ];

        return response()->json([
            'success' => true,
            'message' => $statusMessages[$request->status] ?? 'อัพเดตสถานะเรียบร้อยแล้ว',
        ]);
    }

    public function destroy($id)
    {
        $reward = UserClaimedReward::findOrFail($id);
        $reward->delete();

        return response()->json([
            'success' => true,
            'message' => 'ลบรายการแลกรางวัลเรียบร้อยแล้ว',
        ]);
    }

    /**
     * Cancel a points-based reward redemption: refund points to the user and
     * restore product stock. Idempotent — a row already cancelled is skipped.
     */
    public function cancelRewardRedemption($id)
    {
        \Illuminate\Support\Facades\DB::transaction(function () use ($id) {
            $redemption = \App\Models\RewardRedemption::where('id', $id)->lockForUpdate()->first();
            if (! $redemption || $redemption->status === \App\Models\RewardRedemption::STATUS_CANCELLED) {
                return;
            }

            $user = \App\Models\User::where('id', $redemption->user_id)->lockForUpdate()->first();
            if ($user) {
                $user->points_spent = max(0, (int) $user->points_spent - (int) $redemption->points_total);
                $user->save();
            }

            $product = \App\Models\Product::where('id', $redemption->product_id)->lockForUpdate()->first();
            if ($product) {
                $product->stock = (int) $product->stock + (int) $redemption->quantity;
                $product->save();
            }

            $redemption->status = \App\Models\RewardRedemption::STATUS_CANCELLED;
            $redemption->save();
        });

        return back()->with('success', 'ยกเลิกและคืนคะแนนเรียบร้อย');
    }

    public function stats()
    {
        $stats = [
            'total_claims' => UserClaimedReward::count(),
            'pending_claims' => UserClaimedReward::where('status', 'pending')->count(),
            'approved_claims' => UserClaimedReward::where('status', 'approved')->count(),
            'rejected_claims' => UserClaimedReward::where('status', 'rejected')->count(),
            'level_breakdown' => [
                'level_1' => UserClaimedReward::where('level', 1)->count(),
                'level_2' => UserClaimedReward::where('level', 2)->count(),
                'level_3' => UserClaimedReward::where('level', 3)->count(),
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}
