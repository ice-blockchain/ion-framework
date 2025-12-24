// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trade_row.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_empty.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_skeleton.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class TradesPage extends HookConsumerWidget {
  const TradesPage({required this.externalAddress, super.key});

  static const int pageSize = 20;

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesProvider = tokenLatestTradesProvider(externalAddress, limit: pageSize);
    final tradesAsync = ref.watch(tradesProvider);

    final isLoadingMore = useState(false);
    final hasMore = useState(true);

    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final badgeTextStyle = texts.caption6.copyWith(color: colors.secondaryBackground);

    final buyTextWidth = useMemoized(
      () => _calculateTextWidth(i18n.trade_buy, badgeTextStyle),
      [i18n.trade_buy, badgeTextStyle],
    );
    final sellTextWidth = useMemoized(
      () => _calculateTextWidth(i18n.trade_sell, badgeTextStyle),
      [i18n.trade_sell, badgeTextStyle],
    );
    final baseTextWidth = buyTextWidth > sellTextWidth ? buyTextWidth : sellTextWidth;
    final minTextWidth = baseTextWidth + 2.0.s;

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
                tradesAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.s, vertical: 12.s),
                      child: LatestTradesSkeleton(count: pageSize, seperatorHeight: 14.s),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(child: LatestTradesEmpty()),
                  data: (data) {
                    if (data.isEmpty) {
                      return const SliverToBoxAdapter(child: LatestTradesEmpty());
                    }

                    return SliverList.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final trade = data[index];
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
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = textPainter.width;
    textPainter.dispose();
    return w;
  }
}
