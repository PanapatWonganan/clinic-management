<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add 'paid' to existing ENUM values
        DB::statement("ALTER TABLE orders MODIFY COLUMN status ENUM('pending_payment', 'payment_uploaded', 'paid', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending_payment'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
