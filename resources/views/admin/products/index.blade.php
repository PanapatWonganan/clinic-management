@extends('layouts.admin')

@section('title', 'จัดการสินค้า')
@section('page-title', 'จัดการสินค้า')

@section('page-actions')
    <a href="{{ route('admin.products.create') }}" class="btn btn-primary">
        <i class="fas fa-plus me-2"></i>เพิ่มสินค้าใหม่
    </a>
@endsection

@section('content')
<div class="row mb-4">
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <i class="fas fa-boxes fa-2x text-primary mb-3"></i>
                <h4 class="text-primary">{{ number_format($products->total()) }}</h4>
                <p class="mb-0 text-muted">สินค้าทั้งหมด</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <i class="fas fa-check-circle fa-2x text-success mb-3"></i>
                <h4 class="text-success">{{ number_format($products->where('is_active', true)->count()) }}</h4>
                <p class="mb-0 text-muted">เปิดขาย</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <i class="fas fa-pause-circle fa-2x text-warning mb-3"></i>
                <h4 class="text-warning">{{ number_format($products->where('is_active', false)->count()) }}</h4>
                <p class="mb-0 text-muted">หยุดขาย</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <i class="fas fa-exclamation-triangle fa-2x text-danger mb-3"></i>
                <h4 class="text-danger">{{ number_format($products->where('stock_quantity', '<=', 10)->count()) }}</h4>
                <p class="mb-0 text-muted">สต็อกต่ำ</p>
            </div>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">
            <i class="fas fa-list me-2"></i>รายการสินค้า
        </h5>
        <div class="d-flex gap-2">
            <input type="text" class="form-control form-control-sm" placeholder="ค้นหาสินค้า..." style="width: 200px;">
            <button class="btn btn-outline-primary btn-sm">
                <i class="fas fa-search"></i>
            </button>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>รูปภาพ</th>
                        <th>ชื่อสินค้า</th>
                        <th>ราคา</th>
                        <th>สต็อก</th>
                        <th>สถานะ</th>
                        <th>วันที่เพิ่ม</th>
                        <th class="text-center">จัดการ</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($products as $product)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                @if($product->image_path)
                                    <img src="{{ asset($product->image_path) }}" 
                                         alt="{{ $product->name }}" 
                                         class="rounded" 
                                         style="width: 50px; height: 50px; object-fit: cover;">
                                @else
                                    <div class="bg-light rounded d-flex align-items-center justify-content-center" 
                                         style="width: 50px; height: 50px;">
                                        <i class="fas fa-image text-muted"></i>
                                    </div>
                                @endif
                            </div>
                        </td>
                        <td>
                            <div>
                                <strong>{{ $product->name }}</strong>
                                @if($product->description)
                                    <br>
                                    <small class="text-muted">{{ Str::limit($product->description, 50) }}</small>
                                @endif
                            </div>
                        </td>
                        <td>
                            <strong class="text-success">฿{{ number_format($product->price, 0) }}</strong>
                        </td>
                        <td>
                            <span class="badge {{ $product->stock_quantity <= 10 ? 'bg-danger' : ($product->stock_quantity <= 50 ? 'bg-warning' : 'bg-success') }}">
                                {{ number_format($product->stock_quantity) }} ชิ้น
                            </span>
                        </td>
                        <td>
                            <form action="{{ route('admin.products.toggle-status', $product) }}" method="POST" style="display: inline;">
                                @csrf
                                @method('PATCH')
                                <button type="submit" class="btn btn-sm {{ $product->is_active ? 'btn-success' : 'btn-secondary' }}">
                                    <i class="fas {{ $product->is_active ? 'fa-check' : 'fa-pause' }}"></i>
                                    {{ $product->is_active ? 'เปิดขาย' : 'หยุดขาย' }}
                                </button>
                            </form>
                        </td>
                        <td>{{ $product->created_at->format('d/m/Y') }}</td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="{{ route('admin.products.show', $product) }}" 
                                   class="btn btn-sm btn-outline-info"
                                   title="ดูรายละเอียด">
                                    <i class="fas fa-eye"></i>
                                </a>
                                <a href="{{ route('admin.products.edit', $product) }}" 
                                   class="btn btn-sm btn-outline-warning"
                                   title="แก้ไข">
                                    <i class="fas fa-edit"></i>
                                </a>
                                <button type="button" 
                                        class="btn btn-sm btn-outline-primary"
                                        data-bs-toggle="modal" 
                                        data-bs-target="#stockModal{{ $product->id }}"
                                        title="อัปเดตสต็อก">
                                    <i class="fas fa-boxes"></i>
                                </button>
                                @if($product->orderItems()->count() == 0)
                                <form action="{{ route('admin.products.destroy', $product) }}" 
                                      method="POST" 
                                      style="display: inline;"
                                      onsubmit="return confirm('คุณแน่ใจหรือไม่ที่จะลบสินค้านี้?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="btn btn-sm btn-outline-danger"
                                            title="ลบ">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </form>
                                @endif
                            </div>
                        </td>
                    </tr>

                    <!-- Stock Update Modal -->
                    <div class="modal fade" id="stockModal{{ $product->id }}" tabindex="-1">
                        <div class="modal-dialog modal-sm">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">อัปเดตสต็อก</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <form action="{{ route('admin.products.update-stock', $product) }}" method="POST">
                                    @csrf
                                    @method('PATCH')
                                    <div class="modal-body">
                                        <div class="mb-3">
                                            <label class="form-label">{{ $product->name }}</label>
                                            <input type="number" 
                                                   class="form-control" 
                                                   name="stock_quantity" 
                                                   value="{{ $product->stock_quantity }}" 
                                                   min="0" 
                                                   required>
                                        </div>
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">ยกเลิก</button>
                                        <button type="submit" class="btn btn-primary">อัปเดต</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                    @empty
                    <tr>
                        <td colspan="7" class="text-center text-muted py-5">
                            <i class="fas fa-boxes fa-3x mb-3 d-block"></i>
                            <h5>ยังไม่มีสินค้า</h5>
                            <p>เริ่มต้นด้วยการเพิ่มสินค้าแรกของคุณ</p>
                            <a href="{{ route('admin.products.create') }}" class="btn btn-primary">
                                <i class="fas fa-plus me-2"></i>เพิ่มสินค้าใหม่
                            </a>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($products->hasPages())
        <div class="d-flex justify-content-center mt-4">
            {{ $products->links() }}
        </div>
        @endif
    </div>
</div>
@endsection 