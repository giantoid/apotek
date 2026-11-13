# Sistem Informasi & Kasir Apotek (Laravel + Flutter)

Proyek portofolio sistem apotek yang terdiri dari **panel admin web + REST API (Laravel)** dan **aplikasi kasir mobile/web (Flutter)**. Dirancang untuk alur operasional apotek sehari-hari: pengelolaan katalog obat, pemantauan stok minimum dan tanggal kedaluwarsa, pencatatan mutasi stok, serta transaksi kasir (POS).

## Struktur Repositori

```text
apotek/
├── backend/   # Laravel 13: Panel Admin (Blade + Tailwind CSS v4) & REST API (Sanctum)
├── mobile/    # Flutter 3.50 (Material 3 + Riverpod + Dio): Aplikasi Kasir & Cek Stok
└── docs/
    └── API.md # Kontrak REST API v1
```

## Fitur Utama

### Panel Admin Web (`backend/`)
- **Dashboard ringkasan**: penjualan hari ini, grafik penjualan 7 hari terakhir, obat terlaris, daftar stok menipis, obat segera kedaluwarsa, dan transaksi terakhir.
- **Manajemen Obat & Kategori**: CRUD obat, penanda obat keras (resep dokter), status kedaluwarsa (`≤ 90 hari`), dan stok minimum.
- **Riwayat Mutasi Stok**: stok masuk dan penyesuaian (*stock opname*) dicatat terpisah dalam `stock_movements` dengan penguncian transaksi (`SELECT ... FOR UPDATE`).
- **Laporan Penjualan**: filter tanggal, kasir, nomor invoice, cetak struk, serta ekspor CSV.

### Aplikasi Kasir (`mobile/`)
- **Autentikasi Sanctum**: login dengan token bearer, auto-logout saat `401`, dan pilihan akun demo pada layar masuk.
- **Beranda**: ringkasan harian (*pull-to-refresh*) dengan pintasan ke filter stok menipis/kedaluwarsa dan kasir.
- **Daftar & Detail Obat**: pencarian dengan *debounce*, filter chip (*Semua*, *Stok menipis*, *Segera kedaluwarsa*), filter kategori, dan *infinite scroll*.
- **Kasir (POS)**: cari obat atau kode SKU, tambah ke keranjang dengan validasi stok & blokir obat kedaluwarsa, tombol nominal cepat, hitung kembalian otomatis, checkout ke server, dan tampilkan struk.
- **Riwayat Penjualan**: daftar transaksi (kasir melihat transaksinya sendiri, admin melihat semua), filter tanggal, dan detail struk.

## Menjalankan Secara Lokal

### 1. Backend (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
npm install && npm run build
php artisan serve
```
Buka `http://127.0.0.1:8000` untuk panel admin.

### 2. Mobile / Web (Flutter)
```bash
cd mobile
flutter pub get
# Untuk emulator Android (default sudah 10.0.2.2:8000)
flutter run

# Untuk Chrome / perangkat fisik di jaringan lokal
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Akun Demo (Seeder)
| Peran | Email | Kata Sandi | Akses |
|---|---|---|---|
| Admin | `admin@apotek.test` | `password` | Panel Web + Aplikasi Mobile |
| Kasir | `kasir@apotek.test` | `password` | Aplikasi Mobile |

## Pengujian
- **Backend**: `cd backend && php artisan test` (31 feature tests)
- **Mobile**: `cd mobile && flutter analyze && flutter test` (unit test keranjang, parsing JSON, dan widget test login)
