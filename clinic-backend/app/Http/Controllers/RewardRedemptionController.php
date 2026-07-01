<?php

namespace App\Http\Controllers;

use App\Models\CustomerAddress;
use App\Models\Product;
use App\Models\RewardRedemption;
use App\Models\User;
use App\Services\RewardPointsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class RewardRedemptionController extends Controller
{
    public function __construct(private RewardPointsService $points) {}

    /** GET /reward-catalog — reward products available to redeem. */
    public function catalog()
    {
        $products = Product::where('category', 'reward')
            ->where('is_active', true)
            ->where('stock', '>', 0)
            ->get()
            ->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'description' => $p->description,
                'points' => (int) $p->points,
                'image' => $p->image_url ?: null, // products column is image_url
                'stock' => (int) $p->stock,
            ]);

        return response()->json(['success' => true, 'data' => $products]);
    }
    // Note: products stores the image path in `image_url` (not `image`).
    // ProductController@getRewardProducts runs rewriteStoredImageUrls() to
    // resolve it to a full URL; reuse that helper if you need resolved URLs.
    // Seeded reward items have image_url = null → frontend uses an icon fallback.

    /** GET /reward-points/balance */
    public function balance()
    {
        $user = Auth::user();

        return response()->json([
            'success' => true,
            'data' => [
                'points_balance' => $this->points->balance($user),
                'points_earned' => $this->points->earnedPoints($user),
                'points_spent' => (int) $user->points_spent,
            ],
        ]);
    }

    /** POST /reward-redemptions */
    public function redeem(Request $request)
    {
        $data = $request->validate([
            'product_id' => 'required|integer|exists:products,id',
            'quantity' => 'required|integer|min:1',
            'shipping_address_id' => 'required|integer',
            'notes' => 'nullable|string|max:1000',
        ]);

        try {
            $result = DB::transaction(function () use ($data) {
                /** @var User $user */
                $user = User::where('id', Auth::id())->lockForUpdate()->first();

                $product = Product::where('id', $data['product_id'])
                    ->lockForUpdate()
                    ->first();

                if (! $product || $product->category !== 'reward' || ! $product->is_active) {
                    abort(422, 'สินค้านี้ไม่สามารถแลกได้');
                }

                $address = CustomerAddress::where('id', $data['shipping_address_id'])
                    ->where('user_id', $user->id)
                    ->first();
                if (! $address) {
                    abort(422, 'ไม่พบที่อยู่จัดส่ง');
                }

                $quantity = (int) $data['quantity'];
                if ($product->stock < $quantity) {
                    abort(422, 'สินค้าหมด');
                }

                $pointsPerItem = (int) $product->points;
                $pointsTotal = $pointsPerItem * $quantity;

                $balance = $this->points->balance($user);
                if ($balance < $pointsTotal) {
                    abort(422, 'คะแนนไม่เพียงพอ');
                }

                $user->points_spent = (int) $user->points_spent + $pointsTotal;
                $user->save();

                $product->stock -= $quantity;
                $product->save();

                $redemption = RewardRedemption::create([
                    'user_id' => $user->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'points_per_item' => $pointsPerItem,
                    'points_total' => $pointsTotal,
                    'status' => RewardRedemption::STATUS_PENDING,
                    'shipping_address_id' => $address->id,
                    'notes' => $data['notes'] ?? null,
                ]);

                return [
                    'redemption' => $redemption,
                    'points_balance' => $this->points->balance($user->refresh()),
                ];
            });
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getStatusCode());
        }

        // TODO(reward): enqueue SendTelegramNotification to admin (match the
        // dispatch pattern used by FreeItemRedemptionController@redeem).

        return response()->json([
            'success' => true,
            'data' => $result['redemption'],
            'points_balance' => $result['points_balance'],
        ], 201);
    }

    /** GET /reward-redemptions — current user's history. */
    public function history()
    {
        $rows = RewardRedemption::where('user_id', Auth::id())
            ->with('product')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($r) => $this->presentRedemption($r));

        return response()->json(['success' => true, 'data' => $rows]);
    }

    /** GET /reward-redemptions/{id} */
    public function show($id)
    {
        $r = RewardRedemption::where('id', $id)
            ->where('user_id', Auth::id())
            ->with('product')
            ->first();

        if (! $r) {
            return response()->json(['success' => false, 'message' => 'ไม่พบรายการ'], 404);
        }

        return response()->json(['success' => true, 'data' => $this->presentRedemption($r)]);
    }

    private function presentRedemption(RewardRedemption $r): array
    {
        return [
            'id' => $r->id,
            'product_id' => $r->product_id,
            'product_name' => $r->product?->name,
            'quantity' => $r->quantity,
            'points_per_item' => $r->points_per_item,
            'points_total' => $r->points_total,
            'status' => $r->status,
            'status_label' => $r->status_label,
            'tracking_number' => $r->tracking_number,
            'created_at' => $r->created_at->format('Y-m-d H:i:s'),
        ];
    }
}
