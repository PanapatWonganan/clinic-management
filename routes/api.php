<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PatientController;
use App\Http\Controllers\AppointmentController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Patient API routes
Route::apiResource('patients', PatientController::class);

// Appointment API routes  
Route::apiResource('appointments', AppointmentController::class);

// Custom routes
Route::get('/patients/{patient}/appointments', [PatientController::class, 'appointments']); 