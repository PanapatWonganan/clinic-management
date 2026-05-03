<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

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
        // SQLite cannot DROP FOREIGN KEY / DROP INDEX with this MySQL syntax
        // and tests boot a fresh schema where this constraint may not exist
        // anyway. Use Schema::table for portability when possible; otherwise
        // skip on non-MySQL drivers.
        if (DB::getDriverName() !== 'mysql') {
            Schema::table('user_claimed_rewards', function (Blueprint $table) {
                try {
                    $table->dropUnique(['user_id', 'level', 'reward_type']);
                } catch (\Throwable $e) {
                    // index may not exist on fresh test DB
                }
            });

            return;
        }

        // Step 1: Drop the foreign key constraint on user_id first (it uses the unique index)
        DB::statement('ALTER TABLE user_claimed_rewards DROP FOREIGN KEY user_claimed_rewards_user_id_foreign');

        // Step 2: Now we can drop the unique index
        DB::statement('ALTER TABLE user_claimed_rewards DROP INDEX user_claimed_rewards_user_id_level_reward_type_unique');

        // Step 3: Re-add the foreign key constraint (it will create its own index)
        DB::statement('ALTER TABLE user_claimed_rewards ADD CONSTRAINT user_claimed_rewards_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
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
