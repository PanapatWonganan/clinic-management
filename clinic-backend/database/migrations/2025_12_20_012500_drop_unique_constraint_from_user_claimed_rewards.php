<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Drop unique constraint to allow users to claim same level multiple times
     * (Flow A: progress resets after claim, so user can reach and claim same level again)
     */
    public function up(): void
    {
        // Disable foreign key checks temporarily
        DB::statement('SET FOREIGN_KEY_CHECKS=0');

        // Use raw SQL to drop the unique index
        DB::statement('ALTER TABLE user_claimed_rewards DROP INDEX user_claimed_rewards_user_id_level_reward_type_unique');

        // Re-enable foreign key checks
        DB::statement('SET FOREIGN_KEY_CHECKS=1');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_claimed_rewards', function (Blueprint $table) {
            $table->unique(['user_id', 'level', 'reward_type']);
        });
    }
};
