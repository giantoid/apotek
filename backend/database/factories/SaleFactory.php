<?php

namespace Database\Factories;

use App\Models\Sale;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Sale>
 */
class SaleFactory extends Factory
{
    public function definition(): array
    {
        $total = fake()->numberBetween(1, 50) * 1000;

        return [
            'invoice_number' => 'INV-'.now()->format('Ymd').'-'.fake()->unique()->numerify('9###'),
            'user_id' => User::factory(),
            'total' => $total,
            'paid_amount' => $total,
            'change_amount' => 0,
        ];
    }
}
