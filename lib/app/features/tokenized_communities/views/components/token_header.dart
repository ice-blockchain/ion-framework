// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/tokenized_communities/views/content_token_header.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum TokenHeaderType {
  feed,
  tokenizedCommunity,
}

class TokenHeader extends HookWidget {
  const TokenHeader({
    required this.token,
    required this.type,
    super.key,
  });

  final CommunityToken token;
  final TokenHeaderType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (token.type == CommunityTokenType.profile)
          CreatorTokenHeader(token: token, type: type)
        else
          ContentTokenHeader(token: token),
      ],
    );
  }
}

class CreatorTokenHeader extends HookWidget {
  const CreatorTokenHeader({
    required this.token,
    required this.type,
    super.key,
  });

  final CommunityToken token;
  final TokenHeaderType type;

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
                      color: const Color(0xff1D1E20),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8.0.s),
                    ),
                    child: Assets.svg.iconLoginXlogo
                        .icon(size: 15.0.s, color: context.theme.appColors.secondaryBackground),
                  ),
                ),
              if (type == TokenHeaderType.tokenizedCommunity &&
                  token.source.isIonConnect &&
                  token.creator.addresses?.ionConnect != null)
                PositionedDirectional(
                  bottom: -3.s,
                  end: -3.s,
                  child: ProfileMainAction(
                    profileMode: ProfileMode.dark,
                    pubkey: ReplaceableEventReference.fromString(
                      token.creator.addresses!.ionConnect!,
                    ).masterPubkey,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: type == TokenHeaderType.tokenizedCommunity ? 8.0.s : 10.0.s),
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
              prefixUsername(username: token.marketData.ticker ?? '', context: context),
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
        SizedBox(height: type == TokenHeaderType.tokenizedCommunity ? 16.0.s : 24.0.s),
        if (type == TokenHeaderType.tokenizedCommunity)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 51.0.s),
            child: ProfileTokenStatsInfo(
              externalAddress: token.externalAddress,
            ),
          )
        else
          IntrinsicWidth(
            child: ProfileTokenStatsFeed(
              externalAddress: token.externalAddress,
            ),
          ),
      ],
    );
  }
}
