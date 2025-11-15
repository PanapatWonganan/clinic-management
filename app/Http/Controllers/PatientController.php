<?php

namespace App\Http\Controllers;

use App\Models\Patient;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PatientController extends Controller
{
    public function index(): JsonResponse
    {
        $patients = Patient::with('appointments')->get();
        return response()->json(['data' => $patients]);
    }

    public function store(Request $request): JsonResponse
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

        $patient = Patient::create($validated);
        return response()->json(['data' => $patient], 201);
    }

    public function show(Patient $patient): JsonResponse
    {
        $patient->load('appointments');
        return response()->json(['data' => $patient]);
    }

    public function update(Request $request, Patient $patient): JsonResponse
    {
        $validated = $request->validate([
            'first_name' => 'string|max:255',
            'last_name' => 'string|max:255',
            'email' => 'email|unique:patients,email,' . $patient->id,
            'phone' => 'string|max:20',
            'date_of_birth' => 'date',
            'gender' => 'in:male,female,other',
            'address' => 'nullable|string',
            'emergency_contact' => 'nullable|string|max:255'
        ]);

        $patient->update($validated);
        return response()->json(['data' => $patient]);
    }

    public function destroy(Patient $patient): JsonResponse
    {
        $patient->delete();
        return response()->json(['message' => 'Patient deleted successfully']);
    }
} 