import 'package:flutter/foundation.dart';

import '../../medicines/data/medicine.dart';

/// Satu baris item dalam keranjang kasir.
@immutable
class CartItem {
  const CartItem({required this.medicine, required this.quantity});

  final Medicine medicine;
  final int quantity;

  int get subtotal => medicine.price * quantity;

  CartItem copyWith({Medicine? medicine, int? quantity}) => CartItem(
        medicine: medicine ?? this.medicine,
        quantity: quantity ?? this.quantity,
      );
}

/// Hasil operasi perubahan keranjang; membawa [error] bila ditolak aturan bisnis.
@immutable
class CartUpdateResult {
  const CartUpdateResult(this.state, {this.error});

  final CartState state;
  final String? error;

  bool get hasError => error != null;
}

/// State dan logika murni keranjang POS (mudah diuji tanpa widget/HTTP).
@immutable
class CartState {
  const CartState({this.items = const []});

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  int quantityOf(int medicineId) {
    for (final item in items) {
      if (item.medicine.id == medicineId) return item.quantity;
    }
    return 0;
  }

  /// Kembalian (bisa negatif bila `paidAmount` kurang dari `total`).
  int changeFor(int paidAmount) => paidAmount - total;

  bool canPay(int paidAmount) => items.isNotEmpty && paidAmount >= total;

  /// Menambahkan 1 unit [medicine] ke keranjang dengan validasi kedaluwarsa & stok.
  CartUpdateResult addMedicine(Medicine medicine, {DateTime? now}) {
    if (medicine.isExpired(now)) {
      return CartUpdateResult(
        this,
        error: '${medicine.name} sudah kedaluwarsa dan tidak boleh dijual.',
      );
    }
    if (medicine.isOutOfStock) {
      return CartUpdateResult(
        this,
        error: 'Stok ${medicine.name} habis.',
      );
    }

    final index = items.indexWhere((item) => item.medicine.id == medicine.id);
    if (index == -1) {
      return CartUpdateResult(
        CartState(items: [...items, CartItem(medicine: medicine, quantity: 1)]),
      );
    }

    final existing = items[index];
    final nextQty = existing.quantity + 1;
    if (nextQty > medicine.stock) {
      return CartUpdateResult(
        this,
        error: 'Stok ${medicine.name} hanya tersisa ${medicine.stock} ${medicine.unit}.',
      );
    }

    final updated = [...items];
    updated[index] = existing.copyWith(medicine: medicine, quantity: nextQty);
    return CartUpdateResult(CartState(items: updated));
  }

  /// Menambah jumlah item di keranjang (+1) dengan batas stok.
  CartUpdateResult increment(int medicineId) {
    final index = items.indexWhere((item) => item.medicine.id == medicineId);
    if (index == -1) return CartUpdateResult(this);
    final existing = items[index];
    return setQuantity(medicineId, existing.quantity + 1);
  }

  /// Mengurangi jumlah item di keranjang (-1); dihapus jika menjadi 0.
  CartUpdateResult decrement(int medicineId) {
    final index = items.indexWhere((item) => item.medicine.id == medicineId);
    if (index == -1) return CartUpdateResult(this);
    final existing = items[index];
    return setQuantity(medicineId, existing.quantity - 1);
  }

  /// Mengatur jumlah item secara langsung.
  CartUpdateResult setQuantity(int medicineId, int quantity) {
    final index = items.indexWhere((item) => item.medicine.id == medicineId);
    if (index == -1) return CartUpdateResult(this);

    if (quantity <= 0) {
      return CartUpdateResult(remove(medicineId));
    }

    final existing = items[index];
    if (quantity > existing.medicine.stock) {
      return CartUpdateResult(
        this,
        error:
            'Stok ${existing.medicine.name} hanya tersisa ${existing.medicine.stock} ${existing.medicine.unit}.',
      );
    }

    final updated = [...items];
    updated[index] = existing.copyWith(quantity: quantity);
    return CartUpdateResult(CartState(items: updated));
  }

  CartState remove(int medicineId) {
    return CartState(
      items: items.where((item) => item.medicine.id != medicineId).toList(),
    );
  }

  CartState clear() => const CartState();
}
