import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../data/medicine.dart';
import 'medicine_providers.dart';
import 'widgets/medicine_badges.dart';

class MedicineDetailScreen extends ConsumerWidget {
  const MedicineDetailScreen({super.key, required this.medicineId, this.initial});

  final int medicineId;

  /// Data dari daftar agar layar langsung tampil sambil memuat data terbaru.
  final Medicine? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(medicineDetailProvider(medicineId));
    final medicine = detail.value ?? initial;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Obat')),
      body: medicine == null
          ? detail.when(
              data: (_) => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: describeError(error),
                onRetry: () => ref.invalidate(medicineDetailProvider(medicineId)),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(medicineDetailProvider(medicineId).future),
              child: _MedicineDetailBody(medicine: medicine),
            ),
    );
  }
}

class _MedicineDetailBody extends StatelessWidget {
  const _MedicineDetailBody({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = medicine.daysUntilExpiry();
    final expiry = medicine.expiryDate;

    final String expiryText;
    if (expiry == null) {
      expiryText = '-';
    } else if (days! < 0) {
      expiryText = '${Formatters.date(expiry)} (lewat ${-days} hari)';
    } else if (days == 0) {
      expiryText = '${Formatters.date(expiry)} (hari ini)';
    } else {
      expiryText = '${Formatters.date(expiry)} ($days hari lagi)';
    }

    // Indikator stok relatif terhadap 3x stok minimum.
    final stockTarget = (medicine.minStock * 3).clamp(1, 1 << 31);
    final stockRatio = (medicine.stock / stockTarget).clamp(0.0, 1.0);
    final stockColor = medicine.isOutOfStock
        ? AppTheme.danger
        : medicine.isLowStock
            ? AppTheme.warning
            : AppTheme.success;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.medication_rounded, color: scheme.primary, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            medicine.sku,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  Formatters.rupiah(medicine.price),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('per ${medicine.unit}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                MedicineBadges(medicine: medicine),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Stok',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${Formatters.number(medicine.stock)} ${medicine.unit}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: stockColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stockRatio,
                    minHeight: 8,
                    color: stockColor,
                    backgroundColor: stockColor.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok minimum: ${Formatters.number(medicine.minStock)} ${medicine.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.category_outlined,
                label: 'Kategori',
                value: medicine.category?.name ?? '-',
              ),
              const Divider(indent: 56),
              _InfoTile(icon: Icons.straighten_rounded, label: 'Satuan', value: medicine.unit),
              const Divider(indent: 56),
              _InfoTile(
                icon: Icons.event_outlined,
                label: 'Kedaluwarsa',
                value: expiryText,
                valueColor: medicine.isExpired() || medicine.isExpiringSoon
                    ? AppTheme.danger
                    : null,
              ),
              const Divider(indent: 56),
              _InfoTile(
                icon: Icons.receipt_long_outlined,
                label: 'Butuh resep dokter',
                value: medicine.requiresPrescription ? 'Ya' : 'Tidak',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodySmall),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: valueColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
