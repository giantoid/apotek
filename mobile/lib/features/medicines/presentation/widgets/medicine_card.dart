import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/medicine.dart';
import 'medicine_badges.dart';

/// Kartu ringkas obat untuk daftar obat dan hasil pencarian kasir.
class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.trailing,
  });

  final Medicine medicine;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unavailable = !medicine.isSellable();
    final stockColor = medicine.isOutOfStock
        ? AppTheme.danger
        : medicine.isLowStock
            ? AppTheme.warning
            : scheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unavailable
                      ? AppTheme.danger.withValues(alpha: 0.1)
                      : scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: unavailable ? AppTheme.danger : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [medicine.sku, ?medicine.category?.name].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Formatters.rupiah(medicine.price),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' / ${medicine.unit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.inventory_2_outlined, size: 14, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          'Stok ${Formatters.number(medicine.stock)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (medicine.isExpired() ||
                        medicine.isExpiringSoon ||
                        medicine.isLowStock ||
                        medicine.isOutOfStock ||
                        medicine.requiresPrescription) ...[
                      const SizedBox(height: 8),
                      MedicineBadges(medicine: medicine),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
