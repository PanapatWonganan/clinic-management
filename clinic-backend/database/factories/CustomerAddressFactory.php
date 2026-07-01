<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\CustomerAddress>
 */
class CustomerAddressFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => 'บ้าน',
            'recipient_name' => fake()->name(),
            'phone' => '08' . fake()->numerify('########'),
            'address_line_1' => fake()->streetAddress(),
            'address_line_2' => null,
            'district' => 'ลาดกระบัง',
            'province' => 'กรุงเทพมหานคร',
            'postal_code' => '10520',
            'province_id' => 1,
            'district_id' => 1,
            'sub_district_id' => 1,
            'is_default' => false,
        ];
    }
}
