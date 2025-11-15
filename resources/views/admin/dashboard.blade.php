@extends('layouts.admin')

@section('title', 'Dashboard')
@section('page-title', 'Dashboard')

@section('content')
<div class="row mb-4">
    <!-- Statistics Cards -->
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card stat-card">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="h5 mb-0 font-weight-bold text-white">{{ $totalPatients }}</div>
                        <div class="text-white-50">ผู้ป่วยทั้งหมด</div>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-users fa-2x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card" style="background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="h5 mb-0 font-weight-bold text-dark">{{ $totalAppointments }}</div>
                        <div class="text-dark">การนัดหมายทั้งหมด</div>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-calendar-alt fa-2x text-dark"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card" style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="h5 mb-0 font-weight-bold text-dark">{{ $todayAppointments }}</div>
                        <div class="text-dark">นัดหมายวันนี้</div>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-clock fa-2x text-dark"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card" style="background: linear-gradient(135deg, #ffeaa7 0%, #fab1a0 100%);">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="h5 mb-0 font-weight-bold text-dark">{{ $upcomingAppointments }}</div>
                        <div class="text-dark">นัดหมายที่จะมาถึง</div>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-calendar-check fa-2x text-dark"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <!-- Recent Patients -->
    <div class="col-xl-6 col-lg-12">
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0">ผู้ป่วยล่าสุด</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>ชื่อ</th>
                                <th>อีเมล</th>
                                <th>เบอร์โทร</th>
                                <th>วันที่เพิ่ม</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($recentPatients as $patient)
                            <tr>
                                <td>{{ $patient->full_name }}</td>
                                <td>{{ $patient->email }}</td>
                                <td>{{ $patient->phone }}</td>
                                <td>{{ $patient->created_at->format('d/m/Y') }}</td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center text-muted">ยังไม่มีข้อมูลผู้ป่วย</td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="text-center">
                    <a href="{{ route('admin.patients.index') }}" class="btn btn-primary btn-sm">
                        ดูผู้ป่วยทั้งหมด
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Appointments -->
    <div class="col-xl-6 col-lg-12">
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0">การนัดหมายล่าสุด</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>ผู้ป่วย</th>
                                <th>หมอ</th>
                                <th>วันที่นัด</th>
                                <th>สถานะ</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($recentAppointments as $appointment)
                            <tr>
                                <td>{{ $appointment->patient->full_name ?? 'ไม่ระบุ' }}</td>
                                <td>{{ $appointment->doctor_name }}</td>
                                <td>{{ $appointment->appointment_datetime->format('d/m/Y H:i') }}</td>
                                <td>
                                    @if($appointment->status == 'scheduled')
                                        <span class="badge bg-warning">กำหนดการ</span>
                                    @elseif($appointment->status == 'completed')
                                        <span class="badge bg-success">เสร็จสิ้น</span>
                                    @else
                                        <span class="badge bg-danger">ยกเลิก</span>
                                    @endif
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center text-muted">ยังไม่มีการนัดหมาย</td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="text-center">
                    <a href="{{ route('admin.appointments.index') }}" class="btn btn-primary btn-sm">
                        ดูการนัดหมายทั้งหมด
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection 