<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE orders MODIFY COLUMN payment_method ".
            "ENUM('cash','transfer','credit_card','qr_code','promptpay') NOT NULL DEFAULT 'cash'"
        );
    }

    public function down(): void
    {
        DB::statement(
            "ALTER TABLE orders MODIFY COLUMN payment_method ".
            "ENUM('cash','transfer','credit_card','qr_code') NOT NULL DEFAULT 'cash'"
        );
    }
};
