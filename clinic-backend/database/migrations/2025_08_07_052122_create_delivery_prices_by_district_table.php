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
        Schema::create('delivery_prices_by_district', function (Blueprint $table) {
            $table->id();
            $table->string('province_name'); // ชื่อจังหวัด (สมุทรปราการ, ปทุมธานี, นนทบุรี)
            $table->string('district_name'); // ชื่ออำเภอ
            $table->decimal('grab_motorcycle_price', 8, 2); // ราคา Grab มอเตอร์ไซค์
            $table->decimal('grab_car_price', 8, 2); // ราคา Grab รถยนต์
            $table->decimal('lalamove_motorcycle_price', 8, 2); // ราคา Lalamove มอเตอร์ไซค์
            $table->decimal('lalamove_car_price', 8, 2); // ราคา Lalamove รถยนต์
            $table->timestamps();
            
            // Add indexes for faster searching
            $table->index(['province_name', 'district_name']);
            $table->index('district_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_prices_by_district');
    }
};
