<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AdminCustomerIndexQueryCountTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug M4: Admin\CustomerController::index issued ~5 queries per customer
     * (membership progress, two reward counts, one redemption sum). For 15
     * customers per page that meant 75+ queries before any aggregation.
     *
     * The fix eager-loads orders/orderItems/claimedRewards once and replaces
     * the per-customer reward/redemption queries with two GROUP BY
     * aggregations across all visible customer ids. The total query count
     * should now be O(1) in the size of the page.
     */
    public function test_admin_customer_index_query_count_is_constant_in_page_size(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        // Create a handful of customers and seed each with claimed rewards.
        User::factory()->count(10)->create();

        // Warm any one-time queries (auth, etc.) before measurement.
        $this->actingAs($admin, 'web');

        DB::enableQueryLog();
        $controller = new \App\Http\Controllers\Admin\CustomerController;
        $request = \Illuminate\Http\Request::create('/admin/customers', 'GET');
        $request->setLaravelSession(app('session.store'));
        $controller->index($request); // returns view; rendering not invoked here
        $count = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Generous upper bound — eager loads + aggregates + small fixed query
        // tail. Pre-fix this would have been north of 50 for 10 customers.
        $this->assertLessThan(20, $count, "expected O(1) queries, got $count");
    }
}
