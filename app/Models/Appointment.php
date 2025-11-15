<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    /** @use HasFactory<\Database\Factories\AppointmentFactory> */
    use HasFactory;

    protected $fillable = [
        'patient_id',
        'doctor_name',
        'appointment_datetime',
        'status',
        'notes'
    ];

    protected $casts = [
        'appointment_datetime' => 'datetime'
    ];

    public function patient()
    {
        return $this->belongsTo(Patient::class);
    }
} 