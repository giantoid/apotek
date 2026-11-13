@php
    $maxDaily = max(1, max($dailySales));
    $cards = [
        ['Penjualan Hari Ini', rupiah($summary['today_sales_total']), $summary['today_transactions'].' transaksi', 'bg-emerald-50 text-emerald-700', route('admin.sales.index', ['from' => today()->toDateString(), 'to' => today()->toDateString()])],
        ['Total Jenis Obat', $summary['medicine_count'], 'terdaftar di sistem', 'bg-sky-50 text-sky-700', route('admin.medicines.index')],
        ['Stok Menipis', $summary['low_stock_count'], 'perlu dipesan ulang', 'bg-amber-50 text-amber-700', route('admin.medicines.index', ['filter' => 'low_stock'])],
        ['Segera Kedaluwarsa', $summary['expiring_soon_count'], '≤ '.\App\Models\Medicine::EXPIRING_SOON_DAYS.' hari', 'bg-rose-50 text-rose-700', route('admin.medicines.index', ['filter' => 'expiring'])],
    ];
@endphp

<x-layouts.app title="Dashboard" :subtitle="'Ringkasan apotek, '.now()->translatedFormat('l, d F Y')">
    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ($cards as [$label, $value, $hint, $color, $link])
            <a href="{{ $link }}" class="card p-5 transition hover:shadow-md">
                <p class="text-sm text-slate-500">{{ $label }}</p>
                <p class="mt-2 text-2xl font-semibold text-slate-900">{{ $value }}</p>
                <span class="mt-2 inline-block rounded-md px-2 py-0.5 text-xs font-medium {{ $color }}">{{ $hint }}</span>
            </a>
        @endforeach
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card p-5 lg:col-span-2">
            <h2 class="font-semibold text-slate-900">Penjualan 7 Hari Terakhir</h2>
            <p class="text-sm text-slate-500">Total {{ rupiah(array_sum($dailySales)) }}</p>
            <div class="mt-6 flex h-56 items-end gap-3">
                @foreach ($dailySales as $date => $amount)
                    <div class="flex flex-1 flex-col items-center gap-2">
                        <span class="text-[11px] text-slate-500">{{ $amount ? number_format($amount / 1000, 0, ',', '.').'rb' : '-' }}</span>
                        <div class="w-full rounded-t-md bg-emerald-500/90" style="height: {{ max(2, round($amount / $maxDaily * 170)) }}px"></div>
                        <span class="text-xs text-slate-600">{{ \Illuminate\Support\Carbon::parse($date)->translatedFormat('D d') }}</span>
                    </div>
                @endforeach
            </div>
        </div>

        <div class="card p-5">
            <h2 class="font-semibold text-slate-900">Obat Terlaris (7 hari)</h2>
            <ol class="mt-4 space-y-3">
                @forelse ($topMedicines as $i => $item)
                    <li class="flex items-center gap-3">
                        <span class="flex h-7 w-7 items-center justify-center rounded-full bg-emerald-100 text-xs font-semibold text-emerald-700">{{ $i + 1 }}</span>
                        <span class="flex-1 text-sm">{{ $item->medicine_name }}</span>
                        <span class="text-sm font-medium text-slate-900">{{ $item->qty }}</span>
                    </li>
                @empty
                    <li class="text-sm text-slate-500">Belum ada penjualan.</li>
                @endforelse
            </ol>
        </div>
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card p-5">
            <h2 class="mb-3 font-semibold text-slate-900">Stok Menipis</h2>
            @forelse ($lowStock as $m)
                <a href="{{ route('admin.medicines.show', $m) }}" class="flex items-center justify-between border-b border-slate-100 py-2 text-sm last:border-0 hover:text-emerald-700">
                    <span>{{ $m->name }}</span><span class="badge-amber">{{ $m->stock }} / min {{ $m->min_stock }}</span>
                </a>
            @empty
                <p class="text-sm text-slate-500">Semua stok aman.</p>
            @endforelse
        </div>

        <div class="card p-5">
            <h2 class="mb-3 font-semibold text-slate-900">Segera Kedaluwarsa</h2>
            @forelse ($expiring as $m)
                <a href="{{ route('admin.medicines.show', $m) }}" class="flex items-center justify-between border-b border-slate-100 py-2 text-sm last:border-0 hover:text-emerald-700">
                    <span>{{ $m->name }}</span>
                    <span class="{{ $m->isExpired() ? 'badge-red' : 'badge-amber' }}">{{ $m->isExpired() ? 'Kedaluwarsa' : $m->expiry_date->translatedFormat('d M Y') }}</span>
                </a>
            @empty
                <p class="text-sm text-slate-500">Tidak ada.</p>
            @endforelse
        </div>

        <div class="card p-5">
            <h2 class="mb-3 font-semibold text-slate-900">Transaksi Terakhir</h2>
            @foreach ($recentSales as $sale)
                <a href="{{ route('admin.sales.show', $sale) }}" class="flex items-center justify-between border-b border-slate-100 py-2 text-sm last:border-0 hover:text-emerald-700">
                    <span>
                        <span class="block font-medium">{{ $sale->invoice_number }}</span>
                        <span class="text-xs text-slate-500">{{ $sale->created_at->translatedFormat('d M H:i') }} · {{ $sale->cashier->name }}</span>
                    </span>
                    <span class="font-medium">{{ rupiah($sale->total) }}</span>
                </a>
            @endforeach
        </div>
    </div>
</x-layouts.app>
