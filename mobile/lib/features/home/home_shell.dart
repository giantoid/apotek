import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../dashboard/presentation/dashboard_screen.dart';
import '../medicines/presentation/medicine_list_screen.dart';
import '../pos/presentation/cart_controller.dart';
import '../pos/presentation/pos_screen.dart';
import '../sales/presentation/sale_history_screen.dart';

enum HomeTab { dashboard, medicines, pos, sales }

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);

class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.dashboard;

  void select(HomeTab tab) {
    state = tab;
  }
}

/// Kerangka navigasi utama dengan Bottom Navigation Bar Material 3.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    final cartQty = ref.watch(
      cartControllerProvider.select((cart) => cart.totalQuantity),
    );

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          DashboardScreen(),
          MedicineListScreen(),
          PosScreen(),
          SaleHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) =>
            ref.read(homeTabProvider.notifier).select(HomeTab.values[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Obat',
          ),
          NavigationDestination(
            icon: Badge.count(
              isLabelVisible: cartQty > 0,
              count: cartQty,
              child: const Icon(Icons.point_of_sale_outlined),
            ),
            selectedIcon: Badge.count(
              isLabelVisible: cartQty > 0,
              count: cartQty,
              child: const Icon(Icons.point_of_sale_rounded),
            ),
            label: 'Kasir',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
