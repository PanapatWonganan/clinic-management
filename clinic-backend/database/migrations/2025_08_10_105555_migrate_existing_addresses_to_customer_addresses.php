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
        // Migrate existing user addresses to customer_addresses table
        $users = DB::table('users')
            ->whereNotNull('address')
            ->where('address', '!=', '')
            ->get();

        foreach ($users as $user) {
            // Only create if user doesn't already have a default address
            $existingAddress = DB::table('customer_addresses')
                ->where('user_id', $user->id)
                ->where('is_default', true)
                ->first();

            if (!$existingAddress) {
                DB::table('customer_addresses')->insert([
                    'user_id' => $user->id,
                    'name' => 'บ้าน',
                    'recipient_name' => $user->name,
                    'phone' => $user->phone ?? '',
                    'address_line_1' => $user->address,
                    'address_line_2' => null,
                    'district' => $user->district ?? '',
                    'province' => $user->province ?? '',
                    'postal_code' => $user->postal_code ?? '',
                    'province_id' => $user->province_id ?? 0,
                    'district_id' => $user->district_id ?? 0,
                    'sub_district_id' => $user->sub_district_id ?? 0,
                    'is_default' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove all migrated addresses
        DB::table('customer_addresses')->truncate();
    }
};
