<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\PaymentTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentSecurityTest extends TestCase
{
    use RefreshDatabase;

    private function makeOrderWithPayment(?User $user = null): array
    {
        $user = $user ?: User::factory()->create();
        $order = Order::create([
            'order_number' => 'ORD-TEST-'.uniqid(),
            'user_id' => $user->id,
            'subtotal' => 100,
            'delivery_fee' => 0,
            'discount' => 0,
            'total_amount' => 100,
            'status' => Order::STATUS_PENDING_PAYMENT,
            'delivery_method' => 'pickup',
            'payment_method' => 'credit_card',
            'payment_status' => 'pending',
            'payment_slip_status' => 'none',
        ]);
        $payment = PaymentTransaction::create([
            'order_id' => $order->id,
            'payment_gateway' => 'paysolutions',
            'payment_method' => 'credit_card',
            'amount' => 100,
            'currency' => 'THB',
            'status' => 'pending',
        ]);

        return [$user, $order, $payment];
    }

    /**
     * Bug C3: previously the callback handler skipped signature verification
     * whenever paysolutions test_mode was on, leaving staging exposed to
     * unauthenticated callers who could mark any pending payment paid.
     */
    public function test_callback_rejects_unsigned_request_even_in_test_mode(): void
    {
        config(['paysolutions.test_mode' => true]);

        [, $order, $payment] = $this->makeOrderWithPayment();

        $response = $this->postJson('/api/payment/callback', [
            'transaction_id' => $payment->id,
            'order_id' => $order->order_number,
            'status' => 'success',
            'amount' => 100,
            // intentionally no signature
        ]);

        $response->assertStatus(400);
        $this->assertSame('pending', $payment->fresh()->status);
        $this->assertSame(Order::STATUS_PENDING_PAYMENT, $order->fresh()->status);
    }

    /**
     * Bug C4: verifyAndUpdatePayment did not check that the payment belongs
     * to the authenticated user.
     */
    public function test_verify_payment_rejects_payment_not_owned_by_user(): void
    {
        [, , $payment] = $this->makeOrderWithPayment();

        $other = User::factory()->create();
        $response = $this->actingAs($other)
            ->postJson('/api/payment/verify/'.$payment->id, []);

        $response->assertStatus(403);
    }

    /**
     * Bug C5: checkStatus also leaked payments belonging to other users.
     */
    public function test_check_status_rejects_payment_not_owned_by_user(): void
    {
        [, , $payment] = $this->makeOrderWithPayment();

        $other = User::factory()->create();
        $response = $this->actingAs($other)
            ->getJson('/api/payment/status/'.$payment->id);

        $response->assertStatus(403);
    }

    public function test_check_status_allows_owner(): void
    {
        [$user, , $payment] = $this->makeOrderWithPayment();

        $response = $this->actingAs($user)
            ->getJson('/api/payment/status/'.$payment->id);

        $response->assertStatus(200);
    }
}
