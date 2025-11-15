<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roles = [
            [
                'name' => 'ex_member',
                'display_name' => 'EX MEMBER',
                'description' => 'สมาชิกภาพพื้นฐานสำหรับผู้ใช้ทั่วไป',
                'level' => 1,
                'discount_percentage' => 0.00,
                'is_active' => true,
            ],
            [
                'name' => 'ex_vip',
                'display_name' => 'EX VIP',
                'description' => 'สมาชิกภาพระดับพรีเมียมพร้อมสิทธิพิเศษ',
                'level' => 2,
                'discount_percentage' => 10.00,
                'is_active' => true,
            ],
            [
                'name' => 'ex_supervip',
                'display_name' => 'EX SUPERVIP',
                'description' => 'สมาชิกภาพระดับสูงสุดพร้อมสิทธิพิเศษครบครัน',
                'level' => 3,
                'discount_percentage' => 20.00,
                'is_active' => true,
            ],
            [
                'name' => 'ex_doctor',
                'display_name' => 'EX DOCTOR',
                'description' => 'สมาชิกภาพพิเศษสำหรับแพทย์และผู้เชี่ยวชาญ',
                'level' => 4,
                'discount_percentage' => 15.00,
                'is_active' => true,
            ],
        ];

        foreach ($roles as $role) {
            Role::updateOrCreate(
                ['name' => $role['name']], // Check by name
                $role // Update with all data
            );
        }
    }
}
