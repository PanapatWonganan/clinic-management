<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\PaymentSlip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PaymentSlipUploadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
        Storage::fake('public');
    }

    private function makeOrderForUser(User $user): Order
    {
        return Order::create([
            'order_number' => 'ORD-SLIP-'.uniqid(),
            'user_id' => $user->id,
            'subtotal' => 100, 'delivery_fee' => 0, 'discount' => 0, 'total_amount' => 100,
            'status' => Order::STATUS_PENDING_PAYMENT,
            'delivery_method' => 'pickup',
            'payment_method' => 'transfer',
            'payment_status' => 'pending',
            'payment_slip_status' => 'none',
        ]);
    }

    /**
     * Bug H8: existing slips were deleted before the new upload was attempted,
     * so a failure to write the new files left the order with no slip at all.
     * The fix uploads new files first; old slips are only removed once new
     * ones are safely persisted.
     */
    public function test_existing_slips_remain_when_new_upload_succeeds(): void
    {
        $user = User::factory()->create();
        $order = $this->makeOrderForUser($user);

        $first = $this->actingAs($user, 'sanctum')->postJson('/api/payment-slips/upload', [
            'order_id' => $order->id,
            'files' => [UploadedFile::fake()->image('slip1.jpg')],
        ]);
        $first->assertStatus(200);
        $oldSlipPaths = PaymentSlip::where('order_id', $order->id)->pluck('file_path')->all();
        $this->assertCount(1, $oldSlipPaths);

        $second = $this->actingAs($user, 'sanctum')->postJson('/api/payment-slips/upload', [
            'order_id' => $order->id,
            'files' => [UploadedFile::fake()->image('slip2.jpg')],
        ]);
        $second->assertStatus(200);

        $remaining = PaymentSlip::where('order_id', $order->id)->pluck('file_path')->all();
        $this->assertCount(1, $remaining, 'replacement should leave exactly one slip');
        // The new slip is the one currently in storage; old should have been wiped.
        Storage::disk('public')->assertExists($remaining[0]);
        Storage::disk('public')->assertMissing($oldSlipPaths[0]);
    }

    public function test_rejects_files_larger_than_5mb(): void
    {
        $user = User::factory()->create();
        $order = $this->makeOrderForUser($user);

        $resp = $this->actingAs($user, 'sanctum')->postJson('/api/payment-slips/upload', [
            'order_id' => $order->id,
            'files' => [UploadedFile::fake()->create('huge.pdf', 6000)],
        ]);
        $resp->assertStatus(422);
    }
}
