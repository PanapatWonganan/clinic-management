<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;

class MembershipUpgradeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get roles
        $exMember = Role::where('name', 'ex_member')->first();
        $exVip = Role::where('name', 'ex_vip')->first();
        $exSupervip = Role::where('name', 'ex_supervip')->first();
        $exDoctor = Role::where('name', 'ex_doctor')->first();

        if (!$exMember || !$exVip || !$exSupervip || !$exDoctor) {
            $this->command->error('Some roles not found! Please run RoleSeeder first.');
            return;
        }

        // Set upgrade conditions for ex_member -> ex_vip
        $exMember->update([
            'upgrade_required_amount' => 500000.00, // 500,000 บาท
            'upgrade_required_quantity' => 200, // 200 ชิ้น (500,000 / 2,500)
            'upgrades_to_role_id' => $exVip->id,
            'upgrade_conditions' => 'ยอดซื้อรวมทั้งหมด 500,000 บาท ไม่มีจำกัดเวลา',
            'auto_upgrade' => true,
        ]);

        // Set upgrade conditions for ex_vip -> ex_supervip
        $exVip->update([
            'upgrade_required_amount' => 5000000.00, // 5 million บาท
            'upgrade_required_quantity' => 2000, // 2000 ชิ้น (5,000,000 / 2,500)
            'upgrades_to_role_id' => $exSupervip->id,
            'upgrade_conditions' => 'ยอดซื้อรวมทั้งหมด 5,000,000 บาท ไม่มีจำกัดเวลา',
            'auto_upgrade' => true,
        ]);

        // ex_supervip and ex_doctor don't upgrade further (top tiers)
        $exSupervip->update([
            'upgrade_conditions' => 'ระดับสูงสุด ไม่มีการอัพเกรดเพิ่มเติม',
            'auto_upgrade' => false,
        ]);

        $exDoctor->update([
            'upgrade_conditions' => 'สมาชิกภาพพิเศษสำหรับแพทย์ ไม่มีการอัพเกรดเพิ่มเติม',
            'auto_upgrade' => false,
        ]);

        $this->command->info('Membership upgrade conditions set:');
        $this->command->info('- EX_MEMBER -> EX_VIP: 500,000 THB (200 units)');
        $this->command->info('- EX_VIP -> EX_SUPERVIP: 5,000,000 THB (2,000 units)');
        $this->command->info('- EX_SUPERVIP: Maximum level (no upgrade)');
        $this->command->info('- EX_DOCTOR: Special tier (no upgrade)');
    }
}
