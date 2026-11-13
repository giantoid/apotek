import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated.dart';
import '../../../core/utils/formatters.dart';
import 'sale.dart';

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(ref.watch(dioProvider)),
);

/// Input item untuk checkout `POST /sales`.
class CheckoutItem {
  const CheckoutItem({required this.medicineId, required this.quantity});

  final int medicineId;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'medicine_id': medicineId,
        'quantity': quantity,
      };
}

/// Endpoint transaksi penjualan (`/sales`).
class SaleRepository {
  SaleRepository(this._dio);

  final Dio _dio;

  /// `GET /sales?date=YYYY-MM-DD&page=1`.
  Future<Paginated<Sale>> fetchSales({DateTime? date, int page = 1}) {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sales',
        queryParameters: {
          'page': page,
          if (date != null) 'date': Formatters.apiDate(date),
        },
      );
      return Paginated.fromJson(response.data!, Sale.fromJson);
    });
  }

  /// `GET /sales/{id}`.
  Future<Sale> fetchSale(int id) {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('/sales/$id');
      return Sale.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }

  /// `POST /sales`.
  Future<Sale> checkout({
    required List<CheckoutItem> items,
    required int paidAmount,
    String? note,
  }) {
    return guardRequest(() async {
      final trimmedNote = note?.trim();
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales',
        data: {
          'items': items.map((e) => e.toJson()).toList(),
          'paid_amount': paidAmount,
          if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
        },
      );
      return Sale.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }
}
