<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\RewardPointsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RewardPointsServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_balance_is_earned_minus_spent(): void
    {
        $user = User::factory()->create(['points_spent' => 3]);
        // No orders → earned 0. Balance floored at 0 even though spent is 3.
        $service = new RewardPointsService;

        $this->assertSame(0, $service->earnedPoints($user));
        $this->assertSame(0, $service->balance($user));
    }
}
