<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPaymentSlipRouteTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug H9: admin-only methods used to live on the customer-facing
     * PaymentSlipController. The fix moves them to a dedicated
     * Admin\PaymentSlipController class so route registration cannot
     * accidentally expose status updates without admin middleware.
     */
    public function test_admin_methods_live_on_admin_controller(): void
    {
        $this->assertFalse(
            method_exists(\App\Http\Controllers\PaymentSlipController::class, 'adminUpdateStatus'),
            'adminUpdateStatus must not exist on the public controller'
        );
        $this->assertFalse(
            method_exists(\App\Http\Controllers\PaymentSlipController::class, 'adminIndex'),
            'adminIndex must not exist on the public controller'
        );
        $this->assertTrue(
            method_exists(\App\Http\Controllers\Admin\PaymentSlipController::class, 'adminUpdateStatus')
        );
        $this->assertTrue(
            method_exists(\App\Http\Controllers\Admin\PaymentSlipController::class, 'adminIndex')
        );
    }

    public function test_admin_payment_slip_route_is_behind_admin_middleware(): void
    {
        $route = collect(\Route::getRoutes()->getRoutes())
            ->first(fn ($r) => $r->getName() === 'admin.payment-slips.update.status');

        $this->assertNotNull($route);
        $middleware = $route->gatherMiddleware();
        $this->assertContains('admin', $middleware, 'admin payment-slip route must require admin middleware');
    }
}
