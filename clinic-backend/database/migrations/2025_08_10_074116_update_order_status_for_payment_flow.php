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
        // The column was already renamed manually, just mark as migrated
        // Status enum is already updated to new values
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert back to original enum values
        DB::statement("ALTER TABLE orders MODIFY COLUMN status ENUM(
            'pending', 
            'confirmed', 
            'processing', 
            'shipped', 
            'delivered', 
            'cancelled'
        ) DEFAULT 'pending'");
    }
};
