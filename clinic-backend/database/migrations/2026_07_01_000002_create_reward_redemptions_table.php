<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Points-based reward redemptions. Parallel to free_item_redemptions but
     * bound to reward points (no claimed_reward_id). points_per_item is a
     * snapshot of products.points at redemption time so later price edits do
     * not corrupt historical rows.
     */
    public function up(): void
    {
        Schema::create('reward_redemptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('product_id');
            $table->integer('quantity');
            $table->unsignedInteger('points_per_item'); // snapshot of products.points
            $table->unsignedInteger('points_total');     // quantity * points_per_item
            $table->enum('status', ['pending', 'approved', 'preparing', 'shipped', 'delivered', 'cancelled'])
                ->default('pending');
            $table->unsignedBigInteger('shipping_address_id')->nullable();
            $table->string('tracking_number')->nullable();
            $table->text('notes')->nullable();
            $table->text('admin_notes')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('product_id')->references('id')->on('products')->onDelete('cascade');
            $table->foreign('shipping_address_id')->references('id')->on('customer_addresses')->onDelete('set null');

            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reward_redemptions');
    }
};
