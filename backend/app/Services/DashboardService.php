<?php

namespace App\Services;

use App\Models\Medicine;
use App\Models\Sale;

class DashboardService
{
    /**
     * @return array{today_sales_total: int, today_transactions: int, low_stock_count: int, expiring_soon_count: int, medicine_count: int}
     */
    public function summary(): array
    {
        $today = Sale::query()->whereDate('created_at', today());

        return [
            'today_sales_total' => (int) (clone $today)->sum('total'),
            'today_transactions' => (clone $today)->count(),
            'low_stock_count' => Medicine::lowStock()->count(),
            'expiring_soon_count' => Medicine::expiringSoon()->count(),
            'medicine_count' => Medicine::count(),
        ];
    }

    /**
     * Total penjualan per hari selama $days hari terakhir (untuk grafik).
     *
     * @return array<string, int> 'Y-m-d' => total
     */
    public function dailySales(int $days = 7): array
    {
        $start = today()->subDays($days - 1);

        $rows = Sale::query()
            ->where('created_at', '>=', $start)
            ->get(['total', 'created_at'])
            ->groupBy(fn (Sale $sale) => $sale->created_at->toDateString())
            ->map(fn ($sales) => (int) $sales->sum('total'));

        $result = [];
        for ($date = $start->copy(); $date->lte(today()); $date->addDay()) {
            $result[$date->toDateString()] = $rows->get($date->toDateString(), 0);
        }

        return $result;
    }
}
