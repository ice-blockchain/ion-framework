// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/communities/views/components/community_token_image.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenHeaderComponent extends HookWidget {
  const TokenHeaderComponent({
    required this.token,
    super.key,
  });

  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        SizedBox(height: statusBarHeight + 16.0.s),
        if (token.type == CommunityTokenType.profile)
          CreatorTokenHeader(token: token)
        else
          // TODO ice-kreios content toker header
          Container(),
        SizedBox(height: 25.0.s),
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
                size: 89.0.s,
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
          child: ProfileTokenStatsInfo(
            externalAddress: token.externalAddress,
          ),
        ),
      ],
    );
  }
}
