<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DemoDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Clear existing data (disable foreign key checks)
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        \App\Models\OrderItem::truncate();
        \App\Models\Order::truncate();
        \App\Models\Product::truncate();
        // Keep admin user, delete other users
        \App\Models\User::where('email', '!=', 'somchai@example.com')->delete();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        
        // สินค้าหลัก - ตรงกับ Flutter ProductCategory
        \App\Models\Product::create([
            'name' => 'Fine บาง',
            'description' => 'สินค้าคุณภาพสูง เหมาะสำหรับผิวแพ้ง่าย',
            'price' => 2500.00,
            'image_url' => 'assets/images/mask-group.png',
            'category' => 'main',
            'stock' => 10,
            'is_active' => true,
        ]);
        
        \App\Models\Product::create([
            'name' => 'Deep กลาง',
            'description' => 'เจาะลึกเข้าถึงปัญหาใต้ผิวหนัง',
            'price' => 2500.00,
            'image_url' => 'assets/images/mask-group-1.png',
            'category' => 'main',
            'stock' => 0,
            'is_active' => true,
        ]);
        
        \App\Models\Product::create([
            'name' => 'Sub-Q โวลุ่ม',
            'description' => 'เพิ่มโวลุ่มให้ใบหนังอย่างธรรมชาติ',
            'price' => 2500.00,
            'image_url' => 'assets/images/mask-group-2.png',
            'category' => 'main',
            'stock' => 0,
            'is_active' => true,
        ]);
        
        \App\Models\Product::create([
            'name' => 'Implant แข็ง',
            'description' => 'เทคโนโลยีใหม่สำหรับผลลัพธ์ที่ยาวนาน',
            'price' => 2500.00,
            'image_url' => 'assets/images/mask-group-3.png',
            'category' => 'main',
            'stock' => 10,
            'is_active' => true,
        ]);
        
        // สินค้ารางวัล - ตรงกับ Flutter Rewards
        \App\Models\Product::create([
            'name' => 'แก้วน้ำสูญญากาศ Seagull',
            'description' => 'แก้วน้ำสูญญากาศคุณภาพสูง เก็บความเย็นได้นาน 24 ชั่วโมง และความร้อนได้นาน 12 ชั่วโมง ผลิตจากสแตนเลสสตีลเกรดพรีเมียม',
            'price' => 0.00,
            'points' => 800,
            'image_url' => 'assets/images/product1.png',
            'category' => 'reward',
            'stock' => 50,
            'is_active' => true,
        ]);
        
        \App\Models\Product::create([
            'name' => 'เครื่องดูดฝุ่น 2 IN 1 แบบถังกลม',
            'description' => 'เครื่องดูดฝุ่นอเนกประสงค์ ใช้ได้ทั้งดูดฝุ่นแห้งและเปียก พร้อมหัวดูดหลากหลายแบบ เหมาะสำหรับทำความสะอาดบ้าน',
            'price' => 0.00,
            'points' => 800,
            'image_url' => 'assets/images/product2.png',
            'category' => 'reward',
            'stock' => 30,
            'is_active' => true,
        ]);
        
        echo "✅ สร้างสินค้า " . \App\Models\Product::count() . " รายการเรียบร้อย\n";
        
        // สร้างข้อมูลลูกค้า (Users)
        $users = [];
        for ($i = 3; $i <= 20; $i++) { // เริ่มจาก 3 เพราะมี admin อยู่ 2 คนแล้ว
            $users[] = \App\Models\User::create([
                'name' => "คุณลูกค้า $i",
                'email' => "customer$i@example.com",
                'password' => bcrypt('password'),
                'phone' => '08' . str_pad($i, 8, '0', STR_PAD_LEFT),
                'address' => "ที่อยู่ลูกค้า $i",
                'district' => 'เขตตัวอย่าง',
                'province' => 'กรุงเทพฯ',
                'postal_code' => '10110',
                'email_verified_at' => now(),
                'created_at' => now()->subDays(rand(0, 30)),
            ]);
        }
        echo "✅ สร้างลูกค้า " . count($users) . " คนเรียบร้อย\n";
        
        // ดึงลูกค้าทั้งหมด (รวม admin ที่มีอยู่แล้ว)
        $allUsers = \App\Models\User::all();
        
        // สร้างข้อมูลออเดอร์ (Orders)
        $orders = [];
        $totalRevenue = 0;
        $todayRevenue = 0;
        $todayOrders = 0;
        
        foreach ($allUsers as $user) {
            if (rand(1, 100) <= 70) { // 70% ของลูกค้าสั่งซื้อสินค้า
                $orderDate = rand(1, 100) <= 30 ? 
                    now()->subHours(rand(1, 23)) : // 30% ออเดอร์วันนี้
                    now()->subDays(rand(1, 30));   // 70% ออเดอร์ที่ผ่านมา
                
                $products = \App\Models\Product::where('category', 'main')->get();
                $orderAmount = 0;
                
                $order = \App\Models\Order::create([
                    'user_id' => $user->id,
                    'order_number' => 'EX' . str_pad(count($orders) + 1, 6, '0', STR_PAD_LEFT),
                    'total_amount' => 0, // จะอัปเดตหลังจากสร้าง items
                    'status' => ['pending', 'confirmed', 'delivered', 'cancelled'][rand(0, 3)],
                    'payment_method' => ['credit_card', 'qr_code', 'cash'][rand(0, 2)],
                    'created_at' => $orderDate,
                ]);
                
                // สร้าง Order Items
                $numItems = rand(1, 3); // 1-3 สินค้าต่อออเดอร์
                for ($j = 0; $j < $numItems; $j++) {
                    $product = $products->random();
                    $quantity = rand(1, 5);
                    $itemTotal = $product->price * $quantity;
                    
                    \App\Models\OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $quantity,
                        'unit_price' => $product->price,
                        'total_price' => $itemTotal,
                    ]);
                    
                    $orderAmount += $itemTotal;
                }
                
                // อัปเดตยอดรวมของออเดอร์
                $order->update(['total_amount' => $orderAmount]);
                $orders[] = $order;
                $totalRevenue += $orderAmount;
                
                // นับออเดอร์และรายได้วันนี้
                if ($orderDate->isToday()) {
                    $todayOrders++;
                    $todayRevenue += $orderAmount;
                }
            }
        }
        
        echo "✅ สร้างออเดอร์ " . count($orders) . " รายการเรียบร้อย\n";
        echo "💰 รายได้รวม: ฿" . number_format($totalRevenue, 2) . "\n";
        echo "📅 ออเดอร์วันนี้: $todayOrders รายการ\n";
        echo "💸 รายได้วันนี้: ฿" . number_format($todayRevenue, 2) . "\n";
    }
}
