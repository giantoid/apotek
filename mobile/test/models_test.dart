import 'package:apotek_mobile/core/network/api_exception.dart';
import 'package:apotek_mobile/core/network/paginated.dart';
import 'package:apotek_mobile/features/auth/data/user.dart';
import 'package:apotek_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:apotek_mobile/features/medicines/data/medicine.dart';
import 'package:apotek_mobile/features/sales/data/sale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('User.fromJson memetakan role dan inisial', () {
    final user = User.fromJson({
      'id': 2,
      'name': 'Kasir Demo',
      'email': 'kasir@apotek.test',
      'role': 'kasir',
    });

    expect(user.id, 2);
    expect(user.role, UserRole.kasir);
    expect(user.isAdmin, isFalse);
    expect(user.initials, 'KD');
  });

  test('Medicine.fromJson dan Paginated.fromJson memetakan data kontrak API', () {
    final page = Paginated.fromJson({
      'data': [
        {
          'id': 1,
          'sku': 'OBT-0001',
          'name': 'Paracetamol 500 mg',
          'category': {'id': 1, 'name': 'Analgesik'},
          'unit': 'strip',
          'price': 12000,
          'stock': 120,
          'min_stock': 20,
          'expiry_date': '2027-08-31',
          'requires_prescription': false,
          'is_low_stock': false,
          'is_expiring_soon': false,
        },
      ],
      'meta': {
        'current_page': 1,
        'last_page': 3,
        'per_page': 15,
        'total': 42,
      },
    }, Medicine.fromJson);

    expect(page.hasMore, isTrue);
    expect(page.total, 42);
    final med = page.items.single;
    expect(med.sku, 'OBT-0001');
    expect(med.category?.name, 'Analgesik');
    expect(med.price, 12000);
    expect(med.expiryDate, DateTime(2027, 8, 31));
    expect(med.isSellable(DateTime(2026, 11, 13)), isTrue);
  });

  test('Sale.fromJson memetakan struk beserta items', () {
    final sale = Sale.fromJson({
      'id': 10,
      'invoice_number': 'INV-20261112-0001',
      'cashier': {'id': 2, 'name': 'Kasir Demo'},
      'total': 24000,
      'paid_amount': 50000,
      'change_amount': 26000,
      'note': null,
      'created_at': '2026-11-12T13:30:00+07:00',
      'items': [
        {
          'medicine_id': 1,
          'medicine_name': 'Paracetamol 500 mg',
          'quantity': 2,
          'price': 12000,
          'subtotal': 24000,
        },
      ],
    });

    expect(sale.invoiceNumber, 'INV-20261112-0001');
    expect(sale.cashier?.name, 'Kasir Demo');
    expect(sale.changeAmount, 26000);
    expect(sale.items.length, 1);
    expect(sale.items.first.subtotal, 24000);
  });

  test('DashboardSummary.fromJson memetakan ringkasan', () {
    final summary = DashboardSummary.fromJson({
      'today_sales_total': 1250000,
      'today_transactions': 18,
      'low_stock_count': 4,
      'expiring_soon_count': 3,
      'medicine_count': 40,
    });

    expect(summary.todaySalesTotal, 1250000);
    expect(summary.todayTransactions, 18);
    expect(summary.lowStockCount, 4);
    expect(summary.expiringSoonCount, 3);
    expect(summary.medicineCount, 40);
  });

  test('ApiException.fromResponse mengambil pesan validasi 422 dari server', () {
    final ex = ApiException.fromResponse(422, {
      'message': 'The given data was invalid.',
      'errors': {
        'paid_amount': ['Jumlah bayar kurang dari total belanja.'],
      },
    });

    expect(ex.isValidationError, isTrue);
    expect(ex.message, 'Jumlah bayar kurang dari total belanja.');
  });
}
