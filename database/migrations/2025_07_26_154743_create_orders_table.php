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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique(); // รหัสคำสั่งซื้อ
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('total_amount', 10, 2);
            $table->enum('status', [
                'pending',      // รอดำเนินการ
                'confirmed',    // ยืนยันแล้ว
                'processing',   // กำลังเตรียม
                'shipped',      // จัดส่งแล้ว
                'delivered',    // ส่งสำเร็จ
                'cancelled',    // ยกเลิก
                'refunded'      // คืนเงินแล้ว
            ])->default('pending');
            $table->string('delivery_method')->nullable(); // วิธีจัดส่ง
            $table->string('payment_method')->nullable();  // วิธีการชำระเงิน
            $table->string('tracking_number')->nullable(); // เลขติดตาม
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
}; 