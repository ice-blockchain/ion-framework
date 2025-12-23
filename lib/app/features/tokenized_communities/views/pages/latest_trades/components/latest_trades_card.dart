// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_empty.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_skeleton.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LatestTradesCard extends HookConsumerWidget {
  const LatestTradesCard({required this.externalAddress, this.onTitleVisibilityChanged, super.key});

  static const int limit = 5;

  final String externalAddress;
  final ValueChanged<double>? onTitleVisibilityChanged;

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
      () => _calculateTextWidth(i18n.trade_buy, badgeTextStyle),
      [i18n.trade_buy, badgeTextStyle],
    );

    final sellTextWidth = useMemoized(
      () => _calculateTextWidth(i18n.trade_sell, badgeTextStyle),
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
            if (onTitleVisibilityChanged != null)
              VisibilityDetector(
                key: UniqueKey(),
                onVisibilityChanged: (info) {
                  onTitleVisibilityChanged?.call(info.visibleFraction);
                },
                child: _CardTitle(
                  tradesCount: tradesCount,
                  title: i18n.latest_trades_title,
                  externalAddress: externalAddress,
                ),
              )
            else
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
                    return _TradeRow(
                      trade: trade,
                      minTextWidth: minTextWidth,
                      onTap: (_) {},
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

  double _calculateTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final textWidth = textPainter.width;
    textPainter.dispose();
    return textWidth;
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

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade, required this.minTextWidth, this.onTap});

  final LatestTrade trade;
  final double minTextWidth;
  final ValueChanged<LatestTrade>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final timeText = formatShortTimestamp(DateTime.parse(trade.position.createdAt));
    final amountText = formatAmountCompactFromRaw(trade.position.amount);
    final usdText = formatUSD(trade.position.amountUSD);
    final badgeColor = trade.position.type == TradeType.buy ? colors.success : colors.lossRed;
    final badgeText = trade.position.type == TradeType.buy ? i18n.trade_buy : i18n.trade_sell;

    final holderAddress =
        trade.position.holder.addresses?.ionConnect ?? trade.position.addresses.ionConnect;
    final creatorAddress = trade.creator.addresses?.ionConnect;
    final isCreator =
        creatorAddress != null && holderAddress != null && holderAddress == creatorAddress;

    final textStyle = texts.caption6.copyWith(color: colors.secondaryBackground);

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.s),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12.0.s)),
      child: SizedBox(
        width: minTextWidth,
        child: Text(
          badgeText,
          style: textStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(trade),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                HolderAvatar(imageUrl: trade.position.holder.avatar),
                SizedBox(width: 8.0.s),
                Expanded(
                  child: _TitleAndMeta(
                    name: trade.position.holder.display,
                    handle: trade.position.holder.name,
                    verified: trade.position.holder.verified,
                    isCreator: isCreator,
                    meta: '$amountText • \$$usdText • $timeText',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.0.s),
          badge,
        ],
      ),
    );
  }
}

class _TitleAndMeta extends StatelessWidget {
  const _TitleAndMeta({
    required this.name,
    required this.handle,
    required this.meta,
    this.verified = false,
    this.isCreator = false,
  });

  final String name;
  final String handle;
  final String meta;
  final bool verified;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: texts.subtitle3.copyWith(color: colors.primaryText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            if (handle.isNotEmpty) ...[
              SizedBox(width: 4.0.s),
              Flexible(
                child: Text(
                  handle,
                  style: texts.caption2.copyWith(color: colors.quaternaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
            if (isCreator) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeCreator.icon(size: 16.0.s),
            ],
          ],
        ),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
