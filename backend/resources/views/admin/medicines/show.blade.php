<x-layouts.app :title="$medicine->name" :subtitle="$medicine->sku.' · '.$medicine->category->name">
    <x-slot:actions>
        <a href="{{ route('admin.medicines.edit', $medicine) }}" class="btn-secondary">Ubah</a>
        <form method="POST" action="{{ route('admin.medicines.destroy', $medicine) }}" onsubmit="return confirm('Hapus obat ini?')">
            @csrf @method('DELETE')
            <button class="btn-danger">Hapus</button>
        </form>
    </x-slot:actions>

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card p-5 lg:col-span-2">
            <dl class="grid gap-x-6 gap-y-4 sm:grid-cols-3">
                @foreach ([
                    'Harga Jual' => rupiah($medicine->price),
                    'Stok' => $medicine->stock.' '.$medicine->unit,
                    'Stok Minimum' => $medicine->min_stock.' '.$medicine->unit,
                    'Kedaluwarsa' => $medicine->expiry_date->translatedFormat('d F Y'),
                    'Supplier' => $medicine->supplier?->name ?? '-',
                    'Golongan' => $medicine->requires_prescription ? 'Obat keras (resep)' : 'Obat bebas',
                ] as $label => $value)
                    <div>
                        <dt class="text-xs text-slate-500 uppercase">{{ $label }}</dt>
                        <dd class="mt-1 font-medium text-slate-900">{{ $value }}</dd>
                    </div>
                @endforeach
            </dl>
            <div class="mt-5 flex gap-2">
                @if ($medicine->isExpired())<span class="badge-red">Sudah kedaluwarsa, tidak bisa dijual</span>
                @elseif ($medicine->isExpiringSoon())<span class="badge-amber">Segera kedaluwarsa</span>@endif
                @if ($medicine->isLowStock())<span class="badge-amber">Stok menipis</span>@endif
            </div>
        </div>

        <form method="POST" action="{{ route('admin.stock-movements.store') }}" class="card space-y-4 p-5">
            @csrf
            <input type="hidden" name="medicine_id" value="{{ $medicine->id }}">
            <h2 class="font-semibold text-slate-900">Stok Masuk / Penyesuaian</h2>
            <div>
                <label class="label" for="type">Jenis</label>
                <select id="type" name="type" class="input">
                    <option value="in">Stok masuk (pembelian)</option>
                    <option value="adjustment">Penyesuaian (stock opname)</option>
                </select>
            </div>
            <div>
                <label class="label" for="quantity">Jumlah</label>
                <input id="quantity" name="quantity" type="number" class="input" required>
                <p class="mt-1 text-xs text-slate-500">Untuk penyesuaian, isi negatif bila stok berkurang (rusak/hilang).</p>
            </div>
            <div>
                <label class="label" for="note">Keterangan</label>
                <input id="note" name="note" class="input" placeholder="No. faktur, alasan, dll.">
            </div>
            <button class="btn-primary w-full">Simpan</button>
        </form>
    </div>

    <div class="card overflow-x-auto">
        <h2 class="px-5 pt-5 font-semibold text-slate-900">Riwayat Stok</h2>
        <table class="table mt-3">
            <thead><tr><th>Waktu</th><th>Jenis</th><th class="text-right!">Jumlah</th><th class="text-right!">Stok Akhir</th><th>Keterangan</th><th>Oleh</th></tr></thead>
            <tbody class="divide-y divide-slate-100">
            @forelse ($movements as $mv)
                <tr>
                    <td>{{ $mv->created_at->translatedFormat('d M Y H:i') }}</td>
                    <td><span class="{{ ['in' => 'badge-green', 'out' => 'badge-blue', 'adjustment' => 'badge-amber'][$mv->type->value] }}">{{ $mv->type->label() }}</span></td>
                    <td class="text-right font-medium {{ $mv->quantity < 0 ? 'text-rose-600' : 'text-emerald-600' }}">{{ $mv->quantity > 0 ? '+' : '' }}{{ $mv->quantity }}</td>
                    <td class="text-right">{{ $mv->stock_after }}</td>
                    <td>
                        @if ($mv->sale_id)
                            <a href="{{ route('admin.sales.show', $mv->sale_id) }}" class="text-emerald-700 underline">{{ $mv->note }}</a>
                        @else
                            {{ $mv->note ?? '-' }}
                        @endif
                    </td>
                    <td>{{ $mv->user->name }}</td>
                </tr>
            @empty
                <tr><td colspan="6" class="py-8 text-center text-slate-500">Belum ada riwayat stok.</td></tr>
            @endforelse
            </tbody>
        </table>
        <div class="p-4">{{ $movements->links() }}</div>
    </div>
</x-layouts.app>
