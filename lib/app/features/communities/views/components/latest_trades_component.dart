// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LatestTradesComponent extends HookWidget {
  const LatestTradesComponent({
    required this.trades,
    this.maxVisible = 5,
    this.onViewAllPressed,
    this.onTapTrade,
    this.onLoadMore,
    this.onTitleVisibilityChanged,
    super.key,
  });

  final List<LatestTrade> trades;
  final int maxVisible;
  final VoidCallback? onViewAllPressed;
  final ValueChanged<LatestTrade>? onTapTrade;
  final VoidCallback? onLoadMore;
  final ValueChanged<double>? onTitleVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final visible = useMemoized(
      () => trades.take(maxVisible).toList(),
      [trades, maxVisible],
    );

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

    final titleRow = Row(
      children: [
        Assets.svg.fluentArrowSort16Regular.icon(size: 18.0.s),
        SizedBox(width: 6.0.s),
        Expanded(
          child: Text(
            i18n.latest_trades_title,
            style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onViewAllPressed != null)
          GestureDetector(
            onTap: onViewAllPressed,
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
                child: titleRow,
              )
            else
              titleRow,
            SizedBox(height: 14.0.s),
            Column(
              children: [
                for (final trade in visible)
                  _TradeRow(
                    trade: trade,
                    minTextWidth: minTextWidth,
                    onTap: onTapTrade,
                  ),
              ],
            ),
            if (onLoadMore != null) ...[
              SizedBox(height: 12.0.s),
              Center(
                child: TextButton(
                  onPressed: onLoadMore,
                  child: Text(
                    'Load More',
                    style: texts.caption.copyWith(color: colors.primaryAccent),
                  ),
                ),
              ),
            ],
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

    //TODO: change type to int
    final timeText = formatShortTimestamp(DateTime.parse(trade.position.createdAt));
    final amountText = formatDoubleCompact(trade.position.amount);
    final usdText = formatUSD(trade.position.amountUSD);
    //TODO: use enum
    final badgeColor = trade.position.type == 'buy' ? colors.success : colors.lossRed;
    final badgeText = trade.position.type == 'buy' ? i18n.trade_buy : i18n.trade_sell;

    final textStyle = texts.caption6.copyWith(color: colors.secondaryBackground);

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.s, vertical: 1.0.s),
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _Avatar(url: trade.position.holder.avatar),
                SizedBox(width: 8.0.s),
                _TitleAndMeta(
                  name: trade.position.holder.display,
                  handle: trade.position.holder.name,
                  //TODO: add verified
                  verified: true,
                  meta: '$amountText • \$$usdText • $timeText',
                ),
              ],
            ),
            badge,
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(
        color: colors.onTertiaryFill,
        borderRadius: BorderRadius.circular(10.0.s),
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
  });

  final String name;
  final String handle;
  final String meta;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(name, style: texts.subtitle3.copyWith(color: colors.primaryText)),
            if (handle.isNotEmpty) ...[
              SizedBox(width: 4.0.s),
              Text(handle, style: texts.caption2.copyWith(color: colors.quaternaryText)),
            ],
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
          ],
        ),
        SizedBox(height: 2.0.s),
        Text(meta, style: texts.caption.copyWith(color: colors.quaternaryText)),
      ],
    );
  }
}
