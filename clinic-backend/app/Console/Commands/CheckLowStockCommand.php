<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Jobs\SendLowStockNotification;
use App\Models\Product;

class CheckLowStockCommand extends Command
{
    protected $signature = 'telegram:check-low-stock {--threshold=5 : Minimum stock threshold}';

    protected $description = 'Check for low stock products and send Telegram notification';

    public function handle()
    {
        $threshold = (int) $this->option('threshold');
        
        $this->info("Checking for products with stock below: {$threshold}");
        
        // หาสินค้าที่ stock น้อยกว่า threshold และยังเปิดขายอยู่
        $lowStockProducts = Product::where('stock', '<', $threshold)
            ->where('is_active', true)
            ->orderBy('stock', 'asc')
            ->get();

        if ($lowStockProducts->isEmpty()) {
            $this->info('No low stock products found');
            return 0;
        }

        $this->info("Found {$lowStockProducts->count()} low stock products:");
        
        foreach ($lowStockProducts as $product) {
            $this->line("- {$product->name}: {$product->stock} ชิ้น");
        }

        $this->info('Dispatching low stock notification...');
        
        SendLowStockNotification::dispatch($lowStockProducts, $threshold);
        
        $this->info('Low stock notification job dispatched successfully!');
        
        return 0;
    }
}