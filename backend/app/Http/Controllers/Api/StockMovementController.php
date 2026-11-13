<?php

namespace App\Http\Controllers\Api;

use App\Enums\StockMovementType;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStockMovementRequest;
use App\Http\Resources\StockMovementResource;
use App\Services\StockService;
use Illuminate\Http\JsonResponse;

class StockMovementController extends Controller
{
    public function store(StoreStockMovementRequest $request, StockService $service): JsonResponse
    {
        $movement = $service->record(
            $request->user(),
            $request->integer('medicine_id'),
            StockMovementType::from($request->validated('type')),
            $request->integer('quantity'),
            $request->validated('note'),
        );

        return (new StockMovementResource($movement))->response()->setStatusCode(201);
    }
}
