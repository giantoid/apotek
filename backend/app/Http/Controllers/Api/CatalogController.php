<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\MedicineResource;
use App\Models\Category;
use App\Models\Medicine;
use App\Services\DashboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CatalogController extends Controller
{
    public function dashboard(DashboardService $dashboard): JsonResponse
    {
        return response()->json(['data' => $dashboard->summary()]);
    }

    public function categories(): AnonymousResourceCollection
    {
        return CategoryResource::collection(Category::orderBy('name')->get());
    }

    public function medicines(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'category_id' => ['nullable', 'integer'],
            'filter' => ['nullable', 'in:low_stock,expiring'],
        ]);

        $medicines = Medicine::query()
            ->with('category')
            ->search($request->string('search')->toString())
            ->when($request->filled('category_id'), fn ($q) => $q->where('category_id', $request->integer('category_id')))
            ->when($request->input('filter') === 'low_stock', fn ($q) => $q->lowStock())
            ->when($request->input('filter') === 'expiring', fn ($q) => $q->expiringSoon()->orderBy('expiry_date'))
            ->orderBy('name')
            ->paginate(15)
            ->withQueryString();

        return MedicineResource::collection($medicines);
    }

    public function medicine(Medicine $medicine): MedicineResource
    {
        return new MedicineResource($medicine->load('category'));
    }

    public function medicineBySku(string $sku): MedicineResource
    {
        $medicine = Medicine::with('category')->where('sku', $sku)->firstOrFail();

        return new MedicineResource($medicine);
    }
}
