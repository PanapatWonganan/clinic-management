<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>รายละเอียดคำสั่งซื้อ #{{ $order->order_number ?? $order->id }} - Beauty Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            min-height: 100vh;
            color: #1e293b;
            padding: 2rem;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 1rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            padding: 2rem;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid #e2e8f0;
        }

        h1 {
            font-size: 1.875rem;
            font-weight: 700;
            color: #1e293b;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.75rem 1.5rem;
            border-radius: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            border: none;
        }

        .btn-secondary {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        .btn-success {
            background: #10b981;
            color: white;
        }

        .btn-success:hover {
            background: #059669;
        }

        .btn-primary {
            background: #8b5cf6;
            color: white;
        }

        .btn-primary:hover {
            background: #7c3aed;
        }

        .btn-danger {
            background: #ef4444;
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .order-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
            margin-bottom: 2rem;
        }

        .info-card {
            background: #f8fafc;
            padding: 1.5rem;
            border-radius: 0.75rem;
            border: 1px solid #e2e8f0;
        }

        .info-card h3 {
            font-size: 1.125rem;
            font-weight: 600;
            margin-bottom: 1rem;
            color: #1e293b;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.75rem;
        }

        .info-label {
            color: #64748b;
            font-weight: 500;
        }

        .info-value {
            color: #1e293b;
            font-weight: 600;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-pending_payment { background: #fef3c7; color: #d97706; }
        .status-payment_uploaded { background: #dbeafe; color: #2563eb; }
        .status-paid { background: #d1fae5; color: #059669; }
        .status-confirmed { background: #dcfce7; color: #16a34a; }
        .status-processing { background: #e0f2fe; color: #0891b2; }
        .status-shipped { background: #f3e8ff; color: #7c3aed; }
        .status-delivered { background: #ecfccb; color: #65a30d; }
        .status-cancelled { background: #fee2e2; color: #dc2626; }
        .status-pending { background: #fef3c7; color: #d97706; }
        .status-approved { background: #d1fae5; color: #059669; }
        .status-rejected { background: #fee2e2; color: #dc2626; }

        .order-items {
            margin-bottom: 2rem;
        }

        .items-table {
            overflow-x: auto;
            border-radius: 0.75rem;
            border: 1px solid #e2e8f0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            background: #f8fafc;
            padding: 1rem;
            text-align: left;
            font-weight: 600;
            color: #374151;
            border-bottom: 1px solid #e2e8f0;
        }

        td {
            padding: 1rem;
            border-bottom: 1px solid #f3f4f6;
        }

        .payment-slips {
            margin-bottom: 2rem;
        }

        .slips-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
        }

        .slip-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 0.75rem;
            padding: 1.5rem;
        }

        .slip-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .slip-image {
            width: 100%;
            max-height: 200px;
            object-fit: cover;
            border-radius: 0.5rem;
            margin-bottom: 1rem;
        }

        .slip-actions {
            display: flex;
            gap: 0.5rem;
            margin-top: 1rem;
        }

        .no-slips {
            text-align: center;
            padding: 2rem;
            color: #64748b;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 0.75rem;
        }

        .success-message {
            background: #d1fae5;
            color: #065f46;
            padding: 1rem;
            border-radius: 0.5rem;
            margin-bottom: 1rem;
            display: none;
        }

        .error-message {
            background: #fee2e2;
            color: #991b1b;
            padding: 1rem;
            border-radius: 0.5rem;
            margin-bottom: 1rem;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-receipt"></i> คำสั่งซื้อ #{{ $order->order_number ?? $order->id }}</h1>
            </div>
            <div>
                <a href="{{ route('admin.orders.index') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับรายการคำสั่งซื้อ
                </a>
            </div>
        </div>

        <div id="success-message" class="success-message"></div>
        <div id="error-message" class="error-message"></div>

        <div class="order-info">
            <div class="info-card">
                <h3><i class="fas fa-user"></i> ข้อมูลลูกค้า</h3>
                <div class="info-row">
                    <span class="info-label">ชื่อ:</span>
                    <span class="info-value">{{ $order->user->name ?? 'ไม่ระบุ' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">อีเมล:</span>
                    <span class="info-value">{{ $order->user->email ?? 'ไม่ระบุ' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">เบอร์โทร:</span>
                    <span class="info-value">{{ $order->user->phone ?? 'ไม่ระบุ' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">ที่อยู่:</span>
                    <span class="info-value">{{ $order->user->address ?? 'ไม่ระบุ' }}</span>
                </div>
            </div>

            <div class="info-card">
                <h3><i class="fas fa-shopping-cart"></i> ข้อมูลคำสั่งซื้อ</h3>
                <div class="info-row">
                    <span class="info-label">วันที่สั่ง:</span>
                    <span class="info-value">{{ $order->created_at->format('d/m/Y H:i') }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">สถานะ:</span>
                    <span class="status-badge status-{{ $order->status }}">{{ $order->status_display }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">วิธีชำระเงิน:</span>
                    <span class="info-value">{{ $order->payment_method ?? 'ไม่ระบุ' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">ยอดรวม:</span>
                    <span class="info-value" style="font-size: 1.25rem; color: #8b5cf6;">฿{{ number_format($order->total_amount, 2) }}</span>
                </div>
            </div>
        </div>

        <!-- Order Status Actions -->
        @if(in_array($order->status, ['payment_uploaded', 'paid']))
        <div style="margin-bottom: 2rem; padding: 1.5rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 0.75rem;">
            <h3 style="margin-bottom: 1rem; color: #1e293b;"><i class="fas fa-cogs"></i> จัดการสถานะคำสั่งซื้อ</h3>
            <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
                @if($order->status === 'payment_uploaded')
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'paid')" class="btn btn-success">
                        <i class="fas fa-check-circle"></i> ยืนยันการชำระเงิน
                    </button>
                @endif

                @if($order->status === 'paid')
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'confirmed')" class="btn btn-success">
                        <i class="fas fa-thumbs-up"></i> อนุมัติคำสั่งซื้อ
                    </button>
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'processing')" class="btn" style="background: #3b82f6; color: white;">
                        <i class="fas fa-play"></i> เริ่มเตรียมสินค้า
                    </button>
                @endif

                @if(in_array($order->status, ['confirmed', 'processing']))
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'shipped')" class="btn" style="background: #8b5cf6; color: white;">
                        <i class="fas fa-shipping-fast"></i> ส่งสินค้าแล้ว
                    </button>
                @endif

                @if($order->status === 'shipped')
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'delivered')" class="btn" style="background: #10b981; color: white;">
                        <i class="fas fa-check-double"></i> ส่งสำเร็จแล้ว
                    </button>
                @endif

                @if(!in_array($order->status, ['delivered', 'cancelled']))
                    <button onclick="updateOrderStatus('{{ $order->id }}', 'cancelled')" class="btn btn-danger">
                        <i class="fas fa-ban"></i> ยกเลิกคำสั่งซื้อ
                    </button>
                @endif
            </div>
        </div>
        @endif

        <div class="order-items">
            <h3 style="margin-bottom: 1rem; color: #1e293b;"><i class="fas fa-box"></i> รายการสินค้า</h3>
            <div class="items-table">
                <table>
                    <thead>
                        <tr>
                            <th>สินค้า</th>
                            <th>ราคา/หน่วย</th>
                            <th>จำนวน</th>
                            <th>รวม</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($order->orderItems as $item)
                        <tr>
                            <td>
                                <div>
                                    <div style="font-weight: 500;">{{ $item->product->name ?? 'สินค้าไม่พบ' }}</div>
                                    <div style="color: #64748b; font-size: 0.875rem;">{{ $item->product->description ?? '' }}</div>
                                </div>
                            </td>
                            <td>฿{{ number_format($item->price, 2) }}</td>
                            <td>{{ $item->quantity }}</td>
                            <td style="font-weight: 600;">฿{{ number_format($item->price * $item->quantity, 2) }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        <div class="payment-slips">
            <h3 style="margin-bottom: 1rem; color: #1e293b;">
                <i class="fas fa-receipt"></i> สลิปการชำระเงิน 
                <span style="background: #8b5cf6; color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem;">
                    {{ $order->paymentSlips->count() }} สลิป
                </span>
            </h3>
            
            @if($order->paymentSlips->count() > 0)
                <div class="slips-grid">
                    @foreach($order->paymentSlips as $slip)
                    <div class="slip-card">
                        <div class="slip-header">
                            <div>
                                <div style="font-weight: 600; margin-bottom: 0.25rem;">{{ $slip->original_name }}</div>
                                <div style="color: #64748b; font-size: 0.875rem;">
                                    {{ number_format($slip->file_size / 1024, 1) }} KB • 
                                    {{ $slip->created_at->format('d/m/Y H:i') }}
                                </div>
                            </div>
                            <span class="status-badge status-{{ $slip->status }}">{{ $slip->status_display }}</span>
                        </div>
                        
                        @if(in_array($slip->mime_type, ['image/jpeg', 'image/jpg', 'image/png']))
                            <img src="{{ Storage::url($slip->file_path) }}" alt="Payment Slip" class="slip-image">
                        @else
                            <div style="background: #e2e8f0; padding: 2rem; text-align: center; border-radius: 0.5rem; margin-bottom: 1rem;">
                                <i class="fas fa-file-pdf" style="font-size: 2rem; color: #64748b;"></i>
                                <div style="margin-top: 0.5rem; color: #64748b;">PDF File</div>
                            </div>
                        @endif

                        @if($slip->admin_notes)
                            <div style="background: #fef3c7; padding: 0.75rem; border-radius: 0.5rem; margin-bottom: 1rem;">
                                <div style="font-weight: 600; color: #d97706; font-size: 0.875rem; margin-bottom: 0.25rem;">หมายเหตุ:</div>
                                <div style="color: #92400e; font-size: 0.875rem;">{{ $slip->admin_notes }}</div>
                            </div>
                        @endif

                        <div class="slip-actions">
                            <a href="{{ Storage::url($slip->file_path) }}" target="_blank" class="btn btn-secondary" style="flex: 1; justify-content: center; font-size: 0.875rem; padding: 0.5rem;">
                                <i class="fas fa-external-link-alt"></i> ดูเต็มขนาด
                            </a>
                            
                            @if($slip->status === 'pending')
                                <button onclick="updateSlipStatus({{ $slip->id }}, 'approved')" class="btn btn-success" style="flex: 1; justify-content: center; font-size: 0.875rem; padding: 0.5rem;">
                                    <i class="fas fa-check"></i> อนุมัติ
                                </button>
                                <button onclick="updateSlipStatus({{ $slip->id }}, 'rejected')" class="btn btn-danger" style="flex: 1; justify-content: center; font-size: 0.875rem; padding: 0.5rem;">
                                    <i class="fas fa-times"></i> ปฏิเสธ
                                </button>
                            @endif
                        </div>
                    </div>
                    @endforeach
                </div>
            @else
                <div class="no-slips">
                    <i class="fas fa-receipt" style="font-size: 2rem; color: #cbd5e1; margin-bottom: 1rem;"></i>
                    <h4>ไม่มีสลิปการชำระเงิน</h4>
                    <p>ลูกค้ายังไม่ได้อัพโหลดสลิปการชำระเงิน</p>
                </div>
            @endif
        <!-- Delivery Proof Section in Same Card -->
        @if(in_array($order->status, ['paid', 'confirmed', 'processing', 'shipped']))
        <div style="border-top: 1px solid #e2e8f0; margin-top: 2rem; padding-top: 2rem;">
            <h3 style="margin-bottom: 1rem; color: #1e293b;">
                <i class="fas fa-truck"></i> หลักฐานการจัดส่ง
                @if($order->deliveryProof)
                    <span style="background: #10b981; color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem;">
                        อัพโหลดแล้ว
                    </span>
                @else
                    <span style="background: #f59e0b; color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem;">
                        ยังไม่มี
                    </span>
                @endif
            </h3>
            @if($order->deliveryProof)
                <!-- Show existing delivery proof in same style as payment slips -->
                <div class="slips-grid">
                    <div class="slip-card">
                        <div class="slip-header">
                            <span class="slip-filename">{{ $order->deliveryProof->original_filename }}</span>
                            <span class="status-badge" style="background: #10b981; color: white;">จัดส่งแล้ว</span>
                        </div>
                        
                        <div class="slip-image">
                            <img src="{{ $order->deliveryProof->image_url }}" alt="หลักฐานการจัดส่ง" 
                                 loading="lazy" onclick="showImageModal('{{ $order->deliveryProof->image_url }}')">
                        </div>
                        
                        <div class="slip-info">
                            <p><strong>ขนาดไฟล์:</strong> {{ $order->deliveryProof->file_size_formatted }}</p>
                            <p><strong>อัพโหลดเมื่อ:</strong> {{ $order->deliveryProof->created_at->format('d/m/Y H:i') }}</p>
                            <p><strong>โดย:</strong> {{ $order->deliveryProof->uploader->name }}</p>
                            @if($order->deliveryProof->notes)
                                <p><strong>หมายเหตุ:</strong> {{ $order->deliveryProof->notes }}</p>
                            @endif
                        </div>

                        <div class="slip-actions" style="display: flex; gap: 0.5rem; margin-top: 1rem;">
                            <button onclick="deleteDeliveryProof({{ $order->id }})" class="btn btn-danger" style="flex: 1; justify-content: center; font-size: 0.875rem; padding: 0.5rem;">
                                <i class="fas fa-trash"></i> ลบหลักฐาน
                            </button>
                        </div>
                    </div>
                </div>
            @else
                <!-- Upload form for delivery proof -->
                @if(in_array($order->status, ['paid', 'confirmed', 'processing']))
                <div style="max-width: 500px;">
                    <div style="margin-bottom: 1rem;">
                        <label for="deliveryImage" style="display: block; margin-bottom: 0.5rem; font-weight: 600;">อัพโหลดรูปหลักฐานการจัดส่ง:</label>
                        <input type="file" id="deliveryImage" name="image" accept="image/*" required
                               style="width: 100%; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 6px;">
                        <small style="color: #6b7280;">ไฟล์ภาพ (JPEG, PNG, JPG) ขนาดไม่เกิน 5MB</small>
                    </div>

                    <div style="margin-bottom: 1rem;">
                        <label for="deliveryNotes" style="display: block; margin-bottom: 0.5rem; font-weight: 600;">หมายเหตุ (ถ้ามี):</label>
                        <textarea id="deliveryNotes" name="notes" rows="3"
                                  style="width: 100%; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 6px;"
                                  placeholder="หมายเหตุเพิ่มเติม..."></textarea>
                    </div>

                    <button type="button" class="btn btn-primary" onclick="uploadDeliveryProofNow()">
                        <i class="fas fa-upload"></i> อัพโหลดหลักฐานการจัดส่ง
                    </button>
                </div>
                @else
                    <div class="no-slips">
                        <i class="fas fa-truck" style="font-size: 2rem; color: #cbd5e1; margin-bottom: 1rem;"></i>
                        <h4>รอการอัพโหลดหลักฐานการจัดส่ง</h4>
                        <p>สามารถอัพโหลดหลักฐานการจัดส่งได้เมื่อสถานะเป็น "ชำระเงินแล้ว" หรือ "กำลังเตรียม"</p>
                    </div>
                @endif
            @endif
        </div>
        @endif
        </div>
    </div>

    <!-- Image Modal -->
    <div id="imageModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.9);">
        <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); max-width: 90%; max-height: 90%;">
            <img id="modalImage" style="width: 100%; height: auto; max-width: 800px;">
            <button onclick="closeImageModal()" style="position: absolute; top: -40px; right: -40px; background: white; border: none; border-radius: 50%; width: 40px; height: 40px; font-size: 20px; cursor: pointer;">×</button>
        </div>
    </div>

    <script>
        async function updateSlipStatus(slipId, status) {
            try {
                const response = await fetch(`/admin/payment-slips/${slipId}/status`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                    },
                    body: JSON.stringify({ 
                        status: status,
                        admin_notes: status === 'rejected' ? prompt('หมายเหตุ (ถ้ามี):') : null
                    })
                });

                const result = await response.json();

                if (result.success) {
                    document.getElementById('success-message').style.display = 'block';
                    document.getElementById('success-message').textContent = result.message;
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } else {
                    document.getElementById('error-message').style.display = 'block';
                    document.getElementById('error-message').textContent = result.message || 'เกิดข้อผิดพลาด';
                }
            } catch (error) {
                document.getElementById('error-message').style.display = 'block';
                document.getElementById('error-message').textContent = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
            }
        }

        async function updateOrderStatus(orderId, status) {
            const confirmMessages = {
                'paid': 'ยืนยันการชำระเงินแล้ว?',
                'confirmed': 'อนุมัติคำสั่งซื้อนี้?',
                'processing': 'เริ่มเตรียมสินค้า?',
                'shipped': 'ยืนยันว่าได้ส่งสินค้าแล้ว?',
                'delivered': 'ยืนยันว่าส่งสำเร็จแล้ว?',
                'cancelled': 'ยกเลิกคำสั่งซื้อนี้?'
            };

            if (!confirm(confirmMessages[status] || 'เปลี่ยนสถานะ?')) return;

            try {
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

                const response = await fetch(`/admin/orders/${orderId}/status`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({ status: status })
                });

                const result = await response.json();

                if (result.success) {
                    // Show success message
                    const successDiv = document.getElementById('success-message');
                    successDiv.style.display = 'block';
                    successDiv.textContent = result.message;

                    // Hide error message if visible
                    document.getElementById('error-message').style.display = 'none';

                    // Reload page after showing message
                    setTimeout(() => {
                        window.location.reload();
                    }, 1500);
                } else {
                    // Show error message
                    const errorDiv = document.getElementById('error-message');
                    errorDiv.style.display = 'block';
                    errorDiv.textContent = result.message || 'เกิดข้อผิดพลาด';
                }
            } catch (error) {
                // Show error message
                const errorDiv = document.getElementById('error-message');
                errorDiv.style.display = 'block';
                errorDiv.textContent = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
            }
        }

        // Delivery proof functions
        function uploadDeliveryProofNow() {
            const imageFile = document.getElementById('deliveryImage').files[0];
            const notes = document.getElementById('deliveryNotes').value;

            if (!imageFile) {
                alert('กรุณาเลือกไฟล์รูปภาพ');
                return;
            }

            const formData = new FormData();
            formData.append('image', imageFile);
            formData.append('notes', notes);

            fetch('/admin/orders/{{ $order->id }}/delivery-proof', {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                },
                body: formData
            })
            .then(response => response.json())
            .then(result => {
                if (result.success) {
                    document.getElementById('success-message').style.display = 'block';
                    document.getElementById('success-message').textContent = result.message;
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } else {
                    document.getElementById('error-message').style.display = 'block';
                    document.getElementById('error-message').textContent = result.message || 'เกิดข้อผิดพลาด';
                }
            })
            .catch(error => {
                document.getElementById('error-message').style.display = 'block';
                document.getElementById('error-message').textContent = 'เกิดข้อผิดพลาดในการอัพโหลด';
            });
        }

        async function deleteDeliveryProof(orderId) {
            if (!confirm('คุณต้องการลบหลักฐานการจัดส่งนี้หรือไม่?')) return;
            
            try {
                const response = await fetch(`/admin/orders/${orderId}/delivery-proof`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                    }
                });
                
                const result = await response.json();
                
                if (result.success) {
                    document.getElementById('success-message').style.display = 'block';
                    document.getElementById('success-message').textContent = result.message;
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } else {
                    document.getElementById('error-message').style.display = 'block';
                    document.getElementById('error-message').textContent = result.message || 'เกิดข้อผิดพลาด';
                }
            } catch (error) {
                document.getElementById('error-message').style.display = 'block';
                document.getElementById('error-message').textContent = 'เกิดข้อผิดพลาดในการลบ';
            }
        }

        function showImageModal(imageUrl) {
            document.getElementById('modalImage').src = imageUrl;
            document.getElementById('imageModal').style.display = 'block';
        }

        function closeImageModal() {
            document.getElementById('imageModal').style.display = 'none';
        }

        // Close modal when clicking outside
        document.getElementById('imageModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeImageModal();
            }
        });
    </script>
</body>
</html>