<?php

namespace App\Http\Controllers\Admin;

use App\Enums\StockMovementType;
use App\Http\Controllers\Controller;
use App\Http\Requests\MedicineRequest;
use App\Models\Category;
use App\Models\Medicine;
use App\Models\Supplier;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class MedicineController extends Controller
{
    public function index(Request $request): View
    {
        $medicines = Medicine::query()
            ->with('category')
            ->search($request->string('search')->toString())
            ->when($request->filled('category_id'), fn ($q) => $q->where('category_id', $request->integer('category_id')))
            ->when($request->input('filter') === 'low_stock', fn ($q) => $q->lowStock())
            ->when($request->input('filter') === 'expiring', fn ($q) => $q->expiringSoon())
            ->orderBy('name')
            ->paginate(15)
            ->withQueryString();

        return view('admin.medicines.index', [
            'medicines' => $medicines,
            'categories' => Category::orderBy('name')->get(),
        ]);
    }

    public function create(): View
    {
        return view('admin.medicines.form', $this->formData(new Medicine([
            'min_stock' => 10,
            'sku' => sprintf('OBT-%04d', (Medicine::max('id') ?? 0) + 1),
        ])));
    }

    public function store(MedicineRequest $request): RedirectResponse
    {
        $medicine = Medicine::create($request->validated());

        if ($medicine->stock > 0) {
            $medicine->stockMovements()->create([
                'user_id' => $request->user()->id,
                'type' => StockMovementType::In,
                'quantity' => $medicine->stock,
                'stock_after' => $medicine->stock,
                'note' => 'Stok awal',
            ]);
        }

        return redirect()->route('admin.medicines.show', $medicine)->with('success', 'Obat berhasil ditambahkan.');
    }

    public function show(Medicine $medicine): View
    {
        return view('admin.medicines.show', [
            'medicine' => $medicine->load(['category', 'supplier']),
            'movements' => $medicine->stockMovements()->with('user')->latest('id')->paginate(10),
        ]);
    }

    public function edit(Medicine $medicine): View
    {
        return view('admin.medicines.form', $this->formData($medicine));
    }

    public function update(MedicineRequest $request, Medicine $medicine): RedirectResponse
    {
        $medicine->update($request->validated());

        return redirect()->route('admin.medicines.show', $medicine)->with('success', 'Data obat berhasil diperbarui.');
    }

    public function destroy(Medicine $medicine): RedirectResponse
    {
        if ($medicine->stockMovements()->whereNotNull('sale_id')->exists()) {
            return back()->with('error', 'Obat yang sudah pernah terjual tidak dapat dihapus.');
        }

        $medicine->delete();

        return redirect()->route('admin.medicines.index')->with('success', 'Obat berhasil dihapus.');
    }

    private function formData(Medicine $medicine): array
    {
        return [
            'medicine' => $medicine,
            'categories' => Category::orderBy('name')->get(),
            'suppliers' => Supplier::orderBy('name')->get(),
        ];
    }
}
