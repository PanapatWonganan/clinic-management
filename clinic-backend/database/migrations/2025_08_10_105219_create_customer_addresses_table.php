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
        Schema::create('customer_addresses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('name', 100); // ชื่อที่อยู่ เช่น "บ้าน", "ที่ทำงาน"
            $table->string('recipient_name', 100); // ชื่อผู้รับ
            $table->string('phone', 20);
            $table->text('address_line_1'); // ที่อยู่บรรทัดที่ 1
            $table->text('address_line_2')->nullable(); // ที่อยู่บรรทัดที่ 2
            $table->string('district', 100);
            $table->string('province', 100);
            $table->string('postal_code', 10);
            $table->unsignedInteger('province_id');
            $table->unsignedInteger('district_id');
            $table->unsignedInteger('sub_district_id');
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            // Foreign key constraints
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            
            // Indexes
            $table->index('user_id');
            $table->index(['user_id', 'is_default']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customer_addresses');
    }
};
