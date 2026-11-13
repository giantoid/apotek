@php $editing = $medicine->exists; @endphp

<x-layouts.app :title="$editing ? 'Ubah Obat' : 'Tambah Obat'" :subtitle="$editing ? $medicine->name : 'Daftarkan obat baru ke sistem'">
    <form method="POST" action="{{ $editing ? route('admin.medicines.update', $medicine) : route('admin.medicines.store') }}" class="card max-w-3xl space-y-5 p-6">
        @csrf
        @if ($editing) @method('PUT') @endif

        <div class="grid gap-5 sm:grid-cols-3">
            <div>
                <label class="label" for="sku">Kode / Barcode</label>
                <input id="sku" name="sku" value="{{ old('sku', $medicine->sku) }}" class="input font-mono" required>
            </div>
            <div class="sm:col-span-2">
                <label class="label" for="name">Nama Obat</label>
                <input id="name" name="name" value="{{ old('name', $medicine->name) }}" class="input" placeholder="contoh: Paracetamol 500 mg" required>
            </div>
        </div>

        <div class="grid gap-5 sm:grid-cols-3">
            <div>
                <label class="label" for="category_id">Kategori</label>
                <select id="category_id" name="category_id" class="input" required>
                    <option value="">Pilih...</option>
                    @foreach ($categories as $c)
                        <option value="{{ $c->id }}" @selected(old('category_id', $medicine->category_id) == $c->id)>{{ $c->name }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="label" for="supplier_id">Supplier</label>
                <select id="supplier_id" name="supplier_id" class="input">
                    <option value="">-</option>
                    @foreach ($suppliers as $s)
                        <option value="{{ $s->id }}" @selected(old('supplier_id', $medicine->supplier_id) == $s->id)>{{ $s->name }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="label" for="unit">Satuan</label>
                <input id="unit" name="unit" value="{{ old('unit', $medicine->unit) }}" class="input" list="units" placeholder="strip / botol" required>
                <datalist id="units"><option value="strip"><option value="botol"><option value="tablet"><option value="tube"><option value="kotak"></datalist>
            </div>
        </div>

        <div class="grid gap-5 sm:grid-cols-4">
            <div>
                <label class="label" for="price">Harga Jual (Rp)</label>
                <input id="price" name="price" type="number" min="0" value="{{ old('price', $medicine->price) }}" class="input" required>
            </div>
            @unless ($editing)
                <div>
                    <label class="label" for="stock">Stok Awal</label>
                    <input id="stock" name="stock" type="number" min="0" value="{{ old('stock', 0) }}" class="input" required>
                </div>
            @endunless
            <div>
                <label class="label" for="min_stock">Stok Minimum</label>
                <input id="min_stock" name="min_stock" type="number" min="0" value="{{ old('min_stock', $medicine->min_stock) }}" class="input" required>
            </div>
            <div>
                <label class="label" for="expiry_date">Tgl. Kedaluwarsa</label>
                <input id="expiry_date" name="expiry_date" type="date" value="{{ old('expiry_date', $medicine->expiry_date?->toDateString()) }}" class="input" required>
            </div>
        </div>

        <label class="flex items-center gap-2 text-sm text-slate-700">
            <input type="checkbox" name="requires_prescription" value="1" @checked(old('requires_prescription', $medicine->requires_prescription)) class="rounded border-slate-300 text-emerald-600">
            Obat keras (wajib resep dokter)
        </label>

        @if ($editing)
            <p class="rounded-lg bg-slate-50 p-3 text-xs text-slate-500">Stok tidak diubah dari sini. Gunakan fitur <strong>Stok Masuk / Penyesuaian</strong> di halaman detail obat agar riwayat stok tercatat.</p>
        @endif

        <div class="flex gap-3">
            <button class="btn-primary">Simpan</button>
            <a href="{{ $editing ? route('admin.medicines.show', $medicine) : route('admin.medicines.index') }}" class="btn-secondary">Batal</a>
        </div>
    </form>
</x-layouts.app>
