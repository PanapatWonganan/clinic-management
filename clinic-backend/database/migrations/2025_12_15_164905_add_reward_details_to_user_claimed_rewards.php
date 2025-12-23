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
        Schema::table('user_claimed_rewards', function (Blueprint $table) {
            $table->unsignedBigInteger('order_id')->nullable()->after('user_id');
            $table->integer('required_quantity')->default(0)->after('level');
            $table->integer('earned_free_items')->default(0)->after('required_quantity');
            $table->decimal('unit_price', 10, 2)->default(2500)->after('earned_free_items');
            $table->decimal('savings_amount', 10, 2)->default(0)->after('unit_price');

            // Add foreign key
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_claimed_rewards', function (Blueprint $table) {
            $table->dropForeign(['order_id']);
            $table->dropColumn(['order_id', 'required_quantity', 'earned_free_items', 'unit_price', 'savings_amount']);
        });
    }
};
