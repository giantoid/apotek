import 'package:flutter/foundation.dart';

/// Filter cepat daftar obat (`filter=low_stock|expiring`).
enum MedicineFilter {
  all(null, 'Semua'),
  lowStock('low_stock', 'Stok Menipis'),
  expiring('expiring', 'Segera Kedaluwarsa');

  const MedicineFilter(this.apiValue, this.label);

  final String? apiValue;
  final String label;
}

/// Parameter pencarian `GET /medicines`.
@immutable
class MedicineQuery {
  const MedicineQuery({
    this.search = '',
    this.filter = MedicineFilter.all,
    this.categoryId,
  });

  final String search;
  final MedicineFilter filter;
  final int? categoryId;

  MedicineQuery copyWith({
    String? search,
    MedicineFilter? filter,
    int? Function()? categoryId,
  }) {
    return MedicineQuery(
      search: search ?? this.search,
      filter: filter ?? this.filter,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
    );
  }

  Map<String, dynamic> toQueryParameters({int page = 1}) {
    final trimmed = search.trim();
    return {
      if (trimmed.isNotEmpty) 'search': trimmed,
      if (categoryId != null) 'category_id': categoryId,
      if (filter.apiValue != null) 'filter': filter.apiValue,
      'page': page,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is MedicineQuery &&
      other.search == search &&
      other.filter == filter &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(search, filter, categoryId);
}
