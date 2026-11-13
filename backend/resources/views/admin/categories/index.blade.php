<x-layouts.app title="Kategori Obat" :subtitle="$categories->count().' kategori'">
    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card overflow-x-auto lg:col-span-2">
            <table class="table">
                <thead><tr><th>Nama Kategori</th><th class="text-right!">Jumlah Obat</th><th class="text-right!">Aksi</th></tr></thead>
                <tbody class="divide-y divide-slate-100">
                @foreach ($categories as $category)
                    <tr>
                        <td>
                            <form method="POST" action="{{ route('admin.categories.update', $category) }}" class="flex gap-2">
                                @csrf @method('PUT')
                                <input name="name" value="{{ $category->name }}" class="input max-w-xs py-1" aria-label="Nama kategori">
                                <button class="text-sm text-emerald-700 hover:underline">Simpan</button>
                            </form>
                        </td>
                        <td class="text-right">
                            <a href="{{ route('admin.medicines.index', ['category_id' => $category->id]) }}" class="text-emerald-700 hover:underline">{{ $category->medicines_count }}</a>
                        </td>
                        <td class="text-right">
                            <form method="POST" action="{{ route('admin.categories.destroy', $category) }}" onsubmit="return confirm('Hapus kategori ini?')">
                                @csrf @method('DELETE')
                                <button class="text-sm text-rose-600 hover:underline">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>

        <form method="POST" action="{{ route('admin.categories.store') }}" class="card h-fit space-y-4 p-5">
            @csrf
            <h2 class="font-semibold text-slate-900">Tambah Kategori</h2>
            <input name="name" class="input" placeholder="contoh: Obat Herbal" required>
            <button class="btn-primary w-full">Tambah</button>
        </form>
    </div>
</x-layouts.app>
