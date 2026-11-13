import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/debounced_search_field.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/state_views.dart';
import '../data/medicine.dart';
import '../data/medicine_query.dart';
import 'medicine_detail_screen.dart';
import 'medicine_providers.dart';
import 'widgets/medicine_card.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicineListControllerProvider);
    final controller = ref.read(medicineListControllerProvider.notifier);
    final query = state.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Obat'),
        actions: [
          IconButton(
            tooltip: 'Filter kategori',
            icon: Badge(
              isLabelVisible: query.categoryId != null,
              smallSize: 8,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _pickCategory(context, ref, query.categoryId),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DebouncedSearchField(
              hintText: 'Cari nama obat atau SKU',
              initialValue: query.search,
              onChanged: controller.search,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final filter in MedicineFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: query.filter == filter,
                      onSelected: (_) => controller.setFilter(filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Medicine, MedicineQuery>(
              state: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              header: state.items.isEmpty
                  ? null
                  : Text(
                      '${Formatters.number(state.total)} obat ditemukan',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
              emptyView: EmptyView(
                icon: Icons.medication_outlined,
                title: 'Obat tidak ditemukan',
                subtitle: query.search.isNotEmpty
                    ? 'Tidak ada obat yang cocok dengan "${query.search}".'
                    : 'Coba ubah filter atau kategori.',
              ),
              itemBuilder: (context, medicine) => MedicineCard(
                medicine: medicine,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MedicineDetailScreen(
                      medicineId: medicine.id,
                      initial: medicine,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref, int? selected) async {
    final result = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CategorySheet(selectedId: selected),
    );
    if (result != null) {
      ref.read(medicineListControllerProvider.notifier).setCategory(result.id);
    }
  }
}

/// Hasil pilihan bottom sheet; `id == null` berarti semua kategori.
class _CategoryChoice {
  const _CategoryChoice(this.id);
  final int? id;
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: categories.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => ErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (items) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Pilih kategori',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            _tile(context, const _CategoryChoice(null), 'Semua kategori'),
            for (final category in items)
              _tile(context, _CategoryChoice(category.id), category.name),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _CategoryChoice choice, String label) {
    final selected = choice.id == selectedId;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: selected,
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}
