// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/text/inline_badge_text.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/router/utils/profile_navigation_utils.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class LatestTradeRow extends StatelessWidget {
  const LatestTradeRow({
    required this.trade,
    required this.minTextWidth,
    super.key,
  });

  final LatestTrade trade;
  final double minTextWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final timeText = formatShortTimestamp(DateTime.parse(trade.position.createdAt));
    final amountText = formatAmountCompactFromRaw(trade.position.amount);
    final usdText = formatUSD(trade.position.amountUSD);

    final badgeColor = trade.position.type == TradeType.buy ? colors.success : colors.lossRed;
    final badgeText = trade.position.type == TradeType.buy
        ? i18n.trade_buy_badge_label
        : i18n.trade_sell_badge_label;

    final isCreator = trade.isCreator;
    final holderIonConnectAddress = trade.position.holder.addresses?.ionConnect;
    final isXUser = trade.position.holder.isXUser;
    final username = trade.position.holder.name;

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
                isXUser: isXUser,
                isIonConnectUser: trade.position.holder.addresses?.ionConnect != null,
              ),
              SizedBox(width: 8.0.s),
              Expanded(
                child: TitleAndMeta(
                  name: name,
                  handle: trade.position.holder.name.isNotEmpty
                      ? '@${trade.position.holder.name}'
                      : null,
                  verified: trade.position.holder.verified ?? false,
                  isCreator: isCreator,
                  meta: '$amountText • \$$usdText • $timeText',
                  isXUser: isXUser,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.0.s),
        badge,
      ],
    );

    return InkWell(
      onTap: isXUser
          ? () => openUrlInAppBrowser('https://x.com/$username')
          : holderIonConnectAddress != null
              ? () => ProfileNavigationUtils.navigateToProfile(
                    context,
                    pubkey: holderIonConnectAddress,
                  )
              : null,
      child: content,
    );
  }
}

class TitleAndMeta extends StatelessWidget {
  const TitleAndMeta({
    required this.name,
    required this.meta,
    this.verified = false,
    this.isCreator = false,
    this.handle,
    this.isXUser = false,
    super.key,
  });

  final String name;
  final String meta;
  final bool verified;
  final bool isCreator;
  final String? handle;
  final bool isXUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineBadgeText(
          titleSpan: TextSpan(text: name),
          badges: [
            if (verified) Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            if (isCreator) Assets.svg.iconBadgeCreator.icon(size: 16.0.s),
            if (isXUser) Assets.svg.iconBadgeXlogo.icon(size: 16.0.s),
          ],
          style: texts.subtitle3.copyWith(color: colors.primaryText),
          softWrap: false,
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

extension LatestTradeExtension on LatestTrade {
  bool get isCreator {
    final holderIonConnectAddress = position.holder.addresses?.ionConnect;
    final creatorIonConnectAddress = creator.addresses?.ionConnect;
    final holderTwitterAddress = position.holder.addresses?.twitter;
    final creatorTwitterAddress = creator.addresses?.twitter;

    return (creatorIonConnectAddress != null &&
            holderIonConnectAddress == creatorIonConnectAddress) ||
        (creatorTwitterAddress != null && holderTwitterAddress == creatorTwitterAddress);
  }
}
