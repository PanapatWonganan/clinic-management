<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentTransaction;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OrderCancelRaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
    }

    /**
     * Bug H4: handleCallback used to overwrite a cancelled order back to
     * "paid" without checking the current status, so a user who cancelled
     * just before the gateway confirmed the charge would still see their
     * stock decremented and have to chase a refund manually. The fix is to
     * make the callback refuse to flip a cancelled order to paid.
     */
    public function test_callback_does_not_revive_cancelled_order(): void
    {
        config(['paysolutions.test_mode' => false]);
        config(['paysolutions.secret_key' => 'secret-xyz']);
        config(['paysolutions.merchant_id' => '12345678']);

        $user = User::factory()->create();
        $product = Product::create([
            'name' => 'P', 'price' => 100, 'stock' => 5,
            'category' => 'main', 'is_active' => true,
        ]);
        $order = Order::create([
            'order_number' => 'ORD-CANCEL-1',
            'user_id' => $user->id,
            'subtotal' => 100,
            'delivery_fee' => 0,
            'discount' => 0,
            'total_amount' => 100,
            'status' => Order::STATUS_CANCELLED,
            'delivery_method' => 'pickup',
            'payment_method' => 'credit_card',
            'payment_status' => 'pending',
            'payment_slip_status' => 'none',
        ]);
        OrderItem::create([
            'order_id' => $order->id, 'product_id' => $product->id,
            'quantity' => 1, 'unit_price' => 100, 'total_price' => 100,
        ]);
        $payment = PaymentTransaction::create([
            'order_id' => $order->id,
            'payment_gateway' => 'paysolutions',
            'payment_method' => 'credit_card',
            'amount' => 100,
            'currency' => 'THB',
            'status' => 'pending',
            'transaction_id' => 'TXN-123',
        ]);

        // Build a properly signed callback payload.
        $svc = new \App\Services\PaySolutionsService();
        $payload = [
            'transaction_id' => 'TXN-123',
            'order_id' => $order->order_number,
            'status' => 'success',
            'amount' => 100,
        ];
        $payload['signature'] = $this->signFor($payload);

        $response = $this->postJson('/api/payment/callback', $payload);
        // The callback should still acknowledge with 200 (so the gateway
        // won't retry forever), but the order must remain cancelled and
        // stock must not have moved.
        $this->assertContains($response->status(), [200, 409]);
        $this->assertSame(Order::STATUS_CANCELLED, $order->fresh()->status);
        $this->assertSame(5, (int) $product->fresh()->stock);
    }

    private function signFor(array $params): string
    {
        unset($params['signature']);
        ksort($params);
        $stringToSign = '';
        foreach ($params as $k => $v) {
            $stringToSign .= $k.'='.$v.'&';
        }
        $stringToSign = rtrim($stringToSign, '&');
        $stringToSign .= config('paysolutions.secret_key');

        return hash('sha256', $stringToSign);
    }
}
