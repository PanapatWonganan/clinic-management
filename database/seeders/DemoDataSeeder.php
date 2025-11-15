<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;

class DemoDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // สร้างลูกค้าตัวอย่าง
        $customers = $this->createCustomers();
        
        // สร้างสินค้าตัวอย่าง
        $products = $this->createProducts();
        
        // สร้างออเดอร์ตัวอย่าง
        $this->createOrders($customers, $products);
    }

    private function createCustomers()
    {
        $customers = [
            [
                'name' => 'สมชาย ใจดี',
                'email' => 'somchai@example.com',
                'membership_level' => 'gold',
                'created_at' => Carbon::now()->subDays(30),
            ],
            [
                'name' => 'สมใส สวยงาม',
                'email' => 'somsai@example.com',
                'membership_level' => 'silver',
                'created_at' => Carbon::now()->subDays(20),
            ],
            [
                'name' => 'ทดสอบ ระบบ',
                'email' => 'test@example.com',
                'membership_level' => 'bronze',
                'created_at' => Carbon::now()->subDays(10),
            ],
            [
                'name' => 'วิภา คลาสสิค',
                'email' => 'wipa@example.com',
                'membership_level' => 'platinum',
                'created_at' => Carbon::now()->subDays(5),
            ],
            [
                'name' => 'นิดา บิวตี้',
                'email' => 'nida@example.com',
                'membership_level' => 'gold',
                'created_at' => Carbon::now()->subDays(2),
            ],
        ];

        $createdCustomers = [];
        foreach ($customers as $customer) {
            $createdCustomers[] = User::create([
                'name' => $customer['name'],
                'email' => $customer['email'],
                'password' => Hash::make('password'),
                'membership_level' => $customer['membership_level'],
                'email_verified_at' => $customer['created_at'],
                'created_at' => $customer['created_at'],
                'updated_at' => $customer['created_at'],
            ]);
        }

        return $createdCustomers;
    }

    private function createProducts()
    {
        $products = [
            [
                'name' => 'เซรั่มวิตามินซี ออร์แกนิค',
                'description' => 'เซรั่มวิตามินซี 100% ธรรมชาติ ช่วยลดจุดด่างดำ',
                'price' => 990,
                'stock_quantity' => 50,
                'category' => 'skincare',
                'is_active' => true,
                'featured' => true,
            ],
            [
                'name' => 'ครีมกันแดด SPF 50+',
                'description' => 'ครีมกันแดดสูตรอ่อนโยน เหมาะสำหรับทุกสีผิว',
                'price' => 450,
                'stock_quantity' => 75,
                'category' => 'skincare',
                'is_active' => true,
                'featured' => true,
            ],
            [
                'name' => 'มาส์กหน้าคอลลาเจน',
                'description' => 'มาส์กหน้าคอลลาเจนแท้ ช่วยฟื้นฟูผิวหน้า',
                'price' => 299,
                'stock_quantity' => 100,
                'category' => 'skincare',
                'is_active' => true,
                'featured' => false,
            ],
            [
                'name' => 'ลิปสติกเนื้อแมท',
                'description' => 'ลิปสติกเนื้อแมท กันน้ำ อยู่ทน 12 ชั่วโมง',
                'price' => 350,
                'stock_quantity' => 8, // low stock
                'category' => 'makeup',
                'is_active' => true,
                'featured' => false,
            ],
            [
                'name' => 'แป้งพัฟทรานสปาเรนซี่',
                'description' => 'แป้งพัฟโปร่งแสง เนื้อบางเบา ติดทนนาน',
                'price' => 650,
                'stock_quantity' => 30,
                'category' => 'makeup',
                'is_active' => true,
                'featured' => true,
            ],
            [
                'name' => 'เครื่องสำอางชุดเดินทาง',
                'description' => 'ชุดเครื่องสำอางพกพา สะดวกสำหรับเดินทาง',
                'price' => 1290,
                'stock_quantity' => 25,
                'category' => 'sets',
                'is_active' => true,
                'featured' => false,
            ],
        ];

        $createdProducts = [];
        foreach ($products as $product) {
            $createdProducts[] = Product::create($product);
        }

        return $createdProducts;
    }

    private function createOrders($customers, $products)
    {
        $statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
        
        // สร้างออเดอร์ย้อนหลัง 30 วัน
        for ($i = 30; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            
            // สุ่มจำนวนออเดอร์ต่อวัน (0-5 ออเดอร์)
            $ordersPerDay = rand(0, 5);
            
            for ($j = 0; $j < $ordersPerDay; $j++) {
                $customer = $customers[array_rand($customers)];
                $status = $statuses[array_rand($statuses)];
                
                // สร้างออเดอร์
                $order = Order::create([
                    'user_id' => $customer->id,
                    'order_number' => 'ORD-' . $date->format('Ymd') . '-' . str_pad($j + 1, 3, '0', STR_PAD_LEFT),
                    'status' => $status,
                    'total_amount' => 0, // จะคำนวณใหม่หลังจากเพิ่ม items
                    'shipping_address' => $customer->address ?? '123 ถนนสุขุมวิท กรุงเทพฯ 10110',
                    'payment_method' => rand(0, 1) ? 'credit_card' : 'bank_transfer',
                    'payment_status' => $status === 'cancelled' ? 'cancelled' : 'paid',
                    'created_at' => $date->addHours(rand(8, 20))->addMinutes(rand(0, 59)),
                    'updated_at' => $date,
                ]);

                // เพิ่มสินค้าในออเดอร์ (1-4 รายการ)
                $itemsCount = rand(1, 4);
                $totalAmount = 0;
                
                for ($k = 0; $k < $itemsCount; $k++) {
                    $product = $products[array_rand($products)];
                    $quantity = rand(1, 3);
                    $price = $product->price;
                    
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $quantity,
                        'price' => $price,
                        'total' => $price * $quantity,
                    ]);
                    
                    $totalAmount += $price * $quantity;
                }
                
                // อัปเดตยอดรวมของออเดอร์
                $order->update(['total_amount' => $totalAmount]);
            }
        }
    }
} 