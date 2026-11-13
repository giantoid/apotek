<?php

use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\LoginController;
use App\Http\Controllers\Admin\MedicineController;
use App\Http\Controllers\Admin\SaleController;
use App\Http\Controllers\Admin\StockMovementController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

Route::middleware('guest')->group(function () {
    Route::get('login', [LoginController::class, 'create'])->name('login');
    Route::post('login', [LoginController::class, 'store'])->middleware('throttle:10,1');
});

Route::post('logout', [LoginController::class, 'destroy'])->middleware('auth')->name('logout');

Route::prefix('admin')->name('admin.')->middleware(['auth', 'admin'])->group(function () {
    Route::get('/', DashboardController::class)->name('dashboard');
    Route::resource('medicines', MedicineController::class);
    Route::post('stock-movements', [StockMovementController::class, 'store'])->name('stock-movements.store');
    Route::get('sales/export', [SaleController::class, 'export'])->name('sales.export');
    Route::resource('sales', SaleController::class)->only(['index', 'show']);
    Route::resource('categories', CategoryController::class)->only(['index', 'store', 'update', 'destroy']);
});
