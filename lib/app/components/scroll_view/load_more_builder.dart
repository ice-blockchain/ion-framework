// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';

class LoadMoreBuilder extends HookWidget {
  LoadMoreBuilder({
    required this.slivers,
    required this.onLoadMore,
    required this.hasMore,
    Widget Function(BuildContext context, List<Widget> slivers)? builder,
    this.loadingIndicatorContainerBuilder,
    this.loadMoreOffset,
    this.showIndicator = true,
    super.key,
  }) : builder = builder ??
            ((BuildContext context, List<Widget> slivers) => CustomScrollView(slivers: slivers));

  final Widget Function(BuildContext context, List<Widget> slivers) builder;

  final Widget Function(BuildContext context, Widget child)? loadingIndicatorContainerBuilder;

  final List<Widget> slivers;

  final Future<void> Function() onLoadMore;

  final double? loadMoreOffset;

  final bool hasMore;

  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    final loading = useState(false);

    final loadMore = useCallback(
      () {
        if (hasMore && !loading.value) {
          loading.value = true;
          onLoadMore().whenComplete(() => loading.value = false);
        }
      },
      [hasMore, loading.value, onLoadMore],
    );

    final loadingIndicator = Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(10.0.s),
        child: const IONLoadingIndicatorThemed(),
      ),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onMetricsChanged(notification, loadMore),
      child: builder(
        context,
        loading.value && showIndicator
            ? [
                ...slivers,
                SliverToBoxAdapter(
                  child: loadingIndicatorContainerBuilder?.call(
                        context,
                        loadingIndicator,
                      ) ??
                      loadingIndicator,
                ),
              ]
            : slivers,
      ),
    );
  }

  bool _onMetricsChanged(
    ScrollNotification notification,
    void Function() loadMore,
  ) {
    final metrics = notification.metrics;

    // Do not trigger loadMore if the list is not scrollable at all.
    if (!metrics.hasPixels || metrics.maxScrollExtent == 0.0) {
      return false;
    }

    final loadMoreOffset = this.loadMoreOffset ?? metrics.viewportDimension;
    if (metrics.maxScrollExtent - metrics.pixels <= loadMoreOffset) {
      loadMore();
      return true;
    }
    return false;
  }
}
