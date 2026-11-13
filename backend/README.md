# Apotek Backend (Laravel)

Backend Laravel untuk Sistem Informasi Apotek: panel admin web (Blade + Tailwind CSS v4) dan REST API v1 (Laravel Sanctum).

## Menjalankan Secara Lokal

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
npm install && npm run build
php artisan serve
```

Secara default aplikasi memakai database SQLite (`database/database.sqlite`). Untuk memakai MySQL/MariaDB, ubah pengaturan `DB_*` di `.env` lalu jalankan `php artisan migrate --seed`.

## Dokumentasi API
Lihat [../docs/API.md](../docs/API.md) untuk daftar lengkap endpoint, payload, dan contoh respons.

## Pengujian & Format Kode
```bash
php artisan test
./vendor/bin/pint --test
```
