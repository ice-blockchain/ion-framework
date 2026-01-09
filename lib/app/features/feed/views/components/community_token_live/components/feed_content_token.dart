// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/shapes/bottom_notch_rect_border.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/token_card_builder.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_creator_tile.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class FeedContentToken extends StatelessWidget {
  const FeedContentToken({
    required this.tokenDefinition,
    required this.type,
    this.hodl,
    this.pnl,
    this.showBuyButton = true,
    this.sidePadding,
    this.hasNotch = false,
    super.key,
  });

  final CommunityTokenDefinitionEntity tokenDefinition;
  final CommunityContentTokenType type;
  final Widget? hodl;
  final Widget? pnl;
  final double? sidePadding;
  final bool showBuyButton;
  final bool hasNotch;

  @override
  Widget build(BuildContext context) {
    final externalAddress = tokenDefinition.data.externalAddress;

    return TokenCardBuilder(
      externalAddress: externalAddress,
      skeleton: _Skeleton(type: type, showBuyButton: showBuyButton),
      builder: (token, colors) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding ?? 16.0.s),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: BottomNotchRectBorder(
                  notchPosition: hasNotch ? NotchPosition.top : NotchPosition.none,
                ),
              ),
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
                        tokenDefinition: tokenDefinition,
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
      },
    );
  }
}

class ContentTokenHeader extends HookConsumerWidget {
  const ContentTokenHeader({
    required this.tokenDefinition,
    required this.type,
    required this.token,
    required this.externalAddress,
    this.showBuyButton = true,
    this.pnl,
    super.key,
  });

  final CommunityTokenDefinitionEntity tokenDefinition;
  final CommunityContentTokenType type;
  final CommunityToken token;
  final String externalAddress;
  final bool showBuyButton;
  final Widget? pnl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = useImageColors(token.imageUrl);

    final eventReference = (tokenDefinition.data as CommunityTokenDefinitionIon).eventReference;

    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    final owner = ref.watch(userMetadataProvider(eventReference.masterPubkey)).valueOrNull;

    final isVerified = ref.watch(isUserVerifiedProvider(eventReference.masterPubkey));

    final (mediaAttachment, content) =
        useMemoized<(MediaAttachment? mediaAttachment, String? content)>(
      () {
        if (entity is ModifiablePostEntity) {
          return (entity.data.primaryMedia, entity.data.textContent.trim());
        } else if (entity is PostEntity) {
          return (entity.data.primaryMedia, entity.data.content.trim());
        } else if (entity is ArticleEntity) {
          final headerMedia =
              entity.data.media.entries.firstWhereOrNull((t) => t.value.url == entity.data.image);

          return (headerMedia?.value, entity.data.title?.trim());
        }
        return (null, null);
      },
      [entity],
    );

    final layoutConfig = useMemoized<_MediaLayoutConfig>(
      () {
        return _MediaLayoutConfig.fromAspectRatio(mediaAttachment?.aspectRatio);
      },
      [mediaAttachment?.aspectRatio],
    );

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
                  imageSize: layoutConfig.imageSize,
                  containerSize: layoutConfig.containerSize,
                  outerBorderRadius: layoutConfig.outerBorderRadius,
                  innerBorderRadius: layoutConfig.innerBorderRadius,
                  imageUrl: mediaAttachment?.thumb ?? mediaAttachment?.url,
                  borderWidth: layoutConfig.borderWidth,
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
                borderRadius: BorderRadius.circular(12.0.s),
                color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.15),
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
                          creator: Creator(
                            avatar: owner?.data.avatarUrl,
                            display: owner?.data.displayName,
                            name: owner?.data.name,
                            verified: isVerified,
                          ),
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
                  if (content != null && content.isNotEmpty) ...[
                    SizedBox(height: 12.0.s),
                    Text(
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      content,
                      style: context.theme.appTextThemes.caption2.copyWith(
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                    ),
                  ],
                  GradientHorizontalDivider(
                    margin: EdgeInsetsDirectional.symmetric(
                      vertical: 14.0.s,
                    ),
                  ),
                  ProfileTokenStats(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    eventReference:
                        (tokenDefinition.data as CommunityTokenDefinitionIon).eventReference,
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
                child: _BuyButton(tokenDefinition: tokenDefinition),
              ),
          ],
        ),
      ],
    );
  }
}

class _BuyButton extends ConsumerWidget {
  const _BuyButton({
    required this.tokenDefinition,
  });

  final CommunityTokenDefinitionEntity tokenDefinition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenDefinitionData = tokenDefinition.data;

    if (tokenDefinitionData is! CommunityTokenDefinitionIon) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => TradeCommunityTokenRoute(
        eventReference: tokenDefinitionData.eventReference.encode(),
        initialMode: CommunityTokenTradeMode.buy,
      ).push<void>(context),
      child: BuyButton(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 22.s,
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.type,
    this.showBuyButton = true,
  });

  final CommunityContentTokenType type;
  final bool showBuyButton;

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
          SizedBox(height: showBuyButton ? 34.0.s : 12.0.s),
        ],
      ),
    );
  }
}

class _MediaLayoutConfig {
  _MediaLayoutConfig({
    required this.imageSize,
    required this.containerSize,
    required this.outerBorderRadius,
    required this.innerBorderRadius,
    required this.borderWidth,
  });

  factory _MediaLayoutConfig.fromAspectRatio(double? aspectRatio) {
    if (aspectRatio == null || aspectRatio == 1) {
      return _MediaLayoutConfig(
        imageSize: Size.square(88.s),
        containerSize: Size.square(96.s),
        outerBorderRadius: 20.0.s,
        innerBorderRadius: 16.0.s,
        borderWidth: 2.s,
      );
    } else if (aspectRatio > 1) {
      return _MediaLayoutConfig(
        imageSize: Size(153.s, 86.s),
        containerSize: Size(163.s, 96.s),
        outerBorderRadius: 24.0.s,
        innerBorderRadius: 20.0.s,
        borderWidth: 2.s,
      );
    } else {
      return _MediaLayoutConfig(
        imageSize: Size(86.s, 101.s),
        containerSize: Size(96.s, 111.s),
        outerBorderRadius: 24.0.s,
        innerBorderRadius: 20.0.s,
        borderWidth: 2.s,
      );
    }
  }

  final Size imageSize;
  final Size containerSize;
  final double outerBorderRadius;
  final double innerBorderRadius;
  final double borderWidth;
}
