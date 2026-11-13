import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/state_views.dart';
import '../data/sale.dart';
import 'sale_detail_screen.dart';
import 'sale_providers.dart';

class SaleHistoryScreen extends ConsumerWidget {
  const SaleHistoryScreen({super.key});

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      ref.read(saleListControllerProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleListControllerProvider);
    final controller = ref.read(saleListControllerProvider.notifier);
    final selectedDate = state.query.date;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
        actions: [
          if (selectedDate != null)
            IconButton(
              tooltip: 'Hapus filter tanggal',
              icon: const Icon(Icons.filter_alt_off_rounded),
              onPressed: () => controller.setDate(null),
            ),
          IconButton(
            tooltip: 'Filter tanggal',
            icon: Badge(
              isLabelVisible: selectedDate != null,
              smallSize: 8,
              child: const Icon(Icons.calendar_today_rounded),
            ),
            onPressed: () => _pickDate(context, ref, selectedDate),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  InputChip(
                    avatar: const Icon(Icons.event_rounded, size: 18),
                    label: Text(Formatters.date(selectedDate)),
                    onDeleted: () => controller.setDate(null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PagedListView<Sale, SaleQuery>(
              state: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              header: state.items.isEmpty
                  ? null
                  : Text(
                      '${Formatters.number(state.total)} transaksi',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
              emptyView: EmptyView(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: selectedDate != null
                    ? 'Tidak ada penjualan pada ${Formatters.date(selectedDate)}.'
                    : 'Transaksi penjualan akan muncul di sini.',
              ),
              itemBuilder: (context, sale) => _SaleCard(
                sale: sale,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SaleDetailScreen(
                      saleId: sale.id,
                      initial: sale,
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
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.onTap});

  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_long_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.invoiceNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (sale.createdAt != null)
                          Formatters.dateTime(sale.createdAt!),
                        if (sale.cashier != null) sale.cashier!.name,
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.rupiah(sale.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Kembali ${Formatters.rupiah(sale.changeAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
