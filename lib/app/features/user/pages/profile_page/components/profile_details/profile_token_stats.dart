// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/speech_bubble/speech_bubble.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/utils/market_data_formatter.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class ProfileTokenStatsInfo extends StatelessWidget {
  const ProfileTokenStatsInfo({
    this.data,
    super.key,
  });

  final MarketData? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.53.s),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 34.0.s,
          vertical: 16.0.s,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatItem(
              icon: Assets.svg.iconMemeMarketcap,
              text: data?.marketCap == null
                  ? '--'
                  : MarketDataFormatter.formatCompactNumber(data!.marketCap),
            ),
            _StatItem(
              icon: Assets.svg.iconMemeMarkers,
              text: data?.priceUSD == null ? '--' : MarketDataFormatter.formatPrice(data!.priceUSD),
            ),
            _StatItem(
              icon: Assets.svg.iconSearchGroups,
              text: data?.volume == null
                  ? '--'
                  : MarketDataFormatter.formatCompactNumber(data!.volume),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTokenStats extends ConsumerWidget {
  const ProfileTokenStats({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    if (token == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BuyHint(),
          SizedBox(width: 8.0.s),
          BuyButton(externalAddress: externalAddress),
        ],
      );
    }

    void onStatItemTap() {
      TokenizedCommunityRoute(externalAddress: externalAddress).go(context);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(
          icon: Assets.svg.iconMemeMarketcap,
          text: MarketDataFormatter.formatCompactNumber(token.marketData.marketCap),
          onTap: onStatItemTap,
        ),
        _StatItem(
          icon: Assets.svg.iconMemeMarkers,
          text: MarketDataFormatter.formatPrice(token.marketData.priceUSD),
          onTap: onStatItemTap,
        ),
        _StatItem(
          icon: Assets.svg.iconSearchGroups,
          text: MarketDataFormatter.formatCompactNumber(token.marketData.volume),
          onTap: onStatItemTap,
        ),
        BuyButton(externalAddress: externalAddress),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.text,
    this.onTap,
  });

  final String icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 3.13.s),
          Container(
            width: 14.15.s,
            height: 14.15.s,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Center(
              child: icon.icon(
                size: 14.15.s,
                color: context.theme.appColors.secondaryBackground,
              ),
            ),
          ),
          SizedBox(width: 3.13.s),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.secondaryBackground,
                fontFamily: 'Noto Sans',
                fontWeight: FontWeight.w600,
                height: 1.17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyHint extends StatelessWidget {
  const _BuyHint();

  @override
  Widget build(BuildContext context) {
    return SpeechBubble(
      height: 24.0.s,
      child: Container(
        height: 24.0.s,
        padding: EdgeInsetsDirectional.only(top: 4.0.s, bottom: 4.0.s, start: 12.0.s, end: 12.0.s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.svg.streamlineUltimateGamingRibbonFirst.icon(
              size: 14.0.s,
              color: context.theme.appColors.primaryText,
            ),
            SizedBox(width: 3.13.s),
            Text(
              context.i18n.profile_token_be_first_to_buy,
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.primaryText,
                fontFamily: 'Noto Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 3.13.s),
          ],
        ),
      ),
    );
  }
}

class BuyButton extends StatelessWidget {
  const BuyButton({
    required this.externalAddress,
    this.height = 23.0,
    super.key,
  });

  final String externalAddress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TokenizedCommunityRoute(externalAddress: externalAddress).go(context),
      child: Container(
        height: height.s,
        padding: EdgeInsets.symmetric(horizontal: 22.0.s),
        decoration: ShapeDecoration(
          color: context.theme.appColors.primaryAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.32.s),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              child: Center(
                child: Assets.svg.iconWorkBuycoin.icon(
                  size: 14.s,
                  color: context.theme.appColors.secondaryBackground,
                ),
              ),
            ),
            SizedBox(width: 3.13.s),
            Text(
              context.i18n.profile_token_buy,
              style: context.theme.appTextThemes.caption3.copyWith(
                color: context.theme.appColors.secondaryBackground,
                fontFamily: 'Noto Sans',
                fontWeight: FontWeight.w600,
                height: 1.28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
