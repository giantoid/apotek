<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Medicine;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Medicine>
 */
class MedicineFactory extends Factory
{
    public function definition(): array
    {
        return [
            'sku' => 'OBT-'.fake()->unique()->numerify('#####'),
            'name' => ucfirst(fake()->unique()->word()).' '.fake()->randomElement(['250 mg', '500 mg', '10 ml', '60 ml']),
            'category_id' => Category::factory(),
            'unit' => fake()->randomElement(['strip', 'botol', 'tablet', 'tube']),
            'price' => fake()->numberBetween(2, 100) * 1000,
            'stock' => fake()->numberBetween(30, 200),
            'min_stock' => 10,
            'expiry_date' => today()->addMonths(fake()->numberBetween(6, 36)),
            'requires_prescription' => false,
        ];
    }

    public function lowStock(): static
    {
        return $this->state(fn () => ['stock' => 3, 'min_stock' => 10]);
    }

    public function expired(): static
    {
        return $this->state(fn () => ['expiry_date' => today()->subDay()]);
    }

    public function expiringSoon(): static
    {
        return $this->state(fn () => ['expiry_date' => today()->addDays(30)]);
    }
}
