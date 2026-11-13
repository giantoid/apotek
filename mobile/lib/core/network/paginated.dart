import '../utils/json_utils.dart';

/// Respons daftar berpaginasi sesuai kontrak:
/// `{ "data": [...], "meta": { current_page, last_page, per_page, total } }`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromItem,
  ) {
    final data = (json['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(fromItem)
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return Paginated(
      items: data,
      currentPage: parseInt(meta['current_page'], fallback: 1),
      lastPage: parseInt(meta['last_page'], fallback: 1),
      perPage: parseInt(meta['per_page'], fallback: data.length),
      total: parseInt(meta['total'], fallback: data.length),
    );
  }

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
