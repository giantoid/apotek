<?php

namespace Tests\Feature\Admin;

use App\Enums\Role;
use App\Models\Category;
use App\Models\Medicine;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
        $this->admin = User::factory()->create(['role' => Role::Admin]);
    }

    public function test_admin_can_login_but_cashier_cannot(): void
    {
        $this->post('/login', ['email' => $this->admin->email, 'password' => 'password'])
            ->assertRedirect(route('admin.dashboard'));
        $this->post('/logout');

        $kasir = User::factory()->create(['role' => Role::Kasir]);
        $this->post('/login', ['email' => $kasir->email, 'password' => 'password'])
            ->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_guest_is_redirected_to_login(): void
    {
        $this->get('/admin')->assertRedirect('/login');
    }

    public function test_all_admin_pages_render(): void
    {
        $medicine = Medicine::factory()->create();
        $sale = Sale::factory()->create();

        $this->actingAs($this->admin);

        foreach ([
            route('admin.dashboard'),
            route('admin.medicines.index'),
            route('admin.medicines.index', ['filter' => 'low_stock', 'search' => 'a']),
            route('admin.medicines.create'),
            route('admin.medicines.show', $medicine),
            route('admin.medicines.edit', $medicine),
            route('admin.sales.index'),
            route('admin.sales.show', $sale),
            route('admin.categories.index'),
        ] as $url) {
            $this->get($url)->assertOk();
        }
    }

    public function test_create_medicine_records_initial_stock(): void
    {
        $category = Category::factory()->create();

        $this->actingAs($this->admin)->post(route('admin.medicines.store'), [
            'sku' => 'OBT-9999',
            'name' => 'Obat Baru',
            'category_id' => $category->id,
            'unit' => 'strip',
            'price' => 5000,
            'stock' => 40,
            'min_stock' => 10,
            'expiry_date' => today()->addYear()->toDateString(),
        ])->assertRedirect();

        $medicine = Medicine::where('sku', 'OBT-9999')->firstOrFail();
        $this->assertSame(40, $medicine->stock);
        $this->assertDatabaseHas('stock_movements', ['medicine_id' => $medicine->id, 'quantity' => 40, 'note' => 'Stok awal']);
    }

    public function test_update_medicine_cannot_change_stock_directly(): void
    {
        $medicine = Medicine::factory()->create(['stock' => 10]);

        $this->actingAs($this->admin)->put(route('admin.medicines.update', $medicine), [
            'sku' => $medicine->sku, 'name' => 'Nama Baru', 'category_id' => $medicine->category_id,
            'unit' => 'strip', 'price' => 1000, 'min_stock' => 5,
            'expiry_date' => today()->addYear()->toDateString(), 'stock' => 999,
        ])->assertSessionHasErrors('stock');

        $this->assertSame(10, $medicine->fresh()->stock);
    }

    public function test_sales_csv_export(): void
    {
        Sale::factory()->count(3)->create();

        $response = $this->actingAs($this->admin)->get(route('admin.sales.export'));

        $response->assertOk();
        $this->assertCount(4, array_filter(explode("\n", $response->streamedContent())));
    }

    public function test_category_in_use_cannot_be_deleted(): void
    {
        $medicine = Medicine::factory()->create();

        $this->actingAs($this->admin)
            ->delete(route('admin.categories.destroy', $medicine->category_id))
            ->assertSessionHas('error');

        $this->assertDatabaseHas('categories', ['id' => $medicine->category_id]);
    }
}
