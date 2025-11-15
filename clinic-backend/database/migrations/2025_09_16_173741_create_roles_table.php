<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique(); // ex_member, ex_vip, ex_supervip, ex_doctor
            $table->string('display_name'); // ชื่อแสดงผล
            $table->text('description')->nullable(); // คำอธิบาย
            $table->integer('level')->default(1); // ระดับ membership (1-4)
            $table->decimal('discount_percentage', 5, 2)->default(0); // ส่วนลด (%)
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};
