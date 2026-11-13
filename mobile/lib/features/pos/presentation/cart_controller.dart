import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paginated.dart';
import '../../../core/pagination/paged_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../medicines/data/medicine.dart';
import '../../medicines/data/medicine_query.dart';
import '../../medicines/data/medicine_repository.dart';
import '../../medicines/presentation/medicine_providers.dart';
import '../../sales/data/sale.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/presentation/sale_providers.dart';
import '../data/cart.dart';

/// Katalog obat khusus tab Kasir agar pencarian tidak bentrok dengan tab Obat.
final posCatalogProvider =
    NotifierProvider.autoDispose<PosCatalogController, PagedState<Medicine, String>>(
  PosCatalogController.new,
);

class PosCatalogController extends PagedController<Medicine, String> {
  @override
  String get initialQuery => '';

  @override
  Future<Paginated<Medicine>> fetchPage(String query, int page) =>
      ref.read(medicineRepositoryProvider).fetchMedicines(
            MedicineQuery(search: query),
            page: page,
          );

  void search(String text) => updateQuery(text);
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

/// Mengelola keranjang POS & proses checkout ke server.
class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  String? addMedicine(Medicine medicine) =>
      _apply(state.addMedicine(medicine));

  String? increment(int medicineId) => _apply(state.increment(medicineId));

  String? decrement(int medicineId) => _apply(state.decrement(medicineId));

  void remove(int medicineId) {
    state = state.remove(medicineId);
  }

  void clear() {
    state = state.clear();
  }

  String? _apply(CartUpdateResult result) {
    state = result.state;
    return result.error;
  }

  /// Mengirim transaksi ke `POST /sales`. Melempar `ApiException` bila gagal.
  Future<Sale> checkout({required int paidAmount, String? note}) async {
    final items = state.items
        .map((e) => CheckoutItem(medicineId: e.medicine.id, quantity: e.quantity))
        .toList();

    final sale = await ref.read(saleRepositoryProvider).checkout(
          items: items,
          paidAmount: paidAmount,
          note: note,
        );

    state = state.clear();

    // Segarkan stok, dashboard, dan riwayat penjualan setelah transaksi sukses.
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(medicineListControllerProvider);
    ref.invalidate(posCatalogProvider);
    ref.invalidate(saleListControllerProvider);

    return sale;
  }
}
