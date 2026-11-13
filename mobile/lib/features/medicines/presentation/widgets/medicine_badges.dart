import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/medicine.dart';

/// Kumpulan badge status obat: kedaluwarsa, segera kedaluwarsa, stok
/// menipis/habis, dan butuh resep.
class MedicineBadges extends StatelessWidget {
  const MedicineBadges({super.key, required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (medicine.isExpired())
        const StatusBadge(
          label: 'Kedaluwarsa',
          color: AppTheme.danger,
          icon: Icons.block_rounded,
        )
      else if (medicine.isExpiringSoon)
        const StatusBadge(
          label: 'Segera kedaluwarsa',
          color: AppTheme.danger,
          icon: Icons.schedule_rounded,
        ),
      if (medicine.isOutOfStock)
        const StatusBadge(
          label: 'Stok habis',
          color: AppTheme.danger,
          icon: Icons.remove_shopping_cart_outlined,
        )
      else if (medicine.isLowStock)
        const StatusBadge(
          label: 'Stok menipis',
          color: AppTheme.warning,
          icon: Icons.trending_down_rounded,
        ),
      if (medicine.requiresPrescription)
        const StatusBadge(
          label: 'Resep',
          color: AppTheme.info,
          icon: Icons.receipt_long_outlined,
        ),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }
}
