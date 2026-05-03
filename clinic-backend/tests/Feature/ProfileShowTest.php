<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileShowTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Bug M1: GET /api/profile substituted hard-coded fake address strings
     * for missing user data. The frontend rendered those as if they were
     * real, which is dangerous for shipping. Empty fields must come back
     * as null so the UI can prompt the user to fill them in.
     */
    public function test_profile_returns_null_for_unset_fields(): void
    {
        $user = User::factory()->create([
            'phone' => null,
            'address' => null,
            'district' => null,
            'province' => null,
            'postal_code' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/profile');

        $response->assertStatus(200);
        $response->assertJsonPath('profile.phone', null);
        $response->assertJsonPath('profile.address', null);
        $response->assertJsonPath('profile.district', null);
        $response->assertJsonPath('profile.province', null);
        $response->assertJsonPath('profile.postalCode', null);
    }

    public function test_profile_returns_actual_values_when_set(): void
    {
        $user = User::factory()->create([
            'phone' => '0812345678',
            'address' => 'My real address',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/profile');
        $response->assertJsonPath('profile.phone', '0812345678');
        $response->assertJsonPath('profile.address', 'My real address');
    }
}
