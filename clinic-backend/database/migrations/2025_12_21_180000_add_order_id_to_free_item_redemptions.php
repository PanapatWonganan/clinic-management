<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * เพิ่ม order_id เพื่อเชื่อมของแถมกับ order (กรณีส่งพร้อม order)
     */
    public function up(): void
    {
        Schema::table('free_item_redemptions', function (Blueprint $table) {
            $table->unsignedBigInteger('order_id')->nullable()->after('shipping_address_id');
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('set null');
            $table->index('order_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('free_item_redemptions', function (Blueprint $table) {
            $table->dropForeign(['order_id']);
            $table->dropIndex(['order_id']);
            $table->dropColumn('order_id');
        });
    }
};
