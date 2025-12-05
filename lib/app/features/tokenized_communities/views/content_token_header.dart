// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_creator_tile.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class ContentTokenHeader extends StatelessWidget {
  const ContentTokenHeader({
    required this.token,
    super.key,
  });

  final CommunityToken? token;

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CommunityTokenImage(
          imageUrl: token!.imageUrl,
          width: 110.0.s,
          height: 94.0.s,
          innerBorderRadius: 9.0.s,
          outerBorderRadius: 9.0.s,
          innerPadding: 2.0.s,
        ),
        SizedBox(height: 12.0.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          child: _TokenContent(
            token: token!,
          ),
        ),
        SizedBox(height: 16.0.s),
      ],
    );
  }
}

class _TokenContent extends StatelessWidget {
  const _TokenContent({
    required this.token,
  });

  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.5.s),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
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
              ProfileTokenPrice(amount: token.marketData.priceUSD),
            ],
          ),
          SizedBox(height: 12.0.s),
          Text(
            token.description,
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
            ),
          ),
          SizedBox(height: 12.0.s),
          GradientHorizontalDivider(
            margin: EdgeInsetsDirectional.symmetric(vertical: 12.0.s),
          ),
          ProfileTokenStats(
            externalAddress: token.externalAddress,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          SizedBox(height: 16.0.s),
        ],
      ),
    );
  }
}
