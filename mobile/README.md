# Apotek Mobile (Flutter)

Aplikasi kasir (POS) dan pemantauan stok obat berbasis Flutter (Material 3) yang terhubung ke REST API Laravel (`docs/API.md`).

## Fitur
- **Autentikasi**: Login Laravel Sanctum, penyimpanan token dengan `shared_preferences` (mendukung Android, iOS, dan Web), pembersihan sesi otomatis saat menerima `401`, serta pengisian cepat akun demo.
- **Beranda**: Ringkasan penjualan hari ini, jumlah transaksi, stok menipis, dan obat segera kedaluwarsa dengan *pull-to-refresh*.
- **Daftar & Detail Obat**: Pencarian dengan *debounce*, filter status (*Semua*, *Stok menipis*, *Segera kedaluwarsa*), filter kategori, *infinite scroll pagination*, dan detail informasi stok/kedaluwarsa.
- **Kasir (POS)**: Pencarian obat & kode SKU, kontrol jumlah `+/-` yang mencegah melebihi stok dan memblokir obat kedaluwarsa, input nominal bayar dengan pemisah ribuan + tombol nominal cepat, kalkulasi kembalian, checkout transaksi (`POST /sales`), dan halaman struk pembayaran.
- **Riwayat Penjualan**: Daftar transaksi berpaginasi, filter tanggal, dan detail struk transaksi.

## Arsitektur & Paket Utama
- **State Management**: `flutter_riverpod` (`Notifier`, `AsyncNotifier`, `FutureProvider`)
- **HTTP Client**: `dio` dengan `AuthInterceptor` dan pemetaan error (`ApiException`) ke pesan Bahasa Indonesia
- **Format & Lokal**: `intl` (format Rupiah `Rp` dan tanggal Indonesia)
- **Struktur Direktori**:
  - `lib/core/` — konfigurasi (`AppConfig`), `Dio` & interceptor, tema Material 3 hijau apotek, formatter, dan widget bersama (`PagedListView`, `DebouncedSearchField`, `ErrorView`, `EmptyView`)
  - `lib/features/{auth,home,dashboard,medicines,pos,sales}/` — dipisah per fitur menjadi lapisan `data` (model + repository) dan `presentation` (controller + layar)

## Cara Menjalankan

Pastikan backend Laravel sudah berjalan (`php artisan serve`), lalu jalankan:

```bash
flutter pub get

# Emulator Android (default API_BASE_URL = http://10.0.2.2:8000/api/v1)
flutter run

# Perangkat fisik Android (ganti dengan IP komputer Anda)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1

# Browser (Chrome)
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Pengujian & Analisis Statis
```bash
flutter analyze
flutter test
```
