<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\MembershipBundleDeal;

class ExSuperVipBundleDealSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get ex_supervip role
        $exSuperVipRole = Role::where('name', 'ex_supervip')->first();

        if (!$exSuperVipRole) {
            $this->command->error('ex_supervip role not found! Please run RoleSeeder first.');
            return;
        }

        $unitPrice = 2500.00; // ราคาต่อชิ้น 2,500 บาท

        $bundleDeals = [
            // Level 1: ซื้อ 50 ฟรี 50 (same as VIP level 1)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_50_50',
                'display_name' => 'ซื้อ 50 ฟรี 50',
                'description' => 'ซื้อครบ 50 กล่อง ฟรี 50 กล่อง รวม 100 กล่อง สำหรับสมาชิก SUPER VIP',
                'required_quantity' => 50,
                'free_quantity' => 50,
                'unit_price' => $unitPrice,
                'total_price' => 50 * $unitPrice, // 125,000
                'total_value' => 100 * $unitPrice, // 250,000
                'savings_amount' => 50 * $unitPrice, // 125,000
                'savings_percentage' => 50.00, // (50/100) * 100
                'level' => 1,
                'is_active' => true,
            ],
            // Level 2: ซื้อ 100 ฟรี 150 (enhanced from VIP)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_100_150',
                'display_name' => 'ซื้อ 100 ฟรี 150',
                'description' => 'ซื้อครบ 100 กล่อง ฟรี 150 กล่อง รวม 250 กล่อง สำหรับสมาชิก SUPER VIP',
                'required_quantity' => 100,
                'free_quantity' => 150,
                'unit_price' => $unitPrice,
                'total_price' => 100 * $unitPrice, // 250,000
                'total_value' => 250 * $unitPrice, // 625,000
                'savings_amount' => 150 * $unitPrice, // 375,000
                'savings_percentage' => 60.00, // (150/250) * 100
                'level' => 2,
                'is_active' => true,
            ],
            // Level 3: ซื้อ 200 ฟรี 350 (enhanced from VIP)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_200_350',
                'display_name' => 'ซื้อ 200 ฟรี 350',
                'description' => 'ซื้อครบ 200 กล่อง ฟรี 350 กล่อง รวม 550 กล่อง สำหรับสมาชิก SUPER VIP',
                'required_quantity' => 200,
                'free_quantity' => 350,
                'unit_price' => $unitPrice,
                'total_price' => 200 * $unitPrice, // 500,000
                'total_value' => 550 * $unitPrice, // 1,375,000
                'savings_amount' => 350 * $unitPrice, // 875,000
                'savings_percentage' => 63.64, // (350/550) * 100
                'level' => 3,
                'is_active' => true,
            ],
            // Level 4: ซื้อ 270 ฟรี 480 (same as VIP level 4)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_270_480',
                'display_name' => 'ซื้อ 270 ฟรี 480',
                'description' => 'ซื้อครบ 270 กล่อง ฟรี 480 กล่อง รวม 750 กล่อง สำหรับสมาชิก SUPER VIP',
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
            // Level 5: ซื้อ 704 ฟรี 1469 (same as VIP level 5)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_704_1469',
                'display_name' => 'ซื้อ 704 ฟรี 1469',
                'description' => 'ซื้อครบ 704 กล่อง ฟรี 1,469 กล่อง รวม 2,173 กล่อง สำหรับสมาชิก SUPER VIP',
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
            // Level 6: ซื้อ 900 ฟรี 2100 (same as VIP level 6)
            [
                'role_id' => $exSuperVipRole->id,
                'name' => 'supervip_bundle_900_2100',
                'display_name' => 'ซื้อ 900 ฟรี 2100',
                'description' => 'ซื้อครบ 900 กล่อง ฟรี 2,100 กล่อง รวม 3,000 กล่อง สำหรับสมาชิก SUPER VIP',
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

        $this->command->info('Created 6 SUPER VIP bundle deals for ex_supervip role:');
        $this->command->info('- Level 1: ซื้อ 50 ฟรี 50 (ประหยัด 50.0%, มูลค่า 125K บาท)');
        $this->command->info('- Level 2: ซื้อ 100 ฟรี 150 (ประหยัด 60.0%, มูลค่า 375K บาท)');
        $this->command->info('- Level 3: ซื้อ 200 ฟรี 350 (ประหยัด 63.6%, มูลค่า 875K บาท)');
        $this->command->info('- Level 4: ซื้อ 270 ฟรี 480 (ประหยัด 64.0%, มูลค่า 1.2M บาท)');
        $this->command->info('- Level 5: ซื้อ 704 ฟรี 1,469 (ประหยัด 67.6%, มูลค่า 3.7M บาท)');
        $this->command->info('- Level 6: ซื้อ 900 ฟรี 2,100 (ประหยัด 70.0%, มูลค่า 5.3M บาท)');
        $this->command->info('');
        $this->command->info('SUPER VIP Upgrade Requirement: Total purchase 5,000,000 THB (2,000 units)');
    }
}