<?php

namespace App\Http\Controllers\Admin;

use App\Enums\StockMovementType;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStockMovementRequest;
use App\Models\Medicine;
use App\Services\StockService;
use Illuminate\Http\RedirectResponse;

class StockMovementController extends Controller
{
    public function store(StoreStockMovementRequest $request, StockService $service): RedirectResponse
    {
        $service->record(
            $request->user(),
            $request->integer('medicine_id'),
            StockMovementType::from($request->validated('type')),
            $request->integer('quantity'),
            $request->validated('note'),
        );

        $medicine = Medicine::find($request->integer('medicine_id'));

        return redirect()->route('admin.medicines.show', $medicine)->with('success', "Stok {$medicine->name} sekarang {$medicine->stock} {$medicine->unit}.");
    }
}
