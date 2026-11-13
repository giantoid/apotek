<?php

namespace App\Services;

use App\Enums\StockMovementType;
use App\Models\Medicine;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class StockService
{
    /**
     * Mencatat stok masuk atau penyesuaian stok (stock opname).
     */
    public function record(User $user, int $medicineId, StockMovementType $type, int $quantity, ?string $note = null): StockMovement
    {
        if ($type === StockMovementType::In && $quantity <= 0) {
            throw ValidationException::withMessages([
                'quantity' => ['Jumlah stok masuk harus lebih dari 0.'],
            ]);
        }

        if ($quantity === 0) {
            throw ValidationException::withMessages([
                'quantity' => ['Jumlah penyesuaian tidak boleh 0.'],
            ]);
        }

        return DB::transaction(function () use ($user, $medicineId, $type, $quantity, $note) {
            $medicine = Medicine::query()->lockForUpdate()->findOrFail($medicineId);

            $newStock = $medicine->stock + $quantity;

            if ($newStock < 0) {
                throw ValidationException::withMessages([
                    'quantity' => ["Stok tidak boleh minus (stok saat ini {$medicine->stock})."],
                ]);
            }

            $medicine->update(['stock' => $newStock]);

            return $medicine->stockMovements()->create([
                'user_id' => $user->id,
                'type' => $type,
                'quantity' => $quantity,
                'stock_after' => $newStock,
                'note' => $note,
            ]);
        });
    }
}
