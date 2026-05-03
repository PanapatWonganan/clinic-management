<?php

namespace Tests\Feature;

use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StockRaceConditionTest extends TestCase
{
    use RefreshDatabase;

    /**
     * The atomic-decrement helper must reject the second caller when
     * the first already consumed all stock — emulating two concurrent
     * orders racing against the last unit.
     *
     * Bug C1: previous code did `if (stock >= qty) { decrement; }` which
     * has a TOCTOU window between the read and the write.
     */
    public function test_atomic_stock_decrement_prevents_negative_stock(): void
    {
        $product = Product::create([
            'name' => 'Test Product',
            'price' => 100,
            'stock' => 1,
            'category' => 'main',
            'is_active' => true,
        ]);

        $first = \App\Services\StockService::tryDecrement($product->id, 1);
        $second = \App\Services\StockService::tryDecrement($product->id, 1);

        $this->assertTrue($first, 'first caller should succeed');
        $this->assertFalse($second, 'second caller must be rejected');

        $this->assertSame(0, (int) Product::find($product->id)->stock);
    }

    public function test_atomic_decrement_rejects_when_insufficient(): void
    {
        $product = Product::create([
            'name' => 'Test',
            'price' => 100,
            'stock' => 2,
            'category' => 'main',
            'is_active' => true,
        ]);

        $this->assertFalse(\App\Services\StockService::tryDecrement($product->id, 5));
        $this->assertSame(2, (int) Product::find($product->id)->stock);
    }

    public function test_atomic_decrement_succeeds_within_stock(): void
    {
        $product = Product::create([
            'name' => 'Test',
            'price' => 100,
            'stock' => 10,
            'category' => 'main',
            'is_active' => true,
        ]);

        $this->assertTrue(\App\Services\StockService::tryDecrement($product->id, 3));
        $this->assertSame(7, (int) Product::find($product->id)->stock);
    }
}
