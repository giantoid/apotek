<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Medicine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MedicineTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->create());
    }

    public function test_lists_medicines_with_pagination_meta(): void
    {
        Medicine::factory()->count(20)->create();

        $this->getJson('/api/v1/medicines')
            ->assertOk()
            ->assertJsonCount(15, 'data')
            ->assertJsonPath('meta.total', 20)
            ->assertJsonStructure(['data' => [[
                'id', 'sku', 'name', 'category' => ['id', 'name'], 'unit', 'price', 'stock',
                'min_stock', 'expiry_date', 'requires_prescription', 'is_low_stock', 'is_expiring_soon',
            ]]]);
    }

    public function test_search_by_name_or_sku(): void
    {
        Medicine::factory()->create(['name' => 'Paracetamol 500 mg', 'sku' => 'OBT-0001']);
        Medicine::factory()->create(['name' => 'Amoxicillin 500 mg', 'sku' => 'OBT-0002']);

        $this->getJson('/api/v1/medicines?search=parace')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.sku', 'OBT-0001');

        $this->getJson('/api/v1/medicines?search=OBT-0002')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Amoxicillin 500 mg');
    }

    public function test_filter_low_stock_and_expiring(): void
    {
        Medicine::factory()->count(3)->create();
        $low = Medicine::factory()->lowStock()->create();
        $expiring = Medicine::factory()->expiringSoon()->create();

        $this->getJson('/api/v1/medicines?filter=low_stock')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $low->id)
            ->assertJsonPath('data.0.is_low_stock', true);

        $this->getJson('/api/v1/medicines?filter=expiring')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $expiring->id)
            ->assertJsonPath('data.0.is_expiring_soon', true);
    }

    public function test_filter_by_category(): void
    {
        $category = Category::factory()->create();
        Medicine::factory()->count(2)->create(['category_id' => $category->id]);
        Medicine::factory()->count(3)->create();

        $this->getJson("/api/v1/medicines?category_id={$category->id}")->assertJsonCount(2, 'data');
    }

    public function test_find_by_sku_for_barcode_scan(): void
    {
        Medicine::factory()->create(['sku' => '8991234567890']);

        $this->getJson('/api/v1/medicines/sku/8991234567890')->assertOk()->assertJsonPath('data.sku', '8991234567890');
        $this->getJson('/api/v1/medicines/sku/tidak-ada')->assertNotFound();
    }

    public function test_dashboard_summary(): void
    {
        Medicine::factory()->count(2)->create();
        Medicine::factory()->lowStock()->create();

        $this->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.medicine_count', 3)
            ->assertJsonPath('data.low_stock_count', 1)
            ->assertJsonPath('data.today_transactions', 0);
    }

    public function test_categories_list(): void
    {
        Category::factory()->count(3)->create();

        $this->getJson('/api/v1/categories')->assertOk()->assertJsonCount(3, 'data');
    }
}
