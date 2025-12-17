// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/speech_bubble/speech_bubble.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/views/pages/info/info_modal.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileTokenStatsInfo extends ConsumerWidget {
  const ProfileTokenStatsInfo({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(
      tokenMarketInfoProvider(externalAddress).select((t) => t.valueOrNull?.marketData),
    );
    if (marketData == null) {
      return const SizedBox.shrink();
    }
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
            TokenStatItem(
              icon: Assets.svg.iconMemeMarketcap,
              text: MarketDataFormatter.formatCompactNumber(marketData.marketCap),
              onTap: () => showSimpleBottomSheet<void>(
                context: context,
                child: const InfoModal(infoType: InfoType.marketCap),
              ),
            ),
            TokenStatItem(
              icon: Assets.svg.iconMemeMarkers,
              text: MarketDataFormatter.formatPrice(marketData.priceUSD),
              onTap: () => showSimpleBottomSheet<void>(
                context: context,
                child: const InfoModal(infoType: InfoType.volume),
              ),
            ),
            TokenStatItem(
              icon: Assets.svg.iconSearchGroups,
              text: MarketDataFormatter.formatCompactNumber(marketData.volume),
              onTap: () => showSimpleBottomSheet<void>(
                context: context,
                child: const InfoModal(infoType: InfoType.holders),
              ),
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
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.spacing,
    this.leading,
    super.key,
  });

  final String externalAddress;
  final MainAxisAlignment mainAxisAlignment;
  final Widget? leading;
  final double? spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress));

    if (!tokenInfo.hasValue) {
      return const SizedBox.shrink();
    }

    final marketData = tokenInfo.valueOrNull?.marketData;

    if (marketData == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BuyHint(),
          SizedBox(width: 8.0.s),
          GestureDetector(
            onTap: () => TradeCommunityTokenProfileRoute(
              externalAddress: externalAddress,
              externalAddressType: const ExternalAddressType.ionConnectUser().prefix,
              initialMode: CommunityTokenTradeMode.buy,
            ).push<void>(context),
            child: BuyButton(externalAddress: externalAddress),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      spacing: spacing ?? 0,
      children: [
        TokenStatItem(
          icon: Assets.svg.iconMemeMarketcap,
          text: MarketDataFormatter.formatCompactNumber(marketData.marketCap),
          onTap: () => showSimpleBottomSheet<void>(
            context: context,
            child: const InfoModal(infoType: InfoType.marketCap),
          ),
        ),
        TokenStatItem(
          icon: Assets.svg.iconMemeMarkers,
          text: MarketDataFormatter.formatPrice(marketData.priceUSD),
          onTap: () => showSimpleBottomSheet<void>(
            context: context,
            child: const InfoModal(infoType: InfoType.volume),
          ),
        ),
        TokenStatItem(
          icon: Assets.svg.iconSearchGroups,
          text: MarketDataFormatter.formatCompactNumber(marketData.volume),
          onTap: () => showSimpleBottomSheet<void>(
            context: context,
            child: const InfoModal(infoType: InfoType.holders),
          ),
        ),
        if (leading != null) leading!,
      ],
    );
  }
}

class TokenStatItem extends StatelessWidget {
  const TokenStatItem({
    required this.icon,
    required this.text,
    this.onTap,
    super.key,
  });

  final String icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 4.s),
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
          SizedBox(width: 4.s),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.secondaryBackground,
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
        padding: EdgeInsetsDirectional.only(
          top: 4.0.s,
          bottom: 4.0.s,
          start: 12.0.s,
          end: 12.0.s,
        ),
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
    this.padding,
    super.key,
  });

  final String externalAddress;
  final double height;
  final EdgeInsetsDirectional? padding;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding ?? EdgeInsetsDirectional.symmetric(horizontal: 10.0.s);
    return Container(
      height: height.s,
      padding: padding,
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.s),
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
          SizedBox(width: 4.s),
          Text(
            context.i18n.profile_token_buy,
            style: context.theme.appTextThemes.caption4.copyWith(
              color: context.theme.appColors.secondaryBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTokenStatsFeed extends ConsumerWidget {
  const ProfileTokenStatsFeed({
    required this.externalAddress,
    this.showFollowCounters = true,
    super.key,
  });

  final String externalAddress;
  final bool showFollowCounters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    if (tokenInfo == null) {
      return const SizedBox.shrink();
    }
    final marketData = tokenInfo.marketData;

    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Container(
          decoration: ShapeDecoration(
            color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.s),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showFollowCounters) ...[
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 34.0.s,
                  ),
                  child: FollowCounters(
                    padding: EdgeInsetsDirectional.only(top: 6.s),
                    enableDecoration: false,
                    profileMode: ProfileMode.dark,
                    height: 44.s,
                    pubkey: ReplaceableEventReference.fromString(
                      tokenInfo.creator.addresses!.ionConnect!,
                    ).masterPubkey,
                  ),
                ),
                GradientHorizontalDivider(
                  margin: EdgeInsetsDirectional.only(top: 0.s, bottom: 4.s),
                ),
              ],
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: showFollowCounters ? 10.s : 22.s,
                  start: 20.0.s,
                  end: 20.0.s,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 25.s,
                  children: [
                    TokenStatItem(
                      icon: Assets.svg.iconMemeMarketcap,
                      text: MarketDataFormatter.formatCompactNumber(
                        marketData.marketCap,
                      ),
                      onTap: () => showSimpleBottomSheet<void>(
                        context: context,
                        child: const InfoModal(infoType: InfoType.marketCap),
                      ),
                    ),
                    TokenStatItem(
                      icon: Assets.svg.iconMemeMarkers,
                      text: MarketDataFormatter.formatPrice(
                        marketData.priceUSD,
                      ),
                      onTap: () => showSimpleBottomSheet<void>(
                        context: context,
                        child: const InfoModal(infoType: InfoType.volume),
                      ),
                    ),
                    TokenStatItem(
                      icon: Assets.svg.iconSearchGroups,
                      text: MarketDataFormatter.formatCompactNumber(
                        marketData.volume,
                      ),
                      onTap: () => showSimpleBottomSheet<void>(
                        context: context,
                        child: const InfoModal(infoType: InfoType.holders),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 25.s,
              ),
            ],
          ),
        ),
        PositionedDirectional(
          bottom: -11.5.s,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => TradeCommunityTokenProfileRoute(
              externalAddress: externalAddress,
              externalAddressType: const ExternalAddressType.ionConnectUser().prefix,
              initialMode: CommunityTokenTradeMode.buy,
            ).push<void>(context),
            child: BuyButton(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 22.s),
              externalAddress: externalAddress,
            ),
          ),
        ),
      ],
    );
  }
}
