<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
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
            'payment_method' => 'required|in:cash,transfer,credit_card,qr_code',
            'delivery_fee' => 'nullable|numeric|min:0',
            'discount' => 'nullable|numeric|min:0',
            'shipping_address_id' => 'nullable|exists:customer_addresses,id',
            'notes' => 'nullable|string|max:500'
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

            // Generate order number
            $orderNumber = 'ORD-' . date('Ymd') . '-' . str_pad(Order::whereDate('created_at', today())->count() + 1, 3, '0', STR_PAD_LEFT);

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
            
            $order = Order::with('orderItems.product')
                ->where('user_id', $user->id)
                ->findOrFail($id);

            // Can only cancel orders that haven't been paid yet
            if (!in_array($order->status, [Order::STATUS_PENDING_PAYMENT, Order::STATUS_PAYMENT_UPLOADED])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot cancel order. Order status is ' . $order->status
                ], 422);
            }

            DB::beginTransaction();

            // Only restore stock if it was already reduced (for paid orders)
            // For pending_payment orders, stock was never reduced, so no need to restore
            if ($order->isPaid()) {
                foreach ($order->orderItems as $item) {
                    $item->product->increment('stock', $item->quantity);
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
