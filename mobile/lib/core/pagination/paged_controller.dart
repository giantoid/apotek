import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../network/paginated.dart';

const _unset = Object();

/// State generik untuk daftar berpaginasi dengan infinite scroll.
@immutable
class PagedState<T, Q> {
  const PagedState({
    required this.query,
    this.items = const [],
    this.page = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
  });

  final Q query;
  final List<T> items;
  final int page;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;

  /// Error saat memuat halaman pertama.
  final String? error;

  /// Error saat memuat halaman berikutnya (daftar lama tetap ditampilkan).
  final String? loadMoreError;

  bool get hasMore => page < lastPage;
  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  PagedState<T, Q> copyWith({
    Q? query,
    List<T>? items,
    int? page,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _unset,
    Object? loadMoreError = _unset,
  }) {
    return PagedState<T, Q>(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: identical(error, _unset) ? this.error : error as String?,
      loadMoreError: identical(loadMoreError, _unset)
          ? this.loadMoreError
          : loadMoreError as String?,
    );
  }
}

/// Controller dasar untuk daftar berpaginasi. Subclass cukup menyediakan
/// [initialQuery] dan [fetchPage].
///
/// Respons yang datang terlambat (mis. pengguna sudah mengganti kata kunci
/// pencarian) diabaikan menggunakan penghitung generasi.
abstract class PagedController<T, Q> extends Notifier<PagedState<T, Q>> {
  int _generation = 0;

  Q get initialQuery;

  Future<Paginated<T>> fetchPage(Q query, int page);

  @override
  PagedState<T, Q> build() {
    final query = initialQuery;
    Future.microtask(() => _load(query));
    return PagedState<T, Q>(query: query, isLoading: true);
  }

  /// Memuat ulang dari halaman pertama dengan query saat ini.
  Future<void> refresh() => _load(state.query);

  /// Mengganti query (pencarian/filter) lalu memuat dari halaman pertama.
  Future<void> updateQuery(Q query) async {
    if (query == state.query) return;
    await _load(query);
  }

  Future<void> _load(Q query) async {
    if (!ref.mounted) return;
    final generation = ++_generation;
    final queryChanged = query != state.query;
    state = state.copyWith(
      query: query,
      items: queryChanged ? const [] : null,
      isLoading: true,
      isLoadingMore: false,
      error: null,
      loadMoreError: null,
    );
    try {
      final result = await fetchPage(query, 1);
      if (!ref.mounted || generation != _generation) return;
      state = PagedState<T, Q>(
        query: query,
        items: result.items,
        page: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } on ApiException catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Memuat halaman berikutnya (dipanggil saat scroll mendekati bawah).
  Future<void> loadMore() async {
    if (!ref.mounted || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, loadMoreError: null);
    try {
      final result = await fetchPage(state.query, state.page + 1);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: e.message);
    }
  }
}
