<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Product;
use App\Models\MembershipLevel;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create membership levels first
        $level1 = MembershipLevel::create([
            'name' => 'Level 1',
            'required_boxes' => 5,
            'free_boxes' => 3,
            'description' => 'ซื้อ 5 กล่อง ฟรี 3',
            'is_active' => true
        ]);

        $level2 = MembershipLevel::create([
            'name' => 'Level 2',
            'required_boxes' => 10,
            'free_boxes' => 10,
            'description' => 'ซื้อ 10 กล่อง ฟรี 10',
            'is_active' => true
        ]);

        $level3 = MembershipLevel::create([
            'name' => 'Level 3',
            'required_boxes' => 50,
            'free_boxes' => 75,
            'description' => 'ซื้อ 50 กล่อง ฟรี 75',
            'is_active' => true
        ]);

        // Create products
        $product1 = Product::create([
            'name' => 'Fine บาง',
            'description' => 'ผลิตภัณฑ์เสริมความงาม Fine บาง สำหรับผิวหน้า',
            'price' => 2500.00,
            'image_path' => 'assets/images/mask-group.png',
            'stock_quantity' => 100,
            'is_active' => true
        ]);

        $product2 = Product::create([
            'name' => 'Deep กลาง',
            'description' => 'ผลิตภัณฑ์เสริมความงาม Deep กลาง สำหรับผิวหน้า',
            'price' => 2500.00,
            'image_path' => 'assets/images/mask-group-1.png',
            'stock_quantity' => 100,
            'is_active' => true
        ]);

        $product3 = Product::create([
            'name' => 'Sub-Q โวลุ่ม',
            'description' => 'ผลิตภัณฑ์เสริมความงาม Sub-Q โวลุ่ม สำหรับผิวหน้า',
            'price' => 2500.00,
            'image_path' => 'assets/images/mask-group-2.png',
            'stock_quantity' => 100,
            'is_active' => true
        ]);

        $product4 = Product::create([
            'name' => 'Implant แข็ง',
            'description' => 'ผลิตภัณฑ์เสริมความงาม Implant แข็ง สำหรับผิวหน้า',
            'price' => 2500.00,
            'image_path' => 'assets/images/mask-group-3.png',
            'stock_quantity' => 100,
            'is_active' => true
        ]);

        // Create demo users
        $user1 = User::create([
            'name' => 'สมชาย ใจดี',
            'email' => 'somchai@example.com',
            'password' => Hash::make('password'),
            'phone' => '081-234-5678',
            'address' => '123 ถนนสุขุมวิท',
            'district' => 'คลองเตย',
            'province' => 'กรุงเทพมหานคร',
            'postal_code' => '10110',
            'total_purchases' => 3,
            'total_spent' => 7500.00,
            'current_membership_level_id' => null // Will be calculated
        ]);

        $user2 = User::create([
            'name' => 'สมหญิง รักดี',
            'email' => 'somying@example.com',
            'password' => Hash::make('password'),
            'phone' => '082-345-6789',
            'address' => '456 ถนนรัชดา',
            'district' => 'ห้วยขวาง',
            'province' => 'กรุงเทพมหานคร',
            'postal_code' => '10310',
            'total_purchases' => 8,
            'total_spent' => 20000.00,
            'current_membership_level_id' => $level2->id
        ]);

        // Update membership levels for users
        $user1->updateMembershipLevel();

        // Create demo orders
        $order1 = Order::create([
            'order_number' => 'ORD20250101001',
            'user_id' => $user1->id,
            'total_amount' => 5000.00,
            'status' => 'delivered',
            'delivery_method' => 'Standard Delivery',
            'payment_method' => 'Credit Card',
            'tracking_number' => 'TH123456789',
            'notes' => 'ส่งตามเวลาปกติ'
        ]);

        OrderItem::create([
            'order_id' => $order1->id,
            'product_id' => $product1->id,
            'quantity' => 2,
            'price' => 2500.00,
            'total_price' => 5000.00
        ]);

        $order2 = Order::create([
            'order_number' => 'ORD20250102001',
            'user_id' => $user2->id,
            'total_amount' => 7500.00,
            'status' => 'shipped',
            'delivery_method' => 'Express Delivery',
            'payment_method' => 'Bank Transfer',
            'tracking_number' => 'TH987654321',
            'notes' => 'ส่งด่วน'
        ]);

        OrderItem::create([
            'order_id' => $order2->id,
            'product_id' => $product2->id,
            'quantity' => 1,
            'price' => 2500.00,
            'total_price' => 2500.00
        ]);

        OrderItem::create([
            'order_id' => $order2->id,
            'product_id' => $product3->id,
            'quantity' => 2,
            'price' => 2500.00,
            'total_price' => 5000.00
        ]);

        echo "✅ E-commerce demo data created successfully!\n";
        echo "🏪 Products: " . Product::count() . " items\n";
        echo "👥 Users: " . User::count() . " members\n";
        echo "📦 Orders: " . Order::count() . " orders\n";
        echo "🎯 Membership Levels: " . MembershipLevel::count() . " levels\n";
    }
} 