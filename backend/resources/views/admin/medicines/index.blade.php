<x-layouts.app title="Data Obat" :subtitle="$medicines->total().' obat ditemukan'">
    <x-slot:actions>
        <a href="{{ route('admin.medicines.create') }}" class="btn-primary">+ Tambah Obat</a>
    </x-slot:actions>

    <form method="GET" class="card flex flex-wrap items-end gap-3 p-4">
        <div class="min-w-56 flex-1">
            <label class="label" for="search">Cari</label>
            <input id="search" name="search" value="{{ request('search') }}" placeholder="Nama obat atau kode..." class="input">
        </div>
        <div>
            <label class="label" for="category_id">Kategori</label>
            <select id="category_id" name="category_id" class="input">
                <option value="">Semua kategori</option>
                @foreach ($categories as $c)
                    <option value="{{ $c->id }}" @selected(request('category_id') == $c->id)>{{ $c->name }}</option>
                @endforeach
            </select>
        </div>
        <div>
            <label class="label" for="filter">Status</label>
            <select id="filter" name="filter" class="input">
                <option value="">Semua</option>
                <option value="low_stock" @selected(request('filter') === 'low_stock')>Stok menipis</option>
                <option value="expiring" @selected(request('filter') === 'expiring')>Segera kedaluwarsa</option>
            </select>
        </div>
        <button class="btn-secondary">Terapkan</button>
        @if (request()->hasAny(['search', 'category_id', 'filter']))
            <a href="{{ route('admin.medicines.index') }}" class="text-sm text-slate-500 underline">Reset</a>
        @endif
    </form>

    <div class="card overflow-x-auto">
        <table class="table">
            <thead>
            <tr>
                <th>Kode</th><th>Nama Obat</th><th>Kategori</th><th class="text-right!">Harga</th>
                <th class="text-right!">Stok</th><th>Kedaluwarsa</th><th>Status</th>
            </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
            @forelse ($medicines as $m)
                <tr class="cursor-pointer" onclick="location='{{ route('admin.medicines.show', $m) }}'">
                    <td class="font-mono text-xs text-slate-500">{{ $m->sku }}</td>
                    <td>
                        <span class="font-medium text-slate-900">{{ $m->name }}</span>
                        @if ($m->requires_prescription)<span class="badge-blue ml-1">Resep</span>@endif
                    </td>
                    <td>{{ $m->category->name }}</td>
                    <td class="text-right">{{ rupiah($m->price) }}</td>
                    <td class="text-right">{{ $m->stock }} <span class="text-xs text-slate-400">{{ $m->unit }}</span></td>
                    <td>{{ $m->expiry_date->translatedFormat('d M Y') }}</td>
                    <td class="space-x-1 whitespace-nowrap">
                        @if ($m->isExpired())
                            <span class="badge-red">Kedaluwarsa</span>
                        @elseif ($m->isExpiringSoon())
                            <span class="badge-amber">Segera ED</span>
                        @endif
                        @if ($m->isLowStock())
                            <span class="badge-amber">Stok menipis</span>
                        @elseif (! $m->isExpiringSoon())
                            <span class="badge-green">Aman</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr><td colspan="7" class="py-10 text-center text-slate-500">Tidak ada obat yang cocok.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>

    {{ $medicines->links() }}
</x-layouts.app>
