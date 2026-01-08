// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trade_row.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_empty.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_skeleton.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/utils/string.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradesPage extends HookConsumerWidget {
  const TradesPage({required this.externalAddress, super.key});

  static const int pageSize = 15;

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final tradesProvider = tokenLatestTradesProvider(externalAddress, limit: pageSize);
    final tradesAsync = ref.watch(tradesProvider);

    final isLoadingMore = useState(false);
    final hasMore = useState(true);

    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final badgeTextStyle = texts.caption6.copyWith(color: colors.secondaryBackground);

    final buyTextWidth = useMemoized(
      () => calculateTextWidth(i18n.trade_buy, badgeTextStyle),
      [i18n.trade_buy, badgeTextStyle],
    );
    final sellTextWidth = useMemoized(
      () => calculateTextWidth(i18n.trade_sell, badgeTextStyle),
      [i18n.trade_sell, badgeTextStyle],
    );
    final baseTextWidth = buyTextWidth > sellTextWidth ? buyTextWidth : sellTextWidth;
    final minTextWidth = baseTextWidth + 2.0.s;

    final trades = tradesAsync.valueOrNull ?? const <LatestTrade>[];
    final hasError = tradesAsync.hasError;

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(i18n.latest_trades_title, style: texts.subtitle2),
      ),
      body: Column(
        children: [
          const SimpleSeparator(),
          Expanded(
            child: LoadMoreBuilder(
              showIndicator: false,
              disallowMaxScrollExtentZero: false,
              onLoadMore: () async {
                if (isLoadingMore.value || !hasMore.value) return;

                isLoadingMore.value = true;
                try {
                  final fetched = await ref.read(tradesProvider.notifier).loadMore();
                  if (fetched < pageSize) {
                    hasMore.value = false;
                  }
                } finally {
                  isLoadingMore.value = false;
                }
              },
              hasMore: hasMore.value,
              slivers: [
                if (tradesAsync.isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.s, vertical: 12.s),
                      child: LatestTradesSkeleton(count: pageSize, seperatorHeight: 14.s),
                    ),
                  )
                else if (hasError)
                  const SliverToBoxAdapter(child: LatestTradesEmpty())
                else if (trades.isEmpty)
                  const SliverToBoxAdapter(child: LatestTradesEmpty())
                else
                  SliverList.builder(
                    itemCount: trades.length,
                    itemBuilder: (context, index) {
                      final trade = trades[index];
                      final topPadding = index == 0 ? 12.s : 0.0;
                      final bottomPadding = 14.s;

                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: topPadding,
                          bottom: bottomPadding,
                          start: 16.s,
                          end: 16.s,
                        ),
                        child: LatestTradeRow(
                          trade: trade,
                          minTextWidth: minTextWidth,
                        ),
                      );
                    },
                  ),
                if (isLoadingMore.value)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(10.0.s),
                        child: const IONLoadingIndicatorThemed(),
                      ),
                    ),
                  ),
              ],
              builder: (context, slivers) {
                return PullToRefreshBuilder(
                  slivers: slivers,
                  onRefresh: () async {
                    hasMore.value = true;
                    ref.invalidate(tradesProvider);
                  },
                  builder: (context, slivers) => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    slivers: slivers,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
