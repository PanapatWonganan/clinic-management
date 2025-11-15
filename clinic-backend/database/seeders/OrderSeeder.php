<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Carbon\Carbon;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::all();
        $products = Product::all();

        if ($users->isEmpty() || $products->isEmpty()) {
            echo "Please seed users and products first\n";
            return;
        }

        // Create orders for the last 30 days
        for ($i = 0; $i < 30; $i++) {
            $date = Carbon::now()->subDays($i);
            $ordersCount = rand(0, 5); // 0-5 orders per day

            for ($j = 0; $j < $ordersCount; $j++) {
                $user = $users->random();
                $orderNumber = 'ORD-' . $date->format('Ymd') . '-' . str_pad($j + 1, 3, '0', STR_PAD_LEFT);
                
                $order = Order::create([
                    'order_number' => $orderNumber,
                    'user_id' => $user->id,
                    'total_amount' => 0, // Will be calculated
                    'status' => collect(['pending', 'confirmed', 'processing', 'shipped', 'delivered'])->random(),
                    'delivery_method' => collect(['pickup', 'delivery'])->random(),
                    'payment_method' => collect(['cash', 'transfer', 'credit_card', 'qr_code'])->random(),
                    'notes' => $j % 3 === 0 ? 'Sample order note' : null,
                    'created_at' => $date,
                    'updated_at' => $date,
                ]);

                $totalAmount = 0;
                $itemsCount = rand(1, 4); // 1-4 items per order

                for ($k = 0; $k < $itemsCount; $k++) {
                    $product = $products->random();
                    $quantity = rand(1, 3);
                    $unitPrice = $product->price;
                    $totalPrice = $unitPrice * $quantity;
                    $totalAmount += $totalPrice;

                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'total_price' => $totalPrice,
                        'created_at' => $date,
                        'updated_at' => $date,
                    ]);
                }

                // Update order total
                $order->update(['total_amount' => $totalAmount]);
            }
        }

        echo "Created sample orders for the last 30 days\n";
    }
}
