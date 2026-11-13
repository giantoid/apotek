<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSaleRequest;
use App\Http\Resources\SaleResource;
use App\Models\Sale;
use App\Services\SaleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SaleController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['date' => ['nullable', 'date']]);

        $user = $request->user();

        $sales = Sale::query()
            ->with('cashier')
            ->unless($user->isAdmin(), fn ($q) => $q->where('user_id', $user->id))
            ->when($request->filled('date'), fn ($q) => $q->whereDate('created_at', $request->date('date')))
            ->latest('id')
            ->paginate(15)
            ->withQueryString();

        return SaleResource::collection($sales);
    }

    public function show(Request $request, Sale $sale): SaleResource
    {
        abort_unless(
            $request->user()->isAdmin() || $sale->user_id === $request->user()->id,
            403,
            'Anda tidak berhak melihat transaksi ini.'
        );

        return new SaleResource($sale->load(['items', 'cashier']));
    }

    public function store(StoreSaleRequest $request, SaleService $service): JsonResponse
    {
        $sale = $service->checkout(
            $request->user(),
            $request->validated('items'),
            $request->integer('paid_amount'),
            $request->validated('note'),
        );

        return (new SaleResource($sale))->response()->setStatusCode(201);
    }
}
