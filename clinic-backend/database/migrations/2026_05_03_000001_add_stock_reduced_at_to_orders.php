<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Idempotency marker: when set, the paid-status event handler
            // skips stock reduction so a status that flips paid→other→paid
            // never decrements stock twice.
            $table->timestamp('stock_reduced_at')->nullable()->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('stock_reduced_at');
        });
    }
};
