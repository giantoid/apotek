import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';

/// Ringkasan `GET /dashboard`.
class DashboardSummary {
  const DashboardSummary({
    required this.todaySalesTotal,
    required this.todayTransactions,
    required this.lowStockCount,
    required this.expiringSoonCount,
    required this.medicineCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        todaySalesTotal: parseInt(json['today_sales_total']),
        todayTransactions: parseInt(json['today_transactions']),
        lowStockCount: parseInt(json['low_stock_count']),
        expiringSoonCount: parseInt(json['expiring_soon_count']),
        medicineCount: parseInt(json['medicine_count']),
      );

  final int todaySalesTotal;
  final int todayTransactions;
  final int lowStockCount;
  final int expiringSoonCount;
  final int medicineCount;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> fetchSummary() {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('/dashboard');
      return DashboardSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }
}
