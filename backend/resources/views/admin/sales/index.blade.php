<x-layouts.app title="Laporan Penjualan" :subtitle="$count.' transaksi · total '.rupiah($total)">
    <x-slot:actions>
        <a href="{{ route('admin.sales.export', request()->query()) }}" class="btn-secondary">Ekspor CSV</a>
    </x-slot:actions>

    <form method="GET" class="card flex flex-wrap items-end gap-3 p-4">
        <div>
            <label class="label" for="search">No. Invoice</label>
            <input id="search" name="search" value="{{ request('search') }}" class="input" placeholder="INV-...">
        </div>
        <div>
            <label class="label" for="from">Dari</label>
            <input id="from" name="from" type="date" value="{{ request('from') }}" class="input">
        </div>
        <div>
            <label class="label" for="to">Sampai</label>
            <input id="to" name="to" type="date" value="{{ request('to') }}" class="input">
        </div>
        <div>
            <label class="label" for="user_id">Kasir</label>
            <select id="user_id" name="user_id" class="input">
                <option value="">Semua</option>
                @foreach ($cashiers as $u)
                    <option value="{{ $u->id }}" @selected(request('user_id') == $u->id)>{{ $u->name }}</option>
                @endforeach
            </select>
        </div>
        <button class="btn-secondary">Terapkan</button>
        @if (request()->hasAny(['search', 'from', 'to', 'user_id']))
            <a href="{{ route('admin.sales.index') }}" class="text-sm text-slate-500 underline">Reset</a>
        @endif
    </form>

    <div class="card overflow-x-auto">
        <table class="table">
            <thead><tr><th>No. Invoice</th><th>Waktu</th><th>Kasir</th><th class="text-right!">Total</th><th class="text-right!">Bayar</th><th class="text-right!">Kembali</th></tr></thead>
            <tbody class="divide-y divide-slate-100">
            @forelse ($sales as $sale)
                <tr class="cursor-pointer" onclick="location='{{ route('admin.sales.show', $sale) }}'">
                    <td class="font-mono text-xs font-medium text-slate-900">{{ $sale->invoice_number }}</td>
                    <td>{{ $sale->created_at->translatedFormat('d M Y H:i') }}</td>
                    <td>{{ $sale->cashier->name }}</td>
                    <td class="text-right font-medium">{{ rupiah($sale->total) }}</td>
                    <td class="text-right">{{ rupiah($sale->paid_amount) }}</td>
                    <td class="text-right">{{ rupiah($sale->change_amount) }}</td>
                </tr>
            @empty
                <tr><td colspan="6" class="py-10 text-center text-slate-500">Tidak ada transaksi.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>

    {{ $sales->links() }}
</x-layouts.app>
