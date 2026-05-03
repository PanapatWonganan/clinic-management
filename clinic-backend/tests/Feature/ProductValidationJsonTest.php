<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductValidationJsonTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug H10: ProductController used $request->validate() which throws on
     * failure; without the right Accept header that turns into HTML, not
     * the JSON 422 the rest of the API contracts on. Switch to
     * Validator::make + return JSON for consistency.
     */
    public function test_create_product_returns_json_422_on_invalid_payload(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/products', [
                // Missing required name + price + stock.
            ]);

        $response->assertStatus(422);
        $response->assertJson([
            'success' => false,
        ]);
        $response->assertJsonStructure(['errors']);
    }

    public function test_update_stock_returns_json_422_on_invalid_payload(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $product = \App\Models\Product::create([
            'name' => 'X', 'price' => 100, 'stock' => 1, 'category' => 'main', 'is_active' => true,
        ]);

        $response = $this->actingAs($admin, 'sanctum')
            ->putJson('/api/products/'.$product->id.'/stock', [
                'quantity' => -5,
            ]);

        $response->assertStatus(422);
        $response->assertJsonStructure(['errors']);
    }
}
