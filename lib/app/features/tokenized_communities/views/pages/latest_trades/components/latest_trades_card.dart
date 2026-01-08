// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trade_row.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_empty.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_skeleton.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/string.dart';
import 'package:ion/generated/assets.gen.dart';

class LatestTradesCard extends HookConsumerWidget {
  const LatestTradesCard({required this.externalAddress, super.key});

  static const int limit = 5;

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tokenLatestTradesProvider(externalAddress, limit: limit));

    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final badgeTextStyle = texts.caption6.copyWith(
      color: colors.secondaryBackground,
    );

    final buyTextWidth = useMemoized(
      () => calculateTextWidth(i18n.trade_buy, badgeTextStyle),
      [i18n.trade_buy, badgeTextStyle],
    );

    final sellTextWidth = useMemoized(
      () => calculateTextWidth(i18n.trade_sell, badgeTextStyle),
      [i18n.trade_sell, badgeTextStyle],
    );
    final baseTextWidth = buyTextWidth > sellTextWidth ? buyTextWidth : sellTextWidth;
    final widthBuffer = 2.0.s;
    final minTextWidth = baseTextWidth + widthBuffer;

    final tradesCount = tradesAsync.valueOrNull?.length ?? 0;

    return ColoredBox(
      color: colors.secondaryBackground,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              tradesCount: tradesCount,
              title: i18n.latest_trades_title,
              externalAddress: externalAddress,
            ),
            SizedBox(height: 8.0.s),
            tradesAsync.when(
              data: (data) {
                final trades = data.take(limit).toList();
                if (trades.isEmpty) {
                  return const LatestTradesEmpty();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: trades.length,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    return LatestTradeRow(
                      trade: trade,
                      minTextWidth: minTextWidth,
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 14.0.s),
                );
              },
              loading: () => LatestTradesSkeleton(count: limit, seperatorHeight: 14.0.s),
              error: (error, stackTrace) {
                return const LatestTradesEmpty();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.tradesCount,
    required this.externalAddress,
  });

  final String title;
  final int tradesCount;
  final String externalAddress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    return Row(
      children: [
        Assets.svg.fluentArrowSort16Regular.icon(size: 18.0.s),
        SizedBox(width: 6.0.s),
        Expanded(
          child: Text(
            title,
            style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tradesCount > 0)
          GestureDetector(
            onTap: () => TradesRoute(externalAddress: externalAddress).push<void>(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
              child: Text(
                i18n.core_view_all,
                style: texts.caption2.copyWith(color: colors.primaryAccent),
              ),
            ),
          ),
      ],
    );
  }
}
