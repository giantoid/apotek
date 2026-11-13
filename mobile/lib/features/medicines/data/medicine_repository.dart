import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated.dart';
import 'medicine.dart';
import 'medicine_query.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => MedicineRepository(ref.watch(dioProvider)),
);

/// Endpoint obat & kategori.
class MedicineRepository {
  MedicineRepository(this._dio);

  final Dio _dio;

  /// `GET /medicines?search=&category_id=&filter=&page=`.
  Future<Paginated<Medicine>> fetchMedicines(MedicineQuery query, {int page = 1}) {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/medicines',
        queryParameters: query.toQueryParameters(page: page),
      );
      return Paginated.fromJson(response.data!, Medicine.fromJson);
    });
  }

  /// `GET /medicines/{id}`.
  Future<Medicine> fetchMedicine(int id) {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('/medicines/$id');
      return Medicine.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }

  /// `GET /medicines/sku/{sku}` (untuk scan barcode / input SKU).
  Future<Medicine> findBySku(String sku) {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/medicines/sku/${Uri.encodeComponent(sku)}',
      );
      return Medicine.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }

  /// `GET /categories` (tanpa paginasi).
  Future<List<Category>> fetchCategories() {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('/categories');
      return (response.data!['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();
    });
  }
}
