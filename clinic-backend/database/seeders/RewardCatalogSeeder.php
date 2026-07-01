<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class RewardCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['name' => 'หมวก', 'points' => 50],
            ['name' => 'กระเป๋า', 'points' => 60],
            ['name' => 'เสื้อ Babytee', 'points' => 80],
            ['name' => 'เสื้อ Oversize', 'points' => 120],
            ['name' => 'VDO Marketing', 'points' => 750],
            ['name' => 'Insurance', 'points' => 3700],
            ['name' => 'Hand-Ons 1:1', 'points' => 4000],
            ['name' => 'Lecture + Training', 'points' => 6000],
            ['name' => 'Travel Ticket', 'points' => 10000],
            ['name' => 'Travel Trip', 'points' => 32000],
        ];

        foreach ($items as $item) {
            Product::updateOrCreate(
                ['name' => $item['name'], 'category' => 'reward'],
                [
                    'points' => $item['points'],
                    'is_active' => true,
                    'stock' => 100,
                    'description' => $item['name'],
                    // image_url left null on purpose — frontend renders a
                    // Material Icon fallback until the team supplies real images.
                    // price defaults to 0 at the DB level; no need to set it.
                ]
            );
        }
    }
}
