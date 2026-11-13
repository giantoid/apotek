<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Medicine;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Services\DashboardService;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(DashboardService $dashboard): View
    {
        $topMedicines = SaleItem::query()
            ->select('medicine_name', DB::raw('SUM(quantity) as qty'), DB::raw('SUM(subtotal) as revenue'))
            ->whereHas('sale', fn ($q) => $q->where('created_at', '>=', today()->subDays(6)))
            ->groupBy('medicine_name')
            ->orderByDesc('qty')
            ->limit(5)
            ->get();

        return view('admin.dashboard', [
            'summary' => $dashboard->summary(),
            'dailySales' => $dashboard->dailySales(7),
            'topMedicines' => $topMedicines,
            'lowStock' => Medicine::lowStock()->orderBy('stock')->limit(5)->get(),
            'expiring' => Medicine::expiringSoon()->orderBy('expiry_date')->limit(5)->get(),
            'recentSales' => Sale::with('cashier')->latest('id')->limit(5)->get(),
        ]);
    }
}
