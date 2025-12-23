<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * เพิ่ม column สำหรับติดตามจำนวนของแถมที่แลกไปแล้ว
     */
    public function up(): void
    {
        Schema::table('user_claimed_rewards', function (Blueprint $table) {
            // จำนวนที่แลกไปแล้ว (เริ่มต้น 0)
            $table->integer('redeemed_free_items')->default(0)->after('earned_free_items');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_claimed_rewards', function (Blueprint $table) {
            $table->dropColumn('redeemed_free_items');
        });
    }
};
