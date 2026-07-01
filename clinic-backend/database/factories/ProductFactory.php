<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Product>
 */
class ProductFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->words(3, true),
            'description' => fake()->sentence(),
            'price' => fake()->randomFloat(2, 100, 5000),
            'points' => fake()->numberBetween(1, 100),
            'image_url' => null,
            'category' => 'main',
            'stock' => fake()->numberBetween(0, 100),
            'is_active' => true,
        ];
    }
}
