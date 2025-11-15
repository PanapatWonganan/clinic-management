<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\MembershipBundleDeal;

class ExDoctorBundleDealSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get ex_doctor role
        $exDoctorRole = Role::where('name', 'ex_doctor')->first();

        if (!$exDoctorRole) {
            $this->command->error('ex_doctor role not found! Please run RoleSeeder first.');
            return;
        }

        $unitPrice = 850.00; // ราคาพิเศษสำหรับแพทย์ 850 บาท/ชิ้น

        $bundleDeals = [
            // Level 1: ซื้อ 10 ฟรี 5 (เริ่มต้นสำหรับแพทย์)
            [
                'role_id' => $exDoctorRole->id,
                'name' => 'doctor_bundle_10_5',
                'display_name' => 'ซื้อ 10 ฟรี 5',
                'description' => 'ซื้อครบ 10 กล่อง ฟรี 5 กล่อง รวม 15 กล่อง สำหรับสมาชิกแพทย์',
                'required_quantity' => 10,
                'free_quantity' => 5,
                'unit_price' => $unitPrice,
                'total_price' => 10 * $unitPrice, // 8,500
                'total_value' => 15 * $unitPrice, // 12,750
                'savings_amount' => 5 * $unitPrice, // 4,250
                'savings_percentage' => 33.33, // (5/15) * 100
                'level' => 1,
                'is_active' => true,
            ],
            // Level 2: ซื้อ 20 ฟรี 15 (ค่าดีขึ้น)
            [
                'role_id' => $exDoctorRole->id,
                'name' => 'doctor_bundle_20_15',
                'display_name' => 'ซื้อ 20 ฟรี 15',
                'description' => 'ซื้อครบ 20 กล่อง ฟรี 15 กล่อง รวม 35 กล่อง สำหรับสมาชิกแพทย์',
                'required_quantity' => 20,
                'free_quantity' => 15,
                'unit_price' => $unitPrice,
                'total_price' => 20 * $unitPrice, // 17,000
                'total_value' => 35 * $unitPrice, // 29,750
                'savings_amount' => 15 * $unitPrice, // 12,750
                'savings_percentage' => 42.86, // (15/35) * 100
                'level' => 2,
                'is_active' => true,
            ],
            // Level 3: ซื้อ 50 ฟรี 50 (ค่าดีที่สุดสำหรับแพทย์)
            [
                'role_id' => $exDoctorRole->id,
                'name' => 'doctor_bundle_50_50',
                'display_name' => 'ซื้อ 50 ฟรี 50',
                'description' => 'ซื้อครบ 50 กล่อง ฟรี 50 กล่อง รวม 100 กล่อง สำหรับสมาชิกแพทย์',
                'required_quantity' => 50,
                'free_quantity' => 50,
                'unit_price' => $unitPrice,
                'total_price' => 50 * $unitPrice, // 42,500
                'total_value' => 100 * $unitPrice, // 85,000
                'savings_amount' => 50 * $unitPrice, // 42,500
                'savings_percentage' => 50.00, // (50/100) * 100
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

        $this->command->info('Created 3 DOCTOR bundle deals for ex_doctor role:');
        $this->command->info('- Level 1: ซื้อ 10 ฟรี 5 (ประหยัด 33.3%, มูลค่า 4.3K บาท)');
        $this->command->info('- Level 2: ซื้อ 20 ฟรี 15 (ประหยัด 42.9%, มูลค่า 12.8K บาท)');
        $this->command->info('- Level 3: ซื้อ 50 ฟรี 50 (ประหยัด 50.0%, มูลค่า 42.5K บาท)');
        $this->command->info('');
        $this->command->info('DOCTOR Special Pricing: 850 THB per unit (vs 2,500 THB regular price)');
        $this->command->info('DOCTOR Role: Special tier created by admin only');
    }
}