<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MembershipUpgradeTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug H6: when a single from_type has multiple upgrade rules whose
     * min_spent thresholds are all met by the user, the controller picked
     * whatever the database returned first instead of the highest-tier
     * rule. A whale who deserves exSuperVip would get bumped to exVip.
     * The fix is orderBy('min_spent', 'desc').
     */
    public function test_picks_highest_qualifying_upgrade_when_multiple_rules_match(): void
    {
        // Add a 2nd, higher-tier rule from exMember directly (skipping exVip).
        DB::table('membership_upgrade_rules')->insert([
            'from_type' => 'exMember',
            'to_type' => 'exSuperVip',
            'min_spent' => 1000000.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $user = User::factory()->create([
            'membership_type' => 'exMember',
        ]);
        // Make total_spent comfortably exceed both thresholds (500k and 1M).
        Order::create([
            'order_number' => 'ORD-1',
            'user_id' => $user->id,
            'subtotal' => 2000000,
            'total_amount' => 2000000,
            'delivery_fee' => 0,
            'discount' => 0,
            'status' => 'confirmed',
            'delivery_method' => 'pickup',
            'payment_method' => 'transfer',
            'payment_status' => 'paid',
            'payment_slip_status' => 'approved',
        ]);

        $controller = new \App\Http\Controllers\ProfileController;
        $reflection = new \ReflectionMethod($controller, 'checkAndUpgradeMembership');
        $reflection->setAccessible(true);
        $reflection->invoke($controller, $user);

        $this->assertSame('exSuperVip', $user->fresh()->membership_type);
    }
}
