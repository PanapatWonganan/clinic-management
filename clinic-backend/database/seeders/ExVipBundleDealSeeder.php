<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\MembershipBundleDeal;

class ExVipBundleDealSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get ex_vip role
        $exVipRole = Role::where('name', 'ex_vip')->first();

        if (!$exVipRole) {
            $this->command->error('ex_vip role not found! Please run RoleSeeder first.');
            return;
        }

        $unitPrice = 2500.00; // ราคาต่อชิ้น 2,500 บาท

        $bundleDeals = [
            // Level 4: ซื้อ 270 ฟรี 480
            [
                'role_id' => $exVipRole->id,
                'name' => 'vip_bundle_270_480',
                'display_name' => 'ซื้อ 270 ฟรี 480',
                'description' => 'ซื้อครบ 270 กล่อง ฟรี 480 กล่อง รวม 750 กล่อง สำหรับสมาชิก VIP',
                'required_quantity' => 270,
                'free_quantity' => 480,
                'unit_price' => $unitPrice,
                'total_price' => 270 * $unitPrice, // 675,000
                'total_value' => 750 * $unitPrice, // 1,875,000
                'savings_amount' => 480 * $unitPrice, // 1,200,000
                'savings_percentage' => 64.00, // (480/750) * 100
                'level' => 4,
                'is_active' => true,
            ],
            // Level 5: ซื้อ 704 ฟรี 1469
            [
                'role_id' => $exVipRole->id,
                'name' => 'vip_bundle_704_1469',
                'display_name' => 'ซื้อ 704 ฟรี 1469',
                'description' => 'ซื้อครบ 704 กล่อง ฟรี 1,469 กล่อง รวม 2,173 กล่อง สำหรับสมาชิก VIP',
                'required_quantity' => 704,
                'free_quantity' => 1469,
                'unit_price' => $unitPrice,
                'total_price' => 704 * $unitPrice, // 1,760,000
                'total_value' => 2173 * $unitPrice, // 5,432,500
                'savings_amount' => 1469 * $unitPrice, // 3,672,500
                'savings_percentage' => 67.61, // (1469/2173) * 100
                'level' => 5,
                'is_active' => true,
            ],
            // Level 6: ซื้อ 900 ฟรี 2100
            [
                'role_id' => $exVipRole->id,
                'name' => 'vip_bundle_900_2100',
                'display_name' => 'ซื้อ 900 ฟรี 2100',
                'description' => 'ซื้อครบ 900 กล่อง ฟรี 2,100 กล่อง รวม 3,000 กล่อง สำหรับสมาชิก VIP',
                'required_quantity' => 900,
                'free_quantity' => 2100,
                'unit_price' => $unitPrice,
                'total_price' => 900 * $unitPrice, // 2,250,000
                'total_value' => 3000 * $unitPrice, // 7,500,000
                'savings_amount' => 2100 * $unitPrice, // 5,250,000
                'savings_percentage' => 70.00, // (2100/3000) * 100
                'level' => 6,
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

        $this->command->info('Created 3 VIP bundle deals for ex_vip role:');
        $this->command->info('- Level 4: ซื้อ 270 ฟรี 480 (ประหยัด 64.0%, มูลค่า 1.2M บาท)');
        $this->command->info('- Level 5: ซื้อ 704 ฟรี 1,469 (ประหยัด 67.6%, มูลค่า 3.7M บาท)');
        $this->command->info('- Level 6: ซื้อ 900 ฟรี 2,100 (ประหยัด 70.0%, มูลค่า 5.3M บาท)');
        $this->command->info('');
        $this->command->info('VIP Upgrade Requirement: Total purchase 500,000 THB (200 units)');
    }
}
