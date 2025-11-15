<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // สร้าง Admin User
        User::updateOrCreate(
            ['email' => 'admin@exquiller.com'],
            [
                'name' => 'Admin',
                'email' => 'admin@exquiller.com',
                'password' => Hash::make('Admin@123'),
                'email_verified_at' => now(),
                'is_admin' => true,
            ]
        );

        $this->command->info('✅ Admin user created successfully!');
        $this->command->info('📧 Email: admin@exquiller.com');
        $this->command->info('🔑 Password: Admin@123');
    }
}
