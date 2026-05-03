<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OrderStockReductionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
    }

    private function setupPaidOrder(int $stock = 10, int $qty = 2): array
    {
        $user = User::factory()->create();
        $product = Product::create([
            'name' => 'Test', 'price' => 100, 'stock' => $stock,
            'category' => 'main', 'is_active' => true,
        ]);
        $order = Order::create([
            'order_number' => 'ORD-'.uniqid(),
            'user_id' => $user->id,
            'subtotal' => $qty * 100,
            'delivery_fee' => 0,
            'discount' => 0,
            'total_amount' => $qty * 100,
            'status' => Order::STATUS_PENDING_PAYMENT,
            'delivery_method' => 'pickup',
            'payment_method' => 'transfer',
            'payment_status' => 'pending',
            'payment_slip_status' => 'none',
        ]);
        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => $qty,
            'unit_price' => 100,
            'total_price' => $qty * 100,
        ]);

        return [$user, $order, $product];
    }

    /**
     * Bug H1: previous booted() event reduced stock on every paid transition.
     * If status flipped paid→pending_payment→paid (refund flow, admin error,
     * etc.) stock would be deducted twice. The new flag must guard against this.
     */
    public function test_stock_only_reduces_once_even_when_status_flips_back_to_paid(): void
    {
        [, $order, $product] = $this->setupPaidOrder(10, 3);

        $order->update(['status' => Order::STATUS_PAID]);
        $this->assertSame(7, (int) $product->fresh()->stock);
        $this->assertNotNull($order->fresh()->stock_reduced_at);

        $order->update(['status' => Order::STATUS_PENDING_PAYMENT]);
        $order->update(['status' => Order::STATUS_PAID]);

        $this->assertSame(7, (int) $product->fresh()->stock, 'stock must not be deducted twice');
    }

    public function test_first_transition_to_paid_reduces_stock(): void
    {
        [, $order, $product] = $this->setupPaidOrder(5, 2);

        $order->update(['status' => Order::STATUS_PAID]);

        $this->assertSame(3, (int) $product->fresh()->stock);
    }
}
