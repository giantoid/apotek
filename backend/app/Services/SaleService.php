<?php

namespace App\Services;

use App\Enums\StockMovementType;
use App\Models\Medicine;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaleService
{
    /**
     * Membuat transaksi penjualan.
     *
     * Harga selalu diambil dari database (bukan dari klien), stok dikunci
     * (SELECT ... FOR UPDATE) agar dua kasir tidak menjual stok yang sama,
     * dan seluruh proses berjalan dalam satu transaksi database.
     *
     * @param  array<int, array{medicine_id: int, quantity: int}>  $items
     */
    public function checkout(User $cashier, array $items, int $paidAmount, ?string $note = null): Sale
    {
        $items = $this->mergeDuplicateItems($items);

        return DB::transaction(function () use ($cashier, $items, $paidAmount, $note) {
            $medicines = Medicine::query()
                ->whereIn('id', array_keys($items))
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            $errors = [];
            $total = 0;

            foreach ($items as $medicineId => $quantity) {
                $medicine = $medicines->get($medicineId);

                if ($medicine->isExpired()) {
                    $errors['items'][] = "{$medicine->name} sudah kedaluwarsa dan tidak boleh dijual.";
                } elseif ($medicine->stock < $quantity) {
                    $errors['items'][] = "Stok {$medicine->name} tidak cukup (tersisa {$medicine->stock}).";
                }

                $total += $medicine->price * $quantity;
            }

            if ($errors) {
                throw ValidationException::withMessages($errors);
            }

            if ($paidAmount < $total) {
                throw ValidationException::withMessages([
                    'paid_amount' => ['Jumlah bayar kurang dari total belanja ('.rupiah($total).').'],
                ]);
            }

            $sale = Sale::create([
                'invoice_number' => $this->nextInvoiceNumber(),
                'user_id' => $cashier->id,
                'total' => $total,
                'paid_amount' => $paidAmount,
                'change_amount' => $paidAmount - $total,
                'note' => $note,
            ]);

            foreach ($items as $medicineId => $quantity) {
                $medicine = $medicines->get($medicineId);

                $sale->items()->create([
                    'medicine_id' => $medicine->id,
                    'medicine_name' => $medicine->name,
                    'quantity' => $quantity,
                    'price' => $medicine->price,
                    'subtotal' => $medicine->price * $quantity,
                ]);

                $medicine->decrement('stock', $quantity);

                $medicine->stockMovements()->create([
                    'user_id' => $cashier->id,
                    'type' => StockMovementType::Out,
                    'quantity' => -$quantity,
                    'stock_after' => $medicine->stock,
                    'sale_id' => $sale->id,
                    'note' => "Penjualan {$sale->invoice_number}",
                ]);
            }

            return $sale->load(['items', 'cashier']);
        });
    }

    /**
     * @param  array<int, array{medicine_id: int, quantity: int}>  $items
     * @return array<int, int> medicine_id => quantity
     */
    private function mergeDuplicateItems(array $items): array
    {
        $merged = [];

        foreach ($items as $item) {
            $id = (int) $item['medicine_id'];
            $merged[$id] = ($merged[$id] ?? 0) + (int) $item['quantity'];
        }

        return $merged;
    }

    private function nextInvoiceNumber(): string
    {
        $prefix = 'INV-'.now()->format('Ymd').'-';

        $last = Sale::query()
            ->where('invoice_number', 'like', $prefix.'%')
            ->lockForUpdate()
            ->max('invoice_number');

        $sequence = $last ? ((int) substr($last, -4)) + 1 : 1;

        return $prefix.str_pad((string) $sequence, 4, '0', STR_PAD_LEFT);
    }
}
