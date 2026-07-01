<?php

namespace Tests\Feature;

use App\Models\CustomerAddress;
use App\Models\Order;
use App\Models\Product;
use App\Models\RewardRedemption;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RewardRedemptionTest extends TestCase
{
    use RefreshDatabase;

    private function rewardProduct(int $points = 50, int $stock = 10): Product
    {
        return Product::factory()->create([
            'category' => 'reward',
            'is_active' => true,
            'points' => $points,
            'stock' => $stock,
        ]);
    }

    /** A user with 100k spend has 10 points earned. */
    private function userWithPoints(int $earnedBaht = 100000): User
    {
        $user = User::factory()->create(['points_spent' => 0]);
        Order::factory()->create([
            'user_id' => $user->id,
            'status' => 'paid', // MUST be a real spend status from ProfileController's whereIn list (pending_payment/payment_uploaded/paid/confirmed/processing/shipped/delivered). 'completed' is NOT a real status and yields earnedPoints=0, failing every test.
            'total_amount' => $earnedBaht,
            'is_free_item_order' => false,
        ]);
        return $user;
    }

    public function test_redeem_deducts_points_and_stock_and_creates_row(): void
    {
        $user = $this->userWithPoints(100000); // 10 points
        $product = $this->rewardProduct(50, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        // cost = 1 * 50 = 50 points, but earned is only 10 → should fail first;
        // use a cheaper product to succeed instead.
        $cheap = $this->rewardProduct(5, 10);
        $addr2 = $address;

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $cheap->id,
            'quantity' => 2,
            'shipping_address_id' => $addr2->id,
        ]);

        $res->assertStatus(201);
        $this->assertSame(0, $res->json('points_balance')); // 10 - 2*5 = 0
        $this->assertDatabaseHas('reward_redemptions', [
            'user_id' => $user->id,
            'product_id' => $cheap->id,
            'quantity' => 2,
            'points_per_item' => 5,
            'points_total' => 10,
            'status' => 'pending',
        ]);
        $user->refresh();
        $this->assertSame(10, (int) $user->points_spent);
        $cheap->refresh();
        $this->assertSame(8, (int) $cheap->stock);
    }

    public function test_redeem_fails_when_points_insufficient(): void
    {
        $user = $this->userWithPoints(10000); // 1 point
        $product = $this->rewardProduct(50, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 1,
            'shipping_address_id' => $address->id,
        ]);

        $res->assertStatus(422);
        $this->assertSame(0, RewardRedemption::count());
        $user->refresh();
        $this->assertSame(0, (int) $user->points_spent);
    }

    public function test_redeem_fails_when_out_of_stock(): void
    {
        $user = $this->userWithPoints(100000);
        $product = $this->rewardProduct(5, 1);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 2,
            'shipping_address_id' => $address->id,
        ]);

        $res->assertStatus(422);
        $this->assertSame(0, RewardRedemption::count());
    }

    public function test_redeem_rejects_address_not_owned(): void
    {
        $user = $this->userWithPoints(100000);
        $other = User::factory()->create();
        $product = $this->rewardProduct(5, 10);
        $addr = CustomerAddress::factory()->create(['user_id' => $other->id]);
        Sanctum::actingAs($user);

        $res = $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 1,
            'shipping_address_id' => $addr->id,
        ]);

        $res->assertStatus(422);
    }

    public function test_balance_endpoint_reports_earned_minus_spent(): void
    {
        $user = $this->userWithPoints(100000); // earned 10
        $user->update(['points_spent' => 4]);
        Sanctum::actingAs($user);

        $res = $this->getJson('/api/reward-points/balance');
        $res->assertOk();
        $this->assertSame(10, $res->json('data.points_earned'));
        $this->assertSame(4, $res->json('data.points_spent'));
        $this->assertSame(6, $res->json('data.points_balance'));
    }

    public function test_admin_cancel_nonexistent_id_returns_error_not_success(): void
    {
        // Cancelling a non-existent redemption must flash 'error', not 'success',
        // and must leave zero redemption rows in the DB (no mutation occurred).
        $admin = new \App\Http\Controllers\Admin\RewardController();

        // back()->with('error'/'success', ...) stores flash data on the session
        // attached to the RedirectResponse — accessible via getSession().
        $response = $admin->cancelRewardRedemption('00000000-0000-0000-0000-000000000000');

        $this->assertSame(0, RewardRedemption::count());

        $session = $response->getSession();
        $this->assertNotNull($session, 'RedirectResponse must carry a session instance');

        // Must NOT flash 'success' — the admin must not be misled into thinking the cancel worked.
        $this->assertFalse(
            $session->has('success'),
            'A missing-row cancel must NOT flash success'
        );
        // Must flash 'error' so the admin is informed the row was not found.
        $this->assertTrue(
            $session->has('error'),
            'A missing-row cancel must flash an error'
        );
    }

    public function test_admin_cancel_refunds_points_and_stock(): void
    {
        $user = $this->userWithPoints(100000); // earned 10
        $product = $this->rewardProduct(5, 10);
        $address = CustomerAddress::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);
        $this->postJson('/api/reward-redemptions', [
            'product_id' => $product->id,
            'quantity' => 2,
            'shipping_address_id' => $address->id,
        ])->assertStatus(201);

        $user->refresh();
        $this->assertSame(10, (int) $user->points_spent);
        $product->refresh();
        $this->assertSame(8, (int) $product->stock);

        $redemption = RewardRedemption::first();

        // Admin cancel (call the service/controller method directly).
        $admin = new \App\Http\Controllers\Admin\RewardController();
        $admin->cancelRewardRedemption($redemption->id);

        $user->refresh();
        $product->refresh();
        $redemption->refresh();
        $this->assertSame(0, (int) $user->points_spent);   // refunded
        $this->assertSame(10, (int) $product->stock);       // restored
        $this->assertSame('cancelled', $redemption->status);

        // Idempotent: second cancel does not double-refund.
        $admin->cancelRewardRedemption($redemption->id);
        $user->refresh();
        $this->assertSame(0, (int) $user->points_spent);
    }
}
