<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class MembershipSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $membershipTypes = User::getMembershipTypes();

        // Create sample users for each membership type
        $sampleUsers = [
            [
                'name' => 'นาย สมชาย ใจดี',
                'email' => 'somchai@example.com',
                'membership_type' => User::MEMBERSHIP_EXMEMBER,
                'phone' => '081-234-5678',
                'address' => '123 ถนนสุขุมวิท แขวงคลองเตย',
                'district' => 'คลองเตย',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10110'
            ],
            [
                'name' => 'นพ. วิทยา เก่งมาก',
                'email' => 'doctor.witaya@example.com',
                'membership_type' => User::MEMBERSHIP_EXDOCTOR,
                'phone' => '082-345-6789',
                'address' => '456 ถนนพหลโยธิน แขวงจตุจักร',
                'district' => 'จตุจักร',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10900'
            ],
            [
                'name' => 'คุณ สุดารา รำรวย',
                'email' => 'sudara.vip@example.com',
                'membership_type' => User::MEMBERSHIP_EXVIP,
                'phone' => '083-456-7890',
                'address' => '789 ถนนสีลม แขวงสีลม',
                'district' => 'บางรัก',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10500'
            ],
            [
                'name' => 'คุณ วีรพล ไฮโซ',
                'email' => 'veerapol.super@example.com',
                'membership_type' => User::MEMBERSHIP_EXSUPERVIP,
                'phone' => '084-567-8901',
                'address' => '101 ถนนวิทยุ แขวงลุมพินี',
                'district' => 'ปทุมวัน',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10330'
            ],
            // Additional test users
            [
                'name' => 'นางสาว มาลี สวยงาม',
                'email' => 'malee.beauty@example.com',
                'membership_type' => User::MEMBERSHIP_EXMEMBER,
                'phone' => '085-678-9012',
                'address' => '202 ถนนรามคำแหง แขวงหัวหมาก',
                'district' => 'บางกะปิ',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10240'
            ],
            [
                'name' => 'นพ. ศรีสุข เก่งคลินิก',
                'email' => 'doctor.srisuk@example.com',
                'membership_type' => User::MEMBERSHIP_EXDOCTOR,
                'phone' => '086-789-0123',
                'address' => '303 ถนนประชาชื่น แขวงบางซื่อ',
                'district' => 'บางซื่อ',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10800'
            ]
        ];

        foreach ($sampleUsers as $userData) {
            $membershipType = $userData['membership_type'];
            $membershipInfo = $membershipTypes[$membershipType];

            // Calculate membership end date (some lifetime, some with expiry)
            $membershipEndDate = null;
            if (in_array($membershipType, [User::MEMBERSHIP_EXVIP, User::MEMBERSHIP_EXSUPERVIP])) {
                // VIP memberships expire in 1 year
                $membershipEndDate = now()->addYear();
            }

            $user = User::updateOrCreate(
                ['email' => $userData['email']], // Search criteria
                [
                    'name' => $userData['name'],
                    'password' => Hash::make('password'),
                    'phone' => $userData['phone'],
                    'address' => $userData['address'],
                    'district' => $userData['district'],
                    'province' => $userData['province'],
                    'postal_code' => $userData['postal_code'],
                    'email_verified_at' => now(),
                    // Membership data
                    'membership_type' => $membershipType,
                    'membership_start_date' => now()->subDays(rand(30, 365)), // Random start date in the past
                    'membership_end_date' => $membershipEndDate,
                    'membership_benefits' => $membershipInfo['benefits'],
                    'membership_discount_rate' => $membershipInfo['discount_rate'],
                    'membership_point_multiplier' => $membershipInfo['point_multiplier'],
                ]
            );

            $this->command->info("Created/Updated user: {$user->name} ({$membershipInfo['name']})");
        }

        // Update existing test user to have membership
        $existingUser = User::where('email', 'test@example.com')->first();
        if ($existingUser) {
            $membershipInfo = $membershipTypes[User::MEMBERSHIP_EXMEMBER];
            $existingUser->update([
                'membership_type' => User::MEMBERSHIP_EXMEMBER,
                'membership_start_date' => now(),
                'membership_end_date' => null,
                'membership_benefits' => $membershipInfo['benefits'],
                'membership_discount_rate' => $membershipInfo['discount_rate'],
                'membership_point_multiplier' => $membershipInfo['point_multiplier'],
            ]);
            
            $this->command->info("Updated existing test user with exMember membership");
        }

        $this->command->info('Membership seeder completed!');
    }
}
