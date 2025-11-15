@extends('layouts.admin')

@section('title', 'จัดการการนัดหมาย')
@section('page-title', 'จัดการการนัดหมาย')

@section('page-actions')
    <a href="{{ route('admin.appointments.create') }}" class="btn btn-primary">
        <i class="fas fa-plus me-1"></i> เพิ่มการนัดหมายใหม่
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
                        <th>ผู้ป่วย</th>
                        <th>หมอ</th>
                        <th>วันที่นัดหมาย</th>
                        <th>เวลา</th>
                        <th>สถานะ</th>
                        <th>หมายเหตุ</th>
                        <th>จัดการ</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($appointments as $appointment)
                    <tr>
                        <td>{{ $appointment->id }}</td>
                        <td>
                            <strong>{{ $appointment->patient->full_name ?? 'ไม่ระบุ' }}</strong>
                            <br>
                            <small class="text-muted">{{ $appointment->patient->email ?? '' }}</small>
                        </td>
                        <td>{{ $appointment->doctor_name }}</td>
                        <td>{{ $appointment->appointment_datetime->format('d/m/Y') }}</td>
                        <td>{{ $appointment->appointment_datetime->format('H:i') }}</td>
                        <td>
                            @if($appointment->status == 'scheduled')
                                <span class="badge bg-warning">กำหนดการ</span>
                            @elseif($appointment->status == 'completed')
                                <span class="badge bg-success">เสร็จสิ้น</span>
                            @else
                                <span class="badge bg-danger">ยกเลิก</span>
                            @endif
                        </td>
                        <td>
                            {{ Str::limit($appointment->notes, 30) }}
                        </td>
                        <td>
                            <div class="btn-group" role="group">
                                <a href="{{ route('admin.appointments.show', $appointment) }}" 
                                   class="btn btn-sm btn-outline-info"
                                   title="ดูรายละเอียด">
                                    <i class="fas fa-eye"></i>
                                </a>
                                <a href="{{ route('admin.appointments.edit', $appointment) }}" 
                                   class="btn btn-sm btn-outline-warning"
                                   title="แก้ไข">
                                    <i class="fas fa-edit"></i>
                                </a>
                                <form action="{{ route('admin.appointments.destroy', $appointment) }}" 
                                      method="POST" 
                                      style="display: inline;"
                                      onsubmit="return confirm('คุณแน่ใจหรือไม่ที่จะลบการนัดหมายนี้?')">
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
                            <i class="fas fa-calendar-alt fa-3x mb-3"></i>
                            <div>ยังไม่มีการนัดหมาย</div>
                            <a href="{{ route('admin.appointments.create') }}" class="btn btn-primary mt-2">
                                เพิ่มการนัดหมายแรก
                            </a>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($appointments->hasPages())
        <div class="d-flex justify-content-center">
            {{ $appointments->links() }}
        </div>
        @endif
    </div>
</div>
@endsection 