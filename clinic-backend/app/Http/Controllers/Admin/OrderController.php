<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DeliveryProof;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['user', 'orderItems.product', 'paymentSlips', 'paymentTransactions'])
            ->latest()
            ->paginate(15);
            
        // Calculate stats
        $stats = [
            'total_orders' => Order::count(),
            'pending_payment' => Order::where('status', 'pending_payment')->count(),
            'payment_uploaded' => Order::where('status', 'payment_uploaded')->count(),
            'paid' => Order::where('status', 'paid')->count(),
            'confirmed' => Order::where('status', 'confirmed')->count(),
            'processing' => Order::where('status', 'processing')->count(),
            'shipped' => Order::where('status', 'shipped')->count(),
            'delivered' => Order::where('status', 'delivered')->count(),
            'cancelled' => Order::where('status', 'cancelled')->count(),
            'total_revenue' => Order::whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])->sum('total_amount'),
        ];
        
        return view('admin.orders.index', compact('orders', 'stats'));
    }

    public function show($id)
    {
        $order = Order::with(['user', 'orderItems.product', 'paymentSlips', 'paymentTransactions', 'deliveryProof'])->findOrFail($id);
        return view('admin.orders.show', compact('order'));
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending_payment,payment_uploaded,paid,confirmed,processing,shipped,delivered,cancelled'
        ]);

        $order = Order::findOrFail($id);
        $oldStatus = $order->status;
        $newStatus = $request->status;

        // Validate status transitions
        $validTransitions = [
            'pending_payment' => ['payment_uploaded', 'cancelled'],
            'payment_uploaded' => ['paid', 'cancelled'],
            'paid' => ['confirmed', 'processing', 'cancelled'],
            'confirmed' => ['processing', 'shipped', 'cancelled'],
            'processing' => ['shipped', 'cancelled'],
            'shipped' => ['delivered', 'cancelled'],
            'delivered' => [],
            'cancelled' => []
        ];

        if (!in_array($newStatus, $validTransitions[$oldStatus] ?? [])) {
            return response()->json([
                'success' => false,
                'message' => 'ไม่สามารถเปลี่ยนสถานะจาก ' . $order->status_display . ' เป็น ' . $this->getStatusDisplay($newStatus) . ' ได้'
            ], 422);
        }

        $order->status = $newStatus;
        $order->save();

        $statusMessages = [
            'paid' => 'ยืนยันการชำระเงินเรียบร้อยแล้ว',
            'confirmed' => 'อนุมัติคำสั่งซื้อเรียบร้อยแล้ว',
            'processing' => 'เริ่มเตรียมสินค้าแล้ว',
            'shipped' => 'ส่งสินค้าเรียบร้อยแล้ว',
            'delivered' => 'ส่งสำเร็จแล้ว',
            'cancelled' => 'ยกเลิกคำสั่งซื้อแล้ว'
        ];

        return response()->json([
            'success' => true,
            'message' => $statusMessages[$newStatus] ?? 'อัพเดตสถานะออเดอร์เรียบร้อยแล้ว'
        ]);
    }

    private function getStatusDisplay($status)
    {
        $statusDisplays = [
            'pending_payment' => 'รอชำระเงิน',
            'payment_uploaded' => 'อัพโหลดสลิปแล้ว',
            'paid' => 'ชำระเงินแล้ว',
            'confirmed' => 'ยืนยันแล้ว',
            'processing' => 'กำลังเตรียม',
            'shipped' => 'ส่งแล้ว',
            'delivered' => 'ส่งสำเร็จ',
            'cancelled' => 'ยกเลิก'
        ];

        return $statusDisplays[$status] ?? $status;
    }

    public function destroy($id)
    {
        $order = Order::findOrFail($id);
        $order->delete();

        return response()->json([
            'success' => true,
            'message' => 'ลบออเดอร์เรียบร้อยแล้ว'
        ]);
    }

    public function stats()
    {
        $stats = [
            'total_orders' => Order::count(),
            'pending_orders' => Order::where('status', 'pending')->count(),
            'confirmed_orders' => Order::where('status', 'confirmed')->count(),
            'delivered_orders' => Order::where('status', 'delivered')->count(),
            'cancelled_orders' => Order::where('status', 'cancelled')->count(),
            'total_revenue' => Order::whereIn('status', ['paid', 'confirmed', 'processing', 'shipped', 'delivered'])->sum('total_amount'),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    public function uploadDeliveryProof(Request $request, $id)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg|max:5120', // 5MB max
            'notes' => 'nullable|string|max:500'
        ]);

        try {
            $order = Order::findOrFail($id);
            
            // Check if order status allows delivery proof upload
            if (!in_array($order->status, ['paid', 'confirmed', 'processing'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'สามารถอัปโหลดหลักฐานการจัดส่งได้เฉพาะคำสั่งซื้อที่ยืนยันแล้วหรือกำลังเตรียม'
                ], 422);
            }

            // Delete existing delivery proof if exists
            if ($order->deliveryProof) {
                Storage::disk('public')->delete($order->deliveryProof->image_path);
                $order->deliveryProof->delete();
            }

            $file = $request->file('image');
            $filename = 'delivery_proof_' . $order->id . '_' . time() . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('delivery_proofs', $filename, 'public');

            // Create delivery proof record
            $deliveryProof = DeliveryProof::create([
                'order_id' => $order->id,
                'image_path' => $path,
                'original_filename' => $file->getClientOriginalName(),
                'file_size' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
                'uploaded_by' => Auth::id(),
                'notes' => $request->notes,
            ]);

            // Update order status to shipped
            $order->update(['status' => 'shipped']);

            return response()->json([
                'success' => true,
                'message' => 'อัปโหลดหลักฐานการจัดส่งสำเร็จ',
                'data' => [
                    'delivery_proof' => $deliveryProof,
                    'image_url' => $deliveryProof->image_url,
                    'order_status' => 'shipped',
                    'order_status_display' => 'จัดส่งแล้ว'
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการอัปโหลด: ' . $e->getMessage()
            ], 500);
        }
    }

    public function deleteDeliveryProof($id)
    {
        try {
            $order = Order::findOrFail($id);
            
            if (!$order->deliveryProof) {
                return response()->json([
                    'success' => false,
                    'message' => 'ไม่พบหลักฐานการจัดส่ง'
                ], 404);
            }

            // Delete file from storage
            Storage::disk('public')->delete($order->deliveryProof->image_path);
            
            // Delete record
            $order->deliveryProof->delete();
            
            // Revert order status back to processing
            $order->update(['status' => 'processing']);

            return response()->json([
                'success' => true,
                'message' => 'ลบหลักฐานการจัดส่งสำเร็จ',
                'order_status' => 'processing',
                'order_status_display' => 'กำลังเตรียมสินค้า'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการลบ: ' . $e->getMessage()
            ], 500);
        }
    }
}