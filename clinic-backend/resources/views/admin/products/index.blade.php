<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการสินค้า - Exquiller Admin</title>
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
        .stat-icon.danger { background: linear-gradient(135deg, var(--danger), #f87171); }

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

        .product-info {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .product-image {
            width: 50px;
            height: 50px;
            border-radius: 0.5rem;
            object-fit: cover;
            background: var(--background);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-secondary);
        }

        .product-details {
            flex: 1;
        }

        .product-name {
            font-weight: 600;
            margin-bottom: 0.25rem;
        }

        .product-category {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }

        .category-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }

        .category-badge.main {
            background: #dbeafe;
            color: #1e40af;
        }

        .category-badge.rewards {
            background: #fef3c7;
            color: #92400e;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }

        .status-badge.active {
            background: #d1fae5;
            color: #065f46;
        }

        .status-badge.inactive {
            background: #fee2e2;
            color: #991b1b;
        }

        .stock-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }

        .stock-badge.normal {
            background: #d1fae5;
            color: #065f46;
        }

        .stock-badge.low {
            background: #fef3c7;
            color: #92400e;
        }

        .stock-badge.out {
            background: #fee2e2;
            color: #991b1b;
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
                <i class="fas fa-box"></i>
                จัดการสินค้า
            </h1>
            <div class="header-actions">
                <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i>
                    กลับหน้าหลัก
                </a>
                <button class="btn btn-primary" onclick="openProductModal()">
                    <i class="fas fa-plus"></i>
                    เพิ่มสินค้าใหม่
                </button>
            </div>
        </div>

        <!-- Stats -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon primary">
                        <i class="fas fa-box"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['total_products'] }}</div>
                <div class="stat-label">สินค้าทั้งหมด</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon accent">
                        <i class="fas fa-check-circle"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['active_products'] }}</div>
                <div class="stat-label">สินค้าที่เปิดขาย</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon warning">
                        <i class="fas fa-exclamation-triangle"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['low_stock_products'] }}</div>
                <div class="stat-label">สินค้าใกล้หมด</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <div class="stat-icon danger">
                        <i class="fas fa-times-circle"></i>
                    </div>
                </div>
                <div class="stat-value">{{ $stats['out_of_stock_products'] }}</div>
                <div class="stat-label">สินค้าหมดสต็อก</div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <div class="content-header">
                <h2>รายการสินค้า ({{ $products->total() }} รายการ)</h2>
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" placeholder="ค้นหาสินค้า..." id="searchProduct" onkeyup="searchProducts()">
                </div>
            </div>

            <div class="table-container">
                <table class="table">
                    <thead>
                        <tr>
                            <th>สินค้า</th>
                            <th>ราคา</th>
                            <th>สต็อก</th>
                            <th>หมวดหมู่</th>
                            <th>สถานะ</th>
                            <th>จัดการ</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($products as $product)
                        <tr id="product-row-{{ $product->id }}">
                            <td>
                                <div class="product-info">
                                    <div class="product-image">
                                        @if($product->image_url)
                                            <img src="{{ asset($product->image_url) }}" alt="{{ $product->name }}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 0.5rem;">
                                        @else
                                            <i class="fas fa-image"></i>
                                        @endif
                                    </div>
                                    <div class="product-details">
                                        <div class="product-name">{{ $product->name }}</div>
                                        @if($product->description)
                                            <div class="product-category">{{ Str::limit($product->description, 50) }}</div>
                                        @endif
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600;">฿{{ number_format($product->price, 0) }}</div>
                            </td>
                            <td>
                                @php
                                    $stockClass = 'normal';
                                    if ($product->stock == 0) $stockClass = 'out';
                                    elseif ($product->stock <= 10) $stockClass = 'low';
                                @endphp
                                <span class="stock-badge {{ $stockClass }}">{{ $product->stock }} ชิ้น</span>
                            </td>
                            <td>
                                <span class="category-badge {{ $product->category }}">
                                    {{ $product->category == 'main' ? 'สินค้าหลัก' : 'สินค้ารางวัล' }}
                                </span>
                            </td>
                            <td>
                                <span class="status-badge {{ $product->is_active ? 'active' : 'inactive' }}">
                                    {{ $product->is_active ? 'เปิดขาย' : 'ปิดขาย' }}
                                </span>
                            </td>
                            <td>
                                <div class="action-buttons">
                                    <button class="btn-action edit" onclick="editProduct({{ $product->id }})" title="แก้ไข">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button class="btn-action delete" onclick="deleteProduct({{ $product->id }})" title="ลบ">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                                <i class="fas fa-box" style="font-size: 3rem; margin-bottom: 1rem; opacity: 0.3;"></i>
                                <div>ยังไม่มีสินค้าในระบบ</div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            @if($products->hasPages())
            <div class="pagination">
                <div class="pagination-info">
                    แสดง {{ $products->firstItem() }}-{{ $products->lastItem() }} จาก {{ $products->total() }} รายการ
                </div>
                <div class="pagination-links">
                    {{ $products->links('pagination::simple-bootstrap-4') }}
                </div>
            </div>
            @endif
        </div>
    </div>

    <!-- Add/Edit Product Modal -->
    <div id="productModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modalTitle">เพิ่มสินค้าใหม่</h3>
                <span class="close" onclick="closeProductModal()">&times;</span>
            </div>
            <form id="productForm">
                <div class="modal-body">
                    <input type="hidden" id="productId" name="id">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">ชื่อสินค้า *</label>
                            <input type="text" id="productName" name="name" class="form-input" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">ราคา (บาท) *</label>
                            <input type="number" id="productPrice" name="price" class="form-input" min="0" step="0.01" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">จำนวนสต็อก *</label>
                            <input type="number" id="productStock" name="stock" class="form-input" min="0" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">หมวดหมู่ *</label>
                            <select id="productCategory" name="category" class="form-input" required>
                                <option value="">เลือกหมวดหมู่</option>
                                <option value="main">สินค้าหลัก</option>
                                <option value="rewards">สินค้ารางวัล</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">รายละเอียดสินค้า</label>
                        <textarea id="productDescription" name="description" class="form-input" rows="3" placeholder="อธิบายรายละเอียดสินค้า..."></textarea>
                    </div>

                    <div class="form-group">
                        <label class="form-label">รูปภาพสินค้า</label>
                        <input type="file" id="productImage" name="image" class="form-input" accept="image/*" onchange="previewImage(event)">
                        <small style="color: var(--text-secondary); font-size: 0.75rem;">รองรับไฟล์ JPG, PNG, GIF ขนาดไม่เกิน 2MB</small>
                        <div id="imagePreview" style="margin-top: 1rem; display: none;">
                            <img id="previewImg" src="" alt="Preview" style="max-width: 200px; max-height: 200px; border-radius: 0.5rem;">
                        </div>
                        <div id="currentImageDisplay" style="margin-top: 1rem; display: none;">
                            <label style="color: var(--text-secondary); font-size: 0.875rem;">รูปภาพปัจจุบัน:</label>
                            <img id="currentImg" src="" alt="Current" style="max-width: 200px; max-height: 200px; border-radius: 0.5rem; display: block; margin-top: 0.5rem;">
                        </div>
                    </div>

                    <div class="form-group">
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox" id="productActive" name="is_active" checked>
                            เปิดขายสินค้า
                        </label>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeProductModal()">ยกเลิก</button>
                    <button type="submit" class="btn btn-primary" id="saveProductBtn">
                        <i class="fas fa-save"></i>
                        บันทึก
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let currentProductId = null;

        // Open modal for adding new product
        function openProductModal() {
            const modal = document.getElementById('productModal');
            const form = document.getElementById('productForm');
            const title = document.getElementById('modalTitle');
            const saveBtn = document.getElementById('saveProductBtn');

            title.textContent = 'เพิ่มสินค้าใหม่';
            saveBtn.innerHTML = '<i class="fas fa-save"></i> บันทึก';
            form.reset();
            document.getElementById('productId').value = '';
            document.getElementById('productActive').checked = true;
            currentProductId = null;

            // Hide both image previews
            document.getElementById('imagePreview').style.display = 'none';
            document.getElementById('currentImageDisplay').style.display = 'none';

            modal.style.display = 'block';
        }

        // Edit product
        function editProduct(id) {
            currentProductId = id;

            fetch(`/api/products/${id}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const product = data.data;

                        document.getElementById('productId').value = product.id;
                        document.getElementById('productName').value = product.name || '';
                        document.getElementById('productPrice').value = product.price || '';
                        document.getElementById('productStock').value = product.stock || '';
                        document.getElementById('productCategory').value = product.category || '';
                        document.getElementById('productDescription').value = product.description || '';
                        document.getElementById('productActive').checked = product.is_active;

                        // Show current image if exists
                        if (product.image_url) {
                            document.getElementById('currentImg').src = product.image_url;
                            document.getElementById('currentImageDisplay').style.display = 'block';
                        } else {
                            document.getElementById('currentImageDisplay').style.display = 'none';
                        }

                        // Hide preview image
                        document.getElementById('imagePreview').style.display = 'none';
                        document.getElementById('productImage').value = '';

                        document.getElementById('modalTitle').textContent = 'แก้ไขสินค้า';
                        document.getElementById('saveProductBtn').innerHTML = '<i class="fas fa-save"></i> อัพเดต';

                        document.getElementById('productModal').style.display = 'block';
                    } else {
                        alert('ไม่สามารถโหลดข้อมูลสินค้าได้');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('เกิดข้อผิดพลาด');
                });
        }

        // Delete product
        function deleteProduct(id) {
            if (confirm('คุณแน่ใจหรือไม่ที่จะลบสินค้านี้?')) {
                fetch(`/admin/products/${id}`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                    }
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById(`product-row-${id}`).remove();
                        alert('ลบสินค้าเรียบร้อยแล้ว');
                    } else {
                        alert('ไม่สามารถลบสินค้าได้: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('เกิดข้อผิดพลาด');
                });
            }
        }

        // Close modal
        function closeProductModal() {
            document.getElementById('productModal').style.display = 'none';
        }

        // Image preview function
        function previewImage(event) {
            const file = event.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById('previewImg').src = e.target.result;
                    document.getElementById('imagePreview').style.display = 'block';
                }
                reader.readAsDataURL(file);
            }
        }

        // Handle form submission
        document.getElementById('productForm').addEventListener('submit', function(e) {
            e.preventDefault();

            const formData = new FormData(this);
            const productId = formData.get('id');
            const isEdit = productId && productId.trim() !== '';

            // Use API routes for consistency
            const url = isEdit ? `/api/products/${productId}` : '/api/products';
            const method = 'POST';

            // Add method override for PUT request
            if (isEdit) {
                formData.append('_method', 'PUT');
            }

            // Add checkbox value
            formData.set('is_active', document.getElementById('productActive').checked ? '1' : '0');

            fetch(url, {
                method: method,
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
                    'Accept': 'application/json'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    closeProductModal();
                    alert(isEdit ? 'อัพเดตสินค้าเรียบร้อยแล้ว' : 'เพิ่มสินค้าเรียบร้อยแล้ว');
                    window.location.reload();
                } else {
                    let errorMessage = data.message;
                    if (data.errors) {
                        errorMessage += '\n\nรายละเอียด:\n';
                        Object.keys(data.errors).forEach(field => {
                            errorMessage += `- ${data.errors[field].join(', ')}\n`;
                        });
                    }
                    alert(errorMessage);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('เกิดข้อผิดพลาด');
            });
        });

        // Search functionality
        function searchProducts() {
            const searchTerm = document.getElementById('searchProduct').value.toLowerCase();
            const rows = document.querySelectorAll('tbody tr');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(searchTerm) ? '' : 'none';
            });
        }

        // Close modal when clicking outside
        window.addEventListener('click', function(event) {
            const modal = document.getElementById('productModal');
            if (event.target === modal) {
                closeProductModal();
            }
        });
    </script>
</body>
</html>