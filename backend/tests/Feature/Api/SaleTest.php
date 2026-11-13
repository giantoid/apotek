<?php

namespace Tests\Feature\Api;

use App\Enums\Role;
use App\Models\Medicine;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SaleTest extends TestCase
{
    use RefreshDatabase;

    private User $kasir;

    protected function setUp(): void
    {
        parent::setUp();
        $this->kasir = User::factory()->create(['role' => Role::Kasir]);
        Sanctum::actingAs($this->kasir);
    }

    public function test_checkout_creates_sale_and_decrements_stock(): void
    {
        $a = Medicine::factory()->create(['price' => 12000, 'stock' => 10]);
        $b = Medicine::factory()->create(['price' => 5000, 'stock' => 5]);

        $response = $this->postJson('/api/v1/sales', [
            'items' => [
                ['medicine_id' => $a->id, 'quantity' => 2],
                ['medicine_id' => $b->id, 'quantity' => 1],
            ],
            'paid_amount' => 50000,
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.total', 29000)
            ->assertJsonPath('data.change_amount', 21000)
            ->assertJsonPath('data.cashier.id', $this->kasir->id)
            ->assertJsonCount(2, 'data.items');

        $this->assertMatchesRegularExpression('/^INV-\d{8}-0001$/', $response->json('data.invoice_number'));
        $this->assertSame(8, $a->fresh()->stock);
        $this->assertSame(4, $b->fresh()->stock);
        $this->assertDatabaseHas('stock_movements', ['medicine_id' => $a->id, 'type' => 'out', 'quantity' => -2, 'stock_after' => 8]);
    }

    public function test_price_comes_from_server_not_client(): void
    {
        $medicine = Medicine::factory()->create(['price' => 10000]);

        $this->postJson('/api/v1/sales', [
            'items' => [['medicine_id' => $medicine->id, 'quantity' => 1, 'price' => 1]],
            'paid_amount' => 10000,
        ])->assertCreated()->assertJsonPath('data.total', 10000);
    }

    public function test_duplicate_items_are_merged(): void
    {
        $medicine = Medicine::factory()->create(['price' => 1000, 'stock' => 3]);

        $this->postJson('/api/v1/sales', [
            'items' => [
                ['medicine_id' => $medicine->id, 'quantity' => 2],
                ['medicine_id' => $medicine->id, 'quantity' => 2],
            ],
            'paid_amount' => 10000,
        ])->assertUnprocessable()->assertJsonValidationErrors('items');

        $this->assertSame(3, $medicine->fresh()->stock);
    }

    public function test_rejects_insufficient_stock_without_side_effects(): void
    {
        $medicine = Medicine::factory()->create(['stock' => 1]);

        $this->postJson('/api/v1/sales', [
            'items' => [['medicine_id' => $medicine->id, 'quantity' => 5]],
            'paid_amount' => 1_000_000,
        ])->assertUnprocessable()->assertJsonValidationErrors('items');

        $this->assertSame(1, $medicine->fresh()->stock);
        $this->assertDatabaseCount('sales', 0);
    }

    public function test_rejects_expired_medicine(): void
    {
        $medicine = Medicine::factory()->expired()->create();

        $this->postJson('/api/v1/sales', [
            'items' => [['medicine_id' => $medicine->id, 'quantity' => 1]],
            'paid_amount' => 1_000_000,
        ])->assertUnprocessable()->assertJsonValidationErrors('items');
    }

    public function test_rejects_underpayment(): void
    {
        $medicine = Medicine::factory()->create(['price' => 20000]);

        $this->postJson('/api/v1/sales', [
            'items' => [['medicine_id' => $medicine->id, 'quantity' => 1]],
            'paid_amount' => 10000,
        ])->assertUnprocessable()->assertJsonValidationErrors('paid_amount');
    }

    public function test_rejects_empty_cart(): void
    {
        $this->postJson('/api/v1/sales', ['items' => [], 'paid_amount' => 0])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items');
    }

    public function test_invoice_number_increments(): void
    {
        $medicine = Medicine::factory()->create(['price' => 1000]);
        $payload = ['items' => [['medicine_id' => $medicine->id, 'quantity' => 1]], 'paid_amount' => 1000];

        $this->postJson('/api/v1/sales', $payload);
        $second = $this->postJson('/api/v1/sales', $payload);

        $this->assertStringEndsWith('-0002', $second->json('data.invoice_number'));
    }

    public function test_cashier_only_sees_own_sales_but_admin_sees_all(): void
    {
        $other = User::factory()->create(['role' => Role::Kasir]);
        $mine = Sale::factory()->create(['user_id' => $this->kasir->id]);
        $theirs = Sale::factory()->create(['user_id' => $other->id]);

        $this->getJson('/api/v1/sales')->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $mine->id);
        $this->getJson("/api/v1/sales/{$theirs->id}")->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => Role::Admin]));
        $this->getJson('/api/v1/sales')->assertJsonCount(2, 'data');
        $this->getJson("/api/v1/sales/{$theirs->id}")->assertOk();
    }
}
