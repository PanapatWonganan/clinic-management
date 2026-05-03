<?php

namespace App\Http\Controllers;

use App\Models\FreeItemRedemption;
use App\Models\UserClaimedReward;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class FreeItemRedemptionController extends Controller
{
    /**
     * แสดงสิทธิ์ของแถมทั้งหมดของ user
     */
    public function myRewards()
    {
        try {
            $user = Auth::user();

            $rewards = UserClaimedReward::where('user_id', $user->id)
                ->where('status', 'approved')
                ->where('earned_free_items', '>', 0)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($reward) {
                    $remaining = $reward->earned_free_items - $reward->redeemed_free_items;
                    return [
                        'id' => $reward->id,
                        'level' => $reward->level,
                        'earned_free_items' => $reward->earned_free_items,
                        'redeemed_free_items' => $reward->redeemed_free_items,
                        'remaining_free_items' => $remaining,
                        'required_quantity' => $reward->required_quantity,
                        'created_at' => $reward->created_at->format('Y-m-d H:i:s'),
                        'order_id' => $reward->order_id,
                        'can_redeem' => $remaining > 0,
                    ];
                });

            // คำนวณยอดรวม
            $totalEarned = $rewards->sum('earned_free_items');
            $totalRedeemed = $rewards->sum('redeemed_free_items');
            $totalRemaining = $rewards->sum('remaining_free_items');

            return response()->json([
                'success' => true,
                'data' => [
                    'rewards' => $rewards,
                    'summary' => [
                        'total_earned' => $totalEarned,
                        'total_redeemed' => $totalRedeemed,
                        'total_remaining' => $totalRemaining,
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching rewards: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * ดูรายละเอียดสิทธิ์ของแถม
     */
    public function showReward($id)
    {
        try {
            $user = Auth::user();

            $reward = UserClaimedReward::where('user_id', $user->id)
                ->where('id', $id)
                ->firstOrFail();

            $remaining = $reward->earned_free_items - $reward->redeemed_free_items;

            // ดึงประวัติการแลก
            $redemptions = FreeItemRedemption::where('claimed_reward_id', $id)
                ->with('product')
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($r) {
                    return [
                        'id' => $r->id,
                        'product_name' => $r->product->name ?? 'Unknown',
                        'product_image' => $r->product->image ?? null,
                        'quantity' => $r->quantity,
                        'status' => $r->status,
                        'status_label' => $r->status_label,
                        'tracking_number' => $r->tracking_number,
                        'created_at' => $r->created_at->format('Y-m-d H:i:s'),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => [
                    'reward' => [
                        'id' => $reward->id,
                        'level' => $reward->level,
                        'earned_free_items' => $reward->earned_free_items,
                        'redeemed_free_items' => $reward->redeemed_free_items,
                        'remaining_free_items' => $remaining,
                        'can_redeem' => $remaining > 0,
                    ],
                    'redemptions' => $redemptions,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reward not found'
            ], 404);
        }
    }

    /**
     * แลกของแถม (รองรับทั้ง single reward และ combined FIFO)
     */
    public function redeem(Request $request)
    {
        // Validate items first
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'shipping_address_id' => 'nullable|exists:customer_addresses,id',
            'notes' => 'nullable|string|max:500',
            'is_combined' => 'nullable|boolean',
            'reward_ids' => 'nullable|array',
            'claimed_reward_id' => 'nullable|exists:user_claimed_rewards,id',
            'delivery_fee' => 'nullable|numeric|min:0',
            'delivery_method' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            $user = Auth::user();
            $isCombined = $request->is_combined ?? false;
            $totalQuantity = collect($request->items)->sum('quantity');

            // ถ้าไม่มี shipping_address_id ให้ใช้ default address
            $shippingAddressId = $request->shipping_address_id;
            if (!$shippingAddressId) {
                $defaultAddress = $user->getDefaultAddress();
                if ($defaultAddress) {
                    $shippingAddressId = $defaultAddress->id;
                }
            }

            $redemptions = [];
            $remainingToRedeem = $totalQuantity;

            if ($isCombined) {
                // Combined mode: ใช้ FIFO หักจาก rewards เก่าสุดก่อน
                $rewards = UserClaimedReward::where('user_id', $user->id)
                    ->where('status', 'approved')
                    ->whereRaw('earned_free_items > redeemed_free_items')
                    ->orderBy('created_at', 'asc') // FIFO - เก่าสุดก่อน
                    ->get();

                // คำนวณยอดรวมที่เหลือ
                $totalRemaining = $rewards->sum(function ($r) {
                    return $r->earned_free_items - $r->redeemed_free_items;
                });

                if ($totalQuantity > $totalRemaining) {
                    return response()->json([
                        'success' => false,
                        'message' => "จำนวนที่ต้องการแลก ($totalQuantity) มากกว่าจำนวนที่เหลือ ($totalRemaining)"
                    ], 422);
                }

                // สร้าง redemption records และหัก stock
                foreach ($request->items as $item) {
                    $product = Product::find($item['product_id']);
                    if ($product) {
                        if (!\App\Services\StockService::tryDecrement($product->id, (int) $item['quantity'])) {
                            throw new \Exception("สินค้า {$product->name} มี stock ไม่เพียงพอ (เหลือ {$product->fresh()->stock} ชิ้น)");
                        }
                    }

                    // หาว่าจะหักจาก reward ไหน (FIFO)
                    $itemQtyRemaining = $item['quantity'];
                    foreach ($rewards as $reward) {
                        if ($itemQtyRemaining <= 0) break;

                        $rewardRemaining = $reward->earned_free_items - $reward->redeemed_free_items;
                        if ($rewardRemaining <= 0) continue;

                        $qtyToDeduct = min($itemQtyRemaining, $rewardRemaining);

                        $redemption = FreeItemRedemption::create([
                            'user_id' => $user->id,
                            'claimed_reward_id' => $reward->id,
                            'product_id' => $item['product_id'],
                            'quantity' => $qtyToDeduct,
                            'status' => FreeItemRedemption::STATUS_PENDING,
                            'shipping_address_id' => $shippingAddressId,
                            'notes' => $request->notes,
                        ]);
                        $redemptions[] = $redemption;

                        // อัพเดท redeemed_free_items
                        $reward->increment('redeemed_free_items', $qtyToDeduct);
                        $itemQtyRemaining -= $qtyToDeduct;
                    }
                }
            } else {
                // Single reward mode - รองรับทั้ง claimed_reward_id และ reward_level
                $reward = null;

                if ($request->claimed_reward_id) {
                    // ใช้ claimed_reward_id ที่มีอยู่แล้ว
                    $reward = UserClaimedReward::where('id', $request->claimed_reward_id)
                        ->where('user_id', $user->id)
                        ->where('status', 'approved')
                        ->first();
                }

                // ถ้าไม่มี claimed_reward_id หรือหาไม่เจอ ให้ลองใช้ reward_level
                if (!$reward && $request->reward_level) {
                    // หา claimed_reward ที่มีอยู่แล้วสำหรับ level นี้
                    $reward = UserClaimedReward::where('user_id', $user->id)
                        ->where('level', $request->reward_level)
                        ->where('status', 'approved')
                        ->whereRaw('earned_free_items > redeemed_free_items')
                        ->first();

                    // ถ้ายังไม่มี ให้สร้างใหม่และ auto-approve
                    if (!$reward) {
                        // ดึงข้อมูล membership progress เพื่อหา free_items ที่ได้
                        $membershipService = app(\App\Services\MembershipProgressService::class);
                        $progress = $membershipService->getMembershipProgress($user);

                        $levelData = collect($progress['available_rewards'] ?? [])->firstWhere('level', $request->reward_level);

                        if (!$levelData) {
                            return response()->json([
                                'success' => false,
                                'message' => "ไม่พบสิทธิ์สำหรับ Level {$request->reward_level}"
                            ], 422);
                        }

                        // สร้าง claimed_reward ใหม่และ auto-approve
                        $reward = UserClaimedReward::create([
                            'user_id' => $user->id,
                            'level' => $request->reward_level,
                            'reward_type' => 'free_items',
                            'required_quantity' => $levelData['required_quantity'] ?? 0,
                            'earned_free_items' => $levelData['earned_free_items'] ?? 0,
                            'redeemed_free_items' => 0,
                            'savings_amount' => $levelData['savings_amount'] ?? 0,
                            'unit_price' => $levelData['unit_price'] ?? 0,
                            'status' => 'approved', // Auto-approve!
                            'approved_at' => now(),
                        ]);
                    }
                }

                if (!$reward) {
                    return response()->json([
                        'success' => false,
                        'message' => 'claimed_reward_id หรือ reward_level is required for single reward redemption'
                    ], 422);
                }

                $remaining = $reward->earned_free_items - $reward->redeemed_free_items;

                if ($totalQuantity > $remaining) {
                    return response()->json([
                        'success' => false,
                        'message' => "จำนวนที่ต้องการแลก ($totalQuantity) มากกว่าจำนวนที่เหลือ ($remaining)"
                    ], 422);
                }

                foreach ($request->items as $item) {
                    $product = Product::find($item['product_id']);
                    if ($product) {
                        if (!\App\Services\StockService::tryDecrement($product->id, (int) $item['quantity'])) {
                            throw new \Exception("สินค้า {$product->name} มี stock ไม่เพียงพอ (เหลือ {$product->fresh()->stock} ชิ้น)");
                        }
                    }

                    $redemption = FreeItemRedemption::create([
                        'user_id' => $user->id,
                        'claimed_reward_id' => $reward->id,
                        'product_id' => $item['product_id'],
                        'quantity' => $item['quantity'],
                        'status' => FreeItemRedemption::STATUS_PENDING,
                        'shipping_address_id' => $shippingAddressId,
                        'notes' => $request->notes,
                    ]);
                    $redemptions[] = $redemption;
                }

                $reward->increment('redeemed_free_items', $totalQuantity);
            }

            // สร้าง Order สำหรับค่าขนส่ง (สินค้าราคา 0 บาท)
            $deliveryFee = $request->delivery_fee ?? 0;
            // delivery_method ใน orders table เป็น enum('pickup','delivery')
            // เก็บ method จริง (grab, kerry, etc.) ไว้ใน notes แทน
            $deliveryMethod = 'delivery'; // ใช้ delivery เสมอสำหรับแลกของแถม
            $deliveryMethodDetail = $request->delivery_method ?? 'delivery';

            // Generate order number — collision-resistant; the previous
            // count()+1 approach raced and could even collide across the
            // ORD/FREE prefix families.
            $orderNumber = \App\Services\OrderNumberService::generate('FREE');

            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $user->id,
                'shipping_address_id' => $shippingAddressId,
                'subtotal' => 0, // ของแถมราคา 0
                'delivery_fee' => $deliveryFee,
                'discount' => 0,
                'total_amount' => $deliveryFee, // จ่ายแค่ค่าขนส่ง
                'status' => $deliveryFee > 0 ? Order::STATUS_PENDING_PAYMENT : 'confirmed', // ถ้ามีค่าขนส่ง ต้องจ่ายก่อน
                'delivery_method' => $deliveryMethod,
                'payment_method' => 'transfer',
                'payment_status' => $deliveryFee > 0 ? 'pending' : 'paid',
                'payment_slip_status' => $deliveryFee > 0 ? 'none' : 'approved',
                'notes' => $request->notes ? $request->notes . " | ขนส่ง: $deliveryMethodDetail" : "ขนส่ง: $deliveryMethodDetail",
                'is_free_item_order' => true, // flag บอกว่าเป็น order ของแถม
            ]);

            // สร้าง OrderItems (ราคา 0 บาท)
            foreach ($request->items as $item) {
                $product = Product::find($item['product_id']);
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'],
                    'quantity' => $item['quantity'],
                    'unit_price' => 0, // ของแถมราคา 0
                    'total_price' => 0,
                ]);
            }

            // อัพเดท redemptions ให้เชื่อมกับ order
            foreach ($redemptions as $redemption) {
                $redemption->update(['order_id' => $order->id]);
            }

            DB::commit();

            $message = $deliveryFee > 0
                ? 'แลกของแถมสำเร็จ กรุณาชำระค่าขนส่งและอัปโหลดสลิป'
                : 'แลกของแถมสำเร็จ รอการจัดส่ง';

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'delivery_fee' => $deliveryFee,
                    'requires_payment' => $deliveryFee > 0,
                    'redemptions' => collect($redemptions)->map(function ($r) {
                        return [
                            'id' => $r->id,
                            'product_id' => $r->product_id,
                            'quantity' => $r->quantity,
                            'status' => $r->status,
                        ];
                    }),
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Error redeeming items: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * ดูประวัติการแลกของแถม
     */
    public function redemptionHistory()
    {
        try {
            $user = Auth::user();

            $redemptions = FreeItemRedemption::where('user_id', $user->id)
                ->with(['product', 'claimedReward', 'shippingAddress'])
                ->orderBy('created_at', 'desc')
                ->paginate(20);

            $data = $redemptions->map(function ($r) {
                return [
                    'id' => $r->id,
                    'product' => [
                        'id' => $r->product->id ?? null,
                        'name' => $r->product->name ?? 'Unknown',
                        'image' => $r->product->image ?? null,
                    ],
                    'quantity' => $r->quantity,
                    'status' => $r->status,
                    'status_label' => $r->status_label,
                    'tracking_number' => $r->tracking_number,
                    'shipping_address' => $r->shippingAddress ? [
                        'name' => $r->shippingAddress->name,
                        'address' => $r->shippingAddress->full_address ?? $r->shippingAddress->address,
                    ] : null,
                    'from_reward_level' => $r->claimedReward->level ?? null,
                    'created_at' => $r->created_at->format('Y-m-d H:i:s'),
                    'approved_at' => $r->approved_at?->format('Y-m-d H:i:s'),
                    'shipped_at' => $r->shipped_at?->format('Y-m-d H:i:s'),
                    'delivered_at' => $r->delivered_at?->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $redemptions->currentPage(),
                    'last_page' => $redemptions->lastPage(),
                    'per_page' => $redemptions->perPage(),
                    'total' => $redemptions->total(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching history: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * ดึงรายการสินค้าที่สามารถแลกได้
     */
    public function availableProducts()
    {
        try {
            $products = Product::where('is_active', true)
                ->where('stock', '>', 0)
                ->select('id', 'name', 'image_url as image', 'description', 'stock')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $products
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching products: ' . $e->getMessage()
            ], 500);
        }
    }
}
