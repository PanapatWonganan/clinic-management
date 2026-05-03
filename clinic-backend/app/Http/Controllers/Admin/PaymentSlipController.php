<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PaymentSlip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class PaymentSlipController extends Controller
{
    /**
     * Admin: list payment slips with optional status / order_id filtering.
     *
     * Moved out of the customer-facing PaymentSlipController so a route
     * misconfiguration cannot accidentally expose status updates without
     * the admin middleware. The web.php registration must still go
     * through the admin guard.
     */
    public function adminIndex(Request $request)
    {
        $query = PaymentSlip::with(['order.user'])
            ->orderBy('created_at', 'desc');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('order_id')) {
            $query->where('order_id', $request->order_id);
        }

        $slips = $query->paginate(20);

        $slips->getCollection()->transform(function ($slip) {
            return [
                'id' => $slip->id,
                'order_id' => $slip->order_id,
                'order_number' => $slip->order->order_number ?? 'N/A',
                'customer_name' => $slip->order->user->name ?? 'N/A',
                'customer_email' => $slip->order->user->email ?? 'N/A',
                'file_name' => $slip->file_name,
                'original_name' => $slip->original_name,
                'file_size' => $slip->file_size,
                'status' => $slip->status,
                'url' => Storage::url($slip->file_path),
                'uploaded_at' => $slip->created_at->format('Y-m-d H:i:s'),
                'reviewed_at' => $slip->reviewed_at ? $slip->reviewed_at->format('Y-m-d H:i:s') : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $slips,
        ]);
    }

    public function adminUpdateStatus(Request $request, $slipId)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,approved,rejected',
            'admin_notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $slip = PaymentSlip::find($slipId);
        if (! $slip) {
            return response()->json([
                'success' => false,
                'message' => 'Payment slip not found',
            ], 404);
        }

        $slip->update([
            'status' => $request->status,
            'admin_notes' => $request->admin_notes,
            'reviewed_at' => now(),
            'reviewed_by' => auth()->id(),
        ]);

        if ($request->status === 'approved') {
            $order = Order::find($slip->order_id);
            if ($order) {
                $order->update([
                    'status' => Order::STATUS_PAID,
                    'payment_status' => 'paid',
                    'payment_slip_status' => 'approved',
                ]);
                \Log::info("Order {$order->id} payment approved and stock will be reduced automatically");
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Payment slip status updated successfully',
            'data' => $slip,
        ]);
    }
}
