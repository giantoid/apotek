<x-layouts.app :title="'Transaksi '.$sale->invoice_number" :subtitle="$sale->created_at->translatedFormat('l, d F Y H:i').' · Kasir: '.$sale->cashier->name">
    <x-slot:actions>
        <button onclick="window.print()" class="btn-secondary">Cetak Struk</button>
        <a href="{{ route('admin.sales.index') }}" class="btn-secondary">Kembali</a>
    </x-slot:actions>

    <div class="card max-w-2xl p-6">
        <div class="mb-4 border-b border-dashed border-slate-300 pb-4 text-center">
            <p class="text-lg font-semibold">{{ config('app.name') }}</p>
            <p class="text-xs text-slate-500">Pekanbaru, Riau</p>
            <p class="mt-2 font-mono text-sm">{{ $sale->invoice_number }}</p>
        </div>

        <table class="w-full text-sm">
            <thead class="text-left text-xs text-slate-500 uppercase">
            <tr><th class="pb-2">Obat</th><th class="pb-2 text-right">Qty</th><th class="pb-2 text-right">Harga</th><th class="pb-2 text-right">Subtotal</th></tr>
            </thead>
            <tbody>
            @foreach ($sale->items as $item)
                <tr class="border-t border-slate-100">
                    <td class="py-2">{{ $item->medicine_name }}</td>
                    <td class="py-2 text-right">{{ $item->quantity }}</td>
                    <td class="py-2 text-right">{{ rupiah($item->price) }}</td>
                    <td class="py-2 text-right">{{ rupiah($item->subtotal) }}</td>
                </tr>
            @endforeach
            </tbody>
        </table>

        <dl class="mt-4 space-y-1 border-t border-dashed border-slate-300 pt-4 text-sm">
            <div class="flex justify-between text-base font-semibold"><dt>Total</dt><dd>{{ rupiah($sale->total) }}</dd></div>
            <div class="flex justify-between"><dt>Bayar</dt><dd>{{ rupiah($sale->paid_amount) }}</dd></div>
            <div class="flex justify-between"><dt>Kembalian</dt><dd>{{ rupiah($sale->change_amount) }}</dd></div>
        </dl>

        @if ($sale->note)
            <p class="mt-4 rounded-lg bg-slate-50 p-3 text-sm text-slate-600">Catatan: {{ $sale->note }}</p>
        @endif
    </div>
</x-layouts.app>
