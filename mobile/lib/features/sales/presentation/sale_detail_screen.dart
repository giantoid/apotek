import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../data/sale.dart';
import 'sale_providers.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({
    super.key,
    required this.saleId,
    this.initial,
    this.isReceipt = false,
  });

  final int saleId;
  final Sale? initial;

  /// `true` bila dibuka tepat setelah checkout kasir berhasil.
  final bool isReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = isReceipt
        ? AsyncValue.data(initial!)
        : ref.watch(saleDetailProvider(saleId));
    final sale = detail.value ?? initial;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReceipt ? 'Struk Pembayaran' : 'Detail Transaksi'),
      ),
      body: sale == null
          ? detail.when(
              data: (_) => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: describeError(error),
                onRetry: () => ref.invalidate(saleDetailProvider(saleId)),
              ),
            )
          : _SaleReceiptBody(
              sale: sale,
              isReceipt: isReceipt,
              isLoadingItems: detail.isLoading && sale.items.isEmpty,
              onRefresh: isReceipt
                  ? null
                  : () => ref.refresh(saleDetailProvider(saleId).future),
            ),
      bottomNavigationBar: isReceipt
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Transaksi Baru'),
                ),
              ),
            )
          : null,
    );
  }
}

class _SaleReceiptBody extends StatelessWidget {
  const _SaleReceiptBody({
    required this.sale,
    required this.isReceipt,
    required this.isLoadingItems,
    this.onRefresh,
  });

  final Sale sale;
  final bool isReceipt;
  final bool isLoadingItems;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (isReceipt) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.success,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'Transaksi Berhasil!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kembalian ${Formatters.rupiah(sale.changeAmount)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sale.invoiceNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (sale.createdAt != null)
                  Text(
                    Formatters.dateTime(sale.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (sale.cashier != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Kasir: ${sale.cashier!.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (sale.note != null && sale.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Catatan: ${sale.note}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                Text(
                  'Daftar Item',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (isLoadingItems)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (sale.items.isEmpty)
                  Text(
                    'Tidak ada detail item.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final item in sale.items) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.medicineName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${Formatters.number(item.quantity)} x ${Formatters.rupiah(item.price)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.rupiah(item.subtotal),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                _SummaryRow(
                  label: 'Total',
                  value: Formatters.rupiah(sale.total),
                  bold: true,
                  valueColor: scheme.primary,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Bayar',
                  value: Formatters.rupiah(sale.paidAmount),
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Kembalian',
                  value: Formatters.rupiah(sale.changeAmount),
                  bold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style?.copyWith(color: valueColor)),
      ],
    );
  }
}
