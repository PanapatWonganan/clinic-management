@extends('layouts.admin')

@section('title', 'เพิ่มสินค้าใหม่')
@section('page-title', 'เพิ่มสินค้าใหม่')

@section('page-actions')
    <a href="{{ route('admin.products.index') }}" class="btn btn-secondary">
        <i class="fas fa-arrow-left me-2"></i>กลับ
    </a>
@endsection

@section('content')
<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">
                    <i class="fas fa-plus-circle me-2"></i>เพิ่มสินค้าใหม่
                </h5>
            </div>
            <div class="card-body">
                <form action="{{ route('admin.products.store') }}" method="POST">
                    @csrf
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="name" class="form-label">
                                    <i class="fas fa-tag me-2"></i>ชื่อสินค้า <span class="text-danger">*</span>
                                </label>
                                <input type="text" 
                                       class="form-control @error('name') is-invalid @enderror" 
                                       id="name" 
                                       name="name" 
                                       value="{{ old('name') }}" 
                                       placeholder="เช่น Fine บาง"
                                       required>
                                @error('name')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="price" class="form-label">
                                    <i class="fas fa-money-bill-wave me-2"></i>ราคา (บาท) <span class="text-danger">*</span>
                                </label>
                                <input type="number" 
                                       class="form-control @error('price') is-invalid @enderror" 
                                       id="price" 
                                       name="price" 
                                       value="{{ old('price', 2500) }}" 
                                       min="0" 
                                       step="0.01"
                                       placeholder="2500"
                                       required>
                                @error('price')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="stock_quantity" class="form-label">
                                    <i class="fas fa-boxes me-2"></i>จำนวนสต็อก <span class="text-danger">*</span>
                                </label>
                                <input type="number" 
                                       class="form-control @error('stock_quantity') is-invalid @enderror" 
                                       id="stock_quantity" 
                                       name="stock_quantity" 
                                       value="{{ old('stock_quantity', 100) }}" 
                                       min="0"
                                       placeholder="100"
                                       required>
                                @error('stock_quantity')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="image_path" class="form-label">
                                    <i class="fas fa-image me-2"></i>รูปภาพ (path)
                                </label>
                                <input type="text" 
                                       class="form-control @error('image_path') is-invalid @enderror" 
                                       id="image_path" 
                                       name="image_path" 
                                       value="{{ old('image_path') }}" 
                                       placeholder="assets/images/mask-group.png">
                                @error('image_path')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <div class="form-text">
                                    ใส่ path ของรูปภาพ เช่น assets/images/product.png
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="description" class="form-label">
                            <i class="fas fa-align-left me-2"></i>รายละเอียดสินค้า
                        </label>
                        <textarea class="form-control @error('description') is-invalid @enderror" 
                                  id="description" 
                                  name="description" 
                                  rows="4"
                                  placeholder="อธิบายรายละเอียดของสินค้า...">{{ old('description') }}</textarea>
                        @error('description')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-4">
                        <div class="form-check form-switch">
                            <input class="form-check-input" 
                                   type="checkbox" 
                                   id="is_active" 
                                   name="is_active" 
                                   {{ old('is_active', true) ? 'checked' : '' }}>
                            <label class="form-check-label" for="is_active">
                                <i class="fas fa-toggle-on me-2"></i>เปิดขายสินค้า
                            </label>
                        </div>
                    </div>

                    <hr>

                    <div class="d-flex justify-content-end gap-2">
                        <a href="{{ route('admin.products.index') }}" class="btn btn-secondary">
                            <i class="fas fa-times me-2"></i>ยกเลิก
                        </a>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-2"></i>บันทึกสินค้า
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Preview Card -->
        <div class="card mt-4">
            <div class="card-header">
                <h6 class="mb-0">
                    <i class="fas fa-eye me-2"></i>ตัวอย่างสินค้า
                </h6>
            </div>
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-3">
                        <div class="bg-light rounded d-flex align-items-center justify-content-center" 
                             style="width: 100%; height: 120px;">
                            <i class="fas fa-image fa-2x text-muted"></i>
                        </div>
                    </div>
                    <div class="col-md-9">
                        <h5 class="preview-name">ชื่อสินค้า</h5>
                        <p class="text-muted preview-description">รายละเอียดสินค้า...</p>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="h4 text-success preview-price">฿2,500</span>
                            <span class="badge bg-primary preview-stock">100 ชิ้น</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Live preview
    const nameInput = document.getElementById('name');
    const priceInput = document.getElementById('price');
    const stockInput = document.getElementById('stock_quantity');
    const descriptionInput = document.getElementById('description');
    
    const previewName = document.querySelector('.preview-name');
    const previewPrice = document.querySelector('.preview-price');
    const previewStock = document.querySelector('.preview-stock');
    const previewDescription = document.querySelector('.preview-description');
    
    function updatePreview() {
        previewName.textContent = nameInput.value || 'ชื่อสินค้า';
        previewPrice.textContent = '฿' + (priceInput.value ? Number(priceInput.value).toLocaleString() : '0');
        previewStock.textContent = (stockInput.value || '0') + ' ชิ้น';
        previewDescription.textContent = descriptionInput.value || 'รายละเอียดสินค้า...';
    }
    
    nameInput.addEventListener('input', updatePreview);
    priceInput.addEventListener('input', updatePreview);
    stockInput.addEventListener('input', updatePreview);
    descriptionInput.addEventListener('input', updatePreview);
});
</script>
@endsection 