<?php

namespace Database\Seeders;

use App\Enums\Role;
use App\Models\Category;
use App\Models\Medicine;
use App\Models\Supplier;
use App\Models\User;
use App\Services\SaleService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DatabaseSeeder extends Seeder
{
    public function run(SaleService $sales): void
    {
        $admin = User::create([
            'name' => 'Admin Apotek',
            'email' => 'admin@apotek.test',
            'password' => 'password',
            'role' => Role::Admin,
        ]);

        $kasir = User::create([
            'name' => 'Kasir Demo',
            'email' => 'kasir@apotek.test',
            'password' => 'password',
            'role' => Role::Kasir,
        ]);

        $suppliers = collect([
            ['name' => 'PT Kimia Farma Trading & Distribution', 'phone' => '0761-123456', 'address' => 'Jl. Sudirman, Pekanbaru'],
            ['name' => 'PT Anugrah Pharmindo Lestari', 'phone' => '0761-654321', 'address' => 'Jl. Tuanku Tambusai, Pekanbaru'],
            ['name' => 'PT Enseval Putera Megatrading', 'phone' => '0761-777888', 'address' => 'Jl. Soekarno-Hatta, Pekanbaru'],
        ])->map(fn ($s) => Supplier::create($s));

        // [nama, kategori, satuan, harga, stok, min, bulan kedaluwarsa, resep]
        $data = [
            ['Paracetamol 500 mg', 'Analgesik & Antipiretik', 'strip', 5000, 150, 20, 24, false],
            ['Ibuprofen 400 mg', 'Analgesik & Antipiretik', 'strip', 9000, 80, 15, 18, false],
            ['Asam Mefenamat 500 mg', 'Analgesik & Antipiretik', 'strip', 7000, 6, 15, 20, false],
            ['Panadol Extra', 'Analgesik & Antipiretik', 'strip', 13500, 60, 10, 2, false],
            ['Amoxicillin 500 mg', 'Antibiotik', 'strip', 12000, 70, 15, 16, true],
            ['Cefadroxil 500 mg', 'Antibiotik', 'strip', 25000, 40, 10, 14, true],
            ['Ciprofloxacin 500 mg', 'Antibiotik', 'strip', 18000, 4, 10, 12, true],
            ['OBH Combi 100 ml', 'Obat Batuk & Flu', 'botol', 21000, 45, 10, 22, false],
            ['Woods Peppermint 60 ml', 'Obat Batuk & Flu', 'botol', 19500, 30, 10, 1, false],
            ['Decolgen', 'Obat Batuk & Flu', 'strip', 4500, 120, 20, 24, false],
            ['Mixagrip Flu', 'Obat Batuk & Flu', 'strip', 4000, 8, 20, 30, false],
            ['Promag', 'Saluran Pencernaan', 'strip', 9500, 90, 15, 26, false],
            ['Mylanta Cair 150 ml', 'Saluran Pencernaan', 'botol', 23000, 25, 10, 19, false],
            ['Diapet', 'Saluran Pencernaan', 'strip', 6500, 55, 10, 3, false],
            ['Omeprazole 20 mg', 'Saluran Pencernaan', 'strip', 15000, 35, 10, 15, true],
            ['Vitamin C 1000 mg', 'Vitamin & Suplemen', 'botol', 45000, 50, 10, 28, false],
            ['Sangobion', 'Vitamin & Suplemen', 'strip', 18500, 40, 10, 20, false],
            ['Imboost Force', 'Vitamin & Suplemen', 'strip', 42000, 9, 10, 17, false],
            ['Enervon-C', 'Vitamin & Suplemen', 'botol', 38000, 30, 10, 25, false],
            ['Amlodipine 10 mg', 'Kardiovaskular', 'strip', 8000, 60, 15, 21, true],
            ['Captopril 25 mg', 'Kardiovaskular', 'strip', 6000, 50, 15, -1, true],
            ['Metformin 500 mg', 'Diabetes', 'strip', 7500, 65, 15, 23, true],
            ['Glibenclamide 5 mg', 'Diabetes', 'strip', 5500, 45, 10, 19, true],
            ['Betadine 30 ml', 'Antiseptik & Luka', 'botol', 27000, 35, 10, 30, false],
            ['Hansaplast (isi 10)', 'Antiseptik & Luka', 'kotak', 12000, 80, 15, 36, false],
            ['Salep Kulit 88', 'Kulit', 'tube', 16000, 20, 10, 2, false],
            ['Caladine Lotion 95 ml', 'Kulit', 'botol', 24000, 28, 10, 24, false],
            ['Insto Regular 7,5 ml', 'Mata', 'botol', 15500, 40, 10, 18, false],
            ['Cetirizine 10 mg', 'Antialergi', 'strip', 10000, 55, 10, 22, false],
            ['Loratadine 10 mg', 'Antialergi', 'strip', 12500, 7, 10, 27, false],
        ];

        foreach ($data as $i => [$name, $category, $unit, $price, $stock, $min, $months, $rx]) {
            Medicine::create([
                'sku' => sprintf('OBT-%04d', $i + 1),
                'name' => $name,
                'category_id' => Category::firstOrCreate(['name' => $category])->id,
                'supplier_id' => $suppliers[$i % $suppliers->count()]->id,
                'unit' => $unit,
                'price' => $price,
                'stock' => $stock,
                'min_stock' => $min,
                'expiry_date' => today()->addMonths($months)->endOfMonth(),
                'requires_prescription' => $rx,
            ]);
        }

        $this->seedSalesHistory($sales, [$admin, $kasir]);
    }

    /**
     * Membuat riwayat penjualan 7 hari terakhir agar dashboard & laporan berisi data.
     *
     * @param  array<int, User>  $cashiers
     */
    private function seedSalesHistory(SaleService $sales, array $cashiers): void
    {
        $sellable = Medicine::whereDate('expiry_date', '>=', today())->where('stock', '>', 20)->pluck('id');
        $baseDate = today();

        for ($day = 6; $day >= 0; $day--) {
            $lastHour = $day === 0 ? max(8, min(20, now()->hour)) : 20;
            $count = min(fake()->numberBetween(3, 7), $lastHour - 7);
            $hours = collect(range(8, $lastHour))->random($count)->sort()->values();

            for ($n = 0; $n < $count; $n++) {
                Carbon::setTestNow($baseDate->copy()->subDays($day)->setTime($hours[$n], fake()->numberBetween(0, 59)));

                $items = $sellable->random(fake()->numberBetween(1, 3))
                    ->map(fn ($id) => ['medicine_id' => $id, 'quantity' => fake()->numberBetween(1, 3)])
                    ->all();

                $sales->checkout(fake()->randomElement($cashiers), $items, 1_000_000);
            }
        }

        Carbon::setTestNow();
    }
}
