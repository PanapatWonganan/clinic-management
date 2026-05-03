<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\UserClaimedReward;
use App\Models\FreeItemRedemption;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use App\Jobs\SendTelegramNotification;

class OrderController extends Controller
{
    /**
     * Display a listing of orders for the authenticated user.
     */
    public function index(Request $request)
    {
        try {
            $user = Auth::user();
            
            $orders = Order::with(['orderItems.product', 'deliveryProof'])
                ->where('user_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->paginate(10);
            
            return response()->json([
                'success' => true,
                'data' => $orders,
                'message' => 'Orders retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving orders: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created order.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'delivery_method' => 'required|in:pickup,delivery',
            // qr_code is intentionally excluded — there is no downstream
            // handler for it (createPayment only accepts credit_card; the
            // slip upload flow accepts cash/transfer/promptpay). Allowing
            // qr_code here would let an order get stuck in pending_payment
            // forever. promptpay is the supported QR payment method.
            'payment_method' => 'required|in:cash,transfer,credit_card,promptpay',
            'delivery_fee' => 'nullable|numeric|min:0',
            'discount' => 'nullable|numeric|min:0',
            'shipping_address_id' => 'nullable|exists:customer_addresses,id',
            'notes' => 'nullable|string|max:500',
            // Reward claim fields
            'reward_level' => 'nullable|integer|min:1',
            'reward_discount' => 'nullable|numeric|min:0',
            'reward_free_items' => 'nullable|integer|min:0',
            'reward_required_quantity' => 'nullable|integer|min:0',
            // ของแถมที่เลือกเพิ่มใน order (จากสิทธิ์ที่มีอยู่)
            'selected_free_items' => 'nullable|array',
            'selected_free_items.*.product_id' => 'required_with:selected_free_items|exists:products,id',
            'selected_free_items.*.quantity' => 'required_with:selected_free_items|integer|min:1',
            // ของแถมที่เลือกจาก reward ใหม่ในออเดอร์นี้ (ยังไม่มีสิทธิ์ใน DB — จะ claim พร้อม order)
            // Why: สิทธิ์เก่า (selected_free_items) ถูก validate กับ user_claimed_rewards เดิม
            // ของแถมจาก reward ใหม่ต้องแยก key เพื่อไม่ชน validation ของเก่า
            'new_order_free_items' => 'nullable|array',
            'new_order_free_items.*.product_id' => 'required_with:new_order_free_items|exists:products,id',
            'new_order_free_items.*.quantity' => 'required_with:new_order_free_items|integer|min:1',
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
            $totalAmount = 0;
            $orderItems = [];

            // Handle shipping address
            $shippingAddressId = $request->shipping_address_id;
            
            // If no shipping address provided, use user's default address
            if (!$shippingAddressId && $request->delivery_method === 'delivery') {
                $defaultAddress = $user->getDefaultAddress();
                if (!$defaultAddress) {
                    return response()->json([
                        'success' => false,
                        'message' => 'ไม่พบที่อยู่สำหรับจัดส่ง กรุณาเพิ่มที่อยู่ก่อน'
                    ], 422);
                }
                $shippingAddressId = $defaultAddress->id;
            }

            // Validate shipping address belongs to user
            if ($shippingAddressId) {
                $address = $user->customerAddresses()->find($shippingAddressId);
                if (!$address) {
                    return response()->json([
                        'success' => false,
                        'message' => 'ที่อยู่จัดส่งไม่ถูกต้อง'
                    ], 422);
                }
            }

            // Calculate subtotal and prepare order items
            $subtotal = 0;
            foreach ($request->items as $item) {
                $product = Product::findOrFail($item['product_id']);

                // Check stock availability (still validate, but don't reduce yet)
                if ($product->stock < $item['quantity']) {
                    return response()->json([
                        'success' => false,
                        'message' => "สินค้า {$product->name} มีสต็อกไม่เพียงพอ (เหลือ {$product->stock} ชิ้น)"
                    ], 422);
                }

                $unitPrice = $product->price;
                $totalPrice = $unitPrice * $item['quantity'];
                $subtotal += $totalPrice;

                $orderItems[] = [
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'unit_price' => $unitPrice,
                    'total_price' => $totalPrice,
                    'product' => $product // For reference
                ];
            }

            // Get delivery fee and discount
            $deliveryFee = $request->delivery_fee ?? 0;
            $discount = $request->discount ?? 0;

            // Calculate total amount
            $totalAmount = $subtotal + $deliveryFee - $discount;

            // Generate order number — uses ULID-derived suffix to avoid the
            // count()+1 race that lets concurrent requests build identical numbers.
            $orderNumber = \App\Services\OrderNumberService::generate('ORD');

            // Create order with pending_payment status (Payment-First Flow)
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $user->id,
                'shipping_address_id' => $shippingAddressId,
                'subtotal' => $subtotal,
                'delivery_fee' => $deliveryFee,
                'discount' => $discount,
                'total_amount' => $totalAmount,
                'status' => Order::STATUS_PENDING_PAYMENT, // Don't reduce stock yet
                'delivery_method' => $request->delivery_method,
                'payment_method' => $request->payment_method,
                'payment_status' => 'pending',
                'payment_slip_status' => 'none',
                'notes' => $request->notes
            ]);

            // Create order items (but DON'T reduce stock yet - wait for payment)
            foreach ($orderItems as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'total_price' => $item['total_price']
                ]);

                // NOTE: Stock will be reduced when order status changes to 'paid'
                // This happens automatically via Order model's booted() method
            }

            // บันทึก reward claim ถ้ามีการแลกรางวัล
            if ($request->reward_level) {
                // คำนวณ total quantity ที่ซื้อ
                $totalQuantity = collect($request->items)->sum('quantity');

                UserClaimedReward::create([
                    'user_id' => $user->id,
                    'order_id' => $order->id,
                    'level' => $request->reward_level,
                    'required_quantity' => $request->reward_required_quantity ?? $totalQuantity,
                    'earned_free_items' => $request->reward_free_items ?? 0,
                    'unit_price' => 2500, // ราคาต่อชิ้นคงที่
                    'savings_amount' => $request->reward_discount ?? 0,
                    'reward_type' => 'bundle_deal', // ประเภทรางวัล
                    'status' => 'approved', // อนุมัติทันทีเมื่อทำ order
                ]);

                \Log::info('Reward claimed for order', [
                    'order_id' => $order->id,
                    'user_id' => $user->id,
                    'level' => $request->reward_level,
                    'free_items' => $request->reward_free_items,
                    'discount' => $request->reward_discount,
                ]);
            }

            // ประมวลผลของแถมที่เลือกเพิ่มใน order (จากสิทธิ์ที่มีอยู่)
            if ($request->selected_free_items && count($request->selected_free_items) > 0) {
                $totalFreeItemsQuantity = collect($request->selected_free_items)->sum('quantity');

                // ตรวจสอบว่ามีสิทธิ์เพียงพอ (FIFO)
                $rewards = UserClaimedReward::where('user_id', $user->id)
                    ->where('status', 'approved')
                    ->whereRaw('earned_free_items > redeemed_free_items')
                    ->orderBy('created_at', 'asc')
                    ->get();

                $totalRemaining = $rewards->sum(function ($r) {
                    return $r->earned_free_items - $r->redeemed_free_items;
                });

                if ($totalFreeItemsQuantity > $totalRemaining) {
                    throw new \Exception("สิทธิ์ของแถมไม่เพียงพอ (ต้องการ $totalFreeItemsQuantity, มี $totalRemaining)");
                }

                // สร้าง FreeItemRedemption records (FIFO)
                foreach ($request->selected_free_items as $freeItem) {
                    $product = Product::find($freeItem['product_id']);
                    if (!$product) continue;

                    // Atomic decrement — rejects if another concurrent request
                    // already consumed the row.
                    if (!\App\Services\StockService::tryDecrement($product->id, (int) $freeItem['quantity'])) {
                        throw new \Exception("สินค้าของแถม {$product->name} มี stock ไม่เพียงพอ");
                    }

                    // หักจาก rewards ตาม FIFO
                    $itemQtyRemaining = $freeItem['quantity'];
                    foreach ($rewards as $reward) {
                        if ($itemQtyRemaining <= 0) break;

                        $rewardRemaining = $reward->earned_free_items - $reward->redeemed_free_items;
                        if ($rewardRemaining <= 0) continue;

                        $qtyToDeduct = min($itemQtyRemaining, $rewardRemaining);

                        FreeItemRedemption::create([
                            'user_id' => $user->id,
                            'claimed_reward_id' => $reward->id,
                            'product_id' => $freeItem['product_id'],
                            'quantity' => $qtyToDeduct,
                            'status' => FreeItemRedemption::STATUS_APPROVED, // อนุมัติทันทีเพราะส่งพร้อม order
                            'shipping_address_id' => $shippingAddressId,
                            'notes' => "ส่งพร้อม Order #{$order->order_number}",
                            'order_id' => $order->id, // เชื่อมกับ order
                            'approved_at' => now(),
                        ]);

                        $reward->increment('redeemed_free_items', $qtyToDeduct);
                        $itemQtyRemaining -= $qtyToDeduct;
                    }
                }

                \Log::info('Free items added to order', [
                    'order_id' => $order->id,
                    'free_items' => $request->selected_free_items,
                    'total_quantity' => $totalFreeItemsQuantity,
                ]);
            }

            // ประมวลผลของแถมจาก reward ใหม่ที่เพิ่งเกิดในออเดอร์นี้
            // (แยกจาก selected_free_items เพราะสิทธิ์เพิ่งสร้างในทรานแซคชันนี้ — validate ต่างกัน)
            if ($request->new_order_free_items && count($request->new_order_free_items) > 0) {
                $newRewardQuota = (int) ($request->reward_free_items ?? 0);
                $newOrderTotalQty = collect($request->new_order_free_items)->sum('quantity');

                if ($newRewardQuota <= 0) {
                    throw new \Exception('ออเดอร์นี้ยังไม่ได้แลก reward — ไม่สามารถเลือกของแถมได้');
                }
                if ($newOrderTotalQty > $newRewardQuota) {
                    throw new \Exception("เลือกของแถมเกินสิทธิ์ที่ออเดอร์นี้ได้รับ (ต้องการ $newOrderTotalQty, ได้ $newRewardQuota)");
                }

                // reward record เพิ่งถูกสร้างในบล็อก if ($request->reward_level) ก่อนหน้านี้
                $newReward = UserClaimedReward::where('user_id', $user->id)
                    ->where('order_id', $order->id)
                    ->latest('id')
                    ->first();

                if (!$newReward) {
                    throw new \Exception('ไม่พบ reward ของออเดอร์นี้');
                }

                foreach ($request->new_order_free_items as $freeItem) {
                    $product = Product::find($freeItem['product_id']);
                    if (!$product) continue;

                    if (!\App\Services\StockService::tryDecrement($product->id, (int) $freeItem['quantity'])) {
                        throw new \Exception("สินค้าของแถม {$product->name} มี stock ไม่เพียงพอ");
                    }

                    FreeItemRedemption::create([
                        'user_id' => $user->id,
                        'claimed_reward_id' => $newReward->id,
                        'product_id' => $freeItem['product_id'],
                        'quantity' => $freeItem['quantity'],
                        'status' => FreeItemRedemption::STATUS_APPROVED,
                        'shipping_address_id' => $shippingAddressId,
                        'notes' => "ของแถมจากออเดอร์ #{$order->order_number}",
                        'order_id' => $order->id,
                        'approved_at' => now(),
                    ]);

                    $newReward->increment('redeemed_free_items', $freeItem['quantity']);
                }

                \Log::info('New-order free items claimed', [
                    'order_id' => $order->id,
                    'reward_id' => $newReward->id,
                    'items' => $request->new_order_free_items,
                    'total_quantity' => $newOrderTotalQty,
                ]);
            }

            DB::commit();

            // Send Telegram notification (async)
            SendTelegramNotification::dispatch($order, 'new_order');

            // Load order with relationships for response
            $order->load(['orderItems.product']);

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order created successfully'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Error creating order: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified order.
     */
    public function show($id)
    {
        try {
            $user = Auth::user();
            
            $order = Order::with(['orderItems.product', 'deliveryProof'])
                ->where('user_id', $user->id)
                ->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $order
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found'
            ], 404);
        }
    }

    /**
     * Cancel an order (only if status is pending).
     */
    public function cancel($id)
    {
        try {
            $user = Auth::user();

            DB::beginTransaction();

            // Lock the order row so that a concurrent payment callback that's
            // about to flip the same order to "paid" has to wait until our
            // status update commits. With the race guard in PaymentController
            // it will then see status=cancelled and bail out instead of
            // silently decrementing stock.
            $order = Order::with('orderItems.product')
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->findOrFail($id);

            // Can only cancel orders that haven't been paid yet
            if (!in_array($order->status, [Order::STATUS_PENDING_PAYMENT, Order::STATUS_PAYMENT_UPLOADED])) {
                DB::rollBack();

                return response()->json([
                    'success' => false,
                    'message' => 'Cannot cancel order. Order status is ' . $order->status
                ], 422);
            }

            // Only restore stock if it was already reduced (for paid orders)
            // For pending_payment orders, stock was never reduced, so no need to restore
            if ($order->isPaid()) {
                foreach ($order->orderItems as $item) {
                    \App\Services\StockService::increment((int) $item->product_id, (int) $item->quantity);
                }
            }

            // Update order status
            $order->update(['status' => 'cancelled']);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order cancelled successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Error cancelling order: ' . $e->getMessage()
            ], 500);
        }
    }
}
