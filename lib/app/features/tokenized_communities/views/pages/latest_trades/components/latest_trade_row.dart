// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class LatestTradeRow extends StatelessWidget {
  const LatestTradeRow({
    required this.trade,
    required this.minTextWidth,
    this.onTap,
    super.key,
  });

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

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.s),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      child: SizedBox(
        width: minTextWidth,
        child: Text(
          badgeText,
          style: texts.caption6.copyWith(color: colors.secondaryBackground),
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );

    final name = trade.position.holder.display ??
        shortenAddress(
          trade.position.addresses.ionConnect ??
              trade.position.addresses.twitter ??
              trade.position.addresses.blockchain ??
              '',
        );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              HolderAvatar(
                imageUrl: trade.position.holder.avatar,
                seed: name,
              ),
              SizedBox(width: 8.0.s),
              Expanded(
                child: _TitleAndMeta(
                  name: name,
                  handle: trade.position.holder.name.isNotEmpty ? trade.position.holder.name : null,
                  verified: trade.position.holder.verified ?? false,
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
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: () => onTap!(trade),
      child: content,
    );
  }
}

class _TitleAndMeta extends StatelessWidget {
  const _TitleAndMeta({
    required this.name,
    required this.meta,
    this.verified = false,
    this.isCreator = false,
    this.handle,
  });

  final String name;
  final String meta;
  final bool verified;
  final bool isCreator;
  final String? handle;

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
          handle != null ? '$handle • $meta' : meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
