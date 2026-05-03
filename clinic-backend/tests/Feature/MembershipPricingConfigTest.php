<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MembershipPricingConfigTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug M2: the exDoctor 850 override was hard-coded in two places. The
     * fix moves it to config('membership.main_product_price_overrides') so
     * both the main-products and category-filtered list pick it up from
     * the same source.
     */
    public function test_exdoctor_price_override_picked_up_from_config(): void
    {
        config(['membership.main_product_price_overrides' => ['exDoctor' => 999.0]]);

        $user = User::factory()->create(['membership_type' => 'exDoctor']);
        Product::create([
            'name' => 'Main A', 'price' => 1500, 'stock' => 10,
            'category' => 'main', 'is_active' => true,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/products/main');

        $response->assertStatus(200);
        $price = $response->json('data.0.price');
        $this->assertSame(999.0, (float) $price);
    }

    public function test_non_doctor_membership_keeps_default_price(): void
    {
        config(['membership.main_product_price_overrides' => ['exDoctor' => 999.0]]);

        $user = User::factory()->create(['membership_type' => 'exMember']);
        Product::create([
            'name' => 'Main B', 'price' => 1500, 'stock' => 10,
            'category' => 'main', 'is_active' => true,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/products/main');
        $price = $response->json('data.0.price');
        $this->assertSame(1500.0, (float) $price);
    }
}
