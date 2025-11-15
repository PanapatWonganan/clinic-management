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
        // Update exVip bundle deals with new values
        // Role ID 2 = ex_vip

        // First, delete existing exVip bundle deals
        DB::table('membership_bundle_deals')->where('role_id', 2)->delete();

        // Insert new exVip bundle deals with updated values
        // Assuming unit price is 1000 baht per item for calculations
        $unitPrice = 1000.00;

        DB::table('membership_bundle_deals')->insert([
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_1',
                'display_name' => 'VIP Level 1',
                'description' => 'ซื้อ 5 ฟรี 3 (คละได้)',
                'level' => 1,
                'required_quantity' => 5,
                'free_quantity' => 3,
                'unit_price' => $unitPrice,
                'total_price' => 5 * $unitPrice,
                'total_value' => 8 * $unitPrice,
                'savings_amount' => 3 * $unitPrice,
                'savings_percentage' => (3 / 8) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_2',
                'display_name' => 'VIP Level 2',
                'description' => 'ซื้อ 10 ฟรี 10 (คละได้)',
                'level' => 2,
                'required_quantity' => 10,
                'free_quantity' => 10,
                'unit_price' => $unitPrice,
                'total_price' => 10 * $unitPrice,
                'total_value' => 20 * $unitPrice,
                'savings_amount' => 10 * $unitPrice,
                'savings_percentage' => (10 / 20) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_3',
                'display_name' => 'VIP Level 3',
                'description' => 'ซื้อ 50 ฟรี 75 (คละได้)',
                'level' => 3,
                'required_quantity' => 50,
                'free_quantity' => 75,
                'unit_price' => $unitPrice,
                'total_price' => 50 * $unitPrice,
                'total_value' => 125 * $unitPrice,
                'savings_amount' => 75 * $unitPrice,
                'savings_percentage' => (75 / 125) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_4',
                'display_name' => 'VIP Level 4',
                'description' => 'ซื้อ 270 ฟรี 480 (คละได้)',
                'level' => 4,
                'required_quantity' => 270,
                'free_quantity' => 480,
                'unit_price' => $unitPrice,
                'total_price' => 270 * $unitPrice,
                'total_value' => 750 * $unitPrice,
                'savings_amount' => 480 * $unitPrice,
                'savings_percentage' => (480 / 750) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_5',
                'display_name' => 'VIP Level 5',
                'description' => 'ซื้อ 704 ฟรี 1469 (คละได้)',
                'level' => 5,
                'required_quantity' => 704,
                'free_quantity' => 1469,
                'unit_price' => $unitPrice,
                'total_price' => 704 * $unitPrice,
                'total_value' => 2173 * $unitPrice,
                'savings_amount' => 1469 * $unitPrice,
                'savings_percentage' => (1469 / 2173) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_6',
                'display_name' => 'VIP Level 6',
                'description' => 'ซื้อ 900 ฟรี 2100 (คละได้)',
                'level' => 6,
                'required_quantity' => 900,
                'free_quantity' => 2100,
                'unit_price' => $unitPrice,
                'total_price' => 900 * $unitPrice,
                'total_value' => 3000 * $unitPrice,
                'savings_amount' => 2100 * $unitPrice,
                'savings_percentage' => (2100 / 3000) * 100,
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
        // Restore original exVip bundle deals if needed
        DB::table('membership_bundle_deals')->where('role_id', 2)->delete();

        // Insert original values (if you want to revert)
        $unitPrice = 1000.00;

        DB::table('membership_bundle_deals')->insert([
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_1_original',
                'display_name' => 'VIP Level 1 Original',
                'description' => 'ซื้อ 10 ฟรี 5 (คละได้)',
                'level' => 1,
                'required_quantity' => 10,
                'free_quantity' => 5,
                'unit_price' => $unitPrice,
                'total_price' => 10 * $unitPrice,
                'total_value' => 15 * $unitPrice,
                'savings_amount' => 5 * $unitPrice,
                'savings_percentage' => (5 / 15) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_2_original',
                'display_name' => 'VIP Level 2 Original',
                'description' => 'ซื้อ 25 ฟรี 15 (คละได้)',
                'level' => 2,
                'required_quantity' => 25,
                'free_quantity' => 15,
                'unit_price' => $unitPrice,
                'total_price' => 25 * $unitPrice,
                'total_value' => 40 * $unitPrice,
                'savings_amount' => 15 * $unitPrice,
                'savings_percentage' => (15 / 40) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_3_original',
                'display_name' => 'VIP Level 3 Original',
                'description' => 'ซื้อ 50 ฟรี 35 (คละได้)',
                'level' => 3,
                'required_quantity' => 50,
                'free_quantity' => 35,
                'unit_price' => $unitPrice,
                'total_price' => 50 * $unitPrice,
                'total_value' => 85 * $unitPrice,
                'savings_amount' => 35 * $unitPrice,
                'savings_percentage' => (35 / 85) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_4_original',
                'display_name' => 'VIP Level 4 Original',
                'description' => 'ซื้อ 100 ฟรี 80 (คละได้)',
                'level' => 4,
                'required_quantity' => 100,
                'free_quantity' => 80,
                'unit_price' => $unitPrice,
                'total_price' => 100 * $unitPrice,
                'total_value' => 180 * $unitPrice,
                'savings_amount' => 80 * $unitPrice,
                'savings_percentage' => (80 / 180) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_5_original',
                'display_name' => 'VIP Level 5 Original',
                'description' => 'ซื้อ 200 ฟรี 180 (คละได้)',
                'level' => 5,
                'required_quantity' => 200,
                'free_quantity' => 180,
                'unit_price' => $unitPrice,
                'total_price' => 200 * $unitPrice,
                'total_value' => 380 * $unitPrice,
                'savings_amount' => 180 * $unitPrice,
                'savings_percentage' => (180 / 380) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'role_id' => 2, // ex_vip
                'name' => 'vip_level_6_original',
                'display_name' => 'VIP Level 6 Original',
                'description' => 'ซื้อ 500 ฟรี 500 (คละได้)',
                'level' => 6,
                'required_quantity' => 500,
                'free_quantity' => 500,
                'unit_price' => $unitPrice,
                'total_price' => 500 * $unitPrice,
                'total_value' => 1000 * $unitPrice,
                'savings_amount' => 500 * $unitPrice,
                'savings_percentage' => (500 / 1000) * 100,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
};
