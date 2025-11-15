<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการลูกค้า - Exquiller Admin</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --primary: #6366f1;
            --primary-light: #818cf8;
            --accent: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --text-primary: #1e293b;
            --text-secondary: #64748b;
            --border: #e2e8f0;
            --white: #ffffff;
            --background: #f8fafc;
            --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, var(--background) 0%, #f1f5f9 100%);
            min-height: 100vh;
            color: var(--text-primary);
            padding: 2rem;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: var(--white);
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            margin-bottom: 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 2rem;
            font-weight: 700;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .header-actions {
            display: flex;
            gap: 1rem;
            align-items: center;
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
            font-size: 0.875rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-light);
            transform: translateY(-1px);
            box-shadow: var(--shadow);
        }

        .btn-secondary {
            background: var(--background);
            color: var(--text-secondary);
            border: 1px solid var(--border);
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--white);
            border-radius: 1rem;
            padding: 1.5rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            transition: all 0.3s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }

        .stat-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            color: white;
        }

        .stat-icon.primary { background: linear-gradient(135deg, var(--primary), var(--primary-light)); }
        .stat-icon.accent { background: linear-gradient(135deg, var(--accent), #34d399); }
        .stat-icon.warning { background: linear-gradient(135deg, var(--warning), #fbbf24); }

        .stat-value {
            font-size: 2rem;
            font-weight: 700;
            color: var(--text-primary);
        }

        .stat-label {
            color: var(--text-secondary);
            font-size: 0.875rem;
            margin-top: 0.25rem;
        }

        /* Main Content */
        .main-content {
            background: var(--white);
            border-radius: 1rem;
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            overflow: hidden;
        }

        .content-header {
            padding: 1.5rem 2rem;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .content-header h2 {
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .search-box {
            position: relative;
            max-width: 300px;
        }

        .search-box input {
            width: 100%;
            padding: 0.75rem 1rem 0.75rem 2.5rem;
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            font-size: 0.875rem;
        }

        .search-box i {
            position: absolute;
            left: 0.75rem;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
        }

        /* Table */
        .table-container {
            overflow-x: auto;
        }

        .table {
            width: 100%;
            border-collapse: collapse;
        }

        .table th {
            background: var(--background);
            padding: 1rem 1.5rem;
            text-align: left;
            font-weight: 600;
            font-size: 0.875rem;
            color: var(--text-primary);
            border-bottom: 1px solid var(--border);
        }

        .table td {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #f3f4f6;
            font-size: 0.875rem;
        }

        .table tbody tr:hover {
            background: var(--background);
        }

        .membership-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }

        .membership-badge.exMember {
            background: #f3f4f6;
            color: #6b7280;
        }

        .membership-badge.exDoctor {
            background: #dbeafe;
            color: #1e40af;
        }

        .membership-badge.exVip {
            background: #fef3c7;
            color: #92400e;
        }

        .membership-badge.exSupervip {
            background: #e9d5ff;
            color: #6b21a8;
        }

        .action-buttons {
            display: flex;
            gap: 0.5rem;
        }

        .btn-action {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            border: none;
            border-radius: 0.5rem;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 0.875rem;
        }

        .btn-action.edit {
            background: #dbeafe;
            color: #1d4ed8;
        }

        .btn-action.edit:hover {
            background: #bfdbfe;
        }

        .btn-action.delete {
            background: #fee2e2;
            color: #dc2626;
        }

        .btn-action.delete:hover {
            background: #fecaca;
        }

        .btn-action.membership {
            background: #fef3c7;
            color: #92400e;
        }

        .btn-action.membership:hover {
            background: #fde68a;
        }

        /* Pagination */
        .pagination {
            padding: 1.5rem 2rem;
            display: flex;
            justify-content: between;
            align-items: center;
            border-top: 1px solid var(--border);
        }

        .pagination-info {
            color: var(--text-secondary);
            font-size: 0.875rem;
        }

        .pagination-links {
            display: flex;
            gap: 0.5rem;
        }

        .pagination-links a,
        .pagination-links span {
            padding: 0.5rem 0.75rem;
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 0.875rem;
        }

        .pagination-links .active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 9999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
        }

        .modal-content {
            background: var(--white);
            margin: 2% auto;
            padding: 0;
            border-radius: 1rem;
            width: 90%;
            max-width: 600px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: var(--shadow-lg);
        }

        .modal-header {
            padding: 1.5rem 2rem;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h3 {
            font-size: 1.25rem;
            font-weight: 600;
        }

        .close {
            color: var(--text-secondary);
            font-size: 1.5rem;
            cursor: pointer;
            padding: 0.5rem;
            border-radius: 0.5rem;
            transition: all 0.2s;
        }

        .close:hover {
            background: var(--background);
        }

        .modal-body {
            padding: 2rem;
        }

        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-label {
            display: block;
            font-weight: 500;
            margin-bottom: 0.5rem;
            color: var(--text-primary);
        }

        .form-input {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            font-size: 0.875rem;
            transition: all 0.2s;
        }

        .form-input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }

        .modal-footer {
            padding: 1.5rem 2rem;
            border-top: 1px solid var(--border);
            display: flex;
            justify-content: flex-end;
            gap: 1rem;
        }

        /* Responsive */
        @media (max-width: 768px) {
            body {
                padding: 1rem;
            }

            .header {
                flex-direction: column;
                gap: 1rem;
                text-align: center;
            }

            .header-actions {
                width: 100%;
                justify-content: center;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .content-header {
                flex-direction: column;
                gap: 1rem;
            }

            .search-box {
                max-width: 100%;
            }

            .form-row {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>
                <i class="fas fa-users"></i>
                จัดการลูกค้า
            </h1>
            <div class="header-actions">
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
                <button class="btn btn-primary" onclick="openCustomerModal()">
                    <i class="fas fa-user-plus"></i>
                    เพิ่มลูกค้าใหม่
                </button>
            </div>
        </div>

        <!-- Stats -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon primary">
                        <i class="fas fa-users"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['total_customers'] }}</div>
                <div class="stat-label">ลูกค้าทั้งหมด</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon accent">
                        <i class="fas fa-user-plus"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['new_customers_this_month'] }}</div>
                <div class="stat-label">ลูกค้าใหม่เดือนนี้</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon warning">
                        <i class="fas fa-crown"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['membership_breakdown']->where('membership_type', '!=', 'exMember')->sum('count') }}</div>
                <div class="stat-label">สมาชิกพรีเมียม</div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <div class="content-header">
                <h2>รายการลูกค้า ({{ $customers->total() }} คน)</h2>
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" placeholder="ค้นหาลูกค้า..." id="searchCustomer" onkeyup="searchCustomers()">
                </div>
            </div>

            <div class="table-container">
                <table class="table">
                    <thead>
                        <tr>
                            <th>ลูกค้า</th>
                            <th>อีเมล</th>
                            <th>เบอร์โทร</th>
                            <th>สมาชิกภาพ</th>
                            <th>วันที่สมัคร</th>
                            <th>จัดการ</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($customers as $customer)
                        <tr id="customer-row-{{ $customer->id }}">
                            <td>
                                <div>
                                    <div style="font-weight: 600;">{{ $customer->name }}</div>
                                    @php
                                        $addressCount = $customer->addresses()->count();
                                        $defaultAddress = $customer->addresses()->where('is_default', true)->first();
                                    @endphp
                                    @if($defaultAddress)
                                        <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                            {{ $defaultAddress->district }}, {{ $defaultAddress->province }}
                                        </div>
                                    @elseif($customer->district && $customer->province)
                                        <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                            {{ $customer->district }}, {{ $customer->province }}
                                        </div>
                                    @endif
                                    @if($addressCount > 0)
                                        <div style="font-size: 0.7rem; color: var(--primary); margin-top: 0.25rem; cursor: pointer;" onclick="showAddresses({{ $customer->id }})">
                                            <i class="fas fa-map-marker-alt"></i> {{ $addressCount }} ที่อยู่
                                        </div>
                                    @endif
                                </div>
                            </td>
                            <td>{{ $customer->email }}</td>
                            <td>{{ $customer->phone ?? '-' }}</td>
                            <td>
                                @php
                                    $membershipClass = $customer->membership_type ?? 'exMember';
                                    $membershipName = $customer->membership_info['name'] ?? 'สมาชิกทั่วไป';
                                    $isExpired = $customer->membership_status === 'expired';
                                @endphp
                                <span class="membership-badge {{ $membershipClass }}" style="{{ $isExpired ? 'opacity: 0.6;' : '' }}">
                                    {{ $membershipName }}
                                </span>
                                @if($isExpired)
                                    <div style="font-size: 0.75rem; color: var(--danger); margin-top: 0.25rem;">หมดอายุ</div>
                                @endif
                            </td>
                            <td>{{ $customer->created_at->format('d/m/Y') }}</td>
                            <td>
                                <div class="action-buttons">
                                    <button class="btn-action edit" onclick="editCustomer({{ $customer->id }})" title="แก้ไข">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button class="btn-action membership" onclick="openMembershipModal({{ $customer->id }})" title="จัดการ Membership">
                                        <i class="fas fa-crown"></i>
                                    </button>
                                    <button class="btn-action delete" onclick="deleteCustomer({{ $customer->id }})" title="ลบ">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                                <i class="fas fa-users" style="font-size: 3rem; margin-bottom: 1rem; opacity: 0.3;"></i>
                                <div>ยังไม่มีลูกค้าในระบบ</div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            @if($customers->hasPages())
            <div class="pagination">
                <div class="pagination-info">
                    แสดง {{ $customers->firstItem() }}-{{ $customers->lastItem() }} จาก {{ $customers->total() }} รายการ
                </div>
                <div class="pagination-links">
                    {{ $customers->links('pagination::simple-bootstrap-4') }}
                </div>
            </div>
            @endif
        </div>
    </div>

    <!-- Add/Edit Customer Modal -->
    <div id="customerModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modalTitle">เพิ่มลูกค้าใหม่</h3>
                <span class="close" onclick="closeCustomerModal()">&times;</span>
            </div>
            <form id="customerForm">
                <div class="modal-body">
                    <input type="hidden" id="customerId" name="id">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">ชื่อ-นามสกุล *</label>
                            <input type="text" id="customerName" name="name" class="form-input" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">อีเมล *</label>
                            <input type="email" id="customerEmail" name="email" class="form-input" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">เบอร์โทร</label>
                            <input type="tel" id="customerPhone" name="phone" class="form-input">
                        </div>
                        <div class="form-group">
                            <label class="form-label">รหัสผ่าน</label>
                            <input type="password" id="customerPassword" name="password" class="form-input">
                            <small style="color: var(--text-secondary); font-size: 0.75rem;">เว้นว่างหากไม่ต้องการเปลี่ยน</small>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">ที่อยู่โดยละเอียด</label>
                        <textarea id="customerAddress" name="address" class="form-input" rows="2" placeholder="เลขที่ ซอย ถนน"></textarea>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">จังหวัด *</label>
                            <select id="customerProvinceId" name="province_id" class="form-input" required>
                                <option value="">เลือกจังหวัด</option>
                            </select>
                            <input type="hidden" id="customerProvince" name="province">
                        </div>
                        <div class="form-group">
                            <label class="form-label">อำเภอ/เขต *</label>
                            <select id="customerDistrictId" name="district_id" class="form-input" disabled required>
                                <option value="">เลือกจังหวัดก่อน</option>
                            </select>
                            <input type="hidden" id="customerDistrict" name="district">
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">ตำบล/แขวง *</label>
                            <select id="customerSubDistrictId" name="sub_district_id" class="form-input" disabled required>
                                <option value="">เลือกอำเภอก่อน</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">รหัสไปรษณีย์</label>
                            <input type="text" id="customerPostalCode" name="postal_code" class="form-input" readonly style="background: #f8f9fa;">
                        </div>
                        <div class="form-group">
                            <label class="form-label">ประเภทสมาชิก</label>
                            <select id="customerMembershipType" name="membership_type" class="form-input">
                                <option value="exMember">สมาชิกทั่วไป</option>
                                <option value="exDoctor">หมอ</option>
                                <option value="exVip">VIP</option>
                                <option value="exSupervip">SUPER VIP</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeCustomerModal()">ยกเลิก</button>
                    <button type="submit" class="btn btn-primary" id="saveCustomerBtn">
                        <i class="fas fa-save"></i>
                        บันทึก
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Address Modal -->
    <div id="addressModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="addressModalTitle">ที่อยู่ของลูกค้า</h3>
                <span class="close" onclick="closeAddressModal()">&times;</span>
            </div>
            <div class="modal-body" id="addressModalBody">
                <!-- Address content will be loaded here -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeAddressModal()">ปิด</button>
            </div>
        </div>
    </div>

    <script src="{{ asset('js/admin-customers.js') }}"></script>
    <script>
        // Show customer addresses modal
        function showAddresses(customerId) {
            const modal = document.getElementById('addressModal');
            const modalBody = document.getElementById('addressModalBody');
            const modalTitle = document.getElementById('addressModalTitle');
            
            modal.style.display = 'block';
            modalBody.innerHTML = '<div style="text-align: center; padding: 2rem;"><i class="fas fa-spinner fa-spin"></i> กำลังโหลด...</div>';
            
            // Fetch addresses from API
            fetch(`/api/admin/customers/${customerId}/addresses`, {
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success && data.addresses) {
                    let html = '<div style="display: flex; flex-direction: column; gap: 1rem;">';
                    
                    if (data.addresses.length === 0) {
                        html = '<div style="text-align: center; padding: 2rem; color: var(--text-secondary);">';
                        html += '<i class="fas fa-map-marker-alt" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3;"></i>';
                        html += '<div>ลูกค้ายังไม่มีที่อยู่ในระบบ</div></div>';
                    } else {
                        data.addresses.forEach((address, index) => {
                            const isDefault = address.is_default;
                            html += `
                                <div style="border: 1px solid ${isDefault ? 'var(--primary)' : 'var(--border)'}; 
                                            border-radius: 0.75rem; padding: 1rem; 
                                            background: ${isDefault ? 'rgba(99, 102, 241, 0.05)' : 'var(--white)'};">
                                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.5rem;">
                                        <div style="font-weight: 600; color: var(--text-primary);">
                                            ${address.name}
                                            ${isDefault ? '<span style="background: var(--primary); color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.7rem; margin-left: 0.5rem;">หลัก</span>' : ''}
                                        </div>
                                        <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                            #${index + 1}
                                        </div>
                                    </div>
                                    <div style="font-size: 0.875rem; color: var(--text-secondary); line-height: 1.5;">
                                        <div><strong>ผู้รับ:</strong> ${address.recipient_name}</div>
                                        <div><strong>โทร:</strong> ${address.phone}</div>
                                        <div style="margin-top: 0.5rem;">
                                            ${address.address_line_1}
                                            ${address.address_line_2 ? '<br>' + address.address_line_2 : ''}
                                            <br>${address.district}, ${address.province} ${address.postal_code}
                                        </div>
                                    </div>
                                </div>
                            `;
                        });
                    }
                    
                    html += '</div>';
                    modalBody.innerHTML = html;
                    modalTitle.innerHTML = `ที่อยู่ของ ${data.customer_name} (${data.addresses.length}/3)`;
                } else {
                    modalBody.innerHTML = '<div style="color: var(--danger); text-align: center; padding: 2rem;">เกิดข้อผิดพลาดในการโหลดข้อมูล</div>';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                modalBody.innerHTML = '<div style="color: var(--danger); text-align: center; padding: 2rem;">เกิดข้อผิดพลาดในการโหลดข้อมูล</div>';
            });
        }
        
        function closeAddressModal() {
            document.getElementById('addressModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const addressModal = document.getElementById('addressModal');
            if (event.target == addressModal) {
                addressModal.style.display = 'none';
            }
        }
    </script>
</body>
</html>
