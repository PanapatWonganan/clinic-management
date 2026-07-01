<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Order>
 */
class OrderFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'order_number' => 'ORD-' . strtoupper(Str::random(8)),
            'user_id' => User::factory(),
            'total_amount' => fake()->randomFloat(2, 100, 10000),
            'status' => 'paid',
            'delivery_method' => 'delivery',
            'payment_method' => 'transfer',
            'is_free_item_order' => false,
        ];
    }
}
