import '../../../core/utils/json_utils.dart';

/// Ringkasan kasir pada objek `Sale`.
class SaleCashier {
  const SaleCashier({required this.id, required this.name});

  factory SaleCashier.fromJson(Map<String, dynamic> json) => SaleCashier(
        id: parseInt(json['id']),
        name: json['name'] as String? ?? '',
      );

  final int id;
  final String name;
}

/// Baris item transaksi pada `Sale`.
class SaleItem {
  const SaleItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        medicineId: parseInt(json['medicine_id']),
        medicineName: json['medicine_name'] as String? ?? '',
        quantity: parseInt(json['quantity']),
        price: parseInt(json['price']),
        subtotal: parseInt(json['subtotal']),
      );

  final int medicineId;
  final String medicineName;
  final int quantity;
  final int price;
  final int subtotal;
}

/// Model transaksi penjualan sesuai kontrak API (`Sale`).
class Sale {
  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    this.cashier,
    this.note,
    this.createdAt,
    this.items = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'];
    final rawItems = json['items'];
    final createdAtRaw = json['created_at'] as String?;

    return Sale(
      id: parseInt(json['id']),
      invoiceNumber: json['invoice_number'] as String? ?? '',
      cashier: cashier is Map<String, dynamic>
          ? SaleCashier.fromJson(cashier)
          : null,
      total: parseInt(json['total']),
      paidAmount: parseInt(json['paid_amount']),
      changeAmount: parseInt(json['change_amount']),
      note: json['note'] as String?,
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SaleItem.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String invoiceNumber;
  final SaleCashier? cashier;
  final int total;
  final int paidAmount;
  final int changeAmount;
  final String? note;
  final DateTime? createdAt;
  final List<SaleItem> items;
}
