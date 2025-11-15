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
            // Membership type enum
            $table->enum('membership_type', ['exMember', 'exDoctor', 'exVip', 'exSupervip'])
                  ->default('exMember')
                  ->after('postal_code');
            
            // Membership dates
            $table->timestamp('membership_start_date')
                  ->nullable()
                  ->after('membership_type');
            $table->timestamp('membership_end_date')
                  ->nullable()
                  ->after('membership_start_date');
            
            // Membership benefits and rates
            $table->json('membership_benefits')
                  ->nullable()
                  ->after('membership_end_date');
            $table->decimal('membership_discount_rate', 5, 2)
                  ->default(0.00)
                  ->comment('Discount rate in percentage (0-100)')
                  ->after('membership_benefits');
            $table->decimal('membership_point_multiplier', 3, 2)
                  ->default(1.00)
                  ->comment('Point multiplier (1.00 = normal, 2.00 = double points)')
                  ->after('membership_discount_rate');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'membership_type',
                'membership_start_date',
                'membership_end_date',
                'membership_benefits',
                'membership_discount_rate',
                'membership_point_multiplier'
            ]);
        });
    }
};
