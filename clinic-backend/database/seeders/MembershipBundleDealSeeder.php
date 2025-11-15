<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\MembershipBundleDeal;

class MembershipBundleDealSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get ex_member role
        $exMemberRole = Role::where('name', 'ex_member')->first();

        if (!$exMemberRole) {
            $this->command->error('ex_member role not found! Please run RoleSeeder first.');
            return;
        }

        $unitPrice = 2500.00; // ราคาต่อชิ้น 2,500 บาท

        $bundleDeals = [
            // Level 1: ซื้อ 5 ฟรี 3
            [
                'role_id' => $exMemberRole->id,
                'name' => 'bundle_5_3',
                'display_name' => 'ซื้อ 5 ฟรี 3',
                'description' => 'ซื้อครบ 5 กล่อง ฟรี 3 กล่อง รวม 8 กล่อง',
                'required_quantity' => 5,
                'free_quantity' => 3,
                'unit_price' => $unitPrice,
                'total_price' => 5 * $unitPrice, // 12,500
                'total_value' => 8 * $unitPrice, // 20,000
                'savings_amount' => 3 * $unitPrice, // 7,500
                'savings_percentage' => 37.50, // (3/8) * 100
                'level' => 1,
                'is_active' => true,
            ],
            // Level 2: ซื้อ 10 ฟรี 10
            [
                'role_id' => $exMemberRole->id,
                'name' => 'bundle_10_10',
                'display_name' => 'ซื้อ 10 ฟรี 10',
                'description' => 'ซื้อครบ 10 กล่อง ฟรี 10 กล่อง รวม 20 กล่อง',
                'required_quantity' => 10,
                'free_quantity' => 10,
                'unit_price' => $unitPrice,
                'total_price' => 10 * $unitPrice, // 25,000
                'total_value' => 20 * $unitPrice, // 50,000
                'savings_amount' => 10 * $unitPrice, // 25,000
                'savings_percentage' => 50.00, // (10/20) * 100
                'level' => 2,
                'is_active' => true,
            ],
            // Level 3: ซื้อ 50 ฟรี 75
            [
                'role_id' => $exMemberRole->id,
                'name' => 'bundle_50_75',
                'display_name' => 'ซื้อ 50 ฟรี 75',
                'description' => 'ซื้อครบ 50 กล่อง ฟรี 75 กล่อง รวม 125 กล่อง',
                'required_quantity' => 50,
                'free_quantity' => 75,
                'unit_price' => $unitPrice,
                'total_price' => 50 * $unitPrice, // 125,000
                'total_value' => 125 * $unitPrice, // 312,500
                'savings_amount' => 75 * $unitPrice, // 187,500
                'savings_percentage' => 60.00, // (75/125) * 100
                'level' => 3,
                'is_active' => true,
            ],
        ];

        foreach ($bundleDeals as $deal) {
            MembershipBundleDeal::updateOrCreate(
                [
                    'role_id' => $deal['role_id'],
                    'level' => $deal['level']
                ],
                $deal
            );
        }

        $this->command->info('Created 3 bundle deals for ex_member role:');
        $this->command->info('- Level 1: ซื้อ 5 ฟรี 3 (ประหยัด 37.5%)');
        $this->command->info('- Level 2: ซื้อ 10 ฟรี 10 (ประหยัด 50%)');
        $this->command->info('- Level 3: ซื้อ 50 ฟรี 75 (ประหยัด 60%)');
    }
}
