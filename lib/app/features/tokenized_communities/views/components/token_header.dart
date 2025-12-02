// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/communities/utils/position_formatters.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/tokenized_communities/views/content_token_header.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/views/pages/info/info_modal.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenHeader extends HookWidget {
  const TokenHeader({
    required this.token,
    super.key,
  });

  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.viewPaddingOf(context).top;

    return Column(
      children: [
        SizedBox(height: statusBarHeight + 57.s),
        if (token.type == CommunityTokenType.profile)
          CreatorTokenHeader(token: token)
        else
          ContentTokenHeader(token: token),
      ],
    );
  }
}

class CreatorTokenHeader extends HookWidget {
  const CreatorTokenHeader({
    required this.token,
    super.key,
  });

  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CommunityTokenImage(
                imageUrl: token.imageUrl,
                width: 89.0.s,
                height: 89.0.s,
                innerBorderRadius: 18.0.s,
                outerBorderRadius: 24.0.s,
                innerPadding: 3.0.s,
              ),
              if (token.source.isTwitter)
                PositionedDirectional(
                  bottom: -3.s,
                  end: -3.s,
                  child: Container(
                    padding: EdgeInsets.all(3.58.s),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8.0.s),
                    ),
                    child: Assets.svg.iconLoginXlogo
                        .icon(size: 15.0.s, color: context.theme.appColors.secondaryBackground),
                  ),
                ),
              if (token.source.isIonConnect && token.eventReference != null)
                PositionedDirectional(
                  bottom: -3.s,
                  end: -3.s,
                  child: ProfileMainAction(
                    profileMode: ProfileMode.dark,
                    pubkey: token.eventReference!.masterPubkey,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.0.s),
        Text(
          token.title,
          style: context.theme.appTextThemes.subtitle.copyWith(
            color: context.theme.appColors.secondaryBackground,
          ),
        ),
        SizedBox(height: 4.0.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              token.marketData.ticker,
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.attentionBlock,
              ),
            ),
            SizedBox(
              width: 6.s,
            ),
            ProfileTokenPrice(amount: token.marketData.priceUSD),
          ],
        ),
        SizedBox(height: 16.0.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 51.0.s),
          child: _StatsRow(
            marketCapUsd: token.marketData.marketCap,
            holdersCount: token.marketData.holders,
            volumeUsd: token.marketData.volume,
            abbreviateCount: MarketDataFormatter.formatCompactNumber,
            formatUsd: MarketDataFormatter.formatPrice,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.marketCapUsd,
    required this.holdersCount,
    required this.volumeUsd,
    required this.abbreviateCount,
    required this.formatUsd,
  });

  final double marketCapUsd;
  final int holdersCount;
  final double volumeUsd;
  final SupplyAbbreviator abbreviateCount;
  final UsdFormatter formatUsd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275.0.s,
      height: 44.0.s,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.5.s),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            iconPath: Assets.svg.iconMemeMarketcap,
            value: abbreviateCount(marketCapUsd),
            onInfoTap: () => showSimpleBottomSheet<void>(
              context: context,
              child: const InfoModal(infoType: InfoType.marketCap),
            ),
          ),
          _StatItem(
            iconPath: Assets.svg.iconMemeMarkers,
            value: formatUsd(volumeUsd).replaceAll(r'$', r'$'),
            onInfoTap: () => showSimpleBottomSheet<void>(
              context: context,
              child: const InfoModal(infoType: InfoType.volume),
            ),
          ),
          _StatItem(
            iconPath: Assets.svg.iconSearchGroups,
            value: abbreviateCount(holdersCount),
            onInfoTap: () => showSimpleBottomSheet<void>(
              context: context,
              child: const InfoModal(infoType: InfoType.holders),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconPath,
    required this.value,
    required this.onInfoTap,
  });

  final String iconPath;
  final String value;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final texts = context.theme.appTextThemes;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onInfoTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 14.0.s,
            height: 14.0.s,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          SizedBox(width: 3.0.s),
          Text(
            value,
            style: texts.caption2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
