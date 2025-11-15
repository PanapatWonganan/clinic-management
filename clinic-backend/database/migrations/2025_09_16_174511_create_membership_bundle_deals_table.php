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
        Schema::create('membership_bundle_deals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('role_id')->constrained('roles')->onDelete('cascade');
            $table->string('name'); // ชื่อแพ็คเกจ เช่น "Bundle 5+3"
            $table->string('display_name'); // ชื่อแสดงผล เช่น "ซื้อ 5 ฟรี 3"
            $table->text('description')->nullable(); // คำอธิบาย
            $table->integer('required_quantity'); // จำนวนที่ต้องซื้อ เช่น 5, 10, 50
            $table->integer('free_quantity'); // จำนวนที่ได้ฟรี เช่น 3, 10, 75
            $table->decimal('unit_price', 10, 2); // ราคาต่อหน่วย เช่น 2500.00
            $table->decimal('total_price', 10, 2); // ราคารวม
            $table->decimal('total_value', 10, 2); // มูลค่ารวม (รวมของฟรี)
            $table->decimal('savings_amount', 10, 2); // จำนวนเงินที่ประหยัดได้
            $table->decimal('savings_percentage', 5, 2); // เปอร์เซ็นต์ที่ประหยัดได้
            $table->integer('level')->default(1); // ระดับโปรโมชั่น 1, 2, 3
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['role_id', 'level']); // แต่ละ role มี level ได้เพียง 1 แพ็คเกจ
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('membership_bundle_deals');
    }
};
