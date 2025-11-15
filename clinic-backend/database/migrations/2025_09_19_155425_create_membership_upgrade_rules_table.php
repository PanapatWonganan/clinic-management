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
        Schema::create('membership_upgrade_rules', function (Blueprint $table) {
            $table->id();
            $table->string('from_type', 20);
            $table->string('to_type', 20);
            $table->decimal('min_spent', 12, 2);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Insert initial upgrade rules
        DB::table('membership_upgrade_rules')->insert([
            [
                'from_type' => 'exMember',
                'to_type' => 'exVip',
                'min_spent' => 500000.00,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'from_type' => 'exVip',
                'to_type' => 'exSuperVip',
                'min_spent' => 5000000.00,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('membership_upgrade_rules');
    }
};
