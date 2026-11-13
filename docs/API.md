# Kontrak REST API – Apotek

Base URL: `{HOST}/api/v1`  •  Semua respons JSON  •  Auth: `Authorization: Bearer {token}` (Laravel Sanctum)

Format sukses daftar (paginasi):
```json
{ "data": [ ... ], "meta": { "current_page": 1, "last_page": 3, "per_page": 15, "total": 42 } }
```
Format sukses tunggal: `{ "data": { ... } }`
Format error validasi (422): `{ "message": "...", "errors": { "field": ["pesan"] } }`
Error lain: `{ "message": "..." }` dengan status 401 / 403 / 404 / 409.

## Auth
| Method | Path | Body | Respons |
|---|---|---|---|
| POST | `/auth/login` | `email, password, device_name` | `{ "data": { "token": "...", "user": User } }` |
| GET | `/auth/me` | – | `{ "data": User }` |
| POST | `/auth/logout` | – | `204` |

`User`: `{ id, name, email, role }` dengan `role` = `admin` | `kasir`

## Dashboard
`GET /dashboard` →
```json
{ "data": {
  "today_sales_total": 1250000,
  "today_transactions": 18,
  "low_stock_count": 4,
  "expiring_soon_count": 3,
  "medicine_count": 40
} }
```

## Kategori
`GET /categories` → `{ "data": [ { "id": 1, "name": "Analgesik" } ] }` (tanpa paginasi)

## Obat
`GET /medicines?search=para&category_id=1&filter=low_stock|expiring&page=1`
`GET /medicines/{id}`
`GET /medicines/sku/{sku}` (untuk scan barcode)

`Medicine`:
```json
{
  "id": 1, "sku": "OBT-0001", "name": "Paracetamol 500 mg",
  "category": { "id": 1, "name": "Analgesik" },
  "unit": "strip", "price": 12000, "stock": 120, "min_stock": 20,
  "expiry_date": "2027-08-31", "requires_prescription": false,
  "is_low_stock": false, "is_expiring_soon": false
}
```
Harga dalam Rupiah bilangan bulat. `is_expiring_soon` = kedaluwarsa ≤ 90 hari.

## Stok masuk (admin saja)
`POST /stock-movements` body `{ medicine_id, type: "in"|"adjustment", quantity, note }` → `201 { "data": StockMovement }`
(`quantity` boleh negatif hanya untuk `adjustment`; stok tidak boleh < 0 → 422)

## Penjualan
`GET /sales?date=2026-11-12&page=1` (kasir hanya melihat transaksinya sendiri, admin melihat semua)
`GET /sales/{id}`
`POST /sales`
```json
{ "items": [ { "medicine_id": 1, "quantity": 2 } ], "paid_amount": 50000, "note": "opsional" }
```
Aturan: stok cukup (422 jika tidak), obat kedaluwarsa tidak bisa dijual (422), `paid_amount >= total` (422).
Harga diambil dari server, bukan dari klien. Seluruh proses dalam satu transaksi database.

`Sale`:
```json
{
  "id": 10, "invoice_number": "INV-20261112-0001",
  "cashier": { "id": 2, "name": "Kasir Demo" },
  "total": 24000, "paid_amount": 50000, "change_amount": 26000,
  "note": null, "created_at": "2026-11-12T13:30:00+07:00",
  "items": [ { "medicine_id": 1, "medicine_name": "Paracetamol 500 mg", "quantity": 2, "price": 12000, "subtotal": 24000 } ]
}
```

## Akun demo (seeder)
- Admin: `admin@apotek.test` / `password`
- Kasir: `kasir@apotek.test` / `password`
