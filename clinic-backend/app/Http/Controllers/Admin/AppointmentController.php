<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;

class AppointmentController extends Controller
{
    public function index()
    {
        $appointments = Appointment::with('patient')->latest()->paginate(10);
        return view('admin.appointments.index', compact('appointments'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'patient_id' => 'required|exists:patients,id',
            'appointment_date' => 'required|date',
            'appointment_time' => 'required',
            'service_type' => 'required|string',
            'notes' => 'nullable|string',
        ]);

        $appointment = Appointment::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'เพิ่มนัดหมายสำเร็จ',
            'data' => $appointment
        ]);
    }

    public function show($id)
    {
        $appointment = Appointment::with('patient')->findOrFail($id);
        return view('admin.appointments.show', compact('appointment'));
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'appointment_date' => 'required|date',
            'appointment_time' => 'required',
            'service_type' => 'required|string',
            'status' => 'required|in:scheduled,confirmed,completed,cancelled',
            'notes' => 'nullable|string',
        ]);

        $appointment = Appointment::findOrFail($id);
        $appointment->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'อัปเดตนัดหมายสำเร็จ',
            'data' => $appointment
        ]);
    }

    public function destroy($id)
    {
        $appointment = Appointment::findOrFail($id);
        $appointment->delete();

        return response()->json([
            'success' => true,
            'message' => 'ลบนัดหมายสำเร็จ'
        ]);
    }
}