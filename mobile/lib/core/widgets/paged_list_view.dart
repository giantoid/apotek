import 'package:material_ui/material_ui.dart';

import '../pagination/paged_controller.dart';
import 'state_views.dart';

/// ListView generik untuk [PagedState]: menangani loading awal, error,
/// data kosong, pull-to-refresh, dan infinite scroll.
class PagedListView<T, Q> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.emptyView,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.separatorHeight = 10,
  });

  final PagedState<T, Q> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget emptyView;
  final Widget? header;
  final EdgeInsets padding;
  final double separatorHeight;

  @override
  State<PagedListView<T, Q>> createState() => _PagedListViewState<T, Q>();
}

class _PagedListViewState<T, Q> extends State<PagedListView<T, Q>> {
  static const _loadMoreThreshold = 300.0;

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis == Axis.vertical &&
        metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold) {
      widget.onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return _scrollableFill(
        ErrorView(message: state.error!, onRetry: widget.onRefresh),
      );
    }

    if (state.isEmpty) {
      return _scrollableFill(widget.emptyView);
    }

    final hasHeader = widget.header != null;
    final footerCount = (state.hasMore || state.loadMoreError != null) ? 1 : 0;
    final itemCount = state.items.length + footerCount + (hasHeader ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(height: widget.separatorHeight),
          itemBuilder: (context, index) {
            if (hasHeader) {
              if (index == 0) return widget.header!;
              index -= 1;
            }
            if (index < state.items.length) {
              return widget.itemBuilder(context, state.items[index]);
            }
            return _footer(state);
          },
        ),
      ),
    );
  }

  Widget _footer(PagedState<T, Q> state) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(state.loadMoreError!, textAlign: TextAlign.center),
            TextButton(onPressed: widget.onLoadMore, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  /// Membuat konten tetap bisa ditarik untuk refresh walau tidak ada data.
  Widget _scrollableFill(Widget child) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                ?widget.header,
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
