<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\PaymentTransaction;
use App\Services\PaySolutionsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    protected $paymentService;

    public function __construct(PaySolutionsService $paymentService)
    {
        $this->paymentService = $paymentService;
    }

    /**
     * Create payment for an order
     */
    public function createPayment(Request $request)
    {
        // Log all request data for debugging
        Log::info('Payment create request received', [
            'all_data' => $request->all(),
            'input_data' => $request->input(),
            'raw_body' => $request->getContent(),
            'content_type' => $request->header('Content-Type'),
        ]);

        $validator = validator($request->all(), [
            'order_id' => 'required|exists:orders,id',
        ]);

        if ($validator->fails()) {
            Log::error('Payment validation failed', [
                'errors' => $validator->errors()->toArray(),
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $order = Order::with('user')->findOrFail($request->order_id);

            // Check if order belongs to authenticated user
            if ($order->user_id !== auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Access denied: This order does not belong to you',
                ], 403);
            }

            // Check if payment method is credit card
            if ($order->payment_method !== 'credit_card') {
                return response()->json([
                    'success' => false,
                    'message' => 'Payment gateway is only available for credit card payment method',
                    'payment_method' => $order->payment_method,
                ], 400);
            }

            // Check if order already has a successful payment
            $existingPayment = PaymentTransaction::where('order_id', $order->id)
                ->where('status', 'success')
                ->first();

            if ($existingPayment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order already paid',
                ], 400);
            }

            // Check if order can accept payment
            if (!$order->needsPayment()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order does not need payment or already paid',
                    'order_status' => $order->status,
                ], 400);
            }

            DB::beginTransaction();

            // Create payment transaction (force credit_card method)
            $payment = PaymentTransaction::create([
                'order_id' => $order->id,
                'payment_gateway' => 'paysolutions',
                'payment_method' => 'credit_card', // Always credit_card for gateway
                'amount' => $order->total_amount,
                'currency' => 'THB',
                'status' => 'pending',
                'expired_at' => now()->addMinutes((int) config('paysolutions.timeout', 30)),
            ]);

            // Generate payment URL
            $paymentUrl = $this->paymentService->generatePaymentUrl(
                $order->order_number,
                $order->total_amount,
                [
                    'customerName' => $order->user->name ?? '',
                    'customerEmail' => $order->user->email ?? '',
                    'productName' => 'Order #' . $order->order_number,
                ]
            );

            // Update payment with URL
            $payment->update(['payment_url' => $paymentUrl]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => [
                    'payment_id' => $payment->id,
                    'transaction_id' => $payment->transaction_id,
                    'payment_url' => $paymentUrl,
                    'amount' => $payment->amount,
                    'currency' => $payment->currency,
                    'expired_at' => $payment->expired_at,
                    'test_mode' => $this->paymentService->isTestMode(),
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Payment creation error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to create payment: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Handle payment callback from PaySolutions
     */
    public function handleCallback(Request $request)
    {
        Log::info('Payment callback received', $request->all());

        try {
            // Verify callback signature
            if (!$this->paymentService->isTestMode()) {
                if (!$this->paymentService->verifyCallback($request->all())) {
                    Log::error('Invalid payment callback signature');
                    return response()->json(['success' => false, 'message' => 'Invalid signature'], 400);
                }
            }

            $transactionId = $request->input('transaction_id') ?? $request->input('ref_no');
            $orderId = $request->input('order_id') ?? $request->input('ref_order');
            $status = $request->input('status');
            $amount = $request->input('amount');

            // Find payment transaction
            $payment = PaymentTransaction::where('transaction_id', $transactionId)
                ->orWhere(function ($query) use ($orderId) {
                    $query->whereHas('order', function ($q) use ($orderId) {
                        $q->where('order_number', $orderId);
                    });
                })
                ->first();

            if (!$payment) {
                Log::error('Payment transaction not found', ['transaction_id' => $transactionId]);
                return response()->json(['success' => false, 'message' => 'Transaction not found'], 404);
            }

            DB::beginTransaction();

            // Update payment status based on callback
            if ($status === 'success' || $status === '00') {
                $payment->markAsSuccess($request->all());

                // Update order status to 'paid' (will trigger stock reduction automatically)
                $order = $payment->order;
                $order->update([
                    'payment_status' => 'paid',
                    'status' => Order::STATUS_PAID, // This will trigger stock reduction in Order model
                ]);

                Log::info('Payment gateway successful - Order marked as paid', [
                    'payment_id' => $payment->id,
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                ]);

                // Send Telegram notification for payment success
                \App\Jobs\SendTelegramNotification::dispatch($order, 'payment_success');
            } else {
                $payment->markAsFailed($request->input('error_message', 'Payment failed'));
                Log::warning('Payment gateway failed', [
                    'payment_id' => $payment->id,
                    'order_id' => $payment->order_id,
                    'status' => $status
                ]);
            }

            DB::commit();

            return response()->json(['success' => true]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Payment callback error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json(['success' => false, 'message' => 'Callback processing failed'], 500);
        }
    }

    /**
     * Check payment status
     */
    public function checkStatus($paymentId)
    {
        try {
            $payment = PaymentTransaction::with('order')->findOrFail($paymentId);

            return response()->json([
                'success' => true,
                'data' => [
                    'payment_id' => $payment->id,
                    'transaction_id' => $payment->transaction_id,
                    'status' => $payment->status,
                    'amount' => $payment->amount,
                    'currency' => $payment->currency,
                    'payment_method' => $payment->payment_method,
                    'paid_at' => $payment->paid_at,
                    'order' => [
                        'id' => $payment->order->id,
                        'order_number' => $payment->order->order_number,
                        'status' => $payment->order->status,
                    ],
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Payment not found',
            ], 404);
        }
    }

    /**
     * Test mode payment page
     */
    public function testPaymentPage($orderId)
    {
        if (!$this->paymentService->isTestMode()) {
            abort(404);
        }

        // Extract order_id and amount from query parameters
        $amount = request()->query('amount');

        return view('payment.test', [
            'orderId' => $orderId,
            'amount' => $amount,
            'callbackUrl' => config('paysolutions.callback_url'),
        ]);
    }

    /**
     * Test mode payment simulation
     */
    public function simulatePayment(Request $request)
    {
        if (!$this->paymentService->isTestMode()) {
            abort(404);
        }

        Log::info('Payment simulate request received', [
            'all_data' => $request->all(),
            'order_id' => $request->order_id,
            'status' => $request->status,
            'amount' => $request->amount,
        ]);

        try {
            $validator = validator($request->all(), [
                'order_id' => 'required|string',
                'status' => 'required|in:success,failed',
                'amount' => 'nullable|numeric',
            ]);

            if ($validator->fails()) {
                Log::error('Payment simulate validation failed', [
                    'errors' => $validator->errors()->toArray(),
                    'request_data' => $request->all(),
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            // Simulate callback
            $callbackData = [
                'transaction_id' => 'TEST_' . uniqid(),
                'order_id' => $request->order_id,
                'status' => $request->status,
                'amount' => $request->amount ?? 0,
                'paid_at' => now()->toDateTimeString(),
            ];

            Log::info('Simulating payment callback', $callbackData);

            // Call the callback handler
            return $this->handleCallback(new Request($callbackData));

        } catch (\Exception $e) {
            Log::error('Payment simulate error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Simulation failed: ' . $e->getMessage(),
            ], 500);
        }
    }
}
