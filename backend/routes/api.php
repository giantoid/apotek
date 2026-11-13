<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\StockMovementController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:10,1')
        ->name('login');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('auth/me', [AuthController::class, 'me'])->name('me');
        Route::post('auth/logout', [AuthController::class, 'logout'])->name('logout');

        Route::get('dashboard', [CatalogController::class, 'dashboard'])->name('dashboard');
        Route::get('categories', [CatalogController::class, 'categories'])->name('categories');
        Route::get('medicines', [CatalogController::class, 'medicines'])->name('medicines.index');
        Route::get('medicines/sku/{sku}', [CatalogController::class, 'medicineBySku'])->name('medicines.sku');
        Route::get('medicines/{medicine}', [CatalogController::class, 'medicine'])->name('medicines.show');

        Route::get('sales', [SaleController::class, 'index'])->name('sales.index');
        Route::post('sales', [SaleController::class, 'store'])->name('sales.store');
        Route::get('sales/{sale}', [SaleController::class, 'show'])->name('sales.show');

        Route::post('stock-movements', [StockMovementController::class, 'store'])->name('stock-movements.store');
    });
});
