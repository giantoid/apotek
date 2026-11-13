import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paginated.dart';
import '../../../core/pagination/paged_controller.dart';
import '../data/sale.dart';
import '../data/sale_repository.dart';

@immutable
class SaleQuery {
  const SaleQuery({this.date});

  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      other is SaleQuery &&
      other.date?.year == date?.year &&
      other.date?.month == date?.month &&
      other.date?.day == date?.day;

  @override
  int get hashCode => Object.hash(date?.year, date?.month, date?.day);
}

typedef SaleListState = PagedState<Sale, SaleQuery>;

final saleListControllerProvider =
    NotifierProvider.autoDispose<SaleListController, SaleListState>(
  SaleListController.new,
);

/// Daftar riwayat penjualan dengan filter tanggal & infinite scroll.
class SaleListController extends PagedController<Sale, SaleQuery> {
  @override
  SaleQuery get initialQuery => const SaleQuery();

  @override
  Future<Paginated<Sale>> fetchPage(SaleQuery query, int page) =>
      ref.read(saleRepositoryProvider).fetchSales(date: query.date, page: page);

  void setDate(DateTime? date) => updateQuery(SaleQuery(date: date));
}

final saleDetailProvider = FutureProvider.autoDispose.family<Sale, int>(
  (ref, id) => ref.watch(saleRepositoryProvider).fetchSale(id),
);
