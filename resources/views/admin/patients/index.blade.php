@extends('layouts.admin')

@section('title', 'จัดการผู้ป่วย')
@section('page-title', 'จัดการผู้ป่วย')

@section('page-actions')
    <a href="{{ route('admin.patients.create') }}" class="btn btn-primary">
        <i class="fas fa-plus me-1"></i> เพิ่มผู้ป่วยใหม่
    </a>
@endsection

@section('content')
<div class="card">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-light">
                    <tr>
                        <th>ID</th>
                        <th>ชื่อ</th>
                        <th>อีเมล</th>
                        <th>เบอร์โทร</th>
                        <th>เพศ</th>
                        <th>วันเกิด</th>
                        <th>การนัดหมาย</th>
                        <th>จัดการ</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($patients as $patient)
                    <tr>
                        <td>{{ $patient->id }}</td>
                        <td>
                            <strong>{{ $patient->full_name }}</strong>
                        </td>
                        <td>{{ $patient->email }}</td>
                        <td>{{ $patient->phone }}</td>
                        <td>
                            @if($patient->gender == 'male')
                                <span class="badge bg-primary">ชาย</span>
                            @elseif($patient->gender == 'female')
                                <span class="badge bg-info">หญิง</span>
                            @else
                                <span class="badge bg-secondary">อื่นๆ</span>
                            @endif
                        </td>
                        <td>{{ $patient->date_of_birth->format('d/m/Y') }}</td>
                        <td>
                            <span class="badge bg-success">{{ $patient->appointments_count ?? 0 }}</span>
                        </td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="{{ route('admin.patients.show', $patient) }}" 
                                   class="btn btn-sm btn-outline-info"
                                   title="ดูรายละเอียด">
                                    <i class="fas fa-eye"></i>
                                </a>
                                <a href="{{ route('admin.patients.edit', $patient) }}" 
                                   class="btn btn-sm btn-outline-warning"
                                   title="แก้ไข">
                                    <i class="fas fa-edit"></i>
                                </a>
                                <form action="{{ route('admin.patients.destroy', $patient) }}" 
                                      method="POST" 
                                      style="display: inline;"
                                      onsubmit="return confirm('คุณแน่ใจหรือไม่ที่จะลบผู้ป่วยคนนี้?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="btn btn-sm btn-outline-danger"
                                            title="ลบ">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8" class="text-center text-muted py-4">
                            <i class="fas fa-users fa-3x mb-3"></i>
                            <div>ยังไม่มีข้อมูลผู้ป่วย</div>
                            <a href="{{ route('admin.patients.create') }}" class="btn btn-primary mt-2">
                                เพิ่มผู้ป่วยคนแรก
                            </a>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($patients->hasPages())
        <div class="d-flex justify-content-center">
            {{ $patients->links() }}
        </div>
        @endif
    </div>
</div>
@endsection 