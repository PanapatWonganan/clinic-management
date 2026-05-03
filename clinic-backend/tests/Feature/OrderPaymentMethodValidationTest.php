<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OrderPaymentMethodValidationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
    }

    /**
     * Bug H5: order validation accepted payment_method=qr_code but the
     * downstream flow (PaymentController::createPayment, slip upload)
     * has no handler for qr_code. The validator should reject values
     * that can't be processed end-to-end.
     */
    public function test_order_rejects_unsupported_qr_code_payment_method(): void
    {
        $user = User::factory()->create();
        $product = Product::create([
            'name' => 'P', 'price' => 100, 'stock' => 5,
            'category' => 'main', 'is_active' => true,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/orders', [
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
            ],
            'delivery_method' => 'pickup',
            'payment_method' => 'qr_code',
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['payment_method']);
    }

    public function test_order_accepts_supported_methods(): void
    {
        $user = User::factory()->create();
        $product = Product::create([
            'name' => 'P', 'price' => 100, 'stock' => 5,
            'category' => 'main', 'is_active' => true,
        ]);

        foreach (['cash', 'transfer', 'credit_card', 'promptpay'] as $method) {
            $response = $this->actingAs($user, 'sanctum')->postJson('/api/orders', [
                'items' => [
                    ['product_id' => $product->id, 'quantity' => 1],
                ],
                'delivery_method' => 'pickup',
                'payment_method' => $method,
            ]);
            $response->assertStatus(201, "method=$method should be accepted");
        }
    }
}
