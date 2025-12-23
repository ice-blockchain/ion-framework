// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/avatar_with_badge.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensListItem extends ConsumerWidget {
  const CreatorTokensListItem({
    required this.token,
    super.key,
  });

  final CommunityToken token;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: BadgesUserListItem(
        title: Text(token.creator.display, strutStyle: const StrutStyle(forceStrutHeight: true)),
        trailing: _TokenPriceLabel(
          price: token.marketData.priceUSD,
        ),
        subtitle: _CreatorStatsWidget(
          marketCap: token.marketData.marketCap,
          volume: token.marketData.volume,
          holders: token.marketData.holders,
        ),
        //TODO (ice-kreios): fix this
        masterPubkey: token.externalAddress,
        leading: AvatarWithIndicator(
          masterPubkey: token.externalAddress,
          tokenType: token.type,
        ),
        onTap: () {
          TokenizedCommunityRoute(
            externalAddress: token.externalAddress,
          ).push<void>(context);
        },
      ),
    );
  }
}

class _TokenPriceLabel extends StatelessWidget {
  const _TokenPriceLabel({
    required this.price,
  });

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
        vertical: 2.0.s,
      ),
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0.s),
        ),
      ),
      height: 20.0.s,
      child: Center(
        child: Text(
          formatToCurrency(price),
          style: context.theme.appTextThemes.caption4.copyWith(
            color: context.theme.appColors.primaryBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CreatorStatsWidget extends StatelessWidget {
  const _CreatorStatsWidget({
    required this.marketCap,
    required this.volume,
    required this.holders,
  });

  final double marketCap;
  final double volume;
  final int holders;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.appColors.quaternaryText;
    final iconColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    final textStyle = context.theme.appTextThemes.caption.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );

    final stats = [
      (icon: Assets.svg.iconMemeMarketcap, value: formatCount(marketCap.toInt())),
      (icon: Assets.svg.iconMemeMarkers, value: MarketDataFormatter.formatVolume(volume)),
      (
        icon: Assets.svg.iconSearchGroups,
        value: formatCount(holders),
      ),
    ];

    return Row(
      children: [
        for (final item in stats) ...[
          SvgPicture.asset(
            item.icon,
            colorFilter: iconColorFilter,
            height: 14.0.s,
            width: 14.0.s,
          ),
          SizedBox(width: 2.0.s),
          Text(item.value, style: textStyle),
          if (item != stats.last) ...[
            SizedBox(width: 6.0.s),
            Text('•', style: textStyle),
            SizedBox(width: 6.0.s),
          ],
        ],
      ],
    );
  }
}
