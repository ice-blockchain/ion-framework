// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_creator_tile.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_dialog.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class FeedContentToken extends HookConsumerWidget {
  const FeedContentToken({
    required this.externalAddress,
    required this.type,
    this.hodl,
    this.pnl,
    this.showBuyButton = true,
    super.key,
  });

  final String externalAddress;
  final CommunityContentTokenType type;
  final Widget? hodl;
  final Widget? pnl;
  final bool showBuyButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    if (token == null) {
      return _Skeleton(type: type);
    }

    final colors = useImageColors(token.imageUrl);

    if (colors == null) {
      return _Skeleton(type: type);
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0.s),
          child: ProfileBackground(
            colors: useImageColors(token.imageUrl),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: 24.0.s,
                bottom: showBuyButton ? 34.0.s : 12.0.s,
              ),
              child: Column(
                children: [
                  ContentTokenHeader(
                    type: type,
                    token: token,
                    pnl: pnl,
                    externalAddress: externalAddress,
                    showBuyButton: showBuyButton,
                  ),
                  if (hodl != null) hodl!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContentTokenHeader extends HookWidget {
  const ContentTokenHeader({
    required this.type,
    required this.token,
    required this.externalAddress,
    this.showBuyButton = true,
    this.pnl,
    super.key,
  });

  final CommunityContentTokenType type;
  final CommunityToken token;
  final String externalAddress;
  final bool showBuyButton;
  final Widget? pnl;

  @override
  Widget build(BuildContext context) {
    final colors = useImageColors(token.imageUrl);

    return Column(
      children: [
        if (type == CommunityContentTokenType.postImage ||
            type == CommunityContentTokenType.postVideo ||
            type == CommunityContentTokenType.article)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                TokenAvatar(
                  imageSize: Size.square(88.s),
                  containerSize: Size.square(96.s),
                  outerBorderRadius: 20.0.s,
                  innerBorderRadius: 16.0.s,
                  imageUrl: token.imageUrl,
                  borderWidth: 2.s,
                ),
                if (type == CommunityContentTokenType.postVideo)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.s),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                      child: Container(
                        width: 28.s,
                        height: 28.s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.theme.appColors.backgroundSheet,
                          borderRadius: BorderRadius.circular(12.s),
                        ),
                        child: Assets.svg.iconVideoPlay.icon(size: 16.s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Stack(
          alignment: AlignmentDirectional.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.5.s),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0.s),
              margin: EdgeInsetsDirectional.only(
                start: 12.0.s,
                end: 12.0.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.0.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TokenCreatorTile(
                          creator: token.creator,
                          nameColor: context.theme.appColors.onPrimaryAccent,
                          handleColor: context.theme.appColors.attentionBlock,
                        ),
                      ),
                      pnl ??
                          ProfileTokenPrice(
                            amount: token.marketData.priceUSD,
                          ),
                    ],
                  ),
                  SizedBox(height: 12.0.s),
                  Text(
                    token.description,
                    style: context.theme.appTextThemes.caption2.copyWith(
                      color: context.theme.appColors.onPrimaryAccent,
                    ),
                  ),
                  GradientHorizontalDivider(
                    margin: EdgeInsetsDirectional.symmetric(
                      vertical: 14.0.s,
                    ),
                  ),
                  ProfileTokenStats(
                    externalAddress: token.externalAddress,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ),
                  SizedBox(height: showBuyButton ? 24.0.s : 16.s),
                ],
              ),
            ),
            if (type == CommunityContentTokenType.article)
              PositionedDirectional(
                start: 12.s,
                top: 16.s,
                bottom: 16.s,
                child: Container(
                  width: 4.s,
                  decoration: BoxDecoration(
                    color: colors?.first,
                    borderRadius: BorderRadiusDirectional.only(
                      topEnd: Radius.circular(12.5.s),
                      bottomEnd: Radius.circular(12.5.s),
                    ),
                  ),
                ),
              ),
            if (showBuyButton)
              PositionedDirectional(
                bottom: -11.5.s,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => showSimpleBottomSheet<void>(
                    context: context,
                    child: TradeCommunityTokenDialog(
                      externalAddress: externalAddress,
                      mode: CommunityTokenTradeMode.buy,
                    ),
                  ),
                  child: BuyButton(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 22.s,
                    ),
                    externalAddress: externalAddress,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.type,
  });

  final CommunityContentTokenType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 24.0.s),
      margin: EdgeInsetsDirectional.symmetric(horizontal: 16.0.s),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      child: Column(
        children: [
          if (type == CommunityContentTokenType.postImage)
            Skeleton(
              baseColor: context.theme.appColors.attentionBlock,
              child: Column(
                children: [
                  Container(
                    height: 96.s,
                    width: 96.s,
                    decoration: BoxDecoration(
                      color: context.theme.appColors.attentionBlock,
                      borderRadius: BorderRadius.circular(24.0.s),
                    ),
                  ),
                ],
              ),
            )
          else if (type == CommunityContentTokenType.postVideo ||
              type == CommunityContentTokenType.article)
            Skeleton(
              baseColor: context.theme.appColors.attentionBlock,
              child: Column(
                children: [
                  Container(
                    height: 96.s,
                    width: 163.s,
                    decoration: BoxDecoration(
                      color: context.theme.appColors.attentionBlock,
                      borderRadius: BorderRadius.circular(24.0.s),
                    ),
                  ),
                ],
              ),
            ),
          if (type != CommunityContentTokenType.postText) SizedBox(height: 16.s),
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 288.s,
                decoration: BoxDecoration(
                  color: context.theme.appColors.onPrimaryAccent,
                  borderRadius: BorderRadius.circular(16.0.s),
                ),
                padding: EdgeInsetsDirectional.fromSTEB(16.s, 20.s, 16.s, 27.5.s),
                child: Skeleton(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 30.s,
                            width: 30.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                          SizedBox(width: 8.s),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 19.s,
                                width: 80.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(16.0.s),
                                ),
                              ),
                              SizedBox(height: 4.s),
                              Container(
                                height: 12.s,
                                width: 57.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(16.0.s),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            height: 18.s,
                            width: 53.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(6.0.s),
                            ),
                          ),
                        ],
                      ),
                      if (type == CommunityContentTokenType.postText)
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: 12.s),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 230.s,
                                height: 12.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                              SizedBox(height: 6.s),
                              Container(
                                width: 173.s,
                                height: 12.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                              SizedBox(height: 6.s),
                              Container(
                                width: 173.s,
                                height: 12.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (type == CommunityContentTokenType.postVideo ||
                          type == CommunityContentTokenType.article)
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: 12.s),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 230.s,
                                height: 21.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                              SizedBox(height: 6.s),
                              Container(
                                width: 173.s,
                                height: 21.s,
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.attentionBlock,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 12.s),
                      Container(
                        width: double.infinity,
                        height: 1.s,
                        color: context.theme.appColors.attentionBlock,
                      ),
                      SizedBox(height: 12.s),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -11.5.s,
                child: Skeleton(
                  baseColor: context.theme.appColors.attentionBlock,
                  child: Container(
                    width: 72.s,
                    height: 23.s,
                    decoration: BoxDecoration(
                      color: context.theme.appColors.attentionBlock,
                      borderRadius: BorderRadius.circular(16.0.s),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 27.5.s),
        ],
      ),
    );
  }
}
