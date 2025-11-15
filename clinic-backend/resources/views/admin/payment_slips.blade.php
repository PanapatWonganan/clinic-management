<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการสลิปการชำระเงิน - Admin Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            font-family: 'Prompt', sans-serif;
        }
        
        .admin-header {
            background: linear-gradient(135deg, #8386CB 0%, #383B77 100%);
            color: white;
            padding: 2rem 0;
            margin-bottom: 2rem;
        }
        
        .slip-card {
            border: 1px solid #e0e0e0;
            border-radius: 12px;
            padding: 1.5rem;
            margin-bottom: 1rem;
            transition: all 0.3s ease;
        }
        
        .slip-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        
        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.875rem;
            font-weight: 500;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-approved {
            background-color: #d1edff;
            color: #004085;
        }
        
        .status-rejected {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .slip-preview {
            max-width: 200px;
            max-height: 150px;
            object-fit: cover;
            border-radius: 8px;
            cursor: pointer;
        }
        
        .btn-action {
            padding: 0.5rem 1rem;
            margin: 0.25rem;
            border: none;
            border-radius: 6px;
            font-size: 0.875rem;
            transition: all 0.3s ease;
        }
        
        .btn-approve {
            background-color: #28a745;
            color: white;
        }
        
        .btn-reject {
            background-color: #dc3545;
            color: white;
        }
        
        .btn-action:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        }
        
        .filter-section {
            background-color: #f8f9fa;
            padding: 1.5rem;
            border-radius: 12px;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="admin-header">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1 class="mb-0"><i class="fas fa-receipt me-3"></i>จัดการสลิปการชำระเงิน</h1>
                </div>
                <div class="col-md-6 text-end">
                    <a href="/admin/dashboard" class="btn btn-outline-light">
                        <i class="fas fa-arrow-left me-2"></i>กลับหน้าหลัก
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="container">
        <!-- Filter Section -->
        <div class="filter-section">
            <div class="row align-items-center">
                <div class="col-md-4">
                    <label for="statusFilter" class="form-label">กรองตามสถานะ:</label>
                    <select class="form-select" id="statusFilter">
                        <option value="">ทั้งหมด</option>
                        <option value="pending">รอตรวจสอบ</option>
                        <option value="approved">อนุมัติแล้ว</option>
                        <option value="rejected">ปฏิเสธ</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <label for="orderIdFilter" class="form-label">หมายเลขคำสั่งซื้อ:</label>
                    <input type="text" class="form-control" id="orderIdFilter" placeholder="ค้นหาคำสั่งซื้อ">
                </div>
                <div class="col-md-4 d-flex align-items-end">
                    <button class="btn btn-primary" onclick="filterSlips()">
                        <i class="fas fa-search me-2"></i>ค้นหา
                    </button>
                    <button class="btn btn-outline-secondary ms-2" onclick="resetFilters()">
                        <i class="fas fa-refresh me-2"></i>รีเซ็ต
                    </button>
                </div>
            </div>
        </div>

        <!-- Payment Slips List -->
        <div id="slipsContainer">
            <div class="text-center py-5">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">กำลังโหลด...</span>
                </div>
                <p class="mt-3 text-muted">กำลังโหลดข้อมูลสลิป...</p>
            </div>
        </div>
    </div>

    <!-- Modal for viewing slip -->
    <div class="modal fade" id="slipModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">รายละเอียดสลิป</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <img id="slipImage" src="" class="img-fluid" alt="Payment Slip">
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for updating status -->
    <div class="modal fade" id="statusModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">อัปเดตสถานะสลิป</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="statusForm">
                        <input type="hidden" id="slipId" value="">
                        <div class="mb-3">
                            <label for="status" class="form-label">สถานะ:</label>
                            <select class="form-select" id="status" required>
                                <option value="">เลือกสถานะ</option>
                                <option value="pending">รอตรวจสอบ</option>
                                <option value="approved">อนุมัติ</option>
                                <option value="rejected">ปฏิเสธ</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="adminNotes" class="form-label">หมายเหตุ:</label>
                            <textarea class="form-control" id="adminNotes" rows="3" placeholder="เพิ่มหมายเหตุ (ถ้าต้องการ)"></textarea>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">ยกเลิก</button>
                    <button type="button" class="btn btn-primary" onclick="updateSlipStatus()">บันทึก</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        let currentFilters = {
            status: '',
            orderId: ''
        };

        // Load payment slips on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadPaymentSlips();
        });

        async function loadPaymentSlips() {
            try {
                const params = new URLSearchParams(currentFilters);
                const response = await fetch(`/admin/payment-slips/api?${params}`);
                const data = await response.json();

                if (data.success) {
                    renderPaymentSlips(data.data.data);
                } else {
                    showError('ไม่สามารถโหลดข้อมูลได้');
                }
            } catch (error) {
                showError('เกิดข้อผิดพลาดในการโหลดข้อมูล');
                console.error('Error loading slips:', error);
            }
        }

        function renderPaymentSlips(slips) {
            const container = document.getElementById('slipsContainer');
            
            if (slips.length === 0) {
                container.innerHTML = `
                    <div class="text-center py-5">
                        <i class="fas fa-receipt fa-3x text-muted mb-3"></i>
                        <h5 class="text-muted">ไม่พบสลิปการชำระเงิน</h5>
                        <p class="text-muted">ยังไม่มีลูกค้าอัปโหลดสลิปการชำระเงิน</p>
                    </div>
                `;
                return;
            }

            const slipsHtml = slips.map(slip => {
                const statusClass = `status-${slip.status}`;
                const statusText = getStatusText(slip.status);
                const isImage = slip.file_name.toLowerCase().match(/\.(jpg|jpeg|png)$/);
                
                return `
                    <div class="slip-card">
                        <div class="row align-items-center">
                            <div class="col-md-3">
                                ${isImage ? 
                                    `<img src="${slip.url}" class="slip-preview" onclick="viewSlip('${slip.url}')" alt="Slip Preview">` :
                                    `<div class="text-center p-3 border rounded">
                                        <i class="fas fa-file-pdf fa-2x text-danger mb-2"></i>
                                        <p class="mb-0 small">PDF ไฟล์</p>
                                        <a href="${slip.url}" target="_blank" class="btn btn-sm btn-outline-primary mt-2">ดูไฟล์</a>
                                    </div>`
                                }
                            </div>
                            <div class="col-md-6">
                                <h6 class="mb-2">คำสั่งซื้อ: ${slip.order_number}</h6>
                                <p class="mb-1"><strong>ลูกค้า:</strong> ${slip.customer_name} (${slip.customer_email})</p>
                                <p class="mb-1"><strong>ชื่อไฟล์:</strong> ${slip.original_name}</p>
                                <p class="mb-1"><strong>ขนาดไฟล์:</strong> ${formatFileSize(slip.file_size)}</p>
                                <p class="mb-1"><strong>อัปโหลดเมื่อ:</strong> ${formatDateTime(slip.uploaded_at)}</p>
                                <span class="status-badge ${statusClass}">${statusText}</span>
                            </div>
                            <div class="col-md-3 text-end">
                                ${slip.status === 'pending' ? `
                                    <button class="btn btn-action btn-approve" onclick="openStatusModal(${slip.id}, 'approved')">
                                        <i class="fas fa-check"></i> อนุมัติ
                                    </button>
                                    <button class="btn btn-action btn-reject" onclick="openStatusModal(${slip.id}, 'rejected')">
                                        <i class="fas fa-times"></i> ปฏิเสธ
                                    </button>
                                ` : `
                                    <button class="btn btn-outline-secondary btn-action" onclick="openStatusModal(${slip.id}, '${slip.status}')">
                                        <i class="fas fa-edit"></i> แก้ไข
                                    </button>
                                `}
                            </div>
                        </div>
                    </div>
                `;
            }).join('');

            container.innerHTML = slipsHtml;
        }

        function getStatusText(status) {
            const statusMap = {
                'pending': 'รอตรวจสอบ',
                'approved': 'อนุมัติแล้ว', 
                'rejected': 'ปฏิเสธ'
            };
            return statusMap[status] || status;
        }

        function formatFileSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
            return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
        }

        function formatDateTime(dateString) {
            return new Date(dateString).toLocaleString('th-TH');
        }

        function viewSlip(url) {
            document.getElementById('slipImage').src = url;
            new bootstrap.Modal(document.getElementById('slipModal')).show();
        }

        function openStatusModal(slipId, currentStatus) {
            document.getElementById('slipId').value = slipId;
            document.getElementById('status').value = currentStatus;
            new bootstrap.Modal(document.getElementById('statusModal')).show();
        }

        async function updateSlipStatus() {
            const slipId = document.getElementById('slipId').value;
            const status = document.getElementById('status').value;
            const adminNotes = document.getElementById('adminNotes').value;

            if (!status) {
                alert('กรุณาเลือกสถานะ');
                return;
            }

            try {
                const response = await fetch(`/admin/payment-slips/${slipId}/status`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
                    },
                    body: JSON.stringify({
                        status: status,
                        admin_notes: adminNotes
                    })
                });

                const data = await response.json();

                if (data.success) {
                    bootstrap.Modal.getInstance(document.getElementById('statusModal')).hide();
                    showSuccess('อัปเดตสถานะสำเร็จ');
                    loadPaymentSlips(); // Reload the list
                } else {
                    showError('ไม่สามารถอัปเดตสถานะได้');
                }
            } catch (error) {
                showError('เกิดข้อผิดพลาดในการอัปเดต');
                console.error('Error updating status:', error);
            }
        }

        function filterSlips() {
            currentFilters.status = document.getElementById('statusFilter').value;
            currentFilters.orderId = document.getElementById('orderIdFilter').value;
            loadPaymentSlips();
        }

        function resetFilters() {
            document.getElementById('statusFilter').value = '';
            document.getElementById('orderIdFilter').value = '';
            currentFilters = { status: '', orderId: '' };
            loadPaymentSlips();
        }

        function showSuccess(message) {
            // You can implement a toast notification here
            alert(message);
        }

        function showError(message) {
            // You can implement a toast notification here
            alert(message);
        }
    </script>
</body>
</html>