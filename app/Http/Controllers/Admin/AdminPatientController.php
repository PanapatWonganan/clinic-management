<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Patient;
use Illuminate\Http\Request;

class AdminPatientController extends Controller
{
    public function index()
    {
        $patients = Patient::with('appointments')->paginate(15);
        return view('admin.patients.index', compact('patients'));
    }

    public function create()
    {
        return view('admin.patients.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:patients',
            'phone' => 'required|string|max:20',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female,other',
            'address' => 'nullable|string',
            'emergency_contact' => 'nullable|string|max:255'
        ]);

        Patient::create($validated);

        return redirect()->route('admin.patients.index')
                        ->with('success', 'ผู้ป่วยได้ถูกเพิ่มเรียบร้อยแล้ว');
    }

    public function show(Patient $patient)
    {
        $patient->load('appointments');
        return view('admin.patients.show', compact('patient'));
    }

    public function edit(Patient $patient)
    {
        return view('admin.patients.edit', compact('patient'));
    }

    public function update(Request $request, Patient $patient)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:patients,email,' . $patient->id,
            'phone' => 'required|string|max:20',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female,other',
            'address' => 'nullable|string',
            'emergency_contact' => 'nullable|string|max:255'
        ]);

        $patient->update($validated);

        return redirect()->route('admin.patients.index')
                        ->with('success', 'ข้อมูลผู้ป่วยได้ถูกอัปเดตเรียบร้อยแล้ว');
    }

    public function destroy(Patient $patient)
    {
        $patient->delete();

        return redirect()->route('admin.patients.index')
                        ->with('success', 'ผู้ป่วยได้ถูกลบเรียบร้อยแล้ว');
    }
} 