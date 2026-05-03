<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Models\PaymentSlip;
use App\Models\Order;
use App\Jobs\SendTelegramNotification;

class PaymentSlipController extends Controller
{
    /**
     * Upload payment slips for an order (replaces existing slips)
     */
    public function uploadSlips(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|exists:orders,id',
            'files.*' => 'required|file|mimes:jpeg,jpg,png,pdf|max:5120', // 5MB max per file
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $orderId = $request->order_id;
        
        // Check if order belongs to authenticated user
        $order = Order::where('id', $orderId)->where('user_id', auth()->id())->first();
        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found or access denied'
            ], 403);
        }

        // Check if order can accept payment slips
        if (!$order->needsPayment()) {
            return response()->json([
                'success' => false,
                'message' => 'Order does not need payment or already paid'
            ], 422);
        }

        $files = $request->file('files', []);
        
        // Validate file count (max 5)
        if (count($files) > 5) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot upload more than 5 payment slips per order'
            ], 422);
        }

        // Save the new slips first; only after all of them land successfully
        // do we delete the old ones. Reverses the previous "delete first then
        // upload" order, which lost the user's approved slip if the new
        // upload failed (disk full, transient error, etc.).
        $uploadedSlips = [];
        $newPaths = [];

        foreach ($files as $index => $file) {
            try {
                $extension = $file->getClientOriginalExtension();
                // Include uniqid so two uploads in the same second produce
                // distinct filenames; otherwise the new file silently
                // overwrites the old, and our "delete old" sweep then
                // deletes the file we just wrote.
                $filename = 'slip_' . $orderId . '_' . time() . '_' . uniqid() . '_' . ($index + 1) . '.' . $extension;
                $path = $file->storeAs('payment_slips', $filename, 'public');
                $newPaths[] = $path;

                $slip = PaymentSlip::create([
                    'order_id' => $orderId,
                    'file_name' => $filename,
                    'file_path' => $path,
                    'original_name' => $file->getClientOriginalName(),
                    'file_size' => $file->getSize(),
                    'mime_type' => $file->getMimeType(),
                    'status' => 'pending'
                ]);

                $uploadedSlips[] = $slip;
            } catch (\Exception $e) {
                \Log::error('Payment slip upload error: ' . $e->getMessage());
                // Roll back any new files we managed to write so the order
                // doesn't end up with half-saved replacements alongside the
                // (still untouched) originals.
                foreach ($newPaths as $p) {
                    if (Storage::disk('public')->exists($p)) {
                        Storage::disk('public')->delete($p);
                    }
                }
                foreach ($uploadedSlips as $s) {
                    $s->delete();
                }

                return response()->json([
                    'success' => false,
                    'message' => 'อัปโหลดสลิปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
                ], 500);
            }
        }

        // All new slips persisted; safe to delete the old ones.
        $existingSlips = PaymentSlip::where('order_id', $orderId)
            ->whereNotIn('id', collect($uploadedSlips)->pluck('id')->all())
            ->get();
        foreach ($existingSlips as $slip) {
            if (Storage::disk('public')->exists($slip->file_path)) {
                Storage::disk('public')->delete($slip->file_path);
            }
            $slip->delete();
        }

        // Update order status and payment slip status
        $order->update([
            'status' => Order::STATUS_PAYMENT_UPLOADED,
            'payment_slip_status' => 'uploaded'
        ]);

        // Send Telegram notification for payment slip upload
        SendTelegramNotification::dispatch($order, 'payment_slip');

        return response()->json([
            'success' => true,
            'message' => 'Payment slips uploaded successfully',
            'data' => $uploadedSlips,
            'uploaded_count' => count($uploadedSlips),
            'order_status' => $order->status,
            'order_status_display' => $order->status_display
        ]);
    }

    /**
     * Get payment slips for an order
     */
    public function getSlips(Request $request, $orderId)
    {
        $order = Order::where('id', $orderId)->where('user_id', auth()->id())->first();
        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found or access denied'
            ], 403);
        }

        $slips = PaymentSlip::where('order_id', $orderId)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($slip) {
                return [
                    'id' => $slip->id,
                    'file_name' => $slip->file_name,
                    'original_name' => $slip->original_name,
                    'file_size' => $slip->file_size,
                    'status' => $slip->status,
                    'url' => Storage::url($slip->file_path),
                    'uploaded_at' => $slip->created_at->format('Y-m-d H:i:s')
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $slips
        ]);
    }

    /**
     * Delete a payment slip
     */
    public function deleteSlip(Request $request, $slipId)
    {
        $slip = PaymentSlip::find($slipId);
        if (!$slip) {
            return response()->json([
                'success' => false,
                'message' => 'Payment slip not found'
            ], 404);
        }

        // Check if the slip belongs to the authenticated user's order
        $order = Order::where('id', $slip->order_id)->where('user_id', auth()->id())->first();
        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Access denied'
            ], 403);
        }

        // Delete file from storage
        if (Storage::disk('public')->exists($slip->file_path)) {
            Storage::disk('public')->delete($slip->file_path);
        }

        // Delete database record
        $slip->delete();

        return response()->json([
            'success' => true,
            'message' => 'Payment slip deleted successfully'
        ]);
    }

    // Admin endpoints (adminIndex, adminUpdateStatus) live in
    // App\Http\Controllers\Admin\PaymentSlipController so they cannot be
    // wired up by accident on a route that lacks the admin middleware.
}