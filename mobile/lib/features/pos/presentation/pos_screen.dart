import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/debounced_search_field.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../medicines/data/medicine.dart';
import '../../medicines/data/medicine_repository.dart';
import '../../medicines/presentation/widgets/medicine_card.dart';
import '../../sales/presentation/sale_detail_screen.dart';
import '../data/cart.dart';
import 'cart_controller.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  void _addMedicine(BuildContext context, WidgetRef ref, Medicine medicine) {
    final error = ref.read(cartControllerProvider.notifier).addMedicine(medicine);
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
    }
  }

  Future<void> _lookupBySku(BuildContext context, WidgetRef ref) async {
    final sku = await showDialog<String>(
      context: context,
      builder: (_) => const _SkuLookupDialog(),
    );
    if (sku == null || sku.trim().isEmpty || !context.mounted) return;

    try {
      final medicine =
          await ref.read(medicineRepositoryProvider).findBySku(sku.trim());
      if (!context.mounted) return;
      final error =
          ref.read(cartControllerProvider.notifier).addMedicine(medicine);
      if (error != null) {
        showAppSnackBar(context, error, isError: true);
      } else {
        showAppSnackBar(
          context,
          '${medicine.name} ditambahkan ke keranjang.',
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, isError: true);
      }
    }
  }

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(posCatalogProvider);
    final catalogController = ref.read(posCatalogProvider.notifier);
    final cart = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            tooltip: 'Cari lewat kode SKU',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _lookupBySku(context, ref),
          ),
          if (!cart.isEmpty)
            IconButton(
              tooltip: 'Kosongkan keranjang',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ref.read(cartControllerProvider.notifier).clear(),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DebouncedSearchField(
              hintText: 'Cari obat untuk ditambahkan ke keranjang',
              initialValue: catalogState.query,
              onChanged: catalogController.search,
            ),
          ),
          Expanded(
            child: PagedListView<Medicine, String>(
              state: catalogState,
              onRefresh: catalogController.refresh,
              onLoadMore: catalogController.loadMore,
              emptyView: const EmptyView(
                icon: Icons.search_off_rounded,
                title: 'Obat tidak ditemukan',
                subtitle: 'Coba kata kunci lain atau masukkan kode SKU.',
              ),
              itemBuilder: (context, medicine) {
                final qty = cart.quantityOf(medicine.id);
                final sellable = medicine.isSellable();
                return MedicineCard(
                  medicine: medicine,
                  onTap: () => _addMedicine(context, ref, medicine),
                  trailing: _CartQuickControl(
                    quantity: qty,
                    sellable: sellable,
                    onAdd: () => _addMedicine(context, ref, medicine),
                    onDecrement: () => ref
                        .read(cartControllerProvider.notifier)
                        .decrement(medicine.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _CartSummaryBar(
              cart: cart,
              onCheckout: () => _openCheckout(context),
            ),
    );
  }
}

class _CartQuickControl extends StatelessWidget {
  const _CartQuickControl({
    required this.quantity,
    required this.sellable,
    required this.onAdd,
    required this.onDecrement,
  });

  final int quantity;
  final bool sellable;
  final VoidCallback onAdd;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!sellable) {
      return IconButton.filledTonal(
        onPressed: onAdd,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
          foregroundColor: AppTheme.danger,
        ),
        icon: const Icon(Icons.block_rounded, size: 20),
        tooltip: 'Tidak dapat dijual',
      );
    }

    if (quantity == 0) {
      return IconButton.filledTonal(
        onPressed: onAdd,
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
        tooltip: 'Tambah ke keranjang',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded, size: 18),
            onPressed: onDecrement,
          ),
          Text(
            '$quantity',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.cart, required this.onCheckout});

  final CartState cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.totalQuantity} item (${cart.items.length} jenis)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  Formatters.rupiah(cart.total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
            onPressed: onCheckout,
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: const Text('Bayar'),
          ),
        ],
      ),
    );
  }
}

class _SkuLookupDialog extends StatefulWidget {
  const _SkuLookupDialog();

  @override
  State<_SkuLookupDialog> createState() => _SkuLookupDialogState();
}

class _SkuLookupDialogState extends State<_SkuLookupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan Kode SKU'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'Contoh: OBT-0001',
          prefixIcon: Icon(Icons.qr_code_rounded),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Cari & Tambah'),
        ),
      ],
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _paidController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _paidAmount => Formatters.parseDigits(_paidController.text);

  void _setPaidAmount(int amount) {
    final text = amount == 0 ? '' : Formatters.number(amount);
    _paidController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _errorMessage = null);
  }

  void _handleCartError(String? error) {
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) return;

    final paidAmount = _paidAmount;
    if (!cart.canPay(paidAmount)) {
      setState(() {
        _errorMessage = 'Jumlah bayar kurang dari total belanja.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final sale = await ref.read(cartControllerProvider.notifier).checkout(
            paidAmount: paidAmount,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SaleDetailScreen(
            saleId: sale.id,
            initial: sale,
            isReceipt: true,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<int> _quickAmounts(int total) {
    final suggestions = <int>{total};
    for (final preset in const [10000, 20000, 50000, 100000, 200000]) {
      if (preset >= total) suggestions.add(preset);
    }
    return suggestions.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final paidAmount = _paidAmount;
    final change = cart.changeFor(paidAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang kosong',
              subtitle: 'Tambahkan obat dari layar kasir terlebih dahulu.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Daftar Belanja (${cart.totalQuantity} item)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < cart.items.length; i++) ...[
                        if (i > 0) const Divider(),
                        _CartItemTile(
                          item: cart.items[i],
                          onIncrement: () => _handleCartError(
                            controller.increment(cart.items[i].medicine.id),
                          ),
                          onDecrement: () => _handleCartError(
                            controller.decrement(cart.items[i].medicine.id),
                          ),
                          onRemove: () =>
                              controller.remove(cart.items[i].medicine.id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text('Total Belanja', style: theme.textTheme.titleSmall),
                            const Spacer(),
                            Text(
                              Formatters.rupiah(cart.total),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _paidController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          onChanged: (_) => setState(() => _errorMessage = null),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Bayar',
                            prefixText: 'Rp',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final amount in _quickAmounts(cart.total))
                              ActionChip(
                                label: Text(
                                  amount == cart.total
                                      ? 'Uang Pas (${Formatters.rupiah(amount)})'
                                      : Formatters.rupiah(amount),
                                ),
                                onPressed: () => _setPaidAmount(amount),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: change >= 0
                                ? AppTheme.success.withValues(alpha: 0.08)
                                : AppTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                change >= 0 ? 'Kembalian' : 'Kurang bayar',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Formatters.rupiah(change.abs()),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: change >= 0
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _noteController,
                          maxLength: 255,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (opsional)',
                            hintText: 'Contoh: Pembeli umum',
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Proses Pembayaran'),
                ),
              ),
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.rupiah(item.medicine.price)} / ${item.medicine.unit} • Stok ${item.medicine.stock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.rupiah(item.subtotal),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: onDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: onIncrement,
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
