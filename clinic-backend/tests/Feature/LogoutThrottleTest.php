<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LogoutThrottleTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug H7: /auth/logout had no throttle so a leaked or replayed token
     * could be pumped through it without limit. Cap at 30/min like the
     * other auth endpoints.
     */
    public function test_logout_route_has_throttle_middleware(): void
    {
        $route = collect(\Route::getRoutes()->getRoutes())
            ->first(fn ($r) => $r->uri() === 'api/auth/logout');

        $this->assertNotNull($route, 'auth/logout route must be registered');
        $middleware = $route->gatherMiddleware();
        $hasThrottle = collect($middleware)->contains(fn ($m) => str_starts_with($m, 'throttle:'));
        $this->assertTrue($hasThrottle, 'logout must have throttle middleware');
    }
}
