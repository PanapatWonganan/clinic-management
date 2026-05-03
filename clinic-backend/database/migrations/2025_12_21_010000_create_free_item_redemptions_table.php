<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * ตาราง free_item_redemptions สำหรับเก็บการแลกของแถม
     * - ลูกค้าสามารถแลกของแถมได้หลายครั้งจนกว่าจะหมด
     * - แต่ละครั้งเลือกสินค้าและจำนวนได้
     * - Admin สามารถ approve/reject และติดตามการจัดส่งได้
     */
    public function up(): void
    {
        Schema::create('free_item_redemptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('claimed_reward_id'); // อ้างอิง user_claimed_rewards
            $table->unsignedBigInteger('product_id');        // สินค้าที่เลือก
            $table->integer('quantity');                      // จำนวนที่แลก
            $table->enum('status', ['pending', 'approved', 'preparing', 'shipped', 'delivered', 'cancelled'])
                ->default('pending');
            $table->unsignedBigInteger('shipping_address_id')->nullable(); // ที่อยู่จัดส่ง
            $table->string('tracking_number')->nullable();    // เลข tracking
            $table->text('notes')->nullable();                // หมายเหตุ
            $table->text('admin_notes')->nullable();          // หมายเหตุจาก admin
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('claimed_reward_id')->references('id')->on('user_claimed_rewards')->onDelete('cascade');
            $table->foreign('product_id')->references('id')->on('products')->onDelete('cascade');
            $table->foreign('shipping_address_id')->references('id')->on('customer_addresses')->onDelete('set null');

            // Indexes
            $table->index(['user_id', 'status']);
            $table->index(['claimed_reward_id']);
            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('free_item_redemptions');
    }
};
