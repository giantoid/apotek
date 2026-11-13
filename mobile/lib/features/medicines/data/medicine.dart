import '../../../core/utils/json_utils.dart';

/// `{ "id": 1, "name": "Analgesik" }`.
class Category {
  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: parseInt(json['id']),
        name: json['name'] as String? ?? '',
      );

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Model `Medicine` sesuai kontrak API.
class Medicine {
  const Medicine({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    required this.minStock,
    this.category,
    this.expiryDate,
    this.requiresPrescription = false,
    this.isLowStock = false,
    this.isExpiringSoon = false,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return Medicine(
      id: parseInt(json['id']),
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: category is Map<String, dynamic> ? Category.fromJson(category) : null,
      unit: json['unit'] as String? ?? '',
      price: parseInt(json['price']),
      stock: parseInt(json['stock']),
      minStock: parseInt(json['min_stock']),
      expiryDate: parseDateOnly(json['expiry_date']),
      requiresPrescription: parseBool(json['requires_prescription']),
      isLowStock: parseBool(json['is_low_stock']),
      isExpiringSoon: parseBool(json['is_expiring_soon']),
    );
  }

  final int id;
  final String sku;
  final String name;
  final Category? category;
  final String unit;

  /// Harga dalam Rupiah (bilangan bulat).
  final int price;
  final int stock;
  final int minStock;
  final DateTime? expiryDate;
  final bool requiresPrescription;
  final bool isLowStock;
  final bool isExpiringSoon;

  bool get isOutOfStock => stock <= 0;

  /// Kontrak API tidak menyediakan `is_expired`, sehingga dihitung di klien:
  /// obat dianggap kedaluwarsa bila tanggal kedaluwarsa sebelum hari ini.
  bool isExpired([DateTime? now]) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    final today = _dateOnly(now ?? DateTime.now());
    return expiry.isBefore(today);
  }

  /// Sisa hari menuju tanggal kedaluwarsa (negatif bila sudah lewat).
  int? daysUntilExpiry([DateTime? now]) {
    final expiry = expiryDate;
    if (expiry == null) return null;
    return expiry.difference(_dateOnly(now ?? DateTime.now())).inDays;
  }

  /// Dapat dijual bila stok tersedia dan belum kedaluwarsa.
  bool isSellable([DateTime? now]) => !isOutOfStock && !isExpired(now);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
