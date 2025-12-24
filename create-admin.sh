#!/bin/bash

# Script to create admin user on production server

ssh root@45.32.102.242 << 'ENDSSH'
cd /var/www/api.exquiller.com

# Create admin user via PHP artisan tinker
php artisan tinker << 'EOF'
$user = new App\Models\User();
$user->name = 'Admin';
$user->email = 'admin@example.com';
$user->password = Hash::make('password123');
$user->role_id = 1;
$user->save();

echo "Admin user created successfully!\n";

// Verify the user was created
$admin = App\Models\User::where('email', 'admin@example.com')->first();
if ($admin) {
    echo "✅ Admin user verified - ID: " . $admin->id . ", Email: " . $admin->email . ", Role ID: " . $admin->role_id . "\n";
} else {
    echo "❌ Failed to verify admin user\n";
}
exit
EOF

ENDSSH
