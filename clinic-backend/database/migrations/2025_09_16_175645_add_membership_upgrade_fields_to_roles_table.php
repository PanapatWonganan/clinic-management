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
        Schema::table('roles', function (Blueprint $table) {
            $table->decimal('upgrade_required_amount', 15, 2)->nullable()->after('discount_percentage'); // จำนวนเงินที่ต้องซื้อเพื่ออัพเกรด
            $table->integer('upgrade_required_quantity')->nullable()->after('upgrade_required_amount'); // จำนวนชิ้นที่ต้องซื้อเพื่ออัพเกรด
            $table->foreignId('upgrades_to_role_id')->nullable()->after('upgrade_required_quantity')->constrained('roles')->onDelete('set null'); // role ที่จะอัพเกรดไป
            $table->text('upgrade_conditions')->nullable()->after('upgrades_to_role_id'); // เงื่อนไขการอัพเกรดเพิ่มเติม
            $table->boolean('auto_upgrade')->default(true)->after('upgrade_conditions'); // อัพเกรดอัตโนมัติหรือไม่
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->dropForeign(['upgrades_to_role_id']);
            $table->dropColumn([
                'upgrade_required_amount',
                'upgrade_required_quantity',
                'upgrades_to_role_id',
                'upgrade_conditions',
                'auto_upgrade'
            ]);
        });
    }
};
