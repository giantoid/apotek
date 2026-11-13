import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paginated.dart';
import '../../../core/pagination/paged_controller.dart';
import '../data/medicine.dart';
import '../data/medicine_query.dart';
import '../data/medicine_repository.dart';

typedef MedicineListState = PagedState<Medicine, MedicineQuery>;

final medicineListControllerProvider =
    NotifierProvider.autoDispose<MedicineListController, MedicineListState>(
  MedicineListController.new,
);

/// Daftar obat dengan pencarian, filter, dan infinite scroll.
class MedicineListController extends PagedController<Medicine, MedicineQuery> {
  @override
  MedicineQuery get initialQuery => const MedicineQuery();

  @override
  Future<Paginated<Medicine>> fetchPage(MedicineQuery query, int page) =>
      ref.read(medicineRepositoryProvider).fetchMedicines(query, page: page);

  void search(String text) => updateQuery(state.query.copyWith(search: text));

  void setFilter(MedicineFilter filter) =>
      updateQuery(state.query.copyWith(filter: filter));

  void setCategory(int? categoryId) =>
      updateQuery(state.query.copyWith(categoryId: () => categoryId));
}

final categoriesProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(medicineRepositoryProvider).fetchCategories(),
);

final medicineDetailProvider =
    FutureProvider.autoDispose.family<Medicine, int>(
  (ref, id) => ref.watch(medicineRepositoryProvider).fetchMedicine(id),
);
