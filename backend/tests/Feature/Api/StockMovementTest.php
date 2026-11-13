<?php

namespace Tests\Feature\Api;

use App\Enums\Role;
use App\Models\Medicine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StockMovementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_add_stock(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => Role::Admin]));
        $medicine = Medicine::factory()->create(['stock' => 10]);

        $this->postJson('/api/v1/stock-movements', [
            'medicine_id' => $medicine->id,
            'type' => 'in',
            'quantity' => 25,
            'note' => 'Faktur #123',
        ])->assertCreated()->assertJsonPath('data.stock_after', 35);

        $this->assertSame(35, $medicine->fresh()->stock);
    }

    public function test_adjustment_cannot_make_stock_negative(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => Role::Admin]));
        $medicine = Medicine::factory()->create(['stock' => 5]);

        $this->postJson('/api/v1/stock-movements', [
            'medicine_id' => $medicine->id,
            'type' => 'adjustment',
            'quantity' => -6,
        ])->assertUnprocessable()->assertJsonValidationErrors('quantity');

        $this->assertSame(5, $medicine->fresh()->stock);
    }

    public function test_stock_in_must_be_positive(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => Role::Admin]));
        $medicine = Medicine::factory()->create();

        $this->postJson('/api/v1/stock-movements', [
            'medicine_id' => $medicine->id,
            'type' => 'in',
            'quantity' => -1,
        ])->assertUnprocessable();
    }

    public function test_cashier_cannot_change_stock(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => Role::Kasir]));
        $medicine = Medicine::factory()->create();

        $this->postJson('/api/v1/stock-movements', [
            'medicine_id' => $medicine->id,
            'type' => 'in',
            'quantity' => 10,
        ])->assertForbidden();
    }
}
