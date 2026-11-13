import 'package:apotek_mobile/features/medicines/data/medicine.dart';
import 'package:apotek_mobile/features/pos/data/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  Medicine makeMedicine({
    int id = 1,
    String name = 'Paracetamol 500 mg',
    int price = 12000,
    int stock = 5,
    DateTime? expiryDate,
  }) =>
      Medicine(
        id: id,
        sku: 'OBT-000$id',
        name: name,
        unit: 'strip',
        price: price,
        stock: stock,
        minStock: 2,
        expiryDate: expiryDate ?? DateTime(2027, 8, 31),
      );

  group('CartState', () {
    test('menghitung total, jumlah item, dan kembalian dengan benar', () {
      final a = makeMedicine(id: 1, price: 12000, stock: 10);
      final b = makeMedicine(id: 2, name: 'Amoxicillin', price: 15000, stock: 5);

      var cart = const CartState();
      cart = cart.addMedicine(a, now: today).state;
      cart = cart.addMedicine(a, now: today).state;
      cart = cart.addMedicine(b, now: today).state;

      expect(cart.items.length, 2);
      expect(cart.totalQuantity, 3);
      expect(cart.total, 39000);
      expect(cart.canPay(38000), isFalse);
      expect(cart.canPay(39000), isTrue);
      expect(cart.changeFor(50000), 11000);
      expect(cart.changeFor(30000), -9000);
    });

    test('menolak penambahan melebihi stok tersedia', () {
      final med = makeMedicine(id: 1, stock: 2);
      var cart = const CartState();

      var res = cart.addMedicine(med, now: today);
      expect(res.hasError, isFalse);
      cart = res.state;

      res = cart.increment(1);
      expect(res.hasError, isFalse);
      cart = res.state;
      expect(cart.quantityOf(1), 2);

      final overLimit = cart.increment(1);
      expect(overLimit.hasError, isTrue);
      expect(overLimit.error, contains('tersisa 2'));
      expect(overLimit.state.quantityOf(1), 2);
    });

    test('menolak obat yang sudah kedaluwarsa atau stok habis', () {
      final expired = makeMedicine(
        id: 1,
        name: 'Obat Lama',
        stock: 10,
        expiryDate: DateTime(2026, 11, 12),
      );
      final empty = makeMedicine(id: 2, name: 'Obat Kosong', stock: 0);

      const cart = CartState();
      final resExpired = cart.addMedicine(expired, now: today);
      expect(resExpired.hasError, isTrue);
      expect(resExpired.error, contains('kedaluwarsa'));
      expect(resExpired.state.isEmpty, isTrue);

      final resEmpty = cart.addMedicine(empty, now: today);
      expect(resEmpty.hasError, isTrue);
      expect(resEmpty.error, contains('habis'));
      expect(resEmpty.state.isEmpty, isTrue);
    });

    test('decrement menjadi 0 akan menghapus item dari keranjang', () {
      final med = makeMedicine(id: 1, stock: 5);
      var cart = const CartState().addMedicine(med, now: today).state;
      expect(cart.items.length, 1);

      cart = cart.decrement(1).state;
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0);
    });
  });
}
