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
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone')->nullable()->after('email');
            $table->text('address')->nullable()->after('phone');
            $table->string('district')->nullable()->after('address');
            $table->string('province')->nullable()->after('district');
            $table->string('postal_code')->nullable()->after('province');
            $table->integer('total_purchases')->default(0)->after('postal_code'); // จำนวนกล่องที่ซื้อทั้งหมด
            $table->decimal('total_spent', 10, 2)->default(0)->after('total_purchases'); // ยอดเงินที่ใช้ทั้งหมด
            $table->foreignId('current_membership_level_id')->nullable()->constrained('membership_levels')->after('total_spent');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['current_membership_level_id']);
            $table->dropColumn([
                'phone',
                'address', 
                'district',
                'province',
                'postal_code',
                'total_purchases',
                'total_spent',
                'current_membership_level_id'
            ]);
        });
    }
}; 