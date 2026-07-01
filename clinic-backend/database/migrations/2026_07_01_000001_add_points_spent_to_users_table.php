<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Cumulative reward points already redeemed. Balance is derived as
            // floor(total_spent / 10000) - points_spent, so we only track spend.
            $table->unsignedInteger('points_spent')->default(0)->after('id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('points_spent');
        });
    }
};
