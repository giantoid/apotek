<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class SaleController extends Controller
{
    public function index(Request $request): View
    {
        $query = $this->filteredQuery($request);

        return view('admin.sales.index', [
            'sales' => (clone $query)->with('cashier')->latest('id')->paginate(15)->withQueryString(),
            'total' => (int) (clone $query)->sum('total'),
            'count' => (clone $query)->count(),
            'cashiers' => User::orderBy('name')->get(),
        ]);
    }

    public function show(Sale $sale): View
    {
        return view('admin.sales.show', ['sale' => $sale->load(['items', 'cashier'])]);
    }

    /**
     * Ekspor laporan penjualan ke CSV (bisa dibuka di Excel).
     */
    public function export(Request $request): StreamedResponse
    {
        $sales = $this->filteredQuery($request)->with('cashier')->oldest('id')->get();
        $filename = 'laporan-penjualan-'.now()->format('Ymd-His').'.csv';

        return response()->streamDownload(function () use ($sales) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['No. Invoice', 'Tanggal', 'Kasir', 'Total', 'Bayar', 'Kembalian']);

            foreach ($sales as $sale) {
                fputcsv($out, [
                    $sale->invoice_number,
                    $sale->created_at->format('Y-m-d H:i'),
                    $sale->cashier->name,
                    $sale->total,
                    $sale->paid_amount,
                    $sale->change_amount,
                ]);
            }

            fclose($out);
        }, $filename, ['Content-Type' => 'text/csv']);
    }

    private function filteredQuery(Request $request)
    {
        $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'user_id' => ['nullable', 'integer'],
        ]);

        return Sale::query()
            ->when($request->filled('from'), fn ($q) => $q->whereDate('created_at', '>=', $request->date('from')))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('created_at', '<=', $request->date('to')))
            ->when($request->filled('user_id'), fn ($q) => $q->where('user_id', $request->integer('user_id')))
            ->when($request->filled('search'), fn ($q) => $q->where('invoice_number', 'like', '%'.$request->input('search').'%'));
    }
}
