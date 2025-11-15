<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Patient;
use Illuminate\Http\Request;

class AdminAppointmentController extends Controller
{
    public function index()
    {
        $appointments = Appointment::with('patient')->latest()->paginate(15);
        return view('admin.appointments.index', compact('appointments'));
    }

    public function create()
    {
        $patients = Patient::all();
        return view('admin.appointments.create', compact('patients'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'patient_id' => 'required|exists:patients,id',
            'doctor_name' => 'required|string|max:255',
            'appointment_datetime' => 'required|date|after:now',
            'status' => 'required|in:scheduled,completed,cancelled',
            'notes' => 'nullable|string'
        ]);

        Appointment::create($validated);

        return redirect()->route('admin.appointments.index')
                        ->with('success', 'การนัดหมายได้ถูกสร้างเรียบร้อยแล้ว');
    }

    public function show(Appointment $appointment)
    {
        $appointment->load('patient');
        return view('admin.appointments.show', compact('appointment'));
    }

    public function edit(Appointment $appointment)
    {
        $patients = Patient::all();
        return view('admin.appointments.edit', compact('appointment', 'patients'));
    }

    public function update(Request $request, Appointment $appointment)
    {
        $validated = $request->validate([
            'patient_id' => 'required|exists:patients,id',
            'doctor_name' => 'required|string|max:255',
            'appointment_datetime' => 'required|date',
            'status' => 'required|in:scheduled,completed,cancelled',
            'notes' => 'nullable|string'
        ]);

        $appointment->update($validated);

        return redirect()->route('admin.appointments.index')
                        ->with('success', 'การนัดหมายได้ถูกอัปเดตเรียบร้อยแล้ว');
    }

    public function destroy(Appointment $appointment)
    {
        $appointment->delete();

        return redirect()->route('admin.appointments.index')
                        ->with('success', 'การนัดหมายได้ถูกลบเรียบร้อยแล้ว');
    }
} 